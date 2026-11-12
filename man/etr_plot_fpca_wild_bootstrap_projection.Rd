\name{etr_plot_fpca_wild_bootstrap_projection}
\alias{etr_plot_fpca_wild_bootstrap_projection}
\title{Plot fixed-target FPCR wild-bootstrap intervals with source artist data}
\usage{
etr_plot_fpca_wild_bootstrap_projection(result,
  max_targets = 30L, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native FPCR wild-bootstrap fixed-target interval result.}
\item{max_targets}{Positive integer maximum target count.}
\item{strict_source_record}{Logical scalar; return source-specific Matplotlib errorbar geometry as typed R data when TRUE.}
}
\value{Invisibly, original numeric geometry and backend provenance by default; in strict mode a typed source artist record with exact asymmetric y-errors, zero reference, ticks and legend. No Python Axes is returned.}
\description{Plots pre-calibrated wild-bootstrap FPCR projection bounds without refitting the estimator.}
\details{Matplotlib backend identity, Python exception classes and full Python-object acceptance remain outside the bounded native source-scientific comparison.}
