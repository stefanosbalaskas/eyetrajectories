# Published eyetrajectoriespy 1.2 regression_inference.py, Gaussian FPCR.
.etr_fpcr_uncertainty_fixture<-function(){
  n<-14L;t<-seq(0,1,length.out=15L)
  values<-array(0,c(n,length(t),1L))
  for(i in seq_len(n))
    values[i,,1L]<-sin(pi*t)*(1+i/16)+
      .16*cos(2*pi*t)*(i%%4)/3+t*i/18
  x<-etr_trajectory_set(t,values,sprintf("c%02d",seq_len(n)),
    "gaze",metadata=data.frame(subject=rep(sprintf("p%02d",1:7),each=2)),
    coordinate_system="normalized",time_unit="s")
  list(x=x,y=.2+1.2*seq_len(n)/n+.2*sin(seq_len(n)))
}
test_that("paired full-refit Gaussian FPCR quantiles and provenance are coherent",{
  z<-.etr_fpcr_uncertainty_fixture()
  set.seed(602L);before<-.Random.seed
  a<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,random_state=123L)
  expect_identical(before,.Random.seed)
  expect_s3_class(a,"etr_fpcr_bootstrap_uncertainty")
  expect_identical(dim(a$bootstrap_slopes),c(20L,15L,1L))
  expect_identical(dim(a$bootstrap_mean_predictions),c(20L,14L))
  expect_identical(dim(a$reference_slope),c(15L,1L))
  expect_equal(a$reference_mean_predictions,
    as.numeric(stats::fitted(a$reference_regression$native_model$model)),
    tolerance=1e-10)
  expect_equal(a$slope_lower[,1L],
    as.numeric(apply(a$bootstrap_slopes[,,1L],2,
      quantile,probs=.025,names=FALSE,type=7L)),
    tolerance=1e-10)
  expect_equal(a$prediction_se,
    apply(a$bootstrap_mean_predictions,2L,stats::sd),
    tolerance=1e-12)
  expect_true(all(a$slope_lower<=a$slope_median))
  expect_true(all(a$slope_median<=a$slope_upper))
  expect_true(all(a$prediction_lower<=a$prediction_upper))
  expect_false(a$provenance$fpca_regression_uncertainty$
    future_outcome_prediction_interval)
  expect_false(a$provenance$fpca_regression_uncertainty$
    source_schema_equivalent)
  expected<-etr_fpca_regression_future_prediction_interval(
    a,z$y,residual_indices=matrix(
      rep(0:13,length.out=20L*14L),nrow=20L))
  expect_identical(dim(expected$predictive_draws),c(20L,14L))
  again<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,random_state=123L)
  expect_identical(a$bootstrap_mean_predictions,
    again$bootstrap_mean_predictions)
})

test_that("fixed zero-based source curves replay deterministically",{
  z<-.etr_fpcr_uncertainty_fixture()
  indexes<-replicate(20L,as.integer(c(0:13)),simplify=FALSE)
  r<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,
    bootstrap_indices=indexes,random_state=91L)
  expect_equal(matrix(r$bootstrap_slopes[1,,,drop=FALSE],
    nrow=length(z$x$time),ncol=length(z$x$dimension_names)),
    r$reference_slope,tolerance=1e-8)
  expect_true(all(r$sampled_source_curve_indices[[1L]]==0:13))
  expect_identical(r$provenance$fpca_regression_uncertainty$
    random_engine,"externally_fixed_source_curve_indices")
})

test_that("FPCR paired bootstrap rejects unsupported scientific domains",{
  z<-.etr_fpcr_uncertainty_fixture()
  f<-etr_bootstrap_fpca_regression_uncertainty
  expect_error(f(z$x,z$y,n_bootstrap=19L),"n_bootstrap")
  expect_error(f(z$x,z$y,n_components=0L),"n_components")
  expect_error(f(z$x,z$y,n_components=1.5),"n_components")
  expect_error(f(z$x,z$y[-1L]),"outcome")
  expect_error(f(z$x,z$y,level=1),"level")
  expect_error(f(z$x,z$y,resample_unit="participant"),
    "participant_column")
  expect_error(f(z$x,z$y,resample_unit="curve",
    participant_column="subject"),"participant_column")
  expect_error(f(z$x,z$y,bootstrap_indices=list(0:13),
    n_bootstrap=20L),"bootstrap_indices")
  bad<-z$x;bad$time[2L]<-.07
  expect_error(f(z$x,z$y,targets=bad),"targets")
})

