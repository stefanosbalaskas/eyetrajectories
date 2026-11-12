\name{etr_plot_transfer_entropy_circular_shift_test}
\alias{etr_plot_transfer_entropy_circular_shift_test}
\title{Plot observed transfer entropy versus circular-shift null histogram}
\usage{
etr_plot_transfer_entropy_circular_shift_test(result, bins = "auto", python_boundary_mode = FALSE, numpy_auto_policy = "relaxed", strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Native precomputed TE circular-shift null test result.}
\item{bins}{Positive integer number of bins or source NumPy automatic histogram bins.}
\item{python_boundary_mode}{Opt-in source NumPy auto-edge calculation when bins is auto.}
\item{numpy_auto_policy}{Explicit relaxed modern-NumPy or classic histogram auto rule.}
\item{strict_source_record}{If TRUE, require source-compatible integer/auto bins, compute NumPy-style exact bin counts and return typed scientific Matplotlib histogram/observed line coordinates; automatically uses NumPy auto binning for auto.}
\item{...}{Legacy R graphics options.}
}
\value{Original numerical surrogate, observed TE and histogram geometry invisibly returned by default. Strict mode records the exact source histogram edges/counts and dashed observed statistic marker; not a Python Matplotlib Axes or a causal test.}
\description{Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry while retaining original native R numeric calculations, data, graphics and estimator semantics.}
\details{Strict artist records cover a bounded native source-scientific geometry domain. No actual Python Matplotlib Axes, Python dataclass/pandas protocol or exception-class identity, independent complete-domain certification, or pixel-level rendering equivalence is asserted.}
