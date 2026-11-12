# Pinned Python 1.2.0 generalized/mixed scientific plotting data oracles.
.etr_generalized_mixed_graphics_fixtures <- function() {
  grid<-c(0,.5,1)
  fit<-list(time=grid,time_unit="seconds",family="poisson",
    link="log",coefficient_names=c("Intercept","group"),
    coefficient_functions=matrix(c(1,2,3,-1,0,1),2,3,byrow=TRUE))
  pred<-list(reference=fit,profile_ids=c("A","B"),
    mean_functions=matrix(c(2,3,4,1,2,3),2,3,byrow=TRUE),
    extrapolation_flags=c(FALSE,TRUE),prediction_scale="rate")
  pred_band<-list(prediction=pred,
    mean_lower=pred$mean_functions-.5,
    mean_upper=pred$mean_functions+.5)
  diff<-list(prediction_bootstrap=list(prediction=pred),
    estimate=c(1,1,1),lower=c(.5,.6,.7),upper=c(1.5,1.4,1.3),
    confidence_level=.95,contrast_scale="rate_ratio",
    profile_a="A",profile_b="B")
  coef_band<-list(reference=fit,
    lower=fit$coefficient_functions-.2,
    upper=fit$coefficient_functions+.2)
  specs<-list(list(name="base"),list(name="alternative"))
  sens<-list(specifications=specs,reference_label="base",
    fits=list(base=list(time_unit="seconds")),
    coefficient_frame=data.frame(coefficient=rep("group",6),
      model=rep(c("base","alternative"),each=3),
      time=rep(grid,2),
      difference_from_reference=c(0,0,0,.1,.2,.3)),
    band_width_frame=data.frame(coefficient=rep("group",6),
      model=rep(c("base","alternative"),each=3),
      time=rep(grid,2),
      band_width_ratio_to_reference=c(1,1,1,1.1,1.2,1.3)))
  diagnostics<-data.frame(curve_id=c("c1","c1","c1"),
    participant_id=c("P1","P1","P1"),
    lag_time_mean=c(0,.5,1),
    lag_time_min=c(0,.4,.9),
    lag_time_max=c(0,.6,1.1),
    autocorrelation=c(1,.6,.2),
    semivariance=c(0,.3,.6))
  residual<-list(reference=list(time_unit="seconds"),
    residual_scale="raw",trial_diagnostics=diagnostics,
    participant_diagnostics=diagnostics,
    overall_diagnostics=diagnostics)
  list(fit=fit,prediction=pred,prediction_band=pred_band,
    difference=diff,coefficient_band=coef_band,
    sensitivity=sens,residual=residual)
}
.etr_generalized_mixed_pdf <- function(code) {
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(code)
}
test_that("seven generalized/mixed native plots retain observed-grid geometry",{
  # Native scientific assertions: always run offline without Python.
  x<-.etr_generalized_mixed_graphics_fixtures()
  .etr_generalized_mixed_pdf({
    a<-etr_plot_generalized_function_on_scalar_predictions(
      x$prediction_band)
    expect_equal(nrow(a),6L)
    expect_equal(a$estimate[a$profile_id=="B"],c(1,2,3))
    expect_true(all(a$extrapolation[a$profile_id=="B"]))
    expect_equal(a$upper[a$profile_id=="A"],c(2.5,3.5,4.5))
    b<-etr_plot_generalized_function_on_scalar_mean_difference(
      x$difference)
    expect_equal(b$estimate,c(1,1,1))
    expect_equal(b$lower,c(.5,.6,.7))
    c<-etr_plot_generalized_function_on_scalar_coefficients(
      x$coefficient_band,coefficient="group")
    expect_equal(c$estimate,c(-1,0,1))
    expect_equal(c$lower,c(-1.2,-.2,.8))
    d<-etr_plot_covariance_sensitivity_coefficients(
      x$sensitivity,"group")
    expect_equal(d$value[d$model=="alternative"],c(.1,.2,.3))
    e<-etr_plot_covariance_sensitivity_band_widths(
      x$sensitivity,"group")
    expect_equal(e$value[e$model=="base"],c(1,1,1))
    f<-etr_plot_functional_mixed_effects_residual_acf(x$residual)
    expect_equal(f$value,c(1,.6,.2))
    expect_equal(f$lag_time_min,c(0,.4,.9))
    g<-etr_plot_functional_mixed_effects_residual_variogram(
      x$residual,level="trial",curve_id="c1")
    expect_equal(g$value,c(0,.3,.6))
    expect_equal(g$lag_time_max,c(0,.6,1.1))
  })
})
test_that("generalized mixed graphics preserve declared input uncertainty",{
  x<-.etr_generalized_mixed_graphics_fixtures()
  .etr_generalized_mixed_pdf({
    bad<-x$prediction_band;bad$mean_lower[1,1]<-Inf
    expect_error(etr_plot_generalized_function_on_scalar_predictions(bad),
      "mean_lower")
    bad<-x$difference;bad$upper[2]<-bad$lower[2]-1
    expect_error(etr_plot_generalized_function_on_scalar_mean_difference(bad),
      "lower must not exceed upper")
    bad<-x$coefficient_band;bad$reference$time<-c(1,.5,0)
    expect_error(etr_plot_generalized_function_on_scalar_coefficients(
      bad,coefficient="group"),"time")
    expect_error(etr_plot_covariance_sensitivity_coefficients(
      x$sensitivity,"missing"),"Unknown coefficient")
    bad<-x$sensitivity;bad$band_width_frame<-data.frame()
    expect_error(etr_plot_covariance_sensitivity_band_widths(
      bad,"group"),"does not contain")
    expect_error(etr_plot_functional_mixed_effects_residual_acf(
      x$residual,level="trial"),"curve_id required")
    expect_error(etr_plot_functional_mixed_effects_residual_variogram(
      x$residual,level="participant"),"participant_id required")
    bad<-x$residual;bad$overall_diagnostics$lag_time_min[2]<-1
    expect_error(etr_plot_functional_mixed_effects_residual_acf(bad),
      "physical lag means")
  })
})
test_that("new seven sources are mapped without unearned full certification",{
  names<-c("plot_generalized_function_on_scalar_predictions",
    "plot_generalized_function_on_scalar_mean_difference",
    "plot_generalized_function_on_scalar_coefficients",
    "plot_covariance_sensitivity_coefficients",
    "plot_covariance_sensitivity_band_widths",
    "plot_functional_mixed_effects_residual_acf",
    "plot_functional_mixed_effects_residual_variogram")
  p<-etr_native_parity_catalog()
  z<-p[p$is_python_function&p$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(z),7L)
  expect_identical(sort(z$native_r_candidate),sort(paste0("etr_",names)))
  expect_true(all(z$native_implementation_started))
  scoped<-c("plot_covariance_sensitivity_coefficients",
    "plot_functional_mixed_effects_residual_acf",
    "plot_functional_mixed_effects_residual_variogram",
    "plot_generalized_function_on_scalar_predictions",
    "plot_generalized_function_on_scalar_mean_difference",
    "plot_generalized_function_on_scalar_coefficients")
  # Three generalized FoSR plotting contracts now expose source-scientific
  # Matplotlib artist geometry on bounded native R records. The Gaussian
  # covariance band-width ratio still requires a qualified band estimator.
  expect_false(any(z$source_contract_gap_unresolved[
    z$python_name%in%scoped]))
  expect_true(all(z$source_contract_gap_unresolved[
    !(z$python_name%in%scoped)]))
  expect_false(any(z$one_to_one_native_contract_complete))
  expect_gte(sum(p$is_python_function&p$named_native_candidate),332L)
  expect_gte(sum(p$native_implementation_started),307L)
  inventory<-utils::read.csv(system.file("extdata",
    "native_source_contract_gaps_stage22.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  expect_identical(sum(p$source_contract_gap_unresolved),
    sum(inventory$unresolved_source_gap))
})
test_that("seven generalized/mixed plots match frozen Python 1.2 drawing data",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 FoSR/mixed-effects plot oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg', force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _gm_obj(cls,**kw):
    x=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(x,k,v)
    return x
_gm_grid=np.array([0.,.5,1.])
_gm_coeff=np.array([[1.,2.,3.],[-1.,0.,1.]])
_gm_fit=_gm_obj(et.GeneralizedFunctionOnScalarResult,
    time=_gm_grid,time_unit='seconds',family='poisson',link='log',
    coefficient_names=('Intercept','group'),
    coefficient_functions=_gm_coeff)
_gm_pred=_gm_obj(et.GeneralizedFunctionOnScalarPredictionResult,
    reference=_gm_fit,profile_ids=('A','B'),
    mean_functions=np.array([[2.,3.,4.],[1.,2.,3.]]),
    extrapolation_flags=np.array([False,True]),
    prediction_scale='rate')
_gm_band=_gm_obj(et.GeneralizedFunctionOnScalarPredictionBandResult,
    prediction=_gm_pred,mean_lower=_gm_pred.mean_functions-.5,
    mean_upper=_gm_pred.mean_functions+.5,
    confidence_level=.95)
_gm_diff=_gm_obj(et.GeneralizedFunctionOnScalarMeanDifferenceResult,
    prediction_bootstrap=_gm_obj(
      et.GeneralizedFunctionOnScalarPredictionBootstrapResult,
      prediction=_gm_pred),
    estimate=np.array([1.,1.,1.]),
    lower=np.array([.5,.6,.7]),
    upper=np.array([1.5,1.4,1.3]),
    confidence_level=.95,contrast_scale='rate_ratio',
    profile_a='A',profile_b='B')
_gm_cband=_gm_obj(et.GeneralizedFunctionOnScalarBandResult,
    reference=_gm_fit,lower=_gm_coeff-.2,upper=_gm_coeff+.2,
    confidence_level=.95)
_gm_sens=_gm_obj(et.FunctionalMixedEffectsCovarianceSensitivityResult,
    specifications=(
      _gm_obj(et.FunctionalMixedEffectsCovarianceSpecification,name='base'),
      _gm_obj(et.FunctionalMixedEffectsCovarianceSpecification,
        name='alternative')),
    reference_label='base',
    fits={'base':_gm_obj(et.FunctionalMixedEffectsResult,
      time_unit='seconds')},
    coefficient_frame=pd.DataFrame({
      'coefficient':['group']*6,
      'model':['base']*3+['alternative']*3,
      'time':[0.,.5,1.]*2,
      'difference_from_reference':[0.,0.,0.,.1,.2,.3]}),
    band_width_frame=pd.DataFrame({
      'coefficient':['group']*6,
      'model':['base']*3+['alternative']*3,
      'time':[0.,.5,1.]*2,
      'band_width_ratio_to_reference':[1.,1.,1.,1.1,1.2,1.3]}))
_gm_df=pd.DataFrame({
    'curve_id':['c1']*3,'participant_id':['P1']*3,
    'lag_time_mean':[0.,.5,1.],
    'lag_time_min':[0.,.4,.9],
    'lag_time_max':[0.,.6,1.1],
    'autocorrelation':[1.,.6,.2],
    'semivariance':[0.,.3,.6]})
_gm_res=_gm_obj(et.FunctionalMixedEffectsResidualDiagnosticsResult,
    reference=_gm_obj(et.FunctionalMixedEffectsResult,time_unit='seconds'),
    residual_scale='raw',
    trial_diagnostics=_gm_df,
    participant_diagnostics=_gm_df,
    overall_diagnostics=_gm_df)
_gm_axes={
  'prediction':et.plot_generalized_function_on_scalar_predictions(_gm_band),
  'difference':et.plot_generalized_function_on_scalar_mean_difference(_gm_diff),
  'coefficient':et.plot_generalized_function_on_scalar_coefficients(
    _gm_cband,coefficient='group'),
  'sensitivity':et.plot_covariance_sensitivity_coefficients(
    _gm_sens,coefficient='group'),
  'width':et.plot_covariance_sensitivity_band_widths(
    _gm_sens,coefficient='group'),
  'acf':et.plot_functional_mixed_effects_residual_acf(_gm_res),
  'variogram':et.plot_functional_mixed_effects_residual_variogram(
    _gm_res,level='trial',curve_id='c1')}
_gm_oracle={
  'prediction_B':_gm_axes['prediction'].lines[1].get_ydata(),
  'difference':_gm_axes['difference'].lines[0].get_ydata(),
  'coefficient':_gm_axes['coefficient'].lines[0].get_ydata(),
  'sensitivity_alternative':_gm_axes['sensitivity'].lines[1].get_ydata(),
  'width_base':_gm_axes['width'].lines[0].get_ydata(),
  'acf':_gm_axes['acf'].lines[0].get_ydata(),
  'variogram':_gm_axes['variogram'].lines[0].get_ydata()}
plt.close('all')
")
  # Direct frozen Python numerical and plotting replay, opt-in only.
  # Re-execute seven public Python source plot functions explicitly.
  # Frozen direct Axes geometry is matched to the independently retained
  # _gm_oracle data, which the native R plots already compare against.
  direct_axes<-list(
    prediction=reticulate::py_call(
      etpy_get_export("plot_generalized_function_on_scalar_predictions"),
      result=reticulate::py_eval("_gm_band",convert=FALSE)),
    difference=reticulate::py_call(
      etpy_get_export("plot_generalized_function_on_scalar_mean_difference"),
      result=reticulate::py_eval("_gm_diff",convert=FALSE)),
    coefficient=reticulate::py_call(
      etpy_get_export("plot_generalized_function_on_scalar_coefficients"),
      result=reticulate::py_eval("_gm_cband",convert=FALSE),
      coefficient="group"),
    sensitivity=reticulate::py_call(
      etpy_get_export("plot_covariance_sensitivity_coefficients"),
      result=reticulate::py_eval("_gm_sens",convert=FALSE),
      coefficient="group"),
    width=reticulate::py_call(
      etpy_get_export("plot_covariance_sensitivity_band_widths"),
      result=reticulate::py_eval("_gm_sens",convert=FALSE),
      coefficient="group"),
    acf=reticulate::py_call(
      etpy_get_export("plot_functional_mixed_effects_residual_acf"),
      result=reticulate::py_eval("_gm_res",convert=FALSE)),
    variogram=reticulate::py_call(
      etpy_get_export("plot_functional_mixed_effects_residual_variogram"),
      result=reticulate::py_eval("_gm_res",convert=FALSE),
      level="trial",curve_id="c1")
  )
  line_idx<-c(prediction=1L,difference=0L,coefficient=0L,
    sensitivity=1L,width=0L,acf=0L,variogram=0L)
  get_line<-reticulate::py_eval(
    "lambda axes, index: axes.lines[index].get_ydata()",convert=FALSE)
  oracle_names<-c(prediction="prediction_B",difference="difference",
    coefficient="coefficient",sensitivity="sensitivity_alternative",
    width="width_base",acf="acf",variogram="variogram")
  for(n in names(direct_axes)){
    y<-et_to_r(reticulate::py_call(get_line,direct_axes[[n]],
      as.integer(line_idx[[n]])))
    expected<-reticulate::py_eval(
      paste0("_gm_oracle['",oracle_names[[n]],"']"),convert=TRUE)
    expect_equal(as.numeric(y),as.numeric(expected),
      tolerance=1e-12,ignore_attr=TRUE,
      info=paste("direct frozen matplotlib Axes geometry",n))
  }
  reticulate::py_run_string("plt.close('all')")
  x<-.etr_generalized_mixed_graphics_fixtures()
  .etr_generalized_mixed_pdf({
    a<-etr_plot_generalized_function_on_scalar_predictions(x$prediction_band)
    b<-etr_plot_generalized_function_on_scalar_mean_difference(x$difference)
    c<-etr_plot_generalized_function_on_scalar_coefficients(
      x$coefficient_band,"group")
    d<-etr_plot_covariance_sensitivity_coefficients(
      x$sensitivity,"group")
    e<-etr_plot_covariance_sensitivity_band_widths(
      x$sensitivity,"group")
    f<-etr_plot_functional_mixed_effects_residual_acf(x$residual)
    g<-etr_plot_functional_mixed_effects_residual_variogram(
      x$residual,level="trial",curve_id="c1")
    actual<-list(prediction_B=a$estimate[a$profile_id=="B"],
      difference=b$estimate,coefficient=c$estimate,
      sensitivity_alternative=d$value[d$model=="alternative"],
      width_base=e$value[e$model=="base"],
      acf=f$value,variogram=g$value)
    for(n in names(actual)){
      expected<-reticulate::py_eval(
        paste0("_gm_oracle['",n,"']"),convert=TRUE)
      expect_equal(actual[[n]],expected,
        tolerance=1e-12,ignore_attr=TRUE,
        info=paste("frozen Python 1.2 line geometry",n))
    }
  })
})