test_that("published Python 1.2 Gaussian FPCR agrees on the full-sample estimand",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 paired Gaussian FPCR reference oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_uncertainty_fixture()
  native<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,random_state=7L)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
n=14
time=np.linspace(0.0,1.0,15)
x=np.empty((n,time.size,1))
for ind in range(1,n+1):
 x[ind-1,:,0]=(np.sin(np.pi*time)*(1+ind/16)
                +.16*np.cos(2*np.pi*time)*(ind%4)/3
                +time*ind/18)
y=.2+1.2*np.arange(1,n+1)/n+.2*np.sin(np.arange(1,n+1))
tr=et.TrajectorySet(time=time,values=x,
    curve_ids=tuple(f'c{ind:02d}' for ind in range(1,n+1)),
    dimension_names=('gaze',),
    metadata=pd.DataFrame({'subject':np.repeat(
        [f'p{j:02d}' for j in range(1,8)],2)}),
    coordinate_system='normalized',time_unit='s')
original=et.bootstrap_fpca_regression_uncertainty(
    tr,y,n_bootstrap=20,n_components=1,random_state=7)
_fpcr_published_reference={
    'slope':original.reference_slope,
    'mean':original.reference_mean_predictions,
    'fitted':original.reference_regression.predictions,
    'shape':original.bootstrap_slopes.shape
}
")
  # Repeat frozen Python public source uncertainty bootstrap using its
  # own fixed NumPy seed, preserving separate native R RNG assumptions.
  direct<-reticulate::py_call(
    etpy_get_export("bootstrap_fpca_regression_uncertainty"),
    trajectories=reticulate::py_eval("tr",convert=FALSE),
    outcome=reticulate::py_eval("y",convert=FALSE),
    n_bootstrap=20L,n_components=1L,random_state=7L)
  source_fit<-reticulate::py_eval("original",convert=FALSE)
  for(field in c("reference_slope","reference_mean_predictions",
    "bootstrap_slopes","bootstrap_mean_predictions")){
    replay<-et_to_r(reticulate::py_get_attr(direct,field))
    original<-et_to_r(reticulate::py_get_attr(source_fit,field))
    expect_equal(replay,original,tolerance=1e-12,
      ignore_attr=TRUE,info=paste("replayed source FPCR refit",field))
  }
  for(unit in c("curve","participant")){
    group<-if(unit=="participant")"subject"else NULL
    seeded<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
      n_bootstrap=20L,n_components=1L,random_state=7L,
      resample_unit=unit,participant_column=group)
    source_seeded<-reticulate::py_call(
      etpy_get_export("bootstrap_fpca_regression_uncertainty"),
      trajectories=reticulate::py_eval("tr",convert=FALSE),
      outcome=reticulate::py_eval("y",convert=FALSE),
      n_bootstrap=20L,n_components=1L,random_state=7L,
      resample_unit=unit,participant_column=group)
    for(field in c("bootstrap_slopes","bootstrap_mean_predictions"))
      expect_equal(seeded[[field]],
        et_to_r(reticulate::py_get_attr(source_seeded,field)),
        tolerance=1e-6,ignore_attr=TRUE,info=paste(unit,field))
  }
  oracle<-reticulate::py_to_r(reticulate::py_eval(
    "_fpcr_published_reference",convert=FALSE))
  expect_equal(unname(native$reference_slope),unname(oracle$slope),
    tolerance=1e-6)
  expect_equal(as.numeric(native$reference_mean_predictions),
    as.numeric(oracle$mean),tolerance=1e-6)
  expect_equal(as.numeric(native$reference_regression$predictions),
    as.numeric(oracle$fitted),tolerance=1e-6)
  expect_identical(as.integer(dim(native$bootstrap_slopes)),
    as.integer(oracle$shape))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("pinned Python 1.2 full paired-bootstrap refits match fixed source indices",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 20-replicate fixed-draw FPCR source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_uncertainty_fixture()
  indices<-replicate(20L,as.integer(0:13),simplify=FALSE)
  native<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,random_state=7L,
    bootstrap_indices=indices)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from unittest.mock import patch
