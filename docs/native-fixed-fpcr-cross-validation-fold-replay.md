# Native R exact Python 1.2 KFold / GroupKFold replay — developer source contract

Frozen Python source: `eyetrajectoriespy==1.2.0`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`prediction.py` and `selection.py`.

## Implementation

The existing native FPCA reconstruction CV, Gaussian/binomial FPCR CV, and
nested FPCR CV functions now accept optional *zero-based* source fold IDs.
`etr_cross_validate_fpca_regression(..., fold_assignments=)` and
`etr_cross_validate_fpca_reconstruction(..., fold_assignments=)` take one fold
ID per curve in the original data order. Nested CV accepts
`outer_fold_assignments=` in original order and `inner_fold_assignments=` as a
list of inner-fold vectors aligned to the original-order *training subset*
within each outer fold. The original native-R random splitting is unchanged
unless supplied folds are non-NULL. No Python calls occur in R algorithms.

The validator checks positive fold counts, one valid integer fold per curve,
all folds nonempty, and *whole-group confinement* for participant/group CV
at both nesting levels. This enables experimental validation of scikit-learn
shuffled KFold and nonmonotone GroupKFold ties without claiming base R and
NumPy/RandomState streams are identical. All FPCA and supervised regression
fits remain train-fold-only. External fold inputs are scientific parameters,
not a backdoor for test-outcome reuse.

## Test evidence and boundaries

Developer tests replay published Python shuffled Gaussian FPCR folds and
nested component selection, including full fold-loss and out-of-fold prediction
tables, and validate grouped/faulty specifications. Also test reconstruction
CV explicit-fold route. No test changes the public Python 1.2 API.

This is NOT independent third-party scientific certification. Other unresolved
source differences include Python result dataclasses, statsmodels-vs-R binomial
GLM convergence/separation, arbitrary Pandas covariate coercion, and untested
full-domain edge cases. The full 203-callable/1-nonfunction gap ledger stays
open; no unsupported source differences are silently cleared.
