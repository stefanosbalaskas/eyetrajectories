# Frozen eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# recovery.py::evaluate_functional_mixed_effects_recovery
# Tests complete registered recovery assessment frames and scientific provenance.

.etr_mixed_5_source_fixture <- function(variant){
  stopifnot(variant%in%c("participant","trial","zero","multichannel","unicode"))
  t<-c(0,.5,1)
  multichannel<-variant=="multichannel"
  unicode<-variant=="unicode"
  trial<-variant=="trial"
  zero<-variant=="zero"
  nd<-if(multichannel)2L else 1L
  nm<-if(multichannel)2L else 1L
  dm<-if(multichannel)c("x","y") else "x"
  tm<-if(multichannel)cbind(c(.2,.3,.4),c(.5,.6,.7))
    else matrix(c(.2,.3,.4),ncol=1L)
  phi<-array(0,dim=c(nm,3L,nd))
  phi[1L,,]<-1
  if(multichannel){
    phi[2L,,1L]<-t
    phi[2L,,2L]<- -t
  }
  peig<-if(multichannel)c(.4,.2) else if(zero)0 else 2
  teig<-if(multichannel)c(0,0) else if(trial).5 else 0
  truth<-list(truth_grid=t,dimension_names=dm,mean=tm,
    eigenfunctions=phi,participant_eigenvalues=peig,
    trial_eigenvalues=teig)
  coefficients<-if(multichannel)c("Slope","Intercept") else
    if(unicode)"fish's β" else "Intercept"
  fixed<-if(multichannel)
    rbind(c(1,1,1),c(.55,.65,.75)) else
    matrix(c(.1,.4,.45),nrow=1L)
  basis<-if(multichannel)cbind(rep(1,3L),t) else matrix(1,3L,1L)
  covar<-if(multichannel)diag(c(.4,.2)) else
    matrix(if(zero)0 else 2,1L,1L)
  fit<-list(time=t,dimension_name=if(multichannel)"y" else "x",
    coefficient_names=coefficients,coefficient_functions=fixed,
    random_slope_predictor=NULL,random_basis=basis,
    random_intercept_covariance=covar,
    trial_random_effect=if(trial)"functional_intercept" else NULL)
  if(trial){
    fit$trial_random_basis<-matrix(1,3L,1L)
    fit$trial_random_effect_covariance<-matrix(.75,1L,1L)
  }
  list(truth=truth,fit=fit,intercept_name=if(unicode)"fish's β"
    else "Intercept")
}

test_that("mixed-effects source variance contracts cover five independent domains",{
  for(variant in c("participant","trial","zero","multichannel","unicode")){
    z<-.etr_mixed_5_source_fixture(variant)
    assessment<-etr_evaluate_functional_mixed_effects_recovery(
      z$fit,z$truth,intercept_name=z$intercept_name)
    expect_s3_class(assessment,"etr_functional_recovery_assessment")
    frame<-etr_functional_recovery_assessment_frame(assessment,
      python_boundary_mode=TRUE)
    expect_identical(names(frame),c("metric","value","component",
      "source","quantity","direction","units","scope","description"))
    expect_identical(frame$metric[[1L]],"coefficient_function_ise")
    expect_identical(frame$source[[1L]],"intercept")
    expect_identical(assessment$provenance$intercept_name,
      z$intercept_name)
    expect_true(all(is.finite(frame$value)))
    expect_true(all(frame$value>=0))
    expect_identical(assessment$provenance$trial_variance_target,
      "time_domain_variance_function")
    if(variant=="trial"){
      expect_identical(sum(frame$source=="trial"),3L)
      expect_identical(nrow(frame),7L)
    }else expect_identical(nrow(frame),if(variant=="zero")3L else 4L)
    if(variant=="zero"){
      expect_false("source_integrated_variance_relative_error"%in%
        frame$metric)
    }
    if(variant=="multichannel")
      expect_equal(frame$value[[1L]],.0025,tolerance=1e-14)
  }
})

test_that("mixed source evaluator rejects absent intercepts and invented variance effects",{
  z<-.etr_mixed_5_source_fixture("trial")
  bad<-z$fit;bad$trial_random_effect<-NULL
  expect_error(etr_evaluate_functional_mixed_effects_recovery(
    bad,z$truth),"truth contains trial functional variance")
  bad<-z$fit;bad$random_slope_predictor<-"dose"
  expect_error(etr_evaluate_functional_mixed_effects_recovery(
    bad,z$truth),"random intercepts only")
  bad<-z$fit;bad$random_intercept_covariance<-matrix(0,2L,2L)
  expect_error(etr_evaluate_functional_mixed_effects_recovery(
    bad,z$truth),"basis covariance")
  bad<-z$fit;bad$time[2L]<-.45
  expect_error(etr_evaluate_functional_mixed_effects_recovery(
    bad,z$truth),"truth.truth_grid exactly")
  expect_error(etr_evaluate_functional_mixed_effects_recovery(
    z$fit,z$truth,intercept_name="missing"),"absent from fitted model")
})

