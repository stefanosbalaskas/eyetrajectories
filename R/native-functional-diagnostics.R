# Stage 9: independent Python-free R functional diagnostics and transformations.
# Source: published eyetrajectoriespy 1.2.0 (compositional.py, fpca.py,
# analysis.py, sparse.py, registration.py, phase.py).
# Inputs remain native R containers; no reticulate or Python use.

.etr_fpca_index <- function(index, n, label) {
  .etr_assert(is.numeric(index) && length(index)==1L &&
    is.finite(index) && index==as.integer(index) && n>=1L,
    paste(label,"must be one finite integer"))
  as.integer(index %% n)+1L  # Python-style negative/zero-based reference dimension
}

.etr_fpca_diagnostic_fit <- function(result) {
  .etr_assert(inherits(result,"etr_fpca") &&
    is.matrix(result$mean) && is.array(result$components) &&
    length(dim(result$components))==3L &&
    is.matrix(result$scores) &&
    identical(dim(result$components)[2:3],dim(result$mean)) &&
    nrow(result$scores)==length(result$curve_ids) &&
    ncol(result$scores)==dim(result$components)[1L] &&
    result$n_components==ncol(result$scores),
    "result must be a compatible native FPCA fit")
  invisible(result)
}

# Python np.asarray(..., dtype=float) accepts regular nested sequences.
# Convert one useful class of those inputs without Python/reticulate.
# Full Python coercion and nonfinite/epsilon semantics remain unqualified.
.etr_simplex_nested_input <- function(values) {
  if(!is.list(values) || is.data.frame(values) ||
     !is.null(dim(values))) return(values)
  n<-length(values)
  .etr_assert(n>=1L && is.list(values[[1L]]) &&
    length(values[[1L]])>=1L,
    "simplex nested input requires nonempty curve/time dimensions")
  nt<-length(values[[1L]])
  k<-length(values[[1L]][[1L]])
  .etr_assert(k>=1L,"nested simplex must contain at least one dimension")
  out<-array(NA_real_,c(n,nt,k))
  for(i in seq_len(n)) {
    .etr_assert(is.list(values[[i]]) &&
      length(values[[i]])==nt,
      "simplex nested input must have rectangular time dimensions")
    for(t in seq_len(nt)) {
      cell<-values[[i]][[t]]
      .etr_assert(is.atomic(cell) && is.null(dim(cell)) &&
        !is.factor(cell) && length(cell)==k &&
        (is.numeric(cell)||is.logical(cell)||is.character(cell)),
        "simplex nested input must have equal scalar dimensions")
      out[i,t,]<-suppressWarnings(as.numeric(cell))
    }
  }
  out
}

