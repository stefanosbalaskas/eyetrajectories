# Native asynchronous sparse multivariate FPCA workflow with source-scientific output

No raw synchronization, interpolation, or time binning is performed.
Separate coordinate observation grids and within-time correlated
measurement noise are retained. Python dataclass identity, Python
exception types and full external backend equivalence are not implied.

## Usage

``` r
etr_run_sparse_mfpca_async_workflow(trajectories, config,
    observation_process = NULL, strict_source_record = FALSE)
```

## Arguments

- trajectories:

  Native irregular trajectory set with exact union timestamps and
  missing coordinate observations preserved as NaN. Alternative fdapace
  input can use separate channel collections when strict mode is FALSE.

- config:

  Explicit configuration with native covariance backend, original
  coordinate dimensions, component count, evaluation grid, fixed
  bandwidths, measurement-error model, optional same-time tolerance, and
  empty preprocessing.

- observation_process:

  Optional explicit candidate observation-process denominator for W2
  diagnostics.

- strict_source_record:

  When TRUE, use genuine native direct asynchronous covariance/PACE and
  emit the 10-field frozen Python 1.2 W2 scientific workflow record with
  seven decisions, seven provenance fields, measured steps, and optional
  observation diagnostics. Default FALSE retains the original native
  diagnostic result.

## Value

An R-native asynchronous sparse MFPCA workflow, or in strict source mode
a scientific W2 schema analogue with native fit and audited decisions
and reports.
