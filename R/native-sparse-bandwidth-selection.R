# Training-only sparse population CV following the frozen Python 1.2
# univariate and paired selectors. The held-out loss uses full covariance.

.etr_sparse_cv_permutation <- function(n,seed){
  if(is.null(seed))return(sample.int(n))
  .etr_assert(is.numeric(seed)&&length(seed)==1L&&is.finite(seed)&&
    seed==floor(seed)&&seed>=0&&seed<2^32,
    "random_state must be NULL or an unsigned 32-bit integer")

  # NumPy's legacy RandomState shuffle uses MT19937 and rejection sampling.
  # R has no unsigned integer type. Work in exactly represented doubles
  # and use two 16-bit words for bitwise operations.
  word<-2^16
  modulus<-2^32
  xor<-function(a,b)bitwXor(floor(a/word),floor(b/word))*word+
    bitwXor(a%%word,b%%word)
  and<-function(a,b)bitwAnd(floor(a/word),floor(b/word))*word+
    bitwAnd(a%%word,b%%word)
  state<-numeric(624L)
  state[1L]<-seed
  for(i in 2:624){
    prev<-xor(state[i-1L],floor(state[i-1L]/2^30))
    low<-prev%%word
    high<-floor(prev/word)
    multiplier<-1812433253
    state[i]<-((multiplier%%word)*low+
      ((multiplier%%word)*high+floor(multiplier/word)*low)*word+i-1L)%%modulus
  }
  cursor<-625L
  draw<-function(){
    if(cursor>624L){
      for(i in seq_len(624L)){
        next_word<-state[i%%624L+1L]
        y<-floor(state[i]/2^31)*2^31+next_word%%2^31
        shifted<-floor(y/2)
        if(y%%2!=0)shifted<-xor(shifted,0x9908b0df)
        state[i]<<-xor(state[(i+396L)%%624L+1L],shifted)
      }
      cursor<<-1L
    }
    y<-state[cursor]
    cursor<<-cursor+1L
    y<-xor(y,floor(y/2^11))
    y<-xor(y,and((y*2^7)%%modulus,0x9d2c5680))
    y<-xor(y,and((y*2^15)%%modulus,0xefc60000))
    xor(y,floor(y/2^18))
  }
  order<-seq_len(n)
  for(i in seq.int(n,2L)){
    mask_modulus<-2^ceiling(log2(i))
    repeat {
      j<-1L+draw()%%mask_modulus
      if(j<=i)break
    }
    value<-order[i]
    order[i]<-order[j]
    order[j]<-value
  }
  order
}

.etr_sparse_cv_folds <- function(x,options){
  n<-length(x$curve_ids)
  k<-options$n_splits
  .etr_assert(is.numeric(k)&&length(k)==1L&&is.finite(k)&&
    k==floor(k)&&k>=2L&&k<=n,
    "n_splits must be an integer from two to the number of curves")
  k<-as.integer(k)
  unit<-options$resampling_unit
  .etr_assert(identical(unit,"curve")||identical(unit,"group"),
    "resampling_unit must be curve or group")
  shuffle<-options$shuffle
  .etr_assert(is.logical(shuffle)&&length(shuffle)==1L&&!is.na(shuffle),
    "shuffle must be a nonmissing logical scalar")
  if(!is.null(options$fold_assignments)){
    assignment<-.etr_cv_explicit_fold_assignment(x,k,unit,
      options$group_column,options$fold_assignments)
    policy<-"declared_folds"
  }else if(unit=="group"||!shuffle){
    assignment<-.etr_cv_fold_assignment(x,k,unit,options$group_column,
      FALSE,NULL,sparse_source_order=TRUE)
    policy<-if(unit=="group")"native_group_size_balanced"else"unshuffled_kfold"
  }else{
    permutation<-.etr_sparse_cv_permutation(n,options$random_state)
    sizes<-rep(n%/%k,k)+as.integer(seq_len(k)<=n%%k)
    fold<-integer(n)
    fold[permutation]<-rep(seq_len(k)-1L,sizes)
    assignment<-list(fold=fold,groups=NULL)
    policy<-if(is.null(options$random_state))"unseeded_R_kfold"else"numpy_randomstate_kfold"
  }
  validation<-lapply(seq_len(k)-1L,function(i)which(assignment$fold==i))
  .etr_assert(all(n-lengths(validation)>=3L),
    "each training fold must contain at least three curves for native sparse FPCA")
  order<-unlist(validation,use.names=FALSE)
  frame<-data.frame(curve_id=x$curve_ids[order],
    fold=assignment$fold[order],stringsAsFactors=FALSE)
  if(!is.null(assignment$groups))frame$group<-assignment$groups[order]
  list(validation=validation,assignments=frame,policy=policy)
}

