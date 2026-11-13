\name{etr_multivariate_iaaft_diagnostics_frame}
\alias{etr_multivariate_iaaft_diagnostics_frame}
\alias{etr_functional_mixed_effects_variance_bootstrap_frame}

\title{Source-aligned native multivariate surrogate and mixed-effects diagnostic outputs}
\description{
Read-only diagnostic frames for multivariate IAAFT surrogates and complete
participant-bootstrap mixed-effects covariance refits, with native R
diagnostic visualizations. Python source frozen at eyetrajectoriespy 1.2.0.
}
\usage{
etr_multivariate_iaaft_diagnostics_frame(result)
etr_functional_mixed_effects_variance_bootstrap_frame(bootstrap)
etr_plot_multivariate_iaaft_diagnostics(result, ...)
etr_plot_multivariate_surrogate_nonlinearity(result, bins = 20L,
  python_boundary_mode = FALSE, ...)
}
\arguments{
\item{result}{Explicit R list with the relevant multivariate surrogate or
nonlinearity scientific quantities, including diagnostic spectral errors.}
\item{bootstrap}{Full-refit participant-bootstrap R list with coefficient
draws, covariance arrays, variance/eigenvalue summaries, flags and warnings.}
\item{bins}{Number of equally spaced surrogate-statistic histogram bins,
an integer at least two. Python boundary mode requires an R integer scalar
from 2 through a native safety limit of 10000.}
\item{python_boundary_mode}{If TRUE, reproduce NumPy integer-bin
breaks including fixed half-unit constant-data expansion and left-inclusive
counts with a closed final right edge. FALSE retains existing base R
histogram semantics. This does not emulate Python Matplotlib Axes.}
\item{...}{Additional arguments passed to the base R plotting function.}
}
\value{
The two data-frame functions return source-column-ordered R
\code{data.frame} objects. Plot functions render into the active base R
graphics device and invisibly return the numeric data or plotted histogram
geometry rather than Python Matplotlib Axes.
}
\details{
Source surrogate indices and bootstrap replicate labels begin at zero.
Optional mixed-effects refit diagnostics include residual correlation,
trial-level covariance and random-slope covariance diagnostics when present.
Positive infinite condition numbers preserve singular covariance or
correlation diagnostics in the output frame.
Inputs are validated strictly and do not imply a new fit or inferential
calibration. R and Python plotting APIs are not return-type or pixel
equivalent, and no claim of full 508-contract certification is made.
}
