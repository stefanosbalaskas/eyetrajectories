\name{etr_plot_fpca_outlier_diagnostics}
\alias{etr_plot_fpca_outlier_diagnostics}
\title{Plot original FPCA reconstruction and score-space review diagnostics}
\usage{
etr_plot_fpca_outlier_diagnostics(
    result, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native fitted FPCA outlier-review scientific result with original robust-z reconstruction diagnostics, squared score-space Mahalanobis distances, score cutoff and optional reconstruction-z review threshold.}
\item{strict_source_record}{If TRUE, return an inspectable native R scientific artist record containing frozen Python 1.2 Matplotlib scatter coordinates and reference-line geometry. This is not a Python Matplotlib \code{Axes}.}
\item{...}{Additional base graphics options for actual native R rendering.}
}
\value{Default invisibly returns the original diagnostic columns. Strict mode draws a native base-R figure and invisibly returns native scientific artist metadata: scatter observations, optional vertical reconstruction threshold, horizontal score cutoff, source titles and axes.}
\description{Reuses actual observed FPCA outlier diagnostics without rescaling, refitting or automatically changing flagged trajectories. Source Matplotlib scatter offsets and reference coordinates are directly comparable to the pinned Python 1.2 public function. Native graphics output remains R-specific; Python runtime plotting object identity, exception classes, and pixel-exact rendering are not provided.}
