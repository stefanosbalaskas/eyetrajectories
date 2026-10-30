# Stage 10: Python-free compositional FPCA, component matching,
# reconstruction diagnostics, phase sensitivity, eigengaps and reporting.
# Source contracts: published eyetrajectoriespy 1.2.0:
# compositional.py, stability.py, phase.py, subspace.py,
# reporting.py and inference.py. All research qualification pending.

.etr_fpca_component_count <- function(n,k) {
  if(is.null(k))return(as.integer(n))
  .etr_assert(is.numeric(k) && length(k)==1L && is.finite(k) &&
    k==as.integer(k) && k>=1L && k<=n,
    "n_components is outside the fitted range")
  as.integer(k)
}

.etr_fpca_fitted_check <- function(fit) {
  .etr_assert(inherits(fit,"etr_fpca") &&
    is.matrix(fit$mean) && is.array(fit$components) &&
    length(dim(fit$components))==3L &&
    is.matrix(fit$scores) && is.numeric(fit$scores) &&
    length(fit$weights)==length(fit$time) &&
    length(fit$scale)==length(fit$dimension_names) &&
    identical(dim(fit$components)[2:3],dim(fit$mean)) &&
    dim(fit$components)[1L]==fit$n_components &&
    ncol(fit$scores)==fit$n_components,
    "result must be a compatible native FPCA fit")
  invisible(TRUE)
}

.etr_fpca_compatible_sample <- function(fit,x) {
  .etr_fpca_fitted_check(fit)
  etr_validate(x,require_complete=TRUE)
  .etr_assert(identical(x$time,fit$time),
    "Trajectory grid must match the fitted FPCA grid")
  .etr_assert(identical(x$dimension_names,fit$dimension_names),
    "Functional dimensions must match the fitted FPCA model")
  .etr_assert(identical(x$curve_ids,fit$curve_ids),
    "Trajectory IDs/order must match the fitted FPCA result")
  invisible(TRUE)
}

.etr_fpca_reconstruct_scores <- function(fit,scores=NULL,n_components=NULL) {
  .etr_fpca_fitted_check(fit)
  if(is.null(scores))scores<-fit$scores
  if(is.numeric(scores) && is.null(dim(scores)))
    scores<-matrix(scores,nrow=1L)
  .etr_assert(is.matrix(scores) && is.numeric(scores) &&
    nrow(scores)>=1L && all(is.finite(scores)),
    "scores must be a finite numeric one- or two-dimensional array")
  if(is.null(n_components))n_components<-min(ncol(scores),fit$n_components)
  k<-.etr_fpca_component_count(fit$n_components,n_components)
  .etr_assert(ncol(scores)>=k,
    "scores contain fewer columns than requested components")
  n<-nrow(scores);nt<-length(fit$time);nd<-length(fit$dimension_names)
  out<-array(NA_real_,c(n,nt,nd))
  for(d in seq_len(nd))for(t in seq_len(nt))
    out[,t,d]<-fit$mean[t,d]+
      as.vector(scores[,seq_len(k),drop=FALSE]%*%
        fit$components[seq_len(k),t,d])
  out
}

#' Compositional functional PCA under a declared ALR transform
#' @param trajectories Complete native simplex-valued trajectories.
#' @param reference_dimension Zero-based Python ALR reference (-1 last).
#' @param epsilon Explicit positive clipping floor.
#' @param n_components Integer count or variance fraction.
#' @param scaling Native dimension scaling ("none" or "dimension_sd").
#' @export
etr_fit_compositional_fpca <- function(trajectories,
    reference_dimension=-1L,epsilon=1e-8,n_components=0.95,
    scaling="none") {
  etr_validate(trajectories,require_complete=TRUE)
  etr_validate_simplex(trajectories$values)
  k<-length(trajectories$dimension_names)
  .etr_assert(k>=3L,
    "compositional FPCA requires at least three simplex dimensions (ALR MFPCA)")
  ref<-.etr_fpca_index(reference_dimension,k,"reference_dimension")
  z<-etr_alr_transform(trajectories$values,ref-1L,epsilon)
  dimnames<-paste0("log(",
    trajectories$dimension_names[-ref],"/",
    trajectories$dimension_names[ref],")")
  provenance<-trajectories$provenance
  if(is.null(provenance))provenance<-list()
  provenance$compositional_transform<-list(method="additive_log_ratio",
    reference_dimension=ref-1L,epsilon=epsilon)
  transformed<-etr_trajectory_set(trajectories$time,z,
    curve_ids=trajectories$curve_ids,dimension_names=dimnames,
    metadata=trajectories$metadata,
    coordinate_system="simplex_logratio",
    time_unit=trajectories$time_unit,provenance=provenance)
  fit<-etr_fit_mfpca(transformed,n_components=n_components,scaling=scaling)
  structure(list(fpca=fit,reference_dimension=ref-1L,
    original_dimension_names=trajectories$dimension_names,
    epsilon=epsilon,provenance=list(
      method="ALR + quadrature-weighted MFPCA",
      simplex_preserved_on_inverse=TRUE)),
    class="etr_compositional_fpca")
}

