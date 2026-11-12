\name{etr_functional_mixed_effects_covariance_sensitivity}
\alias{etr_functional_mixed_effects_covariance_sensitivity}
\title{Sensitivity across predeclared functional mixed-effects covariance structures}
\usage{
etr_functional_mixed_effects_covariance_sensitivity(
    fits, reference, max_lag, specifications = NULL, failures = list(),
    bands = NULL, strict_source_record = FALSE)
}
\arguments{
\item{fits}{Named fitted model mapping. Strict source record requires genuine native joint Gaussian spline likelihood fits. R moment-estimator fits are not compatible with this source-scientific mode.}
\item{reference}{Name of a successful predeclared reference model.}
\item{max_lag}{Positive integer upper lag for within-curve residual diagnostics.}
\item{specifications}{Predeclared covariance structures. Optional for a completely successful fitted model mapping.}
\item{failures}{Named scientific reasons for predeclared failed models.}
\item{bands}{Optional named, already calibrated native mixed simultaneous bands for genuine joint-likelihood fits. The reference band is mandatory when supplying bands; shared confidence level, scope, bootstrap type, number of replicates, and exact participant draw indices are required. Zero reference width gives NaN rather than a false finite ratio.}
\item{strict_source_record}{If TRUE, expose the frozen Python 1.2 \code{FunctionalMixedEffectsCovarianceSensitivityResult} 13 scientific fields, including ordered specifications, reference label, input fit mapping, model and coefficient summaries, covariance components, actual paired-bootstrap simultaneous band-width ratios when supplied, residual diagnostics and provenance.}
}
\value{Native descriptive covariance sensitivity. Strict source mode returns a 13-field source-scientific record.}
\description{Compares already-fitted Gaussian functional mixed models under a shared grid, response and fixed design. Likelihood, same-method information criteria, coefficient differences, covariance-variance decomposition and raw/whitened within-curve residual diagnostics are retained. This function never fits, ranks or selects covariance models and does not perform likelihood-ratio tests. Source Python optimizer identity, arbitrary class coercions and full numerical optimizer parity remain outside this bounded scientific contract.}
