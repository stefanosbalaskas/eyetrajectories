\name{etr_plot_windowed_rqa_trajectories}
\alias{etr_plot_windowed_rqa_trajectories}
\title{Plot source functional windowed RQA trajectories and optional ensemble mean}
\usage{
etr_plot_windowed_rqa_trajectories(result, metric, show_mean = FALSE, max_curves = NULL, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed functional windowed RQA trajectories.}
\item{metric}{Existing functional RQA metric dimension.}
\item{show_mean}{Logical scalar determining whether the across-curve mean is shown.}
\item{max_curves}{Optional positive count limiting individual plotted trajectories, not the population contributing to the mean.}
\item{strict_source_record}{Return source scientific artist coordinates with metric units and curve transparency when TRUE.}
\item{...}{Legacy base R graphics options.}
}
\value{Invisibly the original time grid, selected individual curves, and optional full-ensemble mean by default. Strict mode yields typed native per-curve 0.45-alpha lines, optional 2.2-width mean, original metric unit label, and conditional legend.}
\description{Inspect frozen Python 1.2 scientific plotting geometry without recomputing any recurrence, RQA or transfer-entropy estimator. Original native R plots and numeric outputs remain the default.}
\details{Strict mode represents bounded source-scientific coordinates as native R records; Python dataclass and pandas domain identity, exception types, full Matplotlib Axes return, pixel rendering and independent full-source certification are not claimed.}
