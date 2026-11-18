# Native R FPCA eigenspace stability, influence and empirical outlier diagnostics

Seven Python-free scientific implementations: weighted principal-angle
subspace comparison, grouped/curve bootstrap stability, one-group-out
influence, component-matched bootstrap diagnostics and explicitly
selected empirical-covariance outlier screening.

## Usage

``` r
etr_compare_fpca_subspaces(reference, candidate, start_component = 0L,
  n_components = 2L)
etr_bootstrap_fpca_subspace_stability(trajectories, start_component = 0L,
  n_components = 2L, n_bootstrap = 200L, scaling = "none",
  resample_unit = "curve", participant_column = NULL, random_state = 0L)
etr_summarise_fpca_subspace_stability(result, interval = c(0.025, 0.975))
etr_leave_one_group_out_fpca_influence(trajectories, group_column = NULL,
  n_components = 3L, scaling = "none")
etr_bootstrap_fpca_stability(trajectories, n_bootstrap = 200L,
  n_components = 3L, scaling = "none", resample_unit = "curve",
  participant_column = NULL, random_state = 0L,
  bootstrap_unit_indices = NULL)
etr_summarise_fpca_stability(result, similarity_threshold = 0.80,
  interval = c(0.025, 0.975))
etr_diagnose_fpca_outliers(result, trajectories, n_components = NULL,
  reconstruction_z_threshold = 3.5, score_alpha = 0.99,
  score_covariance = "robust", random_state = 0L)
```

## Arguments

- reference:

  Native reference FPCA fitted result.

- candidate:

  Native comparison FPCA result with same observed grid and dimensions.

- start_component:

  Zero-based contiguous component-block start.

- n_components:

  Positive component count; NULL uses all fitted components in outlier
  diagnostics.

- trajectories:

  Complete native common-grid functional source trajectories.

- n_bootstrap:

  Nonparametric bootstrap replicate count, at least 2.

- scaling:

  Native FPCA scaling, none or dimension_sd.

- resample_unit:

  Curve or participant-level independent resampling.

- participant_column:

  Source trajectory participant identifier metadata field.

- random_state:

  Scoped base-R seed; NumPy RNG streams are not identical. Unused when
  fixed unit indices are supplied.

- bootstrap_unit_indices:

  Optional list of zero-based source-unit-index vectors, one per
  replicate. Unit indices reference original curves or first- observed
  participant groups. This is a native R deterministic audit extension
  and does not exist in the frozen Python 1.2 public interface.

- result:

  Native stability, influence or FPCA fit, depending on method.

- interval:

  Two increasing quantile levels in \[0,1\].

- group_column:

  Optional group metadata for entire-participant leave-out.

- similarity_threshold:

  Predeclared descriptive absolute cosine threshold in \[0,1\].

- reconstruction_z_threshold:

  Predeclared positive robust-MAD threshold.

- score_alpha:

  Score-space Mahalanobis chi-square quantile in (0,1).

- score_covariance:

  Only explicitly requested empirical covariance is currently
  implemented; robust MCD fails closed.

## Value

Numerical native comparison, influence, stability or review-diagnostics
results or their structured R summary tables.

## Details

All bootstrap and outlier results are descriptive. No automatic
exclusions, continuous-domain inferential coverage, robust MCD
covariance substitution, bitwise R-versus-NumPy seed matching, or
completed 508-source API certification is claimed.
