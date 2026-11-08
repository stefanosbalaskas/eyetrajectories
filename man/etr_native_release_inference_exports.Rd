\name{etr_native_release_inference_exports}
\alias{etr_bootstrap_fpca_component_envelopes}
\alias{etr_bootstrap_fpca_regression_uncertainty}
\alias{etr_bootstrap_functional_mixed_effects_coefficients}
\alias{etr_bootstrap_functional_mixed_effects_full_refit}
\alias{etr_bootstrap_generalized_function_on_scalar_coefficients}
\alias{etr_fit_elastic_fpca}
\alias{etr_fit_generalized_function_on_scalar_regression}
\alias{etr_fit_sparse_mfpca}
\alias{etr_fpca_wild_bootstrap_projection_family_test}
\alias{etr_functional_mixed_effects_covariance_sensitivity}
\alias{etr_scan_wild_bootstrap_fpca_truncations}
\alias{etr_simulate_functional_scenario}
\alias{etr_wild_bootstrap_fpca_projection}
\title{Native functional estimation, inference and simulation exports}
\description{
Reference index for exported functions in this scientific domain. The
functions are independently callable; scientific scope and input contracts
vary by estimator, data structure, fitted object, and selected backend.
}
\details{
These functions expose explicit native or alternative functional-data model
fits, projection/score uncertainty, simulation and model sensitivity.
Bootstrap and inference functions require their documented experimental
units, fitted source structures, resampling rules and supported numerical
domains. The existence of a source-name mapping is not an independent
full-domain Python 1.2 parity certificate. Review estimator-specific
technical documentation, assumptions and corresponding R/source tests
before scientific reporting; particular uncertainty methods may be
research-only with no external coverage validation.
}
\section{Exported entry points}{
\describe{
\item{\code{etr_bootstrap_fpca_component_envelopes}}{\emph{bootstrap fpca component envelopes} -- descriptive matched-bootstrap FPC pointwise envelopes. Optional \code{bootstrap_unit_indices} provides zero-based fixed curve/participant unit draws for deterministic source replay, without claiming Python NumPy RNG or full-domain parity.}
\item{\code{etr_bootstrap_fpca_regression_uncertainty}}{\emph{bootstrap fpca regression uncertainty} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_bootstrap_functional_mixed_effects_coefficients}}{\emph{bootstrap functional mixed effects coefficients} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_bootstrap_functional_mixed_effects_full_refit}}{\emph{bootstrap functional mixed effects full refit} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_bootstrap_generalized_function_on_scalar_coefficients}}{\emph{bootstrap generalized function on scalar coefficients} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_fit_elastic_fpca}}{\emph{fit elastic fpca} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_fit_generalized_function_on_scalar_regression}}{\emph{fit generalized function on scalar regression} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_fit_sparse_mfpca}}{\emph{fit sparse mfpca} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_fpca_wild_bootstrap_projection_family_test}}{\emph{fpca wild bootstrap projection family test} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_functional_mixed_effects_covariance_sensitivity}}{\emph{functional mixed effects covariance sensitivity} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_scan_wild_bootstrap_fpca_truncations}}{\emph{scan wild bootstrap fpca truncations} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_simulate_functional_process}}{\emph{simulate functional process} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_simulate_functional_scenario}}{\emph{simulate functional scenario} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_wild_bootstrap_fpca_projection}}{\emph{wild bootstrap fpca projection} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
}
}
\value{Each function returns its own documented native R, scientific-model,
bridge, workflow or audit result; no single shared return type is asserted.}
