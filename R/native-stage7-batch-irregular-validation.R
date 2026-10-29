# Native R Stage 7 — validated curve-specific functional time grids.
# Direct counterpart candidates for the published eyetrajectoriespy 1.2.0
# validation.py, irregular.py, and phase.py public functions.
# No function in this file uses reticulate, Python, or a Python bridge.

#' Validate a native R trajectory's strictly increasing common grid
#' @param x Native \code{etr_trajectory_set}.
#' @return Invisibly NULL on success; an error on a malformed grid.
#' @export
etr_validate_common_grid <- function(x) {
  .etr_assert(inherits(x,"etr_trajectory_set"),"trajectories must be a native trajectory set")
  tt <- x$time
  .etr_assert(is.numeric(tt) && is.null(dim(tt)) &&
    length(tt)>=2L && all(is.finite(tt)) &&
    all(diff(tt)>0),"A finite, strictly increasing common grid is required")
  invisible(NULL)
}

#' Validate functional probability simplex values
#' @param values Numeric three-dimensional array (curves, time, dimensions).
#' @param atol Absolute NumPy-style sum and negative-mass tolerance (default 1e-7).
#' @return Invisibly NULL, or a scientifically descriptive error.
#' @export
etr_validate_simplex <- function(values,atol=1e-7) {
  .etr_assert(is.numeric(atol) && length(atol)==1L && is.finite(atol) &&
    atol>=0,"atol must be finite and nonnegative")
  .etr_assert(is.array(values) && is.numeric(values) &&
    length(dim(values))==3L,
    "simplex values must have shape (n_curves, n_time, n_dimensions)")
  .etr_assert(!anyNA(values),"simplex values cannot contain missing values")
  .etr_assert(all(is.finite(values)),
    "simplex values must contain only finite values")
  .etr_assert(!any(values < -atol),"simplex values must be non-negative")
  totals <- apply(values,c(1L,2L),sum)
  # np.allclose(totals,1,atol=atol) uses rtol=1e-5 by default.
  .etr_assert(all(abs(totals-1)<=atol+1e-5),
    "simplex values must sum to one across dimensions at every time point")
  invisible(NULL)
}

#' Fail when any curve's missingness exceeds an explicit tolerance
#' @param x Native common-grid trajectory collection.
#' @param max_missing_fraction Fraction in [0,1), same source contract as Python.
#' @return Invisibly NULL on success, error listing violating curve IDs.
#' @export
etr_validate_no_long_missing_runs <- function(x,max_missing_fraction) {
  etr_validate(x)
  .etr_assert(is.numeric(max_missing_fraction) &&
    length(max_missing_fraction)==1L && is.finite(max_missing_fraction) &&
    max_missing_fraction>=0 && max_missing_fraction<1,
    "max_missing_fraction must be in [0, 1)")
  d <- dim(x$values)
  miss <- vapply(seq_len(d[1L]),function(i)
    mean(vapply(seq_len(d[2L]),function(t)
      any(is.na(x$values[i,t,])),logical(1L))),numeric(1L))
  bad <- which(miss>max_missing_fraction)
  if(length(bad)) stop(length(bad),
    " trajectories exceed max_missing_fraction=",max_missing_fraction,
    ": ",paste(utils::head(x$curve_ids[bad],5L),collapse=", "),call.=FALSE)
  invisible(NULL)
}

