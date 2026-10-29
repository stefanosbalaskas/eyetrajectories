\name{etr_native_functional_mixed_moments}
\alias{etr_fit_functional_mixed_effects_regression}
\alias{etr_functional_mixed_effects_whitened_residuals}
\alias{etr_functional_mixed_effects_residual_diagnostics}
\alias{etr_functional_mixed_effects_residual_diagnostic_frame}
\alias{etr_functional_mixed_effects_residual_pair_frame}
\alias{etr_functional_mixed_effects_variance_decomposition}
\alias{etr_functional_mixed_effects_coefficient_frame}
\title{Restricted functional repeated-measures moments and residual dependence diagnostics}
\description{Seven Python-free numerical R implementations covering a restricted two-level functional method-of-moments fixed-effects model, covariance-conditional participant random functions, within-curve whitening, exact residual lag diagnostics, residual pairs and source-shaped coefficient/variance auditing.}
\usage{
etr_fit_functional_mixed_effects_regression(trajectories, design, predictors, participant_column, dimension, covariance_ridge = 1e-6)
etr_functional_mixed_effects_whitened_residuals(result)
etr_functional_mixed_effects_residual_diagnostics(result, max_lag, residual_scale = "raw")
etr_functional_mixed_effects_residual_diagnostic_frame(result, level = "trial", curve_id = NULL, participant_id = NULL)
etr_functional_mixed_effects_residual_pair_frame(result, lag_index, curve_id = NULL, participant_id = NULL)
etr_functional_mixed_effects_variance_decomposition(fit, model_label = NULL)
etr_functional_mixed_effects_coefficient_frame(result, band = NULL)
}
\arguments{
\item{trajectories}{Complete native common-grid trajectory set with a selected non-simplex outcome channel.}
\item{design}{One complete numeric predictor row per source curve, aligned by unique curve_id.}
\item{predictors}{Unique names of finite numeric scalar fixed predictors; may be empty for intercept-only.}
\item{participant_column}{Metadata field supplying complete participant identities; requires at least 3 participants with at least 2 curves each.}
\item{dimension}{One explicit response dimension name.}
\item{covariance_ridge}{Positive covariance regularization proportion in (0,1).}
\item{result}{Restricted two-level moments fit or its residual diagnostic object as appropriate.}
\item{max_lag}{Explicit positive index lag strictly less than the number of time points.}
\item{residual_scale}{Raw or within-trial covariance-whitened conditional residuals.}
\item{level}{Trial, participant or overall audit-frame aggregation.}
\item{curve_id}{Optional trial/curve filter where supported.}
\item{participant_id}{Optional participant filter where supported.}
\item{lag_index}{Explicit integer lag within the declared maximum.}
\item{fit}{Restricted two-level functional moments fit.}
\item{model_label}{Optional nonempty model identifier.}
\item{band}{Not supported; only NULL is accepted. No simultaneous mixed-model bands are qualified.}
}
\value{A restricted two-level functional model object, whitened residual matrix, diagnostic result, physical-lag residual pair data frame, variance decomposition, or coefficient table.}
\details{Critical restriction: this model is NOT the spline-based statsmodels MixedLM, Gaussian profiled GLS or REML backend in eyetrajectoriespy 1.2.0. Fixed coefficient functions are independently estimated pointwise with participant-cluster sandwich standard errors. Participant random functions use PSD-projected two-level covariance method-of-moments shrinkage with a declared ridge. Participant covariance and interval calibration are not certified. Random slopes, nested trial effects, residual AR1/exponential correlation likelihood optimization, and simultaneous bands are not provided. The public name mapping is partial source-contract support, never one-to-one equivalence.}