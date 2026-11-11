\name{etr_native_wild_source_inference}
\alias{etr_select_fpca_wild_bootstrap_truncation}
\alias{etr_fpca_wild_bootstrap_projection_frame}
\alias{etr_fpca_wild_bootstrap_simultaneous_frame}
\alias{etr_fpca_wild_bootstrap_family_test_frame}
\alias{etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame}
\title{Native FPCA wild-bootstrap truncation selection and inference audit tables}
\description{
One independent native selection algorithm and four source-aligned
read-only inference frames from published \pkg{eyetrajectoriespy} 1.2.0.
The stabilized-volatility selector requires \code{stability_run + 1}
consecutive stable width and center transitions and picks the earliest
candidate starting such a run for each fixed target. There is no fallback
to a largest candidate or automatic calibration.
}
\usage{
etr_select_fpca_wild_bootstrap_truncation(
  scan, width_threshold, center_threshold, stability_run,
  on_failure = "error"
)
etr_fpca_wild_bootstrap_projection_frame(result)
etr_fpca_wild_bootstrap_simultaneous_frame(result)
etr_fpca_wild_bootstrap_family_test_frame(result)
etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(result)
}
\arguments{
\item{scan}{Explicit R record of an already computed wild-bootstrap
truncation scan with candidate components, target curve IDs and
candidate-by-target center, width and interval-bound matrices.}
\item{width_threshold}{Strictly positive width transition threshold,
including a finite decimal-text scalar.}
\item{center_threshold}{Strictly positive center transition threshold,
including a finite decimal-text scalar.}
\item{stability_run}{Nonnegative whole-number r, requiring r+1
successive stable candidate transitions.}
\item{on_failure}{Whether targets with no qualifying run trigger
an error, warning or ignored missing selection.}
\item{result}{Source-aligned realized projection, simultaneous interval,
fixed-family test or Monte Carlo precision diagnostic record.}
}
\details{
Published Python \pkg{eyetrajectoriespy} 1.2.0 source:
\code{wild_selection.py}, \code{wild_regression.py},
\code{wild_simultaneous.py} and \code{wild_testing.py}, pinned at
\code{c1cd95ad718327550f7e55393ff38582872f7a94}.

The selector preserves zero-based chosen candidate index in the result.
Target-specific missing selections use \code{NaN}, not an unreported
fallback. The four audit frames preserve the fixed-target row order,
family-adjusted p values, simultaneous interval bounds, and
Monte Carlo-sensitive decisions; they do not generate or re-estimate
bootstrap quantities. R named-list inputs and R data frame returns
are not equivalent to the Python frozen dataclass and pandas source
types. This boundary remains a documented unresolved full-contract gap.
}
\value{
Selection returns an explicit R record containing transition matrices,
selected source indices, selected values and provenance. Reporting functions
return native R data frames. No Python runtime is invoked.
}
\keyword{models}
