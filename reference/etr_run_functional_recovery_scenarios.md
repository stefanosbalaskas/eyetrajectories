# Run native functional recovery scenarios with semantic scientific metrics

Run declared functional simulation scenarios and score estimator
recovery, without exposing the simulator's latent truth to the
estimator. Recoveries can be returned as named finite scalar metrics or
source-aligned semantic recovery assessments with component/source
labels and metric definitions.

## Usage

``` r
etr_run_functional_recovery_scenarios(
  scenarios, mean, eigenfunctions, estimator, recovery,
  failure_action = "raise", source_draws_by_replicate = NULL,
  observation_times_by_replicate = NULL, random_engine = "base_R",
  python_boundary_mode = FALSE
)
```

## Arguments

- source_draws_by_replicate:

  Ordered records of retained source draws per replicate.

- observation_times_by_replicate:

  Ordered fixed irregular schedules per replicate.

- random_engine:

  `"base_R"` preserves the existing native draws. `"numpy"` uses the
  source-seeded PCG64 mode of
  [`etr_simulate_functional_process()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_simulate_functional_process.md)
  for each scenario seed. Fixed source draws require `"base_R"`.

- scenarios:

  Nonempty list of declared native `etr_functional_simulation_scenario`
  records.

- mean:

  Callable generating the functional population mean.

- eigenfunctions:

  List of generating functional component callables.

- estimator:

  Function of `(observations, scenario)`. Exact generating truth is
  never passed to this callback.

- recovery:

  Function of `(fit, truth, scenario)`. Must return either a named
  finite numeric metric vector or an
  `etr_functional_recovery_assessment` containing nonempty `values` of
  semantically defined metrics and optional named `provenance`. Metric
  component indices are zero-based in source records and shown one-based
  in output keys/frames.

- failure_action:

  Either `"raise"` to propagate a failure or `"record"` to preserve
  explicit simulation, fit, or recovery errors without redraw or
  fabricated metric output.

- python_boundary_mode:

  If TRUE, follow declared published-source boundary semantics; FALSE
  retains native validation defaults.

## Value

An `etr_functional_recovery_result` with one ordered record per
attempted replicate, `metric_definitions` describing the source metric
names, and provenance distinguishing the R random engine from frozen
Python. Structured successes retain `metric_values` and
`assessment_provenance`; failures retain their status, exception
category and message.

## Details

Native Student-t and Gaussian functional simulations with dense or
irregular schedules, source power-phase variation, correlated
measurement noise and MCAR/block dropout can be driven by the declared
scenario fields. Scientific truth remains isolated from the estimator
callback and available only to the recovery callback.

Structured assessments are validated for finite values, nonempty
semantic metric definitions, unique component/source tuples, unique
flattened metric keys and stable definitions across replicates. A
conflicting definition for the same metric name is an error even when
`failure_action="record"`.

The result uses native R records. Seed replay is qualified for the
documented simulation subdomain. Full Python type, callback, and
exception contracts and independent scientific certification remain
open.
