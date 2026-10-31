\name{etr_nested_cross_validate_fpca_regression}
\alias{etr_nested_cross_validate_fpca_regression}
\title{Nested Gaussian FPCR held-out validation}
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
\item{family}{Only Gaussian.}
\item{loss}{NULL for RMSE, rmse or mae.}
\item{covariates}{Must be NULL.}
\item{outer_splits}{Outer KFold count.}
\item{inner_splits}{Inner KFold count.}
\item{selection_rule}{minimum or one_se.}
\item{scaling}{none or dimension_sd.}
\item{cv_unit}{Must be curve.}
\item{group_column}{Must be NULL.}
\item{shuffle}{Must be FALSE.}
\item{random_state}{Ignored with nonshuffled folds.}
}
\value{Outer fold and inner selection summaries, held-out predictions and provenance.}
\description{Source-bounded nested Gaussian FPCA regression: train all
FPCA components and scalar regression only inside the relevant folds;
evaluate selected pipelines on independent outer held-out trajectories.
Grouped folds, shuffled folds, binomial outcomes, covariates, and
full error/schema domain are not implemented or certified.}