#' Native additive log-ratio transformation for compositional trajectories
#' @param values Numeric array of shape curve by time by dimension.
#' @param reference_dimension Python-style zero-based reference index (-1 = last).
#' @param epsilon Positive clipping floor, part of the scientific specification.
#' @param python_boundary_mode Explicitly reproduce Python 1.2 exceptional
#'   NaN/Inf propagation on the inspected scalar/array boundary. FALSE
#'   preserves the finite-only native scientific contract; this option
#'   does not certify the full Python input/return contract.
#' @return Three-dimensional array with the reference channel removed.
#' @export
etr_alr_transform <- function(values,reference_dimension=-1L,epsilon=1e-8,
    python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode) &&
    length(python_boundary_mode)==1L && !is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  if(isTRUE(python_boundary_mode)) {
    # Frozen Python 1.2 only checks epsilon <= 0: NaN and +Inf pass
    # the comparison and may propagate nonfinite log-ratios.
    .etr_assert(is.numeric(epsilon) && length(epsilon)==1L &&
      (is.nan(epsilon) || (!is.na(epsilon) && epsilon>0)),
      "epsilon must satisfy frozen Python 1.2 epsilon > 0 or NaN")
  } else {
    .etr_assert(is.numeric(epsilon) && length(epsilon)==1L &&
      is.finite(epsilon) && epsilon>0,"epsilon must be positive and finite")
  }
  values<-.etr_simplex_nested_input(values)
  # NumPy's published np.asarray(values, dtype=float) also accepts 3-D
  # numeric-string and Boolean arrays. Retain native fail-closed checks for nonfinite
  # and malformed values; conversion alone never approves full parity.
  if(is.array(values) &&
      (is.character(values)||is.logical(values)) &&
      length(dim(values))==3L) {
    numeric_values<-suppressWarnings(as.numeric(values))
    if(all(is.finite(numeric_values)))
      values<-array(numeric_values,dim=dim(values))
  }
  etr_validate_simplex(values)
  d<-dim(values); k<-d[3L]
  # Published Python 1.2 accepts a one-channel simplex and returns an
  # empty last-axis ALR array; inverse_alr maps it back to all ones.
  .etr_assert(k>=1L,"ALR requires at least one simplex dimension")
  ref<-.etr_fpca_index(reference_dimension,k,"reference_dimension")
  clipped<-pmax(values,epsilon)
  totals<-apply(clipped,c(1L,2L),sum)
  clipped<-sweep(clipped,c(1L,2L),totals,"/")
  others<-setdiff(seq_len(k),ref)
  out<-array(NA_real_,c(d[1L],d[2L],k-1L))
  for(j in seq_along(others))
    out[,,j]<-log(clipped[,,others[j]]/clipped[,,ref])
  out
}

#' Recover simplex-valued trajectories from additive log-ratios
#' @param transformed Finite numeric 3D ALR array in default mode.
#' @param python_boundary_mode When TRUE, reproduce Python 1.2 nonfinite
#'   exponentiation and normalization on inspected numeric arrays.
#'   The default keeps the native scientific finite-only contract.
#' @param reference_dimension Python-style zero-based reference channel.
#' @param n_dimensions Original number of simplex channels.
#' @export
etr_inverse_alr <- function(transformed,reference_dimension,n_dimensions,
    python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode) &&
    length(python_boundary_mode)==1L && !is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  .etr_assert(is.numeric(n_dimensions) && length(n_dimensions)==1L &&
    is.finite(n_dimensions) && n_dimensions>=1L &&
    n_dimensions==as.integer(n_dimensions),
    "n_dimensions must be an integer >= 1")
  # Source NumPy np.asarray() accepts regular 3D nested scalar sequences
  # for inverse logits as well as for forward ALR inputs. Preserve the exact
  # input geometry in native R (including zero/negative logits).
  transformed<-.etr_simplex_nested_input(transformed)
  # Frozen Python np.asarray(..., dtype=float) accepts numeric-string
  # and Boolean arrays. Convert that finite, rectangular domain without expanding
  # the native overflow/nonfinite scientific contract.
  if(is.array(transformed) &&
      (is.character(transformed)||is.logical(transformed)) &&
      length(dim(transformed))==3L) {
    numeric_values<-suppressWarnings(as.numeric(transformed))
    if(all(is.finite(numeric_values)) ||
        (isTRUE(python_boundary_mode) &&
          all(!is.na(numeric_values) | is.nan(numeric_values))))
      transformed<-array(numeric_values,dim=dim(transformed))
  }
  .etr_assert(is.array(transformed) && is.numeric(transformed) &&
    length(dim(transformed))==3L &&
    dim(transformed)[3L]==n_dimensions-1L &&
    (if(isTRUE(python_boundary_mode))
      all(!is.na(transformed) | is.nan(transformed))
     else all(is.finite(transformed))),
    "transformed data have incompatible dimensions or nonfinite values")
  d<-dim(transformed)
  ref<-.etr_fpca_index(reference_dimension,as.integer(n_dimensions),
                   "reference_dimension")
  others<-setdiff(seq_len(n_dimensions),ref)
  out<-array(1,c(d[1L],d[2L],as.integer(n_dimensions)))
  for(j in seq_along(others))out[,,others[j]]<-exp(transformed[,,j])
  denom<-apply(out,c(1L,2L),sum)
  if(!isTRUE(python_boundary_mode))
    .etr_assert(all(is.finite(denom) & denom>0),
      "inverse ALR exponentiation overflowed; cannot normalize the simplex")
  sweep(out,c(1L,2L),denom,"/")
}