.etr_sparse_cv_subset <- function(x,rows){
  x$time<-x$time[rows]
  x$values<-x$values[rows]
  x$curve_ids<-x$curve_ids[rows]
  x$metadata<-x$metadata[rows,,drop=FALSE]
  x
}

.etr_sparse_cv_loss <- function(population,grid,time,observed,noise,limit){
  paired<-ncol(observed)==2L
  if(paired){
    mean<-vapply(seq_len(2L),function(j)
      .etr_spn_eval(grid,population$mean[,j],time),numeric(length(time)))
    mean<-matrix(mean,nrow=length(time),ncol=2L)
    sigma<-.etr_spnm_cov_eval(grid,population$operator$covariance,time)+
      kronecker(diag(length(time)),noise)
  }else{
    mean<-.etr_spn_eval(grid,population$mean,time)
    sigma<-.etr_spn_cov_eval(grid,population$covariance,time)+
      diag(population$noise_variance,length(time))
  }
  sigma<-(sigma+t(sigma))/2
  eigenvalues<-eigen(sigma,symmetric=TRUE,only.values=TRUE)$values
  minimum<-min(eigenvalues)
  maximum<-max(eigenvalues)
  prefix<-if(paired)"predictive_joint_covariance"else"predictive_covariance"
  if(minimum<=0)
    .etr_spn_fail(paste0(prefix,"_not_positive_definite"),
      "held-out predictive covariance is not positive definite")
  condition<-maximum/minimum
  if(condition>limit)
    .etr_spn_fail(paste0(prefix,"_ill_conditioned"),
      "held-out predictive covariance exceeds the condition-number limit")
  residual<-as.vector(t(observed-mean))
  quadratic<-sum(residual*solve(sigma,residual,tol=0))
  dimension<-length(residual)
  list(loss=(sum(log(eigenvalues))+quadratic+dimension*log(2*pi))/(2*dimension),
    predictive_condition_number=condition,
    predictive_minimum_eigenvalue=minimum,predictive_maximum_eigenvalue=maximum)
}

.etr_sparse_bandwidth_selection <- function(x,cfg,paired){
  request<-cfg$bandwidth_selection
  fixed<-c(!is.null(cfg$mean_bandwidth),!is.null(cfg$covariance_bandwidth))
  if(is.null(request)){
    .etr_assert(all(fixed),"fixed mode requires mean_bandwidth and covariance_bandwidth")
    return(NULL)
  }
  .etr_assert(!any(fixed),"declare exactly one bandwidth mode")
  options<-list(mean_bandwidths=NULL,covariance_bandwidths=NULL,n_splits=5L,
    resampling_unit="curve",group_column=NULL,shuffle=TRUE,random_state=0L,
    min_valid_folds=NULL,failure_action="retain",predictive_condition_limit=1e12,
    fold_assignments=NULL)
  .etr_assert(is.list(request)&&!is.data.frame(request)&&
    length(names(request))==length(request)&&!anyDuplicated(names(request))&&
    all(names(request)%in%names(options)),
    "bandwidth_selection must be a named list of declared CV options")
  options[names(request)]<-request
  positive_grid<-function(values,name){
    .etr_assert(is.numeric(values)&&is.null(dim(values))&&length(values)>0L&&
      all(is.finite(values)&values>0),paste(name,"must contain positive finite bandwidths"))
    sort(unique(as.numeric(values)))
  }
  options$mean_bandwidths<-positive_grid(options$mean_bandwidths,"mean_bandwidths")
  options$covariance_bandwidths<-positive_grid(options$covariance_bandwidths,"covariance_bandwidths")
  model_parameters<-c("evaluation_grid","analysis_support_action","psd_action",
    "psd_tolerance","mean_min_local_points","covariance_min_local_pairs",
    if(paired)c("dimensions","measurement_error","measurement_error_variance",
      "measurement_error_covariance") else c("dimension","noise_bandwidth",
      "noise_support","noise_variance_method","measurement_error_variance",
      "positive_eigen_tolerance","mean_smoother","covariance_smoother",
      "kernel","noise_min_local_points"))
  parameters<-c(cfg[model_parameters],options)
  if(is.null(options$fold_assignments))parameters$fold_assignments<-NULL
  .etr_sparse_timed_step("bandwidth_selection",
    if(paired)"select_sparse_mfpca_bandwidths"else"select_sparse_fpca_bandwidths",
    parameters,.etr_sparse_evaluate_bandwidths(x,cfg,paired,options))
}

