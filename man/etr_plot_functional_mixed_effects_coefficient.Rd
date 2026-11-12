\name{etr_plot_functional_mixed_effects_coefficient}
\alias{etr_plot_functional_mixed_effects_coefficient}
\title{Native functional mixed-effects coefficient with source Wald or simultaneous band scientific artists}
\usage{
etr_plot_functional_mixed_effects_coefficient(result, coefficient,
  strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native realized mixed-effects coefficient fit, or, when \code{strict_source_record = TRUE}, a source-shaped fit or already computed native simultaneous-band record with \code{reference}, \code{lower}, \code{upper}, \code{confidence_level}, and \code{simultaneous_scope}.}
\item{coefficient}{Exact coefficient name or a zero-based R integer when strict source mode is enabled. The existing default R name/index semantics remain unchanged.}
\item{strict_source_record}{If TRUE, validate the source finite observed-time coefficient arrays and return a typed native R record of frozen Python Matplotlib scientific artists, including the pointwise 95 percent Wald or supplied simultaneous-band branch.}
\item{...}{Additional original base R plotting arguments.}
}
\value{With the default mode, the original invisible native R coefficient data frame with precomputed pointwise 95 percent Wald limits. With strict source mode, a typed R scientific artist record describing the original numerical curve, either the 95 percent pointwise Wald interval or source-calibrated simultaneous-band endpoints, and the source scientific axes and legends. This record is not a live Python \code{matplotlib.axes.Axes}.}
\description{Preserve existing native mixed model estimators while exposing the frozen eyetrajectoriespy 1.2.0 plotting contract's two distinct scientific uncertainty paths.}
\details{The strict source branch uses the original time grid; an unbanded fit uses the frozen Python standard normal quantile 1.959963984540054. A band result reuses its supplied calibrated lower/upper limits rather than recomputing them or treating them as pointwise Wald uncertainty. Matplotlib fill alpha is 0.2, followed by the coefficient line, dashed horizontal zero reference, labels and source confidence/scope legend. The accepted source-shaped R domain is bounded; arbitrary Python dataclass/pandas identities, Python exception classes, Matplotlib Axes object and pixel rendering parity, and independent complete-domain certification are not claimed.}
