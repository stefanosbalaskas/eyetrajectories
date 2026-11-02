# Python 1.2 native functional distance source-domain integration

**Frozen source:** `eyetrajectoriespy==1.2.0`, Git commit
`c1cd95ad718327550f7e55393ff38582872f7a94`;
`src/eyetrajectoriespy/analysis.py`.

## Grounded source contracts

- `functional_l2_distance(a,b,time,dimension_weights)` converts its
  two 2D state arrays using `np.asarray(dtype=float)` before checking
  equal shape and missing values, then uses exact trapezoidal quadrature.
- `pairwise_functional_distances` constructs a complete, symmetric,
  unlabelled L2 matrix from validated trajectories and optionally weighted
  functional channels.
- `nearest_trajectory_indices` sorts full pairwise L2 distances using
  `np.argsort`, removes the queried zero-based index, and slices
  `[:n_neighbors]`. Python Boolean `True` is an accepted slice index;
  the floating-point `1.0` is rejected by NumPy.

## Native implementation changes

- `etr_l2_distance(...,python_boundary_mode=TRUE)`: convert complete
  rectangular 2D numeric-string and Boolean point matrices (and
  numeric-compatible 1D dimension weights) into native numeric state
  matrices. Preserve time geometry and the original weighted L2
  estimator; no Python bridge, imputation, interpolation, coercion of
  malformed numeric text, or change to default native strict validation.
  Nonfinite Python arithmetic, nested object coercion, error classes,
  and every possible NumPy dtype are **not** claimed as equivalent.
- `etr_nearest_trajectory_indices(...,python_boundary_mode=TRUE)`:
  reproduce the relevant Python NumPy slice-index domain for
  `n_neighbors`. `TRUE` requests one neighbor; doubles such as
  `1.0` are rejected in compatibility mode. Default native R counts
  remain unchanged. Identical-distance tie ordering is explicitly
  **not certified**: native R sorts by original index, whereas NumPy's
  default unstable sorting may produce a different permutation.
- `etr_pairwise_functional_distances`: numerical source comparisons
  were added for the unchanged complete common-grid implementation,
  including positive, zero-weight, and all-channel cases.

## Actual validation

`tests/testthat/test-native-functional-distance-source-domain.R`
contains four grouped regression cases. When
`ET_RUN_PYTHON_TESTS=true`, the source oracles call all **three real
frozen Python exports** through `etpy_get_export` and compare L2 values,
pairwise matrices, nearest indices on **strictly distinct distances**,
Boolean neighbor count, floating-point index rejection, and
numeric-string state/dimension-weight coercion.

The new file is registered in both native offline and frozen Python
direct-source qualification modes and source evidence inventory.
Previous qualification at R HEAD
`573b6a0cfaf37a599c9960e70d265684165952c1` was PASS:
353 R files parsed, native 245/350 completed unskipped and Python
347/350 completed unskipped.

**Current change status:** committed but **not yet executed in RStudio**.
New first-party checks do not close a 508-export source-gap entry or
create an independent approval. All 204 recorded source-gap exports
and 0/508 independent certificates remain unchanged.

The isolated CRAN candidate
`eyetrajectories_0.4.2_from_bc3c6d140184` remains separately
qualified on Windows with the expected `New submission` NOTE.
The scientific research branch commits are **not included** in that
previously checked tarball.
