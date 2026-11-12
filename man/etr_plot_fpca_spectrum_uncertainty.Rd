\name{etr_plot_fpca_spectrum_uncertainty}
\alias{etr_plot_fpca_spectrum_uncertainty}
\title{Plot matched-bootstrap FPCA eigenvalue and variance-ratio uncertainty}
\usage{
etr_plot_fpca_spectrum_uncertainty(
    result, metric = "explained_variance_ratio",
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Actual native FPCA spectrum uncertainty result with aligned component eigenvalues and bootstrap intervals for eigenvalue, explained-variance ratio and cumulative ratio.}
\item{metric}{Exactly one of \code{"eigenvalue"}, \code{"explained_variance_ratio"} or \code{"cumulative_variance_ratio"}.}
\item{strict_source_record}{Return a typed native R scientific record preserving Python source errorbar arrays, marker \code{"o"}, capsize 3, variance-ratio source ylabel and familywise versus component-wise title; not Python \code{Axes}.}
\item{...}{Native base graphics options.}
}
\value{Default invisible retained-component source point and interval data frame, or strict source scientific errorbar artist metadata with component positions and asymmetric lower/upper uncertainty.}
\description{Displays original bootstrap-calibrated FPC spectrum uncertainty for a declared metric on the native fitted scale. Component-wise and familywise calibration refer to original native estimator output. The plot never invents new coverage guarantees or clips endpoints to mathematical support. Matplotlib runtime object identity and pixel matching remain outside this source-scientific contract.}
