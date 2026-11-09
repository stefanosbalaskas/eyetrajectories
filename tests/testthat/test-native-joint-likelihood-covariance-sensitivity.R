# Reuse a previously convergent deterministic 8-participant Gaussian
# fixture in all sensitivity tests. A six-participant, nearly noiseless
# moments fixture is numerically singular for the full spline REML model.
.etr_joint_sensitivity_stable_fixture<-function(){
  time<-seq(0,1,length.out=7L)
  ids<-sprintf("curve%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  x<-rep(c(-1,0,1),8L)
  values<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    values[i,,1L]<-.7+.23*time+x[i]*(.25-.15*time)+
      .18*sin(g*.6)+.13*cos(g*.31)*time+
      .06*sin(i*.7+time*4)+.035*cos(1.5*i*time)
  }
  trajectories<-etr_trajectory_set(time,values,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  list(tr=trajectories,design=design)
}

# Source: pinned Python 1.2 covariance sensitivity numerical definitions.
# Actual native nlme joint Gaussian likelihood; no Python parity certification.

test_that("joint mixed sensitivity uses actual REML likelihood and source IC counts",{
  skip_if_not_installed("nlme")
  f<-.etr_joint_sensitivity_stable_fixture()
  fit<-etr_fit_joint_bspline_functional_mixed_effects(
    f$tr,f$design,"x","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE)
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit,replica=fit),reference="reference",max_lag=2L)
  expect_s3_class(z,"etr_joint_likelihood_covariance_sensitivity")
  expect_true(z$information_criterion_available)
  expect_false(z$model_selected)
  expect_false(z$likelihood_ratio_tests_performed)
  expect_false(z$independent_full_source_certified)
  expect_identical(nrow(z$model_summary),2L)
  expect_equal(z$model_summary$log_likelihood,
    rep(as.numeric(stats::logLik(fit$fitted_model)),2L))
  # p=2 coefficient functions, k=2 fixed basis, G=2x2 unstructured,
  # sigma^2=1: four covariance parameters; REML uses only those in IC.
  expect_equal(z$model_summary$n_fixed_parameters,c(4L,4L))
  expect_equal(z$model_summary$n_covariance_parameters,c(4L,4L))
  expect_equal(z$model_summary$information_criterion_parameter_count,
    c(4L,4L))
  expect_equal(z$model_summary$delta_aic,c(0,0),tolerance=1e-12)
  expect_equal(z$model_summary$delta_bic,c(0,0),tolerance=1e-12)
  expect_equal(z$coefficient_summary$sup_abs_difference_from_reference,
    rep(0,4),tolerance=0)
  expect_equal(nrow(z$variance_decomposition),2L*2L*7L)
  expect_equal(nrow(z$residual_diagnostics),2L*2L*3L)
  expect_equal(
    z$variance_decomposition$value[
      z$variance_decomposition$component=="residual_variance"],
    rep(fit$residual_variance,14L),tolerance=1e-12)
})

test_that("joint sensitivity validates source comparability and rejects mixed estimators",{
  skip_if_not_installed("nlme")
  f<-.etr_joint_sensitivity_stable_fixture()
  fit<-etr_fit_joint_bspline_functional_mixed_effects(
    f$tr,f$design,"x","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE)
  run<-function(other)etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit,other=other),"reference",2L)
  altered<-fit
  altered$observed_functions[1L,1L]<-
    altered$observed_functions[1L,1L]+.1
  expect_error(run(altered),"identical observed_functions")
  altered<-fit;altered$reml<-FALSE
  expect_error(run(altered),"identical reml")
  altered<-fit;altered$fixed_basis[1L,1L]<-.5
  expect_error(run(altered),"identical fixed_basis")
  # Only the S3 estimator distinction is under test here; avoid an
  # unnecessary second scientific fit for a rejected input type.
  moment<-structure(list(),class="etr_functional_mixed_moments")
  expect_error(run(moment),"cannot combine moments and joint")
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit),"reference",2L,
    failures=list(rejected="failed convergence"),
    specifications=list(
      reference=list(random_slope_predictor=NULL,
        trial_random_effect=NULL,residual_correlation="iid"),
      rejected=list(random_slope_predictor="x",
        trial_random_effect=NULL,residual_correlation="iid")))
  expect_identical(z$model_summary$status,c("success","failed"))
  expect_true(is.na(z$model_summary$aic[2L]))
  expect_identical(nrow(z$coefficient_frame),2L*length(fit$time))
})

