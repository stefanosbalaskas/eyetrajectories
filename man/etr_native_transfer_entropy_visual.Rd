\name{etr_plot_transfer_entropy_sensitivity}
\alias{etr_plot_transfer_entropy_sensitivity}

\title{Native source-aligned transfer-entropy sensitivity and circular-shift graphics}
\description{
Three independent Python-free native R graphics presenting already
estimated discrete transfer-entropy sensitivity, source-only
circular-shift null distributions, and conditional transfer entropy.
No TE estimator is rerun or adjusted by the plots.
}
\usage{
etr_plot_transfer_entropy_sensitivity(result, parameter,
  metric = "transfer_entropy_bits", filters = NULL, ...)
etr_plot_transfer_entropy_circular_shift_test(result, bins = "auto",
  python_boundary_mode = FALSE, numpy_auto_policy = "relaxed", ...)
etr_plot_conditional_transfer_entropy_circular_shift_test(result,
  bins = "auto", python_boundary_mode = FALSE,
  numpy_auto_policy = "relaxed", ...)
}
\arguments{
\item{result}{Native TE parameter sensitivity or circular source-shift
test result, including a complete observed statistic and surrogate
distribution as relevant.}
\item{parameter}{One declared TE sensitivity specification parameter.}
\item{metric}{One native scientific TE sensitivity metric to plot.}
\item{filters}{Named list fixing other varying parameter dimensions.
Ambiguous slices fail rather than silently averaging any cells.}
\item{bins}{Explicit positive integer histogram bin count or
\code{"auto"}. Explicit bins use equal-width source min/max breaks.
The default native R \code{"auto"} retains Sturges for backward
compatibility. With \code{python_boundary_mode=TRUE}, automatic bins
use the selected NumPy finite-data estimator and exact bin counts.}
\item{python_boundary_mode}{Logical. When TRUE with \code{bins="auto"},
use explicitly declared NumPy-style automatic histogram geometry,
without importing or calling Python. Defaults to FALSE.}
\item{numpy_auto_policy}{Either \code{"relaxed"} (the FD/Sqrt/Sturges
width rule observed in modern NumPy) or \code{"classic"} (classic
FD/Sturges fallback observed in older NumPy). Explicit selection is
necessary because frozen Python 1.2 declares \code{numpy>=1.26},
not a single histogram implementation.}
\item{...}{Additional base R graphics arguments.}
}
\value{
Plots render on the active native R graphics device and invisibly
return exact numeric source coordinates or surrogate/observed
statistics and histogram count/bin geometry. These are not Matplotlib
Axes and therefore are not equivalent public Python return types.
}
\details{
The circular-source-shift null is a statistical procedure under an
explicit source wrap-around assumption and is not a causal
identification design. In conditional TE the target and conditioning
processes remain fixed while the source is shifted. The selected
TE multiverse slice is descriptive; no automatic parameter selection
or statistical multiplicity correction is inferred. Full public
source certification requires typed result-schema equivalence,
full NumPy-version-dependent histogram behavior, Matplotlib Axes
return identity, and independent review. Finite numerical histogram
geometry and bin counts now have explicit source-boundary options,
but source-side plotting remains a different graphics backend.
}
