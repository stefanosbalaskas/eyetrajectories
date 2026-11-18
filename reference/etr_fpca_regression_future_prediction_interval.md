# Marginal future-outcome prediction intervals for Gaussian FPCR

Applies the published Python 1.2 centered empirical residual resampling
and percentile-calibration law to retained paired-bootstrap
conditional-mean predictions. It assumes exchangeable response residuals
and reports marginal intervals for individual targets. An integer seed
with the default engine reproduces NumPy's first spawned SeedSequence
stream for the residual indices.

## Usage

``` r
etr_fpca_regression_future_prediction_interval(
  result, outcome, confidence_level = 0.95,
  residual_method = "empirical_centered", random_state = 0L,
  residual_indices = NULL, random_engine = "numpy",
  python_boundary_mode = FALSE
)
```

## Arguments

- result:

  Retained Gaussian FPCR paired-bootstrap uncertainty record.

- outcome:

  Training outcomes matching the reference fitted responses.

- confidence_level:

  Marginal predictive interval coverage probability.

- residual_method:

  Must equal `"empirical_centered"`.

- random_state:

  Nonnegative integer seed below 2^53 for a spawned NumPy-compatible
  PCG64 stream. NULL uses the current R RNG stream.

- residual_indices:

  Optional zero-based B-by-target source index matrix allowing exact
  numerical replay of pinned Python residual draws.

- random_engine:

  Use `"numpy"` for source-seeded residual draws or `"base_R"` to
  reproduce previous native seeded draws.

- python_boundary_mode:

  If TRUE, apply the explicitly requested frozen Python 1.2 boundary
  semantics; FALSE retains strict native defaults.

## Value

Source-shaped marginal future-outcome predictive draws, limits, medians,
pointwise sample standard deviations and scientific provenance.
