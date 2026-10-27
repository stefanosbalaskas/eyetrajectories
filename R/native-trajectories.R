# Native trajectory objects never import or initialize Python.
.etr_assert <- function(ok, message) if (!isTRUE(ok)) stop(message, call. = FALSE)

# Python TrajectorySet.provenance is a JSON-like mapping, not a
# pandas/dataframe or backend estimator. Native-R fields keep that distinction.
.etr_provenance_valid <- function(value, depth=0L, mapping=TRUE) {
  if (depth > 32L) return(FALSE)
  # Python TrajectorySet.provenance is dict-like at the root. Scalar
  # JSON values and NULL are only permitted *inside* that mapping,
  # never as a replacement for the top-level provenance dictionary.
  if (mapping && (!is.list(value) || is.object(value)))
    return(FALSE)
  if (is.null(value)) return(!mapping)
  if (is.list(value) && !is.object(value)) {
    keys <- names(value)
    if (mapping) {
      if (length(value) > 0L && (is.null(keys) ||
            anyNA(keys) || any(!nzchar(keys)) || anyDuplicated(keys)))
        return(FALSE)
    } else if (!is.null(keys) &&
               (anyNA(keys) || any(!nzchar(keys)) || anyDuplicated(keys))) {
      return(FALSE)
    }
    for (entry in value)
      if (!.etr_provenance_valid(entry,depth+1L,mapping=FALSE)) return(FALSE)
    return(TRUE)
  }
  is.atomic(value) && is.null(dim(value)) &&
    (is.character(value) || is.numeric(value) || is.logical(value)) &&
    !anyNA(value) && (!is.numeric(value) || all(is.finite(value)))
}

#' Construct a native common-grid trajectory collection
#' @param time Finite, strictly increasing numeric observation times.
#' @param values Numeric array (curve, time, channel); NA represents missing gaze.
#' @param curve_ids Unique curve identifiers; generated if omitted.
#' @param dimension_names Distinct channel names.
#' @param metadata Optional one-row-per-curve data.frame.
#' @param coordinate_system Explicit coordinate semantics.
#' @param time_unit Explicit clock unit.
#' @param provenance Optional JSON-like named R list recording the source,
#'   preprocessing steps and specifications; empty by default. This is a
#'   native representation of Python's provenance mapping, not a fitted model.
#' @export
etr_trajectory_set <- function(time, values, curve_ids = NULL, dimension_names = NULL,
                               metadata = NULL, coordinate_system = "unknown",
                               time_unit = "unknown", provenance = list()) {
  .etr_assert(is.numeric(time) && length(time) >= 2L && all(is.finite(time)) &&
                all(diff(time) > 0), "time must be finite, strictly increasing, length >= 2")
  .etr_assert(is.array(values) && is.numeric(values) && length(dim(values)) == 3L,
              "values must be a numeric 3D array: curve x time x dimension")
  shape <- dim(values)
  .etr_assert(shape[1] >= 1L && shape[2] == length(time) && shape[3] >= 1L,
              "values dimensions must agree with time and contain curves/channels")
  .etr_assert(!any(is.infinite(values) | is.nan(values)),
              "values may contain NA but not NaN or infinity")
  if (is.null(curve_ids)) curve_ids <- paste0("curve_", seq_len(shape[1]))
  if (is.null(dimension_names)) dimension_names <- paste0("dim_", seq_len(shape[3]))
  .etr_assert(is.character(curve_ids) && length(curve_ids) == shape[1] &&
                !anyNA(curve_ids) && all(nzchar(curve_ids)) &&
                !anyDuplicated(curve_ids), "curve_ids must be unique nonempty strings")
  .etr_assert(is.character(dimension_names) && length(dimension_names) == shape[3] &&
                !anyNA(dimension_names) && all(nzchar(dimension_names)) &&
                !anyDuplicated(dimension_names), "dimension_names must be unique strings")
  if (is.null(metadata)) metadata <- data.frame(row.names = seq_len(shape[1]))
  .etr_assert(is.data.frame(metadata) && nrow(metadata) == shape[1],
              "metadata must be a data.frame with one row per curve")
  .etr_assert(is.character(coordinate_system) && length(coordinate_system) == 1L &&
                !is.na(coordinate_system) && nzchar(coordinate_system),
              "coordinate_system must be a single nonempty string")
  .etr_assert(is.character(time_unit) && length(time_unit) == 1L &&
                !is.na(time_unit) && nzchar(time_unit),
              "time_unit must be a single nonempty string")
  .etr_assert(.etr_provenance_valid(provenance),
              "provenance must be a JSON-like named R list with unique nonempty keys")
  structure(list(time = as.numeric(time), values = values,
                 curve_ids = curve_ids, dimension_names = dimension_names,
                 metadata = metadata, coordinate_system = coordinate_system,
                 time_unit = time_unit, provenance = provenance),
            class = "etr_trajectory_set")
}

