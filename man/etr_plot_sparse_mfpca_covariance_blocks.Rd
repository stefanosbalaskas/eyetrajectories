\name{etr_plot_sparse_mfpca_covariance_blocks}
\alias{etr_plot_sparse_mfpca_covariance_blocks}
\title{Plot four native paired sparse covariance operator blocks}
\usage{
etr_plot_sparse_mfpca_covariance_blocks(result, source = "used",
    stage = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native paired sparse joint-covariance/PACE fitted scientific record.}
\item{source}{Legacy native R choice \code{"used"} (PSD-qualified fitted covariance) or \code{"smoothed"} (pre-PSD-repair covariance).}
\item{stage}{Optional exact frozen Python stage name, \code{"used"} or \code{"smoothed"}. Cannot disagree with an explicitly supplied \code{source}.}
\item{strict_source_record}{If TRUE, return source-scientific four-panel imshow metadata (ordered Cxx, Cxy, Cyx, Cyy; source grid extent, signed symmetric shared color limits, per-panel titles/labels and declared colorbar), not actual Python \code{Axes}.}
}
\value{Invisible native covariance matrices in default mode; strict mode returns native R scientific four-panel artist geometry.}
\description{Displays direct sparse planar covariance surfaces on the declared evaluation grid without changing source arrays or discarding directional xy/yx information. Source-scientific geometry and symmetric color-range semantics are compared directly to frozen Python 1.2 Matplotlib imshow artists. Exact backend pixel colors, Figure and Axes runtime identity, and Python exception classes are not claimed.}
