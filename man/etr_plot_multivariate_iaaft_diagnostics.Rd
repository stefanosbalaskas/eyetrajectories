\name{etr_plot_multivariate_iaaft_diagnostics}
\alias{etr_plot_multivariate_iaaft_diagnostics}
\title{Show multivariate IAAFT power- and cross-spectrum scientific source artists}
\usage{
etr_plot_multivariate_iaaft_diagnostics(result, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native IAAFT surrogate result with reference dimension, per-surrogate spectral and cross-spectral error matrices and iteration counts.}
\item{strict_source_record}{If TRUE return a typed native R scientific source artist record with Python 1.2 line and legend geometry, rather than the default native numeric data frame.}
\item{...}{Additional legacy R graphics arguments.}
}
\value{Default invisibly returns exact source diagnostic frame. Strict mode invisibly returns a typed R scientific artist record with zero-based surrogate indices, two solid lines with source labels and markers, scientific title and axes. Not a Python Matplotlib Axes.}
\description{Return source-scientific Matplotlib artist coordinates from already computed native R scientific results, with original base R plotting and numerical return preserved by default.}
\details{Frozen source eyetrajectoriespy 1.2.0. Strict source records do not recreate a live Python matplotlib.axes.Axes object, all Python dataclass or pandas acceptance/exception protocols, backend raster parity, or independent full-contract certification.}
