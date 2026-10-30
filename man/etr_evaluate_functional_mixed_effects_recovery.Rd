\name{etr_evaluate_functional_mixed_effects_recovery}
\alias{etr_evaluate_functional_mixed_effects_recovery}
\title{Known-truth functional mixed-effects intercept and variance recovery}
\usage{
etr_evaluate_functional_mixed_effects_recovery(
  result, truth, intercept_name = "Intercept"
)
}
\arguments{
\item{result}{Native source-shaped Gaussian functional mixed-effects fit.}
\item{truth}{Retained functional simulator truth, including exact grid,
mean, eigenfunctions, and participant/trial eigenvalue declarations.}
\item{intercept_name}{Predeclared fixed-intercept name.}
}
\value{An assessment of integrated squared intercept error, participant and
optional trial time-domain variance errors, and exact scientific provenance.}
\description{Evaluates known truth only. Never compares fitted basis
covariance coefficients directly to KL eigenvalues, reinterprets curve-level
functional variation as scalar residual variance, refits or resamples.
Python dataclass and full accepted-domain certification remain open.}
