# Frozen Python eyetrajectoriespy==1.2.0 wild_testing.py plus plotting.py
# src c1cd95ad718327550f7e55393ff38582872f7a94.
.etr_wild_mc_fixture <- function() {
  roots<-rbind(c(.1,.2,.3),c(.5,.4,.1),c(.9,.6,.7),c(.2,.8,.3))
  projection<-list(target_curve_ids=c("A","B","C"),
    bootstrap_projections=matrix(0,4,3),
    studentized_roots=roots,
    reference_projection=c(.3,-.2,.1),
    reference_se=c(.1,.2,.05))
  family<-list(projection_result=projection,
    observed_statistics=c(.4,.5,.25),
    max_statistics=c(.3,.5,.9,.8),global_statistic=.7,
    reject_targetwise=c(FALSE,FALSE,FALSE),
    reject_familywise=c(FALSE,FALSE,FALSE),
    reject_global=FALSE,significance_level=.05,
    pvalue_correction="plus_one",provenance=list())
  simultaneous<-list(projection_result=projection,
    lower=c(.1,-.6,-.1),upper=c(.6,.2,.3),
    targetwise_critical_values=c(1,1.5,2))
  list(family=family,simultaneous=simultaneous)
}
.etr_wild_mc_pdf <- function(code) {
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path)
  on.exit({if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)},add=TRUE)
  force(code)
}
test_that("exact native Monte Carlo precision reuses fixed bootstrap roots",{
  z<-.etr_wild_mc_fixture()
  a<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    z$family)
  expect_identical(a$targetwise_exceedances,c(2L,2L,3L))
  expect_identical(a$adjusted_exceedances,c(3L,3L,4L))
  expect_identical(a$global_exceedances,2L)
  expect_equal(a$targetwise_tail_probabilities,c(.5,.5,.75))
  expect_equal(a$adjusted_tail_probabilities,c(.75,.75,1))
  expect_equal(a$global_tail_probability,.5)
  expect_equal(a$targetwise_mcse,
    sqrt(c(.5*.5,.5*.5,.75*.25)/4))
  expect_identical(a$targetwise_decision_stable,c(FALSE,FALSE,FALSE))
  expect_identical(a$adjusted_decision_stable,c(FALSE,FALSE,FALSE))
  expect_identical(a$global_decision_stable,FALSE)
  expect_equal(a$targetwise_interval_lower[1L],
    stats::qbeta(.025,2,3),tolerance=1e-12)
  expect_equal(a$adjusted_interval_upper[3L],1)
  expect_equal(a$adjusted_interval_lower[3L],
    stats::qbeta(.025,4,1),tolerance=1e-12)
  expect_false(a$provenance$additional_bootstrap_draws)
  expect_false(a$provenance$changes_reported_test_decisions)
  expect_false(a$provenance$strong_fwer_claim_added)
})
test_that("source wild-bootstrap visuals preserve fixed targets and uncertainty",{
  z<-.etr_wild_mc_fixture()
  result<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    z$family)
  .etr_wild_mc_pdf({
    a<-etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      result,max_targets=2L,show_targetwise=TRUE)
    expect_identical(a$target_index,0:1)
    expect_identical(a$target_curve_id,c("A","B"))
    expect_equal(a$adjusted,c(.75,.75))
    expect_equal(a$targetwise,c(.5,.5))
    expect_equal(a$adjusted_upper,
      result$adjusted_interval_upper[1:2])
    b<-etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      z$simultaneous,max_targets=2L,show_targetwise=TRUE)
    expect_equal(b$reference_projection,c(.3,-.2))
    expect_equal(b$simultaneous_lower,c(.1,-.6))
    expect_equal(b$simultaneous_upper,c(.6,.2))
    expect_equal(b$targetwise_lower,c(.2,-.5))
    expect_equal(b$targetwise_upper,c(.4,.1))
  })
})
test_that("MC diagnostics reject malformed roots and inconsistent support",{
  z<-.etr_wild_mc_fixture()
  a<-z$family;a$projection_result$studentized_roots[1L,1L]<-Inf
  expect_error(etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(a),
    "studentized_roots")
  a<-z$family;a$observed_statistics<-numeric()
  expect_error(etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(a),
    "observed_statistics")
  a<-z$family;a$reject_familywise<-c(TRUE)
  expect_error(etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(a),
    "reject_familywise")
  a<-z$family;a$max_statistics<-c(1,2)
  expect_error(etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(a),
    "max_statistics")
  expect_error(etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    z$family,confidence_level=1),"confidence_level")
  expect_error(etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    z$family,confidence_level=TRUE),"confidence_level")
  result<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    z$family)
  .etr_wild_mc_pdf({
    expect_error(etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      result,max_targets=0),"max_targets")
    expect_error(etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      result,show_targetwise=1),"show_targetwise")
    bad<-result;bad$adjusted_interval_lower[1]<-1
    expect_error(etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      bad),"interval bounds")
    bad<-z$simultaneous;bad$upper[1]<-0
    expect_error(etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      bad),"must enclose")
    bad<-z$simultaneous;bad$projection_result$reference_se[1]<--1
    expect_error(etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      bad),"nonnegative")
  })
})
test_that("three new source functions remain independently uncertified",{
  names<-c("fpca_wild_bootstrap_family_test_monte_carlo_diagnostics",
    "plot_fpca_wild_bootstrap_monte_carlo_diagnostics",
    "plot_fpca_wild_bootstrap_simultaneous_interval")
  p<-etr_native_parity_catalog()
  x<-p[p$is_python_function & p$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(x),3L)
  expect_identical(sort(x$native_r_candidate),
    sort(paste0("etr_",names)))
  expect_true(all(x$native_implementation_started))
  expect_true(all(x$source_contract_gap_unresolved))
  expect_false(any(x$one_to_one_native_contract_complete))
  expect_equal(sum(p$is_python_function & p$named_native_candidate),324L)
  expect_equal(sum(p$native_implementation_started),299L)
  expect_equal(sum(p$source_contract_gap_unresolved),146L)
})
test_that("direct frozen Python 1.2 exact binomial and plot coordinates agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python wild Monte Carlo numerical source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
def _etmc(cls,**kw):
    x=object.__new__(cls)
    for key,val in kw.items(): object.__setattr__(x,key,val)
    return x
_mc_proj=_etmc(et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('A','B','C'),
    bootstrap_projections=np.zeros((4,3)),
    studentized_roots=np.array([[.1,.2,.3],[.5,.4,.1],
       [.9,.6,.7],[.2,.8,.3]]),
    reference_projection=np.array([.3,-.2,.1]),
    reference_se=np.array([.1,.2,.05]))
_mc_family=_etmc(et.FPCAWildBootstrapFamilyTestResult,
    projection_result=_mc_proj,observed_statistics=np.array([.4,.5,.25]),
    max_statistics=np.array([.3,.5,.9,.8]),global_statistic=.7,
    reject_targetwise=np.array([False]*3),
    reject_familywise=np.array([False]*3),reject_global=False,
    significance_level=.05,pvalue_correction='plus_one',provenance={})
_mc_result=et.fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    _mc_family,confidence_level=.95)
_mc_sim=_etmc(et.FPCAWildBootstrapSimultaneousResult,
    projection_result=_mc_proj,
    lower=np.array([.1,-.6,-.1]),
    upper=np.array([.6,.2,.3]),
    targetwise_critical_values=np.array([1.,1.5,2.]))