.etr_sparse_evaluate_bandwidths <- function(x,cfg,paired,options){
  means<-options$mean_bandwidths
  covariances<-options$covariance_bandwidths
  .etr_irregular_validate_samples(x)
  dimensions<-if(paired)cfg$dimensions else cfg$dimension
  .etr_assert(is.character(dimensions)&&length(dimensions)==if(paired)2L else 1L,
    "bandwidth selection requires the declared response dimension(s)")
  columns<-match(dimensions,x$dimension_names)
  .etr_assert(!anyNA(columns)&&!anyDuplicated(columns),
    "bandwidth selection requires distinct observed response dimensions")
  if(paired&&length(x$curve_ids)<3L)
    .etr_spn_fail("insufficient_joint_support",
      "sparse planar bandwidth selection requires at least three curves",
      list(n_curves=length(x$curve_ids)))
  for(i in seq_along(x$curve_ids)){
    finite<-is.finite(x$values[[i]][,columns,drop=FALSE])
    if(paired){
      mismatch<-which(finite[,1L]!=finite[,2L])
      if(length(mismatch))
        .etr_spn_fail("coordinate_specific_missingness_unsupported",
          "x and y must be jointly observed at every retained sparse timestamp",
          list(curve_id=x$curve_ids[i],sample_indices=mismatch-1L,
            dimensions=dimensions))
      nonfinite<-which(!finite[,1L])
      if(length(nonfinite))
        .etr_spn_fail("nonfinite_sparse_planar_observation",
          "bandwidth selection requires finite paired planar samples",
          list(curve_id=x$curve_ids[i],sample_indices=nonfinite-1L,
            dimensions=dimensions))
    }else if(any(!finite)){
      .etr_spn_fail("nonfinite_sparse_observation",
        "bandwidth selection requires finite observed sparse samples",
        list(curve_id=x$curve_ids[i],dimension=dimensions))
    }
  }
  grid<-.etr_spn_grid(cfg$evaluation_grid)
  action<-cfg$analysis_support_action
  .etr_assert(identical(action,"error")||identical(action,"restrict"),
    "analysis_support_action must be error or restrict")
  inside<-lapply(x$time,function(t)t>=grid[1L]&t<=tail(grid,1L))
  raw<-lengths(inside)
  effective<-vapply(inside,sum,integer(1L))
  if(action=="error"&&any(effective!=raw))
    .etr_spn_fail("observations_outside_analysis_support",
      "training/validation observations lie outside declared support",
      list(analysis_support=range(grid),curve_ids=x$curve_ids[effective!=raw]))
  limit<-options$predictive_condition_limit
  .etr_assert(is.numeric(limit)&&length(limit)==1L&&is.finite(limit)&&limit>1,
    "predictive_condition_limit must be finite and greater than one")
  failure_action<-options$failure_action
  .etr_assert(identical(failure_action,"retain")||identical(failure_action,"error"),
    "failure_action must be retain or error")
  folds<-.etr_sparse_cv_folds(x,options)
  k<-length(folds$validation)
  required<-options$min_valid_folds
  if(is.null(required))required<-k
  .etr_assert(is.numeric(required)&&length(required)==1L&&is.finite(required)&&
    required==floor(required)&&required>=1L&&required<=k,
    "min_valid_folds must be an integer from one to n_splits")

  common<-c("analysis_support_action","psd_action","psd_tolerance",
    "mean_min_local_points","covariance_min_local_pairs")
  if(paired){
    noise<-.etr_spnm_error(cfg$measurement_error,
      cfg$measurement_error_variance,cfg$measurement_error_covariance)$covariance
    fit_population<-function(train,mean_bw,cov_bw)do.call(.etr_spnm_population,
      c(list(trajectories=train,dimensions=dimensions,grid=grid,
        mean_bandwidth=mean_bw,covariance_bandwidth=cov_bw),cfg[common]))
  }else{
    noise<-NULL
    method<-cfg$noise_variance_method
    .etr_assert(identical(method,"fixed")||identical(method,"diagonal_difference"),
      "noise_variance_method must be fixed or diagonal_difference")
    if(method=="fixed"){
      .etr_assert(is.null(cfg$noise_bandwidth)&&is.null(cfg$noise_support)&&
        is.numeric(cfg$measurement_error_variance)&&length(cfg$measurement_error_variance)==1L&&
        is.finite(cfg$measurement_error_variance)&&cfg$measurement_error_variance>=0,
        "fixed-noise bandwidth selection requires a nonnegative measurement_error_variance")
    }else{
      .etr_assert(is.null(cfg$measurement_error_variance)&&!is.null(cfg$noise_support),
        "diagonal_difference requires noise_support and no fixed variance")
      bandwidth<-cfg$noise_bandwidth
      .etr_assert(is.numeric(bandwidth)&&length(bandwidth)==1L&&
        is.finite(bandwidth)&&bandwidth>0,"noise_bandwidth must be a positive scalar")
    }
    controls<-c(common,"noise_variance_method","measurement_error_variance",
      "noise_bandwidth","noise_support","noise_min_local_points",
      "positive_eigen_tolerance","mean_smoother","covariance_smoother","kernel")
    fit_population<-function(train,mean_bw,cov_bw)do.call(etr_fit_sparse_fpca_native,
      c(list(trajectories=train,dimension=dimensions,n_components=1L,
        evaluation_grid=grid,mean_bandwidth=mean_bw,covariance_bandwidth=cov_bw,
        score_failure_action="retain_nan"),cfg[controls]))
  }

  candidates<-data.frame(candidate_id=sprintf("candidate_%04d",seq_len(
    length(means)*length(covariances))-1L),
    mean_bandwidth=rep(means,each=length(covariances)),
    covariance_bandwidth=rep(covariances,length(means)),stringsAsFactors=FALSE)
  if(!paired)candidates$noise_bandwidth<-if(is.null(cfg$noise_bandwidth))NA_real_ else cfg$noise_bandwidth
  training_rows<-lapply(folds$validation,function(held)setdiff(seq_along(raw),held))
  training<-lapply(training_rows,function(rows).etr_sparse_cv_subset(x,rows))
  compare<-function(call)tryCatch(force(call),error=function(e){
    if(failure_action=="error")stop(e)
    e
  })
  failure<-function(value){
    if(!inherits(value,"error"))return(list(failure_code=NA_character_,failure_message=NA_character_))
    message<-conditionMessage(value)
    code<-if(inherits(value,"etr_sparse_native_error"))value$code else "ValueError"
    list(failure_code=code,failure_message=message)
  }
  criterion<-if(paired)"mean_curve_planar_gaussian_nll"else"mean_curve_gaussian_nll"
  median_name<-sub("^mean_","median_",criterion)
  fold_rows<-vector("list",nrow(candidates)*k)
  curve_rows<-vector("list",nrow(candidates)*length(raw))
  fold_cursor<-1L
  curve_cursor<-1L
  for(i in seq_len(nrow(candidates))){
    candidate<-as.list(candidates[i,,drop=FALSE])
    for(j in seq_len(k)){
      held<-folds$validation[[j]]
      train<-training_rows[[j]]
      fit<-compare(fit_population(training[[j]],candidate$mean_bandwidth,
        candidate$covariance_bandwidth))
      fit_failed<-inherits(fit,"error")
      counts<-c(sum(raw[train]),sum(raw[held]),sum(effective[train]),sum(effective[held]))
      count_names<-paste0(rep(c("n_train_","n_validation_"),2L),
        if(paired)"time_points_"else"observations_",rep(c("raw","effective"),each=2L))
      fold_row<-c(candidate["candidate_id"],list(fold=j-1L),
        candidate[setdiff(names(candidate),"candidate_id")],
        list(n_train_curves=length(train),n_validation_curves=length(held)),
        setNames(as.list(counts),count_names))
      if(paired)fold_row<-c(fold_row,setNames(as.list(2L*counts),
        sub("time_points","planar_observations",count_names,fixed=TRUE)))
      losses<-numeric()
      evaluated<-0L
      first_failure<-if(fit_failed)fit else NULL
      if(!fit_failed)for(index in held){
        mask<-inside[[index]]
        value<-compare({
          if(!any(mask)).etr_spn_fail("no_validation_observations_on_support",
            "held-out curve has no observations on declared support")
          .etr_sparse_cv_loss(fit,grid,x$time[[index]][mask],
            x$values[[index]][mask,columns,drop=FALSE],noise,limit)
        })
        failed<-inherits(value,"error")
        if(failed&&is.null(first_failure))first_failure<-value
        count<-if(failed)0L else effective[index]
        outside<-if(failed)NA_integer_ else raw[index]-count
        loss<-if(failed)NA_real_ else value$loss
        if(!failed){
          losses<-c(losses,loss)
          evaluated<-evaluated+count
        }
        curve_row<-c(list(candidate_id=candidate$candidate_id,fold=j-1L,
          curve_id=x$curve_ids[index],status_code=if(failed)"validation_failure"else"ok"),
          failure(value))
        curve_row<-c(curve_row,if(paired)list(
          planar_gaussian_nll_per_scalar_observation=loss,n_time_points_raw=raw[index],
          n_time_points_evaluated=count,n_planar_observations_evaluated=2L*count,
          outside_support_time_points=outside)else list(
          gaussian_nll_per_observation=loss,n_observations_raw=raw[index],
          n_evaluated_observations=count,outside_support_observations=outside))
        diagnostics<-c("predictive_condition_number","predictive_minimum_eigenvalue",
          "predictive_maximum_eigenvalue")
        curve_row<-c(curve_row,if(failed)setNames(as.list(rep(NA_real_,3L)),diagnostics)
          else value[diagnostics])
        if(paired)curve_row$observation_order<-"time_major_interleaved_xy"
        curve_rows[[curve_cursor]]<-as.data.frame(curve_row,stringsAsFactors=FALSE)
        curve_cursor<-curve_cursor+1L
      }
      ok<-is.null(first_failure)
      status<-if(fit_failed)"fit_failure"else if(ok)"ok"else"validation_failure"
      fold_row<-c(fold_row,list(status_code=status),failure(first_failure),
        setNames(list(if(ok)mean(losses)else NA_real_,
          if(ok)stats::median(losses)else NA_real_),c(criterion,median_name)),
        list(n_evaluated_curves=length(losses)))
      fold_row<-c(fold_row,if(paired)list(n_evaluated_time_points=evaluated,
        n_evaluated_planar_observations=2L*evaluated,
        psd_applied_action=if(fit_failed)NA_character_ else fit$operator$audit$applied_action,
        psd_relative_operator_correction=if(fit_failed)NA_real_ else
          fit$operator$audit$relative_operator_correction_frobenius_norm)
        else list(n_evaluated_observations=evaluated,
          fitted_noise_variance=if(fit_failed)NA_real_ else fit$noise_variance))
      fold_rows[[fold_cursor]]<-as.data.frame(fold_row,stringsAsFactors=FALSE)
      fold_cursor<-fold_cursor+1L
    }
  }
  fold_results<-do.call(rbind,fold_rows)
  curve_losses<-if(curve_cursor==1L)data.frame()else
    do.call(rbind,curve_rows[seq_len(curve_cursor-1L)])
  valid<-fold_results$status_code=="ok"
  by_candidate<-lapply(candidates$candidate_id,function(id)
    fold_results[[criterion]][valid&fold_results$candidate_id==id])
  n_valid<-lengths(by_candidate)
  summary<-cbind(candidates,data.frame(
    mean_loss=vapply(by_candidate,function(loss)if(length(loss))mean(loss)else NA_real_,numeric(1L)),
    sd_loss=vapply(by_candidate,function(loss)if(length(loss)>1L)stats::sd(loss)else 0,numeric(1L)),
    n_valid_folds=n_valid,n_failed_folds=k-n_valid,eligible=n_valid>=required))
  summary$se_loss<-ifelse(n_valid>0L,summary$sd_loss/sqrt(n_valid),NA_real_)
  summary<-summary[c(names(candidates),"mean_loss","sd_loss","se_loss",
    "n_valid_folds","n_failed_folds","eligible")]
  eligible<-which(summary$eligible&is.finite(summary$mean_loss))
  ranked<-eligible[order(summary$mean_loss[eligible],-summary$mean_bandwidth[eligible],
    -summary$covariance_bandwidth[eligible],summary$candidate_id[eligible])]
  selected<-if(length(ranked))as.list(candidates[ranked[1L],,drop=FALSE])else NULL
  if(!paired&&!is.null(selected))selected["noise_bandwidth"]<-list(cfg$noise_bandwidth)
  group_column<-if(options$resampling_unit=="group")options$group_column else NULL
  provenance<-.etr_sparse_cv_provenance(cfg,options,grid,noise,folds,criterion,
    paired,nrow(candidates),required,group_column)
  structure(list(assignments=folds$assignments,fold_results=fold_results,
    curve_losses=curve_losses,candidate_summary=summary,candidates=candidates,
    selected_bandwidths=selected,criterion=criterion,resampling_unit=options$resampling_unit,
    n_splits=k,group_column=group_column,min_valid_folds=as.integer(required),
    status_code=if(is.null(selected))"no_eligible_candidate"else"ok",
    provenance=provenance,parameters=options),class="etr_sparse_bandwidth_selection")
}

