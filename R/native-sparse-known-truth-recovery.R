# Frozen Python eyetrajectoriespy==1.2.0
# recovery.py::evaluate_sparse_fpca_recovery
# commit c1cd95ad718327550f7e55393ff38582872f7a94
# Exact one-mode score/mean/covariance audit with no sparse PACE refit.
# The general multi-component alignment and Python typed source domain
# remain explicitly open.

.etr_sparse_recovery_metric<-function(name){
  def<-switch(name,
    score_failure_rate=c("conditional score solve",
      "proportion","numerical",
      "Proportion of curves whose score system did not return status 'ok'."),
    score_condition_number_median=c("conditional score covariance system",
      "condition number","numerical",
      "Median finite score-system condition number across curves."),
    score_condition_number_q95=c("conditional score covariance system",
      "condition number","numerical",
      "95th percentile finite score-system condition number across curves."),
    score_condition_number_max=c("conditional score covariance system",
      "condition number","numerical",
      "Maximum finite score-system condition number across curves."),
    psd_repair_applied=c("fitted covariance PSD repair",
      "indicator","numerical",
      "Indicator that covariance projection was actually applied."),
    psd_relative_operator_correction=c("fitted covariance PSD repair",
      "relative Frobenius norm","numerical",
      "Relative weighted-operator correction introduced by PSD repair."),
    noise_variance_absolute_error=c("measurement-noise variance",
      "variance units","measurement_error",
      "Absolute fitted-versus-generating measurement-noise variance error."),
    noise_variance_relative_error=c("measurement-noise variance",
      "relative","measurement_error",
      "Absolute measurement-noise variance error divided by true variance."),
    stop("unsupported sparse recovery metric",call.=FALSE))
  list(name=name,quantity=def[[1L]],direction="lower_is_better",
    units=def[[2L]],scope=def[[3L]],description=def[[4L]])
}
.etr_sparse_recovery_value<-function(name,value){
  .etr_assert(is.numeric(value)&&length(value)==1L&&is.finite(value),
    paste(name,"must be a finite source metric"))
  list(metric=.etr_sparse_recovery_metric(name),value=as.numeric(value),
    component=NULL,source=NULL)
}

