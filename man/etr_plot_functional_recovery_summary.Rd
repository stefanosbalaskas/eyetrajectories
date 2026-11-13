\name{etr_plot_functional_recovery_summary}
\alias{etr_plot_functional_recovery_summary}
\title{Plot functional recovery metric summaries with source point or IQR geometry}
\usage{
etr_plot_functional_recovery_summary(summary, metric, statistic = "median",
  strict_source_record = FALSE, ...)
}
\arguments{
\item{summary}{A native source-shaped recovery summary data frame, corresponding to Python's summary pandas DataFrame.}
\item{metric}{Exact recovery statistic metric identifier in the summary.}
\item{statistic}{Selected summary column; median uses existing q25 and q75 for an IQR when present, while other statistics are displayed as points only.}
\item{strict_source_record}{Return a typed R source scientific artist record instead of the original numeric geometry when TRUE.}
\item{...}{Additional legacy R graphics options.}
}
\value{Default invisible native recovered group numeric geometry. Strict mode yields median IQR asymmetric error bars (caps 3) when available or point-only estimates otherwise, source scenario/source/component labels, 45-degree tick labels and original title and axis text.}
\description{Return source-scientific Matplotlib artist coordinates from already computed native R scientific results, with original base R plotting and numerical return preserved by default.}
\details{Frozen source eyetrajectoriespy 1.2.0. Strict source records do not recreate a live Python matplotlib.axes.Axes object, all Python dataclass or pandas acceptance/exception protocols, backend raster parity, or independent full-contract certification.}