.etr_sparse_cv_provenance<-function(cfg,options,grid,noise,folds,criterion,
    paired,n_candidates,required,group_column){
  grouped<-options$resampling_unit=="group"
  shuffled<-!grouped&&isTRUE(options$shuffle)&&folds$policy!="declared_folds"
  common<-list(criterion=criterion,population_refit_inside_fold=TRUE,
    fold_policy=folds$policy,
    validation_observations_used_for_population_fitting=FALSE,
    full_fitted_covariance_used_for_validation=TRUE,
    score_ridge_included_in_validation_covariance=FALSE,
    resampling_unit=options$resampling_unit,group_column=group_column,
    group_leakage_prevented=grouped,n_splits=length(folds$validation),
    shuffle=shuffled,random_state=if(shuffled)options$random_state else NULL,
    min_valid_folds=as.integer(required),failure_action=options$failure_action,
    predictive_condition_limit=options$predictive_condition_limit,
    candidate_order="sorted_unique_mean_x_covariance_cartesian_product",
    selection_rule="minimum_mean_fold_loss",
    tie_break_rule=paste("minimum loss, then larger mean/covariance bandwidths",
      "lexicographically, then candidate_id"),
    one_se_rule_implemented=FALSE,
    one_se_reason=paste("no predeclared scalar simplicity ordering for a",
      "multidimensional bandwidth tuple"),
    automatic_fit_bandwidth_selection_performed=FALSE,
    evaluation_grid=as.numeric(grid),analysis_support_action=cfg$analysis_support_action,
    psd_action=cfg$psd_action,psd_tolerance=cfg$psd_tolerance,
    mean_min_local_points=as.integer(cfg$mean_min_local_points),
    covariance_min_local_pairs=as.integer(cfg$covariance_min_local_pairs),
    candidate_count=n_candidates,fold_assignment_count=nrow(folds$assignments),
    measurement_error_covariance=noise)
  if(grouped)common$group_count<-length(unique(folds$assignments$group))
  if(paired){
    c(common,list(method="group_aware_training_fold_sparse_planar_population_cv",
      criterion_formula=paste0("0.5*(logdet(Sigma_i)+r_i^T Sigma_i^-1 r_i+",
        "2*m_i*log(2*pi))/(2*m_i); fold mean weights held-out curves equally"),
      predictive_covariance="full_fitted_joint_covariance_plus_declared_measurement_error",
      joint_pace_scoring_performed=FALSE,
      validation_observations_used_for_score_fitting=FALSE,
      full_fitted_joint_covariance_used_for_validation=TRUE,
      rank_k_covariance_used_for_validation=FALSE,
      raw_sparse_trajectory_interpolation_performed=FALSE,
      score_observation_order="time_major_interleaved_xy",
      operator_storage_order="channel_major",
      measurement_error_mode=cfg$measurement_error,measurement_error_tuned=FALSE,
      measurement_error_policy="fixed_declared_across_candidates_and_folds",
      selected_values_must_be_passed_explicitly_to_fit_sparse_mfpca=TRUE,
      rank_tuned=FALSE,score_ridge_tuned=FALSE,evaluation_grid_tuned=FALSE,
      psd_policy_tuned=FALSE,support_policy_tuned=FALSE))
  }else{
    c(common,list(method="group_aware_training_fold_sparse_population_cv",
      criterion_formula=paste0("curve mean of 0.5*(logdet(Sigma_i)+r_i^T Sigma_i^-1 r_i+",
        "m_i*log(2*pi))/m_i; fold mean weights held-out curves equally"),
      validation_distribution=paste("Gaussian observation model from training-only",
        "fitted mean, full latent covariance, and measurement-error variance"),
      fit_inside_fold=TRUE,validation_observations_used_for_training=FALSE,
      validation_observations_used_for_pace_scoring=FALSE,
      noise_bandwidth_tuned=FALSE,
      noise_bandwidth_policy=if(is.null(cfg$noise_bandwidth))
        "not_applicable_fixed_measurement_error_variance" else
        "fixed_declared_across_candidates_and_folds",
      selected_values_must_be_passed_explicitly_to_fit_sparse_fpca=TRUE,
      noise_variance_method=cfg$noise_variance_method,noise_bandwidth=cfg$noise_bandwidth,
      noise_support=cfg$noise_support,measurement_error_variance=cfg$measurement_error_variance,
      positive_eigen_tolerance=cfg$positive_eigen_tolerance,mean_smoother=cfg$mean_smoother,
      covariance_smoother=cfg$covariance_smoother,kernel=cfg$kernel,
      noise_min_local_points=as.integer(cfg$noise_min_local_points),
      training_population_fit_n_components=1L,training_score_failure_action="retain_nan"))
  }
}

