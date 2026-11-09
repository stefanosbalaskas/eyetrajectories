# Restricted native functional repeated-measures model.
# The estimator below is explicitly a two-level METHOD-OF-MOMENTS model,
# NOT the spline-based likelihood/reml/GLS backend in Python 1.2.
# Residual audits follow Python 1.2 diagnostics.py conventions.
# All production numerical operations are base R, with no Python dependency.

.etr_mixed_moments_fit <- function(x){
  .etr_assert(inherits(x,"etr_functional_mixed_moments") &&
    identical(x$estimator,"two_level_functional_method_of_moments") &&
    isTRUE(x$converged)&&is.matrix(x$residual_functions)&&
    is.numeric(x$residual_functions)&&all(is.finite(x$residual_functions)) &&
    is.numeric(x$time)&&length(x$time)==ncol(x$residual_functions) &&
    all(is.finite(x$time))&&all(diff(x$time)>0) &&
    nrow(x$residual_functions)==length(x$source_curve_ids) &&
    nrow(x$residual_functions)==length(x$curve_participant_ids),
    "requires a finite, converged restricted native mixed-moments fit")
  invisible(x)
}
.etr_mixed_moments_psd <- function(a){
  a<-(a+t(a))/2
  eigen<-eigen(a,symmetric=TRUE)
  eigen$vectors%*%(pmax(0,eigen$values)*t(eigen$vectors))
}
.etr_mixed_moments_cov <- function(a){
  a<-as.matrix(a)
  .etr_assert(nrow(a)>=2L,"need at least two independent covariance records")
  crossprod(scale(a,center=TRUE,scale=FALSE))/(nrow(a)-1L)
}

