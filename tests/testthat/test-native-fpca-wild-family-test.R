# Published Python 1.2 wild_testing.py fixed-family root reuse.
.etr_wild_family_fixture<-function(){
  roots<-matrix(c(
    0,1,0, 1,0,-1, .4,.6,.2,
    -.2,-.7,.5, 1.8,.8,-.5,
    .9,1.4,.3, 0,0,0),ncol=3,byrow=TRUE)
  list(bootstrap_projections=matrix(0,nrow(roots),3L),
    studentized_roots=roots,reference_projection=c(1,.5,-.25),
    reference_se=c(.5,1,.25),
    target_curve_ids=c("A","B","C"),
    residual_components=2L,inference_components=3L,
    multiplier="normal",
    provenance=list(fpca_wild_bootstrap_projection=list(
      studentization="heteroscedastic_fixed_score")))
}
test_that("fixed-family maxT source law reuses exact roots and never refits",{
  z<-.etr_wild_family_fixture()
  fixed<-etr_fpca_wild_bootstrap_projection_family_test(z,
    null_values=c(.25,0,-.25),significance_level=.2)
  expect_s3_class(fixed,"etr_fpca_wild_bootstrap_family_test")
  expect_equal(fixed$observed_statistics,c(1.5,.5,0))
  expect_equal(fixed$max_statistics,apply(abs(z$studentized_roots),1L,max))
  exp_target<-vapply(seq_len(3L),function(j)
    (sum(abs(z$studentized_roots[,j])>=abs(fixed$observed_statistics[j]))+1)/8,
    numeric(1L))
  exp_adj<-vapply(seq_len(3L),function(j)
    (sum(fixed$max_statistics>=abs(fixed$observed_statistics[j]))+1)/8,
    numeric(1L))
  expect_equal(fixed$targetwise_p_values,exp_target)
  expect_equal(fixed$adjusted_p_values,exp_adj)
  expect_true(all(fixed$adjusted_p_values>=fixed$targetwise_p_values))
  expect_equal(fixed$global_p_value,
    (sum(fixed$max_statistics>=max(abs(fixed$observed_statistics)))+1)/8)
  expect_identical(fixed$projection_result,z)
  family_frame<-etr_fpca_wild_bootstrap_family_test_frame(fixed)
  expect_equal(nrow(family_frame),3L)
  expect_equal(family_frame$adjusted_p_value,fixed$adjusted_p_values)
  diagnostic<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    fixed,confidence_level=.95)
  expect_identical(length(diagnostic$adjusted_exceedances),3L)
  expect_equal(diagnostic$global_tail_probability,
    (fixed$global_p_value*8-1)/7,tolerance=1e-12)
  expect_true(diagnostic$provenance$
    fpca_wild_bootstrap_monte_carlo_diagnostics$bootstrap_roots_reused)
  expect_true(fixed$provenance$
    fpca_wild_bootstrap_family_test$bootstrap_roots_reused)
  expect_false(fixed$provenance$
    fpca_wild_bootstrap_family_test$bootstrap_rerun)
  expect_null(fixed$provenance$
    fpca_wild_bootstrap_family_test$source_full_contract_certified)
  expect_equal(fixed$minimum_attainable_p,1/8)
  no_correction<-etr_fpca_wild_bootstrap_projection_family_test(z,
    null_values=c(.25,0,-.25),pvalue_correction="none")
  expect_equal(no_correction$targetwise_p_values,
    (exp_target*8-1)/7)
})

test_that("source zero-SE conventions fail closed on nonzero discrepancy",{
  z<-.etr_wild_family_fixture()
  z$reference_se[2L]<-0
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(z,
    null_values=0),"zero reference standard error")
  valid<-etr_fpca_wild_bootstrap_projection_family_test(z,
    null_values=c(1,.5,-.25))
  expect_equal(valid$observed_statistics,rep(0,3))
  expect_true(all(valid$targetwise_p_values==1))
  expect_true(valid$reject_global==FALSE)
  z$studentized_roots[1L,1L]<-NA_real_
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(z),
    "studentized_roots")
  z<-.etr_wild_family_fixture()
  z$studentized_roots<-z$studentized_roots[,1:2]
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(z),
    "studentized_roots")
  z<-.etr_wild_family_fixture()
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(z,
    significance_level=1),"significance_level")
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(z,
    null_values=c(1,2)),"null_values")
  expect_error(etr_fpca_wild_bootstrap_projection_family_test(z,
    pvalue_correction="foo"),"pvalue_correction")
})