.etr_sparse_bandwidth_refit <- function(parameters,selection){
  if(is.null(selection))return(parameters)
  if(is.null(selection$selected_bandwidths))
    stop(structure(list(message="audited bandwidth selection produced no eligible candidate",
      call=NULL,bandwidth_selection=selection),
      class=c("etr_sparse_bandwidth_selection_error","error","condition")))
  bandwidths<-c("mean_bandwidth","covariance_bandwidth")
  parameters[bandwidths]<-selection$selected_bandwidths[bandwidths]
  parameters
}

.etr_sparse_bandwidth_report<-function(result){
  failed<-sum(result$fold_results$status_code!="ok")
  grouped<-result$resampling_unit=="group"
  selected<-result$selected_bandwidths
  if(result$criterion=="mean_curve_planar_gaussian_nll"){
    unit<-if(grouped)paste("groups from metadata column",
      .etr_python_workflow_identifier_repr(result$group_column))else"curves"
    selection<-if(is.null(selected))"No candidate met the declared valid-fold requirement."else{
      row<-match(selected$candidate_id,result$candidate_summary$candidate_id)
      sprintf(paste("The minimum eligible mean fold loss selected %s",
        "(mean bandwidth=%.3f, covariance bandwidth=%.3f, mean loss=%.3f)."),
        selected$candidate_id,selected$mean_bandwidth,selected$covariance_bandwidth,
        result$candidate_summary$mean_loss[row])
    }
    return(paste0("Sparse planar MFPCA bandwidth selection evaluated ",nrow(result$candidates),
      " declared mean/covariance candidate(s) using ",result$n_splits,
      "-fold cross-validation over ",unit,". Population mean and full joint latent ",
      "covariance surfaces were refitted from training curves only. Held-out curves ",
      "were scored by Gaussian negative log predictive density from the full fitted ",
      "joint covariance plus the fixed declared 2x2 measurement-error covariance, ",
      "normalised per scalar planar observation and then averaged equally across curves. ",
      "Joint-PACE scores were not used for selection. ",sum(result$candidate_summary$eligible),
      " candidate(s) were eligible and ",failed," candidate-fold failure(s) were retained. ",
      selection," Selected values are not applied automatically to fit_sparse_mfpca(); ",
      "they must be supplied explicitly."))
  }
  unit<-if(grouped)paste("grouped by",
    .etr_python_workflow_identifier_repr(result$group_column))else"at the curve level"
  prefix<-paste0("Sparse-FPCA mean/covariance bandwidths were evaluated using ",result$n_splits,
    "-fold cross-validation ",unit,". Population mean, covariance, and measurement-noise ",
    "objects were refitted using training curves only. The prespecified criterion was mean ",
    "held-out-curve Gaussian negative log predictive density, using the full fitted latent ",
    "covariance plus measurement-error variance; held-out observations were not used for ",
    "population fitting or PACE score estimation. The audit evaluated ",nrow(result$candidates),
    " bandwidth candidate(s) and retained ",failed," failed candidate-fold evaluation(s).")
  noise<-result$provenance$noise_bandwidth
  if(!is.null(noise))prefix<-paste0(prefix," The diagonal-difference noise bandwidth ",
    sprintf("%g",noise)," was declared in advance and held fixed rather than tuned by this criterion.")
  if(is.null(selected))return(paste0(prefix," No candidate satisfied the declared valid-fold requirement."))
  paste0(prefix," The minimum mean fold loss selected mean bandwidth ",sprintf("%g",selected$mean_bandwidth),
    " and covariance bandwidth ",sprintf("%g",selected$covariance_bandwidth),
    ". The selected numeric values were not applied automatically to the fitter.")
}

.etr_sparse_bandwidth_workflow <- function(workflow,selection_run){
  selection<-selection_run$result
  workflow["bandwidth_selection"]<-list(selection)
  workflow$provenance$bandwidth_mode<-if(is.null(selection))"fixed"else"audited_selector"
  if(is.null(selection))return(workflow)
  workflow$steps<-c(list(selection_run$step),workflow$steps)
  values<-selection$selected_bandwidths
  for(key in c("mean_bandwidth","covariance_bandwidth"))
    workflow$decisions[[key]]<-.etr_source_workflow_decision(
      values[[key]],"audited_selector",selection$criterion)
  workflow$tables$bandwidth_candidates<-selection$candidate_summary
  workflow$tables$bandwidth_curve_losses<-selection$curve_losses
  workflow$reports$bandwidth_selection<-.etr_sparse_bandwidth_report(selection)
  workflow
}
