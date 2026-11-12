\name{etr_plot_lyapunov_sensitivity}
\alias{etr_plot_lyapunov_sensitivity}
\title{Plot source scientific Rosenstein Lyapunov parameter sensitivity}
\usage{
etr_plot_lyapunov_sensitivity(result, parameter, response = "exponent", filters = NULL, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed Lyapunov sensitivity grid.}
\item{parameter}{Exact parameter of the source sensitivity slice.}
\item{response}{A supported LLE exponent, standard-error, fit-quality, or pair-count output.}
\item{filters}{Optional fixed tuning parameter values.}
\item{strict_source_record}{Logical scalar yielding native source-scientific plotting artist data when TRUE.}
\item{...}{Legacy base R plotting options.}
}
\value{Invisible original numerical sensitivity table by default. Strict mode returns typed native R line artist geometry with source title and physical unit, and zero-exponent reference only for exponent response.}
\description{Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry while retaining original native R numeric calculations, data, graphics and estimator semantics.}
\details{Strict artist records cover a bounded native source-scientific geometry domain. No actual Python Matplotlib Axes, Python dataclass/pandas protocol or exception-class identity, independent complete-domain certification, or pixel-level rendering equivalence is asserted.}
