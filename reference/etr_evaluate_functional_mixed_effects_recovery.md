# Known-truth functional mixed-effects intercept and variance recovery

Evaluates known truth only. Never compares fitted basis covariance
coefficients directly to KL eigenvalues, reinterprets curve-level
functional variation as scalar residual variance, refits or resamples.
Python dataclass and full accepted-domain certification remain open.

## Usage

``` r
etr_evaluate_functional_mixed_effects_recovery(
  result, truth, intercept_name = "Intercept"
)
```

## Arguments

- result:

  Native source-shaped Gaussian functional mixed-effects fit.

- truth:

  Retained functional simulator truth, including exact grid, mean,
  eigenfunctions, and participant/trial eigenvalue declarations.

- intercept_name:

  Predeclared fixed-intercept name.

## Value

An assessment of integrated squared intercept error, participant and
optional trial time-domain variance errors, and exact scientific
provenance.
