# Native multivariate IAAFT surrogates with shared Fourier constraints

Imposes the published reference-anchored multivariate Fourier phase
constraints with iterative marginal rank remapping. The output records
approximate cross-spectrum agreement after rank remapping. The seeded
and supplied initialization paths run entirely in R.

## Usage

``` r
etr_generate_multivariate_iaaft_surrogates(trajectories, curve, dimensions,
  reference_dimension, n_surrogates = 199L, max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL, initial_permutations = NULL,
  phase_replay = NULL, python_boundary_mode = FALSE)
```

## Arguments

- trajectories:

  Complete regular-grid native trajectory set.

- curve:

  Source curve ID or zero-based source index.

- dimensions:

  At least two selected channel names in requested order.

- reference_dimension:

  Explicit selected reference channel.

- n_surrogates:

  Number of rank-matched surrogate matrices.

- max_iterations:

  Maximum Fourier/rank remapping iterations.

- tolerance:

  Positive absolute change tolerance for combined spectral error.

- random_state:

  Integer seed for NumPy-compatible PCG64 permutations, or NULL for
  unseeded native R draws.

- initial_permutations:

  Optional integer-valued zero-based three-dimensional array of shape
  (n_surrogates, n_time, n_selected_dimensions), containing complete
  initial time-index permutations for every surrogate and channel.

- phase_replay:

  Optional named list with `target`, a
  `(floor(n_time/2) + 1, n_selected_dimensions)` matrix, and/or
  `reference`, a list with one entry per surrogate. Each reference entry
  is NULL or a matrix with one row per iteration and one column per
  Fourier bin. Entries are radians in \\\[-\pi, \pi\]\\ or NA to keep
  the native phase. Channel and bin order match the selected dimensions
  and the real half spectrum. The first row of a reference matrix is the
  phase during the first iteration. Supplied values after convergence
  cause an error.

- python_boundary_mode:

  If TRUE, use the declared source boundary semantics; FALSE preserves
  native validation defaults.

## Value

Native multivariate IAAFT source-shaped surrogate array, exact empirical
marginals, spectral/cross-spectral residual errors, convergence counts
and scientific provenance.

## Details

Phase replay supports reproducible comparison at Fourier bins where the
phase is numerically unresolved. In each channel the allowed amplitude
is at most eight times the ceiling of the base-two logarithm of the
sample count times double machine epsilon times the largest Fourier
amplitude. DC and the even-length Nyquist bin retain their original real
coefficients. With no replay, the algorithm uses native Fourier phases.
Replay leaves amplitudes, stable rank remapping, spectral diagnostics
and convergence evaluation native. Near-zero cross-spectrum norms can
make relative errors sensitive to the Fourier backend even with phase
replay. Provenance records the affected zero-based target reference bins
and the number of replayed target and reference phases.
