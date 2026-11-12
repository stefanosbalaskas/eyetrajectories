\name{etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics}
\alias{etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics}
\title{Plot fixed-family Monte Carlo precision with inspectable source artists}
\usage{
etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(result,
  max_targets = 30L, show_targetwise = FALSE,
  strict_source_record = FALSE)
}
\arguments{
\item{result}{Native exact-binomial Monte Carlo diagnostic result for fixed-family FPCR wild-bootstrap tests.}
\item{max_targets}{Positive integer number of fixed target trajectories to show.}
\item{show_targetwise}{Logical flag controlling the additional target-wise tail probability interval.}
\item{strict_source_record}{If TRUE, return a typed native R record of frozen Python 1.2 Matplotlib scientific artist geometry. Defaults to FALSE.}
}
\value{Invisible source-ordered numerical drawing frame by default. In strict mode, a typed \code{etr_fpca_inference_artist_source_record} describing asymmetric maxT and optional target-wise error bars, threshold, legend, x coordinates and labels. No Python Axes object is returned.}
\description{Displays existing exact-binomial uncertainty in finite-bootstrap tail probability estimates without new simulations or recalibration. The plotted intervals describe Monte Carlo precision, not scientific effect uncertainty.}
\details{Strict mode qualifies only the observable scientific geometry for supported native records. Python runtime object identity, exception classes, backend details, and pixel-perfect rendering are not claimed. Independent full-contract certification is pending.}
