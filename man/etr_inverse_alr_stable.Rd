\name{etr_inverse_alr_stable}
\alias{etr_inverse_alr_stable}
\title{Overflow-stable inverse additive log-ratio transformation}
\usage{
etr_inverse_alr_stable(transformed, reference_dimension = -1L,
  n_dimensions = dim(transformed)[3L] + 1L,
  infinite_policy = c("error", "limit"))
}
\arguments{
\item{transformed}{Numeric array of curves by times by K-1 ALR coordinates.}
\item{reference_dimension}{Python-style zero-based reference index; negative indices are from the end.}
\item{n_dimensions}{Number K of simplex components.}
\item{infinite_policy}{Reject infinities by default, or use a limiting softmax; NA and NaN are rejected.}
}
\description{
Uses a per-row log-sum-exp normalization, avoiding overflow in the direct
exponentiation of extreme finite log ratios. This is a native scientific
alternative, not exact Python 1.2 overflow semantics.
}
\value{Numeric array of curves by times by K probability components.}
\examples{
z <- array(c(1, -1, 1000, -1000), dim = c(1, 2, 2))
p <- etr_inverse_alr_stable(z, reference_dimension = -1L)
stopifnot(all(is.finite(p)), all(abs(apply(p, 1:2, sum) - 1) < 1e-12))
}
