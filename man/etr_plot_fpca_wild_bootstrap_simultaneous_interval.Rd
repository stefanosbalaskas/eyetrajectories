\name{etr_plot_fpca_wild_bootstrap_simultaneous_interval}
\alias{etr_plot_fpca_wild_bootstrap_simultaneous_interval}
\title{Plot familywise and target-wise FPCR wild-bootstrap intervals}
\usage{
etr_plot_fpca_wild_bootstrap_simultaneous_interval(result,
  max_targets = 30L, show_targetwise = TRUE,
  strict_source_record = FALSE)
}
\arguments{
\item{result}{Already-calibrated native fixed-family wild-bootstrap simultaneous projection result.}
\item{max_targets}{Positive integer number of fixed trajectories plotted.}
\item{show_targetwise}{Logical flag controlling the additional per-target interval.}
\item{strict_source_record}{If TRUE, return a typed native R record of frozen Python 1.2 scientific Matplotlib errorbars; otherwise return the original numerical frame.}
}
\value{Invisible numerical fixed-target interval frame by default. In strict mode, a typed \code{etr_fpca_inference_artist_source_record} with asymmetric familywise errorbar, optional target-wise errorbar, zero reference and source axes metadata. Does not return Python Matplotlib Axes.}
\description{Displays the original calibrated familywise and target-wise centered Gaussian FPCR projections. No new wild-bootstrap draws, multiple-testing adjustments or scientific extrapolations are introduced.}
\details{Strict mode covers source-scientific artist coordinates and labels only, not Matplotlib runtime identity, backend pixels, Python error classes, or independent full-source certification.}
