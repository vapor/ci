# vapor-ci

Contains workflows and actions which encapsulate, as best as possible, common CI logic and requirements across Vapor's repositories.

## Benchmark workflow

`run-benchmark.yml` runs the standalone `Benchmarks` package on the benchmark
runner and posts threshold comparisons to PRs dispatched by Penny. Existing callers
need only the optional `sha` input. Additional inputs are opt-in:

| Input | Default | Purpose |
| --- | --- | --- |
| `swift_image` | `swift:noble` | Pin the compiler/container used for measurements. |
| `configurations` | `[{}]` | JSON array of named configurations; see below. |
| `environment` | `{}` | JSON object of string-valued environment variables shared by all configurations. |
| `validate_thresholds` | `false` | Require nonempty results and matching metric keys in committed thresholds. |
| `record_thresholds` | `false` | Export thresholds for review instead of comparing committed thresholds. |

### Separate configurations

The shared workflow runs configurations sequentially on the same runner using the
benchmark package's standard `baseline update/read` and `thresholds update/check`
commands. A caller supplies data rather than an executable driver. For example:

```yaml
with:
  swift_image: swift:6.4-bookworm
  configurations: >-
    [
      {"name":"instructions","build":"plain","environment":{"BENCHMARK_MODE":"instructions"}},
      {"name":"allocations","build":"allocations","swift_flags":["--traits","AllocationCounting"],"environment":{"BENCHMARK_MODE":"allocations"}}
    ]
  environment: '{"NIO_SINGLETON_GROUP_LOOP_COUNT":"2"}'
  validate_thresholds: true
```

Each configuration accepts:

- `name`: unique identifier using letters, digits, underscores and hyphens.
- `build`: build directory identifier, defaulting to the configuration name.
  Builds use `Benchmarks/.build/BUILD`. Configurations can share a directory when
  their `swift_flags` are identical; instrumented and uninstrumented builds must
  use different directories.
- `swift_flags`: array of arguments passed to `swift package` before `benchmark`.
- `environment`: object of string-valued variables overriding the common environment.

Named configurations use `ci-NAME` baselines and `Benchmarks/Thresholds/NAME`.
One unnamed configuration, the default `[{}]`, preserves the original baseline
name, build directory and threshold path for existing callers. Every configuration
contributes to one report and commit status. Differences and failures are combined;
a regression in one configuration cannot cancel an improvement in another.
Arguments and environment values are passed without shell evaluation. The image,
runner architecture and configuration/environment select separate build caches.

### Thresholds and reports

Set `record_thresholds: true` to generate initial thresholds or refresh them on the
benchmark runner. Recording runs upload a `benchmark-thresholds` artifact and
report that no comparison was performed; they do not set a performance commit
status. Review and commit the generated files, then run with the default `false`
to compare against them. Missing thresholds never trigger automatic recording.

With `validate_thresholds`, the workflow inspects native threshold exports before
comparison. Every exported fixture must have the same metric keys in the committed
reference. Missing results or incompatible references fail the check. Metric values,
direction and tolerances are interpreted by the benchmark package. This coverage
check does not add comparison rules or validate hardware counters. Benchmark names
and tags must work with the native threshold reader and GitHub artifact filenames.

Full markdown reports are uploaded as `benchmark-reports`. PR comment sections
are capped to keep large suites within GitHub's comment size limit. A caller using
Penny needs a `benchmark.yml` dispatch workflow accepting `sha` on its default
branch, and the existing Penny app credentials.

Run `bash .github/tests/benchmark.sh` to test configuration handling, default caller
compatibility, threshold validation and reporting without building Swift packages.
The self-test workflow runs these checks on every PR.