import eyetrajectoriespy as et
import eyetrajectoriespy.regression_inference as ri
time=np.linspace(0.0,1.0,15)
n=14
values=np.empty((n,15,1))
for j in range(1,15):
 values[j-1,:,0]=(np.sin(np.pi*time)*(1+j/16)
     +.16*np.cos(2*np.pi*time)*(j%4)/3+time*j/18)
y=.2+1.2*np.arange(1,15)/14+.2*np.sin(np.arange(1,15))
x=et.TrajectorySet(time=time,values=values,
 curve_ids=tuple(f'c{j:02d}' for j in range(1,15)),
 dimension_names=('gaze',),
 metadata=pd.DataFrame({'subject':np.repeat(
     [f'p{j:02d}' for j in range(1,8)],2)}),
 coordinate_system='normalized',time_unit='s')
class _FixedBootstrapRNG:
 def integers(self,low,high=None,size=None):
  assert low==0 and high==14 and size==14
  return np.arange(14,dtype=int)
with patch.object(ri.np.random,'default_rng',
                  return_value=_FixedBootstrapRNG()):
 exact=ri.bootstrap_fpca_regression_uncertainty(
     x,y,n_bootstrap=20,n_components=1,random_state=7)
_python_fpcr_fixed={
 'bootstrap_slopes':exact.bootstrap_slopes,
 'bootstrap_mean_predictions':exact.bootstrap_mean_predictions,
 'slope_lower':exact.slope_lower,
 'slope_upper':exact.slope_upper,
 'prediction_lower':exact.prediction_lower,
 'prediction_upper':exact.prediction_upper
}
")
  source<-reticulate::py_to_r(reticulate::py_eval(
    "_python_fpcr_fixed",convert=FALSE))
  expect_equal(unname(native$bootstrap_slopes),
    unname(source$bootstrap_slopes),tolerance=1e-6)
  expect_equal(unname(native$bootstrap_mean_predictions),
    unname(source$bootstrap_mean_predictions),tolerance=1e-6)
  expect_equal(unname(native$slope_lower),
    unname(source$slope_lower),tolerance=1e-6)
  expect_equal(unname(native$slope_upper),
    unname(source$slope_upper),tolerance=1e-6)
  expect_equal(as.numeric(native$prediction_lower),
    as.numeric(source$prediction_lower),tolerance=1e-6)
  expect_equal(as.numeric(native$prediction_upper),
    as.numeric(source$prediction_upper),tolerance=1e-6)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("fixed unequal-size whole-participant FPCR resamples preserve the sampling unit",{
  z<-.etr_fpcr_uncertainty_fixture()
  # Seven participants, with unequal 3,1,2,3,1,2,2 curve memberships.
  memberships<-rep(sprintf("p%02d",1:7),times=c(3L,1L,2L,3L,1L,2L,2L))
  z$x$metadata$subject<-memberships
  groups<-lapply(unique(memberships),function(id)
    as.integer(which(memberships==id)-1L))
  units<-lapply(seq_len(20L),function(i)
    if(i%%2L==1L)c(1L,1L,2L,3L,4L,5L,6L) else
      c(7L,6L,5L,4L,3L,2L,2L))
  draws<-lapply(units,function(u)
    as.integer(unlist(groups[u],use.names=FALSE)))
  set.seed(715L);before<-.Random.seed
  result<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,
    resample_unit="participant",participant_column="subject",
    random_state=7L,bootstrap_indices=draws)
  expect_identical(.Random.seed,before)
  expect_identical(result$sampled_source_curve_indices,draws)
  expect_identical(dim(result$bootstrap_slopes),c(20L,15L,1L))
  expect_equal(result$slope_lower[,1L],
    as.numeric(apply(result$bootstrap_slopes[,,1L],2L,
      stats::quantile,probs=.025,names=FALSE,type=7L)),tolerance=1e-10)
  expect_identical(result$provenance$fpca_regression_uncertainty$
    random_engine,"externally_fixed_source_participant_indices")
  broken<-draws
  broken[[1L]]<-broken[[1L]][-1L]
  expect_error(etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,
    resample_unit="participant",participant_column="subject",
    bootstrap_indices=broken),"whole-participant")
  broken<-draws
  broken[[1L]]<-c(broken[[1L]][-1L],broken[[1L]][1L])
  expect_error(etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,
    resample_unit="participant",participant_column="subject",
    bootstrap_indices=broken),"whole-participant")
})

