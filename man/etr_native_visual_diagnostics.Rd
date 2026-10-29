\name{etr_plot_planar_trajectories}
\alias{etr_plot_planar_trajectories}
\alias{etr_plot_fpca_component}
\alias{etr_plot_dynamic_time_warping_alignment}
\alias{etr_plot_trajectory_distance_rank_correlations}
\title{Native R descriptive graphics for source-aligned eye-tracking diagnostics}
\description{
Plots planar gaze paths, a selected functional principal component,
a zero-based DTW alignment path, or descriptive rank agreement among
distance specifications, without importing Python.
}
\usage{
etr_plot_planar_trajectories(trajectories, max_curves = 40L,
  alpha = 0.35, invert_y = TRUE, ...)

etr_plot_fpca_component(result, component = 0L, dimension = NULL,
  sd_multiplier = 2, ...)

etr_plot_dynamic_time_warping_alignment(result, ...)

etr_plot_trajectory_distance_rank_correlations(result, ...)
}
\arguments{
\item{trajectories}{Complete native trajectory set with two or more channels.}
\item{max_curves}{Maximum number of curves; \code{NULL} selects all.}
\item{alpha}{Plot line opacity in (0, 1].}
\item{invert_y}{Reverse the screen-space vertical axis.}
\item{result}{Native FPCA, DTW-with-path, or trajectory distance-sensitivity result, as appropriate.}
\item{component}{Zero-based fitted FPCA component index.}
\item{dimension}{Functional dimension, or \code{NULL} for the first fitted channel.}
\item{sd_multiplier}{Positive score standard-deviation multiplier.}
\item{...}{Additional base plotting options.}
}
\value{
The plotting function draws using base R graphics and invisibly returns
auditable plot geometry: selected IDs and limits, the mean and SD curves,
the zero-based DTW path, or the symmetric Spearman matrix.
}
\details{
These are native-R scientific plot-geometry implementations aligned with
public \code{eyetrajectoriespy} 1.2 names. Python plot functions return
Matplotlib Axes objects whereas these functions draw on an R graphics
device and return native R data invisibly. Therefore this is NOT exact
Python output-object equivalence or a fully certified public source
contract. The source-contract certification ledger remains independent.
}