#' Evaluate known-truth univariate sparse PACE for one mode
#'
#' Ports frozen Python 1.2 source mean and directly estimated covariance
#' geometry, aligned scores, source diagnostic rates and finite conditions,
#' optional PSD-repair evidence and measurement-noise variance recovery.
#' Does not fit PACE, interpolate or certify general multi-mode assignments.
#' @param result Native source-shaped sparse FPCA result.
#' @param truth Full source-shaped functional simulator truth.
#' @return Native source-shaped recovery assessment with explicit provenance.
#' @export
etr_evaluate_sparse_fpca_recovery<-function(result,truth){
  .etr_recovery_source_fields(result,c("evaluation_grid","dimension",
    "mean","covariance","eigenfunctions","eigenvalues","scores"),
    "sparse FPCA fit")
  .etr_recovery_source_fields(truth,c("truth_grid",
    "dimension_names","mean","eigenfunctions","eigenvalues",
    "scores","latent_on_truth_grid","measurement_noise_covariance"),
    "generating sparse FPCA truth")
  .etr_assert(is.numeric(result$evaluation_grid)&&
    is.null(dim(result$evaluation_grid))&&
    identical(as.numeric(result$evaluation_grid),
      as.numeric(truth$truth_grid)),
    "sparse recovery requires an exact truth evaluation grid")
  .etr_assert(is.character(result$dimension)&&
    length(result$dimension)==1L&&!is.na(result$dimension),
    "sparse recovery dimension must be named")
  d<-match(result$dimension,truth$dimension_names)
  .etr_assert(length(d)==1L&&!is.na(d),
    "sparse result dimension is absent from generating truth")
  grid<-truth$truth_grid;nt<-length(grid)
  nd<-length(truth$dimension_names)
  .etr_assert(is.matrix(truth$mean)&&is.numeric(truth$mean)&&
    identical(dim(truth$mean),c(nt,nd)),
    "truth mean must be time by dimension")
  .etr_assert(is.array(truth$eigenfunctions)&&
    length(dim(truth$eigenfunctions))==3L&&
    identical(dim(truth$eigenfunctions)[2:3],c(nt,nd)),
    "truth functional eigenfunctions must have time/dimension geometry")
  .etr_assert(is.matrix(truth$scores)&&is.numeric(truth$scores)&&
    is.array(truth$latent_on_truth_grid)&&
    length(dim(truth$latent_on_truth_grid))==3L&&
    identical(dim(truth$latent_on_truth_grid),
      c(nrow(truth$scores),nt,nd)),
    "truth latent curves must align with simulator scores")
  .etr_assert(is.numeric(result$mean)&&is.null(dim(result$mean))&&
    length(result$mean)==nt&&all(is.finite(result$mean)),
    "sparse mean must be a finite time vector")
  .etr_assert(is.matrix(result$covariance)&&
    is.numeric(result$covariance)&&
    identical(dim(result$covariance),c(nt,nt))&&
    all(is.finite(result$covariance)),
    "sparse covariance must match the observed source grid")
  eigen<-result$eigenfunctions
  .etr_assert(is.matrix(eigen)&&is.numeric(eigen)&&
    identical(dim(eigen),c(1L,nt))&&all(is.finite(eigen)),
    "sparse recovery subset requires one mode by time")
  weights<-result[["quadrature_weights",exact=TRUE]]
  if(is.null(weights))weights<-etr_trapezoid_weights(grid)
  .etr_assert(is.numeric(weights)&&is.null(dim(weights))&&
    length(weights)==nt&&all(is.finite(weights))&&all(weights>0),
    "sparse recovery requires finite positive quadrature weights")
  one_truth<-list(truth_grid=grid,
    dimension_names=result$dimension,
    mean=matrix(truth$mean[,d],ncol=1L),
    eigenfunctions=truth$eigenfunctions[,,d,drop=FALSE],
    eigenvalues=truth$eigenvalues,
    scores=truth$scores,
    latent_on_truth_grid=truth$latent_on_truth_grid[,,d,drop=FALSE])
  parent_fit<-list(time=grid,dimension_names=result$dimension,
    provenance=list(fpca=list(scaling="none")),
    scale=1,mean=matrix(result$mean,ncol=1L),
    components=array(eigen,c(1L,nt,1L)),
    explained_variance=result$eigenvalues,
    scores=result$scores,weights=weights)
  parent<-etr_evaluate_fpca_recovery(parent_fit,one_truth)
  values<-parent$values
  truth_mode<-as.numeric(one_truth$eigenfunctions[1L,,1L])
  true_cov<-as.numeric(truth$eigenvalues)*tcrossprod(truth_mode)
  values[[2L]]$value<-sum(
    (result$covariance-true_cov)^2*outer(weights,weights))
  .etr_assert(is.finite(values[[2L]]$value),
    "sparse covariance ISE must be finite")
  diagnostics<-result[["score_diagnostics",exact=TRUE]]
  if(is.null(diagnostics))diagnostics<-data.frame()
  .etr_assert(is.data.frame(diagnostics),
    "sparse score_diagnostics must be a source-shaped data frame")
  add<-function(name,value){
    values[[length(values)+1L]]<<-
      .etr_sparse_recovery_value(name,value)
  }
  if(nrow(diagnostics)>0L){
    if("status_code"%in%names(diagnostics)){
      status<-as.character(diagnostics[["status_code"]])
      .etr_assert(!anyNA(status),
        "sparse status_code requires explicit nonmissing values")
      add("score_failure_rate",mean(status!="ok"))
    }
    if("condition_number"%in%names(diagnostics)){
      condition<-suppressWarnings(
        as.numeric(as.character(diagnostics[["condition_number"]])))
      condition<-condition[is.finite(condition)]
      if(length(condition)){
        add("score_condition_number_median",stats::median(condition))
        add("score_condition_number_q95",as.numeric(
          stats::quantile(condition,probs=.95,type=7,names=FALSE)))
        add("score_condition_number_max",max(condition))
      }
    }
  }else{
    # The supported bounded source domain validates complete finite scores.
    add("score_failure_rate",mean(
      !apply(is.finite(result$scores),1L,all)))
  }
  cov_diag<-result[["covariance_diagnostics",exact=TRUE]]
  if(is.null(cov_diag))cov_diag<-list()
  .etr_assert(is.list(cov_diag),
    "covariance_diagnostics must be a named source record")
  correction<-cov_diag[["relative_operator_correction_frobenius_norm",
    exact=TRUE]]
  if(!is.null(correction)&&is.numeric(correction)&&
      length(correction)==1L&&is.finite(correction)){
    action<-cov_diag[["applied_action",exact=TRUE]]
    add("psd_repair_applied",if(identical(action,"project"))1 else 0)
    add("psd_relative_operator_correction",correction)
  }
  noise_cov<-truth$measurement_noise_covariance
  .etr_assert(is.matrix(noise_cov)&&is.numeric(noise_cov)&&
    identical(dim(noise_cov),c(nd,nd))&&
    all(is.finite(noise_cov)),
    "truth measurement_noise_covariance must match dimension order")
  true_noise<-noise_cov[d,d]
  noise<-result[["noise_variance",exact=TRUE]]
  if(!is.null(noise)){
    .etr_assert(is.numeric(noise)&&length(noise)==1L&&
      is.finite(noise),"noise_variance must be finite scalar")
    abs_error<-abs(noise-true_noise)
    add("noise_variance_absolute_error",abs_error)
    if(true_noise>0)add("noise_variance_relative_error",
      abs_error/true_noise)
  }
  src_prov<-result[["provenance",exact=TRUE]]
  if(is.null(src_prov))src_prov<-list()
  .etr_assert(is.list(src_prov),
    "sparse provenance must be a source-shaped record")
  sparse_prov<-src_prov[["sparse_fpca",exact=TRUE]]
  if(is.null(sparse_prov))sparse_prov<-list()
  .etr_assert(is.list(sparse_prov),
    "sparse_fpca provenance must be a named record")
  structure(list(values=values,provenance=list(
    estimator="native_sparse_fpca_pace",
    truth_grid_match="exact",dimension=result$dimension,
    noise_variance_method=sparse_prov[["noise_variance_method",exact=TRUE]],
    measurement_error_variance_supplied=sparse_prov[["measurement_error_variance_supplied",exact=TRUE]],
    matched_truth_components=0L,
    alignment_signs=parent$provenance$alignment_signs)),
    class="etr_functional_recovery_assessment")
}
