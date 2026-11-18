# Native R functional transformations and scientific diagnostics

Twelve Python-free implementations of selected eyetrajectoriespy 1.2.0
functional transformations, distance summaries and phase diagnostics.
Native R implementations have been authored; comprehensive one-to-one
Python contract equivalence has not been established.

## Usage

``` r
etr_alr_transform(values, reference_dimension = -1L, epsilon = 1e-8,
  python_boundary_mode = FALSE)
etr_inverse_alr(transformed, reference_dimension, n_dimensions,
  python_boundary_mode = FALSE)
etr_component_trajectories(result, component, sd_multipliers = c(-2, -1, 0, 1, 2))
etr_select_n_components(result, threshold = 0.95)
etr_fpca_score_frame(result, prefix = "FPC")
etr_score_distance_matrix(fpca, n_components = NULL,
  python_boundary_mode = FALSE)
etr_pairwise_functional_distances(trajectories, dimension_weights = NULL)
etr_sparse_dimension_summary(trajectories, dimension)
etr_warping_displacement(result)
etr_phase_summary(result)
etr_phase_trajectory_set(registration, representation = "displacement")
etr_fit_phase_fpca(registration, representation = "displacement",
                   n_components = 0.95)
```

## Arguments

- values:

  Three-dimensional numeric array of compositional probabilities. In
  explicit Python boundary mode, a complex atomic 3D ndarray-style input
  is cast to its real component as NumPy's dtype=float conversion does.
  Regular mixed-type Python-style nested scalar lists, including Boolean
  leaves, use elementwise rather than whole-container R coercion.

- reference_dimension:

  Python-style zero-based reference component; -1 selects the last. In
  Python boundary mode a Boolean reference index is converted to 0 or 1,
  matching Python integer-index behavior.

- epsilon:

  Strictly positive clipping floor for ALR, declared before analysis.

- python_boundary_mode:

  Logical, opt-in Python 1.2 boundary validation where implemented; the
  default FALSE retains the native R input domain. For ALR and inverse
  ALR, preserves 3D output shape when the curve or time axis is empty,
  matching frozen Python 1.2 source semantics. It also accepts complex
  ndarray-style 3D input after discarding imaginary coordinates and
  Boolean reference indices. In inverse ALR it requires an integer
  storage-type dimension count as NumPy does when constructing an output
  shape; nonfinite source exponentiation is propagated rather than
  rejected. For score-distance matrices, sparse Matrix inputs use native
  sparse row norms and Gram products, with a dense output of no more
  than five million cells. In explicit Python boundary mode, minimal
  duck-typed FPCA score objects may declare more components than their
  score matrix actually contains: a requested integer slice uses the
  available columns, matching NumPy; a fractional declared count
  requires an explicit integer slice count. In score-distance source
  mode, dense and sparse matrices use scikit-learn-style squared norms
  and Gram products and can return Inf or NaN from numerical overflow,
  or lose tiny distances through cancellation. Strict native R mode
  retains the more stable
  [`stats::dist`](https://rdrr.io/r/stats/dist.html) computation. Strict
  default native FPCA-object validation is preserved. This flag does not
  invoke Python or certify full-domain equivalence.

- transformed:

  Finite three-dimensional ALR values in the strict default mode. In
  Python boundary mode, complex ndarray values are cast to real and
  NaN/Inf logarithms use source arithmetic.

- n_dimensions:

  Original number of channels, at least one. The NumPy source-mode shape
  contract accepts integer scalars, not Boolean or floating-point
  scalars, even if numerically integral.

- result:

  A native FPCA fit or registration result, as appropriate.

- component:

  Zero-based index of a fitted FPCA component.

- sd_multipliers:

  Finite standard deviation multipliers for component curves.

- threshold:

  Cumulative explained variance threshold in (0, 1\].

- prefix:

  Component score column prefix.

- fpca:

  Native fitted FPCA object, or a minimal validated score-bearing list.
  With `python_boundary_mode=TRUE`, accepts Matrix-package sparse score
  matrices without densification of the input; Matrix remains optional
  for ordinary native use.

- n_components:

  Number of retained FPCA components or requested variance fraction, as
  appropriate.

- trajectories:

  Native complete common-grid or irregular trajectory set, depending on
  the diagnostic.

- dimension_weights:

  Optional nonnegative spatial-channel weights.

- dimension:

  Name of one irregularly sampled dimension.

- registration:

  Native registration with original trajectories and reference-to-source
  warpings.

- representation:

  Either "displacement" or "warping".

## Value

A matrix, array, data frame, list, native trajectory set, or native FPCA
fit according to the selected function. All paths are Python-free.

## Details

The ALR clipping threshold, target component count, registration
orientation and finite-observation support must be specified and
recorded. Python result dataclass identity and generalized inference are
not claimed.
