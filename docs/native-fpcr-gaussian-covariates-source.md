# Source-scoped Gaussian FPCR covariates: native R expansion

**Pinned source:** `eyetrajectoriespy==1.2.0`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/prediction.py`: `_validate_covariates`,
`_design_matrix`, `_fit_predict_regression`,
`cross_validate_fpca_regression`,
`nested_cross_validate_fpca_regression`.

## New native domain

- An optional R `data.frame` with exactly one row per trajectory and
  uniquely named finite numeric or logical columns can now be supplied
  to both Gaussian native regression CV functions.
- Covariate column names `const` and `FPC<digits>` are rejected to
  match the frozen source's reserved design-matrix names.
- A shared validator converts covariates positionally to a finite
  double matrix; row names are ignored in the modeling path.
- Fold-specific Gaussian OLS designs have columns
  `[intercept, FPC1 ... FPCk, covariates]`; the FPC basis is fitted
  only using training trajectories. Regression coefficients are fitted
  only with training outcomes. Held-out covariate values are used solely
  for held-out prediction, not coefficient estimation.
- In nested CV, covariates first follow the outer training subset and
  then the inner training folds; the final outer regression uses only
  outer-training outcomes. The feature matrix is not standardized or
  imputed globally.
- The R return object's provenance names the included covariates.
  Existing no-covariate behavior is preserved.

## Source limitations (not full one-to-one certification)

This bounded change does **not** implement binomial GLM, sklearn NumPy
RandomState seed parity, full sklearn GroupKFold equal-size tie handling,
or Python dataclass type identity. R numeric/logical data frames are
accepted; pandas' more permissive dtype coercions (e.g. numeric-looking
string columns) are not claimed equivalent. Near-singular numerical
rank decisions may differ between R QR and NumPy SVD tolerances.
No success on the whole frozen export domain or independent scientific
certification is claimed.

## Evidence

`tests/testthat/test-native-fpcr-gaussian-covariates.R` includes:

1. Fold-local Gaussian regression with a nontrivial numeric covariate.
2. Held-out outcome perturbation: own-fold predictions and nested
   component selection must not depend on own held-out outcomes.
3. Group-held-out nested loss and prediction consistency.
4. Rejection of duplicated names, reserved names, wrong row counts,
   nonnumeric columns, factors, missing and infinite values, and
   rank-deficient regressors.
5. Opt-in paired frozen Python 1.2 exported grouped regression and
   nested regression comparisons using distinct participant-group
   sizes to avoid known GroupKFold tie ambiguity.

The new test file is registered in both offline R and direct Python
source qualification modes, alongside the added R source, manuals, and
this documentation file in the evidence manifest. These remain
**developer-side qualification**, not independent full-domain
certificate decisions.

**QA status before the owner executes qualification:** not yet
confirmed in Windows RStudio. All new tests and direct Python oracle
tests must pass before the PR is merged or source-gap triage is changed.
