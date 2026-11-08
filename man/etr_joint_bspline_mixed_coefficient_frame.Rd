\name{etr_joint_bspline_mixed_coefficient_frame}
\alias{etr_joint_bspline_mixed_coefficient_frame}
\title{Pointwise coefficient table from a joint B-spline functional mixed model}
\description{Return native R pointwise estimates and normal-Wald intervals for
fitted functional fixed coefficients. Intervals are not simultaneous.}
\usage{
etr_joint_bspline_mixed_coefficient_frame(fit, confidence_level = 0.95)
}
\arguments{
\item{fit}{Result from \code{etr_fit_joint_bspline_functional_mixed_effects()}.}
\item{confidence_level}{Pointwise nominal confidence level, strictly between zero and one.}
}
\value{A data frame with \code{coefficient}, \code{time}, \code{estimate},
\code{se}, \code{lower}, and \code{upper} columns.}
