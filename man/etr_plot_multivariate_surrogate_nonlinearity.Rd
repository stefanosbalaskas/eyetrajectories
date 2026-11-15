\name{etr_plot_multivariate_surrogate_nonlinearity}
\alias{etr_plot_multivariate_surrogate_nonlinearity}
\title{Show multivariate surrogate histogram with NumPy scientific source bins}
\usage{
etr_plot_multivariate_surrogate_nonlinearity(result, bins = 20L,
  python_boundary_mode = FALSE, strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native multivariate surrogate nonlinearity result with observed and surrogate statistics, p-value and statistic name.}
\item{bins}{Integer count of at least two; source strict mode requires a true R integer to represent the Python integer acceptance domain.}
\item{python_boundary_mode}{When TRUE use exact equal-width NumPy histogram boundaries and left-inclusive/rightmost-closed counting.}
\item{strict_source_record}{When TRUE force source NumPy boundaries and return typed scientific source Matplotlib histogram/bar and observed-statistic line geometry.}
\item{...}{Legacy base R graphics options.}
}
\value{Default returns original base-R histogram numeric geometry and observed statistic. Strict mode returns typed histogram edges and counts (source alpha 0.7), observed dashed reference, labels and conditional legend without rerunning surrogate tests.}
\description{Return source-scientific Matplotlib artist coordinates from already computed native R scientific results, with original base R plotting and numerical return preserved by default.}
\details{Frozen source eyetrajectoriespy 1.2.0. Strict source records do not recreate a live Python matplotlib.axes.Axes object, all Python dataclass or pandas acceptance/exception protocols, backend raster parity, or independent full-contract certification.}
