\name{etr_plot_functional_mixed_effects_residual_acf}
\alias{etr_plot_functional_mixed_effects_residual_acf}
\title{Plot native Gaussian mixed-model residual autocorrelation against physical lag}
\usage{
etr_plot_functional_mixed_effects_residual_acf(
    result, level = "overall", curve_id = NULL,
    participant_id = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Retained native functional mixed-effects residual diagnostics with physical-lag summaries and within-trial covariance provenance. Strict mode requires diagnostics from an actual native joint Gaussian spline likelihood fit, not a restricted moment model.}
\item{level}{One of \code{"overall"}, \code{"participant"}, \code{"trial"}.}
\item{curve_id}{Required source curve ID for trial level; otherwise NULL.}
\item{participant_id}{Required participant ID for participant level; otherwise NULL.}
\item{strict_source_record}{Return an inspectable source scientific Matplotlib-equivalent line, horizontal-zero and axes record, without claiming a Python plotting object.}
}
\value{Invisible observed physical-lag and autocorrelation table in default mode; a source-scientific R artist geometry record in strict mode.}
\description{Preserves mean/min/max physical lag per index lag, pair-count-weighted native trial/participant/overall dependence and any undefined zero-residual-variance autocorrelation. If the actual grid is nonuniform, the source plotting title warns that the x coordinate is mean physical lag. No automatic AR(1) selection, physical-lag binning or Python \code{Axes} identity is implied.}
