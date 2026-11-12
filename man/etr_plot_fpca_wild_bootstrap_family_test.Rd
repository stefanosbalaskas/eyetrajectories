\name{etr_plot_fpca_wild_bootstrap_family_test}
\alias{etr_plot_fpca_wild_bootstrap_family_test}
\title{Plot fixed-family wild-bootstrap p-values with source artist data}
\usage{
etr_plot_fpca_wild_bootstrap_family_test(result,
  max_targets = 30L, show_targetwise = TRUE,
  strict_source_record = FALSE)
}
\arguments{
\item{result}{Native FPCR family test record with fixed-target adjusted and targetwise p-values.}
\item{max_targets}{Positive integer maximum target count.}
\item{show_targetwise}{Logical flag for including targetwise p-values.}
\item{strict_source_record}{Logical scalar; include frozen Python 1.2 Matplotlib scatter and alpha-reference artist data when TRUE.}
}
\value{Invisibly, the original numeric fixed-target p-value frame by default. In strict mode a typed source artist record of maxT scatter positions, optional targetwise scatter, alpha line and labels. No Python Axes is returned.}
\description{Visualizes existing calibrated fixed-family wild-bootstrap test results, without recomputing adjusted p-values.}
\details{The native representation is a bounded scientific artist comparison rather than complete Matplotlib runtime or Python exception-class parity. No independent certification is asserted.}
