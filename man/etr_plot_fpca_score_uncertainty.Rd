\name{etr_plot_fpca_score_uncertainty}
\alias{etr_plot_fpca_score_uncertainty}
\title{Plot source-scientific FPCA fixed-target bootstrap score uncertainty}
\usage{
etr_plot_fpca_score_uncertainty(
    result, component = 0L, max_targets = 30L,
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Actual native FPCA score uncertainty result with reference scores, bootstrap medians, lower and upper percentile endpoints for fixed identified targets.}
\item{component}{Python-compatible zero-based FPC component index.}
\item{max_targets}{Positive integer limit on the original ordered fixed target curves shown.}
\item{strict_source_record}{If TRUE, retain frozen Python 1.2 Matplotlib scientific errorbar, original reference-score scatter, zero line, tick labels and source plot metadata in a typed native R record. This does not return Python Matplotlib \code{Axes}.}
\item{...}{Native base-R plot options.}
}
\value{Default invisible target-curve median, lower, upper and full-sample reference score table; strict mode returns an inspectable one-panel source scientific artist record with asymmetric error-bar matrix, reference scatter offsets, plot labels and zero reference.}
\description{The existing native bootstrap estimator supplies each fixed target's percentile interval. The plot does not refit, recalibrate or add future-target measurement uncertainty. Source Matplotlib artist arrays and axes are compared to the frozen public Python 1.2 function, but native R graphics and Python figure runtime/pixel rendering remain distinct.}
