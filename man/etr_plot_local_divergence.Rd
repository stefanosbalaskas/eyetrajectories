\name{etr_plot_local_divergence}
\alias{etr_plot_local_divergence}
\title{Plot local or Kantz divergence and an optional Lyapunov fit}
\usage{
etr_plot_local_divergence(result, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native local/Kantz divergence or largest-Lyapunov result with fit window and physical time unit.}\item{strict_source_record}{Logical scalar for typed native scientific artists in frozen Python source coordinates.}\item{...}{Legacy base R graphics options.}
}
\value{Native default invisibly returns the original divergence data and finite-window fit estimates; strict mode records source divergence line and optional fitted Lyapunov line using the correct physical time-unit conversion.}
\description{Native scientific geometry for the frozen Python 1.2 nonlinear plotting contract. Scientific estimators and the default base R graphics return are unchanged.}
\details{The strict source record does not return a live Python Matplotlib Axes, accept arbitrary Python dataclasses, reproduce Python exception classes, or establish pixel parity. No independent full-contract certification is claimed.}
