# Source: eyetrajectoriespy 1.2.0
# functional_mixed_effects_covariance_sensitivity.py.
# This native function compares existing two-level moments fits only.
# No fitted likelihood, AIC/BIC, covariance family selection, or Python
# spline MixedLM covariance sensitivity is claimed.

#' Compare predeclared native functional mixed-moments fits descriptively
#' @param fits Named nonempty list of already converged native moments fits.
#' @param reference Label of the explicitly declared reference fit.
#' @param max_lag Positive integer smaller than time-grid length.
#' @param specifications Optional named list of declared ridge specifications.
#' @param failures Optional named list of failed intended specifications.
#' @param bands Must be NULL; Python MixedLM band provenance is unsupported.
#' @return Descriptive coefficient differences, covariance traces, residual
#'   lag summaries and complete retained failure audit; no model selection.
#' @export
etr_functional_mixed_effects_covariance_sensitivity<-function(
    fits,reference,max_lag,specifications=NULL,failures=list(),bands=NULL,
    strict_source_record=FALSE){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict_source_record)){
    .etr_assert(is.list(fits)&&length(fits)>0L&&
      all(vapply(fits,function(x)
        inherits(x,"etr_joint_bspline_mixed"),logical(1L))),
      "strict mixed sensitivity requires native joint spline likelihood fits")
  }
  # The older moments path and the full joint-likelihood path use different
  # estimators. Never silently compare their incompatible likelihoods.
  if(is.list(fits)&&length(fits)>0L&&
     any(vapply(fits,function(x)
       inherits(x,"etr_joint_bspline_mixed"),logical(1L)))){
    .etr_assert(all(vapply(fits,function(x)
      inherits(x,"etr_joint_bspline_mixed"),logical(1L))),
      "mixed covariance sensitivity cannot combine moments and joint likelihood fits")
    out<-.etr_joint_likelihood_covariance_sensitivity(
      fits,reference,max_lag,specifications,failures,bands)
    if(isTRUE(strict_source_record))
      return(.etr_mixed_w3_sensitivity_record(out,fits,max_lag))
    return(out)
  }
  .etr_assert(is.list(fits)&&length(fits)>=1L&&
    !is.null(names(fits))&&!anyDuplicated(names(fits))&&
    all(nzchar(names(fits)))&&
    all(vapply(fits,function(z)
      inherits(z,"etr_functional_mixed_moments"),logical(1L))),
    "fits must be a named nonempty collection of native mixed-moments fits")
  .etr_assert(is.character(reference)&&length(reference)==1L&&
    !is.na(reference)&&reference%in%names(fits),
    "reference must name a successful native model")
  .etr_assert(is.numeric(max_lag)&&length(max_lag)==1L&&
    is.finite(max_lag)&&max_lag==floor(max_lag)&&max_lag>=1,
    "max_lag must be a positive integer")
  .etr_assert(is.null(bands),
    "published mixed-model bands are not source-equivalent to native moments")
  .etr_assert(is.list(failures)&&
    (length(failures)==0L||(!is.null(names(failures))&&
      !anyDuplicated(names(failures))&&all(nzchar(names(failures)))))&&
    all(vapply(failures,function(v)is.character(v)&&length(v)==1L&&
      !is.na(v)&&nzchar(trimws(v)),logical(1L))),
    "failures must contain named nonempty reasons")
  .etr_assert(!any(names(fits)%in%names(failures)),
    "successful and failed model labels must be disjoint")
  if(is.null(specifications)){
    .etr_assert(length(failures)==0L,
      "specifications are required when failures are supplied")
    specifications<-lapply(fits,function(fit)
      list(estimator=fit$estimator,
        covariance_ridge=fit$provenance$covariance_ridge))
  }else{
    .etr_assert(is.list(specifications)&&
      !is.null(names(specifications))&&
      !anyDuplicated(names(specifications))&&
      setequal(names(specifications),c(names(fits),names(failures))),
      "specification labels must match successful and failed models")
  }
  ref<-fits[[reference]]
  .etr_mixed_moments_fit(ref)
  .etr_assert(max_lag<length(ref$time),
    "max_lag must be smaller than observed time-grid size")
  for(label in names(fits)){
    fit<-fits[[label]]
    .etr_mixed_moments_fit(fit)
    for(field in c("time","source_curve_ids","curve_participant_ids",
      "participant_ids","coefficient_names","predictor_names",
      "dimension_name","time_unit")){
      .etr_assert(identical(fit[[field]],ref[[field]]),
        paste0("covariance sensitivity requires identical ",field,
          " for model ",label))
    }
    for(field in c("observed_functions","scalar_design_matrix")){
      .etr_assert(identical(unname(fit[[field]]),unname(ref[[field]])),
        paste("covariance sensitivity requires identical",field))
    }
    .etr_assert(identical(fit$estimator,
      "two_level_functional_method_of_moments"),
      "only native moments fits can be compared")
    cfg<-specifications[[label]]
    .etr_assert(is.list(cfg)&&
      identical(cfg$estimator,fit$estimator)&&
      identical(as.numeric(cfg$covariance_ridge),
        as.numeric(fit$provenance$covariance_ridge)),
      paste("fit does not match its declared covariance ridge",label))
  }
  counts<-lapply(names(fits),function(label){
    fit<-fits[[label]]
    b<-fit$random_intercept_covariance
    data.frame(model=label,status="success",is_reference=label==reference,
      estimator=fit$estimator,
      covariance_ridge=fit$provenance$covariance_ridge,
      participant_intercept_covariance_trace=sum(diag(b)),
      residual_variance=fit$residual_variance,
      n_curves=fit$n_curves,n_participants=fit$n_participants,
      likelihood_available=FALSE,aic=NA_real_,bic=NA_real_,
      stringsAsFactors=FALSE)
  })
  failed<-lapply(names(failures),function(label)
    data.frame(model=label,status="failed",is_reference=FALSE,
      estimator="not_fitted",covariance_ridge=NA_real_,
      participant_intercept_covariance_trace=NA_real_,
      residual_variance=NA_real_,n_curves=ref$n_curves,
      n_participants=ref$n_participants,
      likelihood_available=FALSE,aic=NA_real_,bic=NA_real_,
      stringsAsFactors=FALSE))
  models<-do.call(rbind,c(counts,failed))
  change<-do.call(rbind,lapply(names(fits),function(label){
    fit<-fits[[label]]
    values<-fit$coefficient_functions-ref$coefficient_functions
    do.call(rbind,lapply(seq_along(fit$coefficient_names),function(i){
      v<-as.numeric(values[i,])
      dt<-diff(ref$time)
      norm<-sqrt(sum((v[-1]^2+v[-length(v)]^2)*dt/2))
      data.frame(model=label,coefficient=fit$coefficient_names[i],
        sup_abs_difference_from_reference=max(abs(v)),
        l2_difference_from_reference=norm,
        stringsAsFactors=FALSE)
    }))
  }))
  coefficient_frame<-do.call(rbind,lapply(names(fits),function(label){
    fit<-fits[[label]]
    do.call(rbind,lapply(seq_along(fit$coefficient_names),function(i)
      data.frame(model=label,coefficient=fit$coefficient_names[i],
        time=fit$time,estimate=as.numeric(fit$coefficient_functions[i,]),
        reference_estimate=as.numeric(ref$coefficient_functions[i,]),
        difference_from_reference=as.numeric(
          fit$coefficient_functions[i,]-ref$coefficient_functions[i,]),
        stringsAsFactors=FALSE)))
  }))
  diagnostic<-do.call(rbind,lapply(names(fits),function(label){
    fit<-fits[[label]]
    res<-fit$residual_functions
    rms<-sqrt(mean(res^2))
    data.frame(model=label,residual_rms_global=rms,
      lag=seq_len(as.integer(max_lag)),
      lag_correlation=vapply(seq_len(as.integer(max_lag)),function(k){
        a<-as.vector(res[,seq_len(ncol(res)-k),drop=FALSE])
        b<-as.vector(res[,seq.int(k+1L,ncol(res)),drop=FALSE])
        if(stats::sd(a)<=.Machine$double.eps||
           stats::sd(b)<=.Machine$double.eps)NA_real_
        else stats::cor(a,b)
      },numeric(1L)),stringsAsFactors=FALSE)
  }))
  rownames(models)<-NULL
  rownames(change)<-NULL
  rownames(coefficient_frame)<-NULL
  rownames(diagnostic)<-NULL
  structure(list(
    reference=reference,specifications=specifications,
    failures=failures,model_summary=models,
    coefficient_frame=coefficient_frame,coefficient_summary=change,
    residual_diagnostics=diagnostic,
    information_criterion_available=FALSE,
    model_selected=FALSE,ranking_performed=FALSE,
    likelihood_ratio_tests_performed=FALSE,
    source_python_equivalent=FALSE,
    independent_full_source_certified=FALSE,
    provenance=list(
      native_estimator="two_level_functional_method_of_moments",
      python_source_estimator="spline_MixedLM_REML_or_nested_GLS",
      scientific_scope="descriptive_covariance_ridge_sensitivity",
      fixed_effect_basis="observed_grid_not_spline",
      no_automatic_covariance_selection=TRUE)),
    class="etr_functional_mixed_effects_covariance_sensitivity")
}