#' Validate native trajectories
#' @param x Native trajectory collection.
#' @param require_complete Reject missing samples.
#' @export
etr_validate <- function(x, require_complete = FALSE) {
  .etr_assert(inherits(x, "etr_trajectory_set") && is.list(x),
              "x must be a native etr_trajectory_set")
  etr_trajectory_set(x$time, x$values, x$curve_ids, x$dimension_names,
                     x$metadata, x$coordinate_system, x$time_unit,
                     if (is.null(x$provenance)) list() else x$provenance)
  if (isTRUE(require_complete)) {
    .etr_assert(!anyNA(x$values), "complete observations required; handle missing gaze explicitly")
  }
  invisible(TRUE)
}

#' Create native trajectories from long-format gaze samples
#' @param data Data frame containing one row per sample.
#' @param curve_columns One or more curve identifiers.
#' @param time_column Time variable.
#' @param value_columns Measured functional channels.
#' @param metadata_columns Curve-constant columns, if required.
#' @inheritParams etr_trajectory_set
#' @export
etr_from_long <- function(data, curve_columns, time_column = "time",
                          value_columns = c("x", "y"), metadata_columns = NULL,
                          coordinate_system = "unknown", time_unit = "unknown",
                          provenance = NULL) {
  .etr_assert(is.data.frame(data) && nrow(data) > 0L, "data must be a nonempty data.frame")
  .etr_assert(is.character(curve_columns) && length(curve_columns) >= 1L &&
                !anyNA(curve_columns) && !anyDuplicated(curve_columns),
              "curve_columns must be nonempty distinct column names")
  .etr_assert(is.character(value_columns) && length(value_columns) >= 1L &&
                !anyNA(value_columns) && !anyDuplicated(value_columns),
              "value_columns must be nonempty distinct column names")
  needed <- c(curve_columns, time_column, value_columns, metadata_columns)
  .etr_assert(!anyDuplicated(needed), "identifier, time, value and metadata columns must be distinct")
  .etr_assert(all(needed %in% names(data)), "one or more requested columns are missing")
  .etr_assert(all(vapply(data[c(time_column, value_columns)], is.numeric, logical(1))),
              "time and value columns must be numeric")
  .etr_assert(!anyNA(data[curve_columns]) && !anyNA(data[[time_column]]),
              "curve identifiers and time cannot be missing")
  keys <- do.call(paste, c(lapply(data[curve_columns], as.character),
                             sep = "\u001f"))
  ids <- unique(keys)
  idx <- split(seq_len(nrow(data)), factor(keys, levels = ids), drop = TRUE)
  frames <- lapply(idx, function(rows) {
    z <- data[rows, , drop = FALSE]
    z[order(z[[time_column]]), , drop = FALSE]
  })
  grids <- lapply(frames, function(z) z[[time_column]])
  .etr_assert(all(vapply(grids, function(g) length(g) >= 2L &&
                all(is.finite(g)) && all(diff(g) > 0), logical(1))),
              "each curve requires >= 2 unique, strictly increasing finite times")
  .etr_assert(all(vapply(grids, function(g) identical(as.numeric(g), as.numeric(grids[[1]])),
                         logical(1))), "curves do not share an identical grid; resample explicitly")
  n <- length(frames); nt <- length(grids[[1]]); nd <- length(value_columns)
  values <- array(NA_real_, c(n, nt, nd))
  metadata <- data.frame(row.names = seq_len(n))
  for (i in seq_len(n)) {
    z <- frames[[i]]
    values[i, , ] <- as.matrix(z[, value_columns, drop = FALSE])
    for (name in metadata_columns) {
      u <- unique(z[[name]])
      .etr_assert(length(u) == 1L, paste("metadata varies within curve:", name))
    }
  }
  metadata <- do.call(rbind, lapply(frames, function(z)
    z[1L, unique(c(curve_columns, metadata_columns)), drop = FALSE]))
  rownames(metadata) <- NULL
  curve_ids <- vapply(frames, function(z) paste(as.character(z[1, curve_columns, drop = TRUE]),
                                               collapse = "|"), character(1))
  curve_ids <- unname(curve_ids)
  # Python from_long_dataframe includes an explicit source audit.
  provenance_defaults <- list(source="long_dataframe",
    curve_columns=as.character(curve_columns),
    time_column=as.character(time_column),
    value_columns=as.character(value_columns))
  if(!is.null(provenance)) {
    .etr_assert(.etr_provenance_valid(provenance),
                "provenance must be a JSON-like named R list")
    provenance_defaults[names(provenance)] <- provenance
  }
  etr_trajectory_set(grids[[1]], values, curve_ids, value_columns,
                     metadata, coordinate_system, time_unit,
                     provenance=provenance_defaults)
}

