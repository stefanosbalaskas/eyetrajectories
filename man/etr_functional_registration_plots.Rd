\name{etr_plot_reconstruction_curve}
\alias{etr_plot_reconstruction_curve}

\title{Native functional reconstruction and landmark registration visualization}
\description{
Three stable, unnumbered Python-free public scientific plotting methods:
integrated FPCA reconstruction error against retained component count,
original versus registered complete functional curves, and source
landmark time warping/displacement curves.
}
\usage{
etr_plot_reconstruction_curve(reconstruction_summary, ...)
etr_plot_registration(result, dimension = NULL, max_curves = 20L, ...)
etr_plot_warping_functions(result, displacement = FALSE, ...)
}
\arguments{
\item{reconstruction_summary}{An FPCA reconstruction result data frame
with numeric \code{n_components} and \code{mean_integrated_rmse} columns.}
\item{result}{A complete native \code{etr_landmark_registration} object
with original and registered trajectories on a common time grid.}
\item{dimension}{Optional registered physical/functional channel name.}
\item{max_curves}{Positive integer maximum number of original and
registered curves to show.}
\item{displacement}{If \code{TRUE}, show \eqn{h(t)-t} instead of the
warped source time \eqn{h(t)}.}
\item{...}{Additional base graphics arguments.}
}
\value{
Plots are rendered on an R graphics device, and exact source
numerical geometry is returned invisibly in data-frame or list form.
}
\details{
Original and registered functions appear on distinct panels, as in
the published Python 1.2 source. Identity warping is plotted for
reference without changing original scientific time units. No
smoothing, numerical integration or FPCA refit is undertaken by these
plotting functions. Python's public source returns Matplotlib Axes or
figures; these R functions use base graphics and return native
numerical geometry instead. Full public Python source-contract
certification is therefore not implied by numeric fixture parity.
}