#' Reconstruct compositional FPCA scores onto the probability simplex
#' @param result Native compositional FPCA result.
#' @param scores Optional replacement score vector/matrix.
#' @param n_components Optional fitted component count.
#' @export
etr_reconstruct_compositional_fpca <- function(result,scores=NULL,
                                               n_components=NULL) {
  .etr_assert(inherits(result,"etr_compositional_fpca") &&
    inherits(result$fpca,"etr_fpca") &&
    length(result$original_dimension_names)>=3L,
    "result must be a native compositional FPCA fit")
  z<-.etr_fpca_reconstruct_scores(result$fpca,scores,n_components)
  etr_inverse_alr(z,result$reference_dimension,
    length(result$original_dimension_names))
}

#' Quadrature-weighted signed component cosine similarity
#' @param reference,candidate Compatible native FPCA fits.
#' @param n_components Number of fitted components to compare.
#' @export
etr_component_similarity_matrix <- function(reference,candidate,
                                              n_components=NULL) {
  .etr_fpca_fitted_check(reference);.etr_fpca_fitted_check(candidate)
  .etr_assert(identical(reference$time,candidate$time),
    "FPCA results must use the same time grid")
  .etr_assert(identical(reference$dimension_names,candidate$dimension_names),
    "FPCA results must use the same functional dimensions")
  .etr_assert(isTRUE(all.equal(reference$weights,candidate$weights,
    tolerance=1e-8,check.attributes=FALSE)),
    "FPCA quadrature weights differ between results")
  common<-min(reference$n_components,candidate$n_components)
  k<-.etr_fpca_component_count(common,n_components)
  w<-reference$weights
  .etr_assert(all(is.finite(w)) && all(w>0) &&
    all(is.finite(reference$scale)) && all(reference$scale>0) &&
    all(is.finite(candidate$scale)) && all(candidate$scale>0),
    "FPCA quadrature weights and channel scales must be positive finite")
  standardized<-function(fit,i) {
    a<-fit$components[i,,,drop=FALSE]
    matrix(as.numeric(a),nrow=length(w),
           ncol=length(fit$dimension_names)) /
      matrix(rep(fit$scale,each=length(w)),nrow=length(w))
  }
  out<-matrix(NA_real_,k,k)
  for(i in seq_len(k)) {
    a<-standardized(reference,i)
    na<-sqrt(sum(rowSums(a^2)*w))
    for(j in seq_len(k)) {
      b<-standardized(candidate,j)
      nb<-sqrt(sum(rowSums(b^2)*w))
      out[i,j]<-if(na<=.Machine$double.eps || nb<=.Machine$double.eps)
        NaN else sum(rowSums(a*b)*w)/(na*nb)
    }
  }
  out
}

#' One-to-one matching by maximum total absolute component cosine similarity
#' @inheritParams etr_component_similarity_matrix
#' @return List with zero-based candidate assignments and signed similarities.
#' @export
etr_match_fpca_components <- function(reference,candidate,
                                       n_components=NULL) {
  sim<-etr_component_similarity_matrix(reference,candidate,n_components)
  .etr_assert(all(is.finite(sim)),
    "Component similarity is undefined for a zero-norm component")
  k<-nrow(sim)
  .etr_assert(k<=12L,
    "native exact assignment limited to 12 components; do not approximate")
  # Exact dynamic programming over subsets. The SciPy source also solves a
  # maximum-weight one-to-one assignment; ties need not match SciPy.
  count<-as.integer(2^k)
  best<-rep(-Inf,count);best[1L]<-0
  paths<-vector("list",count);paths[[1L]]<-integer()
  for(mask in 0:(count-1L)) {
    idx<-mask+1L
    if(!is.finite(best[idx]))next
    row<-sum(as.integer(intToBits(mask)[seq_len(k)]))+1L
    if(row>k)next
    for(j in seq_len(k))if(bitwAnd(mask,bitwShiftL(1L,j-1L))==0L) {
      nextmask<-bitwOr(mask,bitwShiftL(1L,j-1L))
      score<-best[idx]+abs(sim[row,j])
      dest<-nextmask+1L
      if(score>best[dest]) {
        best[dest]<-score
        paths[[dest]]<-c(paths[[idx]],j-1L)
      }
    }
  }
  assignment<-as.integer(paths[[count]])
  .etr_assert(length(assignment)==k && !anyDuplicated(assignment),
    "Failed to solve component assignment")
  signed<-sim[cbind(seq_len(k),assignment+1L)]
  list(assignments=assignment,signed_similarity=as.numeric(signed))
}

