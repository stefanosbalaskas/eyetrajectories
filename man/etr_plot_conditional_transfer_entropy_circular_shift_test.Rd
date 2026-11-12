\name{etr_plot_conditional_transfer_entropy_circular_shift_test}
\alias{etr_plot_conditional_transfer_entropy_circular_shift_test}
\title{Plot conditional transfer entropy versus source-only circular-shift null}
\usage{
etr_plot_conditional_transfer_entropy_circular_shift_test(result, bins = "auto", python_boundary_mode = FALSE, numpy_auto_policy = "relaxed", strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed conditional TE source-only circular-shift null test result.}
\item{bins}{Positive R integer or auto NumPy bins in source mode.}
\item{python_boundary_mode}{Use source NumPy histogram boundaries for auto bins when TRUE.}
\item{numpy_auto_policy}{Modern relaxed or classic NumPy bin width policy.}
\item{strict_source_record}{Logical scalar for frozen-Python scientific histogram edges/counts and source marker as typed native R artists.}
\item{...}{Legacy R graphics options.}
}
\value{Original numeric source-only conditional TE test histogram geometry returned invisibly by default. Strict mode records source Matplotlib-compatible scientific histogram and vertical observed CTE marker, without claiming Python runtime or causality.}
\description{Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry while retaining original native R numeric calculations, data, graphics and estimator semantics.}
\details{Strict artist records cover a bounded native source-scientific geometry domain. No actual Python Matplotlib Axes, Python dataclass/pandas protocol or exception-class identity, independent complete-domain certification, or pixel-level rendering equivalence is asserted.}
