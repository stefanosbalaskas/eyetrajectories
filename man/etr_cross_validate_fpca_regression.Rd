\name{etr_cross_validate_fpca_regression}
\alias{etr_cross_validate_fpca_regression}
\title{Native leakage-aware Gaussian and binomial FPCR cross-validation}
\usage{
etr_cross_validate_fpca_regression(trajectories, outcome,
  candidate_components = c(1L, 2L, 3L, 4L, 5L),
  family = "gaussian", loss = NULL, covariates = NULL,
  n_splits = 5L, scaling = "none", cv_unit = "curve",
  group_column = NULL, shuffle = FALSE, random_state = 0L,
  fold_assignments = NULL,
  coerce_numeric_text_covariates = FALSE, random_engine = "base_R",
  group_tie_order = "native", strict_source_record = FALSE)
}
\arguments{
\item{strict_source_record}{If TRUE, return the six canonical frozen Python 1.2 scientific provenance fields and require source-compatible fold generation; shuffled curve folds must use \code{random_engine="numpy"}, grouped folds an explicit NumPy tie-order profile, and R-only supplied fold assignments and numeric-text covariate coercion are rejected. The default FALSE preserves native diagnostic provenance. Runtime classes and full exceptional domains are not independently certified.}

\item{coerce_numeric_text_covariates}{Native-only opt-in for finite numeric-text covariate columns (including interdigit underscores). The frozen Python validator parses text but source statsmodels rejects object-typed columns, so FALSE preserves the default source-safe behavior.}
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
\item{shuffle}{Logical flag for shuffled curve folds. Group CV is
deterministic.}
\item{random_state}{Nonnegative integer seed for shuffled curve folds,
ignored for unshuffled or grouped folds. The NumPy engine accepts seeds
up to \eqn{2^{32}-1}.}
\item{group_tie_order}{Grouped sort profile. See
\code{\link{etr_cross_validate_fpca_reconstruction}} for the native,
NumPy SIMD and NumPy scalar options and supported domains. Explicit
fold assignments take precedence.}
\item{random_engine}{\code{"base_R"} retains the original native
shuffle. \code{"numpy"} reproduces scikit-learn's seeded
NumPy RandomState permutation.}
\item{fold_assignments}{Optional complete zero-based integer fold IDs matching a source KFold/GroupKFold result. Grouped units must never straddle folds. This overrides native fold generation without altering fitting or predictions.}
}
\value{Retained fold-loss, assignment and out-of-fold prediction frames
and source-shaped scientific provenance. Group assignments have
an additional `group` label column when grouping is requested.}
\description{Refits FPCA and Gaussian OLS or binomial logit regression inside each
training fold and projects held-out trajectories using only the training
basis. Whole-group held-out folds prevent participant leakage,
while isolated seeded curve folds allow reproducible
sensitivity studies. The grouped sort profile selects the implementation of mixed-size ties. Binomial inference uses
R stats::glm.fit; its IRLS and separation warnings can differ from statsmodels.
Pandas nonnumeric-to-float source-fitting coercions remain outside the default; optional finite text conversion is a native-only extension;
this is not independent full-domain source certification.}