test_that("joint serial fit retains source-comparable time and likelihood fields",{
  skip_if_not_installed("nlme")
  # A separate slow scientific qualification fixture; ordinary fast waves
  # avoid repeatedly optimizing both covariance structures.
  if(!identical(Sys.getenv("ET_RUN_SCIENTIFIC_SLOW"),"true"))
    skip("set ET_RUN_SCIENTIFIC_SLOW=true for joint iid-vs-AR1 numerical model comparison")
  set.seed(72019L)
  tt<-seq(0,1,length.out=8L)
  ng<-18L;nc<-ng*3L
  ids<-sprintf("curve%03d",seq_len(nc))
  pid<-rep(sprintf("P%02d",seq_len(ng)),each=3L)
  x<-rep(c(-1,0,1),ng)
  y<-array(0,c(nc,length(tt),1L))
  for(g in seq_len(ng))for(j in seq_len(3L)){
    i<-(g-1L)*3L+j
    eta<-.6+.2*tt+x[i]*(.4-.1*tt)+
      .22*sin(g*.53)+.16*cos(g*.71)*tt
    e<-numeric(length(tt))
    for(k in seq_along(tt))
      e[k]<-if(k==1L)rnorm(1L,sd=.07) else
        .45*e[k-1L]+rnorm(1L,sd=.055)
    y[i,,1L]<-eta+e
  }
  trajectories<-etr_trajectory_set(tt,y,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="seconds")
  design<-data.frame(curve_id=rev(ids),condition=rev(x))
  iid<-etr_fit_joint_bspline_functional_mixed_effects(
    trajectories,design,"condition","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE)
  ar1<-etr_fit_joint_bspline_functional_correlated(
    trajectories,design,"condition","pid","signal",
    residual_correlation="ar1",fixed_basis_size=2L,
    random_basis_size=2L,spline_degree=1L,reml=TRUE)
  expect_identical(ar1$time_unit,"seconds")
  expect_identical(ar1$dimension_name,"signal")
  expect_identical(ar1$source_curve_ids,ids)
  expect_equal(ar1$log_likelihood,
    as.numeric(stats::logLik(ar1$fitted_model)),tolerance=1e-12)
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    list(iid=iid,serial=ar1),reference="iid",max_lag=2L)
  expect_true(z$information_criterion_available)
  expect_identical(z$model_summary$residual_correlation,c("iid","ar1"))
  expect_equal(z$model_summary$n_covariance_parameters,c(4L,5L))
  expect_true(all(is.finite(z$model_summary$aic)))
  expect_equal(nrow(z$coefficient_frame),4L*length(tt))
  expect_equal(nrow(z$residual_diagnostics),2L*2L*3L)
})

