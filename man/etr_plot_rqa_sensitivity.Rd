\name{etr_plot_rqa_sensitivity}
\alias{etr_plot_rqa_sensitivity}
\title{Plot an explicit one-parameter recurrence quantification sensitivity slice}
\usage{
etr_plot_rqa_sensitivity(result, parameter, metric, filters = NULL,
  strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed RQA parameter sensitivity grid with declared parameter and metric columns.}
\item{parameter}{One numerical parameter varied in the source slice.}
\item{metric}{Existing RQA summary metric.}
\item{filters}{Optional named exact values holding remaining declared parameters fixed.}
\item{strict_source_record}{Return native Matplotlib scientific source artist data, requiring distinct plotted-parameter values, when TRUE.}
\item{...}{Legacy base R graphics options.}
}
\value{Invisibly the original ordered parameter/metric data frame by default. Strict mode returns a typed R source line with original source title, o marker, axes and no legend.}
\description{Inspect frozen Python 1.2 scientific plotting geometry without recomputing any recurrence, RQA or transfer-entropy estimator. Original native R plots and numeric outputs remain the default.}
\details{Strict mode represents bounded source-scientific coordinates as native R records; Python dataclass and pandas domain identity, exception types, full Matplotlib Axes return, pixel rendering and independent full-source certification are not claimed.}