#' Construct independent native R irregular trajectories without resampling
#'
#' Each curve has a unique finite increasing time vector and its own
#' numeric sample-by-dimension array. No interpolation is implied.
#' @param time List of numeric curve-specific grids of length >= 2.
#' @param values List of numeric sample-by-dimension matrices.
#' @param curve_ids Distinct nonempty curve identifiers.
#' @param dimension_names Distinct named channels, at least one.
#' @param metadata One-row-per-curve data frame, optional.
#' @param coordinate_system,time_unit Nonempty metadata strings.
#' @param provenance JSON-like named list.
#' @return New \code{etr_irregular_trajectory_set}.
#' @export
etr_irregular_trajectory_set <- function(
    time,values,curve_ids,dimension_names,metadata=NULL,
    coordinate_system="unknown",time_unit="unknown",provenance=list()) {
  .etr_assert(is.list(time) && length(time)>=1L &&
    is.list(values) && length(values)==length(time),
    "irregular time and values must be equally sized nonempty lists")
  n <- length(time)
  .etr_assert(is.character(curve_ids) && length(curve_ids)==n &&
    !anyNA(curve_ids) && all(nzchar(curve_ids)) &&
    !anyDuplicated(curve_ids),"curve_ids must be distinct nonempty strings")
  .etr_assert(is.character(dimension_names) &&
    length(dimension_names)>=1L && !anyNA(dimension_names) &&
    all(nzchar(dimension_names)) && !anyDuplicated(dimension_names),
    "dimension_names must be unique nonempty strings")
  nd <- length(dimension_names)
  for(i in seq_len(n)) {
    t <- time[[i]];v <- values[[i]]
    .etr_assert(is.numeric(t) && is.null(dim(t)) &&
      length(t)>=2L && all(is.finite(t)) && all(diff(t)>0),
      paste0("time[",i,"] must be finite and strictly increasing"))
    .etr_assert(is.matrix(v) && is.numeric(v) &&
      identical(dim(v),c(length(t),nd)),
      paste0("values[",i,"] must match curve time and dimension counts"))
    .etr_assert(!any(is.infinite(v)),
      "irregular trajectory values cannot contain infinity")
  }
  if(is.null(metadata)) metadata <- data.frame(row.names=seq_len(n))
  .etr_assert(is.data.frame(metadata) && nrow(metadata)==n,
    "metadata must have exactly one row per irregular curve")
  .etr_assert(is.character(coordinate_system) &&
    length(coordinate_system)==1L && !is.na(coordinate_system) &&
    nzchar(coordinate_system),"coordinate_system must be a nonempty string")
  .etr_assert(is.character(time_unit) && length(time_unit)==1L &&
    !is.na(time_unit) && nzchar(time_unit),
    "time_unit must be a nonempty string")
  .etr_assert(.etr_provenance_valid(provenance),
    "provenance must be a JSON-like named list")
  structure(list(time=lapply(time,as.numeric),
    values=lapply(values,function(v)matrix(as.numeric(v),nrow=nrow(v),
                                            ncol=ncol(v))),
    curve_ids=curve_ids,dimension_names=dimension_names,
    metadata=metadata,coordinate_system=coordinate_system,
    time_unit=time_unit,provenance=provenance),
    class="etr_irregular_trajectory_set")
}

.etr_irregular_validate_samples <- function(x){
  .etr_assert(inherits(x,"etr_irregular_trajectory_set") && is.list(x),
    "trajectories must be a native irregular trajectory set")
  etr_irregular_trajectory_set(x$time,x$values,x$curve_ids,
    x$dimension_names,x$metadata,x$coordinate_system,x$time_unit,
    x$provenance)
  invisible(TRUE)
}

#' Construct native irregular trajectories from long-format sample data
#'
#' @param data Nonempty long-format data frame.
#' @param curve_columns Nonempty identifier column names.
#' @param time_column Single numeric time column.
#' @param value_columns Numeric measured channel columns.
#' @param metadata_columns Curve-constant metadata column names.
#' @inheritParams etr_irregular_trajectory_set
#' @export
etr_from_irregular_long_native <- function(
    data,curve_columns,time_column,
    value_columns=c("x","y"),metadata_columns=NULL,
    coordinate_system="unknown",time_unit="unknown",provenance=NULL) {
  .etr_assert(is.data.frame(data) && nrow(data)>0L,
    "data must be a nonempty data.frame")
  .etr_assert(is.character(curve_columns) &&
    length(curve_columns)>=1L && all(nzchar(curve_columns)) &&
    !anyDuplicated(curve_columns),"curve_columns must contain at least one identifier")
  .etr_assert(is.character(value_columns) &&
    length(value_columns)>=1L && all(nzchar(value_columns)) &&
    !anyDuplicated(value_columns),
    "value_columns must contain at least one functional dimension")
  .etr_assert(is.character(time_column) && length(time_column)==1L &&
    nzchar(time_column),"time_column must identify the time variable")
  if(is.null(metadata_columns))metadata_columns<-character(0)
  needed<-unique(c(curve_columns,time_column,value_columns,metadata_columns))
  .etr_assert(all(needed %in% names(data)),"Missing columns in irregular data")
  .etr_assert(is.numeric(data[[time_column]]) &&
    all(vapply(data[value_columns],is.numeric,logical(1L))),
    "time and functional values must be numeric")
  .etr_assert(!anyNA(data[c(curve_columns,time_column)]),
    "curve identifiers and time values cannot be missing")
  keys <- do.call(paste,c(lapply(data[curve_columns],as.character),sep="\r"))
  unique_keys <- unique(keys)
  groups <- lapply(unique_keys,function(key)which(keys==key))
  times <- values <- vector("list",length(groups))
  ids <- character(length(groups))
  mds <- vector("list",length(groups))
  for(i in seq_along(groups)){
    idx <- groups[[i]]
    idx <- idx[order(data[[time_column]][idx],method="radix")]
    tt <- as.numeric(data[[time_column]][idx])
    .etr_assert(length(tt)>=2L,
      "Each irregular curve must contain at least two observations")
    .etr_assert(all(is.finite(tt)) && all(diff(tt)>0),
      "Duplicate time points or nonincreasing time within curve")
    times[[i]] <- tt
    values[[i]] <- as.matrix(data[idx,value_columns,drop=FALSE])
    ids[i] <- paste(as.character(unlist(data[idx[1L],curve_columns,
                                             drop=FALSE],use.names=FALSE)),
                    collapse="|")
    md <- as.list(data[idx[1L],c(curve_columns,metadata_columns),
                            drop=FALSE])
    for(col in metadata_columns)
      .etr_assert(length(unique(data[[col]][idx]))==1L,
        paste("Metadata column",col,"varies within curve"))
    mds[[i]] <- md
  }
  md <- do.call(rbind,lapply(mds,function(x)
    as.data.frame(x,stringsAsFactors=FALSE,check.names=FALSE)))
  rownames(md)<-NULL
  audit <- list(source="irregular_long_dataframe_native",
    curve_columns=as.character(curve_columns),
    time_column=time_column,value_columns=as.character(value_columns))
  if(!is.null(provenance)){
    .etr_assert(.etr_provenance_valid(provenance),
      "provenance must be a JSON-like named list")
    audit[names(provenance)]<-provenance
  }
  etr_irregular_trajectory_set(times,values,ids,value_columns,
    metadata=md,coordinate_system=coordinate_system,
    time_unit=time_unit,provenance=audit)
}

