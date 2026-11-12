\name{etr_plot_fpca_influence}
\alias{etr_plot_fpca_influence}
\title{Native FPCA leave-one-group-out influence source-scientific plot}
\usage{
etr_plot_fpca_influence(
    result, metric = "min_abs_component_similarity",
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native FPCA group-influence result with original group summaries and a declared numeric influence column.}
\item{metric}{Exact summary metric name to display in source group order.}
\item{strict_source_record}{Return an inspectable native R source-scientific Matplotlib line, zero-based group x-coordinates, 90-degree source tick labels and axes. Does not return Python Matplotlib \code{Axes}.}
\item{...}{Additional base-R plotting options.}
}
\value{Default invisible group/value data frame in source group order. Strict mode returns one-panel scientific source artist geometry with source x/y arrays and labels.}
\description{Preserves observed leave-one-group-out FPCA influence statistics without recomputing a leave-one-out fit or changing the source metric. Frozen Python 1.2 source line arrays and axis text are directly comparable; R graphics backend identity and exact rendered pixels are not.}
