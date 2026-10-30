# Frozen Python 1.2 source oracles and deterministic R witnesses for
# stabilized-volatility FPCR selection and projection, simultaneous,
# fixed-family and Monte Carlo inference reporting.
.etr_wild_source_test_fixtures <- function(){
  widths<-cbind(c(5,4,3.95,3.9,3.85),c(5,7,5,7,5))
  centers<-cbind(c(1,1.5,1.53,1.55,1.58),0:4)
  scan<-list(candidate_components=2:6,
    target_curve_ids=c("a","b"),widths=widths,centers=centers,
    lower=centers-widths/2,upper=centers+widths/2,
    provenance=list(frozen_source="Python 1.2"))
  projection<-list(target_curve_ids=c("a","b"),
    reference_projection=c(1,2),reference_se=c(.2,.3),
    pseudo_truth_projection=c(.9,1.8),
    critical_values=c(1.8,2.1),
    lower=c(.64,1.37),upper=c(1.36,2.63))
  simultaneous<-list(projection_result=projection,
    targetwise_critical_values=c(1.5,1.7),critical_value=2.2,
    lower=c(.56,1.34),upper=c(1.44,2.66))
  family<-list(projection_result=projection,
    null_values=c(0,0),observed_statistics=c(2.5,3.1),
    targetwise_p_values=c(.02,.04),adjusted_p_values=c(.08,.09),
    reject_targetwise=c(TRUE,TRUE),reject_familywise=c(FALSE,FALSE),
    global_statistic=3.1,global_p_value=.08,
    significance_level=.05)
  mc<-list(family_test_result=family,
    targetwise_exceedances=c(1L,3L),
    targetwise_tail_probabilities=c(.02,.04),
    targetwise_mcse=c(.01,.02),
    targetwise_interval_lower=c(.01,.02),
    targetwise_interval_upper=c(.05,.08),
    targetwise_decision_stable=c(FALSE,TRUE),
    adjusted_exceedances=c(7L,8L),
    adjusted_tail_probabilities=c(.08,.09),
    adjusted_mcse=c(.03,.03),
    adjusted_interval_lower=c(.05,.06),
    adjusted_interval_upper=c(.12,.13),
    adjusted_decision_stable=c(TRUE,FALSE))
  list(scan=scan,projection=projection,simultaneous=simultaneous,
    family=family,mc=mc)
}

test_that("earliest target-specific stable transition run is selected exactly",{
  x<-.etr_wild_source_test_fixtures()
  s<-etr_select_fpca_wild_bootstrap_truncation(
    x$scan,.1,.05,1L,on_failure="ignore")
  expect_identical(s$selected_candidate_indices,c(1L,-1L))
  expect_equal(s$selected_components,c(3,NaN))
  expect_equal(s$selected_widths[1],4)
  expect_equal(s$selected_centers[1],1.5)
  expect_equal(s$selected_lower[1],x$scan$lower[2L,1L])
  expect_equal(s$selected_upper[1],x$scan$upper[2L,1L])
  expect_identical(dim(s$stable_both),c(4L,2L))
  expect_identical(s$stable_both[,1],c(FALSE,TRUE,TRUE,TRUE))
  expect_false(any(s$stable_both[,2]))
  expect_equal(s$width_changes[,1],c(1,.05,.05,.05),
    tolerance=1e-12)
  expect_identical(s$provenance$fpca_wild_bootstrap_truncation_selection$
    required_consecutive_stable_transitions,2L)
  expect_false(s$provenance$fpca_wild_bootstrap_truncation_selection$
    silent_largest_h_fallback)
  frame<-etr_fpca_wild_bootstrap_truncation_selection_frame(s)
  expect_identical(nrow(frame),2L)
  expect_identical(frame$selected_inference_components[1],3L)
  expect_true(is.na(frame$selected_inference_components[2]))
  expect_error(etr_select_fpca_wild_bootstrap_truncation(
    x$scan,.1,.05,1L),"no qualifying run")
  expect_warning(etr_select_fpca_wild_bootstrap_truncation(
    x$scan,.1,.05,1L,on_failure="warn"),"no qualifying run")
  all_stable<-etr_select_fpca_wild_bootstrap_truncation(
    x$scan,100,100,0L,on_failure="error")
  expect_identical(all_stable$selected_candidate_indices,c(0L,0L))
  expect_equal(all_stable$selected_components,c(2,2))
})

