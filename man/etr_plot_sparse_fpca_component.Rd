\name{etr_plot_sparse_fpca_component}
\alias{etr_plot_sparse_fpca_component}
\title{Plot fitted sparse functional mean and retained PACE component deviation}
\usage{
etr_plot_sparse_fpca_component(result, component = 0L,
    sd_multiplier = 2, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native univariate sparse covariance/PACE fit with a mean, joint estimation-grid covariance, eigenvalues and eigenfunctions.}
\item{component}{Zero-based retained functional principal-component index, as in frozen Python 1.2.}
\item{sd_multiplier}{Finite strictly positive standard deviation multiple of the retained principal component.}
\item{strict_source_record}{Return an ordered native R scientific Matplotlib line-artist data record with mean, mean minus mode and mean plus mode, source labels and axis titles. No actual Python Axes object is created.}
}
\value{By default, invisible time, mean, lower and upper curve data frame. Strict mode returns an inspectable source-scientific geometry record describing three labelled native R plotted lines, matching the frozen Python plotting order.}
\description{Uses the genuine native sparse functional PACE mean and covariance eigensystem. Mean plus/minus standard-deviation mode uses the fitted eigenvalue and eigenfunction, never a substituted fdapace marginal estimator. Direct Python 1.2 Matplotlib artist line data can be compared, but rendered pixel geometry and Python runtime class identity differ.}