test_that("pinned Python 1.2 full participant FPCR bootstrap numerics match fixed whole-group draws",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 participant FPCR fixed-draw oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_uncertainty_fixture()
  # Repeated participant units, source zero-based group indices. Different
  # orderings are deliberately included to test the paired slope refit.
  units<-lapply(seq_len(20L),function(i){
    if(i%%3L==1L)c(0L,1L,1L,2L,3L,4L,5L) else
      if(i%%3L==2L)c(6L,5L,4L,3L,2L,2L,1L) else
        c(0L,2L,3L,4L,5L,6L,6L)
  })
  draws<-lapply(units,function(u)
    as.integer(unlist(lapply(u,function(p)c(2L*p,2L*p+1L)),
      use.names=FALSE)))
  native<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,
    resample_unit="participant",participant_column="subject",
    random_state=23L,bootstrap_indices=draws)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from unittest.mock import patch
import eyetrajectoriespy as et
import eyetrajectoriespy.regression_inference as ri
time=np.linspace(0.0,1.0,15)
n=14
values=np.empty((n,15,1))
for j in range(1,15):
 values[j-1,:,0]=(np.sin(np.pi*time)*(1+j/16)
     +.16*np.cos(2*np.pi*time)*(j%4)/3+time*j/18)
y=.2+1.2*np.arange(1,15)/14+.2*np.sin(np.arange(1,15))
x=et.TrajectorySet(time=time,values=values,
 curve_ids=tuple(f'c{j:02d}' for j in range(1,15)),
 dimension_names=('gaze',),
 metadata=pd.DataFrame({'subject':np.repeat(
     [f'p{j:02d}' for j in range(1,8)],2)}),
 coordinate_system='normalized',time_unit='s')
_units=[([0,1,1,2,3,4,5] if b%3==0 else
         [6,5,4,3,2,2,1] if b%3==1 else
         [0,2,3,4,5,6,6]) for b in range(20)]
_rows=[np.array([2*u+d for u in group for d in (0,1)],dtype=int)
       for group in _units]
assert any(len(set(v))<len(v) for v in _units)
_iterator=iter(_rows)
def _fixed_participant_indices(*args,**kwargs):
 return next(_iterator)
with patch.object(ri,'_participant_bootstrap_indices',
                  side_effect=_fixed_participant_indices):
 exact=ri.bootstrap_fpca_regression_uncertainty(
     x,y,n_bootstrap=20,n_components=1,
     resample_unit='participant',participant_column='subject',random_state=23)
