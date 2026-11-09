# Scientific covariance-structure sensitivity for actual nlme joint
# Gaussian spline likelihood fits. Pinned Python reference:
# functional_mixed_effects_covariance_sensitivity.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Unlike the legacy moments analogue, this path evaluates the fitted
# likelihood, same-mode AIC/BIC, variance functions, and raw/whitened
# residual lag diagnostics. It never ranks, selects or refits candidates.
# Different optimizers, object types and entire source-domain exceptions
# remain independent open contract differences.

.etr_joint_sensitivity_field<-function(fit,name,alias=NULL){
  out<-fit[[name]]
  if(is.null(out)&&!is.null(alias))out<-fit[[alias]]
  out
}
.etr_joint_sensitivity_spec<-function(label,fit){
  list(name=label,
    random_slope_predictor=fit$random_slope_predictor,
    trial_random_effect=fit$trial_random_effect,
    residual_correlation=if(is.null(fit$residual_correlation))
      "iid" else fit$residual_correlation)
}
.etr_joint_sensitivity_norm<-function(fit,label,reference){
  .etr_assert(inherits(fit,"etr_joint_bspline_mixed")&&
    inherits(reference,"etr_joint_bspline_mixed"),
    paste("joint covariance sensitivity requires joint spline likelihood fits:",label))
  for(field in c("time","curve_participant_ids","participant_ids",
      "predictor_names","fixed_basis","random_basis",
      "observed_functions","scalar_design","fixed_long_design",
      "spline_degree","reml")){
    a<-fit[[field]];b<-reference[[field]]
    .etr_assert(identical(unname(a),unname(b)),
      paste("joint covariance sensitivity requires identical",field,
        "for model",label))
  }
  a<-.etr_joint_sensitivity_field(fit,"source_curve_ids","curve_ids")
  b<-.etr_joint_sensitivity_field(reference,"source_curve_ids","curve_ids")
  .etr_assert(identical(a,b),
    paste("joint covariance sensitivity requires identical source_curve_ids for",label))
  .etr_assert(identical(fit$dimension,reference$dimension),
    paste("joint covariance sensitivity requires identical response dimension for",label))
  .etr_assert(identical(fit$time_unit,reference$time_unit),
    paste("joint covariance sensitivity requires identical time_unit for",label))
  if(!is.null(fit$trial_random_effect)&&
      !is.null(reference$trial_random_effect)){
    .etr_assert(identical(fit$curve_trial_ids,reference$curve_trial_ids)&&
      identical(unname(fit$trial_random_basis),
        unname(reference$trial_random_basis)),
      paste("joint covariance sensitivity requires identical trial identities/basis for",label))
  }
  .etr_assert(is.matrix(fit$fixed_coefficient_functions)&&
      is.matrix(fit$residual_functions)&&
      all(is.finite(fit$fixed_coefficient_functions))&&
      all(is.finite(fit$residual_functions)),
      paste("joint covariance sensitivity requires finite fitted quantities for",label))
  .etr_assert(identical(dim(fit$fixed_coefficient_functions),
      dim(reference$fixed_coefficient_functions))&&
      identical(dim(fit$residual_functions),
        dim(reference$residual_functions)),
      paste("joint covariance sensitivity requires identical coefficient and residual geometry for",label))
  .etr_assert(is.numeric(fit$residual_variance)&&
      length(fit$residual_variance)==1L&&
      is.finite(fit$residual_variance)&&fit$residual_variance>0,
      paste("joint covariance sensitivity residual variance invalid for",label))
  .etr_assert(inherits(fit$fitted_model,"lme"),
      paste("joint covariance sensitivity requires a fitted nlme likelihood for",label))
  invisible(TRUE)
}
.etr_joint_sensitivity_ic<-function(fit){
  nfix<-nrow(fit$fixed_coefficient_functions)*ncol(fit$fixed_basis)
  G<-fit$random_effect_covariance
  .etr_assert(is.matrix(G)&&nrow(G)==ncol(G)&&
    all(is.finite(G)),
    "joint random-effect covariance must be finite square")
  nrandom<-nrow(G)
  ncov<-nrandom*(nrandom+1L)/2L + 1L
  if(!is.null(fit$trial_random_effect_covariance)){
    H<-fit$trial_random_effect_covariance
    .etr_assert(is.matrix(H)&&nrow(H)==ncol(H)&&
      all(is.finite(H)),"trial random-effect covariance must be finite square")
    ncov<-ncov+nrow(H)*(nrow(H)+1L)/2L
  }
  serial<-!is.null(fit$residual_correlation)&&
    !identical(fit$residual_correlation,"iid")
  if(serial)ncov<-ncov+1L
  ll<-as.numeric(stats::logLik(fit$fitted_model))
  .etr_assert(length(ll)==1L&&is.finite(ll),
    "joint fitted marginal log likelihood is not finite")
  nobs<-fit$n_curves*fit$n_time
  k<-if(isTRUE(fit$reml))ncov else nfix+ncov
  list(n_fixed=as.integer(nfix),n_covariance=as.integer(ncov),
    n_parameters=as.integer(nfix+ncov),
    information_criterion_parameter_count=as.integer(k),
    n_observations=as.integer(nobs),log_likelihood=ll,
    aic=-2*ll+2*k,bic=-2*ll+log(nobs)*k)
}
.etr_joint_sensitivity_variance<-function(fit,label){
  values<-.etr_joint_source_variance_record(fit)
  basis<-values$random_basis;tt<-values$time
  quad<-function(G)rowSums((basis%*%G)*basis)
  records<-list()
  put<-function(component,value,kind="variance"){
    .etr_assert(length(value)==length(tt)&&all(is.finite(value)),
      paste("joint variance component",component,"is not finite"))
    records[[length(records)+1L]]<<-data.frame(
      model=label,component=component,component_type=kind,
      time=tt,value=as.numeric(value),stringsAsFactors=FALSE)
  }
  put("participant_intercept_variance",
    quad(values$random_intercept_covariance))
  if(!is.null(values$random_slope_covariance)){
    put("participant_slope_variance",
      quad(values$random_slope_covariance))
    put("participant_intercept_slope_cross_covariance",
      quad(values$random_intercept_slope_covariance),
      "covariance")
  }
  if(!is.null(values$trial_random_effect)){
    trial<-values$trial_random_basis
    G<-values$trial_random_effect_covariance
    put("trial_variance",rowSums((trial%*%G)*trial))
  }
  put("residual_variance",rep(fit$residual_variance,length(tt)))
  do.call(rbind,records)
}
.etr_joint_sensitivity_diagnostics<-function(fit,label,max_lag){
  rr<-fit$residual_functions
  C<-fit$residual_correlation_matrix
  nt<-ncol(rr)
  .etr_assert(is.matrix(C)&&identical(dim(C),c(nt,nt))&&
    all(is.finite(C)),"residual correlation matrix is invalid")
  # Match the frozen source's within-curve Cholesky whitening;
  # diagonal iid is a special case of this same operation.
  if(!is.null(fit$whitened_residual_functions)){
    white<-fit$whitened_residual_functions
  }else{
    lower<-t(chol(fit$residual_variance*C))
    white<-t(vapply(seq_len(nrow(rr)),function(i)
      as.numeric(forwardsolve(lower,rr[i,])),numeric(nt)))
  }
  .etr_assert(identical(dim(white),dim(rr))&&all(is.finite(white)),
    "joint whitened residuals must be finite per curve and time")
  one<-function(res,scale){
    rms<-sqrt(mean(res^2))
    do.call(rbind,lapply(0:as.integer(max_lag),function(lag){
      if(lag==0L){
        r<-1
        n_pairs<-length(res)
        physical<-0
      }else{
        left<-as.vector(res[,seq_len(nt-lag),drop=FALSE])
        right<-as.vector(res[,seq.int(lag+1L,nt),drop=FALSE])
        r<-if(stats::sd(left)>.Machine$double.eps&&
              stats::sd(right)>.Machine$double.eps)
          stats::cor(left,right) else NA_real_
        n_pairs<-length(left)
        physical<-mean(fit$time[seq.int(lag+1L,nt)]-
          fit$time[seq_len(nt-lag)])
      }
      data.frame(model=label,residual_scale=scale,
        lag_index=as.integer(lag),lag_physical=physical,
        time_unit=if(is.null(fit$time_unit))"unknown" else fit$time_unit,
        autocorrelation=as.numeric(r),n_pairs=as.integer(n_pairs),
        residual_rms_global=rms,stringsAsFactors=FALSE)
    }))
  }
  rbind(one(rr,"raw"),one(white,"whitened"))
}
.etr_joint_likelihood_covariance_sensitivity<-function(
    fits,reference,max_lag,specifications,failures,bands){
  .etr_assert(is.list(fits)&&length(fits)>=1L&&
    !is.null(names(fits))&&!anyNA(names(fits))&&
    !anyDuplicated(names(fits))&&all(nzchar(names(fits)))&&
    all(vapply(fits,function(x)
      inherits(x,"etr_joint_bspline_mixed"),logical(1L))),
    "fits must be named converged joint B-spline likelihood models")
  .etr_assert(is.character(reference)&&length(reference)==1L&&
    !is.na(reference)&&reference%in%names(fits),
    "reference must name a successful joint model")
  .etr_assert(is.numeric(max_lag)&&length(max_lag)==1L&&
    !is.logical(max_lag)&&is.finite(max_lag)&&
    max_lag==floor(max_lag)&&max_lag>=1L,
    "max_lag must be a positive integer")
  .etr_assert(is.null(bands),
    "joint likelihood sensitivity requires independently qualified bands")
  .etr_assert(is.list(failures)&&
    (length(failures)==0L||(!is.null(names(failures))&&
       !anyNA(names(failures))&&!anyDuplicated(names(failures))&&
       all(nzchar(names(failures)))))&&
    all(vapply(failures,function(x)is.character(x)&&length(x)==1L&&
      !is.na(x)&&nzchar(trimws(x)),logical(1L))),
    "failures must be named nonempty source declarations")
  .etr_assert(!any(names(fits)%in%names(failures)),
    "a model cannot be both successful and failed")
  if(is.null(specifications)){
    .etr_assert(length(failures)==0L,
      "specifications are required for declared failed models")
    specifications<-lapply(names(fits),function(label)
      .etr_joint_sensitivity_spec(label,fits[[label]]))
    names(specifications)<-names(fits)
  }else{
    .etr_assert(is.list(specifications)&&
      !is.null(names(specifications))&&
      !anyNA(names(specifications))&&
      !anyDuplicated(names(specifications))&&
      setequal(names(specifications),c(names(fits),names(failures))),
      "specification labels must cover successful and failed models")
  }
  ref<-fits[[reference]]
  .etr_assert(max_lag<length(ref$time),
    "max_lag must be smaller than observed time-grid size")
  for(label in names(fits)){
    fit<-fits[[label]]
    .etr_joint_sensitivity_norm(fit,label,ref)
    spec<-specifications[[label]]
    .etr_assert(is.list(spec)&&
      identical(spec$random_slope_predictor,fit$random_slope_predictor)&&
      identical(spec$trial_random_effect,fit$trial_random_effect)&&
      identical(if(is.null(spec$residual_correlation))"iid"else
        spec$residual_correlation,
        if(is.null(fit$residual_correlation))"iid"else
          fit$residual_correlation),
      paste("joint fitted model does not match its covariance specification:",label))
  }
  ref_ic<-.etr_joint_sensitivity_ic(ref)
  records<-list()
  for(label in c(names(fits),names(failures))){
    failed<-label%in%names(failures)
    if(failed){
      records[[length(records)+1L]]<-data.frame(
        model=label,status="failed",is_reference=FALSE,converged=FALSE,
        failure_reason=failures[[label]],reml=ref$reml,
        residual_correlation=if(is.null(specifications[[label]]$residual_correlation))
          "iid" else specifications[[label]]$residual_correlation,
        log_likelihood=NA_real_,n_fixed_parameters=NA_integer_,
        n_covariance_parameters=NA_integer_,n_parameters=NA_integer_,
        information_criterion_parameter_count=NA_integer_,
        n_observations=ref_ic$n_observations,
        aic=NA_real_,bic=NA_real_,delta_log_likelihood=NA_real_,
        delta_aic=NA_real_,delta_bic=NA_real_,
        participant_intercept_covariance_trace=NA_real_,
        trial_covariance_trace=NA_real_,residual_variance=NA_real_,
        stringsAsFactors=FALSE)
    }else{
      fit<-fits[[label]]
      ic<-.etr_joint_sensitivity_ic(fit)
      G<-fit$random_effect_covariance
      nr<-ncol(fit$random_basis)
      trial<-if(is.null(fit$trial_random_effect_covariance))NA_real_ else
        sum(diag(fit$trial_random_effect_covariance))
      records[[length(records)+1L]]<-data.frame(
        model=label,status="success",is_reference=label==reference,
        converged=TRUE,failure_reason=NA_character_,reml=fit$reml,
        residual_correlation=if(is.null(fit$residual_correlation))
          "iid" else fit$residual_correlation,
        log_likelihood=ic$log_likelihood,
        n_fixed_parameters=ic$n_fixed,
        n_covariance_parameters=ic$n_covariance,
        n_parameters=ic$n_parameters,
        information_criterion_parameter_count=
          ic$information_criterion_parameter_count,
        n_observations=ic$n_observations,aic=ic$aic,bic=ic$bic,
        delta_log_likelihood=ic$log_likelihood-ref_ic$log_likelihood,
        delta_aic=ic$aic-ref_ic$aic,delta_bic=ic$bic-ref_ic$bic,
        participant_intercept_covariance_trace=
          sum(diag(G[seq_len(nr),seq_len(nr),drop=FALSE])),
        trial_covariance_trace=trial,
        residual_variance=fit$residual_variance,
        stringsAsFactors=FALSE)
    }
  }
  model_summary<-do.call(rbind,records)
  coef_names<-rownames(ref$fixed_coefficient_functions)
  if(is.null(coef_names))coef_names<-ref$predictor_names
  coef_summary<-list();coef_rows<-list()
  for(label in names(fits)){
    fit<-fits[[label]]
    difference<-fit$fixed_coefficient_functions-
      ref$fixed_coefficient_functions
    for(j in seq_len(nrow(difference))){
      delta<-as.numeric(difference[j,])
      dt<-diff(ref$time)
      magnitude<-sqrt(sum(
        (delta[-1L]^2+delta[-length(delta)]^2)*dt/2))
      coef_summary[[length(coef_summary)+1L]]<-data.frame(
        model=label,coefficient=coef_names[j],
        sup_abs_difference_from_reference=max(abs(delta)),
        l2_difference_from_reference=magnitude,
        stringsAsFactors=FALSE)
      coef_rows[[length(coef_rows)+1L]]<-data.frame(
        model=label,coefficient=coef_names[j],time=fit$time,
        estimate=as.numeric(fit$fixed_coefficient_functions[j,]),
        reference_estimate=as.numeric(
          ref$fixed_coefficient_functions[j,]),
        difference_from_reference=delta,stringsAsFactors=FALSE)
    }
  }
  var_frames<-lapply(names(fits),function(label)
    .etr_joint_sensitivity_variance(fits[[label]],label))
  diag_frames<-lapply(names(fits),function(label)
    .etr_joint_sensitivity_diagnostics(fits[[label]],label,max_lag))
  for(i in seq_along(model_summary$model)){
    label<-model_summary$model[i]
    if(model_summary$status[i]!="success")next
    frame<-diag_frames[[match(label,names(fits))]]
    model_summary$raw_residual_rms[i]<-sqrt(mean(
      fits[[label]]$residual_functions^2))
    model_summary$whitened_residual_rms[i]<-
      unique(frame$residual_rms_global[frame$residual_scale=="whitened"])[1L]
  }
  rownames(model_summary)<-NULL
  frame<-do.call(rbind,coef_rows);rownames(frame)<-NULL
  summary<-do.call(rbind,coef_summary);rownames(summary)<-NULL
  variance<-do.call(rbind,var_frames);rownames(variance)<-NULL
  residual<-do.call(rbind,diag_frames);rownames(residual)<-NULL
  empty_band<-data.frame(model=character(),
    coefficient=character(),time=numeric(),band_width=numeric(),
    reference_band_width=numeric(),
    band_width_ratio_to_reference=numeric())
  structure(list(reference=reference,specifications=specifications,
    failures=failures,model_summary=model_summary,
    coefficient_frame=frame,coefficient_summary=summary,
    variance_decomposition=variance,
    residual_diagnostics=residual,band_width_frame=empty_band,
    information_criterion_available=TRUE,model_selected=FALSE,
    ranking_performed=FALSE,likelihood_ratio_tests_performed=FALSE,
    source_python_equivalent=FALSE,independent_full_source_certified=FALSE,
    provenance=list(
      native_estimator="nlme_joint_bspline_likelihood",
      python_source_estimator="statsmodels_MixedLM_or_nested_GLS",
      scientific_scope="predeclared_joint_likelihood_covariance_sensitivity",
      no_automatic_covariance_selection=TRUE,
      REML_and_ML_must_not_be_compared=TRUE,
      entire_python_domain_and_optimizer_parity_certified=FALSE)),
    class=c("etr_joint_likelihood_covariance_sensitivity",
      "etr_functional_mixed_effects_covariance_sensitivity"))
}
