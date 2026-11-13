\name{etr_native_sparse_scientific_graphics}
\alias{etr_native_sparse_scientific_graphics}

\title{Scientific sparse FPCA and multivariate PACE diagnostics in native R graphics}
\description{Plot the native sparse univariate and planar multivariate FPCA fitted
population objects and original irregular observations, retaining scientific
coordinate values from the frozen Python 1.2 source. No estimator is refit.}
\usage{
etr_plot_sparse_fpca_covariance(result)
etr_plot_sparse_fpca_component(result, component = 0L, sd_multiplier = 2)
etr_plot_sparse_mfpca_component(result, component = 0L, sd_multiplier = 2)
etr_plot_sparse_mfpca_covariance_blocks(result, source = "used")
etr_plot_sparse_mfpca_cross_covariance(result, source = "used")
etr_plot_sparse_mfpca_score_diagnostics(result)
etr_plot_sparse_irregular_dimension(trajectories, dimension)
}
\arguments{
\item{result}{Explicit native R-list fitted sparse FPCA or MFPCA record
with grid, covariance, eigenfunctions, uncertainty and dimensions.}
\item{component}{Zero-based integer index of a retained component.}
\item{sd_multiplier}{Strictly positive multiple of the fitted component
standard deviation used for the mean-plus/minus perturbation.}
\item{source}{One of \code{"used"} (fitted PSD-qualified covariance) or
\code{"smoothed"} (pre-repair smoothing output).}
\item{trajectories}{Native irregular-trajectory R-list with per-curve times
and observed coordinate matrices.}
\item{dimension}{Explicit dimension identifier from trajectories.}
}
\value{Base R plots on the active graphics device. In each case the
source-ordered numerical plot geometry is returned invisibly; unlike
the published Python 1.2 functions, no Matplotlib Axes object is returned.}
\details{
Covariance heatmaps retain original directional XY and YX blocks,
component indices are zero-based as in Python, and values are not
automatically interpolated. Input, rendering and backend object
differences are documented source-contract gaps, not independently
certified one-to-one parity. Source: published eyetrajectoriespy 1.2.0,
pinned commit c1cd95ad718327550f7e55393ff38582872f7a94.
}
