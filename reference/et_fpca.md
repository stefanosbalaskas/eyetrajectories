# Functional PCA through eyetrajectoriespy

Run Python FPCA or multivariate FPCA and read selected results into R.

## Usage

``` r
et_fit_fpca(trajectories, n_components = 0.95,
            scaling = c("none", "dimension_sd"))

et_fit_mfpca(trajectories, n_components = 0.95,
             scaling = c("none", "dimension_sd"))

et_scores(fit, prefix = "FPC")

et_explained_variance(fit, cumulative = FALSE)
```

## Arguments

- trajectories:

  Python TrajectorySet object.

- n_components:

  Integer number of components or fraction of variance.

- scaling:

  Scale dimensions or preserve the original units.

- fit:

  Python FPCAResult object.

- prefix:

  Prefix for component score column names.

- cumulative:

  Return cumulative instead of component-level variance fractions.

## Value

`et_fit_fpca()` and `et_fit_mfpca()` return Python FPCAResult objects.
`et_scores()` returns an R data frame; `et_explained_variance()` returns
a numeric vector.

## Details

Inference and numerical guarantees come from the Python implementation.

## Examples

``` r
if (FALSE) { # \dontrun{
gaze <- et_simulate_planar()
fit <- et_fit_mfpca(gaze, scaling = "dimension_sd")
head(et_scores(fit))
et_explained_variance(fit)
} # }
```
