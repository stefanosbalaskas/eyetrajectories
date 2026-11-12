\name{etr_plot_registration}
\alias{etr_plot_registration}
\title{Plot original and landmark-registered functional trajectories side by side}
\usage{
etr_plot_registration(
    result, dimension = NULL, max_curves = 20L,
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Real native landmark-registration result retaining original and registered trajectories on their original common time grid, dimension names and curve identifiers.}
\item{dimension}{Exact named native functional dimension. If NULL, select the first source channel.}
\item{max_curves}{Positive integer maximum number of first-seen curves displayed in each panel.}
\item{strict_source_record}{Return a native R scientific artist record preserving Python's two source panels, per-curve data, alpha 0.25, axis titles, figure size intent and curve ordering. No real Python Figure or Axes objects are produced.}
\item{...}{Native base graphics plot options.}
}
\value{Default invisible original and registered per-curve data frames and metadata. Strict mode returns a native R two-panel source scientific artist record.}
\description{Does not apply new registration or recompute warps. Every line is plotted on the source grid in observed curve order with matched original/registered panels. Frozen Python 1.2 source's \code{(fig,axes)} runtime return and pixel-perfect Matplotlib rendering are deliberately not claimed by native R.}
