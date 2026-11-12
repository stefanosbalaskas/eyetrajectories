\name{etr_bootstrap_functional_mixed_effects_full_refit}
\alias{etr_bootstrap_functional_mixed_effects_full_refit}
\title{Whole-participant Gaussian functional mixed-effects full-refit bootstrap}
\usage{
etr_bootstrap_functional_mixed_effects_full_refit(
    result, n_bootstrap = 1000L, random_state = 0L,
    sampled_participant_indices = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native jointly fitted functional spline mixed-effects likelihood model. Strict mode excludes timewise moments estimators.}
\item{n_bootstrap}{Number of participant-case refits, with a minimum supported full-refit sample count of 20.}
\item{random_state}{Integer seed for source NumPy PCG64-compatible participant draws.}
\item{sampled_participant_indices}{Optional explicit zero-based native R bootstrap draws. Rejected in strict source mode because the original Python public function does not take them.}
\item{strict_source_record}{If TRUE, emit the 33 frozen Python 1.2 \code{FunctionalMixedEffectsFullRefitBootstrapResult} scientific fields in declared order, excluding R-native auditing-only flags.}
}
\value{Native likelihood full-refit bootstrap including all fitted random covariance matrices, participant resample identities, fixed coefficients, residual variances, log likelihoods, convergence and backend warnings. Strict mode emits 33 source-scientific fields without Python type identity.}
\description{Every participant resample refits fixed effects and variance components with a genuine Gaussian likelihood optimizer. Supported native spline covariance and residual families retain their fitted scientific meaning. The \code{nlme} and Python \code{statsmodels} optimizers may produce different likelihood and boundary estimates; exact full-source optimization parity is not claimed.}
