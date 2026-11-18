# Stage 10 native R compositional FPCA and scientific diagnostics

Python-free functional PCA, reconstruction, component matching,
registration sensitivity, eigenvalue gaps and descriptive reporting.
Implementations await independent source-equivalence qualification.

## Usage

``` r
etr_fit_compositional_fpca(trajectories, reference_dimension = -1L,
  epsilon = 1e-8, n_components = 0.95, scaling = "none")
etr_reconstruct_compositional_fpca(result, scores = NULL, n_components = NULL)
etr_component_similarity_matrix(reference, candidate, n_components = NULL)
etr_match_fpca_components(reference, candidate, n_components = NULL)
etr_reconstruction_error_by_curve(result, trajectories, n_components = NULL)
etr_fpca_reconstruction_curve(result, trajectories)
etr_compare_registered_unregistered_fpca(registration, n_components = 3L,
  scaling = "none")
etr_registration_sensitivity_frame(result)
etr_summarise_trajectory_set(trajectories)
etr_summarise_fpca(result)
etr_fpca_reporting_text(result, digits = 1L)
etr_fpca_eigenvalue_gap_table(result, relative_gap_threshold = NULL)
etr_fpca_eigengap_reporting_text(result, relative_gap_threshold = NULL, digits = 3L)
etr_registration_sensitivity_reporting_text(result, digits = 2L)
etr_functional_mean_band_frame(result)
```

## Arguments

- trajectories:

  A native common-grid complete trajectory set, or the fitted original
  sample for reconstruction diagnostics.

- reference_dimension:

  Zero-based Python-style ALR reference index; -1 selects the last
  dimension.

- epsilon:

  Positive probability clipping floor in the compositional log ratio.

- n_components:

  Fitted component count; NULL uses all available components. For
  compositional fitting a variance fraction is also accepted.

- scaling:

  Native FPCA channel scaling method.

- result:

  A compatible native FPCA, compositional FPCA, registration sensitivity
  or functional mean-band result.

- scores:

  Optional finite replacement FPCA score matrix.

- reference:

  Reference native FPCA fit.

- candidate:

  Candidate native FPCA fit with same grid and dimensions.

- registration:

  Native registered and original trajectories.

- digits:

  Requested reporting decimal places, integer from 0 to 15.

- relative_gap_threshold:

  Optional pre-specified descriptive near-tie threshold in \[0,1).

## Value

Numeric array, matrix, component-matching list, diagnostic data frame,
reporting text or native compositional FPCA result, according to the
function.

## Details

Exact native maximum-weight component matching uses the historical
subset dynamic program for up to 12 components and an exact cubic-time
Hungarian assignment for larger fitted bases. Both optimize the absolute
integrated component similarity; tied optimum permutations need not
agree with SciPy tie choices. Diagnostic frames do not supply
inferential guarantees. Scientific full-source and 508-export
independent contract qualification remain pending.
