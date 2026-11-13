\name{etr_native_scientific_visualization}
\alias{etr_native_scientific_visualization}

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
etr_plot_surrogate_nonlinearity(result, bins = 20L,
  python_boundary_mode = FALSE, ...)
etr_plot_poincare_return_map(crossings, fit = NULL, ...)
}
\arguments{
\item{result}{A corresponding native embedding-delay, FNN-dimension,
recurrence-network, radius-profile, windowed-RQA, local-divergence,
largest-Lyapunov or surrogate-nonlinearity diagnostic result.}
\item{normalized}{Use degree normalized by source node count.}
\item{metrics}{Distinct available numeric windowed-RQA columns.}
\item{bins}{Integer histogram-break count (>=2) for base R plotting.
In the explicit source-boundary mode, must be a Python-style integer
within the native finite 10000-bin safety limit.}
\item{python_boundary_mode}{If TRUE, reproduce exact finite NumPy
equal-width integer-bin edges and left-inclusive counts for the
surrogate-nonlinearity histogram. FALSE retains the existing base R
histogram interpretation and validation.}
\item{crossings}{One-dimensional native Poincare crossing result with
at least two observed crossings.}
\item{fit}{Optional compatible one-dimensional native local affine map.}
\item{...}{Additional native plotting parameters.}
}
\value{
Each function draws into the active R graphics device and returns the
plotted numeric geometry invisibly. Return classes and graphics
devices are not Matplotlib Axes. The source-boundary mode of
\code{etr_plot_surrogate_nonlinearity()} aligns NumPy integer-bin
histogram geometry for finite surrogate samples, but all other
graphics and native R result classes retain their native behavior.
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
