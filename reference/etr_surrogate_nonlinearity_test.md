# Native IAAFT surrogate test of an explicitly declared Lyapunov statistic

Independent base-R iterative amplitude-adjusted Fourier-transform
surrogates with explicit Rosenstein sample-index statistic and plus-one
Monte Carlo tail probability. Published Python 1.2 is the source of the
mathematical contract; random draws are not identical across R and
NumPy.

## Usage

``` r
etr_surrogate_nonlinearity_test(trajectories, curve, dimension, statistic,
  embedding_dimension, delay, theiler_window, max_horizon, fit_start, fit_end,
  delay_units = "samples", theiler_window_units = "samples",
  max_horizon_units = "samples", fit_units = "samples", method = "iaaft",
  n_surrogates = 199L, alternative = "greater", max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL)
```

## Arguments

- trajectories:

  A complete native common-grid trajectory set.

- curve:

  Exact source curve ID or zero-based index.

- dimension:

  An explicitly declared source dimension.

- statistic:

  Only largest_lyapunov is supported.

- embedding_dimension:

  Number of delay-coordinate blocks, at least two.

- delay:

  Positive integer observed-sample delay.

- theiler_window:

  Nonnegative sample-unit neighbor exclusion.

- max_horizon:

  Positive integer forward sample horizon.

- fit_start,fit_end:

  Explicit inclusive fit horizon indices.

- delay_units,theiler_window_units,max_horizon_units,fit_units:

  All must be samples; time conversions are not silently approximated.

- method:

  Only iaaft is supported.

- n_surrogates:

  Positive count of independent IAAFT surrogate series.

- alternative:

  greater, less, or two-sided.

- max_iterations:

  Positive IAAFT convergence iteration limit.

- tolerance:

  Positive finite spectral-error-change stopping threshold.

- random_state:

  Optional scoped base-R nonnegative integer random seed; omitted draws
  use current R RNG.

## Value

A native structured result with observed exponent, per-surrogate
exponents, p-value, convergence iterations, spectral errors and
fail-closed provenance.

## Details

IAAFT preserves each observed finite sample value exactly but
approximately matches Fourier amplitude spectrum. The native test uses a
plus-one tail probability, doubles the smaller tail for two-sided
alternatives and raises an error if a declared surrogate fails to
converge. R and NumPy RNG streams are not equivalent. The test is
evidence against the declared linear-stochastic null, not proof of a
unique deterministic chaotic mechanism or causality. Exact source API
parity and sampling calibration have not been certified.
