# Frozen eyetrajectoriespy==1.2.0 at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# recovery.py::evaluate_sparse_mfpca_recovery
# Source-faithful bounded one-mode bivariate population/diagnostic audit.
# Multi-component Hungarian alignment, tied subspaces and full dataclass
# input/error domains remain unsupported, with no MFPCA refit.

.etr_sparse_mfpca_block_value<-function(source,value){
  .etr_assert(is.numeric(value)&&length(value)==1L&&is.finite(value),
    "named planar covariance block ISE must be finite")
  list(metric=list(name="covariance_block_ise",
    quantity="planar covariance block",
    direction="lower_is_better",units="squared covariance \u00d7 time\u00b2",
    scope="covariance_block",
    description="Quadrature-weighted integrated squared error of one named planar covariance block."),
    value=as.numeric(value),component=NULL,source=source)
}

#' Known-truth sparse bivariate MFPCA with one retained component
#'
#' Scores one declared source component on the exact generating grid.
#' Reports four separate fitted planar covariance block ISEs and their
#' sum, signed component/score alignment, retained diagnostic metrics
#' and the actual supplied measurement-error-covariance agreement.
#' No estimator/refit, implicit interpolation, or tied-eigenspace claims.
#' @param result Source-shaped bivariate sparse joint-PACE result.
#' @param truth Source-shaped generating truth with one component.
#' @return Source-shaped recovery assessment with explicit provenance.
#' @export
etr_evaluate_sparse_mfpca_recovery<-function(result,truth){
  .etr_recovery_source_fields(result,c("evaluation_grid","dimensions",
    "mean","eigenfunctions","eigenvalues","scores",
    "quadrature_weights","covariance_cxx","covariance_cxy",
    "covariance_cyx","covariance_cyy",
    "measurement_error_covariance"),"sparse MFPCA fit")
  .etr_recovery_source_fields(truth,c("truth_grid","dimension_names",
    "mean","eigenfunctions","eigenvalues","scores",
    "latent_on_truth_grid","measurement_noise_covariance"),
    "sparse MFPCA generating truth")
  grid<-truth$truth_grid
  .etr_assert(is.numeric(grid)&&is.null(dim(grid))&&
    length(grid)>=3L&&all(is.finite(grid))&&all(diff(grid)>0),
    "truth grid must be finite strictly increasing time")
  .etr_assert(is.numeric(result$evaluation_grid)&&
    identical(as.numeric(result$evaluation_grid),as.numeric(grid)),
    "sparse MFPCA recovery requires exact truth evaluation grid")
  dims<-truth$dimension_names
  .etr_assert(is.character(dims)&&length(dims)==2L&&
    identical(result$dimensions,dims),
    "sparse MFPCA recovery requires exactly two dimensions in source order")
  nt<-length(grid)
  weights<-result$quadrature_weights
  target_weights<-etr_trapezoid_weights(grid)
  .etr_assert(is.numeric(weights)&&is.null(dim(weights))&&
    identical(length(weights),nt)&&all(is.finite(weights))&&
    all(abs(weights-target_weights)<=1e-14),
    "sparse MFPCA recovery requires declared functional quadrature weights")
  .etr_assert(is.matrix(result$mean)&&is.numeric(result$mean)&&
    identical(dim(result$mean),c(nt,2L))&&
    all(is.finite(result$mean)),
    "sparse MFPCA fitted mean must be finite time by two dimensions")
  .etr_assert(is.matrix(truth$mean)&&is.numeric(truth$mean)&&
    identical(dim(truth$mean),c(nt,2L))&&
    all(is.finite(truth$mean)),
    "generating sparse MFPCA mean geometry mismatch")
  comps<-result$eigenfunctions
  generating<-truth$eigenfunctions
  .etr_assert(is.array(comps)&&is.numeric(comps)&&
    identical(dim(comps),c(1L,nt,2L))&&all(is.finite(comps)),
    "source subset requires one fitted bivariate eigenfunction")
  .etr_assert(is.array(generating)&&is.numeric(generating)&&
    identical(dim(generating),c(1L,nt,2L))&&all(is.finite(generating)),
    "source subset requires one generating bivariate eigenfunction")
  .etr_assert(is.numeric(result$eigenvalues)&&
    length(result$eigenvalues)==1L&&
    is.finite(result$eigenvalues),
    "source subset requires one finite fitted eigenvalue")
  .etr_assert(is.numeric(truth$eigenvalues)&&
    length(truth$eigenvalues)==1L&&
    is.finite(truth$eigenvalues)&&truth$eigenvalues>0,
    "source subset requires one strictly positive truth eigenvalue")
  .etr_assert(is.matrix(result$scores)&&is.numeric(result$scores)&&
    ncol(result$scores)==1L&&all(is.finite(result$scores)),
    "source subset requires finite one-component scores")
  n<-nrow(result$scores)
  .etr_assert(n>=2L&&is.matrix(truth$scores)&&
    identical(dim(truth$scores),c(n,1L))&&
    all(is.finite(truth$scores)),
    "source fitted and generating score geometry mismatch")
  .etr_assert(is.array(truth$latent_on_truth_grid)&&
    identical(dim(truth$latent_on_truth_grid),c(n,nt,2L))&&
    all(is.finite(truth$latent_on_truth_grid)),
    "source latent curve geometry mismatch")
  parent_fit<-list(time=grid,dimension_names=dims,
    provenance=list(fpca=list(scaling="none")),scale=c(1,1),
    mean=result$mean,components=comps,
    explained_variance=result$eigenvalues,
    scores=result$scores,weights=weights)
  parent_truth<-list(truth_grid=grid,dimension_names=dims,
    mean=truth$mean,eigenfunctions=generating,
    eigenvalues=truth$eigenvalues,scores=truth$scores,
    latent_on_truth_grid=truth$latent_on_truth_grid)
  population<-etr_evaluate_fpca_recovery(parent_fit,parent_truth)
  block_names<-c("cxx","cxy","cyx","cyy")
  truth_modes<-list(x=as.numeric(generating[1L,,1L]),
    y=as.numeric(generating[1L,,2L]))
  expected<-list(cxx=truth$eigenvalues*tcrossprod(truth_modes$x),
    cxy=truth$eigenvalues*outer(truth_modes$x,truth_modes$y),
    cyx=truth$eigenvalues*outer(truth_modes$y,truth_modes$x),
    cyy=truth$eigenvalues*tcrossprod(truth_modes$y))
  block_values<-vector("list",length(block_names))
  for(j in seq_along(block_names)){
    key<-block_names[[j]]
    fitted<-result[[paste0("covariance_",key),exact=TRUE]]
    .etr_assert(is.matrix(fitted)&&is.numeric(fitted)&&
      identical(dim(fitted),c(nt,nt))&&all(is.finite(fitted)),
      paste("planar covariance block",key,
        "must be finite and match truth-grid geometry"))
    ise<-sum((fitted-expected[[key]])^2*outer(weights,weights))
    block_values[[j]]<-.etr_sparse_mfpca_block_value(key,ise)
  }
  joint<-sum(vapply(block_values,function(v)v$value,numeric(1L)))
  joint_value<-.etr_fpca_recovery_value("covariance_ise",joint)
  # Python source order: mean, four named blocks, sum, component and score
  # metrics, principal geometry, reconstruction, numerical diagnostics.
  values<-c(list(population$values[[1L]]),
    block_values,list(joint_value),population$values[-(1:2)])
  add<-function(name,value){
    values[[length(values)+1L]]<<-.etr_sparse_recovery_value(name,value)
  }
  diagnostics<-result[["score_diagnostics",exact=TRUE]]
  if(is.null(diagnostics))diagnostics<-data.frame()
  .etr_assert(is.data.frame(diagnostics),
    "score_diagnostics must be a source-shaped data frame")
  if(nrow(diagnostics)>0L){
    if("status_code"%in%names(diagnostics)){
      status<-as.character(diagnostics[["status_code"]])
      .etr_assert(!anyNA(status),"score status must be explicitly reported")
      add("score_failure_rate",mean(status!="ok"))
    }
    if("condition_number"%in%names(diagnostics)){
      cond<-suppressWarnings(as.numeric(as.character(
        diagnostics[["condition_number"]])))
      cond<-cond[is.finite(cond)]
      if(length(cond)){
        add("score_condition_number_median",stats::median(cond))
        add("score_condition_number_q95",as.numeric(
          stats::quantile(cond,.95,type=7,names=FALSE)))
        add("score_condition_number_max",max(cond))
      }
    }
  }else{
    add("score_failure_rate",mean(!apply(is.finite(result$scores),1L,all)))
  }
  diag<-result[["covariance_diagnostics",exact=TRUE]]
  if(is.null(diag))diag<-list()
  .etr_assert(is.list(diag),
    "covariance_diagnostics must be a source-shaped record")
  repair<-diag[["relative_operator_correction_frobenius_norm",
    exact=TRUE]]
  if(!is.null(repair)&&is.numeric(repair)&&
     length(repair)==1L&&is.finite(repair)){
    action<-diag[["applied_action",exact=TRUE]]
    add("psd_repair_applied",if(identical(action,"project"))1 else 0)
    add("psd_relative_operator_correction",repair)
  }
  supplied<-result$measurement_error_covariance
  actual<-truth$measurement_noise_covariance
  .etr_assert(is.matrix(supplied)&&is.numeric(supplied)&&
    identical(dim(supplied),c(2L,2L))&&
    all(is.finite(supplied))&&
    is.matrix(actual)&&is.numeric(actual)&&
    identical(dim(actual),c(2L,2L))&&
    all(is.finite(actual)),
    "source measurement error covariance must match both dimensions")
  agreement<-all(abs(supplied-actual)<=1e-12)
  prov<-result[["provenance",exact=TRUE]]
  if(is.null(prov))prov<-list()
  .etr_assert(is.list(prov),"sparse MFPCA provenance must be a record")
  sparse<-prov[["sparse_mfpca",exact=TRUE]]
  if(is.null(sparse))sparse<-list()
  .etr_assert(is.list(sparse),"sparse_mfpca provenance must be a record")
  structure(list(values=values,provenance=list(
    estimator="native_sparse_mfpca_joint_pace",
    truth_grid_match="exact",dimensions=as.list(dims),
    covariance_recovery="named_block_quadrature_ise",
    joint_covariance_ise_definition="cxx + cxy + cyx + cyy",
    matched_truth_components=0L,
    alignment_signs=population$provenance$alignment_signs,
    truth_eigenvalue_tie_relative_tolerance=1e-8,
    tied_truth_component_groups=list(),
    tied_score_subspace_sources=list(),
    component_metrics_omitted_for_tied_eigenspaces=FALSE,
    measurement_error_mode=sparse[["measurement_error_mode",exact=TRUE]],
    measurement_error_truth_supplied=agreement,
    measurement_error_recovery_metric_reported=FALSE)),
    class="etr_functional_recovery_assessment")
}