#' Per-curve integrated reconstruction error of the original FPCA sample
#' @param result Native FPCA fit.
#' @param trajectories Complete original curves with identical ID/order/grid.
#' @param n_components Retained components (NULL all fitted).
#' @export
etr_reconstruction_error_by_curve <- function(result,trajectories,
                                               n_components=NULL) {
  .etr_fpca_compatible_sample(result,trajectories)
  k<-.etr_fpca_component_count(result$n_components,n_components)
  reconstructed<-.etr_fpca_reconstruct_scores(result,n_components=k)
  diff<-reconstructed-trajectories$values
  n<-length(trajectories$curve_ids);nd<-length(trajectories$dimension_names)
  denom<-sum(result$weights)*nd
  .etr_assert(denom>0,"quadrature weights must have positive total")
  rmse<-vapply(seq_len(n),function(i) {
    value<-0
    for(d in seq_len(nd))
      value<-value+sum(diff[i,,d]^2*result$weights)
    sqrt(value/denom)
  },numeric(1L))
  data.frame(curve_id=trajectories$curve_ids,
    n_components=rep(as.integer(k),n),integrated_rmse=rmse,
    row.names=NULL,check.names=FALSE)
}

#' FPCA reconstruction-error curve across the retained component count
#' @inheritParams etr_reconstruction_error_by_curve
#' @export
etr_fpca_reconstruction_curve <- function(result,trajectories) {
  .etr_fpca_compatible_sample(result,trajectories)
  do.call(rbind,lapply(seq_len(result$n_components),function(k) {
    err<-etr_reconstruction_error_by_curve(result,trajectories,k)
    data.frame(n_components=as.integer(k),
      mean_integrated_rmse=mean(err$integrated_rmse),
      median_integrated_rmse=stats::median(err$integrated_rmse),
      cumulative_variance_ratio=sum(result$explained_variance_ratio[seq_len(k)]))
  }))
}

