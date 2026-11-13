\name{etr_fpca_score_uncertainty_reporting_text}
\alias{etr_fpca_score_uncertainty_reporting_text}
\alias{etr_fpca_spectrum_uncertainty_reporting_text}
\alias{etr_functional_mean_band_reporting_text}
\alias{etr_fpca_component_band_reporting_text}

\title{Native Python 1.2 source-aligned FPCA uncertainty reporting and graphics}
\description{
Seven Python-free native R API methods presenting matched-bootstrap
FPCA score, spectrum, component shape and observed-grid functional mean
uncertainty. Estimation methods are not recomputed by these functions.
}
\usage{
etr_fpca_score_uncertainty_reporting_text(result, digits = 3L)
etr_fpca_spectrum_uncertainty_reporting_text(result, digits = 3L)
etr_functional_mean_band_reporting_text(result, digits = 3L)
etr_fpca_component_band_reporting_text(result, digits = 2L)
etr_plot_fpca_score_uncertainty(result, component = 0L,
  max_targets = 30L, ...)
etr_plot_fpca_spectrum_uncertainty(result,
  metric = "explained_variance_ratio", ...)
etr_plot_fpca_component_band(result, component = 0L,
  dimension = NULL, ...)
}
\arguments{
\item{result}{Corresponding audited native R score, spectrum,
functional mean or component-band result class.}
\item{digits}{Nonnegative integer numeric reporting precision, 0 to 12.}
\item{component}{Source-compatible zero-based component index.}
\item{max_targets}{Maximum finite number of target trajectories to plot.}
\item{metric}{Source spectrum measure, one of \code{"eigenvalue"},
\code{"explained_variance_ratio"} or \code{"cumulative_variance_ratio"}.}
\item{dimension}{Optional fitted FPCA channel name.}
\item{...}{Further base R graphics parameters.}
}
\value{
Reporting methods return a character string. The plot methods render
base R graphics to the active device and invisibly return the exact
numeric estimate and uncertainty interval geometry used in the plot.
}
\details{
The published Python source returns Matplotlib Axes, accepts typed
Python FPCA results and obtains bootstrap draws with different RNGs.
The output text may be exactly reproducible for matched numerical
fixtures, while the complete source callable contract remains
uncertified. These graphics use only observed-grid values.
A pointwise target score percentile envelope is not a simultaneous
uncertainty band; a studentized observed-grid band is not a
continuous-domain coverage guarantee. Source certification is
restricted pending independent complete-domain and scientific review.
}
