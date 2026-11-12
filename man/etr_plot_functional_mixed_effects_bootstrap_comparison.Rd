\name{etr_plot_functional_mixed_effects_bootstrap_comparison}
\alias{etr_plot_functional_mixed_effects_bootstrap_comparison}
\title{Plot mixed-effects full-refit versus fixed-covariance bootstrap widths}
\usage{
etr_plot_functional_mixed_effects_bootstrap_comparison(
  comparison, coefficient, strict_source_record = FALSE
)
}
\arguments{
\item{comparison}{Source-shaped full-refit versus fixed-covariance bootstrap comparison frame with coefficient, time, and band-width ratio.}
\item{coefficient}{An existing nonempty coefficient name to select.}
\item{strict_source_record}{If TRUE, return a typed native R record of frozen Python 1.2 scientific Matplotlib line geometry instead of the default numeric base-R plotting return.}
}
\value{Invisibly original coefficient, ordered ratio line, identity baseline and provenance by default. In strict mode a typed \code{etr_predictive_scientific_artist_record} with sorted time/ratio line, horizontal reference at one and source scientific title and labels. Not a live Matplotlib Axes.}
\description{Display the observed-grid sensitivity ratio of full-refit and fixed-covariance simultaneous bootstrap band widths, without rerunning bootstrap or changing uncertainty estimates.}
\details{Python pandas input identity, exact exception types, Matplotlib return object, backend pixels and independent full-contract source certification are outside the scoped scientific artist comparison.}
