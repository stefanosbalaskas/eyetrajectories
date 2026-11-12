\name{etr_plot_embedding_delay_diagnostics}
\alias{etr_plot_embedding_delay_diagnostics}
\title{Plot AMI and ACF embedding-delay source scientific artists}
\usage{
etr_plot_embedding_delay_diagnostics(result, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native embedding delay diagnostic with original lag-time, mutual-information and autocorrelation table.}\item{strict_source_record}{Return native typed frozen Python 1.2 source artist geometry instead of the default numeric result when TRUE.}\item{...}{Legacy base R graphics options.}
}
\value{Native default invisibly returns lag time, AMI, ACF and zero-based first local minimum indices. Strict source mode returns typed twin-y-axis source scientific artists with AMI/ACF lines and optional marked minimum scatter.}
\description{Native scientific geometry for the frozen Python 1.2 nonlinear plotting contract. Scientific estimators and the default base R graphics return are unchanged.}
\details{The strict source record does not return a live Python Matplotlib Axes, accept arbitrary Python dataclasses, reproduce Python exception classes, or establish pixel parity. No independent full-contract certification is claimed.}
