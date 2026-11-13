\name{etr_list_mathematical_contracts}
\alias{etr_list_mathematical_contracts}
\alias{etr_get_mathematical_contract}
\alias{etr_mathematical_contract_frame}

\title{Published Python 1.2 mathematical contracts and native nonlinear sensitivity plots}
\description{
Read-only native metadata access to all 41 scientific mathematical
contracts and 88 API-function rows from the published Python 1.2.0
source, plus three Python-free visualizations of declared nonlinear
parameter sensitivity results. No estimator is invoked by the catalog.
}
\usage{
etr_list_mathematical_contracts()
etr_get_mathematical_contract(..., name, python_boundary_mode = FALSE)
etr_mathematical_contract_frame()
etr_plot_kantz_sensitivity(result, parameter,
  response = "exponent", filters = NULL, ...)
etr_plot_lyapunov_sensitivity(result, parameter,
  response = "exponent", filters = NULL, ...)
etr_plot_windowed_rqa_sensitivity(result, curve, metric, ...)
}
\arguments{
\item{name}{An exact mathematical source contract key or registered
public Python 1.2 function name.}
\item{python_boundary_mode}{Use the frozen Python call boundary. Supply
the name positionally or with the exact \code{name} argument. For
dimensioned arrays, the joint sparse contract key and its public API
name are accepted in a single cell. Other single-cell arrays signal a
type error, and empty or multi-cell arrays signal an ambiguous-value
error.}
\item{result}{Existing native Kantz, Rosenstein or multiscale
windowed-RQA sensitivity result; not a Python object.}
\item{parameter}{One sensitivity parameter column to vary.}
\item{response}{An explicitly supported numeric sensitivity statistic.}
\item{filters}{Named list holding other varying sensitivity columns
constant. Ambiguous duplicate parameter values cause errors instead of
silent averaging.}
\item{curve}{Exact curve identifier or zero-based source curve index.}
\item{metric}{Named functional windowed-RQA metric.}
\item{...}{For lookup, one positional name when \code{name} is omitted.
For plotting, additional base R graphics arguments.}
}
\value{
\code{etr_list_mathematical_contracts()} returns 41 named semantic
S3 records; \code{etr_get_mathematical_contract()} returns one such
record; \code{etr_mathematical_contract_frame()} returns all 88 ordered
rows in a six-column R data frame (contract_key, title, function,
latex, site_anchor and scope), retaining source equation text and
documentation order. Plots return original numeric geometry invisibly.
}
\details{
Invalid name types and unregistered strings signal
\code{etr_mathematical_contract_type_error} and
\code{etr_mathematical_contract_key_error}, respectively.
The explicit boundary mode uses \code{etr_mathematical_contract_value_error}
for ambiguous array truth values. It models the shaped-array boundary for
ordinary R arrays and NumPy 2.3.5. Custom Python equality methods are outside
the represented domain.

The metadata source is an immutable snapshot of public published
eyetrajectoriespy version 1.2.0. Direct Python 1.2 contract tests check
all 88 table rows and all fields of the 41 registry objects. Native R
returns S3 lists and a data frame instead of Python frozen dataclasses,
tuples and pandas, so no full public return-class parity is claimed.
The numerical plots likewise use base R graphics and return geometry
rather than Python Matplotlib Axes. Source contract approval is pending
complete type/domain review and independent reviewer signoff.
}
