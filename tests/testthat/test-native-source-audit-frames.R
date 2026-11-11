# Six read-only Python 1.2 source frame contracts: row ordering,
# missing values, source indices, variance-independent audit fields.
.etr_source_audit_frame_fixtures <- function(){
  participant<-list(participant_ids=c("p2","p1"),
    time=c(0,.5,1),dimension_name="y",
    random_intercept_functions=matrix(1:6/10,nrow=2L),
    random_slope_functions=matrix(11:16/10,nrow=2L),
    random_slope_predictor="cue")
  trial<-list(source_curve_ids=c("c2","c1"),
    curve_participant_ids=c("p1","p2"),
    curve_trial_ids=c("trial2","trial1"),
    trial_ids=c("p1/trial2","p2/trial1"),
    time=c(0,.5,1),trial_random_effect="functional_intercept",
    trial_random_effect_functions=matrix(1:6/5,nrow=2L))
  boot<-list(sampled_participant_indices=matrix(c(1L,0L,0L,1L),
      nrow=2L,byrow=TRUE),
    sampled_source_participant_ids=list(c("p2","p1"),c("p1","p2")),
    bootstrap_participant_ids=list(c("b0","b1"),c("b2","b3")),
    bootstrap_trial_audit=list(
      list(c("p2","b0","t9","bt0"),c("p1","b1","t0","bt1")),
      list(c("p1","b2","t0","bt2"))))
  m<-matrix(c(1,2,3,4),nrow=2L,byrow=TRUE)
  scan<-list(candidate_components=c(2L,3L),
    target_curve_ids=c("c2","c1"),
    reference_projections=m,reference_se=m/5,
    critical_values=m/2,lower=m-1,upper=m+1,
    centers=m+.2,widths=m/3)
  selection<-list(scan=scan,selected_components=c(2,NA_real_),
    selected_centers=c(1.2,NA_real_),
    selected_widths=c(.4,NA_real_),
    selected_lower=c(.8,NA_real_),
    selected_upper=c(1.6,NA_real_))
  list(participant=participant,trial=trial,boot=boot,
    scan=scan,selection=selection)
}

test_that("source frames reproduce participant/trial and bootstrap row order",{
  x<-.etr_source_audit_frame_fixtures()
  a<-etr_functional_random_effect_frame(x$participant)
  expect_identical(names(a),c("participant_id","time","dimension",
    "effect","random_slope_predictor","estimate"))
  expect_equal(nrow(a),6L)
  expect_identical(a$participant_id,c(rep("p2",3L),rep("p1",3L)))
  expect_equal(a$estimate,c(.1,.3,.5,.2,.4,.6))
  expect_true(all(is.na(a$random_slope_predictor)))
  slope<-etr_functional_random_effect_frame(x$participant,"slope")
  expect_equal(slope$estimate,c(1.1,1.3,1.5,1.2,1.4,1.6))
  expect_identical(unique(slope$random_slope_predictor),"cue")
  expect_error(etr_functional_random_effect_frame(x$participant,"other"),
    "effect")
  bad<-x$participant;bad$random_slope_functions<-NULL
  expect_error(etr_functional_random_effect_frame(bad,"slope"),
    "random functional slope")
  trial<-etr_functional_trial_random_effect_frame(x$trial)
  expect_identical(names(trial),c("curve_index","curve_id",
    "participant_id","source_trial_id","trial_id","time","effect","value"))
  expect_equal(trial$curve_index,c(rep(0L,3L),rep(1L,3L)))
  expect_equal(trial$value,c(.2,.6,1,.4,.8,1.2))
  bad<-x$trial;bad$trial_random_effect<-"none"
  expect_error(etr_functional_trial_random_effect_frame(bad),
    "random intercept")
  bootstrap<-etr_functional_mixed_effects_full_refit_audit_frame(x$boot)
  expect_equal(bootstrap$bootstrap_replicate,c(0L,0L,1L,1L))
  expect_equal(bootstrap$draw_index,c(0L,1L,0L,1L))
  expect_equal(bootstrap$source_participant_index,c(1L,0L,0L,1L))
  expect_identical(bootstrap$bootstrap_participant_id,
    c("b0","b1","b2","b3"))
  bt<-etr_functional_mixed_effects_full_refit_trial_audit_frame(x$boot)
  expect_equal(bt$bootstrap_replicate,c(0L,0L,1L))
  expect_identical(bt$bootstrap_trial_id,c("bt0","bt1","bt2"))
  blank<-x$boot;blank$bootstrap_trial_audit<-list()
  expect_identical(nrow(
    etr_functional_mixed_effects_full_refit_trial_audit_frame(blank)),0L)
  bad<-x$boot;bad$sampled_participant_indices[1L,1L]<--1L
  expect_error(etr_functional_mixed_effects_full_refit_audit_frame(bad),
    "nonnegative")
})

