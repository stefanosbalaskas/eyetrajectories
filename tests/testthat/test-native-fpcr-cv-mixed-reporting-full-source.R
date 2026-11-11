# Frozen eyetrajectoriespy==1.2.0 commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Compare typed Python scientific result reporting to Python-free native R.
.etr_two_report_source_fixture <- function(variant="base") {
  stopifnot(variant %in% c("base","conditional","full_refit"))
  alternate <- variant != "base"
  full <- variant == "full_refit"
  cv <- list(
    fold_losses=data.frame(n_components=c(1L,1L,1L,2L,2L,2L),
                           loss=c(.41,.43,.45,.32,.45,.49)),
    n_splits=3L,cv_unit=if(alternate)"curve" else "group",
    family=if(full)"binomial" else "gaussian",
    loss=if(full)"deviance" else "rmse")
  fit <- list(
    predictor_names=if(alternate)c("dose","time") else "dose",
    boundary_fit=alternate,
    trial_random_effect=if(full)"functional_intercept" else NULL,
    random_effect_singular=full,
    trial_random_effect_singular=full,
    random_effect_complexity_warning=full,
    residual_correlation_boundary_fit=full,
    residual_correlation_independence_limit_fit=FALSE,
    backend_warnings=if(alternate)"optimizer warning" else character(),
    random_slope_predictor=if(alternate)"dose's β" else NULL,
    random_basis_size=3L,
    residual_correlation=if(full)"exponential" else
      if(alternate)"ar1" else "iid",
    dimension_name=if(alternate)"fish's x" else "x",
    fixed_basis_size=4L,spline_degree=3L,n_curves=8L,
    n_participants=4L,reml=!full,method="lbfgs",
    random_effect_covariance_condition_number=7.123)
  if(alternate){
    fit$random_effect_dimension <- 6L
    fit$random_effect_covariance_parameter_count <- 21L
    fit$residual_correlation_parameter <- if(full)1.2345 else .25
  }
  if(full){
    fit$n_trials <- 8L
    fit$trial_random_basis_size <- 2L
    fit$trial_random_effect_covariance_parameter_count <- 3L
    fit$residual_correlation_parameter_unit <- "seconds"
  }
  band <- if(!alternate) NULL else list(
    reference=fit,confidence_level=.95,
    simultaneous_scope=if(full)"family" else "coefficient",
    bootstrap=list(
      bootstrap_type=if(full)"full_refit" else "conditional_covariance",
      bootstrap_coefficient_functions=array(0,c(4L,1L,2L))))
  list(cv=cv,fit=fit,band=band)
}
test_that("FPCR CV and mixed-effects source interpretations are preserved",{
  z<-.etr_two_report_source_fixture("base")
  expect_match(etr_fpca_regression_cv_reporting_text(z$cv),
    "family='gaussian'",fixed=TRUE)
  expect_match(etr_fpca_regression_cv_reporting_text(z$cv,rule="one_se"),
    "The one-standard-error rule was used as a parsimony heuristic",
    fixed=TRUE)
  expect_match(etr_functional_mixed_effects_reporting_text(z$fit),
    "pointwise Wald intervals",fixed=TRUE)
  z<-.etr_two_report_source_fixture("conditional")
  expect_match(etr_functional_mixed_effects_reporting_text(z$fit,z$band),
    'functional random slope for "dose\'s β"',fixed=TRUE)
  expect_match(etr_functional_mixed_effects_reporting_text(z$fit,z$band),
    "were held fixed",fixed=TRUE)
  z<-.etr_two_report_source_fixture("full_refit")
  expect_match(etr_functional_mixed_effects_reporting_text(z$fit,z$band),
    "variance-component re-estimation",fixed=TRUE)
  expect_match(etr_functional_mixed_effects_reporting_text(z$fit,z$band),
    "within-trial continuous-time exponential correlation",fixed=TRUE)
})
test_that("source reports reject invalid native scientific domains",{
  z<-.etr_two_report_source_fixture()
  expect_error(etr_fpca_regression_cv_reporting_text(z$cv,rule="bogus"),
    "rule")
  expect_error(etr_fpca_regression_cv_reporting_text(z$cv,digits=-1L),
    "digits")
  bad<-z$cv;bad$cv_unit<-"invalid"
  expect_error(etr_fpca_regression_cv_reporting_text(bad),"cv_unit")
  bad<-z$fit;bad$boundary_fit<-NA
  expect_error(etr_functional_mixed_effects_reporting_text(bad),
    "boundary_fit")
  bad<-z$fit;bad$residual_correlation<-"ar1"
  bad$residual_correlation_parameter<-NaN
  expect_error(etr_functional_mixed_effects_reporting_text(bad),
    "residual_correlation_parameter")
  z<-.etr_two_report_source_fixture("conditional")
  bad<-z$band
  bad$reference$dimension_name<-"different fit"
  expect_error(etr_functional_mixed_effects_reporting_text(z$fit,bad),
    "band.reference")
})
test_that("21 independent typed Python 1.2 full-source reporting cases match R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("typed frozen Python 1.2 source differential comparison opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import pandas as pd",
    "import eyetrajectoriespy as et",
    "def _etr_reports_obj(cls,**kw):",
    "    obj=object.__new__(cls)",
    "    for key,val in kw.items():object.__setattr__(obj,key,val)",
    "    return obj",
    "def _etr_two_report_source(variant,rule,digits):",
    "    alternate=variant!='base'; full=variant=='full_refit'",
    "    fold=pd.DataFrame({'n_components':[1,1,1,2,2,2],",
    "      'loss':[.41,.43,.45,.32,.45,.49]})",
    "    cv=_etr_reports_obj(et.FPCARegressionCVResult,",
    "      fold_losses=fold,n_splits=3,",
    "      cv_unit='curve' if alternate else 'group',",
    "      family='binomial' if full else 'gaussian',",
    "      loss='deviance' if full else 'rmse')",
    "    attrs=dict(predictor_names=('dose','time') if alternate else ('dose',),",
    "      boundary_fit=alternate,",
    "      trial_random_effect='functional_intercept' if full else None,",
    "      random_effect_singular=full,trial_random_effect_singular=full,",
    "      random_effect_complexity_warning=full,",
    "      residual_correlation_boundary_fit=full,",
    "      residual_correlation_independence_limit_fit=False,",
    "      backend_warnings=('optimizer warning',) if alternate else (),",
    "      random_slope_predictor=\"dose's β\" if alternate else None,",
    "      random_basis_size=3,",
    "      residual_correlation='exponential' if full else 'ar1' if alternate else 'iid',",
    "      dimension_name=\"fish's x\" if alternate else 'x',",
    "      fixed_basis_size=4,spline_degree=3,",
    "      source_curve_ids=tuple('c'+str(i) for i in range(8)),",
    "      participant_ids=tuple('p'+str(i) for i in range(4)),",
    "      reml=not full,method='lbfgs',",
    "      random_effect_covariance_condition_number=7.123)",
    "    if alternate:",
    "      attrs.update(random_effect_dimension=6,",
    "        random_effect_covariance_parameter_count=21,",
    "        residual_correlation_parameter=1.2345 if full else .25)",
    "    if full:",
    "      attrs.update(trial_ids=tuple('t'+str(i) for i in range(8)),",
    "        trial_random_basis_size=2,",
    "        trial_random_effect_covariance_parameter_count=3,",
    "        residual_correlation_parameter_unit='seconds')",
    "    fit=_etr_reports_obj(et.FunctionalMixedEffectsResult,**attrs)",
    "    band=None",
    "    if alternate:",
    "      cls=(et.FunctionalMixedEffectsFullRefitBootstrapResult if full",
    "        else et.FunctionalMixedEffectsBootstrapResult)",
    "      bootstrap=_etr_reports_obj(cls,",
    "        bootstrap_coefficient_functions=np.zeros((4,1,2)))",
    "      band=_etr_reports_obj(et.FunctionalMixedEffectsBandResult,",
    "        reference=fit,bootstrap=bootstrap,confidence_level=.95,",
    "        simultaneous_scope='family' if full else 'coefficient')",
    "    return (",
    "      et.fpca_regression_cv_reporting_text(cv,rule=rule,digits=digits),",
    "      et.functional_mixed_effects_reporting_text(fit,band=band))"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,
    "_etr_two_report_source")
  for(variant in c("base","conditional","full_refit")){
    z<-.etr_two_report_source_fixture(variant)
    for(digits in c(0L,2L,5L)){
      for(rule in c("minimum","one_se")){
        expected<-reticulate::py_to_r(
          reticulate::py_call(oracle,variant,rule,as.integer(digits)))
        actual_cv<-etr_fpca_regression_cv_reporting_text(
          z$cv,rule=rule,digits=digits)
        expect_identical(actual_cv,as.character(expected[[1L]]),
          info=paste(variant,rule,digits,"CV"))
        if(identical(digits,0L)&&identical(rule,"minimum")){
          actual_mixed<-etr_functional_mixed_effects_reporting_text(
            z$fit,z$band)
          expect_identical(actual_mixed,as.character(expected[[2L]]),
            info=paste(variant,"mixed"))
        }
      }
    }
  }
})
