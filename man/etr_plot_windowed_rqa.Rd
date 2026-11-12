\name{etr_plot_windowed_rqa}
\alias{etr_plot_windowed_rqa}
\title{Plot selected time-varying RQA metrics using source scientific artists}
\usage{
etr_plot_windowed_rqa(result, metrics = c("recurrence_rate", "determinism", "laminarity"), strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native windowed recurrence quantification result on its physical time grid.}\item{metrics}{Character vector of selected, distinct existing metric columns in source order.}\item{strict_source_record}{Logical scalar for native source scientific artist geometry.}\item{...}{Legacy base R graphics options.}
}
\value{Native default invisibly returns the original center-time and selected RQA metric values. Strict mode gives each source-ordered metric a line with marker o and source labels and legend.}
\description{Native scientific geometry for the frozen Python 1.2 nonlinear plotting contract. Scientific estimators and the default base R graphics return are unchanged.}
\details{The strict source record does not return a live Python Matplotlib Axes, accept arbitrary Python dataclasses, reproduce Python exception classes, or establish pixel parity. No independent full-contract certification is claimed.}
