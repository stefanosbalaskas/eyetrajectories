# Native sparse multivariate FPCA workflow with optional Python W2 scientific contract

Performs paired sparse multivariate covariance/PACE in native R without
a Python dependency. In the strict source-scientific representation,
Python W2 schema and scientific numerical quantities are separated from
Python dataclass/Matplotlib/runtime identity. Exact source parity and
independent certification require a passing frozen Python 1.2
differential run.

## Usage

``` r
etr_run_sparse_mfpca_workflow(trajectories, config,
    observation_process = NULL, strict_source_record = FALSE)
```

## Arguments

- trajectories:

  Native irregular two-coordinate trajectory set with paired source
  observations.

- config:

  Named configuration with explicit backend. For strict source mode use
  `backend="native_covariance"`, `n_components`, `evaluation_grid`,
  `measurement_error`, and fixed `mean_bandwidth`/`covariance_bandwidth`
  or `bandwidth_selection`; optional `score_uncertainty`,
  `observation_diagnostics` and empty `preprocessing`. The separate
  fdapace marginal-score alternative is not Python source parity.

- observation_process:

  Optional explicit candidate-sample denominator for observation-process
  diagnostics.

- strict_source_record:

  When TRUE, emit the 12-field Python 1.2 W2 source-scientific workflow
  analogue with 22 ordered configuration fields, seven decisions, four
  provenance fields and genuinely measured R steps. Reject R-only
  explicit selector fold assignments and fdapace, and require a declared
  NumPy group sort profile for group bandwidth selection. No Python
  runtime type identity is claimed. Default FALSE retains native R
  diagnostic records.

## Value

A native sparse MFPCA workflow record; if strict, a canonical
source-scientific result including the native covariance/PACE fit,
optional bandwidth selection, score uncertainty, observation
diagnostics, steps, decisions, reports and tables.