#' Plot-ready mean and score-SD trajectories for one FPCA component
#' @param result Native etr_fpca fit.
#' @param component Zero-based component index, as in Python.
#' @param sd_multipliers Finite score-standard-deviation multipliers.
#' @return Array of shape multiplier x time x dimension.
#' @export
etr_component_trajectories <- function(result,component,
    sd_multipliers=c(-2,-1,0,1,2)) {
  .etr_fpca_diagnostic_fit(result)
  .etr_assert(is.numeric(component) && length(component)==1L &&
    is.finite(component) && component==as.integer(component) &&
    component>=0L && component<result$n_components,
    "component is outside the fitted range")
  .etr_assert(is.numeric(sd_multipliers) && length(sd_multipliers)>=1L &&
    all(is.finite(sd_multipliers)),"sd_multipliers must be finite")
  which_component<-as.integer(component)+1L
  variance<-result$explained_variance[which_component]
  .etr_assert(is.finite(variance) && variance>=0,
    "component variance is invalid")
  out<-array(NA_real_,c(length(sd_multipliers),dim(result$mean)))
  for(i in seq_along(sd_multipliers))
    out[i,,]<-result$mean +
      sd_multipliers[i]*sqrt(variance)*result$components[which_component,,]
  out
}

#' Smallest retained FPCA component count reaching a variance threshold
#' @param result Native etr_fpca fit.
#' @param threshold Target cumulative fraction in (0, 1].
#' @return Integer count. Mirrors Python searchsorted: may exceed fitted k
#'   if the fitted components do not jointly reach the requested fraction.
#' @export
etr_select_n_components <- function(result,threshold=0.95) {
  .etr_fpca_diagnostic_fit(result)
  .etr_assert(is.numeric(threshold) && length(threshold)==1L &&
    is.finite(threshold) && threshold>0 && threshold<=1,
    "threshold must be in (0, 1]")
  x<-which(cumsum(result$explained_variance_ratio)>=threshold)
  as.integer(if(length(x))x[1L] else result$n_components+1L)
}

#' Tidy native FPCA score frame, with configurable component prefix
#' @param result Native etr_fpca fit.
#' @param prefix Single nonmissing string.
#' @export
etr_fpca_score_frame <- function(result,prefix="FPC") {
  .etr_fpca_diagnostic_fit(result)
  .etr_assert(is.character(prefix) && length(prefix)==1L && !is.na(prefix),
    "prefix must be a single nonmissing string")
  scores<-as.data.frame(result$scores)
  names(scores)<-paste0(prefix,seq_len(result$n_components))
  data.frame(curve_id=result$curve_ids,scores,row.names=NULL,
             check.names=FALSE,stringsAsFactors=FALSE)
}

