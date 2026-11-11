# Full field-by-field source audit: frozen Python eyetrajectoriespy==1.2.0
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Python dataclass / pandas identity differs from native R S3 / data.frame.

.etr_source_blup_frame_pair_fixture<-function() {
  time<-c(0,.5,1)
  participant<-list(
    participant_ids=c("p02","p01"),time=time,dimension_name="AOI",
    random_intercept_functions=matrix(c(.1,.2,.3,.4,.5,.6),
      nrow=2L,byrow=TRUE),
    random_slope_functions=matrix(c(-.3,0,.3,-.6,0,.6),
      nrow=2L,byrow=TRUE),
    random_slope_predictor="condition")
  trial<-list(
    source_curve_ids=c("c02","c01"),
    curve_participant_ids=c("p02","p01"),
    curve_trial_ids=c("trialB","trialA"),
    trial_ids=c("p02::trialB","p01::trialA"),
    time=time,trial_random_effect="functional_intercept",
    trial_random_effect_functions=matrix(
      c(.11,.12,.13,.21,.22,.23),nrow=2L,byrow=TRUE))
  list(participant=participant,trial=trial)
}

test_that("participant BLUP source frames preserve id/time-major rows and nullable slope metadata",{
  z<-.etr_source_blup_frame_pair_fixture()
  i<-etr_functional_random_effect_frame(z$participant)
  s<-etr_functional_random_effect_frame(z$participant,effect="slope")
  expect_identical(names(i),c("participant_id","time","dimension",
    "effect","random_slope_predictor","estimate"))
  expect_identical(i$participant_id,c(rep("p02",3L),rep("p01",3L)))
  expect_equal(i$time,rep(c(0,.5,1),times=2L),tolerance=0)
  expect_identical(i$effect,rep("intercept",6L))
  expect_true(all(is.na(i$random_slope_predictor)))
  expect_equal(i$estimate,c(.1,.2,.3,.4,.5,.6),tolerance=0)
  expect_identical(s$random_slope_predictor,rep("condition",6L))
  expect_equal(s$estimate,c(-.3,0,.3,-.6,0,.6),tolerance=0)

  z$participant$random_slope_predictor<-NULL
  optional<-etr_functional_random_effect_frame(z$participant,effect="slope")
  expect_identical(optional$estimate,s$estimate)
  expect_true(all(is.na(optional$random_slope_predictor)))
  z$participant$random_slope_functions<-NULL
  expect_error(etr_functional_random_effect_frame(
    z$participant,effect="slope"),"random functional slope")
  expect_error(etr_functional_random_effect_frame(
    z$participant,effect="unknown"),"effect must")
})

test_that("trial BLUP frame preserves zero-based curve index and nested source provenance",{
  z<-.etr_source_blup_frame_pair_fixture()
  actual<-etr_functional_trial_random_effect_frame(z$trial)
  expect_identical(names(actual),c("curve_index","curve_id",
    "participant_id","source_trial_id","trial_id","time","effect","value"))
  expect_identical(actual$curve_index,c(0L,0L,0L,1L,1L,1L))
  expect_identical(actual$curve_id,c(rep("c02",3L),rep("c01",3L)))
  expect_identical(actual$participant_id,
    c(rep("p02",3L),rep("p01",3L)))
  expect_identical(actual$source_trial_id,
    c(rep("trialB",3L),rep("trialA",3L)))
  expect_identical(actual$trial_id,
    c(rep("p02::trialB",3L),rep("p01::trialA",3L)))
  expect_equal(actual$time,rep(c(0,.5,1),2L),tolerance=0)
  expect_identical(unique(actual$effect),"trial_functional_intercept")
  expect_equal(actual$value,c(.11,.12,.13,.21,.22,.23),tolerance=0)
  z$trial$trial_random_effect<-NULL
  expect_error(etr_functional_trial_random_effect_frame(
    z$trial),"trial functional random intercept")
  z$trial$trial_random_effect<-"functional_intercept"
  z$trial$trial_random_effect_functions[1L,1L]<-Inf
  expect_error(etr_functional_trial_random_effect_frame(z$trial),
    "finite matrix")
})

test_that("two typed Python 1.2 FunctionalMixedEffectsResult BLUP frames match native cellwise",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 typed mixed frame source oracle is opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_frozen_blup_record(**fields):",
    "    obj=object.__new__(et.FunctionalMixedEffectsResult)",
    "    for k,v in fields.items():object.__setattr__(obj,k,v)",
    "    return obj",
    "_etr_blup_part=_etr_frozen_blup_record(",
    "    participant_ids=('p02','p01'),time=np.array([0.,.5,1.]),",
    "    dimension_name='AOI',random_slope_predictor='condition',",
    "    random_intercept_functions=np.array([[.1,.2,.3],[.4,.5,.6]]),",
    "    random_slope_functions=np.array([[-.3,0.,.3],[-.6,0.,.6]]))",
    "_etr_blup_trial=_etr_frozen_blup_record(",
    "    source_curve_ids=('c02','c01'),",
    "    curve_participant_ids=('p02','p01'),",
    "    curve_trial_ids=('trialB','trialA'),",
    "    trial_ids=('p02::trialB','p01::trialA'),",
    "    time=np.array([0.,.5,1.]),",
    "    trial_random_effect='functional_intercept',",
    "    trial_random_effect_functions=np.array([[.11,.12,.13],[.21,.22,.23]]))",
    "_etr_blup_py_intercept=et.functional_random_effect_frame(_etr_blup_part)",
    "_etr_blup_py_slope=et.functional_random_effect_frame(_etr_blup_part,effect='slope')",
    "_etr_blup_py_trial=et.functional_trial_random_effect_frame(_etr_blup_trial)",
    "object.__setattr__(_etr_blup_part,'random_slope_predictor',None)",
    "_etr_blup_py_missing_pred=et.functional_random_effect_frame(_etr_blup_part,effect='slope')"
  ),collapse="\n"),convert=FALSE)
  z<-.etr_source_blup_frame_pair_fixture()
  comparisons<-list(
    list(name="intercept",n=etr_functional_random_effect_frame(z$participant),
      python="_etr_blup_py_intercept"),
    list(name="slope",n=etr_functional_random_effect_frame(
      z$participant,effect="slope"),python="_etr_blup_py_slope"),
    list(name="trial",n=etr_functional_trial_random_effect_frame(z$trial),
      python="_etr_blup_py_trial"))
  z$participant$random_slope_predictor<-NULL
  comparisons[[4L]]<-list(name="nullable slope predictor",
    n=etr_functional_random_effect_frame(z$participant,effect="slope"),
    python="_etr_blup_py_missing_pred")
  for(pair in comparisons){
    py<-reticulate::py_eval(pair$python,convert=FALSE)
    source<-as.data.frame(et_to_r(py),check.names=FALSE)
    native<-pair$n
    expect_identical(names(source),names(native),info=pair$name)
    expect_identical(nrow(source),nrow(native),info=pair$name)
    for(nm in names(source)){
      observed<-source[[nm]]
      expect_equal(unname(native[[nm]]),unname(observed),tolerance=0,
        info=paste(pair$name,nm))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