#' Restricted two-level functional fixed effects and participant BLUPs
#' @param trajectories Complete common-grid trajectories.
#' @param design Data frame containing one row per source curve, with curve_id.
#' @param predictors Explicit independent scalar fixed predictors.
#' @param participant_column Complete participant metadata column.
#' @param dimension Exactly one response channel name.
#' @param covariance_ridge Relative positive ridge added to within covariance.
#' @export
etr_fit_functional_mixed_effects_regression <- function(trajectories,
    design,predictors,participant_column,dimension,
    covariance_ridge=1e-6){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(trajectories$coordinate_system!="probability_simplex",
    "Gaussian mixed-moments regression requires non-simplex response")
  .etr_assert(is.data.frame(design)&&
    "curve_id"%in%names(design) &&
    !anyDuplicated(design$curve_id) &&
    nrow(design)==length(trajectories$curve_ids),
    "design must have one unique curve_id row per source curve")
  alignment<-match(trajectories$curve_ids,as.character(design$curve_id))
  .etr_assert(!anyNA(alignment),"design is missing source curve IDs")
  .etr_assert(is.character(predictors)&&!anyNA(predictors)&&
    !anyDuplicated(predictors)&&all(predictors%in%names(design)) &&
    !"curve_id"%in%predictors,"predictors must be unique known design columns")
  .etr_assert(is.character(dimension)&&length(dimension)==1L &&
    dimension%in%trajectories$dimension_names,
    "dimension must identify one response channel")
  .etr_assert(is.character(participant_column)&&
    length(participant_column)==1L&&
    participant_column%in%names(trajectories$metadata),
    "participant_column must exist in source metadata")
  .etr_assert(is.numeric(covariance_ridge)&&
    length(covariance_ridge)==1L&&is.finite(covariance_ridge)&&
    covariance_ridge>0&&covariance_ridge<1,
    "covariance_ridge must lie in (0,1)")
  group<-as.character(trajectories$metadata[[participant_column]])
  .etr_assert(!anyNA(group)&&all(nzchar(group)),
    "participant identifiers must be complete")
  participants<-unique(group);G<-length(participants)
  n<-length(group);time<-trajectories$time;nt<-length(time)
  .etr_assert(G>=3L&&all(tabulate(match(group,participants))>=2L),
    "requires >=3 independent participants with >=2 curves each")
  X<-matrix(1,n,1,dimnames=list(NULL,"Intercept"))
  if(length(predictors))for(p in predictors){
    val<-design[[p]][alignment]
    .etr_assert(is.numeric(val)&&all(is.finite(val)),
      paste("predictor",p,"must be complete finite numeric"))
    X<-cbind(X,val);colnames(X)[ncol(X)]<-p
  }
  .etr_assert(qr(X)$rank==ncol(X)&&n>ncol(X),
    "expanded fixed-effect design is rank deficient")
  Y<-matrix(trajectories$values[,,match(dimension,
    trajectories$dimension_names),drop=FALSE],nrow=n,ncol=nt)
  beta<-qr.solve(X,Y)
  .etr_assert(is.matrix(beta)&&nrow(beta)==ncol(X)&&
    all(is.finite(beta)),"fixed effect coefficient functions invalid")
  residual<-Y-X%*%beta
  group_means<-matrix(0,G,nt)
  within<-matrix(0,nt,nt)
  sizes<-integer(G)
  for(g in seq_len(G)){
    ix<-which(group==participants[g]);sizes[g]<-length(ix)
    group_means[g,]<-colMeans(residual[ix,,drop=FALSE])
    centered<-sweep(residual[ix,,drop=FALSE],2L,group_means[g,],"-")
    within<-within+crossprod(centered)
  }
  within<-within/(n-G)
  .etr_assert(all(is.finite(within)),"within covariance nonfinite")
  residual_var<-mean(diag(within))
  .etr_assert(is.finite(residual_var)&&residual_var>0,
    "within covariance contains no positive residual variation")
  within_pd<-within+diag(covariance_ridge*residual_var,nt)
  # A declared, unequal-group moment approximation: E Var(mean residual)
  # includes mean(1/m_g) times the pooled within-curve covariance.
  between<-.etr_mixed_moments_cov(group_means)-
    mean(1/sizes)*within_pd
  between<-.etr_mixed_moments_psd(between)
  blup<-matrix(0,G,nt)
  for(g in seq_len(G)){
    lhs<-between+within_pd/sizes[g]
    blup[g,]<-as.vector(between%*%solve(lhs,group_means[g,]))
  }
  curve_blup<-blup[match(group,participants),,drop=FALSE]
  fitted<-X%*%beta+curve_blup
  conditional<-Y-fitted
  # Cluster-score sandwich for pointwise OLS fixed coefficient functions.
  Hinv<-solve(crossprod(X))
  se<-matrix(0,ncol(X),nt)
  for(t in seq_len(nt)){
    meat<-matrix(0,ncol(X),ncol(X))
    for(g in seq_len(G)){
      ix<-which(group==participants[g])
      score<-crossprod(X[ix,,drop=FALSE],residual[ix,t])
      meat<-meat+tcrossprod(score)
    }
    cov<-Hinv%*%meat%*%Hinv
    se[,t]<-sqrt(pmax(0,diag(cov)))
  }
  corr<-within_pd/residual_var
  structure(list(estimator="two_level_functional_method_of_moments",
    converged=TRUE,n_curves=n,n_participants=G,time=time,
    time_unit=trajectories$time_unit,dimension_name=dimension,
    source_curve_ids=trajectories$curve_ids,
    curve_participant_ids=group,participant_ids=participants,
    curves_per_participant=sizes,
    predictor_names=predictors,coefficient_names=colnames(X),
    scalar_design_matrix=X,coefficient_functions=beta,
    coefficient_standard_errors=se,
    observed_functions=Y,fitted_functions=fitted,
    residual_functions=conditional,
    fixed_residual_functions=residual,
    participant_random_functions=blup,
    residual_variance=residual_var,
    residual_correlation="empirical_regularized",
    residual_correlation_matrix=corr,
    random_basis=diag(nt),
    random_intercept_covariance=between,
    random_slope_covariance=NULL,
    random_intercept_slope_covariance=NULL,
    trial_random_effect=NULL,
    provenance=list(operation="fit_functional_mixed_effects_regression",
      estimator="two_level_functional_method_of_moments",
      source_python_equivalent=FALSE,
      likelihood_optimized=FALSE,REML=FALSE,
      fixed_effect="per_time_point_OLS",
      random_intercept="PSD_projected_participant_functional_covariance",
      unequal_trial_correction="mean_inverse_participant_curve_count",
      covariance_ridge=covariance_ridge,
      uncertainty="pointwise_cluster_score_sandwich_descriptive",
      unsupported=c("random_functional_slope","trial_random_effect",
        "joint_spline_MixedLM_GLS","REML_covariance_optimization"))),
    class="etr_functional_mixed_moments")
}

