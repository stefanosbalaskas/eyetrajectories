# Multi-component functional PCA known-truth recovery — native R

**Frozen Python source:** `eyetrajectoriespy==1.2.0`, immutable
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/recovery.py::evaluate_fpca_recovery()`,
`_population_values()` and `_align_components()`.

## Scientific gap closed within an explicitly finite grid domain

The previous R `etr_evaluate_fpca_recovery(result,truth)` supported
only **one fitted and one generating functional component**, while the
frozen Python evaluator supports multiple components, optimal
cross-component matching and weighted principal-angle metrics.
The mapping ledger's callable-name coverage did not convey this
restriction. The native one-component implementation had already
passed developer numerical source tests and is **retained verbatim**.

For a multi-component input, the new
`R/native-fpca-multicomponent-recovery.R` computes:

1. An exact time-grid/dimension/unit-scaled compatibility check
   without interpolation, automatic scaling or re-fitting.
2. Quadrature-weighted normalization of the estimated and true
   functional modes, flattening by **time then dimension** to match
   `numpy.reshape(k,-1)` of `(k,time,dimension)` arrays.
3. Maximum total **absolute** weighted-cosine assignment of each
   estimated mode to one generating mode. The rectangular
   `k_est <= k_truth` case is padded with dummy equal-cost rows
   and solved by the exact cubic-time native Hungarian algorithm
   previously qualified against SciPy.
4. Signed component orientation and matched eigenvalue relative
   errors, mode similarities, score correlations and score RMSE.
   These are matched scientific quantities; raw component indices
   without assignment do not identify latent modes.
5. Source weighted principal cosines using QR orthonormal bases of
   the **weighted functional subspaces**, then SVD; angles reported
   in degrees without inferring confidence coverage.
6. Population mean-function and covariance-operator ISE with the
   source's quadrature tensor weights, plus curve-mean latent
   reconstruction ISE using every retained score/component.

The result retains the source metric name, order, zero-based fitted
component indices and provenance fields
`matched_truth_components` and `alignment_signs`.

## Confirmed design and source boundaries

- Ordinary native R inputs are source-shaped scientific lists,
  not frozen Python `FPCAResult` or
  `FunctionalSimulationTruth` dataclass instances.
- Finite complete-grid observations are required. Nonfinite
  covariance, components and score correlation are rejected.
  Python may return NaN in a constant-score correlation;
  the native scientific subset deliberately fails closed.
- Population covariance uses a dense operator; the multi-mode
  path sets a **2000 flattened-coordinate resource bound** instead
  of silently allocating an unbounded quadratic matrix.
- A tied truth eigenspace requires careful scientific
  identification. The frozen basic FPCA source also uses
  component-level optimal assignment without the specialized tied
  subspace suppression used by the sparse MFPCA evaluator;
  users should not interpret individual rotated modes as unique
  when eigenvalues are exactly or nearly tied.
- SciPy and R can return different permutations under exactly
  tied optimum assignments. Only uniquely identifiable
  assignments or matching optimum scores support index-level
  equality claims.

## Regression and paired source witnesses

`tests/testthat/test-native-fpca-multicomponent-recovery-source.R`
adds four groups:

- Three-mode permuted and sign-flipped generating modes with
  known weighted eigenfunction geometry and zero covariance error.
- The **rectangular two-estimated/three-true** case, including
  expected unmatched truth-mode covariance ISE = 16.
- Adversarial grid, scaling, component counts and zero-norm
  checks; old one-component source tests continue unchanged
  except an updated expected validation message.
- Direct frozen Python 1.2 `evaluate_fpca_recovery` execution
  on exactly the same source arrays, comparing metric
  names/order, zero-based assignments, score/covariance values,
  and sign provenance. Principal angle comparisons have a
  narrow absolute error bound because `acos` is ill-conditioned
  for cosines arbitrarily close to 1.

The new test and source files, existing modified evaluator and
manual are captured by the author's exact-head SHA evidence
inventory, with test filters in both
`native_r_offline` and `python_1_2_direct_source`.

**Qualification pending:** This commit must be executed in RStudio
before it is labeled passing. No independent source certificates
are issued automatically, and the 204 documented unresolved
source-gap exports remain open for full-domain review.
The separate staged CRAN 0.4.2 candidate remains unchanged.