#' Native registered-versus-unregistered FPCA sensitivity comparison
#' @param registration Native landmark registration with original and registered.
#' @param n_components Integer common fitted components.
#' @param scaling FPCA scaling ("none" or "dimension_sd").
#' @export
etr_compare_registered_unregistered_fpca <- function(registration,
    n_components=3L,scaling="none") {
  .etr_assert(is.list(registration) &&
    inherits(registration$original,"etr_trajectory_set") &&
    inherits(registration$registered,"etr_trajectory_set"),
    "registration must retain native original and registered curves")
  .etr_assert(identical(registration$original$curve_ids,
    registration$registered$curve_ids),
    "Original and registered curve ordering must match")
  .etr_assert(is.numeric(n_components) && length(n_components)==1L &&
    is.finite(n_components) && n_components==as.integer(n_components) &&
    n_components>=1L,"n_components must be positive integer")
  .etr_assert(scaling %in% c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  a<-etr_fit_fpca(registration$original,
    n_components=as.integer(n_components),scaling=scaling)
  b<-etr_fit_fpca(registration$registered,
    n_components=as.integer(n_components),scaling=scaling)
  match<-etr_match_fpca_components(a,b,n_components=as.integer(n_components))
  correlations<-vapply(seq_len(n_components),function(i) {
    raw_a<-a$scores[,i]
    sign<-if(match$signed_similarity[i]>=0)1 else -1
    raw_b<-sign*b$scores[,match$assignments[i]+1L]
    if(stats::sd(raw_a)<=.Machine$double.eps ||
       stats::sd(raw_b)<=.Machine$double.eps)NaN
    else stats::cor(raw_a,raw_b)
  },numeric(1L))
  structure(list(unregistered_fpca=a,registered_fpca=b,
    component_assignments=match$assignments,
    signed_component_similarity=match$signed_similarity,
    score_correlations=correlations,
    provenance=list(method="registered_vs_unregistered_fpca",
      registration_method=registration$method,
      n_components=as.integer(n_components),scaling=scaling)),
    class="etr_registration_sensitivity")
}

#' Registration sensitivity comparison as a tidy component-level table
#' @param result Native etr_registration_sensitivity.
#' @export
etr_registration_sensitivity_frame <- function(result) {
  .etr_assert(inherits(result,"etr_registration_sensitivity"),
    "result must be native registration sensitivity")
  k<-result$unregistered_fpca$n_components
  data.frame(unregistered_component=seq_len(k),
    registered_component=result$component_assignments+1L,
    signed_component_similarity=result$signed_component_similarity,
    absolute_component_similarity=abs(result$signed_component_similarity),
    score_correlation=result$score_correlations)
}

#' Describe native trajectory representation without excluding samples
#' @param trajectories Native common-grid trajectory set.
#' @export
etr_summarise_trajectory_set <- function(trajectories) {
  etr_validate(trajectories)
  d<-dim(trajectories$values)
  data.frame(n_curves=as.integer(d[1L]),
    n_time=as.integer(d[2L]),n_dimensions=as.integer(d[3L]),
    time_start=trajectories$time[1L],
    time_end=trajectories$time[length(trajectories$time)],
    time_unit=trajectories$time_unit,
    coordinate_system=trajectories$coordinate_system,
    missing_fraction=mean(is.na(trajectories$values)),
    dimensions=paste(trajectories$dimension_names,collapse=", "),
    check.names=FALSE)
}

#' Component-level explained-variance table for native functional PCA
#' @param result Native FPCA fit.
#' @export
etr_summarise_fpca <- function(result) {
  .etr_fpca_fitted_check(result)
  data.frame(component=seq_len(result$n_components),
    explained_variance=result$explained_variance,
    explained_variance_ratio=result$explained_variance_ratio,
    cumulative_variance_ratio=cumsum(result$explained_variance_ratio))
}

#' Descriptive native functional PCA reporting text
#' @param result Native FPCA fit.
#' @param digits Nonnegative integer decimal places.
#' @export
etr_fpca_reporting_text <- function(result,digits=1L) {
  .etr_fpca_fitted_check(result)
  .etr_assert(is.numeric(digits) && length(digits)==1L &&
    is.finite(digits) && digits==as.integer(digits) &&
    digits>=0L && digits<=15L,
    "digits must be a nonnegative integer <= 15")
  pct<-100*sum(result$explained_variance_ratio)
  individual<-100*result$explained_variance_ratio
  head<-paste(vapply(seq_len(min(length(individual),4L)),function(i)
    sprintf(paste0("FPC%d=%.",digits,"f%%"),i,individual[i]),
    character(1L)),collapse=", ")
  scaling<-if(!is.null(result$provenance$fpca$scaling))
    result$provenance$fpca$scaling else
      if(!is.null(result$scaling))result$scaling else "unknown"
  paste0("Functional PCA retained ",result$n_components,
    " component(s), explaining ",sprintf(paste0("%.",digits,"f"),pct),
    "% of the weighted functional variance (",head,
    "). The analysis used ",result$coordinate_system,
    " coordinates, time unit '",result$time_unit,
    "', and channel scaling='",scaling,"'.")
}

#' Descriptive gaps between adjacent retained functional eigenvalues
#' @param result Native FPCA fit with at least two retained components.
#' @param relative_gap_threshold Optional threshold in [0,1) for near ties.
#' @export
etr_fpca_eigenvalue_gap_table <- function(result,
                                          relative_gap_threshold=NULL) {
  .etr_fpca_fitted_check(result)
  v<-result$explained_variance
  .etr_assert(length(v)>=2L && all(is.finite(v)) && all(v>=0),
    "At least two finite nonnegative fitted components are required")
  .etr_assert(all(diff(v)<=.Machine$double.eps*max(1,v[1L])),
    "explained_variance must be non-increasing")
  if(!is.null(relative_gap_threshold))
    .etr_assert(is.numeric(relative_gap_threshold) &&
      length(relative_gap_threshold)==1L &&
      is.finite(relative_gap_threshold) &&
      relative_gap_threshold>=0 && relative_gap_threshold<1,
      "relative_gap_threshold must be in [0,1)")
  current<-v[-length(v)]
  following<-v[-1L]
  denom<-pmax(current,.Machine$double.eps)
  tab<-data.frame(component=seq_len(length(v)-1L),
    next_component=seq.int(2L,length(v)),
    eigenvalue=current,next_eigenvalue=following,
    absolute_gap=current-following,
    relative_gap=(current-following)/denom,
    next_to_current_ratio=following/denom)
  if(!is.null(relative_gap_threshold)) {
    tab$near_tie_flag<-tab$relative_gap<=relative_gap_threshold
    tab$relative_gap_threshold<-rep(relative_gap_threshold,nrow(tab))
  }
  tab
}

#' Manuscript-ready description of the smallest retained eigengap
#' @inheritParams etr_fpca_eigenvalue_gap_table
#' @param digits Nonnegative decimal places.
#' @export
etr_fpca_eigengap_reporting_text <- function(result,
    relative_gap_threshold=NULL,digits=3L) {
  tab<-etr_fpca_eigenvalue_gap_table(result,relative_gap_threshold)
  .etr_assert(is.numeric(digits) && length(digits)==1L &&
    is.finite(digits) && digits==as.integer(digits) &&
    digits>=0L && digits<=15L,
    "digits must be nonnegative integer <=15")
  row<-tab[which.min(tab$relative_gap),,drop=FALSE]
  f<-function(x)sprintf(paste0("%.",digits,"f"),x)
  out<-paste0("The smallest adjacent retained FPCA eigengap was between FPC",
    row$component," and FPC",row$next_component,
    " (relative gap=",f(row$relative_gap),
    "; next/current eigenvalue ratio=",f(row$next_to_current_ratio),").")
  if(!is.null(relative_gap_threshold))
    out<-paste0(out," Using the pre-specified relative-gap threshold ",
      f(relative_gap_threshold),", ",sum(tab$near_tie_flag),
      " adjacent retained pair(s) met the descriptive near-tie criterion.")
  out
}

#' Descriptive registered-vs-unregistered principal component report
#' @param result Native registration-sensitivity result.
#' @param digits Number of decimals.
#' @export
etr_registration_sensitivity_reporting_text <- function(result,digits=2L) {
  .etr_assert(inherits(result,"etr_registration_sensitivity"),
    "result must be a native registration sensitivity")
  .etr_assert(is.numeric(digits) && length(digits)==1L &&
    is.finite(digits) && digits==as.integer(digits) &&
    digits>=0L && digits<=15L,"digits must be nonnegative integer <=15")
  f<-function(x)sprintf(paste0("%.",digits,"f"),x)
  parts<-vapply(seq_along(result$signed_component_similarity),function(i)
    paste0("FPC",i,": matched shape similarity=",
      f(abs(result$signed_component_similarity[i])),
      ", score correlation=",f(result$score_correlations[i])),
    character(1L))
  paste0("Registration sensitivity compared matched functional principal components before ",
    "and after the explicit registration step. ",
    paste(parts,collapse="; "),".")
}

#' Long-format simultaneous functional-mean band values
#' @param result Valid native functional mean band object with required fields.
#' @export
etr_functional_mean_band_frame <- function(result) {
  needed<-c("time","dimension_names","mean","pointwise_se","lower","upper")
  .etr_assert(is.list(result) && all(needed %in% names(result)),
    "mean-band result must contain time, dimension_names and band matrices")
  t<-result$time;dims<-result$dimension_names
  .etr_assert(is.numeric(t) && length(t)>=2L &&
    all(is.finite(t)) && all(diff(t)>0) &&
    is.character(dims) && length(dims)>=1L &&
    !anyNA(dims) && !anyDuplicated(dims),
    "band time and dimension names must be valid")
  for(n in needed[3:6])
    .etr_assert(is.matrix(result[[n]]) && is.numeric(result[[n]]) &&
      identical(dim(result[[n]]),c(length(t),length(dims))) &&
      all(is.finite(result[[n]])),
      paste("mean-band matrix",n,"has invalid dimensions or values"))
  data.frame(time=rep(t,times=length(dims)),
    dimension=rep(dims,each=length(t)),
    mean=as.vector(result$mean),
    pointwise_se=as.vector(result$pointwise_se),
    lower=as.vector(result$lower),
    upper=as.vector(result$upper),row.names=NULL)
}
