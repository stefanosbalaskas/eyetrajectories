\name{etr_plot_reconstruction_curve}
\alias{etr_plot_reconstruction_curve}
\title{Plot observed integrated FPCA reconstruction error against component count}
\usage{
etr_plot_reconstruction_curve(
    reconstruction_summary, strict_source_record = FALSE, ...)
}
\arguments{
\item{reconstruction_summary}{An observed native reconstruction summary with source columns \code{n_components} and \code{mean_integrated_rmse}, preserving source row order, even if unsorted.}
\item{strict_source_record}{If TRUE, draw natively but return a typed R source-scientific record containing the frozen Python 1.2 Matplotlib line, marker, original source coordinates and axes metadata. This is not Python \code{Axes}.}
\item{...}{Native base R plot options.}
}
\value{Default invisible original source scientific data frame. Strict mode returns source-scientific one-panel native R artist geometry.}
\description{Plots actual mean integrated RMSE for each retained functional principal component count without sorting, interpolating or re-estimating observed values. Source Matplotlib plotting data and labels are covered by frozen Python 1.2 differential tests, not full Matplotlib runtime, exception or pixel identity.}
