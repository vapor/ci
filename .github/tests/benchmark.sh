#!/usr/bin/env bash
set -euo pipefail
unset BENCHMARK_CONFIGURATIONS BENCHMARK_ENVIRONMENT VALIDATE_THRESHOLDS

repository=$(cd "$(dirname "$0")/../.." && pwd)
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT
mkdir -p "$workspace/bin"
# Exercise the exact command embedded in the reusable workflow, without Swift builds.
awk '
  /cat > .*<<.BENCHMARK_SCRIPT./ { copying=1; next }
  /^          BENCHMARK_SCRIPT$/ { copying=0 }
  copying { sub(/^          /, ""); print }
' "$repository/.github/workflows/run-benchmark.yml" > "$workspace/run-benchmark"
test -s "$workspace/run-benchmark"
export CALL_LOG="$workspace/calls.jsonl"
export PATH="$workspace/bin:$PATH"
cat > "$workspace/bin/swift" <<'SWIFT'
#!/usr/bin/env bash
set -euo pipefail
jq -cn --arg mode "${MODE:-}" --arg common "${COMMON:-}" --args \
  '{mode:$mode,common:$common,args:$ARGS.positional}' -- "$@" >> "$CALL_LOG"
while [[ "$1" != benchmark ]]; do shift; done
shift
category=$1 operation=$2
shift 3
if [[ "$category/$operation" == thresholds/update ]]; then
  while [[ "$1" != --path ]]; do shift; done
  mkdir -p "$2"
  if [[ "${MOCK_EMPTY:-false}" != true ]]; then
    jq -n --arg metric "${MOCK_METRIC:-instructions}" --argjson value "${MOCK_VALUE:-100}" \
      '{($metric):$value}' > "$2/Suite.example.p90.json"
  fi
elif [[ "$category/$operation" == thresholds/check ]]; then
  exit "${MOCK_STATUS:-0}"
fi
SWIFT
chmod +x "$workspace/bin/swift"
cd "$workspace"

expect_status() {
  local expected=$1 actual=0
  shift
  "$@" > "$workspace/output" 2>&1 || actual=$?
  if [[ "$actual" != "$expected" ]]; then
    cat "$workspace/output"
    echo "Expected exit ${expected}, got ${actual}: $*" >&2
    exit 1
  fi
}

# Existing callers keep their original command, baseline title and threshold path.
expect_status 0 bash ./run-benchmark baseline update 'PR title with spaces'
jq -es 'length == 1 and .[0].args == ["package","-c","release","--disable-sandbox","--package-path","Benchmarks","benchmark","baseline","update","PR title with spaces"]' "$CALL_LOG" >/dev/null
expect_status 0 bash ./run-benchmark thresholds update 'PR title with spaces'
test -f Benchmarks/Thresholds/Suite.example.p90.json

export BENCHMARK_CONFIGURATIONS='[
  {"name":"instructions","build":"plain","environment":{"MODE":"instructions"}},
  {"name":"allocations","build":"allocations","swift_flags":["--traits","AllocationCounting"],"environment":{"MODE":"allocations","MOCK_METRIC":"mallocCountTotal"}},
  {"name":"cpu","build":"plain","environment":{"MODE":"cpu","MOCK_METRIC":"cpuTotal","COMMON":"overridden value"}},
  {"name":"wall-clock","build":"plain","environment":{"MODE":"wall-clock","MOCK_METRIC":"wallClock"}}
]'
export BENCHMARK_ENVIRONMENT='{"COMMON":"shared value"}'
: > "$CALL_LOG"
expect_status 0 bash ./run-benchmark baseline update 'PR title with spaces'
jq -es '
  length == 4 and map(.mode) == ["instructions","allocations","cpu","wall-clock"] and
  all(.[]; (.args | .[index("--scratch-path") + 1]) == (if .mode == "allocations" then "Benchmarks/.build/allocations" else "Benchmarks/.build/plain" end)) and
  all(.[]; (.args | index("--traits") != null) == (.mode == "allocations")) and
  .[2].common == "overridden value" and .[0].common == "shared value" and
  all(.[]; .args[-1] == "ci-" + .mode)
' "$CALL_LOG" >/dev/null

export VALIDATE_THRESHOLDS=true
expect_status 0 bash ./run-benchmark thresholds update title
for mode in instructions allocations cpu wall-clock; do
  test -f "Benchmarks/Thresholds/$mode/Suite.example.p90.json"
done
expect_status 0 bash ./run-benchmark thresholds check title --format markdown
printf '{"mallocCountTotal":0}' > Benchmarks/Thresholds/allocations/Suite.example.p90.json
expect_status 2 bash ./run-benchmark thresholds check title
expect_status 0 bash ./run-benchmark thresholds update title
rm Benchmarks/Thresholds/cpu/Suite.example.p90.json
expect_status 30 bash ./run-benchmark thresholds check title
expect_status 0 bash ./run-benchmark thresholds update title
printf '{"wrongMetric":100}' > Benchmarks/Thresholds/cpu/Suite.example.p90.json
expect_status 30 bash ./run-benchmark thresholds check title
expect_status 30 env MOCK_VALUE=0 bash ./run-benchmark thresholds check title
rm -rf Benchmarks/Thresholds
expect_status 30 env MOCK_EMPTY=true bash ./run-benchmark thresholds update title

# A regression and an improvement must not cancel out or hide a command failure.
export VALIDATE_THRESHOLDS=false
export BENCHMARK_CONFIGURATIONS='[{"name":"one","environment":{"MOCK_STATUS":"2"}},{"name":"two","environment":{"MOCK_STATUS":"4"}}]'
expect_status 1 bash ./run-benchmark thresholds check title
export BENCHMARK_CONFIGURATIONS='[{"name":"one","environment":{"MOCK_STATUS":"30"}},{"name":"two","environment":{"MOCK_STATUS":"4"}}]'
expect_status 30 bash ./run-benchmark thresholds check title

for invalid in '[]' '[{},{}]' '[{"name":"../escape"}]' \
  '[{"name":"one","build":"same"},{"name":"two","build":"same","swift_flags":["--traits","AllocationCounting"]}]' \
  '[{"name":"duplicate"},{"name":"duplicate"}]' '[{"unexpected":true}]'; do
  expect_status 30 env BENCHMARK_CONFIGURATIONS="$invalid" bash ./run-benchmark --validate
done
expect_status 30 env BENCHMARK_ENVIRONMENT='{"COUNT":2}' bash ./run-benchmark --validate

# Full reports remain intact; comment excerpts are raw Markdown, not JSON strings.
awk '
  /^          for REPORT in comparison benchmark; do$/ { copying=1 }
  copying { sub(/^          /, ""); print }
  copying && /^done$/ { copying=0 }
' "$repository/.github/workflows/run-benchmark.yml" > "$workspace/truncate-reports"
awk 'BEGIN { for (i=0; i<5000; i++) print "benchmark report row" }' > benchmark.md
cp benchmark.md comparison.md
bash ./truncate-reports
test "$(wc -c < benchmark-comment.md)" -lt 21000
test "$(wc -c < benchmark.md)" -gt 90000
grep -q '^benchmark report row$' benchmark-comment.md
grep -q 'Report truncated' benchmark-comment.md
printf 'Passed native benchmark workflow tests: legacy invocation, configurations, build isolation, environment, thresholds, exit statuses and report formatting.\n'
