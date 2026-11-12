\name{etr_plot_functional_mean_band}
\alias{etr_plot_functional_mean_band}
\title{Plot fitted functional mean with its simultaneous observed-grid uncertainty band}
\usage{
etr_plot_functional_mean_band(
    result, dimension = NULL, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native scientifically estimated functional mean-band result, with source time grid, dimension-named finite mean, lower and upper matrices, and the actual declared simultaneous confidence level.}
\item{dimension}{Exact existing dimension name. If NULL, selects the first declared functional channel as in frozen Python 1.2.}
\item{strict_source_record}{If TRUE, draw the native R figure and return one source-scientific Matplotlib-like band artist with original time/lower/upper, transparency \code{0.2}, source confidence-level label, mean-line values and legend order. This is an R data record, not a Python \code{Axes}.}
\item{...}{Additional native base R plot options.}
}
\value{Default invisible time, mean, lower and upper data frame for one channel. Strict mode returns a native R source-scientific two-artist geometry record retaining the observed-grid simultaneous band and functional mean in the source order.}
\description{Plots the retained simultaneously calibrated functional mean uncertainty on its original observed grid and confidence level without constructing new bounds. Source geometry is compared to Python 1.2 Matplotlib \code{fill_between} data and line artist, but Python class identity, backend rasterization, and rendering color equality are not claimed.}
