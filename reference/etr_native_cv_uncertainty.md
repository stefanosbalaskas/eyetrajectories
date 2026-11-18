# Stage 12 native R FPCA cross-validation and uncertainty-result frames

Python-free leakage-aware functional PCA cross-validation with explicit
component selection and deterministic adapters for previously computed
uncertainty and prediction results.

## Usage

``` r
etr_cross_validate_fpca_reconstruction(trajectories,
  candidate_components = c(1L, 2L, 3L, 4L, 5L), n_splits = 5L, scaling = "none",
  cv_unit = "curve", group_column = NULL, shuffle = TRUE, random_state = 0L,
  fold_assignments = NULL, random_engine = "base_R", group_tie_order = "native")
etr_summarise_fpca_cross_validation(result)
etr_select_fpca_components_cv(result, rule = "minimum")
etr_summarise_fpca_regression_cv(result)
etr_select_fpca_regression_components(result, rule = "minimum")
etr_fpca_score_uncertainty_frame(result)
etr_fpca_spectrum_uncertainty_frame(result)
etr_conformal_fpca_anomaly_frame(result)
etr_trajectory_distance_comparison_frame(result)
etr_trajectory_distance_neighbor_frame(result)
etr_fpca_regression_slope_band_frame(result)
etr_fpca_regression_slope_uncertainty_frame(result)
etr_fpca_regression_prediction_uncertainty_frame(result)
etr_fpca_regression_future_prediction_frame(result)
```

## Arguments

- trajectories:

  Complete native common-grid curves.

- candidate_components:

  Positive integer counts, deduplicated and sorted.

- n_splits:

  Number of held-out partitions, at least two.

- scaling:

  Declared functional channel scaling.

- cv_unit:

  Use curve-level or group-level partitioning.

- group_column:

  Required metadata column for grouped holdouts.

- shuffle:

  Whether to shuffle curve order prior to fold assignment.

- random_state:

  Nonnegative integer seed for the selected shuffle engine.

- group_tie_order:

  Grouped sort profile. Use `"numpy_simd"` or `"numpy_scalar"` for the
  corresponding NumPy 2.3.5 integer sort used by scikit-learn
  GroupKFold. `"native"` uses the original R group policy. Explicit
  `fold_assignments` take precedence.

- random_engine:

  `"base_R"` retains the original native shuffle. `"numpy"` reproduces
  scikit-learn's seeded NumPy RandomState permutation for seeds up to
  \\2^{32}-1\\.

- fold_assignments:

  Optional numeric vector of zero-based source-fold IDs, one per curve;
  all declared folds must occur and grouped curves may not be split.
  Replays externally observed folds without invoking Python.

- result:

  Native FPCA CV object, declared regression CV object or a
  source-shaped, previously computed uncertainty structure.

- rule:

  Explicit minimum or one-standard-error heuristic.

## Value

Native FPCA cross-validation result, a component count, or an auditable
R data frame, according to the function.

## Details

Functional PCA is refitted only on each fold's training sample and
evaluated on held-out curves. The NumPy profiles order supported scalar
metadata labels as pandas strings in Unicode order. The SIMD profile
supports up to 256 groups with mixed-order tied counts, and any number
with already sorted or distinct counts. Supply explicit fold assignments
for larger mixed-order tied SIMD cohorts. The scalar profile follows
NumPy introsort, including its unstable ties. Choose the profile used by
the source installation. Other helpers organize preexisting uncertainty
results without calculating new bootstrap intervals or certifying
coverage. The 508 public Python source-contract gate remains closed.
