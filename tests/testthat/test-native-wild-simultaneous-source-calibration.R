# Frozen Python 1.2.0 wild_simultaneous.py numerical source oracle.
.etr_fpcr_simultaneous_fixture <- function(){
  roots<-rbind(c(.1,.2,.3),c(.5,.4,.1),c(.9,.6,.7),c(.2,.8,.3))
  list(target_curve_ids=c("A","B","C"),
    bootstrap_projections=matrix(0,4,3),
    studentized_roots=roots,
    reference_projection=c(.3,-.2,.1),
    reference_se=c(.1,.2,.05),
    confidence_level=.95,provenance=list(
      fpca_wild_bootstrap_projection=list(studentization="full_fit")))
}
test_that("NumPy higher bootstrap quantiles preserve discrete order statistics",{
  z<-.etr_fpcr_simultaneous_fixture()
  x<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    z,confidence_level=.5)
  # For B=4 the NumPy 'higher' median selects sorted index 3,
  # whereas R type=1 would select sorted index 2.
  expect_equal(x$targetwise_critical_values,c(.5,.6,.3))
  expect_equal(x$max_statistics,c(.3,.5,.9,.8))
  expect_equal(x$critical_value,.8)
  expect_equal(x$lower,c(.22,-.36,.06),tolerance=1e-12)
  expect_equal(x$upper,c(.38,-.04,.14),tolerance=1e-12)
  expect_identical(x$projection_result$target_curve_ids,c("A","B","C"))
  expect_true(x$provenance$fpca_wild_bootstrap_simultaneous$
    bootstrap_roots_reused)
  expect_false(x$provenance$fpca_wild_bootstrap_simultaneous$
    bootstrap_rerun)
  expect_false(x$provenance$fpca_wild_bootstrap_simultaneous$
    future_outcome_prediction_interval)
  y<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(z)
  expect_equal(y$critical_value,.9)
  expect_equal(y$targetwise_critical_values,c(.9,.8,.7))
})
test_that("wild simultaneous calibration fails closed on invalid support",{
  z<-.etr_fpcr_simultaneous_fixture()
  bad<-z;bad$studentized_roots[1,1]<-Inf
  expect_error(etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    bad),"studentized_roots")
  bad<-z;bad$studentized_roots<-matrix(1,3,3)
  expect_error(etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    bad),"studentized_roots")
  bad<-z;bad$reference_se[1]<--1
  expect_error(etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    bad),"reference standard errors")
  bad<-z;bad$target_curve_ids<-c("A","A","C")
  expect_error(etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    bad),"target_curve_ids")
  expect_error(etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    z,confidence_level=TRUE),"confidence_level")
  expect_error(etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    z,confidence_level=0),"confidence_level")
})
test_that("one new wild simultaneous numerical source mapping stays uncertified",{
  name<-"fpca_wild_bootstrap_projection_simultaneous_interval"
  p<-etr_native_parity_catalog()
  x<-p[p$is_python_function&p$python_name==name,,drop=FALSE]
  expect_equal(nrow(x),1L)
  expect_identical(x$native_r_candidate,paste0("etr_",name))
  expect_true(x$native_implementation_started)
  expect_true(x$source_contract_gap_unresolved)
  expect_false(x$one_to_one_native_contract_complete)
  expect_gte(sum(p$is_python_function&p$named_native_candidate),327L)
  expect_gte(sum(p$native_implementation_started),302L)
  expect_gte(sum(p$source_contract_gap_unresolved),149L)
})
test_that("wild simultaneous exact higher order statistics agree with Python",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 wild maxT interval numerical oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _ws_obj(cls, **fields):
    x=object.__new__(cls)
    for name,value in fields.items(): object.__setattr__(x,name,value)
    return x
_ws_base=_ws_obj(et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('A','B','C'),
    bootstrap_projections=np.zeros((4,3)),
    studentized_roots=np.array([[.1,.2,.3],[.5,.4,.1],
      [.9,.6,.7],[.2,.8,.3]]),
    reference_projection=np.array([.3,-.2,.1]),
    reference_se=np.array([.1,.2,.05]),
    confidence_level=.95,
    provenance={'fpca_wild_bootstrap_projection':{
        'studentization':'full_fit'}},
    multiplier='rademacher',
    residual_components=2,inference_components=2)
_ws_result=et.fpca_wild_bootstrap_projection_simultaneous_interval(
    _ws_base,confidence_level=.5)
_ws_oracle={
    'targetwise_critical_values':_ws_result.targetwise_critical_values,
    'max_statistics':_ws_result.max_statistics,
    'critical_value':_ws_result.critical_value,
    'lower':_ws_result.lower,'upper':_ws_result.upper,
    'confidence_level':_ws_result.confidence_level}
")
  direct<-reticulate::py_call(
    etpy_get_export("fpca_wild_bootstrap_projection_simultaneous_interval"),
    result=reticulate::py_eval("_ws_base",convert=FALSE),
    confidence_level=.5)
  z<-.etr_fpcr_simultaneous_fixture()
  a<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    z,confidence_level=.5)
  for(n in c("targetwise_critical_values","max_statistics",
    "critical_value","lower","upper","confidence_level")){
    py<-reticulate::py_eval(paste0("_ws_oracle['",n,"']"),
      convert=TRUE)
    expect_equal(a[[n]],py,tolerance=1e-12,ignore_attr=TRUE,
      info=paste("pinned Python 1.2 wild simultaneous",n))
    expect_equal(et_to_r(reticulate::py_get_attr(direct,n)),py,
      tolerance=1e-12,ignore_attr=TRUE)
  }
})
