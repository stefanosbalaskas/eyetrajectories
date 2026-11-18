# Whole-participant conditional covariance functional mixed-effects bootstrap

Resamples entire participant trial bundles, retains the reference
random/residual covariance, and recomputes joint fixed-basis Gaussian
GLS coefficients, not timewise independent moments. The reference fitted
R likelihood optimizer is `nlme`, whereas frozen Python uses
`statsmodels`; equality of independent optimizer paths and runtime
objects is not claimed.

## Usage

``` r
etr_bootstrap_functional_mixed_effects_coefficients(
    result, n_bootstrap = 1000L, random_state = 0L,
    sampled_participant_indices = NULL, strict_source_record = FALSE)
```

## Arguments

- result:

  Previously fitted native functional mixed-effects model; strict source
  mode requires a genuine native joint spline Gaussian likelihood fit,
  not the older two-level moments alternative.

- n_bootstrap:

  Number of whole-participant resamples. Source-oriented conditional
  covariance path requires at least 100 draws.

- random_state:

  Integer source PCG64 seed (representable by native exact arithmetic).

- sampled_participant_indices:

  Optional zero-based matrix for native R reproducibility. Disallowed
  under strict source mode because the frozen Python public API does not
  accept externally supplied draws.

- strict_source_record:

  If TRUE, emit exactly nine ordered scientific fields from frozen
  Python 1.2 `FunctionalMixedEffectsBootstrapResult`.

## Value

Native fixed-covariance participant GLS bootstrap. With strict source
record, a nine-field scientific record; no Python dataclass identity.
