\name{etr_plot_kantz_sensitivity}
\alias{etr_plot_kantz_sensitivity}
\title{Plot source scientific Kantz parameter sensitivity}
\usage{
etr_plot_kantz_sensitivity(result, parameter, response = "exponent", filters = NULL,
  strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed Kantz parameter sensitivity result with finite declared source table.}
\item{parameter}{Exact numerical parameter varied in a unique source sensitivity slice.}
\item{response}{One of the supported exponent, fit quality or reference-count measures.}
\item{filters}{Optional named exact values holding other sensitivity parameters fixed.}
\item{strict_source_record}{If TRUE return a typed native R record of the frozen Python scientific Matplotlib artists instead of the original numeric table.}
\item{...}{Legacy base R plotting options.}
}
\value{Original numerical Kantz sensitivity slice returned invisibly by default; strict mode gives the original o-marker line, source labels, physical exponent unit, and dashed/dotted zero reference for the exponent response. It does not return a Python Axes object.}
\description{Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry while retaining original native R numeric calculations, data, graphics and estimator semantics.}
\details{Strict artist records cover a bounded native source-scientific geometry domain. No actual Python Matplotlib Axes, Python dataclass/pandas protocol or exception-class identity, independent complete-domain certification, or pixel-level rendering equivalence is asserted.}
