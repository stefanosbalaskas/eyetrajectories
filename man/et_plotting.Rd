\name{et_plot_planar}
\alias{et_plot_planar}
\alias{et_plot_fpca_variance}
\alias{et_save_plot}
\title{Python matplotlib plot helpers}
\description{Produce and export eye-trajectory and FPCA figures using matplotlib.}
\usage{
et_plot_planar(trajectories, max_curves = 40L,
               alpha = 0.35, invert_y = TRUE)

et_plot_fpca_variance(fit, cumulative = TRUE)

et_save_plot(axes, file, dpi = 150L)
}
\arguments{
\item{trajectories}{Python TrajectorySet object.}
\item{max_curves}{Number of paths to plot; \code{NULL} means all.}
\item{alpha}{Path opacity.}
\item{invert_y}{Invert screen Y axis.}
\item{fit}{Python FPCAResult object.}
\item{cumulative}{Plot cumulative component variance.}
\item{axes}{Python matplotlib Axes object.}
\item{file}{Output file path with supported image extension.}
\item{dpi}{Resolution of raster output.}
}
\value{
Plotting functions return matplotlib Axes proxies, not native R plots.
\code{et_save_plot()} invisibly returns the destination file name.
}
\examples{
\dontrun{
gaze <- et_simulate_planar()
ax <- et_plot_planar(gaze)
et_save_plot(ax, "paths.png")
}
}
