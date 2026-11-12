\name{etr_plot_transfer_entropy_sensitivity}
\alias{etr_plot_transfer_entropy_sensitivity}
\title{Plot explicit transfer-entropy parameter sensitivity without hidden averaging}
\usage{
etr_plot_transfer_entropy_sensitivity(result, parameter, metric = "transfer_entropy_bits", filters = NULL, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed transfer-entropy parameter sensitivity grid.}
\item{parameter}{A declared numerical tuning parameter to vary.}
\item{metric}{Declared transfer-entropy summary metric.}
\item{filters}{Exact named tuning-parameter filters.}
\item{strict_source_record}{Return typed native scientific source line and fail closed if any other tuning parameters remain variable.}
\item{...}{Legacy base R graphics options.}
}
\value{Invisibly the original sorted source tuning-parameter and statistic data frame by default. Strict mode returns a typed native R source line and Matplotlib-equivalent scientific labels. No causal interpretation or Python Axes identity is implied.}
\description{Inspect frozen Python 1.2 scientific plotting geometry without recomputing any recurrence, RQA or transfer-entropy estimator. Original native R plots and numeric outputs remain the default.}
\details{Strict mode represents bounded source-scientific coordinates as native R records; Python dataclass and pandas domain identity, exception types, full Matplotlib Axes return, pixel rendering and independent full-source certification are not claimed.}
