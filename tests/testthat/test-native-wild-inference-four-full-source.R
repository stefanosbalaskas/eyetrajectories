# Source: frozen eyetrajectoriespy==1.2.0, c1cd95ad718327550f7e55393ff38582872f7a94.
# A scientific-data audit of four already-computed fixed-target inference tables.

.etr_wild_four_source_fixture<-function() {
  projection<-list(
    target_curve_ids=c("curveβ","c-02","curve3"),
    reference_projection=c(1,2,3),
    reference_se=c(.2,.3,.4),
    pseudo_truth_projection=c(.9,1.8,2.7),
    critical_values=c(1.8,2.1,1.6),
    lower=c(.64,1.37,2.36),
    upper=c(1.36,2.63,3.64))
  simultaneous<-list(
    projection_result=projection,
    targetwise_critical_values=c(1.5,1.7,2.0),
    critical_value=2.2,
    lower=c(.56,1.34,2.12),
    upper=c(1.44,2.66,3.88))
  family<-list(
    projection_result=projection,
    null_values=c(0,0,1),
    observed_statistics=c(2.5,3.1,1.1),
    targetwise_p_values=c(.01,.05,.9),
    adjusted_p_values=c(.08,.12,.98),
    reject_targetwise=c(TRUE,FALSE,FALSE),
    reject_familywise=c(FALSE,FALSE,FALSE),
    global_statistic=3.1,
    global_p_value=.08,significance_level=.05)
  mc<-list(
    family_test_result=family,
    targetwise_exceedances=c(2L,4L,8L),
    targetwise_tail_probabilities=c(.03,.06,.11),
    targetwise_mcse=c(.01,.015,.02),
    targetwise_interval_lower=c(.01,.03,.07),
    targetwise_interval_upper=c(.07,.11,.17),
    targetwise_decision_stable=c(TRUE,FALSE,TRUE),
    adjusted_exceedances=c(6L,7L,9L),
    adjusted_tail_probabilities=c(.1,.12,.16),
    adjusted_mcse=c(.02,.025,.03),
    adjusted_interval_lower=c(.05,.06,.1),
    adjusted_interval_upper=c(.18,.2,.24),
    adjusted_decision_stable=c(TRUE,TRUE,FALSE))
  list(projection=projection,simultaneous=simultaneous,family=family,mc=mc)
}

test_that("four FPCA inference frames preserve all published columns and target identifiers",{
  x<-.etr_wild_four_source_fixture()
  p<-etr_fpca_wild_bootstrap_projection_frame(x$projection)
  s<-etr_fpca_wild_bootstrap_simultaneous_frame(x$simultaneous)
  f<-etr_fpca_wild_bootstrap_family_test_frame(x$family)
  m<-etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(x$mc)
  expect_identical(names(p),c("curve_id","reference_projection",
    "pseudo_truth_projection","heteroscedastic_se","critical_value",
    "lower","upper"))
  expect_identical(names(s),c("curve_id","reference_projection",
    "heteroscedastic_se","targetwise_critical_value",
    "familywise_critical_value","targetwise_lower","targetwise_upper",
    "simultaneous_lower","simultaneous_upper"))
  expect_identical(names(f),c("curve_id","reference_projection",
    "null_value","heteroscedastic_se","observed_statistic",
    "targetwise_p_value","adjusted_p_value","reject_targetwise",
    "reject_familywise","global_statistic","global_p_value"))
  expect_identical(names(m),c("curve_id","targetwise_exceedances",
    "targetwise_tail_probability","targetwise_mcse",
    "targetwise_mc_lower","targetwise_mc_upper",
    "targetwise_precision_status","adjusted_exceedances",
    "adjusted_tail_probability","adjusted_mcse",
    "adjusted_mc_lower","adjusted_mc_upper",
    "adjusted_precision_status","reported_targetwise_p_value",
    "reported_adjusted_p_value","alpha"))
  for(frame in list(p,s,f,m)){
    expect_identical(nrow(frame),3L)
    expect_identical(frame$curve_id,c("curveβ","c-02","curve3"))
  }
  expect_equal(s$targetwise_lower,c(.7,1.49,2.2),tolerance=1e-12)
  expect_equal(s$targetwise_upper,c(1.3,2.51,3.8),tolerance=1e-12)
  expect_identical(m$targetwise_precision_status,
    c("stable_reject","monte_carlo_sensitive","stable_non_reject"))
  expect_identical(m$adjusted_precision_status,
    c("stable_non_reject","stable_non_reject","monte_carlo_sensitive"))
  expect_identical(f$reject_targetwise,c(TRUE,FALSE,FALSE))
  expect_identical(f$reject_familywise,c(FALSE,FALSE,FALSE))
  expect_equal(m$alpha,rep(.05,3L),tolerance=0)
})

