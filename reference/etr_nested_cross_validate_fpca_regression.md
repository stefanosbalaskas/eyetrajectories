# Nested Gaussian or binomial FPCR held-out validation

Source-bounded nested Gaussian or binomial FPCA regression: train all
FPCA components and scalar regression only inside the relevant folds;
evaluate selected pipelines on independent outer held-out trajectories.
Grouped participant-held-out folds and seeded curve-shuffle folds are
implemented. With grouped CV, both the outer test set and the inner
component selection use whole-participant folds, avoiding train/test
participant leakage. The resulting outer prediction frame retains a
group column. Select the grouped sort profile that matches the source
installation. R glm.fit and Python statsmodels binomial IRLS/separation
details, pandas coercion semantics, and complete Python return and
exception domains remain unsupported and are not independently
certified.

## Usage

``` r
etr_nested_cross_validate_fpca_regression(trajectories, outcome,
  candidate_components = c(1L,2L,3L,4L,5L),
  family = "gaussian", loss = NULL, covariates = NULL,
  outer_splits = 5L, inner_splits = 4L, selection_rule = "minimum",
  scaling = "none", cv_unit = "curve", group_column = NULL,
  shuffle = FALSE, random_state = 0L,
  outer_fold_assignments = NULL, inner_fold_assignments = NULL,
  coerce_numeric_text_covariates = FALSE, random_engine = "base_R",
  group_tie_order = "native", strict_source_record = FALSE)
```

## Arguments

- strict_source_record:

  If TRUE, return the six canonical frozen Python 1.2 scientific
  provenance fields and require source-compatible fold generation;
  shuffled curve folds must use `random_engine="numpy"`, grouped folds
  an explicit NumPy tie-order profile, and R-only supplied fold
  assignments and numeric-text covariate coercion are rejected. The
  default FALSE preserves native diagnostic provenance. Runtime classes
  and full exceptional domains are not independently certified.

- coerce_numeric_text_covariates:

  Native-only opt-in for finite numeric-text covariate columns,
  including interdigit underscores. The frozen Python source statsmodels
  model rejects object-typed columns, so FALSE preserves the default
  source-safe behavior.

- trajectories:

  Complete native common-grid trajectories.

- outcome:

  Finite numeric, logical or decimal numeric-looking character response
  per curve. Logical TRUE/FALSE becomes 1/0; binomial responses must be
  0/1. R factor integer codes are not accepted.

- candidate_components:

  Positive integer retained FPC counts.

- family:

  `"gaussian"` or binary 0/1 `"binomial"`.

- loss:

  Gaussian: rmse (default) or mae; binomial: log_loss (default) or
  brier.

- covariates:

  NULL or curve-aligned finite numeric/logical data.frame. Covariates
  are subset to each outer training fold, then each inner training fold,
  before Gaussian OLS or binomial logit fitting; held-out values are
  used only as fixed prediction features.

- outer_splits:

  Outer KFold count.

- inner_splits:

  Inner KFold count.

- selection_rule:

  minimum or one_se.

- scaling:

  none or dimension_sd.

- cv_unit:

  `"curve"` or `"group"` for independent participant/cluster holdout in
  both outer evaluation and inner selection.

- group_column:

  Required metadata column for grouped folds; every curve from one group
  remains within a single fold.

- shuffle:

  Logical flag for shuffled curve folds. Grouped folds are
  deterministic.

- random_state:

  Nonnegative integer seed for shuffled curve folds. Each inner seed is
  the outer seed plus the zero-based outer fold index plus one. With the
  NumPy engine every seed must fit in an unsigned 32-bit integer.

- group_tie_order:

  Grouped sort profile. See
  [`etr_cross_validate_fpca_reconstruction`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_native_cv_uncertainty.md)
  for the native, NumPy SIMD and NumPy scalar options and supported
  domains. Explicit fold assignments take precedence.

- random_engine:

  `"base_R"` retains the original native shuffle. `"numpy"` reproduces
  scikit-learn's seeded NumPy RandomState permutations at both levels.

- outer_fold_assignments:

  Optional one zero-based fold ID per original trajectory; all outer
  folds must occur and grouped units cannot split.

- inner_fold_assignments:

  Optional list of length outer_splits; for each outer fold, zero-based
  inner fold IDs align with its original-order training subset. Group
  leakage is rejected at both levels.

## Value

Outer fold and inner selection summaries, held-out predictions and
provenance.
