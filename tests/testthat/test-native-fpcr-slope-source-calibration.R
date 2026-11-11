# Numerical regression_inference.py paired-FPCR source calibration witness.
.etr_slope_calibration_fixture <- function() {
  ref<-matrix(c(1,2,3,4),nrow=2,ncol=2)
  boots<-array(rep(as.numeric(ref),each=4L),dim=c(4L,2L,2L))
  boots[,1,1]<-ref[1,1]+c(-1,0,1,0)
  boots[,2,1]<-ref[2,1]+c(0,-1,0,1)
  list(reference_slope=ref,bootstrap_slopes=boots,
    reference_fpca=list(dimension_names=c("x","y")),
    provenance=list())
}
test_that("FPCR simultaneous slope bands retain observed grid and NumPy higher quantile",{
  z<-.etr_slope_calibration_fixture()
  x<-etr_fpca_regression_slope_simultaneous_band(
    z,confidence_level=.5)
  expect_equal(dim(x$lower),c(2L,2L))
  expect_equal(x$pointwise_se[1,1],sqrt(2/3),tolerance=1e-12)
  expect_equal(x$pointwise_se[2,1],sqrt(2/3),tolerance=1e-12)
  expect_equal(x$pointwise_se[,2],c(0,0))
  expect_equal(x$critical_values,rep(sqrt(3/2),2L),
    tolerance=1e-12)
  expect_equal(x$lower,z$reference_slope -
    matrix(c(1,1,0,0),2,2),tolerance=1e-12)
  expect_equal(x$upper,z$reference_slope +
    matrix(c(1,1,0,0),2,2),tolerance=1e-12)
  expect_equal(x$provenance$fpca_regression_slope_band$
    zero_variance_cells,2L)
  y<-etr_fpca_regression_slope_simultaneous_band(
    z,confidence_level=.5,simultaneous_scope="dimension")
  expect_equal(y$critical_values,c(sqrt(3/2),0),
    tolerance=1e-12)
  expect_equal(dim(y$max_statistics),c(4L,2L))
  expect_equal(y$lower,x$lower)
  expect_false(y$provenance$fpca_regression_slope_band$
    continuous_between_grid_points)
  expect_false(y$provenance$fpca_regression_slope_band$
    operator_scaled_fpcr_test)
})
test_that("FPCR slope calibration fails closed on degenerate scientific cells",{
  z<-.etr_slope_calibration_fixture()
  bad<-z;bad$bootstrap_slopes[,1,2]<-bad$reference_slope[1,2]+1
  expect_error(etr_fpca_regression_slope_simultaneous_band(bad),
    "degenerate")
  bad<-z;bad$bootstrap_slopes[1,1,1]<-Inf
  expect_error(etr_fpca_regression_slope_simultaneous_band(bad),
    "finite")
  bad<-z;bad$bootstrap_slopes<-bad$bootstrap_slopes[1,,,drop=FALSE]
  expect_error(etr_fpca_regression_slope_simultaneous_band(bad),
    "bootstrap slope array")
  expect_error(etr_fpca_regression_slope_simultaneous_band(
    z,confidence_level=TRUE),"confidence_level")
  expect_error(etr_fpca_regression_slope_simultaneous_band(
    z,simultaneous_scope="none"),"simultaneous_scope")
})
test_that("source FPCR slope bands remain unsigned pending complete review",{
  name<-"fpca_regression_slope_simultaneous_band"
  p<-etr_native_parity_catalog()
  x<-p[p$is_python_function&p$python_name==name,,drop=FALSE]
  expect_equal(nrow(x),1L)
  expect_identical(x$native_r_candidate,paste0("etr_",name))
  expect_true(x$native_implementation_started)
  expect_false(x$source_contract_gap_unresolved)
  expect_false(x$one_to_one_native_contract_complete)
  expect_gte(sum(p$is_python_function&p$named_native_candidate),327L)
  expect_gte(sum(p$native_implementation_started),302L)
  rows<-utils::read.csv(.etr_test_extdata(
    "native_source_contract_gaps_stage22.csv"))
  classes<-utils::read.csv(.etr_test_extdata(
    "native_nonfunction_source_gaps_v1.csv"))
  expect_equal(sum(p$source_contract_gap_unresolved),
    sum(rows$unresolved_source_gap)+sum(classes$unresolved))
})
test_that("pinned Python 1.2 FPCR slope bands agree on both maxima scopes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 FPCR simultaneous slope calibration is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _sl_obj(cls,**fields):
    v=object.__new__(cls)
    for name,value in fields.items(): object.__setattr__(v,name,value)
    return v
_sl_ref=np.array([[1.,3.],[2.,4.]])
_sl_boot=np.repeat(_sl_ref[None,:,:],4,axis=0)
_sl_boot[:,0,0]=_sl_ref[0,0]+np.array([-1.,0.,1.,0.])
_sl_boot[:,1,0]=_sl_ref[1,0]+np.array([0.,-1.,0.,1.])
_sl_fit=_sl_obj(et.FPCARegressionUncertaintyResult,
    reference_slope=_sl_ref,bootstrap_slopes=_sl_boot,
    reference_fpca=_sl_obj(et.FPCAResult,dimension_names=('x','y')),
    provenance={})
_sl_results={
    scope:et.fpca_regression_slope_simultaneous_band(
      _sl_fit,confidence_level=.5,simultaneous_scope=scope)
    for scope in ('global','dimension')}
")
  # Direct source calls for both simultaneous maxima scopes; compare
  # source-to-source and source-to-native without promoting certification.
  direct<-list(
    global=reticulate::py_call(
      etpy_get_export("fpca_regression_slope_simultaneous_band"),
      result=reticulate::py_eval("_sl_fit",convert=FALSE),
      confidence_level=.5,simultaneous_scope="global"),
    dimension=reticulate::py_call(
      etpy_get_export("fpca_regression_slope_simultaneous_band"),
      result=reticulate::py_eval("_sl_fit",convert=FALSE),
      confidence_level=.5,simultaneous_scope="dimension")
  )
  z<-.etr_slope_calibration_fixture()
  for(scope in c("global","dimension")){
    x<-etr_fpca_regression_slope_simultaneous_band(
      z,confidence_level=.5,simultaneous_scope=scope)
    for(n in c("lower","upper","pointwise_se",
      "critical_values","max_statistics")){
      py<-reticulate::py_eval(paste0(
        "_sl_results['",scope,"'].",n),convert=TRUE)
      expect_equal(x[[n]],py,tolerance=1e-12,ignore_attr=TRUE,
        info=paste("frozen 1.2",scope,n))
      expect_equal(et_to_r(reticulate::py_get_attr(direct[[scope]],n)),py,
        tolerance=1e-12,ignore_attr=TRUE)
    }
  }
})
