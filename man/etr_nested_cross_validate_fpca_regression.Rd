\name{etr_nested_cross_validate_fpca_regression}
\alias{etr_nested_cross_validate_fpca_regression}
\title{Nested Gaussian or binomial FPCR held-out validation}
\usage{
etr_nested_cross_validate_fpca_regression(trajectories, outcome,
  candidate_components = c(1L,2L,3L,4L,5L),
  family = "gaussian", loss = NULL, covariates = NULL,
  outer_splits = 5L, inner_splits = 4L, selection_rule = "minimum",
  scaling = "none", cv_unit = "curve", group_column = NULL,
  shuffle = FALSE, random_state = 0L)
}
\arguments{
\item{trajectories}{Complete native common-grid trajectories.}
\item{outcome}{Finite scalar response per curve.}
\item{candidate_components}{Positive integer retained FPC counts.}
\item{family}{\code{"gaussian"} or binary 0/1 \code{"binomial"}.}
\item{loss}{Gaussian: rmse (default) or mae; binomial: log_loss (default) or brier.}
\item{covariates}{NULL or curve-aligned finite numeric/logical data.frame.
Covariates are subset to each outer training fold, then each inner
training fold, before Gaussian OLS or binomial logit fitting; held-out values are used only
as fixed prediction features.}
\item{outer_splits}{Outer KFold count.}
\item{inner_splits}{Inner KFold count.}
\item{selection_rule}{minimum or one_se.}
\item{scaling}{none or dimension_sd.}
\item{cv_unit}{\code{"curve"} or \code{"group"} for independent
participant/cluster holdout in both outer evaluation and inner selection.}
\item{group_column}{Required metadata column for grouped folds;
every curve from one group remains within a single fold.}
\item{shuffle}{Logical curve-fold shuffle using isolated native R
RNG; grouped folds are deterministic even if \code{shuffle=TRUE}.}
\item{random_state}{Nonnegative integer R seed for shuffled curve
folds; inner seeds use the source offsets outer_fold + 1. R and
sklearn NumPy RandomState shuffle permutations are not identical.}
}
\value{Outer fold and inner selection summaries, held-out predictions and provenance.}
\description{Source-bounded nested Gaussian or binomial FPCA regression: train all
FPCA components and scalar regression only inside the relevant folds;
evaluate selected pipelines on independent outer held-out trajectories.
Grouped participant-held-out folds and seeded curve-shuffle folds
are implemented. With grouped CV, both the outer test set and the
inner component selection use whole-participant folds, avoiding
train/test participant leakage. The resulting outer prediction
frame retains a group column. Nonmonotone GroupKFold ties and
R versus NumPy RNG streams can differ. R glm.fit and Python statsmodels
binomial IRLS/separation details, pandas coercion semantics, and complete
Python return and exception domains
remain unsupported and are not independently certified.}