test_that("wild bootstrap audit frames preserve NumPy candidate-major order",{
  x<-.etr_source_audit_frame_fixtures()
  scan<-etr_fpca_wild_bootstrap_truncation_scan_frame(x$scan)
  expect_identical(names(scan),c("curve_id","inference_components",
    "reference_projection","heteroscedastic_se","critical_value",
    "lower","upper","center","width"))
  expect_identical(scan$curve_id,c("c2","c1","c2","c1"))
  expect_equal(scan$inference_components,c(2L,2L,3L,3L))
  expect_equal(scan$reference_projection,c(1,2,3,4))
  selected<-etr_fpca_wild_bootstrap_truncation_selection_frame(x$selection)
  expect_identical(names(selected),c("curve_id",
    "selected_inference_components","selected_center",
    "selected_width","selected_lower","selected_upper"))
  expect_true(is.na(selected$selected_inference_components[2L]))
  expect_identical(selected$selected_inference_components[1L],2L)
  bad<-x$scan;bad$reference_se<-matrix(1,nrow=1L,ncol=2L)
  expect_error(etr_fpca_wild_bootstrap_truncation_scan_frame(bad),
    "expected shape")
  bad<-x$selection;bad$selected_components<-c(0,NA_real_)
  expect_error(etr_fpca_wild_bootstrap_truncation_selection_frame(bad),
    "positive integers")
})