test_that("joint residual dependence uses frozen within-curve centred lag law",{
  # Hand-computable source oracle with one constant residual trial:
  # Python retains it in pair counts, but excludes its undefined ACF.
  r<-rbind(c(1,2,3,4,5),c(2,3,4,3,2),rep(3,5))
  x<-list(time=c(0,.2,.5,1,1.8),
    time_unit="s",residual_functions=r,
    residual_correlation_matrix=diag(5L),residual_variance=1.5)
  frame<-.etr_joint_sensitivity_diagnostics(x,"source",max_lag=2L)
  raw<-frame[frame$residual_scale=="raw",,drop=FALSE]
  white<-frame[frame$residual_scale=="whitened",,drop=FALSE]
  expect_identical(raw$n_pairs,c(15L,12L,9L))
  expect_identical(raw$n_trials_total,c(3L,3L,3L))
  expect_identical(raw$n_trials_acf_defined,c(2L,2L,2L))
  expect_equal(raw$autocorrelation[1L],1,tolerance=1e-12)
  # For lag 1: first centred trial covariance=1, variance=2, ACF=.5;
  # second covariance=.04, variance=.56, ACF=1/14.
  expect_equal(raw$autocorrelation[2L],(.5+1/14)/2,
    tolerance=1e-12)
  expect_equal(raw$autocovariance[2L],(1+.04+0)/3,
    tolerance=1e-12)
  expect_equal(raw$trial_autocorrelation_min[2L],1/14,
    tolerance=1e-12)
  expect_equal(raw$trial_autocorrelation_max[2L],.5,
    tolerance=1e-12)
  expect_equal(raw$lag_time_mean[2L],
    mean(diff(x$time)),tolerance=1e-12)
  expect_equal(raw$lag_time_min[2L],min(diff(x$time)),
    tolerance=1e-12)
  expect_equal(raw$lag_time_max[2L],max(diff(x$time)),
    tolerance=1e-12)
  # Covariances scale under whitening but ACF (ratio) does not.
  expect_equal(white$autocorrelation,raw$autocorrelation,
    tolerance=1e-12)
  expect_equal(white$autocovariance,
    raw$autocovariance/1.5,tolerance=1e-12)
  expect_equal(white$residual_rms_global[1L],
    sqrt(mean(r^2)/1.5),tolerance=1e-12)
  expect_true(all(raw$semivariance>=0))
})
test_that("frozen numpy source within-curve autocorrelation agrees with native implementation",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("opt-in frozen Python mixed residual numerical source oracle")
  x<-list(time=c(0,.2,.5,1,1.8),
    time_unit="s",
    residual_functions=rbind(c(1,2,3,4,5),c(2,3,4,3,2),rep(3,5)),
    residual_correlation_matrix=diag(5L),residual_variance=1.5)
  native<-.etr_joint_sensitivity_diagnostics(x,"numpy",max_lag=2L)
  reticulate::py_run_string("
import numpy as np
_r=np.array([[1.,2.,3.,4.,5.],[2.,3.,4.,3.,2.],[3.,3.,3.,3.,3.]])
_out=[]
for _scale,_values in (('raw',_r),('whitened',_r/np.sqrt(1.5))):
  for _lag in range(3):
    _cov=[];_acf=[];_semi=[]
    for _row in _values:
      _center=_row-_row.mean()
      _v=np.mean(_center*_center)
      _c=float(np.mean(_center[:5-_lag]*_center[_lag:]))
      _cov.append(_c)
      _acf.append(_c/_v if _v>0 else np.nan)
      _semi.append(.5*np.mean((_row[_lag:]-_row[:5-_lag])**2))
    _acf=np.asarray(_acf,dtype=float)
    _out.append((_scale,_lag,
       float(np.mean(_cov)),float(np.nanmean(_acf)),
       float(np.mean(_semi)),int(np.isfinite(_acf).sum())))
_numpy_mixed_diagnostic_oracle=_out
")
  source<-reticulate::py_eval("_numpy_mixed_diagnostic_oracle",
    convert=TRUE)
  expected<-do.call(rbind,lapply(source,function(row)
    c(as.numeric(row[[3L]]),as.numeric(row[[4L]]),
      as.numeric(row[[5L]]),as.numeric(row[[6L]]))))
  observed<-as.matrix(native[,c("autocovariance",
    "autocorrelation","semivariance","n_trials_acf_defined")])
  expect_equal(unname(observed),unname(expected),tolerance=1e-12)
})
