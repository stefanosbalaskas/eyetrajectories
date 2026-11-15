\name{etr_functional_recovery_evidence}
\alias{etr_functional_recovery_evidence}
\alias{etr_functional_recovery_result}
\alias{etr_functional_recovery_frame}
\alias{etr_functional_recovery_failure_frame}
\alias{etr_functional_recovery_summary_frame}

\title{Native functional recovery evidence and descriptive Monte Carlo diagnostics}
\description{
Independently validated recovery records, per-replicate source metric
tables, scenario failure frequency with binomial Monte Carlo standard
error, descriptive groupwise recovery summaries, and metric-specific
source plots. These methods do not run simulation, fit an estimator,
or infer scientific qualification cutoffs.
}
\usage{
etr_functional_recovery_result(records, metric_definitions = list())
etr_functional_recovery_frame(result)
etr_functional_recovery_failure_frame(result)
etr_functional_recovery_summary_frame(result, python_boundary_mode = TRUE)
}
\arguments{
\item{records}{Nonempty list of explicit scenario replicate records:
scenario_name, replicate (zero-based), seed, status and a named numeric
metrics vector. Replicate and seed integers with magnitude below
\eqn{2^{53}} are retained exactly, including values outside R's integer
storage range. Successful records require nonempty finite metrics;
failed records require no metric values and explicit error_type and
error_message. Optional structured metric_values carry metric metadata,
source and zero-based component.}
\item{metric_definitions}{Optional list of uniquely named semantic
metric metadata records, with name, quantity, direction, units and scope.}
\item{result}{Native functional recovery result produced by the
constructor; not a Python dataclass.}
\item{python_boundary_mode}{Use the frozen NumPy double-precision
pairwise reductions and linear interpolation arithmetic for the
group summary. The default uses R's native arithmetic.}




}
\value{
The constructor returns an explicit \code{etr_functional_recovery_result}
list. The next three methods return tidy numeric R data frames, and
the plot function draws base R graphics and invisibly returns exact
source x, estimate and interval geometry.
}
\details{
Source alignment is with the published \code{eyetrajectoriespy} 1.2.0
FunctionalRecoveryResult and FunctionalRecoveryRecord contracts.
Failures are retained in the denominator, not discarded or silently
imputed. Failure Monte Carlo standard error is
\eqn{\sqrt{p(1-p)/n}}. Group summaries retain sample standard deviation
(ddof=1), type-7 linear quantiles matching NumPy's default linear
quantiles, median, IQR and standard error of the mean. Source
component labels are reported one-based even though structured
scientific source values use zero-based component indices.
Scenario names and grouped metric keys sort by UTF-8 code point.
The explicit Python arithmetic mode preserves source numeric outcomes
for cancellation or overflow at extreme finite inputs, including
nonfinite computed summaries. Python runtime warning behavior is outside
this numerical replay mode.

Monte Carlo summaries are descriptive and impose no automatic
qualification, calibrated coverage, or causal interpretation.
Python accepts immutable dataclasses and returns pandas tables and
Matplotlib Axes; native R uses independently validated lists,
data frames and base graphics. Complete public Python source
return-class/error equivalence remains unapproved pending independent
review of the entire accepted domain.
}