test_that("six source frames are mapped with explicit noncertified boundaries",{
  catalog<-etr_native_parity_catalog()
  keys<-c("functional_random_effect_frame",
    "functional_trial_random_effect_frame",
    "functional_mixed_effects_full_refit_audit_frame",
    "functional_mixed_effects_full_refit_trial_audit_frame",
    "fpca_wild_bootstrap_truncation_scan_frame",
    "fpca_wild_bootstrap_truncation_selection_frame")
  for(nm in keys){
    row<-catalog[catalog$is_python_function&
      catalog$python_name==nm,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",nm))
    expect_true(row$native_implementation_started)
    gap_ledger<-utils::read.csv(system.file("extdata",
      "native_source_contract_gaps_stage22.csv",
      package="eyetrajectories"),stringsAsFactors=FALSE)
    ledger_row<-gap_ledger[gap_ledger$python_name==nm,,drop=FALSE]
    expect_equal(nrow(ledger_row),1L)
    expect_identical(row$source_contract_gap_unresolved,
      ledger_row$unresolved_source_gap)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_gte(sum(catalog$is_python_function&
    catalog$named_native_candidate),332L)
  expect_gte(sum(catalog$native_implementation_started),307L)
  expect_gte(sum(catalog$source_contract_gap_unresolved),154L)
})

test_that("pinned published Python source frame oracle agrees on six fixtures",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("six published Python 1.2 audit frame oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _et_record(cls, **kwargs):
    x=object.__new__(cls)
    for k,v in kwargs.items():
        object.__setattr__(x,k,v)
    return x
_a_part=_et_record(et.FunctionalMixedEffectsResult,
    participant_ids=('p2','p1'),time=np.array([0.,.5,1.]),
    dimension_name='y',
    random_intercept_functions=np.arange(1.,7.).reshape((2,3),order='F')/10.,
    random_slope_functions=np.arange(11.,17.).reshape((2,3),order='F')/10.,
    random_slope_predictor='cue')
_a_trial=_et_record(et.FunctionalMixedEffectsResult,
    source_curve_ids=('c2','c1'),
    curve_participant_ids=('p1','p2'),
    curve_trial_ids=('trial2','trial1'),
    trial_ids=('p1/trial2','p2/trial1'),
    time=np.array([0.,.5,1.]),trial_random_effect='functional_intercept',
    trial_random_effect_functions=np.arange(1.,7.).reshape((2,3),order='F')/5.)
_a_boot=_et_record(et.FunctionalMixedEffectsFullRefitBootstrapResult,
    # The frozen Python dataclass computes n_bootstrap from this field;
    # sampling history alone does not satisfy its published source property.
    bootstrap_coefficient_functions=np.zeros((2,1,1),dtype=float),
    sampled_participant_indices=np.array([[1,0],[0,1]],dtype=int),
    sampled_source_participant_ids=(('p2','p1'),('p1','p2')),
    bootstrap_participant_ids=(('b0','b1'),('b2','b3')),
    bootstrap_trial_audit=(
      (('p2','b0','t9','bt0'),('p1','b1','t0','bt1')),
      (('p1','b2','t0','bt2'),)))
_a_mat=np.array([[1.,2.],[3.,4.]])
_a_scan=_et_record(et.FPCAWildBootstrapTruncationScanResult,
    candidate_components=(2,3),target_curve_ids=('c2','c1'),
    reference_projections=_a_mat,reference_se=_a_mat/5.,
    critical_values=_a_mat/2.,lower=_a_mat-1.,upper=_a_mat+1.,
    centers=_a_mat+.2,widths=_a_mat/3.)
_a_sel=_et_record(et.FPCAWildBootstrapTruncationSelectionResult,
    scan=_a_scan,selected_components=np.array([2.,np.nan]),
    selected_centers=np.array([1.2,np.nan]),
    selected_widths=np.array([.4,np.nan]),
    selected_lower=np.array([.8,np.nan]),
    selected_upper=np.array([1.6,np.nan]))
_a_frames=[
    et.functional_random_effect_frame(_a_part),
    et.functional_random_effect_frame(_a_part,effect='slope'),
    et.functional_trial_random_effect_frame(_a_trial),
    et.functional_mixed_effects_full_refit_audit_frame(_a_boot),
    et.functional_mixed_effects_full_refit_trial_audit_frame(_a_boot),
    et.fpca_wild_bootstrap_truncation_scan_frame(_a_scan),
    et.fpca_wild_bootstrap_truncation_selection_frame(_a_sel)]
",convert=FALSE)
  x<-.etr_source_audit_frame_fixtures()
  native<-list(
    etr_functional_random_effect_frame(x$participant),
    etr_functional_random_effect_frame(x$participant,"slope"),
    etr_functional_trial_random_effect_frame(x$trial),
    etr_functional_mixed_effects_full_refit_audit_frame(x$boot),
    etr_functional_mixed_effects_full_refit_trial_audit_frame(x$boot),
    etr_fpca_wild_bootstrap_truncation_scan_frame(x$scan),
    etr_fpca_wild_bootstrap_truncation_selection_frame(x$selection))
  pyframes<-reticulate::py_to_r(
    reticulate::py_get_attr(reticulate::py,"_a_frames"))
  expect_length(pyframes,length(native))
  for(i in seq_along(native)){
    p<-pyframes[[i]];n<-native[[i]]
    expect_identical(names(n),names(p),info=paste("frame",i))
    expect_equal(nrow(n),nrow(p),info=paste("frame",i))
    for(col in names(p)){
      if(is.numeric(p[[col]]))
        expect_equal(as.numeric(n[[col]]),as.numeric(p[[col]]),
          tolerance=1e-12,info=paste("frame",i,col))
      else expect_equal(as.character(n[[col]]),as.character(p[[col]]),
        info=paste("frame",i,col))
    }
  }
})
