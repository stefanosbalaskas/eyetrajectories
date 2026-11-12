\name{etr_plot_sparse_mfpca_cross_covariance}
\alias{etr_plot_sparse_mfpca_cross_covariance}
\title{Display directional cross-covariance of paired sparse functional coordinates}
\usage{
etr_plot_sparse_mfpca_cross_covariance(result, source = "used",
    stage = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native genuine paired sparse multivariate PACE fitted covariance.}
\item{source}{Native \code{"used"} or \code{"smoothed"} covariance stage.}
\item{stage}{Optional frozen Python 1.2 stage alias; must match explicitly specified source.}
\item{strict_source_record}{Return a native source-scientific 1-by-2 heatmap artist geometry record for Cxy and Cyx, including exact matrix values, source imshow extent and shared symmetric signed limits.}
}
\value{Invisible pair of native directional covariance matrices; strict mode returns native R source-scientific plot geometry.}
\description{Preserves independent directional Cxy and Cyx scientific surfaces rather than silently symmetrizing xy before covariance projection. Native R graphics rendering is not Python Matplotlib \code{Axes}, and exact rendered color palette is not asserted.}
