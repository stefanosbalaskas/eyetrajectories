\name{etr_plot_embedding_delay_diagnostics}
\alias{etr_plot_embedding_delay_diagnostics}
\alias{etr_plot_embedding_dimension_diagnostics}
\alias{etr_plot_recurrence_network_degree}
\alias{etr_plot_recurrence_rate_curve}
\alias{etr_plot_windowed_rqa}
\alias{etr_plot_local_divergence}
\alias{etr_plot_surrogate_nonlinearity}
\alias{etr_plot_poincare_return_map}
\title{Native R embedding, recurrence and nonlinear-dynamics visual diagnostics}
\description{
Eight Python-free native R descriptive graphics plotting the exact
stored scientific geometry without automatic parameter tuning or
mathematical estimator modification. These functions are experimental
source-name analogues; they are not exact Matplotlib output contracts.
}
\usage{
etr_plot_embedding_delay_diagnostics(result, ...)
etr_plot_embedding_dimension_diagnostics(result, ...)
etr_plot_recurrence_network_degree(result, normalized = TRUE, ...)
etr_plot_recurrence_rate_curve(result, ...)
etr_plot_windowed_rqa(result,
  metrics = c("recurrence_rate", "determinism", "laminarity"), ...)
etr_plot_local_divergence(result, ...)
etr_plot_surrogate_nonlinearity(result, bins = 20L, ...)
etr_plot_poincare_return_map(crossings, fit = NULL, ...)
}
\arguments{
\item{result}{A corresponding native embedding-delay, FNN-dimension,
recurrence-network, radius-profile, windowed-RQA, local-divergence,
largest-Lyapunov or surrogate-nonlinearity diagnostic result.}
\item{normalized}{Use degree normalized by source node count.}
\item{metrics}{Distinct available numeric windowed-RQA columns.}
\item{bins}{Integer histogram-break count (>=2) for base R plotting.}
\item{crossings}{One-dimensional native Poincare crossing result with
at least two observed crossings.}
\item{fit}{Optional compatible one-dimensional native local affine map.}
\item{...}{Additional native plotting parameters.}
}
\value{
Each function draws into the active R graphics device and returns the
plotted numeric geometry invisibly. Return classes and graphics
devices are not Matplotlib Axes, and R histogram binning is not
claimed identical to NumPy/matplotlib.
}
\details{
The visualisations preserve the declared physical-time/lag
coordinates, source sample-index semantics, ordered diagnostic tables,
and recorded fit intervals. All source-name parity ledger entries
remain full-contract certification pending: graphical-backend return
objects are an explicit known divergence. These plots are descriptive
and do not provide causal inference, chaos classification, or calibrated
confidence by themselves.
}
