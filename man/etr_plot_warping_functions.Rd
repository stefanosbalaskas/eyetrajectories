\name{etr_plot_warping_functions}
\alias{etr_plot_warping_functions}
\title{Plot native functional registration warping maps and displacements}
\usage{
etr_plot_warping_functions(
    result, displacement = FALSE,
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Real native landmark-registration result with finite fitted original-time warp functions and the identical original functional grid.}
\item{displacement}{If TRUE, plot original h(t)-t with a zero-reference line. If FALSE, plot the actual h(t) source-time map and diagonal identity reference.}
\item{strict_source_record}{Return one-panel source-scientific native R line artist geometry for all original curves with alpha 0.3 and the source identity/zero-reference behavior; this is not a Python Matplotlib \code{Axes}.}
\item{...}{Native base plotting arguments.}
}
\value{Default invisible native original time-by-curve warp data frame. Strict mode returns the source-scientific plotting geometry, including reference line, axes, legends and original numeric warps.}
\description{Uses registered native landmark warp functions without re-estimating or modifying participant trajectories. Frozen Python 1.2 source line data and labels are directly compared in tests. Matplotlib runtime object identity and pixel equality are not certified.}
