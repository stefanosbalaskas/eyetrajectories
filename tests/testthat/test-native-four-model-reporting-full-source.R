# Frozen eyetrajectoriespy==1.2.0 @ c1cd95ad718327550f7e55393ff38582872f7a94.
# Typed Python source dataclasses compared with checked Python-free R scientific records.
.etr_four_model_source_fixture<-function(variant="base"){
  stopifnot(variant %in% c("base","alternate","exposure"))
  alt<-identical(variant,"alternate")
  expo<-identical(variant,"exposure")
  fit<-list(
    dimension_name=if(alt)"fish's β" else "pupil",
    family=if(alt)"binomial" else "poisson",
    link=if(alt)"logit" else "log",basis_size=5L,
    binomial_denominators=if(alt)c(10,20) else NULL,
    exposure=if(expo)matrix(c(1,2,3,4),nrow=2) else NULL,
    exposure_units=if(expo)"fish's / tank" else NULL)
  band<-if(alt)list(
    reference=fit,confidence_level=.95,simultaneous_scope="coefficient",
    bootstrap=list(bootstrap_coefficient_functions=array(0,c(4L,2L,3L)))) else NULL
  residual<-list(trial_diagnostics=data.frame(
    lag_index=c(0L,1L,0L,1L),
    zero_residual_variance=c(FALSE,FALSE,TRUE,TRUE)),
    reference=list(
      random_slope_predictor=if(alt)"fish's β" else NULL,
      time_unit=if(alt)"sec's" else "seconds"),
    residual_scale=if(alt || expo)"whitened" else "raw",max_lag=1L)
  sparse_m<-list(
    dimensions=if(alt)c("fish's β","y") else c("x","y"),
    curve_ids=c("a","b"),n_components=2L,
    score_diagnostics=data.frame(status_code=c("ok","failed")),
    measurement_error_covariance=diag(2),
    covariance_diagnostics=list(
      requested_action=if(alt)"nearest's psd" else "nearest_psd",
      applied_action="none",correction_frobenius_norm=0),
    provenance=list(sparse_mfpca=list(
      mean_bandwidth=.2,covariance_bandwidth=.5,
      measurement_error_mode=if(alt)"diagonal's" else "diagonal",
      score_ridge=.001,score_failure_action="record")))
  sparse_u<-list(
    dimension=if(alt)"fish's β" else "pupil",
    n_components=2L,eigenvalues=c(.333,.111),
    provenance=list(sparse_fpca=list(
      backend=if(alt)"fdapy" else "native",
      sample_counts=c(3,6),evaluation_grid=c(0,.5,1),
      covariance_psd=list(applied_action="none",
        relative_operator_correction_frobenius_norm=.001),
      noise_variance_method="diagonal_difference",
      noise_support=c(0,1),score_ridge=.001,
      analysis_support=c(0,1),analysis_support_action="reject",
      outside_observation_count=0L,kwargs_mean=list(),kwargs_covariance=list())),
    score_diagnostics=data.frame(status_code=c("ok","failed"),
      condition_number=c(1.5,2.5)),
    fit_smoothing=NULL,score_smoothing=NULL,tolerance=.0001)
  list(fit=fit,band=band,residual=residual,sparse_m=sparse_m,sparse_u=sparse_u)
}
.etr_four_model_source_texts<-function(z,digits) {
  c(
    etr_generalized_function_on_scalar_reporting_text(z$fit,z$band),
    etr_functional_mixed_effects_residual_reporting_text(z$residual),
    etr_sparse_mfpca_reporting_text(z$sparse_m,digits=digits),
    etr_sparse_fpca_reporting_text(z$sparse_u,digits=digits))
}
test_that("four scientific model reports retain essential scientific caveats",{
  a<-.etr_four_model_source_texts(.etr_four_model_source_fixture(),3L)
  b<-.etr_four_model_source_texts(.etr_four_model_source_fixture("alternate"),3L)
  c<-.etr_four_model_source_texts(.etr_four_model_source_fixture("exposure"),3L)
  expect_identical(length(a),4L)
  expect_true(all(nzchar(a)))
  expect_match(a[[1L]],"population-averaged marginal interpretation",fixed=TRUE)
  expect_match(a[[1L]],"No simultaneous coefficient band was requested",fixed=TRUE)
  expect_match(b[[1L]],"grouped-binomial integer success counts",fixed=TRUE)
  expect_match(b[[1L]],"4 replicates",fixed=TRUE)
  expect_match(c[[1L]],"rate ratios holding exposure fixed",fixed=TRUE)
  expect_match(a[[2L]],"random functional intercept only",fixed=TRUE)
  expect_match(b[[2L]],'slope for "fish\'s β"',fixed=TRUE)
  expect_match(b[[2L]],'retained in "sec\'s"',fixed=TRUE)
  expect_match(b[[2L]],"Whitening targets the declared residual covariance",fixed=TRUE)
  expect_match(a[[3L]],"R_epsilon=",fixed=TRUE)
  expect_match(a[[3L]],"never a rank-K covariance reconstruction",fixed=TRUE)
  expect_match(b[[3L]],'PSD action "nearest\'s psd"',fixed=TRUE)
  expect_match(b[[3L]],'mode "diagonal\'s"',fixed=TRUE)
  expect_match(a[[4L]],"Raw sparse trajectories were not interpolated",fixed=TRUE)
  expect_match(b[[4L]],"using FDApy's covariance-operator estimator",fixed=TRUE)
})
test_that("four source reporting contracts reject malformed native scientific results",{
  z<-.etr_four_model_source_fixture()
  f<-z$fit;f$basis_size<-0
  expect_error(etr_generalized_function_on_scalar_reporting_text(f),"basis_size")
  r<-z$residual;r$residual_scale<-"unknown"
  expect_error(etr_functional_mixed_effects_residual_reporting_text(r),"residual_scale")
  r<-z$residual;r$trial_diagnostics$zero_residual_variance[1]<-NA
  expect_error(etr_functional_mixed_effects_residual_reporting_text(r),"trial_diagnostics")
  m<-z$sparse_m;m$measurement_error_covariance[1,1]<-Inf
  expect_error(etr_sparse_mfpca_reporting_text(m),"measurement_error_covariance")
  u<-z$sparse_u;u$eigenvalues[[1L]]<--1
  expect_error(etr_sparse_fpca_reporting_text(u),"eigenvalues")
  expect_error(etr_sparse_mfpca_reporting_text(z$sparse_m,digits=-1L),"digits")
  expect_error(etr_sparse_fpca_reporting_text(z$sparse_u,digits=-1L),"digits")
})
test_that("24 full typed frozen Python 1.2 source strings match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct pinned Python typed source oracles are opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import pandas as pd",
    "import eyetrajectoriespy as et",
    "def _etr_model_source_obj(cls,**fields):",
    "    x=object.__new__(cls)",
    "    for k,v in fields.items(): object.__setattr__(x,k,v)",
    "    return x",
    "def _etr_four_model_texts(variant,digits):",
    "    alt=(variant=='alternate'); expo=(variant=='exposure')",
    "    fit=_etr_model_source_obj(et.GeneralizedFunctionOnScalarResult,",
    "      dimension_name=\"fish's β\" if alt else 'pupil',",
    "      family='binomial' if alt else 'poisson',",
    "      link='logit' if alt else 'log',basis_size=5,",
    "      binomial_denominators=np.array([10,20]) if alt else None,",
    "      exposure=np.array([[1,3],[2,4]]) if expo else None,",
    "      exposure_units=\"fish's / tank\" if expo else None)",
    "    band=None",
    "    if alt:",
    "      bootstrap=_etr_model_source_obj(",
    "        et.GeneralizedFunctionOnScalarBootstrapResult,",
    "        bootstrap_coefficient_functions=np.zeros((4,2,3)))",
    "      band=_etr_model_source_obj(et.GeneralizedFunctionOnScalarBandResult,",
    "        reference=fit,confidence_level=.95,",
    "        simultaneous_scope='coefficient',bootstrap=bootstrap)",
    "    residual_ref=_etr_model_source_obj(et.FunctionalMixedEffectsResult,",
    "      random_slope_predictor=\"fish's β\" if alt else None,",
    "      time_unit=\"sec's\" if alt else 'seconds')",
    "    trial=pd.DataFrame({'lag_index':[0,1,0,1],",
    "      'zero_residual_variance':[False,False,True,True]})",
    "    residual=_etr_model_source_obj(et.FunctionalMixedEffectsResidualDiagnosticsResult,",
    "      trial_diagnostics=trial,reference=residual_ref,",
    "      residual_scale='whitened' if alt or expo else 'raw',max_lag=1)",
    "    sm=_etr_model_source_obj(et.SparseMFPCAResult,",
    "      dimensions=(\"fish's β\",'y') if alt else ('x','y'),",
    "      curve_ids=('a','b'),n_components=2,",
    "      score_diagnostics=pd.DataFrame({'status_code':['ok','failed']}),",
    "      measurement_error_covariance=np.eye(2),",
    "      covariance_diagnostics={'requested_action':\"nearest's psd\" if alt else 'nearest_psd',",
    "        'applied_action':'none','correction_frobenius_norm':0},",
    "      provenance={'sparse_mfpca':{'mean_bandwidth':.2,'covariance_bandwidth':.5,",
    "        'measurement_error_mode':\"diagonal's\" if alt else 'diagonal',",
    "        'score_ridge':.001,'score_failure_action':'record'}})",
    "    sparse_provenance={'backend':'fdapy' if alt else 'native',",
    "      'sample_counts':[3,6],'evaluation_grid':[0.,.5,1.],",
    "      'covariance_psd':{'applied_action':'none',",
    "        'relative_operator_correction_frobenius_norm':.001},",
    "      'noise_variance_method':'diagonal_difference',",
    "      'noise_support':[0.,1.],'score_ridge':.001,",
    "      'analysis_support':[0.,1.],'analysis_support_action':'reject',",
    "      'outside_observation_count':0,'kwargs_mean':{},'kwargs_covariance':{}}",
    "    su=_etr_model_source_obj(et.SparseFPCAResult,",
    "      dimension=\"fish's β\" if alt else 'pupil',",
    "      n_components=2,eigenvalues=np.array([.333,.111]),",
    "      provenance={'sparse_fpca':sparse_provenance},",
    "      score_diagnostics=pd.DataFrame({'status_code':['ok','failed'],",
    "        'condition_number':[1.5,2.5]}),",
    "      fit_smoothing=None,score_smoothing=None,tolerance=.0001)",
    "    return [",
    "      et.generalized_function_on_scalar_reporting_text(fit,band=band),",
    "      et.functional_mixed_effects_residual_reporting_text(residual),",
    "      et.sparse_mfpca_reporting_text(sm,digits=digits),",
    "      et.sparse_fpca_reporting_text(su,digits=digits)]"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_four_model_texts")
  for(variant in c("base","alternate","exposure")){
    z<-.etr_four_model_source_fixture(variant)
    for(digits in c(2L,5L)){
      expected<-reticulate::py_to_r(
        reticulate::py_call(oracle,variant,as.integer(digits)))
      actual<-.etr_four_model_source_texts(z,digits)
      expect_identical(length(actual),length(expected))
      for(i in seq_along(actual))
        expect_identical(actual[[i]],as.character(expected[[i]]),
          info=paste(variant,digits,i))
    }
  }
})
