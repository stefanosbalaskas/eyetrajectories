\name{etr_compare_functional_mixed_effects_bootstraps}
\alias{etr_compare_functional_mixed_effects_bootstraps}
\title{Compare fixed-covariance and full-refit mixed functional bands}
\usage{
etr_compare_functional_mixed_effects_bootstraps(
  fixed_covariance_bootstrap,
  full_refit_bootstrap,
  confidence_level = 0.95,
  simultaneous_scope = "coefficient"
)
}
\arguments{
\item{fixed_covariance_bootstrap}{Source-shaped retained conditional
covariance bootstrap.}
\item{full_refit_bootstrap}{Source-shaped retained full-refit bootstrap.}
\item{confidence_level}{Nominal confidence level in (0,1).}
\item{simultaneous_scope}{Either \code{"coefficient"} or \code{"family"}.}
}
\value{One data frame row per coefficient/time observation with fixed
covariance and full-refit band widths and their ratio (infinity when the
fixed-covariance band is zero-width).}
\description{Descriptive comparison of already retained source-model
bootstrap arrays; never fits or selects a model. R value equality of
source-shaped reference objects is not Python's \code{is} object identity
requirement and full source contract certification remains open.}
