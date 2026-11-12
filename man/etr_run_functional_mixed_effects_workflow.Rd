\name{etr_run_functional_mixed_effects_workflow}
\alias{etr_run_functional_mixed_effects_workflow}
\title{Native functional mixed-effects workflow with an optional frozen Python 1.2 W3 scientific record}
\usage{
etr_run_functional_mixed_effects_workflow(
    trajectories, design, config, strict_source_record = FALSE)
}
\arguments{
\item{trajectories}{Complete native functional trajectories on a shared time grid.}
\item{design}{Curve-aligned native data frame of declared scalar predictors.}
\item{config}{Named configuration. Use \code{estimator="native_joint_bspline_gaussian"} for a genuine Gaussian spline likelihood fit with explicit \code{predictors}, \code{participant_column}, \code{dimension}, basis controls and \code{method="nlme::lme"}. The separate legacy moments estimator remains available only outside strict source mode.}
\item{strict_source_record}{If TRUE, require the native likelihood optimizer and emit the nine ordered frozen Python \code{FunctionalMixedEffectsWorkflowResult} scientific fields, a fifteen-field scientific config, one measured native fit step, fourteen analyst decisions, six provenance declarations, a coefficient table and an honest R-native report. This does not supply Python \code{statsmodels} class or optimizer identity.}
}
\value{An explicit native functional mixed-effects workflow. In strict mode, a \code{etr_functional_mixed_effects_w3_scientific_workflow} record with genuine Gaussian fixed/random effect fit, timed execution and source-ordered W3 scientific fields.}
\description{Runs an explicitly declared functional Gaussian spline mixed-effects analysis without preprocessing, automatic covariance selection, optimizer fallback or implicit model selection. Source mode preserves the frozen Python 1.2 W3 scientific workflow envelope and coefficient-frame columns, but the actual optimizer is native R \code{nlme}, rather than \code{statsmodels} \code{MixedLM}. The strict source config therefore declares \code{method="nlme::lme"}, not an impersonated Python optimizer method. The reported elapsed time covers the one native fit-and-audit operation. Python error classes, runtime object identity, literal report wording, full numerical optimizer and boundary-domain parity remain unverified.}