test_that("four inference audit frames reject corrupt native science domains",{
  x<-.etr_wild_four_source_fixture()
  p<-x$projection;p$reference_se[[1L]]<--.2
  expect_error(etr_fpca_wild_bootstrap_projection_frame(p),"nonnegative")
  p<-x$projection;p$pseudo_truth_projection<-c(.9,1.8)
  expect_error(etr_fpca_wild_bootstrap_projection_frame(p),"finite numeric vector")
  s<-x$simultaneous;s$critical_value<--1
  expect_error(etr_fpca_wild_bootstrap_simultaneous_frame(s),"nonnegative")
  s<-x$simultaneous;s$targetwise_critical_values<-c(1,2)
  expect_error(etr_fpca_wild_bootstrap_simultaneous_frame(s),"finite numeric vector")
  f<-x$family;f$targetwise_p_values[[2L]]<-1.2
  expect_error(etr_fpca_wild_bootstrap_family_test_frame(f),"targetwise_p_values")
  f<-x$family;f$reject_familywise<-c(TRUE,NA,FALSE)
  expect_error(etr_fpca_wild_bootstrap_family_test_frame(f),"complete logical")
  m<-x$mc;m$targetwise_exceedances[[1L]]<--1L
  expect_error(etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(m),
    "nonnegative integers")
  m<-x$mc;m$adjusted_decision_stable<-c(TRUE,NA,FALSE)
  expect_error(etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(m),
    "complete logical")
})

test_that("four typed frozen Python 1.2 inference result frames agree with native R cellwise",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 four-frame scientific audit oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_source_inference_obj(cls,**attrs):",
    "    v=object.__new__(cls)",
    "    for k,x in attrs.items():object.__setattr__(v,k,x)",
    "    return v",
    "_etr_inf_projection=_etr_source_inference_obj(et.FPCAWildBootstrapProjectionResult,",
    "    target_curve_ids=('curveβ','c-02','curve3'),",
    "    reference_projection=np.array([1.,2.,3.]),",
    "    reference_se=np.array([.2,.3,.4]),",
    "    pseudo_truth_projection=np.array([.9,1.8,2.7]),",
    "    critical_values=np.array([1.8,2.1,1.6]),",
    "    lower=np.array([.64,1.37,2.36]),",
    "    upper=np.array([1.36,2.63,3.64]))",
    "_etr_inf_sim=_etr_source_inference_obj(et.FPCAWildBootstrapSimultaneousResult,",
    "    projection_result=_etr_inf_projection,",
    "    targetwise_critical_values=np.array([1.5,1.7,2.]),",
    "    critical_value=2.2,lower=np.array([.56,1.34,2.12]),",
    "    upper=np.array([1.44,2.66,3.88]))",
    "_etr_inf_family=_etr_source_inference_obj(et.FPCAWildBootstrapFamilyTestResult,",
    "    projection_result=_etr_inf_projection,",
    "    null_values=np.array([0.,0.,1.]),",
    "    observed_statistics=np.array([2.5,3.1,1.1]),",
    "    targetwise_p_values=np.array([.01,.05,.9]),",
    "    adjusted_p_values=np.array([.08,.12,.98]),",
    "    reject_targetwise=np.array([True,False,False]),",
    "    reject_familywise=np.array([False,False,False]),",
    "    global_statistic=3.1,global_p_value=.08,significance_level=.05)",
    "_etr_inf_mc=_etr_source_inference_obj(et.FPCAWildBootstrapMonteCarloDiagnosticResult,",
    "    family_test_result=_etr_inf_family,",
    "    targetwise_exceedances=np.array([2,4,8]),",
    "    targetwise_tail_probabilities=np.array([.03,.06,.11]),",
    "    targetwise_mcse=np.array([.01,.015,.02]),",
    "    targetwise_interval_lower=np.array([.01,.03,.07]),",
    "    targetwise_interval_upper=np.array([.07,.11,.17]),",
    "    targetwise_decision_stable=np.array([True,False,True]),",
    "    adjusted_exceedances=np.array([6,7,9]),",
    "    adjusted_tail_probabilities=np.array([.1,.12,.16]),",
    "    adjusted_mcse=np.array([.02,.025,.03]),",
    "    adjusted_interval_lower=np.array([.05,.06,.1]),",
    "    adjusted_interval_upper=np.array([.18,.2,.24]),",
    "    adjusted_decision_stable=np.array([True,True,False]))",
    "_etr_inf_python_frames=[",
    "  et.fpca_wild_bootstrap_projection_frame(_etr_inf_projection),",
    "  et.fpca_wild_bootstrap_simultaneous_frame(_etr_inf_sim),",
    "  et.fpca_wild_bootstrap_family_test_frame(_etr_inf_family),",
    "  et.fpca_wild_bootstrap_monte_carlo_diagnostic_frame(_etr_inf_mc)]"
  ),collapse="\n"),convert=FALSE)
  x<-.etr_wild_four_source_fixture()
  native<-list(etr_fpca_wild_bootstrap_projection_frame(x$projection),
    etr_fpca_wild_bootstrap_simultaneous_frame(x$simultaneous),
    etr_fpca_wild_bootstrap_family_test_frame(x$family),
    etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(x$mc))
  python<-reticulate::py_to_r(
    reticulate::py_get_attr(reticulate::py,"_etr_inf_python_frames"))
  expect_identical(length(native),4L)
  expect_identical(length(python),4L)
  for(i in seq_along(native)){
    expect_identical(names(native[[i]]),names(python[[i]]),
      info=paste("schema",i))
    expect_identical(nrow(native[[i]]),nrow(python[[i]]),
      info=paste("nrow",i))
    for(field in names(python[[i]])){
      a<-native[[i]][[field]];b<-python[[i]][[field]]
      if(is.numeric(a)&&is.numeric(b))
        expect_equal(as.numeric(a),as.numeric(b),tolerance=1e-12,
          info=paste("numeric",i,field))
      else
        expect_identical(as.character(a),as.character(b),
          info=paste("labels",i,field))
    }
  }
})