test_that("source selection fails closed for thresholds, runs and grids",{
  x<-.etr_wild_source_test_fixtures()
  f<-function(...)etr_select_fpca_wild_bootstrap_truncation(
    x$scan,...)
  expect_error(f(0,.1,0L),"width_threshold")
  expect_error(f(.1,-.1,0L),"center_threshold")
  expect_error(f(.1,.1,-1L),"stability_run")
  expect_error(f(.1,.1,4L),"more consecutive")
  expect_error(f(.1,.1,1L,on_failure="fallback"),"on_failure")
  bad<-x$scan;bad$centers<-matrix(1,nrow=2L,ncol=2L)
  expect_error(etr_select_fpca_wild_bootstrap_truncation(
    bad,.1,.1,1L),"expected shape")
  bad<-x$scan;bad$widths[2L,1L]<-NA_real_
  expect_error(etr_select_fpca_wild_bootstrap_truncation(
    bad,.1,.1,1L),"finite")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("wild inference frames retain exact source order and identities",{
  x<-.etr_wild_source_test_fixtures()
  p<-etr_fpca_wild_bootstrap_projection_frame(x$projection)
  expect_identical(names(p),c("curve_id","reference_projection",
    "pseudo_truth_projection","heteroscedastic_se","critical_value",
    "lower","upper"))
  expect_equal(p$reference_projection,c(1,2))
  sim<-etr_fpca_wild_bootstrap_simultaneous_frame(x$simultaneous)
  expect_identical(names(sim),c("curve_id","reference_projection",
    "heteroscedastic_se","targetwise_critical_value",
    "familywise_critical_value","targetwise_lower","targetwise_upper",
    "simultaneous_lower","simultaneous_upper"))
  expect_equal(sim$targetwise_lower,c(.7,1.49))
  expect_equal(sim$targetwise_upper,c(1.3,2.51))
  fam<-etr_fpca_wild_bootstrap_family_test_frame(x$family)
  expect_identical(names(fam),c("curve_id","reference_projection",
    "null_value","heteroscedastic_se","observed_statistic",
    "targetwise_p_value","adjusted_p_value","reject_targetwise",
    "reject_familywise","global_statistic","global_p_value"))
  expect_true(all(fam$reject_targetwise))
  expect_false(any(fam$reject_familywise))
  expect_equal(fam$global_p_value,c(.08,.08))
  mc<-etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(x$mc)
  expect_equal(nrow(mc),2L)
  expect_identical(mc$targetwise_precision_status,
    c("monte_carlo_sensitive","stable_reject"))
  expect_identical(mc$adjusted_precision_status,
    c("stable_non_reject","monte_carlo_sensitive"))
  expect_equal(mc$alpha,c(.05,.05))
  expect_equal(mc$targetwise_exceedances,c(1L,3L))
  expect_equal(mc$reported_adjusted_p_value,c(.08,.09))
  bad<-x$family;bad$adjusted_p_values[1L]<-1.2
  expect_error(etr_fpca_wild_bootstrap_family_test_frame(bad),
    "adjusted_p_values")
})

test_that("five true source operations remain explicitly uncertified",{
  z<-etr_native_parity_catalog()
  for(nm in c("select_fpca_wild_bootstrap_truncation",
    "fpca_wild_bootstrap_projection_frame",
    "fpca_wild_bootstrap_simultaneous_frame",
    "fpca_wild_bootstrap_family_test_frame",
    "fpca_wild_bootstrap_monte_carlo_diagnostic_frame")){
    row<-z[z$is_python_function&z$python_name==nm,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",nm))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$is_python_function&z$named_native_candidate),304L)
  expect_equal(sum(z$native_implementation_started),279L)
  expect_equal(sum(z$source_contract_gap_unresolved),126L)
})

test_that("frozen Python 1.2 selection and four inference tables agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 selection and inference-frame oracles opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _wt(cls,**kw):
    obj=object.__new__(cls)
    for name,value in kw.items():
        object.__setattr__(obj,name,value)
    return obj
_w=np.array([[5.,5.],[4.,7.],[3.95,5.],[3.9,7.],[3.85,5.]])
_c=np.array([[1.,0.],[1.5,1.],[1.53,2.],[1.55,3.],[1.58,4.]])
_s=_wt(et.FPCAWildBootstrapTruncationScanResult,
    candidate_components=(2,3,4,5,6),target_curve_ids=('a','b'),
    widths=_w,centers=_c,lower=_c-_w/2,upper=_c+_w/2,
    studentized_roots=np.zeros((5,2,2)),
    provenance={'frozen_source':'Python 1.2'})
_selection=et.select_fpca_wild_bootstrap_truncation(
    _s,width_threshold=.1,center_threshold=.05,stability_run=1,
    on_failure='ignore')
_projection=_wt(et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('a','b'),reference_projection=np.array([1.,2.]),
    reference_se=np.array([.2,.3]),
    pseudo_truth_projection=np.array([.9,1.8]),
    critical_values=np.array([1.8,2.1]),
    lower=np.array([.64,1.37]),upper=np.array([1.36,2.63]),
    bootstrap_projections=np.zeros((2,2)))
_sim=_wt(et.FPCAWildBootstrapSimultaneousResult,
    projection_result=_projection,
    targetwise_critical_values=np.array([1.5,1.7]),
    critical_value=2.2,lower=np.array([.56,1.34]),
    upper=np.array([1.44,2.66]))
_family=_wt(et.FPCAWildBootstrapFamilyTestResult,
    projection_result=_projection,
    null_values=np.array([0.,0.]),
    observed_statistics=np.array([2.5,3.1]),
    targetwise_p_values=np.array([.02,.04]),
    adjusted_p_values=np.array([.08,.09]),
    reject_targetwise=np.array([True,True]),
    reject_familywise=np.array([False,False]),
    global_statistic=3.1,global_p_value=.08,
    significance_level=.05)
_mc=_wt(et.FPCAWildBootstrapMonteCarloDiagnosticResult,
    family_test_result=_family,
    targetwise_exceedances=np.array([1,3]),
    targetwise_tail_probabilities=np.array([.02,.04]),
    targetwise_mcse=np.array([.01,.02]),
    targetwise_interval_lower=np.array([.01,.02]),
    targetwise_interval_upper=np.array([.05,.08]),
    targetwise_decision_stable=np.array([False,True]),
    adjusted_exceedances=np.array([7,8]),
    adjusted_tail_probabilities=np.array([.08,.09]),
    adjusted_mcse=np.array([.03,.03]),
    adjusted_interval_lower=np.array([.05,.06]),
    adjusted_interval_upper=np.array([.12,.13]),
    adjusted_decision_stable=np.array([True,False]))
_frames=[
    et.fpca_wild_bootstrap_projection_frame(_projection),
    et.fpca_wild_bootstrap_simultaneous_frame(_sim),
    et.fpca_wild_bootstrap_family_test_frame(_family),
    et.fpca_wild_bootstrap_monte_carlo_diagnostic_frame(_mc)]
",convert=FALSE)
  x<-.etr_wild_source_test_fixtures()
  py<-reticulate::py
  selection<-reticulate::py_get_attr(py,"_selection")
  native<-etr_select_fpca_wild_bootstrap_truncation(
    x$scan,.1,.05,1L,on_failure="ignore")
  for(nm in c("width_changes","center_changes","stable_width",
    "stable_center","stable_both","selected_candidate_indices",
    "selected_components","selected_centers","selected_widths",
    "selected_lower","selected_upper")){
    expected<-reticulate::py_to_r(reticulate::py_get_attr(selection,nm))
    expect_equal(native[[nm]],expected,tolerance=1e-12,info=nm)
  }
  source_provenance<-reticulate::py_to_r(
    reticulate::py_get_attr(selection,"provenance"))
  expect_equal(native$provenance,
    source_provenance,tolerance=1e-12)
  expected_frames<-reticulate::py_to_r(
    reticulate::py_get_attr(py,"_frames"))
  actual_frames<-list(
    etr_fpca_wild_bootstrap_projection_frame(x$projection),
    etr_fpca_wild_bootstrap_simultaneous_frame(x$simultaneous),
    etr_fpca_wild_bootstrap_family_test_frame(x$family),
    etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(x$mc))
  expect_length(expected_frames,4L)
  for(i in seq_along(actual_frames)){
    expect_identical(names(actual_frames[[i]]),
      names(expected_frames[[i]]),info=paste("frame columns",i))
    expect_equal(nrow(actual_frames[[i]]),
      nrow(expected_frames[[i]]),info=paste("frame rows",i))
    for(col in names(expected_frames[[i]]))
      expect_equal(actual_frames[[i]][[col]],
        expected_frames[[i]][[col]],tolerance=1e-12,
        info=paste("frame",i,col))
  }
})

test_that("72 randomized frozen Python 1.2 selection grids match native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("72 published Python 1.2 randomized selection witnesses are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_rng=np.random.default_rng(73173)
_selection_stress=[]
for k in range(72):
    h=np.arange(2,7+(k%4),dtype=int)
    n_targets=1+(k%3)
    w=np.maximum(.01,2+np.cumsum(
        _rng.normal(0,.18,size=(len(h),n_targets)),axis=0))
    c=np.cumsum(_rng.normal(0,.11,size=(len(h),n_targets)),axis=0)
    ids=tuple('target_'+str(j) for j in range(n_targets))
    scan=object.__new__(et.FPCAWildBootstrapTruncationScanResult)
    record={
        'candidate_components':tuple(int(x) for x in h),
        'target_curve_ids':ids,
        'widths':w,'centers':c,
        'lower':c-w/2,'upper':c+w/2,
        'studentized_roots':np.zeros((len(h),2,n_targets)),
        'provenance':{}}
    for key,value in record.items():
        object.__setattr__(scan,key,value)
    wt=(.04,.16,.33)[k%3]
    ct=(.03,.11,.23)[(k//3)%3]
    rr=(k//9)%3
    selected=et.select_fpca_wild_bootstrap_truncation(
        scan,width_threshold=wt,center_threshold=ct,
        stability_run=rr,on_failure='ignore')
    _selection_stress.append({
        'scan':record,'width_threshold':wt,
        'center_threshold':ct,'stability_run':rr,
        'indices':selected.selected_candidate_indices,
        'components':selected.selected_components,
        'centers':selected.selected_centers,
        'widths':selected.selected_widths,
        'lower':selected.selected_lower,
        'upper':selected.selected_upper,
        'stable_both':selected.stable_both})
",convert=FALSE)
  cases<-reticulate::py_to_r(
    reticulate::py_get_attr(reticulate::py,"_selection_stress"))
  expect_length(cases,72L)
  for(i in seq_along(cases)){
    v<-cases[[i]];scan<-v$scan
    got<-etr_select_fpca_wild_bootstrap_truncation(
      scan,width_threshold=v$width_threshold,
      center_threshold=v$center_threshold,
      stability_run=v$stability_run,on_failure="ignore")
    for(pair in list(
      c("selected_candidate_indices","indices"),
      c("selected_components","components"),
      c("selected_centers","centers"),
      c("selected_widths","widths"),
      c("selected_lower","lower"),
      c("selected_upper","upper"),
      c("stable_both","stable_both"))){
      expect_equal(got[[pair[[1L]]]],v[[pair[[2L]]]],
        tolerance=1e-11,info=paste("case",i,pair[[1L]]))
    }
    expect_true(all(got$selected_candidate_indices>=-1L))
    expect_false(any(is.finite(got$selected_components)&
      got$selected_candidate_indices<0L))
  }
})
