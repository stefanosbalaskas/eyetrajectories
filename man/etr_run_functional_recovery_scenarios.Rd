\name{etr_run_functional_recovery_scenarios}
\alias{etr_run_functional_recovery_scenarios}
\title{Run native functional recovery scenarios with semantic scientific metrics}
\description{
Run declared functional simulation scenarios and score estimator recovery,
without exposing the simulator's latent truth to the estimator. Recoveries
can be returned as named finite scalar metrics or source-aligned semantic
recovery assessments with component/source labels and metric definitions.
}
\usage{
etr_run_functional_recovery_scenarios(
  scenarios, mean, eigenfunctions, estimator, recovery,
  failure_action = "raise"
)
}
\arguments{
\item{scenarios}{Nonempty list of declared native
\code{etr_functional_simulation_scenario} records.}
\item{mean}{Callable generating the functional population mean.}
\item{eigenfunctions}{List of generating functional component callables.}
\item{estimator}{Function of \code{(observations, scenario)}.
Exact generating truth is never passed to this callback.}
\item{recovery}{Function of \code{(fit, truth, scenario)}. Must return
either a named finite numeric metric vector or an
\code{etr_functional_recovery_assessment} containing nonempty
\code{values} of semantically defined metrics and optional
named \code{provenance}. Metric component indices are zero-based
in source records and shown one-based in output keys/frames.}
\item{failure_action}{Either \code{"raise"} to propagate a failure
or \code{"record"} to preserve explicit simulation, fit, or
recovery errors without redraw or fabricated metric output.}
}
\value{
An \code{etr_functional_recovery_result} with one ordered record
per attempted replicate, \code{metric_definitions} describing
the source metric names, and provenance distinguishing the R
random engine from frozen Python. Structured successes retain
\code{metric_values} and \code{assessment_provenance}; failures retain
their status, exception category and message.
}
\details{
Native Student-t and Gaussian functional simulations with dense
or irregular schedules, source power-phase variation, correlated
measurement noise and MCAR/block dropout can be driven by the
declared scenario fields. Scientific truth remains isolated from
the estimator callback and available only to the recovery callback.

Structured assessments are validated for finite values, nonempty
semantic metric definitions, unique component/source tuples, unique
flattened metric keys and stable definitions across replicates.
A conflicting definition for the same metric name is an error
even when \code{failure_action="record"}.

This is an independent native R scientific workflow. It does not
produce Python frozen dataclass objects or establish one-to-one
full-domain source equivalence, identical NumPy PCG64 streams, or
independent scientific certification.
}
