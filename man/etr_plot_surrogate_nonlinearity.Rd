\name{etr_plot_surrogate_nonlinearity}
\alias{etr_plot_surrogate_nonlinearity}
\title{Plot source-consistent IAAFT surrogate histogram and observation marker}
\usage{
etr_plot_surrogate_nonlinearity(result, bins = 20L, python_boundary_mode = FALSE, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed surrogate nonlinearity diagnostic.}\item{bins}{Number of histogram bins. Strict mode requires an R integer scalar corresponding to a Python integer.}\item{python_boundary_mode}{Use NumPy-style equal-width, left-inclusive bin counts when TRUE. Automatically enabled by strict source artist mode.}\item{strict_source_record}{Logical scalar selecting native Matplotlib source histogram artist geometry.}\item{...}{Legacy base R graphics options.}
}
\value{Native default returns original R histogram breaks, counts and observed statistic. Strict mode represents the source NumPy-bin histogram counts and alpha 0.7, observation vertical line, title, labels and legend.}
\description{Native scientific geometry for the frozen Python 1.2 nonlinear plotting contract. Scientific estimators and the default base R graphics return are unchanged.}
\details{The strict source record does not return a live Python Matplotlib Axes, accept arbitrary Python dataclasses, reproduce Python exception classes, or establish pixel parity. No independent full-contract certification is claimed.}