#' Within-trial conditional residual whitening for restricted mixed moments
#' @param result Native restricted mixed-moments fit.
#' @export
etr_functional_mixed_effects_whitened_residuals <- function(result){
  .etr_mixed_moments_fit(result)
  nt<-length(result$time)
  V<-result$residual_variance*result$residual_correlation_matrix
  .etr_assert(is.matrix(V)&&identical(dim(V),c(nt,nt))&&
    all(is.finite(V))&&isTRUE(all.equal(V,t(V),tolerance=1e-8)),
    "residual covariance must be finite symmetric nt by nt")
  R<-tryCatch(chol(V),error=function(e)
    stop("residual covariance is not positive definite",call.=FALSE))
  t(forwardsolve(t(R),t(result$residual_functions)))
}
.etr_mixed_moments_aggregate <- function(trial,cols){
  keys<-unique(trial[,cols,drop=FALSE])
  rows<-vector("list",nrow(keys))
  for(i in seq_len(nrow(keys))){
    keep<-rep(TRUE,nrow(trial))
    for(c in cols)keep<-keep&(trial[[c]]==keys[[c]][i])
    f<-trial[keep,,drop=FALSE];w<-f$n_pairs
    weighted<-function(metric){
      x<-f[[metric]];ok<-is.finite(x)&w>0
      if(!any(ok))return(NaN)
      sum(w[ok]*x[ok])/sum(w[ok])
    }
    acf<-f$autocorrelation[is.finite(f$autocorrelation)]
    rows[[i]]<-cbind(keys[i,,drop=FALSE],
      data.frame(lag_time_mean=f$lag_time_mean[1L],
        lag_time_min=f$lag_time_min[1L],
        lag_time_max=f$lag_time_max[1L],
        n_pairs=as.integer(sum(w)),n_trials_total=nrow(f),
        n_trials_acf_defined=length(acf),
        autocovariance=weighted("autocovariance"),
        autocorrelation=weighted("autocorrelation"),
        semivariance=weighted("semivariance"),
        trial_autocorrelation_min=if(length(acf))min(acf)else NaN,
        trial_autocorrelation_max=if(length(acf))max(acf)else NaN))
  }
  do.call(rbind,rows)
}
#' Trial, participant, and overall residual lag dependence diagnostics
#' @param max_lag Explicit within-curve lag count.
#' @param residual_scale "raw" or fitted-covariance "whitened".
#' @inheritParams etr_functional_mixed_effects_whitened_residuals
#' @export
etr_functional_mixed_effects_residual_diagnostics <- function(result,
    max_lag,residual_scale="raw"){
  .etr_mixed_moments_fit(result)
  lag<-.etr_nonlinear_integer(max_lag,1L,"max_lag")
  nt<-length(result$time)
  .etr_assert(lag<nt,"max_lag must be smaller than n_time")
  .etr_assert(is.character(residual_scale)&&length(residual_scale)==1L&&
    residual_scale%in%c("raw","whitened"),
    "residual_scale must be raw or whitened")
  resid<-if(identical(residual_scale,"raw"))result$residual_functions
    else etr_functional_mixed_effects_whitened_residuals(result)
  trial<-vector("list",nrow(resid)*(lag+1L))
  ptr<-0L
  for(i in seq_len(nrow(resid))){
    r<-resid[i,];centered<-r-mean(r)
    variance<-mean(centered^2);zero<-variance==0
    for(h in 0:lag){
      at<-seq_len(nt-h);bt<-at+h
      physical<-result$time[bt]-result$time[at]
      acov<-mean(centered[at]*centered[bt])
      ptr<-ptr+1L
      trial[[ptr]]<-data.frame(
        curve_index=as.integer(i-1L),
        curve_id=result$source_curve_ids[i],
        participant_id=result$curve_participant_ids[i],
        lag_index=as.integer(h),
        lag_time_mean=mean(physical),
        lag_time_min=min(physical),lag_time_max=max(physical),
        n_pairs=as.integer(length(at)),residual_mean=mean(r),
        residual_sd=sqrt(variance),residual_rms=sqrt(mean(r^2)),
        zero_residual_variance=zero,
        autocovariance=acov,
        autocorrelation=if(zero)NaN else acov/variance,
        semivariance=.5*mean((r[bt]-r[at])^2))
    }
  }
  trial<-do.call(rbind,trial)
  participant<-.etr_mixed_moments_aggregate(trial,c("participant_id","lag_index"))
  overall<-.etr_mixed_moments_aggregate(trial,"lag_index")
  structure(list(reference=result,trial_diagnostics=trial,
    participant_diagnostics=participant,overall_diagnostics=overall,
    max_lag=lag,residual_scale=residual_scale,
    provenance=list(operation="functional_mixed_effects_residual_diagnostics",
      residual_type="conditional_moment_model_residual",
      within_trial_centering=TRUE,
      participant_summary="pair_count_weighted",
      overall_summary="pair_count_weighted",
      automatic_lag_selection=FALSE,
      residual_model="restricted_moment_based_not_python_MixedLM")),
    class="etr_functional_mixed_residual_diagnostics")
}

