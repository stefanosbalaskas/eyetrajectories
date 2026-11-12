\name{etr_plot_functional_simulation_phase_warps}
\alias{etr_plot_functional_simulation_phase_warps}
\title{Inspect actual functional simulation phase warps against identity time}
\usage{
etr_plot_functional_simulation_phase_warps(
    result, max_curves = 20L, alpha = 0.35,
    strict_source_record = FALSE)
}
\arguments{
\item{result}{Genuine native simulated functional truth, including phase warps evaluated on the same truth grid.}
\item{max_curves}{Positive whole number of first-seen curves, or \code{NULL} for all curves.}
\item{alpha}{Finite transparency within (0,1].}
\item{strict_source_record}{If TRUE, return a source-ordered line artist record with dashed identity mapping followed by original retained phase warps, instead of the default R numeric-geometry list.}
}
\value{Default invisible time grid, identity and warps; strict mode provides inspectable source-scientific line and legend data.}
\description{The source-comparable geometry draws the identity time map followed by actual native phase functions in original curve order, with the same number of curves and transparency as frozen Python 1.2. Renderer remains native base R and never returns real Python Matplotlib axes.}
