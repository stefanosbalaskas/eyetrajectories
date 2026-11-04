# Group-isolated and seeded-fold native FPCR prediction cross-validation

**Frozen source:** `eyetrajectoriespy==1.2.0` SHA
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/prediction.py`:
`_make_splits`, `cross_validate_fpca_regression`,
`nested_cross_validate_fpca_regression`.

## Scientific change

The existing native regression CV and nested CV originally
supported only Gaussian models on unshuffled per-curve folds,
even though the lower-level native reconstruction CV already
implemented independent group partitioning and seeded curve
shuffle. They now invoke the existing vetted native
`.etr_cv_fold_assignment` with explicit fold policy.

### Grouped cross-validation

`cv_unit="group",group_column="participant"` takes nonmissing
participant IDs from the trajectory metadata, assigns each
group to **exactly one test fold**, and fits the FPCA
components and Gaussian scalar-outcome regression on curves
from the other groups. Out-of-fold test scores are projected
using **the training-only FPCA basis**. A group is never
simultaneously present in training and held-out test data.

Each source-shaped `assignments` frame includes the
`group` label; `provenance$group_leakage_prevented`
is TRUE. Folds are deterministic and ignore shuffle and
random_state, as in source GroupKFold. The native R now reproduces the frozen sklearn GroupKFold fold
assignment for **all-equal-sized** groups by visiting sorted labels in
reverse order before greedy lightest-fold allocation. The bounded
source-aligned behavior is directly tested for six equal-sized groups.
For groups with **unequal sizes and ties within size strata**, NumPy's
default argsort/Quicksort tie behavior can still differ from the
native deterministic label order. The direct previously existing
paired oracle tests use **distinct group sizes**; the added source
oracle covers the all-equal-size case. This is not full-domain
GroupKFold certification.

### Shuffled curve folds

For `cv_unit="curve",shuffle=TRUE`, the method uses
`sample()` with the explicitly declared nonnegative integer
`random_state`. The global R RNG state is restored exactly;
repeated calls at the same native seed produce identical
assignments, component fits and held-out predictions.
Native R and NumPy/scikit-learn random generators use
different algorithms (native R versus sklearn NumPy RandomState).
The same seed therefore is **not**
asserted to reproduce the same Python fold permutation.
For `shuffle=FALSE`, prior deterministic sklearn KFold
block-assignment and existing Gaussian prediction values
remain unchanged.

### Nested predictive selection

`etr_nested_cross_validate_fpca_regression` now
propagates group CV to **both** outer held-out performance
and inner retained-component selection. In grouped mode,
the original metadata is subset with the training curves,
so inner folds only use groups remaining in the
corresponding outer training set. The outer prediction
table includes the held-out `group` label. This prevents
a participant appearing in the outer training fold while
that participant's curves are held out, and also prevents
inner selection leakage. The original one-standard-error
and minimum-loss selection rules remain unchanged.

For shuffled curve CV, outer fold assignment uses the
declared native seed and the inner selection uses the
source offset `random_state + outer_fold + 1`, with
isolated R random states. This does not imply identical
NumPy random streams or fold outcomes on the same
random_state.

## Scientific evidence and tests

`tests/testthat/test-native-fpcr-regression-fold-domains.R`
includes native held-out group validation, deterministic
native shuffle and global RNG restoration, invalid group
metadata and split domain checks, independently recomputed
per-fold RMSE from held-out predictions, grouped nested
CV selection with outer outcome perturbation proving
**no outer-label leakage**, and shuffled nested
repeatability. Paired source tests invoke actual
frozen Python 1.2 exported predictive and nested
regression CV for **unequal group sizes** and compare
full fold-loss, assignment, prediction and inner
selection tables.

Source-scoped statistical limitations remain explicit:
Gaussian scalar regression only; numeric Gaussian covariates
are supported in the source-scoped subset (see
`native-fpcr-gaussian-covariates-source.md`); no binomial family, no guaranteed sklearn mixed-size group-tie
ordering, no sklearn NumPy RandomState seed equivalence,
and no Python dataclass identity. Participant grouping
prevents leakage but does not in itself fit a
within-participant residual correlation model or
equalize participant weights. Full scientific
export certification remains unsigned.

Both native offline and frozen Python 1.2 qualification
modes have the source test filter registered; test,
implementation, manuals and this document are included
in the developer exact-head evidence manifest.
**No Windows RStudio runtime PASS is claimed for the
new research HEAD until the owner runs the qualifier.**
The previously qualified HEAD stays valid. The
separately checked CRAN 0.4.2 candidate is unchanged.