#' Auditable native residual dependence frame, filtered at one analysis level
#' @param level Trial, participant or overall.
#' @param curve_id,participant_id Optional compatible identifiers.
#' @inheritParams etr_functional_mixed_effects_whitened_residuals
#' @export
etr_functional_mixed_effects_residual_diagnostic_frame <- function(result,
    level="trial",curve_id=NULL,participant_id=NULL){
  .etr_assert(inherits(result,"etr_functional_mixed_residual_diagnostics"),
    "requires a native residual diagnostic result")
  .etr_assert(is.character(level)&&length(level)==1L&&
    level%in%c("trial","participant","overall"),
    "level must be trial, participant or overall")
  .etr_assert(is.null(curve_id)||identical(level,"trial"),
    "curve_id is accepted only for trial diagnostics")
  .etr_assert(is.null(participant_id)||identical(level,"participant"),
    "participant_id is accepted only for participant diagnostics")
  f<-switch(level,trial=result$trial_diagnostics,
    participant=result$participant_diagnostics,
    overall=result$overall_diagnostics)
  if(!is.null(curve_id)){
    f<-f[as.character(f$curve_id)==as.character(curve_id),,drop=FALSE]
    .etr_assert(nrow(f)>0L,"Unknown curve_id")
  }
  if(!is.null(participant_id)){
    f<-f[as.character(f$participant_id)==as.character(participant_id),,drop=FALSE]
    .etr_assert(nrow(f)>0L,"Unknown participant_id")
  }
  rownames(f)<-NULL
  f
}

