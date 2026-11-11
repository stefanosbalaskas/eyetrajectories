# Two non-resampling source inference contracts:
# Frozen eyetrajectoriespy==1.2.0 at
# c1cd95ad718327550f7e55393ff38582872f7a94
# wild_testing.py::fpca_wild_bootstrap_projection_family_test
# regression_inference.py::fpca_regression_slope_simultaneous_band

.etr_family_slope_fixture <- function() {
  roots<-rbind(c(.1,.2,.3),c(.5,.4,.1),c(.9,.6,.7),c(.2,.8,.3))
  projection<-list(target_curve_ids=c("fixedβ","second","third"),
    bootstrap_projections=matrix(0,4,3),
    studentized_roots=roots,
    reference_projection=c(.3,-.2,.1),
    reference_se=c(.1,.2,.05),
    residual_components=2L,inference_components=3L,
    multiplier="rademacher",
    provenance=list(study="full-source-fixture",
      fpca_wild_bootstrap_projection=list(studentization="full_fit")))
  slope<-matrix(c(.3,-.2,.1,.4,.5,-.1),nrow=3L,ncol=2L)
  boot<-array(0,dim=c(5L,3L,2L))
  offsets<-c(-.4,-.2,0,.2,.4)
  for(i in seq_len(5L)){
    boot[i,,1L]<-slope[,1L]+offsets[i]*c(1,2,-1)
    boot[i,,2L]<-slope[,2L]+offsets[i]*c(.5,0,-.5)
  }
  fit<-list(reference_slope=slope,bootstrap_slopes=boot,
    reference_fpca=list(dimension_names=c("gaze-x","gaze-y")),
    provenance=list(study="full-source-fixture"))
  list(projection=projection,fit=fit)
}

test_that("fixed family law is full source-aligned for both p-value corrections", {
  f<-.etr_family_slope_fixture()
  for(rule in c("plus_one","none"))for(null in list(0,c(0,-.2,.1))){
    a<-etr_fpca_wild_bootstrap_projection_family_test(
      f$projection,null_values=null,significance_level=.2,
      pvalue_correction=rule)
    expect_s3_class(a,"etr_fpca_wild_bootstrap_family_test")
    expect_equal(a$n_bootstrap,4L)
    expect_equal(a$n_targets,3L)
    expect_equal(a$minimum_attainable_p,if(rule=="plus_one")1/5 else 0)
    expect_identical(a$projection_result$target_curve_ids,
      c("fixedβ","second","third"))
    expect_identical(names(a$provenance),
      c("study","fpca_wild_bootstrap_projection",
        "fpca_wild_bootstrap_family_test"))
    m<-a$provenance$fpca_wild_bootstrap_family_test
    expect_identical(m$studentization,"full_fit")
    expect_identical(m$multiplier,"rademacher")
    expect_identical(m$residual_components_k,2L)
    expect_identical(m$pseudo_truth_components_g,2L)
    expect_identical(m$inference_components_h,3L)
    expect_null(m$source_full_contract_certified)
    expect_true(all(a$adjusted_p_values>=a$targetwise_p_values))
    expect_false(m$strong_fwer_for_arbitrary_subset_nulls_claimed)
    expect_true(m$bootstrap_roots_reused)
    expect_false(m$bootstrap_rerun)
  }
})

test_that("FPCR observed-grid slope band preserves both calibrated scopes", {
  f<-.etr_family_slope_fixture()
  for(scope in c("global","dimension")){
    a<-etr_fpca_regression_slope_simultaneous_band(
      f$fit,confidence_level=.6,simultaneous_scope=scope)
    expect_identical(dim(a$lower),c(3L,2L))
    expect_identical(dim(a$upper),c(3L,2L))
    expect_identical(dim(a$pointwise_se),c(3L,2L))
    expect_equal(a$lower+a$upper,2*f$fit$reference_slope,tolerance=1e-12)
    expect_equal(a$pointwise_se[2,2],0,tolerance=0)
    expect_equal(a$critical_values[2],if(scope=="dimension")
      a$critical_values[2] else a$critical_values[1],tolerance=0)
    expect_identical(a$regression_uncertainty, f$fit)
    expect_identical(a$provenance$study,"full-source-fixture")
    p<-a$provenance$fpca_regression_slope_band
    expect_identical(p$n_bootstrap,5L)
    expect_identical(p$zero_variance_cells,1L)
    expect_false(p$continuous_between_grid_points)
    expect_false(p$operator_scaled_fpcr_test)
    expect_true(p$bootstrap_reused_from_regression_uncertainty)
  }
})

