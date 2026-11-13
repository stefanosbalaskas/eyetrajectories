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
}
\arguments{
\item{result}{Explicit R list with the relevant multivariate surrogate or
nonlinearity scientific quantities, including diagnostic spectral errors.}
\item{bootstrap}{Full-refit participant-bootstrap R list with coefficient
draws, covariance arrays, variance/eigenvalue summaries, flags and warnings.}



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