test_that("frozen Python 1.2 direct-source wild maxT numerical oracle matches R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 fixed-family maxT numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy.types import FPCAWildBootstrapProjectionResult
from eyetrajectoriespy.wild_testing import fpca_wild_bootstrap_projection_family_test
roots=np.array([[0,1,0],[1,0,-1],[.4,.6,.2],[-.2,-.7,.5],[1.8,.8,-.5],[.9,1.4,.3],[0,0,0]],dtype=float)
p=FPCAWildBootstrapProjectionResult(
 reference_fpca=None,target_curve_ids=('A','B','C'),
 reference_projection=np.array([1,.5,-.25]),
 pseudo_truth_projection=np.zeros(3),
 reference_se=np.array([.5,1,.25]),
 bootstrap_projections=np.zeros_like(roots),
 bootstrap_se=np.ones_like(roots),
 studentized_roots=roots,
 critical_values=np.ones(3),
 lower=np.zeros(3),upper=np.zeros(3),
 residuals=np.ones(8),confidence_level=.95,
 residual_components=2,inference_components=3,
 scaling='none',multiplier='normal',target_source='fixed',
 independent_unit_column=None,random_state=0,
 provenance={'fpca_wild_bootstrap_projection':{'studentization':'heteroscedastic_fixed_score'}})
t=fpca_wild_bootstrap_projection_family_test(
 p,null_values=np.array([.25,0,-.25]),significance_level=.2)
_source_maxT=dict(
 observed=t.observed_statistics.tolist(),
 target=t.targetwise_p_values.tolist(),
 adjusted=t.adjusted_p_values.tolist(),
 maxima=t.max_statistics.tolist(),
 global_stat=t.global_statistic,
 global_p=t.global_p_value,
 target_reject=t.reject_targetwise.tolist(),
 adjusted_reject=t.reject_familywise.tolist(),
 global_reject=t.reject_global)
")
  # Literal public export source replay and retained numerical oracle agree.
  direct<-reticulate::py_call(
    etpy_get_export("fpca_wild_bootstrap_projection_family_test"),
    result=reticulate::py_eval("p",convert=FALSE),
    null_values=reticulate::py_eval("np.array([.25,0.,-.25])",
      convert=FALSE),
    significance_level=.2)
  for(field in c("observed_statistics","targetwise_p_values",
    "adjusted_p_values","max_statistics","global_statistic",
    "global_p_value","reject_targetwise","reject_familywise",
    "reject_global")){
    x<-reticulate::py_get_attr(direct,field)
    expected<-reticulate::py_get_attr(
      reticulate::py_eval("t",convert=FALSE),field)
    expect_equal(et_to_r(x),et_to_r(expected),
      tolerance=1e-12,ignore_attr=TRUE)
  }
  source<-reticulate::py_to_r(reticulate::py_eval("_source_maxT",convert=FALSE))
  r<-etr_fpca_wild_bootstrap_projection_family_test(
    .etr_wild_family_fixture(),
    null_values=c(.25,0,-.25),significance_level=.2)
  expect_equal(r$observed_statistics,as.numeric(source$observed),tolerance=1e-12)
  expect_equal(r$targetwise_p_values,as.numeric(source$target),tolerance=1e-12)
  expect_equal(r$adjusted_p_values,as.numeric(source$adjusted),tolerance=1e-12)
  expect_equal(r$max_statistics,as.numeric(source$maxima),tolerance=1e-12)
  expect_equal(r$global_statistic,as.numeric(source$global_stat),tolerance=1e-12)
  expect_equal(r$global_p_value,as.numeric(source$global_p),tolerance=1e-12)
  expect_identical(r$reject_targetwise,as.logical(source$target_reject))
  expect_identical(r$reject_familywise,as.logical(source$adjusted_reject))
  expect_identical(r$reject_global,as.logical(source$global_reject))
})