test_that("five complete frozen Python 1.2 mixed recovery assessments match native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 exact typed source replay opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth",
    "def _etr_mix_make(cls,**fields):",
    "    z=object.__new__(cls)",
    "    for k,v in fields.items():object.__setattr__(z,k,v)",
    "    return z",
    "def _etr_mix_recovery(variant):",
    "    t=np.array([0.,.5,1.]);multi=variant=='multichannel'",
    "    trial=variant=='trial';zero=variant=='zero'",
    "    unicode=variant=='unicode'",
    "    dm=('x','y') if multi else ('x',)",
    "    mean=np.array([[.2,.5],[.3,.6],[.4,.7]]) if multi",
    "      else np.array([[.2],[.3],[.4]])",
    "    phi=np.zeros((2,3,2)) if multi else np.ones((1,3,1))",
    "    if multi:",
    "      phi[0,:,:]=1.;phi[1,:,0]=t;phi[1,:,1]=-t",
    "    truth=_etr_mix_make(FunctionalSimulationTruth,",
    "      truth_grid=t,dimension_names=dm,mean=mean,",
    "      eigenfunctions=phi,",
    "      participant_eigenvalues=np.array([.4,.2]) if multi",
    "        else np.array([0. if zero else 2.]),",
    "      trial_eigenvalues=np.array([0.,0.]) if multi",
    "        else np.array([.5 if trial else 0.]))",
    "    intercept=\"fish's β\" if unicode else 'Intercept'",
    "    coefficient_names=('Slope','Intercept') if multi",
    "      else (intercept,)",
    "    fixed=np.array([[1.,1.,1.],[.55,.65,.75]]) if multi",
    "      else np.array([[.1,.4,.45]])",
    "    basis=np.column_stack([np.ones(3),t]) if multi",
    "      else np.ones((3,1))",
    "    cov=np.diag([.4,.2]) if multi",
    "      else np.array([[0. if zero else 2.]])",
    "    fields=dict(time=t,dimension_name='y' if multi else 'x',",
    "      coefficient_names=coefficient_names,",
    "      coefficient_functions=fixed,random_slope_predictor=None,",
    "      random_basis=basis,random_intercept_covariance=cov,",
    "      trial_random_effect='functional_intercept' if trial else None)",
    "    if trial:",
    "      fields['trial_random_basis']=np.ones((3,1))",
    "      fields['trial_random_effect_covariance']=np.array([[.75]])",
    "    fit=_etr_mix_make(et.FunctionalMixedEffectsResult,**fields)",
    "    value=et.evaluate_functional_mixed_effects_recovery(",
    "      fit,truth,intercept_name=intercept)",
    "    return (et.functional_recovery_assessment_frame(value),",
    "      dict(value.provenance))"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_mix_recovery")
  for(variant in c("participant","trial","zero","multichannel","unicode")){
    z<-.etr_mixed_5_source_fixture(variant)
    assessment<-etr_evaluate_functional_mixed_effects_recovery(
      z$fit,z$truth,intercept_name=z$intercept_name)
    pair<-reticulate::py_call(oracle,variant)
    expected<-reticulate::py_to_r(reticulate::py_get_item(pair,0L))
    prov<-reticulate::py_to_r(reticulate::py_get_item(pair,1L))
    frame<-etr_functional_recovery_assessment_frame(assessment,
      python_boundary_mode=TRUE)
    expect_identical(names(frame),names(expected),info=variant)
    expect_identical(nrow(frame),nrow(expected),info=variant)
    for(name in names(frame)){
      a<-frame[[name]];b<-expected[[name]]
      expect_identical(is.na(a),is.na(b),
        info=paste(variant,name,"missingness"))
      if(is.numeric(a)&&is.numeric(b))
        expect_equal(as.numeric(a),as.numeric(b),tolerance=1e-12,
          info=paste(variant,name))
      else expect_identical(as.character(a),as.character(b),
        info=paste(variant,name))
    }
    expect_identical(names(assessment$provenance),names(prov),
      info=paste(variant,"provenance names"))
    for(name in names(prov)){
      actual<-assessment$provenance[[name]]
      expected_value<-prov[[name]]
      if(is.null(actual))expect_null(expected_value)
      else if(is.numeric(actual)&&is.numeric(expected_value))
        expect_equal(actual,expected_value,tolerance=1e-14)
      else expect_identical(as.character(actual),
        as.character(expected_value),info=paste(variant,name))
    }
  }
})
