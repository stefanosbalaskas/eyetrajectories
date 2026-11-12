\name{etr_plot_fpca_wild_bootstrap_truncation_scan}
\alias{etr_plot_fpca_wild_bootstrap_truncation_scan}
\title{Plot FPCR wild-bootstrap truncation scan with an optional selected component}
\usage{
etr_plot_fpca_wild_bootstrap_truncation_scan(
  result, target = 1L, metric = "width", strict_source_record = FALSE
)
}
\arguments{
\item{result}{Already computed wild-bootstrap truncation scan record, or selection record with embedded scan.}
\item{target}{Exact target ID or numeric target index. Legacy R default is 1-based; when \code{strict_source_record = TRUE}, numeric indices are zero-based, with omitted target interpreted as zero.}
\item{metric}{Either \code{"width"} or \code{"center"}.}
\item{strict_source_record}{If TRUE, return a native typed record of the frozen Python 1.2 scientific Matplotlib line and optional selected-h reference. Default FALSE keeps the original R plot and source numerical return.}
}
\value{Invisibly original numerical scan line, selected inference component, target ID and provenance by default. In strict mode a typed \code{etr_predictive_scientific_artist_record} with candidate-h values, metric line, optional vertical selected-h reference, source title, labels and conditional legend. No Python Axes is returned.}
\description{Read-only display of precomputed studentized wild-bootstrap interval width or center over candidate inference truncations. Explicit source mode reproduces Python zero-based target indexing without altering the native one-based default.}
\details{Strict scientific geometry does not imply that automatic truncation selection, full Python typed-object validation, Python error classes, Matplotlib runtime identity or independent scientific certification are reproduced.}