#' Exact within-trial residual pairs and physical time offsets
#' @param lag_index Explicit zero-based within-trial index lag.
#' @inheritParams etr_functional_mixed_effects_residual_diagnostic_frame
#' @export
etr_functional_mixed_effects_residual_pair_frame <- function(result,
    lag_index,curve_id=NULL,participant_id=NULL){
  .etr_assert(inherits(result,"etr_functional_mixed_residual_diagnostics"),
    "requires a native residual diagnostic result")
  h<-.etr_nonlinear_integer(lag_index,0L,"lag_index")
  .etr_assert(h<=result$max_lag,"lag_index exceeds max_lag")
  fit<-result$reference;.etr_mixed_moments_fit(fit)
  resid<-if(result$residual_scale=="raw")fit$residual_functions else
    etr_functional_mixed_effects_whitened_residuals(fit)
  nt<-length(fit$time)
  frames<-vector("list",nrow(resid))
  for(i in seq_len(nrow(resid))){
    if(!is.null(curve_id)&&!identical(as.character(curve_id),
      as.character(fit$source_curve_ids[i])))next
    if(!is.null(participant_id)&&!identical(as.character(participant_id),
      as.character(fit$curve_participant_ids[i])))next
    idx<-seq_len(nt-h);end<-idx+h;r<-resid[i,]
    centered<-r-mean(r)
    frames[[i]]<-data.frame(
      curve_index=rep(as.integer(i-1L),length(idx)),
      curve_id=rep(fit$source_curve_ids[i],length(idx)),
      participant_id=rep(fit$curve_participant_ids[i],length(idx)),
      lag_index=rep(h,length(idx)),start_index=as.integer(idx-1L),
      end_index=as.integer(end-1L),time_start=fit$time[idx],
      time_end=fit$time[end],physical_lag=fit$time[end]-fit$time[idx],
      residual_start=r[idx],residual_end=r[end],
      centered_product=centered[idx]*centered[end],
      semivariance_contribution=.5*(r[end]-r[idx])^2)
  }
  frames<-Filter(Negate(is.null),frames)
  .etr_assert(length(frames)>0L,"Unknown curve_id or participant_id")
  do.call(rbind,frames)
}