#' Common strictly positive time interval observed by all irregular curves
#' @param x Native irregular trajectories.
#' @return Numeric start/end tuple (R length-two vector).
#' @export
etr_common_overlap_interval <- function(x){
  .etr_irregular_validate_samples(x)
  lo <- max(vapply(x$time,function(t)t[1L],numeric(1L)))
  hi <- min(vapply(x$time,function(t)t[length(t)],numeric(1L)))
  .etr_assert(hi>lo,
    "Irregular trajectories do not share a positive common time interval")
  c(lo,hi)
}

#' Construct but do not apply a common irregular-data grid
#' @param x Native irregular trajectories.
#' @param n_time At least two finite integer sample locations.
#' @param domain "overlap" (all curves) or "union" (full observed extent).
#' @param start,end Optional explicit finite domain limits, provided together.
#' @return Finite evenly spaced grid.
#' @export
etr_make_common_grid <- function(x,n_time,domain="overlap",
                                 start=NULL,end=NULL){
  .etr_irregular_validate_samples(x)
  .etr_assert(is.numeric(n_time) && length(n_time)==1L &&
    is.finite(n_time) && n_time>=2 && n_time==as.integer(n_time),
    "n_time must be an integer at least 2")
  .etr_assert(is.character(domain) && length(domain)==1L &&
    !is.na(domain),"domain must be overlap or union")
  .etr_assert(is.null(start)==is.null(end),
    "start and end must be supplied together")
  if(!is.null(start)){
    .etr_assert(is.numeric(start) && length(start)==1L && is.finite(start) &&
      is.numeric(end) && length(end)==1L && is.finite(end),
      "explicit common-grid bounds must be finite numeric scalars")
    lo<-start;hi<-end
  }else if(domain=="overlap"){
    interval<-etr_common_overlap_interval(x)
    lo<-interval[1L];hi<-interval[2L]
  }else if(domain=="union"){
    lo<-min(vapply(x$time,function(t)t[1L],numeric(1L)))
    hi<-max(vapply(x$time,function(t)t[length(t)],numeric(1L)))
  }else stop("domain must be 'overlap' or 'union'",call.=FALSE)
  .etr_assert(hi>lo,"Common-grid end must be greater than start")
  seq(lo,hi,length.out=as.integer(n_time))
}

