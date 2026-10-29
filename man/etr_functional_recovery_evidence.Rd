\name{etr_functional_recovery_result}
\alias{etr_functional_recovery_result}
\alias{etr_functional_recovery_frame}
\alias{etr_functional_recovery_failure_frame}
\alias{etr_functional_recovery_summary_frame}
\alias{etr_plot_functional_recovery_summary}
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
etr_functional_recovery_summary_frame(result)
etr_plot_functional_recovery_summary(summary, metric,
  statistic = "median", ...)
}
\arguments{
\item{records}{Nonempty list of explicit scenario replicate records:
scenario_name, replicate (zero-based), seed, status and a named numeric
metrics vector. Successful records require nonempty finite metrics;
failed records require no metric values and explicit error_type and
error_message. Optional structured metric_values carry metric metadata,
source and zero-based component.}
\item{metric_definitions}{Optional list of uniquely named semantic
metric metadata records, with name, quantity, direction, units and scope.}
\item{result}{Native functional recovery result produced by the
constructor; not a Python dataclass.}
\item{summary}{Native descriptive functional recovery summary data frame.}
\item{metric}{Exact recovery metric name in the summary.}
\item{statistic}{Numeric recovery summary field; median displays
the observed IQR if q25 and q75 are present. Other scalar statistics
are drawn without invented uncertainty intervals.}
\item{...}{Further base R graphics parameters.}
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

Monte Carlo summaries are descriptive and impose no automatic
qualification, calibrated coverage, or causal interpretation.
Python accepts immutable dataclasses and returns pandas tables and
Matplotlib Axes; native R uses independently validated lists,
data frames and base graphics. Complete public Python source
return-class/error equivalence remains unapproved pending independent
review of the entire accepted domain.
}