_python_fpcr_participant_fixed={
 'bootstrap_slopes':exact.bootstrap_slopes,
 'bootstrap_mean_predictions':exact.bootstrap_mean_predictions,
 'bootstrap_intercepts':exact.bootstrap_intercepts,
 'slope_lower':exact.slope_lower,
 'slope_median':exact.slope_median,
 'slope_upper':exact.slope_upper,
 'slope_se':exact.slope_se,
 'prediction_lower':exact.prediction_lower,
 'prediction_median':exact.prediction_median,
 'prediction_upper':exact.prediction_upper,
 'prediction_se':exact.prediction_se
}
")
  source<-reticulate::py_to_r(reticulate::py_eval(
    "_python_fpcr_participant_fixed",convert=FALSE))
  expect_equal(unname(native$bootstrap_slopes),
    unname(source$bootstrap_slopes),tolerance=1e-6)
  expect_equal(unname(native$bootstrap_mean_predictions),
    unname(source$bootstrap_mean_predictions),tolerance=1e-6)
  expect_equal(as.numeric(native$bootstrap_intercepts),
    as.numeric(source$bootstrap_intercepts),tolerance=1e-6)
  for(field in c("slope_lower","slope_median","slope_upper","slope_se"))
    expect_equal(unname(native[[field]]),unname(source[[field]]),
      tolerance=1e-6,info=paste("participant FPCR",field))
  for(field in c("prediction_lower","prediction_median",
      "prediction_upper","prediction_se"))
    expect_equal(as.numeric(native[[field]]),as.numeric(source[[field]]),
      tolerance=1e-6,info=paste("participant FPCR",field))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("end-to-end FPCR bootstrap-prediction-slope source pipeline replays fixed participants and external targets",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("full frozen Python 1.2 FPCR pipeline oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_uncertainty_fixture()
  chosen<-c(2L,7L,13L)
  external<-etr_trajectory_set(z$x$time,
    z$x$values[chosen,,,drop=FALSE]+.025,
    curve_ids=c("e02","e07","e13"),
    dimension_names=z$x$dimension_names,
    metadata=z$x$metadata[chosen,,drop=FALSE],
    coordinate_system=z$x$coordinate_system,
    time_unit=z$x$time_unit)
  units<-lapply(0:19,function(i){
    if(i%%3L==0L)c(0L,1L,1L,2L,3L,4L,5L) else
      if(i%%3L==1L)c(6L,5L,4L,3L,2L,2L,1L) else
        c(0L,2L,3L,4L,5L,6L,6L)
  })
  indices<-lapply(units,function(u)
    as.integer(unlist(lapply(u,function(p)c(2L*p,2L*p+1L)),
      use.names=FALSE)))
  local_boot<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,targets=external,n_bootstrap=20L,n_components=1L,
    resample_unit="participant",participant_column="subject",
    level=.9,random_state=23L,bootstrap_indices=indices)
  expect_identical(local_boot$target_source,"external")
  expect_identical(local_boot$target_curve_ids,c("e02","e07","e13"))
  expect_identical(dim(local_boot$bootstrap_mean_predictions),c(20L,3L))
  reticulate::py_run_string("

import numpy as np
import pandas as pd
from unittest.mock import patch
import eyetrajectoriespy as et
import eyetrajectoriespy.regression_inference as ri
_f15_n=14
_f15_time=np.linspace(0.,1.,15)
_f15_val=np.empty((_f15_n,15,1))
for j in range(1,15):
 _f15_val[j-1,:,0]=(np.sin(np.pi*_f15_time)*(1+j/16)
    +.16*np.cos(2*np.pi*_f15_time)*(j%4)/3+_f15_time*j/18)
_f15_y=.2+1.2*np.arange(1,15)/14+.2*np.sin(np.arange(1,15))
_f15_tr=et.TrajectorySet(time=_f15_time,values=_f15_val,
 curve_ids=tuple(f'c{j:02d}' for j in range(1,15)),
 dimension_names=('gaze',),
 metadata=pd.DataFrame({'subject':np.repeat(
 [f'p{j:02d}' for j in range(1,8)],2)}),
 coordinate_system='normalized',time_unit='s')
_f15_target=et.TrajectorySet(time=_f15_time,
 values=_f15_val[[1,6,12]]+.025,
 curve_ids=('e02','e07','e13'),dimension_names=('gaze',),
 metadata=pd.DataFrame({'subject':['p01','p04','p07']}),
 coordinate_system='normalized',time_unit='s')
_f15_units=[([0,1,1,2,3,4,5] if i%3==0 else
  [6,5,4,3,2,2,1] if i%3==1 else [0,2,3,4,5,6,6])
  for i in range(20)]
_f15_rows=[np.asarray([2*p+d for p in u for d in (0,1)],dtype=int)
  for u in _f15_units]
_f15_iter=iter(_f15_rows)
def _f15_fixed_groups(*args,**kwargs):
 return next(_f15_iter)
with patch.object(ri,'_participant_bootstrap_indices',
 side_effect=_f15_fixed_groups):
 _f15_boot=ri.bootstrap_fpca_regression_uncertainty(
   _f15_tr,_f15_y,targets=_f15_target,n_bootstrap=20,
   n_components=1,resample_unit='participant',
   participant_column='subject',level=.9,random_state=23)
_f15_pi=ri.fpca_regression_future_prediction_interval(
 _f15_boot,_f15_y,confidence_level=.9,random_state=17)
_f15_band=ri.fpca_regression_slope_simultaneous_band(
 _f15_boot,confidence_level=.9,simultaneous_scope='dimension')
_f15_ridx=np.random.default_rng(
 np.random.SeedSequence(17).spawn(1)[0]).integers(
  0,14,size=_f15_boot.bootstrap_mean_predictions.shape)
_f15_pf=ri.fpca_regression_future_prediction_frame(_f15_pi)
_f15_sf=ri.fpca_regression_slope_band_frame(_f15_band)
assert _f15_pi.predictive_draws.shape==(20,3)
assert _f15_band.lower.shape==(15,1)
assert _f15_pf.shape==(3,8)
assert _f15_sf.shape==(15,7)
assert np.allclose(_f15_pi.sampled_residuals,
 _f15_pi.centered_residuals[_f15_ridx])

")
  py_boot<-reticulate::py_eval("_f15_boot",convert=FALSE)
  for(field in c("reference_slope","bootstrap_slopes",
    "reference_mean_predictions","bootstrap_mean_predictions",
    "bootstrap_intercepts","prediction_lower","prediction_median",
    "prediction_upper","prediction_se","slope_lower","slope_median",
    "slope_upper","slope_se")){
    expected<-et_to_r(reticulate::py_get_attr(py_boot,field))
    actual<-local_boot[[field]]
    expect_equal(unname(actual),unname(expected),
      tolerance=1e-6,ignore_attr=TRUE,
      info=paste("external target participant FPCR",field))
  }
  ridx<-reticulate::py_to_r(reticulate::py_eval(
    "_f15_ridx",convert=FALSE))
  local_pi<-etr_fpca_regression_future_prediction_interval(
    local_boot,z$y,confidence_level=.9,random_state=17L)
  expect_identical(local_pi$sampled_residuals,
    matrix(local_pi$centered_residuals[ridx+1],nrow(ridx),ncol(ridx)))
  py_pi<-reticulate::py_eval("_f15_pi",convert=FALSE)
  for(field in c("centered_residuals","sampled_residuals",
    "predictive_draws","lower","median","upper","predictive_se")){
    expected<-et_to_r(reticulate::py_get_attr(py_pi,field))
    expect_equal(unname(local_pi[[field]]),unname(expected),
      tolerance=1e-6,ignore_attr=TRUE,
      info=paste("external target future predictive",field))
  }
  local_band<-etr_fpca_regression_slope_simultaneous_band(
    local_boot,confidence_level=.9,simultaneous_scope="dimension")
  py_band<-reticulate::py_eval("_f15_band",convert=FALSE)
  for(field in c("lower","upper","pointwise_se",
    "critical_values","max_statistics")){
    expected<-et_to_r(reticulate::py_get_attr(py_band,field))
    expect_equal(unname(local_band[[field]]),unname(expected),
      tolerance=1e-6,ignore_attr=TRUE,
      info=paste("external target simultaneous slope",field))
  }
  local_pred_table<-etr_fpca_regression_future_prediction_frame(local_pi)
  python_pred_table<-reticulate::py_to_r(reticulate::py_eval(
    "_f15_pf",convert=FALSE))
  expect_identical(names(local_pred_table),names(python_pred_table))
  expect_equal(as.character(local_pred_table$curve_id),
    as.character(python_pred_table$curve_id))
  for(field in setdiff(names(local_pred_table),"curve_id"))
    expect_equal(as.numeric(local_pred_table[[field]]),
      as.numeric(python_pred_table[[field]]),tolerance=1e-6,
      info=paste("external future frame",field))
  local_slope_table<-etr_fpca_regression_slope_band_frame(local_band)
  python_slope_table<-reticulate::py_to_r(reticulate::py_eval(
    "_f15_sf",convert=FALSE))
  expect_identical(names(local_slope_table),names(python_slope_table))
  expect_equal(as.character(local_slope_table$dimension),
    as.character(python_slope_table$dimension))
  for(field in setdiff(names(local_slope_table),"dimension"))
    expect_equal(as.numeric(local_slope_table[[field]]),
      as.numeric(python_slope_table[[field]]),tolerance=1e-6,
      info=paste("external slope band frame",field))
  expect_false(local_pi$provenance$
    fpca_regression_future_prediction_interval$simultaneous_across_targets)
  expect_false(local_band$provenance$
    fpca_regression_slope_band$continuous_between_grid_points)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
