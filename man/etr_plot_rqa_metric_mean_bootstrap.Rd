\name{etr_plot_rqa_metric_mean_bootstrap}
\alias{etr_plot_rqa_metric_mean_bootstrap}
\title{Plot RQA population bootstrap mean estimates with source percentile error bars}
\usage{
etr_plot_rqa_metric_mean_bootstrap(result, metrics = NULL,
  strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Precomputed native whole-unit RQA mean bootstrap summary and unit label.}
\item{metrics}{Optional explicit ordered subset of already computed RQA metric names.}
\item{strict_source_record}{When TRUE return a typed native source scientific errorbar record including asymmetric intervals, caps, metrics labels and fixed tick formatting.}
\item{...}{Additional original base graphics arguments.}
}
\value{Default invisible numeric metric bootstrap table. Strict mode returns one native R scientific errorbar artist for the declared metric order with source asymmetrical yerr, marker o, caps 4, 30-degree tick labels and source axes.}
\description{Return source-scientific Matplotlib artist coordinates from already computed native R scientific results, with original base R plotting and numerical return preserved by default.}
\details{Frozen source eyetrajectoriespy 1.2.0. Strict source records do not recreate a live Python matplotlib.axes.Axes object, all Python dataclass or pandas acceptance/exception protocols, backend raster parity, or independent full-contract certification.}
