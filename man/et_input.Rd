\name{et_from_long}
\alias{et_from_long}
\alias{et_simulate_planar}
\title{Construct trajectories using the Python backend}
\description{
Convert an R long-format data frame to a Python TrajectorySet,
or generate explicitly synthetic planar eye-tracking trajectories.
}
\usage{
et_from_long(data, curve_columns, time_column = "time",
             value_columns = c("x", "y"), metadata_columns = NULL,
             coordinate_system = "unknown", time_unit = "unknown")

et_simulate_planar(n_participants = 20L, trials_per_participant = 6L,
                   n_time = 121L, duration = 2, random_state = 42L)
}
\arguments{
\item{data}{An R data.frame with one row per sample.}
\item{curve_columns}{Character vector of trajectory identifiers.}
\item{time_column}{Name of the time column.}
\item{value_columns}{Names of numerical measurement columns.}
\item{metadata_columns}{Optional curve-constant metadata column names.}
\item{coordinate_system}{Semantics of coordinates, e.g. \code{"pixels"}.}
\item{time_unit}{Unit for the time column, e.g. \code{"ms"}.}
\item{n_participants}{Number of simulated participants.}
\item{trials_per_participant}{Simulated trials per participant.}
\item{n_time}{Time samples per simulated curve.}
\item{duration}{Simulated duration.}
\item{random_state}{Seed for deterministic simulation.}
}
\value{Python \code{TrajectorySet} object.}
\details{
No data cleaning, interpolation, or duplicate-time aggregation occurs.
All curves must share a common time grid in \code{et_from_long()}.
These are Python bridge functions, not independently implemented R methods.
}
\examples{
\dontrun{
gaze <- et_simulate_planar(n_participants = 5L, random_state = 7L)
}
}
