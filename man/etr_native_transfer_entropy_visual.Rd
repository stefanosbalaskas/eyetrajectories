\name{etr_plot_transfer_entropy_sensitivity}
\alias{etr_plot_transfer_entropy_sensitivity}
\alias{etr_plot_transfer_entropy_circular_shift_test}
\alias{etr_plot_conditional_transfer_entropy_circular_shift_test}
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
etr_plot_transfer_entropy_circular_shift_test(result, bins = "auto", ...)
etr_plot_conditional_transfer_entropy_circular_shift_test(result,
  bins = "auto", ...)
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
The R automatic \code{"auto"} uses Sturges and is not the same as
Python/NumPy automatic FD/Sturges bin selection.}
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
Python NumPy automatic histogram binning and independent review.
}
