\name{etr_bootstrap_functional_mixed_effects_coefficients}
\alias{etr_bootstrap_functional_mixed_effects_coefficients}
\title{Whole-participant conditional covariance functional mixed-effects bootstrap}
\usage{
etr_bootstrap_functional_mixed_effects_coefficients(
    result, n_bootstrap = 1000L, random_state = 0L,
    sampled_participant_indices = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Previously fitted native functional mixed-effects model; strict source mode requires a genuine native joint spline Gaussian likelihood fit, not the older two-level moments alternative.}
\item{n_bootstrap}{Number of whole-participant resamples. Source-oriented conditional covariance path requires at least 100 draws.}
\item{random_state}{Integer source PCG64 seed (representable by native exact arithmetic).}
\item{sampled_participant_indices}{Optional zero-based matrix for native R reproducibility. Disallowed under strict source mode because the frozen Python public API does not accept externally supplied draws.}
\item{strict_source_record}{If TRUE, emit exactly nine ordered scientific fields from frozen Python 1.2 \code{FunctionalMixedEffectsBootstrapResult}.}
}
\value{Native fixed-covariance participant GLS bootstrap. With strict source record, a nine-field scientific record; no Python dataclass identity.}
\description{Resamples entire participant trial bundles, retains the reference random/residual covariance, and recomputes joint fixed-basis Gaussian GLS coefficients, not timewise independent moments. The reference fitted R likelihood optimizer is \code{nlme}, whereas frozen Python uses \code{statsmodels}; equality of independent optimizer paths and runtime objects is not claimed.}
