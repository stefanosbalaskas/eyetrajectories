\name{etr_frozen_fpca_workflow_config}
\alias{etr_frozen_fpca_workflow_config}
\alias{etr_frozen_function_on_scalar_workflow_config}
\alias{etr_frozen_recurrence_workflow_config}
\alias{etr_frozen_workflow_decision_record}
\alias{etr_frozen_workflow_step_record}
\alias{etr_run_frozen_native_workflow}
\title{Run explicit frozen-workflow configurations through native R scientific estimators}
\description{
Construct source-field-aligned native R configuration records for frozen
Python 1.2 common-grid FPCA, function-on-scalar regression and recurrence.
Execute these configurations through existing Python-free native R scientific
estimators. The source class names and fields are retained, but source Python
backend, estimation-domain, timing and result dataclass equivalence remain
unqualified and are not independent full-domain certifications.
}
\usage{
etr_frozen_fpca_workflow_config(n_components = 0.95,
  scaling = "none", preprocessing = NULL)
etr_frozen_function_on_scalar_workflow_config(predictors,
  dimensions = NULL, participant_column = NULL, unit = "curve",
  preprocessing = NULL)
etr_frozen_recurrence_workflow_config(curve, dimensions,
  embedding_dimension, delay, radius, delay_units = "samples",
  metric = "euclidean", theiler_window = 0L,
  theiler_window_units = "samples", min_diagonal_length = 2L,
  min_vertical_length = 2L, preprocessing = NULL)
etr_frozen_workflow_decision_record(value, source, criterion = NULL)
etr_frozen_workflow_step_record(name, function_name, status,
  parameters = list(), elapsed_seconds, warnings = character())
etr_run_frozen_native_workflow(trajectories, config, design = NULL)
}
\arguments{
\item{n_components}{Integer component count or finite variance proportion.}
\item{scaling}{One of \code{none} or \code{dimension_sd}.}
\item{preprocessing}{Native frozen preprocessing plan, NULL for an empty plan.}
\item{predictors}{Explicit nonempty distinct regression predictor names.}
\item{dimensions}{Explicit dimension names.}
\item{participant_column}{Optional participant identifier for participant-level inference.}
\item{unit}{\code{curve} or \code{participant}.}
\item{curve}{Zero-based curve index or curve ID.}
\item{embedding_dimension}{Positive integer delay embedding state dimension.}
\item{delay}{Positive embedding delay: integer samples or finite positive physical-time duration (including fractional units).}
\item{radius}{Positive recurrence radius.}
\item{delay_units}{\code{samples} or convertible physical-time units on approximately regular observed grids.}
\item{metric}{Recurrence distance: \code{cityblock}, \code{euclidean}, or \code{chebyshev}.}
\item{theiler_window}{Nonnegative exclusion lag: integer samples or finite nonnegative physical-time duration (including fractional units).}
\item{theiler_window_units}{\code{samples} or convertible physical-time units; resolve on the embedded grid.}
\item{min_diagonal_length}{Minimum diagonal recurrence line length.}
\item{min_vertical_length}{Minimum vertical recurrence line length.}
\item{value}{Explicit scientific decision value.}
\item{source}{Decision provenance \code{analyst}, \code{audited_selector},
\code{workflow_contract} or \code{derived}.}
\item{criterion}{Explicit selector criterion when the decision source is audited.}
\item{name}{Nonempty step name.}
\item{function_name}{Explicit scientific callable identifier.}
\item{status}{Step status: \code{completed}, \code{failed} or \code{skipped}.}
\item{parameters}{Named parameters used by the step.}
\item{elapsed_seconds}{Nonnegative finite observed step elapsed time.}
\item{warnings}{Recorded warnings for the step.}
\item{trajectories}{Native complete common-grid trajectory collection.}
\item{config}{A frozen source-field native R workflow configuration record.}
\item{design}{Curve-aligned regression design data frame for function-on-scalar.}
}
\value{
Constructor functions return native source-field-ordered S3 records,
with unapproved source parity flags. \code{etr_run_frozen_native_workflow}
returns an actual fitted native R workflow object.
}
\details{
Only an empty preprocessing plan is executable, preserving a strict
no-hidden-imputation rule. The native FPCA implementation does not currently
accept floating 1.0 as a variance retention threshold, although the Python
source config constructor does. L1, L2 and L-infinity recurrence distances are supported natively.
Time-unit delays and Theiler windows may be fractional durations (for example 37.5 milliseconds). They resolve to exact integral sample lags on approximately regular grids. Fractional sample-count inputs, nonintegral physical-time conversions, incompatible units and irregular grids fail closed without interpolation.
}
\examples{
cfg <- etr_frozen_fpca_workflow_config(n_components = 1L)
stopifnot(identical(cfg$n_components, 1L))
}
