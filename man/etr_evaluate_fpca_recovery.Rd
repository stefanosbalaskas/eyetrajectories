\name{etr_evaluate_fpca_recovery}
\alias{etr_evaluate_fpca_recovery}
\title{Known-truth FPCA recovery for one unscaled functional component}
\usage{
etr_evaluate_fpca_recovery(result, truth)
}
\arguments{
\item{result}{Explicit source-shaped unscaled FPCA fit with one mode.}
\item{truth}{Retained functional simulation truth with exactly one positive
eigenvalue and matching source curve/time/dimension geometry.}
}
\value{Native source-shaped recovery metric values and provenance, including
weighted mean and covariance ISE, component similarity, score correlation
and RMSE, principal angle, and mean latent curve reconstruction ISE.}
\description{Matches a bounded one-component domain of published Python
1.2.0 FPCA known-truth recovery. It does not silently interpolate truth,
rescale modes, or construct an estimator. The general multi-component
assignment and full typed input/error source contracts are not certified.}
