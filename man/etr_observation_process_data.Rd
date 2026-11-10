\name{etr_observation_process_data}
\alias{etr_observation_process_data}
\alias{etr_diagnose_observation_process}
\alias{etr_observation_process_frame}
\alias{etr_observation_process_reporting_text}
\title{Descriptive diagnostics for an explicit observation process}
\description{
Construct a candidate-sample denominator and describe retention, support,
and associations with candidate-time variables and past observations.
}
\usage{
etr_observation_process_data(frame, curve_column, time_column,
  observed_column, group_column = NULL, candidate_predictors = character(),
  predictor_sources = NULL, coordinate_columns = character(),
  time_unit = "unknown", coordinate_system = "unknown", provenance = list())

etr_diagnose_observation_process(process, predictors = NULL,
  history_predictors = character(), eccentricity_reference = NULL,
  risk_set = "all_candidates", time_basis = "linear", time_bins = NULL,
  association_bins = 4L, low_support_threshold = 0.10)

etr_observation_process_frame(result, table = "associations")

etr_observation_process_reporting_text(result)
}
\arguments{
\item{frame}{Data frame with one row per scheduled or otherwise explicit
candidate sample. Each curve has a strictly increasing time sequence in
the supplied rows.}
\item{curve_column, time_column, observed_column}{Names of the curve
identifier, candidate time, and binary observation indicator columns.}
\item{group_column}{Optional metadata column for group summaries.}
\item{candidate_predictors}{Columns available at every candidate row.}
\item{predictor_sources}{Named list or vector declaring
\code{"candidate_time"}, \code{"design"}, or
\code{"external_candidate_time"} per predictor.}
\item{coordinate_columns}{Optional pair of observed coordinate columns with
finite values on retained rows and missing values on unretained rows.}
\item{time_unit, coordinate_system, provenance}{Source metadata.}
\item{process}{An explicit denominator from \code{etr_observation_process_data()}.}
\item{predictors}{Subset of declared candidate-time predictors. The default
uses every declared predictor.}
\item{history_predictors}{Requested prior-history columns.
Available names are \code{previous_observed_x}, \code{previous_observed_y},
\code{previous_observed_eccentricity}, \code{previous_observed_speed},
\code{time_since_last_observed}, \code{preceding_observed_run_length},
and \code{preceding_missing_run_length}.}
\item{eccentricity_reference}{Optional finite pair of coordinate values.}
\item{risk_set}{Evaluate all candidate rows or those immediately following
an observed candidate within a curve, using \code{"after_observed"}.}
\item{time_basis}{\code{"linear"} includes a descriptive time association.
\code{NULL} omits it.}
\item{time_bins, association_bins}{Number of equal-width bins, increasing
edge vector, or \code{NULL}.}
\item{low_support_threshold}{Observed fraction threshold in \eqn{[0,1]}.}
\item{result}{An observation-process diagnostic result.}
\item{table}{One of \code{"global"}, \code{"curves"}, \code{"groups"},
\code{"time"}, \code{"support"}, \code{"associations"}, \code{"profiles"},
\code{"failures"}, or \code{"candidates"}.}
}
\details{
Time summaries use the selected risk set. Regional support uses the full
candidate denominator and identifies empty, zero-observation, and low-support
regions. Predictor associations summarize observed versus missing rows.
History variables use earlier observations within the same curve.
}
\value{
The constructor returns an \code{etr_observation_process_data} record.
The diagnostic function returns an \code{etr_observation_process_diagnostic}
record with summaries, failure rows, and provenance. The frame and reporting
functions return a data frame and a character string, respectively.
}
