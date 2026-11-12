\name{etr_plot_fpca_regression_future_prediction_interval}
\alias{etr_plot_fpca_regression_future_prediction_interval}
\title{Plot fixed-target FPCR future-outcome intervals with source scientific artists}
\usage{
etr_plot_fpca_regression_future_prediction_interval(result,
  max_targets = 30L, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native fixed-target Gaussian FPCR predictive interval result with fitted regression uncertainty and full-sample reference conditional means.}
\item{max_targets}{Positive integer maximum count of fixed target trajectories.}
\item{strict_source_record}{If TRUE, return source-scientific Matplotlib artist coordinates and labels in a native R record. FALSE preserves the original base-R plotted geometry.}
}
\value{Invisible original numerical interval geometry and provenance by default; typed \code{etr_fpca_inference_artist_source_record} in strict mode with asymmetric y-errors, fixed target ticks, reference mean scatter and source plot legend. Never a Python Matplotlib Axes.}
\description{Plots precomputed future-outcome predictive intervals and fitted reference conditional means without recalibrating or refitting FPCR.}
\details{Strict source mode is a developer-scoped scientific artist comparison against frozen Python 1.2. Full Python Matplotlib runtime, Python dataclass identity and independent source-contract certification remain outstanding.}
