\name{etr_native_predictive_visual_audits}
\alias{etr_native_predictive_visual_audits}

\title{Native diagnostic plots for FPCA predictive CV and bootstrap sensitivity}
\description{
Four independent, read-only R-graphics adapters for published
\pkg{eyetrajectoriespy} 1.2 numerical plot geometry: FPC count predictive
cross-validation, nested outer-fold loss, full-refit versus fixed-covariance
mixed-effects simultaneous band-width ratios, and target-specific FPCA
wild-bootstrap truncation width or center.
}
\usage{
etr_plot_fpca_regression_cv(result)
etr_plot_nested_fpca_regression_cv(result)
etr_plot_functional_mixed_effects_bootstrap_comparison(
  comparison, coefficient
)
etr_plot_fpca_wild_bootstrap_truncation_scan(
  result, target = 1L, metric = "width"
)
}
\arguments{
\item{result}{Explicit native R record of already-computed fold losses,
outer-fold losses, or FPCA wild-bootstrap scan/selection values.}
\item{comparison}{Data frame of already-computed bootstrap sensitivity ratios.}
\item{coefficient}{Nonempty name of the coefficient to visualize.}
\item{target}{Native one-based target index or named source curve identifier.}
\item{metric}{Truncation interval \code{width} or \code{center}.}
}
\details{
Published Python 1.2 source \code{plotting.py},
commit \code{c1cd95ad718327550f7e55393ff38582872f7a94}.
Single-fold predictive CV uncertainty uses \code{sd_loss = 0}; other
sample standard deviations use the \code{n - 1} denominator, matching pandas.
No cross-validation, bootstrap, selection or model fitting occurs in these
graphics functions. Returned native R geometry is not a Matplotlib Axes
object. Python numeric target indices are zero-based while native R indices
are one-based. Complete input, output, and error-schema equivalence has
not been certified.
}
\value{
Each function draws to the active base R graphics device and invisibly returns
an auditable list of source numerical plot coordinates and provenance.
}
\keyword{hplot}