#' Variance functions for a restricted native two-level functional fit
#' @param fit Native restricted moments model.
#' @param model_label Optional nonempty model label.
#' @export
etr_functional_mixed_effects_variance_decomposition <- function(fit,
    model_label=NULL){
  # Direct native B-spline likelihood fit: map its already estimated
  # random-covariance blocks onto the frozen Python numerical component
  # formula. No refit, no synthetic variance or optimizer substitution.
  if(inherits(fit,"etr_joint_bspline_mixed"))
    fit <- .etr_joint_source_variance_record(fit)
  if(!inherits(fit,"etr_functional_mixed_moments")){
    # Source-shaped frozen Python 1.2.0 FunctionalMixedEffectsResult.
    # Do not coerce a restricted moment fit into a REML/GLS model.
    .etr_recovery_source_fields(fit,c(
      "time","random_basis","random_intercept_covariance",
      "residual_variance"),"source mixed fit")
    name<-if(is.null(model_label))"model" else model_label
    .etr_assert(is.character(name)&&length(name)==1L&&
      !is.na(name)&&nzchar(name),"model_label must be non-empty when supplied")
    grid<-fit$time
    .etr_assert(is.numeric(grid)&&is.null(dim(grid))&&
      length(grid)>=1L&&all(is.finite(grid)),
      "source mixed time must be finite numeric grid")
    nt<-length(grid)
    B<-fit$random_basis
    .etr_assert(is.matrix(B)&&is.numeric(B)&&
      nrow(B)==nt&&ncol(B)>=1L&&all(is.finite(B)),
      "source mixed random_basis must match time by basis")
    .etr_assert(is.numeric(fit$residual_variance)&&
      length(fit$residual_variance)==1L&&
      is.finite(fit$residual_variance),
      "source residual_variance must be finite numeric scalar")
    rows<-list()
    add<-function(component,values,kind){
      rows[[length(rows)+1L]]<<-data.frame(
        model=rep(name,nt),component=rep(component,nt),
        component_type=rep(kind,nt),time=grid,
        value=as.numeric(values),stringsAsFactors=FALSE)
    }
    quadratic<-function(basis,covariance,label){
      .etr_assert(is.matrix(basis)&&is.numeric(basis)&&
        nrow(basis)==nt&&ncol(basis)>=1L&&
        all(is.finite(basis)),
        paste(label,"basis must be finite time by basis matrix"))
      k<-ncol(basis)
      .etr_assert(is.matrix(covariance)&&is.numeric(covariance)&&
        identical(dim(covariance),c(k,k))&&
        all(is.finite(covariance)),
        paste(label,"covariance must be finite square basis matrix"))
      rowSums((basis%*%covariance)*basis)
    }
    add("participant_intercept_variance",
      quadratic(B,fit$random_intercept_covariance,
        "participant intercept"),"variance")
    if(!is.null(fit[["random_slope_covariance",exact=TRUE]])){
      add("participant_slope_variance",
        quadratic(B,fit$random_slope_covariance,
          "participant slope"),"variance")
      .etr_assert(!is.null(fit[["random_intercept_slope_covariance",exact=TRUE]]),
        "random slope covariance is present without intercept/slope cross-covariance")
      # Source emits a signed covariance, not a variance or percentage.
      add("participant_intercept_slope_cross_covariance",
        quadratic(B,fit$random_intercept_slope_covariance,
          "participant intercept/slope"),"covariance")
    }
    # An absent short optional field must not match the longer
    # trial_random_effect_covariance field.
    trial<-fit[["trial_random_effect",exact=TRUE]]
    if(!is.null(trial)){
      .etr_assert(identical(trial,"functional_intercept"),
        "unsupported source trial_random_effect")
      .etr_assert(!is.null(fit$trial_random_basis)&&
        !is.null(fit$trial_random_effect_covariance),
        "trial random-effect result is missing its basis/covariance")
      add("trial_variance",
        quadratic(fit$trial_random_basis,
          fit$trial_random_effect_covariance,"trial"),"variance")
    }
    add("residual_variance",rep(fit$residual_variance,nt),"variance")
    return(do.call(rbind,rows))
  }
  .etr_mixed_moments_fit(fit)
  name<-if(is.null(model_label))"model" else model_label
  .etr_assert(is.character(name)&&length(name)==1L&&nzchar(name),
    "model_label must be nonempty")
  B<-fit$random_basis;C<-fit$random_intercept_covariance
  v<-rowSums((B%*%C)*B)
  part<-data.frame(model=name,
    component="participant_intercept_variance",
    component_type="variance",time=fit$time,value=pmax(0,v))
  resid<-data.frame(model=name,component="residual_variance",
    component_type="variance",time=fit$time,
    value=rep(fit$residual_variance,length(fit$time)))
  rbind(part,resid)
}

#' Source-shaped fixed coefficient and pointwise sandwich standard error table
#' @param band Unsupported; only NULL preserves clear inference boundary.
#' @inheritParams etr_functional_mixed_effects_whitened_residuals
#' @export
etr_functional_mixed_effects_coefficient_frame <- function(result,band=NULL){
  # Preserve the original restricted moments path. Native likelihood
  # models use the source-ordered coefficient frame without a refit.
  if(inherits(result,"etr_joint_bspline_mixed"))
    return(.etr_joint_source_coefficient_frame(result,band))
  .etr_mixed_moments_fit(result)
  .etr_assert(is.null(band),
    "simultaneous mixed-model bootstrap bands are not yet qualified")
  names<-result$coefficient_names;nt<-length(result$time)
  zval<-1.959963984540054
  out<-vector("list",length(names)*nt);k<-0L
  for(i in seq_along(names))for(t in seq_len(nt)){
    k<-k+1L;e<-result$coefficient_functions[i,t]
    se<-result$coefficient_standard_errors[i,t]
    out[[k]]<-data.frame(coefficient=names[i],
      time=result$time[t],dimension=result$dimension_name,
      estimate=e,standard_error=se,
      lower_95_wald=e-zval*se,upper_95_wald=e+zval*se)
  }
  do.call(rbind,out)
}
