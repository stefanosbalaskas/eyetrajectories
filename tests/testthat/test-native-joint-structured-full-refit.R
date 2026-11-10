# Author-side scientific scope: full Gaussian native nlme likelihood refits
# for serial, participant slope, nested trial and nested slope covariance
# structures. These are expensive and deliberately slow-gated: the regular
# test suite validates source-model dispatch, guardrails and source metadata.
# ET_RUN_SCIENTIFIC_SLOW=true enables 20 optimizer refits PER model family.
# Zero Python 1.2 full-domain certification is claimed.

.etr_structured_refit_synthetic<-function(kind,seed=411L){
  set.seed(seed)
  ng<-if(kind%in%c("nested_trial","nested_slope"))16L else 18L
  m<-3L;nt<-8L;nc<-ng*m
  t<-seq(0,1,length.out=nt)
  pid<-rep(sprintf("P%02d",seq_len(ng)),each=m)
  trial<-rep(sprintf("T%02d",seq_len(m)),times=ng)
  x<-rep(c(-1,0,1),times=ng)
  values<-array(NA_real_,c(nc,nt,1L))
  for(g in seq_len(ng)){
    ri<-rnorm(2L,sd=.21)
    rs<-rnorm(2L,sd=.12)
    for(j in seq_len(m)){
      i<-(g-1L)*m+j
      tr<-rnorm(2L,sd=.08)
      err<-rnorm(nt,sd=.085)
      for(k in 2:nt)err[k]<-.25*err[k-1L]+sqrt(1-.25^2)*err[k]
      values[i,,1L]<-.5+.17*t+x[i]*(.27-.08*t)+
        (1-t)*ri[1L]+t*ri[2L]+
        if(kind%in%c("slope","nested_slope"))
          x[i]*((1-t)*rs[1L]+t*rs[2L])else 0
      if(kind%in%c("nested_trial","nested_slope"))
        values[i,,1L]<-values[i,,1L]+
          (1-t)*tr[1L]+t*tr[2L]
      values[i,,1L]<-values[i,,1L]+err
    }
  }
  ids<-sprintf("c%03d",seq_len(nc))
  traj<-etr_trajectory_set(t,values,ids,"signal",
    metadata=data.frame(pid=pid,trial=trial),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  args<-list(trajectories=traj,design=design,
    predictors="x",participant_column="pid",dimension="signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE,maxiter=400L)
  fn<-switch(kind,
    serial=etr_fit_joint_bspline_functional_correlated,
    slope=etr_fit_joint_bspline_functional_random_slope,
    nested_trial=etr_fit_joint_bspline_functional_nested_trial,
    nested_slope=etr_fit_joint_bspline_functional_nested_slope)
  if(kind%in%c("nested_trial","nested_slope")){
    args$trial_column<-"trial"
    args$trial_random_basis_size<-2L
  }
  if(kind%in%c("slope","nested_slope"))
    args$random_slope_predictor<-"x"
  if(kind%in%c("serial","nested_trial","nested_slope"))
    args$residual_correlation<-"ar1"
  do.call(fn,args)
}

test_that("all four structured likelihood families dispatch without silent moments fallback",{
  for(k in c("serial","slope","nested_trial","nested_slope")){
    cl<-switch(k,serial="etr_joint_bspline_mixed_correlated",
      slope="etr_joint_bspline_mixed_slope",
      nested_trial="etr_joint_bspline_mixed_nested_trial",
      nested_slope="etr_joint_bspline_mixed_nested_slope")
    object<-structure(list(),class=c(cl,"etr_joint_bspline_mixed"))
    expect_identical(.etr_joint_structured_refit_kind(object),k)
    expect_error(.etr_joint_structured_full_refit_bootstrap(object,
      n_bootstrap=20L),"converged joint nlme")
  }
  expect_error(.etr_joint_structured_refit_kind(
    structure(list(),class="etr_joint_bspline_mixed")),
    "supported joint likelihood subclass")
})

test_that("structured full likelihood resamples whole participants and refits covariance",{
  if(!identical(Sys.getenv("ET_RUN_SCIENTIFIC_SLOW"),"true"))
    skip("set ET_RUN_SCIENTIFIC_SLOW=true for four 20-replicate actual likelihood refits")
  skip_if_not_installed("nlme")
  for(kind in c("serial","slope","nested_trial","nested_slope")){
    reference<-.etr_structured_refit_synthetic(kind)
    expect_identical(reference$coordinate_system,"degrees")
    expect_identical(reference$maxiter,400L)
    expect_identical(.etr_joint_structured_refit_kind(reference),kind)
    n<-length(reference$participant_ids)
    selected<-matrix(rep(seq_len(n)-1L,times=20L),
      nrow=20L,byrow=TRUE)
    set.seed(4321L)
    state<-.Random.seed
    out<-etr_bootstrap_functional_mixed_effects_full_refit(
      reference,n_bootstrap=20L,random_state=21L,
      sampled_participant_indices=selected)
    expect_identical(state,.Random.seed,
      info=paste(kind,"retained R RNG state"))
    expect_s3_class(out,"etr_joint_mixed_structured_full_refit_bootstrap")
    expect_identical(out$bootstrap_type,"full_refit")
    expect_identical(dim(out$bootstrap_fixed_basis_coefficients),
      c(20L,2L,2L))
    expect_identical(dim(out$bootstrap_coefficient_functions),
      c(20L,2L,8L))
    expect_identical(dim(out$random_effect_covariances),
      c(20L,if(kind%in%c("slope","nested_slope"))4L else 2L,
        if(kind%in%c("slope","nested_slope"))4L else 2L))
    expect_true(all(out$convergence_flags))
    expect_true(all(is.finite(out$residual_variances)))
    expect_true(all(out$residual_variances>0))
    expect_equal(out$bootstrap_coefficient_functions[1L,,],
      reference$fixed_coefficient_functions,
      tolerance=5e-3,ignore_attr=TRUE,
      info=paste(kind,"full-participant identity refit coefficients"))
    expect_equal(out$residual_variances[1L],
      reference$residual_variance,tolerance=5e-3,
      info=paste(kind,"identity-refit residual variance"))
    if(kind%in%c("nested_trial","nested_slope")){
      expect_identical(dim(out$trial_random_effect_covariances),
        c(20L,2L,2L))
      expect_equal(nrow(out$bootstrap_trial_audit[[1L]]),
        nrow(reference$observed_functions))
      expect_false(anyDuplicated(
        out$bootstrap_trial_audit[[1L]]$bootstrap_trial_id)>0L)
    }else{
      expect_null(out$trial_random_effect_covariances)
    }
    if(kind%in%c("slope","nested_slope")){
      expect_identical(dim(out$random_slope_covariances),
        c(20L,2L,2L))
    }else expect_null(out$random_slope_covariances)
    if(kind!="slope"){
      expect_identical(length(out$residual_correlation_parameters),20L)
      expect_true(all(is.finite(
        out$residual_correlation_parameters)))
    }else expect_null(out$residual_correlation_parameters)
    expect_false(out$independent_full_source_certified)
    expect_false(out$source_python_full_contract_certified)
    expect_error(etr_bootstrap_functional_mixed_effects_full_refit(
      reference,n_bootstrap=19L),"n_bootstrap")
  }
})