#' Pairwise Euclidean distances in native fitted FPCA score space
#' @param fpca Native etr_fpca fit.
#' @param n_components Retained fitted score columns (NULL means all).
#' @param python_boundary_mode When TRUE, additionally accept a minimal
#'   score-bearing R environment as a native analogue of Python's
#'   duck-typed objects, and a bounded Matrix-package sparse score array.
#'   Other Python-specific classes and error types
#'   remain outside the audited subset.
#' @return Unlabelled symmetric numeric matrix.
#' @export
etr_score_distance_matrix <- function(fpca,n_components=NULL,
    python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode) &&
    length(python_boundary_mode)==1L && !is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  # sklearn pairwise_distances accepts scipy sparse score arrays.
  # Provide a bounded native analogue for Matrix objects in explicit
  # source-compatibility mode. The normal native scientific default
  # continues to require a dense numeric matrix.
  source_scores <- NULL
  if(inherits(fpca,"etr_fpca") || is.list(fpca) ||
      (isTRUE(python_boundary_mode) && is.environment(fpca)))
    source_scores <- fpca$scores
  if(isTRUE(python_boundary_mode) && inherits(source_scores,"Matrix")) {
    .etr_assert(as.double(nrow(source_scores)) *
      as.double(ncol(source_scores)) <= 2e6,
      "sparse score matrix exceeds bounded native densification domain")
    source_scores <- as.matrix(source_scores)
  }
  if(inherits(fpca,"etr_fpca")) {
    .etr_fpca_diagnostic_fit(fpca)
  } else {
    # Published Python 1.2 uses only .scores and .n_components, with
    # duck-typed FPCA-compatible objects. Permit that minimal finite
    # matrix contract without pretending all Python object types port.
    .etr_assert((is.list(fpca) ||
      (isTRUE(python_boundary_mode) && is.environment(fpca)))&&
      is.matrix(source_scores)&&
      (is.numeric(source_scores)||is.character(source_scores)||
        is.logical(source_scores))&&
      nrow(source_scores)>=1L&&ncol(source_scores)>=1L&&
      all(is.finite(suppressWarnings(as.numeric(source_scores))))&&
      is.numeric(fpca$n_components)&&
      length(fpca$n_components)==1L&&
      is.finite(fpca$n_components)&&
      fpca$n_components==as.integer(fpca$n_components)&&
      fpca$n_components>=1L&&
      fpca$n_components<=ncol(source_scores),
      "fpca must provide finite scores and a compatible n_components")
  }
  if(is.null(n_components))n_components<-fpca$n_components
  .etr_assert(is.numeric(n_components) && length(n_components)==1L &&
    is.finite(n_components) && n_components==as.integer(n_components) &&
    n_components>=1L && n_components<=fpca$n_components,
    "n_components is outside the fitted range")
  # sklearn pairwise_distances accepts numeric-string and Boolean score arrays.
  # Do not coerce the caller's object, nor accept NaN, Inf or bad strings.
  scores<-if(is.character(source_scores)||is.logical(source_scores))
    matrix(suppressWarnings(as.numeric(source_scores)),
      nrow=nrow(source_scores),ncol=ncol(source_scores)) else source_scores
  x<-scores[,seq_len(n_components),drop=FALSE]
  out<-as.matrix(stats::dist(x,method="euclidean"))
  unname(out)
}

#' Python-style unlabelled complete-curve L2 distance matrix
#' @param trajectories Native common-grid trajectory set.
#' @param dimension_weights Nonnegative dimension weights, if supplied.
#' @export
etr_pairwise_functional_distances <- function(trajectories,
    dimension_weights=NULL) {
  etr_validate(trajectories,require_complete=TRUE)
  unname(etr_pairwise_l2(trajectories,dimension_weights))
}

#' Density summary for one dimension of native irregular trajectories
#' @param trajectories Native etr_irregular_trajectory_set.
#' @param dimension A measured dimension name.
#' @return One row per curve with observed and nonfinite support diagnostics.
#' @export
etr_sparse_dimension_summary <- function(trajectories,dimension) {
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(is.character(dimension) && length(dimension)==1L &&
    !is.na(dimension) && dimension %in% trajectories$dimension_names,
    "Unknown dimension")
  j<-match(dimension,trajectories$dimension_names)
  n<-length(trajectories$curve_ids)
  rows<-lapply(seq_len(n),function(i) {
    t<-trajectories$time[[i]]
    v<-trajectories$values[[i]][,j]
    observed<-is.finite(v)
    intervals<-if(sum(observed)>=2L)diff(t[observed]) else numeric()
    data.frame(curve_id=trajectories$curve_ids[i],
      n_sample_times=as.integer(length(t)),
      n_observed=as.integer(sum(observed)),
      n_nonfinite=as.integer(sum(!observed)),
      observed_fraction=mean(observed),
      time_start=t[1L],time_end=t[length(t)],
      time_span=t[length(t)]-t[1L],
      median_observed_interval=if(length(intervals))stats::median(intervals) else NaN,
      max_observed_interval=if(length(intervals))max(intervals) else NaN,
      stringsAsFactors=FALSE,check.names=FALSE)
  })
  do.call(rbind,rows)
}

