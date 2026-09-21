# vapor-ci

Contains workflows and actions which encapsulate, as best as possible, common CI logic and requirements across Vapor's repositories.

## Benchmark workflow

`run-benchmark.yml` runs the standalone `Benchmarks` package on the benchmark
runner and posts threshold comparisons to PRs dispatched by Penny. Existing callers
need only the optional `sha` input. Additional inputs are opt-in:

| Input | Default | Purpose |
| --- | --- | --- |
| `swift_image` | `swift:noble` | Pin the compiler/container used for measurements. |
| `benchmark_driver` | Empty | Executable path relative to the checked-out repository; replaces the default `swift package ... benchmark` command. |
| `thresholds_mode` | `check` | `check` compares committed thresholds; `record` exports replacements; `bootstrap` records only when no `*.p90.json` files exist under `Benchmarks/Thresholds`. |

A custom driver receives the same argument interface as the benchmark plugin:
`baseline update TITLE`, `baseline read TITLE --format markdown`,
`thresholds check TITLE --path Benchmarks/Thresholds/ --format markdown`, and
`thresholds update TITLE --path Benchmarks/Thresholds/`. It must preserve the
comparison exit codes: 0 equal, 1 mixed differences, 2 regressions, 4 improvements;
other failures must also return nonzero. Python 3 is available for drivers.
The driver can run separate instrumented/uninstrumented builds and aggregate their
results into one report and commit status. Arguments are passed directly, without
shell evaluation. A changed driver, runner architecture or container image selects
a separate build cache.

Recording runs upload a `benchmark-thresholds` artifact and explicitly report that
no comparison was performed. They do not set a successful performance commit
status. A human reviews and commits the generated files; bootstrap callers then
switch to checking automatically. Explicit `record` runs support later refreshes.
No thresholds are automatically committed or approved.

Full markdown reports are uploaded as `benchmark-reports`. PR comment sections
are capped to keep large suites within GitHub's comment size limit. A caller using
Penny needs a `benchmark.yml` dispatch workflow accepting `sha` on its default
branch, and the existing Penny app credentials.
