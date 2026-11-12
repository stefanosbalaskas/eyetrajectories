\name{etr_plot_sparse_fpca_covariance}
\alias{etr_plot_sparse_fpca_covariance}
\title{Plot the fitted sparse functional latent covariance on its native grid}
\usage{
etr_plot_sparse_fpca_covariance(result, strict_source_record = FALSE)
}
\arguments{
\item{result}{Real native sparse univariate covariance/PACE fit with a finite evaluation grid, mean, eigenbasis, and latent covariance surface. Strict mode requires the real native fitted scientific class.}
\item{strict_source_record}{If TRUE, draw in native R graphics and return an inspectable, source-scientific one-panel Matplotlib image-artist geometry record. This does not return an actual Python Axes or Figure.}
}
\value{By default, invisible fitted evaluation grid and covariance matrix. In strict mode, a native R one-panel artist geometry with the actual fitted latent covariance matrix, source title, axis labels, image extent, color limits, declared viridis colormap, and source colorbar label.}
\description{Displays the actual smoothed and PSD-qualified latent covariance of a native sparse univariate PACE result, preserving original evaluation-grid indexing and source Python 1.2 image orientation. Frozen Python Matplotlib imshow arrays, extents, labels and normalized data color limits can be compared directly. Pixel colors and Python plotting-object identity are outside this scientific record contract.}
