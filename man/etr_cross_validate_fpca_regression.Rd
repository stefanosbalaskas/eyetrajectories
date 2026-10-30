\name{etr_cross_validate_fpca_regression}
\alias{etr_cross_validate_fpca_regression}
\title{Native leakage-aware Gaussian FPCR cross-validation}
\usage{
etr_cross_validate_fpca_regression(trajectories, outcome,
  candidate_components = c(1L, 2L, 3L, 4L, 5L),
  family = "gaussian", loss = NULL, covariates = NULL,
  n_splits = 5L, scaling = "none", cv_unit = "curve",
  group_column = NULL, shuffle = FALSE, random_state = 0L)
}
\arguments{
\item{trajectories}{Complete native common-grid trajectory set.}
\item{outcome}{Curve-aligned finite Gaussian scalar outcomes.}
\item{candidate_components}{Positive integer retained FPC counts.}
\item{family}{Only \code{"gaussian"} for this bounded source subset.}
\item{loss}{\code{"rmse"} or \code{"mae"}, default RMSE.}
\item{covariates}{Must be NULL; covariate models not yet supported.}
\item{n_splits}{Unshuffled curve-wise KFold partition count.}
\item{scaling}{One of \code{"none"} or \code{"dimension_sd"}.}
\item{cv_unit}{Must be \code{"curve"}; group CV not yet supported.}
\item{group_column}{Must be NULL.}
\item{shuffle}{Must be FALSE; sklearn RNG parity not implemented.}
\item{random_state}{Ignored for deterministic unshuffled folds.}
}
\value{Retained fold-loss, assignment and out-of-fold prediction frames
and source-shaped scientific provenance.}
\description{Refits FPCA and Gaussian scalar regression inside each
training fold and projects held-out trajectories using only the training
basis. This source-aligned native subset does not support grouping,
shuffling, binomial regression or covariates, and is not a full-domain
one-to-one source certification.}
