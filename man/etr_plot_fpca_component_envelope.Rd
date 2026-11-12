\name{etr_plot_fpca_component_envelope}
\alias{etr_plot_fpca_component_envelope}
\title{Plot matched-bootstrap FPCA component envelopes with source artist data}
\usage{
etr_plot_fpca_component_envelope(result, component = 0L,
  dimension = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native fitted FPCA component envelope and reference record.}
\item{component}{Zero-based component index.}
\item{dimension}{Fitted dimension name; defaults to the first dimension.}
\item{strict_source_record}{Logical scalar. If TRUE, return a typed record of the frozen Python 1.2 scientific Matplotlib artists.}
}
\value{Invisibly, the original observed-grid numeric frame by default. In strict mode an \code{etr_fpca_inference_artist_source_record} with band, median and reference artist data. Neither mode returns a Python Matplotlib Axes object.}
\description{Plots matched-bootstrap pointwise FPC shape envelopes; strict mode preserves source band alpha, labels, and curve geometry without re-estimating uncertainty.}
\details{The strict mode is a bounded native-language scientific geometry comparison, not Matplotlib object or pixel parity. It is not independently certified.}
