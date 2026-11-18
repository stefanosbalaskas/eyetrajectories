# Execute a Python FPCA workflow

Runs the published Python common-grid FPCA workflow using a declared
configuration.

## Usage

``` r
et_run_fpca_workflow(trajectories, n_components = 0.95,
                     scaling = c("none", "dimension_sd"))
```

## Arguments

- trajectories:

  Python TrajectorySet object.

- n_components:

  Integer component count or variance fraction.

- scaling:

  Coordinate channel scaling policy.

## Value

Python `FPCAWorkflowResult` object with fit, decisions, and reports.

## Details

No hidden preprocessing is applied. Other public workflows are
accessible through `et_call(name, ..., .namespace = "workflows")`. The R
bridge does not claim independent scientific qualification.

## Examples

``` r
if (FALSE) { # \dontrun{
gaze <- et_simulate_planar()
workflow <- et_run_fpca_workflow(gaze, scaling = "dimension_sd")
fit <- workflow$fit
et_scores(fit)
} # }
```
