# Sparse FPCA score-distance domain: frozen Python 1.2 vs native R

Pinned Python source: `eyetrajectoriespy==1.2.0` at
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/analysis.py::score_distance_matrix`.

Published Python checks `n_components` and dispatches
`sklearn.metrics.pairwise_distances(fpca.scores[:, :n_components],
metric="euclidean")`. A SciPy CSR/CSC score matrix can therefore
remain sparse until the output distances are materialized.

The previous native `etr_score_distance_matrix(...,
python_boundary_mode=TRUE)` branch accepted `Matrix` sparse input
only by `as.matrix()` conversion, and imposed a fixed **two million
input-cell limit**. It rejected valid, extremely wide but very sparse
FPCA score arrays before the scientific calculation.

## Updated bounded native algorithm

- Validate sparse slot entries, matrix shape and declared score count
  without converting the full score array to a dense base R matrix.
- Compute Euclidean score distances from row squared norms and
  `Matrix::tcrossprod` on the retained sparse component slice.
- Clamp tiny negative squared distances from floating-point cancellation
  to zero and enforce a zero diagonal and numerical symmetry.
- Limit the final dense n-curves-by-n-curves distance result to at most
  five million cells; source SciPy/scikit-learn does not share this
  exact resource limit.
- Preserve the legacy dense R path, all original strict native input
  requirements and Python-style Boolean/integer count slicing in the
  explicit `python_boundary_mode`. `Matrix` remains under `Suggests`,
  not `Imports`; ordinary native R use needs no Matrix installation.

## Reproducible source witnesses

`tests/testthat/test-native-sparse-score-distance-source.R`
covers direct native distances, dense-vs-sparse numeric equivalence,
pattern/logical sparse matrices, nonfinite stored entries, a bounded
output guard, and a **4 × 600,001** score matrix with only five
stored nonzero values. This matrix exceeds the previous input-cell
threshold yet requires a 4 × 4 distance output.

The optional frozen Python test invokes the actual
`eyetrajectoriespy.score_distance_matrix` export with a
`scipy.sparse.csr_matrix` embedded in a Python score-bearing object,
including first-component slicing. With no Python installation,
the offline R tests remain meaningful and Python oracles skip explicitly.

The same wide CSR fixture was checked by the development environment
against scikit-learn's Euclidean `pairwise_distances`, giving the
symmetric reference values sqrt(30), sqrt(35), sqrt(42),
sqrt(13), sqrt(20), sqrt(25) above the diagonal.

## Certification status

This work increases practical native sparse source-domain coverage.
It **does not** establish arbitrary scipy sparse class equivalence,
all floating-point boundary semantics, Python-type serialization or
full-domain independent certification. The existing
`score_distance_matrix` source-gap row remains open, and the
**204 recorded source-gap exports and 0/508 independent signed
certificates** are unchanged.