# All phase helpers require source-orientation h_i(t), not inverse warps.
.etr_registration_diagnostic <- function(registration) {
  .etr_assert(is.list(registration) &&
    inherits(registration$original,"etr_trajectory_set"),
    "registration must have a native original trajectory set")
  etr_validate(registration$original)
  t<-registration$original$time
  w<-registration$warping_functions
  .etr_assert(is.matrix(w) && is.numeric(w) &&
    identical(dim(w),c(length(registration$original$curve_ids),length(t))) &&
    all(is.finite(w)) &&
    all(apply(w,1L,function(z)all(diff(z)>0))),
    "warping_functions must be complete, increasing curve-by-time source warps")
  .etr_assert(is.character(registration$method) &&
    length(registration$method)==1L && !is.na(registration$method) &&
    nzchar(registration$method),"registration method must be declared")
  if(is.null(registration$provenance))registration$provenance<-list()
  .etr_assert(.etr_provenance_valid(registration$provenance),
    "registration provenance must be a JSON-like mapping")
  invisible(registration)
}

#' Signed displacement h_i(t)-t for each registered functional curve
#' @param result Native registration list with original and warping_functions.
#' @export
etr_warping_displacement <- function(result) {
  .etr_registration_diagnostic(result)
  sweep(result$warping_functions,2L,result$original$time,"-")
}

#' Per-curve signed and absolute phase displacement statistics
#' @inheritParams etr_warping_displacement
#' @export
etr_phase_summary <- function(result) {
  delta<-etr_warping_displacement(result)
  list(mean_absolute_displacement=rowMeans(abs(delta)),
       max_absolute_displacement=apply(abs(delta),1L,max),
       signed_mean_displacement=rowMeans(delta))
}

#' Recast a declared registration as functional phase observations
#' @param registration Native registration with forward warping functions.
#' @param representation Either displacement h(t)-t or warping h(t).
#' @export
etr_phase_trajectory_set <- function(registration,
                                     representation="displacement") {
  .etr_registration_diagnostic(registration)
  .etr_assert(is.character(representation) && length(representation)==1L &&
    !is.na(representation) &&
    representation %in% c("displacement","warping"),
    "representation must be 'displacement' or 'warping'")
  original<-registration$original
  mat<-if(identical(representation,"displacement"))
    etr_warping_displacement(registration) else registration$warping_functions
  values<-array(mat,c(nrow(mat),ncol(mat),1L))
  provenance<-registration$provenance
  provenance$phase_representation<-representation
  provenance$registration_method<-registration$method
  etr_trajectory_set(original$time,values,original$curve_ids,
    if(identical(representation,"displacement"))
      "phase_displacement" else "warping_time",
    metadata=original$metadata,coordinate_system="phase_time",
    time_unit=original$time_unit,provenance=provenance)
}

#' Fit native univariate FPCA to declared registration phase functions
#' @inheritParams etr_phase_trajectory_set
#' @param n_components Integer fitted component count or variance fraction.
#' @export
etr_fit_phase_fpca <- function(registration,representation="displacement",
                                n_components=0.95) {
  x<-etr_phase_trajectory_set(registration,representation)
  etr_fit_fpca(x,n_components=n_components,scaling="none")
}
