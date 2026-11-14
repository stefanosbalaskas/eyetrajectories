\name{etr_native_nine_scientific_plots}
\alias{etr_native_nine_scientific_plots}

\title{Native R FPCA, simultaneous-band and recurrence visualizations}
\description{
Nine Python-free native R scientific plots derived from the explicitly
declared FPCA bootstrap, influence, cross-validation, outlier,
functional-band and recurrence analysis result objects.
}

\arguments{
\item{result}{Compatible native R result for the individual plot.}
\item{metric}{Declared influence summary, eigenspace stability or
recurrence functional metric.}
\item{dimension}{Functional-band dimension name; defaults to the first.}
\item{max_points}{Maximum accepted recurrent cells in joint recurrence,
or \code{NULL}. Exceeding it raises an error rather than subsampling.}
\item{show_mean}{Overlay an across-curve mean of functional RQA samples.}
\item{max_curves}{Maximum plotted source curves, or \code{NULL}.}
\item{parameter}{Declared varying RQA sensitivity parameter column.}
\item{filters}{Named list restricting the other varying RQA parameters
to explicit fixed values.}
\item{...}{Further base R graphics options.}
}
\value{
Each routine draws on the active R graphics device and returns its
plotted numeric geometry invisibly. Native R return objects are not
Python Matplotlib Axes and thus do not satisfy full Python source-output
type and graphical backend contracts.
}
\details{
No estimator is recomputed, no hidden smoothing, reweighting or
hypothesis selection is performed, and no declared uncertainty
coverage is extended from the observed time grid to a continuous
domain. RQA sensitivity is descriptive, with other varying parameters
required to be held constant explicitly. Full public source contract
certification requires independent source-domain/schema review.
}