test_that("postcalibrators reject malformed scientific inputs without hidden fitting", {
  f<-.etr_family_slope_fixture()
  for(rule in list("invalid",FALSE,NA_character_))
    expect_error(etr_fpca_wild_bootstrap_projection_family_test(
      f$projection,pvalue_correction=rule),"pvalue_correction")
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(
    f$projection,null_values=c(0,1)),"null_values")
  bad<-f$projection;bad$reference_se[1]<-0
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(
    bad,null_values=0),"zero reference standard error")
  bad<-f$fit
  bad$bootstrap_slopes[,2,2]<-bad$reference_slope[2,2]+1
  expect_error(etr_fpca_regression_slope_simultaneous_band(bad),
    "degenerate")
  expect_error(etr_fpca_regression_slope_simultaneous_band(
    f$fit,confidence_level=0),"confidence_level")
  expect_error(etr_fpca_regression_slope_simultaneous_band(
    f$fit,simultaneous_scope="other"),"simultaneous_scope")
})

test_that("complete typed Python 1.2 family and slope-band source results match R", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("exact frozen Python 1.2 source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _fs_obj(cls,**kw):
    x=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(x,k,v)
    return x
_fs_base=_fs_obj(
    et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('fixedβ','second','third'),
    bootstrap_projections=np.zeros((4,3)),
    studentized_roots=np.array([
       [.1,.2,.3],[.5,.4,.1],[.9,.6,.7],[.2,.8,.3]]),
    reference_projection=np.array([.3,-.2,.1]),
    reference_se=np.array([.1,.2,.05]),
    residual_components=2,inference_components=3,
    multiplier='rademacher',
    provenance={'study':'full-source-fixture',
       'fpca_wild_bootstrap_projection':{'studentization':'full_fit'}})
_fs_slope=np.array([[.3,.4],[-.2,.5],[.1,-.1]])
_fs_boot=np.empty((5,3,2))
for i,offset in enumerate([-.4,-.2,0,.2,.4]):
    _fs_boot[i,:,0]=_fs_slope[:,0]+offset*np.array([1,2,-1])
    _fs_boot[i,:,1]=_fs_slope[:,1]+offset*np.array([.5,0,-.5])
_fs_fit=_fs_obj(
    et.FPCARegressionUncertaintyResult,
    reference_slope=_fs_slope,bootstrap_slopes=_fs_boot,
    reference_fpca=_fs_obj(et.FPCAResult,
        dimension_names=('gaze-x','gaze-y')),
    provenance={'study':'full-source-fixture'})
_fs_families={
    (rule,scalar):et.fpca_wild_bootstrap_projection_family_test(
       _fs_base,null_values=(0.0 if scalar else np.array([0.,-.2,.1])),
       significance_level=.2,pvalue_correction=rule)
    for rule in ('plus_one','none') for scalar in (True,False)}
_fs_bands={
    scope:et.fpca_regression_slope_simultaneous_band(
       _fs_fit,confidence_level=.6,simultaneous_scope=scope)
    for scope in ('global','dimension')}
")
  f<-.etr_family_slope_fixture()
  for(rule in c("plus_one","none"))for(scalar in c(TRUE,FALSE)){
    result<-etr_fpca_wild_bootstrap_projection_family_test(
      f$projection,null_values=if(scalar)0 else c(0,-.2,.1),
      significance_level=.2,pvalue_correction=rule)
    key<-paste0("('",rule,"', ",if(scalar)"True" else "False",")")
    py<-reticulate::py_eval(paste0("_fs_families[",key,"]"),
      convert=FALSE)
    for(n in setdiff(names(result),
       c("projection_result","provenance"))){
      actual<-result[[n]]
      expected<-et_to_r(reticulate::py_get_attr(py,n))
      expect_equal(actual,expected,tolerance=1e-12,ignore_attr=TRUE,
        info=paste("family",rule,scalar,n))
    }
    expect_equal(result$provenance,
      et_to_r(reticulate::py_get_attr(py,"provenance")),
      ignore_attr=TRUE,info=paste("family provenance",rule,scalar))
  }
  for(scope in c("global","dimension")){
    actual<-etr_fpca_regression_slope_simultaneous_band(
      f$fit,confidence_level=.6,simultaneous_scope=scope)
    py<-reticulate::py_eval(paste0("_fs_bands['",scope,"']"),
      convert=FALSE)
    for(n in setdiff(names(actual),c("regression_uncertainty","provenance"))){
      expected<-et_to_r(reticulate::py_get_attr(py,n))
      expect_equal(actual[[n]],expected,tolerance=2e-12,ignore_attr=TRUE,
        info=paste("slope scope",scope,n))
    }
    expect_equal(actual$provenance,
      et_to_r(reticulate::py_get_attr(py,"provenance")),
      ignore_attr=TRUE,info=paste("slope provenance",scope))
  }
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
