\name{etr_cross_validate_fpca_regression}
\alias{etr_cross_validate_fpca_regression}
\title{Native leakage-aware Gaussian and binomial FPCR cross-validation}
\usage{
etr_cross_validate_fpca_regression(trajectories, outcome,
  candidate_components = c(1L, 2L, 3L, 4L, 5L),
  family = "gaussian", loss = NULL, covariates = NULL,
  n_splits = 5L, scaling = "none", cv_unit = "curve",
  group_column = NULL, shuffle = FALSE, random_state = 0L)
}
\arguments{
\item{trajectories}{Complete native common-grid trajectory set.}
\item{outcome}{Curve-aligned finite numeric, logical, or decimal numeric-looking character outcomes. Logical TRUE/FALSE becomes numeric 1/0; binomial responses must be 0/1. R factors are not converted to their integer codes.}
\item{candidate_components}{Positive integer retained FPC counts.}
\item{family}{\code{"gaussian"} or \code{"binomial"} for Bernoulli logistic regression.}
\item{loss}{Gaussian: \code{"rmse"} (default) or \code{"mae"}. Binomial: \code{"log_loss"} (default) or \code{"brier"}.}
\item{covariates}{NULL or a curve-aligned data.frame of finite numeric or
logical covariate columns. Names must be unique and must not collide with
\code{const} or reserved \code{FPC} score names. Columns are included
in the Gaussian OLS or binomial logit model fitted inside each training fold and in matching held-out predictions.}
\item{n_splits}{KFold or GroupKFold partition count, from two up to
the number of curves or unique groups respectively.}
\item{scaling}{One of \code{"none"} or \code{"dimension_sd"}.}
\item{cv_unit}{\code{"curve"} or \code{"group"}; group CV excludes
every curve from a held-out participant/group from training folds.}
\item{group_column}{Metadata column containing group identifiers;
required for \code{cv_unit="group"}.}
\item{shuffle}{Logical flag. With curve CV, use native seeded R
shuffle; group CV is deterministic irrespective of this flag.}
\item{random_state}{Nonnegative integer base-R seed for shuffled
curve folds, ignored for unshuffled or grouped folds. Base-R random
permutations cannot be equated with sklearn's NumPy RandomState.}
}
\value{Retained fold-loss, assignment and out-of-fold prediction frames
and source-shaped scientific provenance. Group assignments have
an additional `group` label column when grouping is requested.}
\description{Refits FPCA and Gaussian OLS or binomial logit regression inside each
training fold and projects held-out trajectories using only the training
basis. Whole-group held-out folds prevent participant leakage,
while isolated native-R shuffled curve folds allow reproducible
sensitivity studies. Nonmonotone GroupKFold tie ordering and shuffled
NumPy permutations remain implementation-specific. Binomial inference uses
R stats::glm.fit; its IRLS and separation warnings can differ from statsmodels.
Pandas nonnumeric-to-float covariate coercions remain outside this subset;
this is not independent full-domain source certification.}