_mc_ax=et.plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
    _mc_result,max_targets=2,show_targetwise=True)
_mc_ax2=et.plot_fpca_wild_bootstrap_simultaneous_interval(
    _mc_sim,max_targets=2,show_targetwise=True)
_mc_oracle={
    'targetwise_exceedances':_mc_result.targetwise_exceedances,
    'adjusted_exceedances':_mc_result.adjusted_exceedances,
    'targetwise_tail_probabilities':_mc_result.targetwise_tail_probabilities,
    'adjusted_tail_probabilities':_mc_result.adjusted_tail_probabilities,
    'targetwise_mcse':_mc_result.targetwise_mcse,
    'adjusted_mcse':_mc_result.adjusted_mcse,
    'targetwise_interval_lower':_mc_result.targetwise_interval_lower,
    'targetwise_interval_upper':_mc_result.targetwise_interval_upper,
    'adjusted_interval_lower':_mc_result.adjusted_interval_lower,
    'adjusted_interval_upper':_mc_result.adjusted_interval_upper,
    'targetwise_decision_stable':_mc_result.targetwise_decision_stable,
    'adjusted_decision_stable':_mc_result.adjusted_decision_stable,
    'plot_adjusted':_mc_ax.lines[0].get_ydata(),
    'plot_targetwise':_mc_ax.lines[1].get_ydata(),
    'plot_projection':_mc_ax2.lines[0].get_ydata()
}
plt.close('all')
")
  z<-.etr_wild_mc_fixture()
  a<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    z$family)
  .etr_wild_mc_pdf({
    b<-etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      a,max_targets=2L,show_targetwise=TRUE)
    c<-etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      z$simultaneous,max_targets=2L,show_targetwise=TRUE)
    actual<-list(
      targetwise_exceedances=a$targetwise_exceedances,
      adjusted_exceedances=a$adjusted_exceedances,
      targetwise_tail_probabilities=a$targetwise_tail_probabilities,
      adjusted_tail_probabilities=a$adjusted_tail_probabilities,
      targetwise_mcse=a$targetwise_mcse,adjusted_mcse=a$adjusted_mcse,
      targetwise_interval_lower=a$targetwise_interval_lower,
      targetwise_interval_upper=a$targetwise_interval_upper,
      adjusted_interval_lower=a$adjusted_interval_lower,
      adjusted_interval_upper=a$adjusted_interval_upper,
      targetwise_decision_stable=a$targetwise_decision_stable,
      adjusted_decision_stable=a$adjusted_decision_stable,
      plot_adjusted=b$adjusted,plot_targetwise=b$targetwise,
      plot_projection=c$reference_projection)
    for(n in names(actual)){
      py<-reticulate::py_eval(paste0("_mc_oracle['",n,"']"),
        convert=TRUE)
      expect_equal(actual[[n]],py,tolerance=1e-10,
        ignore_attr=TRUE,info=paste("frozen Python source",n))
    }
  })
})
