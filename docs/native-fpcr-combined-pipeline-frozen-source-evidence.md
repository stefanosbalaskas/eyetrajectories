# Frozen Python 1.2 paired FPCR: end-to-end external-target numerical replay

## Scientific scope

This is a *developer-owned numerical source-oracle test*, not a new estimator,
independent certificate, or claim that NumPy RNG streams match base R. The
new test reuses the existing native functions without adding a second route:

1. `etr_bootstrap_fpca_regression_uncertainty`: 20 full Gaussian FPCR refits,
   paired outcome resampling of repeated whole participant groups, plus fixed
   **external** target curves and conditional-mean percentile summaries.
2. `etr_fpca_regression_future_prediction_interval`: residual draws from
   Python's separate `SeedSequence.spawn(1)` stream, supplied to R as exact
   zero-based indices, yielding marginal future-outcome (not conditional-mean)
   intervals for the same three external target curves.
3. `etr_fpca_regression_slope_simultaneous_band`: reuse those slope replicates,
   calibrate a dimension-wise observed-grid simultaneous studentized band.
4. Compare all source numerical outputs and both long-form reporting frames.

The existing native algorithms and ordinary base-R RNG defaults are unchanged.
The source helper is patched in the **test-only Python process** to return
predeclared participant draw indices; published estimator code is executed.
The held source version is `eyetrajectoriespy==1.2.0` at
`c1cd95ad718327550f7e55393ff38582872f7a94`.

## Auditable boundaries

- 14 training curves, 7 two-curve participants, with replacement and repeats.
- 20 paired refits, 1 FPCA component, 15 observed time points.
- Three shifted external target curves, kept fixed across bootstrap refits.
- Independently replayed future residual draws, no unsupported RNG identity.
- Source numerical and reporting-table comparisons at `1e-6` tolerance.
- Same source-declared scope of pointwise percentile intervals, marginal
  predictive intervals and observed-grid (not continuous-domain) slope band.

The 203 callable source-gap rows and the separate TrajectorySet nonfunction
remain unresolved. Independent review still requires its own execution and
signatures; this file cannot count as external verification.
