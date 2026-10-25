#' Convert an R long-format gaze data frame into Python trajectories
#'
#' This function does not impute, smooth, interpolate, or aggregate observations.
#' Every curve must have a common strictly increasing time grid. Duplicate
#' time points are rejected by the Python implementation.
#' @param data An R data.frame with one row per gaze observation.
#' @param curve_columns Names of one or more curve identifier columns.
#' @param time_column Name of sample-time column.
#' @param value_columns Names of functional channel columns.
#' @param metadata_columns Optional curve-constant metadata columns.
#' @param coordinate_system Explicit coordinate semantics.
#' @param time_unit Explicit time units.
#' @export
et_from_long <- function(
    data,
    curve_columns,
    time_column = "time",
    value_columns = c("x", "y"),
    metadata_columns = NULL,
    coordinate_system = "unknown",
    time_unit = "unknown") {
  if (!is.data.frame(data)) {
    stop("data must be an R data.frame", call. = FALSE)
  }
  if (!is.character(curve_columns) || !length(curve_columns) ||
      anyNA(curve_columns) || any(!nzchar(curve_columns))) {
    stop("curve_columns must contain one or more nonempty column names", call. = FALSE)
  }
  if (!is.character(time_column) || length(time_column) != 1L ||
      is.na(time_column) || !nzchar(time_column)) {
    stop("time_column must be a nonempty column name", call. = FALSE)
  }
  if (!is.character(value_columns) || !length(value_columns) ||
      anyNA(value_columns) || any(!nzchar(value_columns))) {
    stop("value_columns must contain one or more nonempty column names", call. = FALSE)
  }
  if (!is.null(metadata_columns) &&
      (!is.character(metadata_columns) || anyNA(metadata_columns) ||
       any(!nzchar(metadata_columns)))) {
    stop("metadata_columns must be NULL or a character vector", call. = FALSE)
  }
  expected <- unique(c(curve_columns, time_column, value_columns, metadata_columns))
  missing <- setdiff(expected, names(data))
  if (length(missing)) {
    stop(sprintf("Missing columns: %s", paste(missing, collapse = ", ")), call. = FALSE)
  }
  et_call(
    "from_long_dataframe",
    data,
    curve_columns = curve_columns,
    time_column = time_column,
    value_columns = value_columns,
    metadata_columns = metadata_columns,
    coordinate_system = coordinate_system,
    time_unit = time_unit,
    require_common_grid = TRUE
  )
}

#' Simulate repeated two-dimensional gaze trajectories
#'
#' Generates explicitly synthetic trajectories for examples and bridge testing.
#' @param n_participants Number of participants.
#' @param trials_per_participant Number of trials per participant.
#' @param n_time Samples per trajectory.
#' @param duration Time duration.
#' @param random_state Reproducible Python RNG seed.
#' @export
et_simulate_planar <- function(
    n_participants = 20L,
    trials_per_participant = 6L,
    n_time = 121L,
    duration = 2,
    random_state = 42L) {
  et_call(
    "simulate_planar_trajectories",
    n_participants = as.integer(n_participants),
    trials_per_participant = as.integer(trials_per_participant),
    n_time = as.integer(n_time),
    duration = as.numeric(duration),
    random_state = as.integer(random_state)
  )
}