#' Project curve-specific samples to a declared common grid
#'
#' Linear interpolation never extrapolates. Gaps exceeding max_gap
#' remain explicitly missing inside those spans. PCHIP is deliberately
#' unsupported until independently numerically qualified.
#' @param x Native irregular trajectories.
#' @param grid Finite strictly increasing common grid.
#' @param method "linear"; "pchip" fails closed until qualified.
#' @param max_gap NULL or positive time separation maximum.
#' @return Native common-grid etr_trajectory_set.
#' @export
etr_resample_irregular_to_grid <- function(x,grid,method="linear",
                                           max_gap=NULL) {
  .etr_irregular_validate_samples(x)
  .etr_assert(is.numeric(grid) && is.null(dim(grid)) &&
    length(grid)>=2L && all(is.finite(grid)) &&
    all(diff(grid)>0),"grid must be strictly increasing and finite")
  .etr_assert(identical(method,"linear"),
    "method must be 'linear'; Python pchip is not yet qualified in native R")
  if(!is.null(max_gap))
    .etr_assert(is.numeric(max_gap) && length(max_gap)==1L &&
      is.finite(max_gap) && max_gap>0,"max_gap must be positive")
  n<-length(x$time);nd<-length(x$dimension_names)
  arr<-array(NA_real_,dim=c(n,length(grid),nd))
  for(i in seq_len(n))for(j in seq_len(nd)){
    tt<-x$time[[i]];yy<-x$values[[i]][,j]
    good<-which(is.finite(yy))
    if(length(good)<2L)next
    t<-tt[good];v<-yy[good]
    inside<-which(grid>=t[1L] & grid<=t[length(t)])
    if(length(inside))arr[i,inside,j]<-stats::approx(t,v,xout=grid[inside],
      method="linear",ties="ordered",rule=1L)$y
    if(!is.null(max_gap) && length(t)>=2L)
      for(k in seq_len(length(t)-1L))if(t[k+1L]-t[k]>max_gap)
        arr[i,grid>t[k] & grid<t[k+1L],j]<-NA_real_
  }
  prov<-x$provenance
  prov["irregular_to_grid"]<-list(list(method=method,max_gap=max_gap,
    n_time=as.integer(length(grid)),grid_start=as.numeric(grid[1L]),
    grid_end=as.numeric(grid[length(grid)])))
  etr_trajectory_set(grid,arr,x$curve_ids,x$dimension_names,
    x$metadata,x$coordinate_system,x$time_unit,provenance=prov)
}

#' Build and apply a selected common grid in native R
#' @param x Native irregular trajectories.
#' @param n_time Number of common sample locations.
#' @param domain "overlap" or "union".
#' @inheritParams etr_resample_irregular_to_grid
#' @return Native common-grid trajectory set.
#' @export
etr_resample_irregular_to_common_grid <- function(x,n_time,
    domain="overlap",method="linear",max_gap=NULL){
  g<-etr_make_common_grid(x,n_time=n_time,domain=domain)
  etr_resample_irregular_to_grid(x,g,method=method,max_gap=max_gap)
}

#' Describe native irregular sampling and missingness per curve
#' @param x Native irregular trajectories.
#' @return One row per curve, mirroring the Python columns.
#' @export
etr_irregular_sampling_summary <- function(x){
  .etr_irregular_validate_samples(x)
  n<-length(x$time)
  data.frame(curve_id=x$curve_ids,
    n_samples=as.integer(vapply(x$time,length,integer(1L))),
    time_start=vapply(x$time,function(t)t[1L],numeric(1L)),
    time_end=vapply(x$time,function(t)t[length(t)],numeric(1L)),
    median_interval=vapply(x$time,function(t)stats::median(diff(t)),numeric(1L)),
    max_interval=vapply(x$time,function(t)max(diff(t)),numeric(1L)),
    missing_fraction=vapply(x$values,function(v)mean(is.na(v)),numeric(1L)),
    stringsAsFactors=FALSE,check.names=FALSE)
}

#' Report observed-minus-reference registration landmark deviations
#' @param registration Named R registration result with \code{original},
#'   \code{observed_landmarks}, \code{reference_landmarks}.
#' @return Tidy native R data frame with Python-compatible column names.
#' @export
etr_phase_landmark_frame <- function(registration){
  .etr_assert(is.list(registration) &&
    inherits(registration$original,"etr_trajectory_set"),
    "registration must contain original native trajectory set")
  obs<-registration$observed_landmarks
  reference<-registration$reference_landmarks
  .etr_assert(is.matrix(obs) && is.numeric(obs) &&
    nrow(obs)==length(registration$original$curve_ids),
    "observed_landmarks must be a matrix, one row per curve")
  .etr_assert(is.numeric(reference) &&
    is.null(dim(reference)) && length(reference)==ncol(obs),
    "reference_landmarks must match observed landmark columns")
  n<-nrow(obs);k<-ncol(obs)
  data.frame(curve_id=rep(registration$original$curve_ids,each=k),
    landmark=rep(seq_len(k),times=n),
    observed_time=as.numeric(t(obs)),
    reference_time=rep(as.numeric(reference),times=n),
    timing_deviation=as.numeric(t(obs))-
      rep(as.numeric(reference),times=n),stringsAsFactors=FALSE)
}
