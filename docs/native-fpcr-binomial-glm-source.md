# Native FPCR: frozen Python 1.2 Bernoulli logit subdomain

**Pinned Python source**: `eyetrajectoriespy==1.2.0`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/prediction.py`:
`_validate_outcome`, `_resolve_loss`, `_loss_value`,
`_fit_predict_regression`, `cross_validate_fpca_regression`,
`nested_cross_validate_fpca_regression`.

## Functional change

The native `etr_cross_validate_fpca_regression` and
`etr_nested_cross_validate_fpca_regression` functions accept
`family="binomial"` with finite **0/1 outcomes**, including logical TRUE/FALSE vectors converted to numeric 1/0 in the same manner as frozen Python's NumPy `dtype=float` conversion. Gaussian CV likewise accepts logical outcomes. The FPCA basis,
binomial-logit coefficients and nested inner retained-FPC selection
are fitted within the relevant **training** folds. Held-out outcomes
are used only for scoring, not for coefficient estimation.

- `loss=NULL` resolves to `log_loss` for binomial data;
  `loss="brier"` uses the mean squared probability error.
  Log loss clips predicted probabilities at R double precision
  machine epsilon just as frozen NumPy source does.
- `stats::glm.fit` fits the Bernoulli logit model using the
  actual training-fold FPCA scores plus any finite numeric/logical
  covariates. Held-out feature rows are projected through the same
  FPCA basis and GLM coefficients. Gaussian OLS remains available
  with RMSE/MAE, with its prior result shape preserved.
- A training fold containing only one response class fails explicitly.
  A nonconverged or nonfinite GLM, and detected near-perfect
  separation, fail rather than silently producing invalid
  probabilities.
- Both ordinary and nested results retain source-shaped fold losses,
  predictions, component counts and provenance with the declared
  `family` and resolved loss.

## Scientific and source limits

Python uses `statsmodels.GLM(..., Binomial()).fit()`; native R
uses `stats::glm.fit`. These are *different numerical backends*,
even when their Bernoulli/logit estimands coincide. Stopping
criteria, convergence, numerical rank decisions and warnings
about (near-)perfect separation can differ, especially for
high-leverage or poorly conditioned data. This implementation
does not claim cross-language result equality outside the
validated finite and nonseparated fixtures.

Native R randomized curve folds still use a base-R RNG
rather than the NumPy RandomState stream. Nonmonotone
mixed-size GroupKFold tie behavior and pandas' permissive
numeric coercion are not claimed source-equivalent. Native
output S3 classes are not Python dataclass identities.

## Evidence and qualification

`tests/testthat/test-native-fpcr-binomial-glm.R` has author-side
tests for per-fold Bernoulli probabilities, Brier and clipped
log losses, leakage rejection by holding out and modifying
labels, group-preserving nested component selection, invalid
domain handling and an opt-in paired frozen Python 1.2
source oracle for predictive and nested tables.

The helper and test files are added to the exact-head
qualification source manifest and both test modes.
**No Windows RStudio run is claimed at authoring time.**
The PR remains unqualified until the owner runs the
registered tests and full source-evidence capture.

No 508-export independent scientific certifications or
source-gap approvals are inferred from this developer-side
implementation, and the existing CRAN candidate was
prepared on an earlier source head.
