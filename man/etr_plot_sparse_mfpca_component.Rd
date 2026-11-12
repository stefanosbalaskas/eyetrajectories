\name{etr_plot_sparse_mfpca_component}
\alias{etr_plot_sparse_mfpca_component}
\title{Plot native sparse bivariate PACE component mean and modal deviations}
\usage{
etr_plot_sparse_mfpca_component(result, component = 0L,
    sd_multiplier = 2, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native sparse bivariate PACE fit with two measured coordinates, eigenvalues, joint eigenfunctions and an evaluation grid. Strict scientific-record mode requires a real native fitted sparse-MFPCA result class.}
\item{component}{Zero-based component identifier, as in frozen Python 1.2.}
\item{sd_multiplier}{Finite positive multiple of each principal-component standard deviation.}
\item{strict_source_record}{If TRUE, draw natively and return a \code{etr_sparse_mfpca_artist_source_record} with two source-scientific axes, exact mean and plus/minus mode curve coordinates, source titles, labels and legend declarations. This is not a Python Matplotlib \code{Axes} array.}
}
\value{In default mode, invisible coordinate-wise time, mean and modal-perturbation data frames. In strict mode, an invisible source-scientific artist geometry record with two panels and six scientific line artists.}
\description{Native sparse principal-component visualization uses the direct joint PACE eigenvalue/eigenfunction and exact fitted population mean without interpolation. Strict geometry is directly testable against Matplotlib source artists, but the rendered R device is not a Python Matplotlib figure.}