#' Return all samples in tidy long form
#' @param x Native trajectory collection.
#' @export
etr_as_long <- function(x) {
  etr_validate(x)
  n <- dim(x$values)[1]; nt <- length(x$time)
  result <- data.frame(curve_id = rep(x$curve_ids, each = nt),
                       time = rep(x$time, times = n), stringsAsFactors = FALSE)
  for (j in seq_along(x$dimension_names))
    result[[x$dimension_names[j]]] <- as.vector(t(x$values[, , j]))
  result
}

#' Extract selected trajectories
#' @param x Native collection.
#' @param curves Integer indices or curve IDs (never silently reorders).
#' @export
etr_subset <- function(x, curves) {
  etr_validate(x)
  if (is.character(curves)) {
    .etr_assert(all(curves %in% x$curve_ids), "unknown curve identifier")
    curves <- match(curves, x$curve_ids)
  }
  .etr_assert(is.numeric(curves) && length(curves) >= 1L &&
                all(is.finite(curves)) && all(curves == as.integer(curves)) &&
                all(curves >= 1L & curves <= length(x$curve_ids)) &&
                !anyDuplicated(curves), "curves must be unique valid 1-based indices")
  etr_trajectory_set(x$time, x$values[curves, , , drop = FALSE],
                     x$curve_ids[curves], x$dimension_names,
                     x$metadata[curves, , drop = FALSE],
                     x$coordinate_system, x$time_unit,
                     if (is.null(x$provenance)) list() else x$provenance)
}

#' Retrieve one channel as curve-by-time matrix
#' @param x Native collection.
#' @param dimension Character channel name or integer index.
#' @export
etr_dimension <- function(x, dimension) {
  etr_validate(x)
  if (is.character(dimension)) dimension <- match(dimension, x$dimension_names)
  .etr_assert(length(dimension) == 1L && !is.na(dimension) &&
                is.numeric(dimension) && dimension %in% seq_along(x$dimension_names),
              "dimension must be a valid channel name or index")
  out <- x$values[, , dimension, drop = FALSE]
  dim(out) <- dim(out)[1:2]
  dimnames(out) <- list(x$curve_ids, as.character(x$time))
  out
}

#' Describe native trajectory dimensions and missingness
#' @param x Native collection.
#' @export
etr_summary <- function(x) {
  etr_validate(x)
  data.frame(n_curves = dim(x$values)[1], n_time = length(x$time),
             n_dimensions = dim(x$values)[3], start = x$time[1],
             end = utils::tail(x$time, 1), missing_samples = sum(is.na(x$values)),
             coordinate_system = x$coordinate_system, time_unit = x$time_unit)
}
