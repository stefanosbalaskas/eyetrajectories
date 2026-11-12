\name{etr_plot_functional_mixed_effects_residual_variogram}
\alias{etr_plot_functional_mixed_effects_residual_variogram}
\title{Plot actual within-trial functional mixed residual semivariance}
\usage{
etr_plot_functional_mixed_effects_residual_variogram(
    result, level = "overall", curve_id = NULL,
    participant_id = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native already-computed residual diagnostic scientific record. Strict mode requires genuine native Gaussian spline joint-likelihood provenance.}
\item{level}{Trial, participant or overall summary level.}
\item{curve_id}{Explicit curve for trial summary.}
\item{participant_id}{Explicit participant for participant summary.}
\item{strict_source_record}{Return source-ordered one-panel scientific line and axes geometry instead of default numerical R return. Does not construct Matplotlib Axes.}
}
\value{Physical-lag semivariance geometry for native Gaussian residual diagnostics.}
\description{Plots observed one-half mean squared within-trial residual differences at each retained index lag. The native source stores exact mean/min/max physical separations and does not silently aggregate an unrequested trial or participant. The nonuniform-lag warning title and raw/whitened residual scale follow frozen Python 1.2 scientific rendering semantics.}
