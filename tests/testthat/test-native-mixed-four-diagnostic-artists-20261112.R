# Frozen Python 1.2 actual scientific-artist geometry:
# functional_mixed_effects_diagnostics.py (ACF/variogram)
# functional_mixed_effects_covariance_sensitivity.py (coefficient/variance)
# Frozen commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Only direct matched input science and Matplotlib line metadata are scoped.
# No Python statsmodels optimiser or Matplotlib runtime Axes identity.

.etr_mixed_artist_fixture<-function(){
  skip_if_not_installed("nlme")
  tt<-seq(0,1,length.out=7L)
  n<-24L
  ids<-sprintf("c%02d",seq_len(n))
  grp<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  cue<-rep(c(-1,0,1),8L)
  val<-array(0,c(n,length(tt),1L))
  for(i in seq_len(n)){
    p<-(i-1L)%/%3L+1L
    val[i,,1L]<-.7+.2*tt+cue[i]*(.5-.15*tt)+
      .6*sin(1.1*p)+.3*cos(2*p)*tt+
      .07*sin(.7*i*(tt+.3))+
      .035*cos((p+i)*tt)
  }
  source<-etr_trajectory_set(tt,val,ids,"gaze_x",
    metadata=data.frame(participant_id=grp),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),cue=rev(cue))
  fit<-etr_fit_joint_bspline_functional_mixed_effects(
    source,design,predictors="cue",
    participant_column="participant_id",dimension="gaze_x",
    fixed_basis_size=2L,random_basis_size=2L,spline_degree=1L,
    reml=TRUE,maxiter=500L)
  expect_s3_class(fit,"etr_joint_bspline_mixed")
  expect_true(inherits(fit$fitted_model,"lme"))
  expect_identical(fit$backend,"nlme::lme")
  fit
}
.etr_mixed_artist_pdf<-function(code){
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(file)
  },add=TRUE)
  force(code)
}

test_that("native Gaussian likelihood supports three source mixed diagnostics and variance decomposition",{
  fit<-.etr_mixed_artist_fixture()
  acf<-etr_functional_mixed_effects_residual_diagnostics(
    fit,max_lag=2L,residual_scale="raw")
  white<-etr_functional_mixed_effects_residual_diagnostics(
    fit,max_lag=2L,residual_scale="whitened")
  sens<-etr_functional_mixed_effects_covariance_sensitivity(
    list(base=fit,replica=fit),reference="base",max_lag=2L,
    strict_source_record=TRUE)
  expect_s3_class(sens,"etr_mixed_w3_sensitivity_source_record")
  .etr_mixed_artist_pdf({
    a<-etr_plot_functional_mixed_effects_residual_acf(
      acf,strict_source_record=TRUE)
    expect_s3_class(a,"etr_mixed_diagnostic_artist_source_record")
    expect_identical(a$source_export,
      "plot_functional_mixed_effects_residual_acf")
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$axes[[1L]]$xlabel,"Physical lag (s)")
    expect_identical(a$axes[[1L]]$ylabel,"Residual autocorrelation")
    expect_equal(a$axes[[1L]]$lines[[1L]]$xdata,
      acf$overall_diagnostics$lag_time_mean,tolerance=1e-12)
    expect_equal(a$axes[[1L]]$lines[[1L]]$ydata,
      acf$overall_diagnostics$autocorrelation,tolerance=1e-12)
    expect_identical(a$axes[[1L]]$lines[[1L]]$marker,"o")
    expect_true(a$axes[[1L]]$lines[[2L]]$is_horizontal_reference)
    expect_equal(a$axes[[1L]]$lines[[2L]]$ydata,c(0,0))
    b<-etr_plot_functional_mixed_effects_residual_variogram(
      white,level="trial",curve_id=fit$curve_ids[[1L]],
      strict_source_record=TRUE)
    expect_identical(b$source_export,
      "plot_functional_mixed_effects_residual_variogram")
    expect_identical(b$axes[[1L]]$ylabel,
      "Whitened residual semivariance")
    one<-white$trial_diagnostics
    one<-one[one$curve_id==fit$curve_ids[[1L]],,drop=FALSE]
    expect_equal(b$axes[[1L]]$lines[[1L]]$ydata,
      one$semivariance,tolerance=1e-12)
    expect_length(b$axes[[1L]]$lines,1L)
    co<-etr_plot_covariance_sensitivity_coefficients(sens,
      coefficient="cue",strict_source_record=TRUE)
    expect_identical(co$source_export,
      "plot_covariance_sensitivity_coefficients")
    expect_identical(co$axes[[1L]]$title,
      "Covariance sensitivity: cue")
    expect_identical(co$axes[[1L]]$legend_labels,
      c("base","replica"))
    expect_length(co$axes[[1L]]$lines,3L)
    for(label in c("base","replica")){
      line<-co$axes[[1L]]$lines[[
        match(label,c("base","replica"))]]
      expect_equal(line$ydata,
        sens$coefficient_frame$difference_from_reference[
          sens$coefficient_frame$model==label&
          sens$coefficient_frame$coefficient=="cue"],
        tolerance=1e-12)
      expect_equal(line$ydata,rep(0,length(fit$time)),
        tolerance=1e-10)
    }
    expect_true(co$axes[[1L]]$lines[[3L]]$is_horizontal_reference)
    va<-etr_plot_functional_variance_decomposition(fit,
      strict_source_record=TRUE)
    expect_identical(va$source_export,
      "plot_functional_variance_decomposition")
    expect_identical(va$axes[[1L]]$title,
      "Functional variance decomposition: model")
    source_v<-etr_functional_mixed_effects_variance_decomposition(fit)
    for(line in va$axes[[1L]]$lines[-length(va$axes[[1L]]$lines)]){
      expected<-source_v[
        source_v$component==line$label,,drop=FALSE]
      expect_equal(line$xdata,expected$time,tolerance=0)
      expect_equal(line$ydata,expected$value,tolerance=1e-12)
    }
    vs<-etr_plot_functional_variance_decomposition(
      sens,model="replica",strict_source_record=TRUE)
    expect_identical(vs$axes[[1L]]$title,
      "Functional variance decomposition: replica")
    expect_identical(vs$source_options$model,"replica")
    expect_false(vs$independently_certified)
  })
})

test_that("native mixed diagnostic artists preserve physical index lags, error boundaries and missing-band gap",{
  fit<-.etr_mixed_artist_fixture()
  raw<-etr_functional_mixed_effects_residual_diagnostics(
    fit,2L,residual_scale="raw")
  sens<-etr_functional_mixed_effects_covariance_sensitivity(
    list(base=fit),reference="base",max_lag=2L,
    strict_source_record=TRUE)
  .etr_mixed_artist_pdf({
    expect_error(etr_plot_functional_mixed_effects_residual_acf(
      raw,level="trial",strict_source_record=TRUE),
      "curve_id required")
    expect_error(etr_plot_functional_mixed_effects_residual_variogram(
      raw,level="participant",strict_source_record=TRUE),
      "participant_id required")
    expect_error(etr_plot_functional_mixed_effects_residual_acf(
      raw,strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_functional_mixed_effects_residual_acf(
      unclass(raw),strict_source_record=TRUE),
      "genuine native joint-likelihood diagnostics")
    expect_error(etr_plot_covariance_sensitivity_coefficients(
      sens,coefficient="unknown",strict_source_record=TRUE),
      "Unknown coefficient")
    expect_error(etr_plot_covariance_sensitivity_coefficients(
      unclass(sens),coefficient="cue",strict_source_record=TRUE),
      "strict source sensitivity")
    expect_error(etr_plot_covariance_sensitivity_band_widths(
      sens,coefficient="cue",strict_source_record=TRUE),
      "independently qualified native bands")
    expect_error(etr_plot_functional_variance_decomposition(
      fit,model="base",strict_source_record=TRUE),
      "only accepted for a covariance sensitivity")
    expect_error(etr_plot_functional_variance_decomposition(
      sens,strict_source_record=TRUE),
      "model must be declared")
    expect_error(etr_plot_functional_variance_decomposition(
      sens,model="missing",strict_source_record=TRUE),
      "Unknown model")
    expect_error(etr_plot_functional_variance_decomposition(
      list(),strict_source_record=TRUE),
      "real fitted Gaussian model or sensitivity")
    undefined<-raw
    undefined$overall_diagnostics$autocorrelation[]<-NaN
    blank<-etr_plot_functional_mixed_effects_residual_acf(
      undefined,strict_source_record=TRUE)
    expect_true(all(is.nan(blank$axes[[1L]]$lines[[1L]]$ydata)))
    expect_length(blank$axes[[1L]]$lines,2L)
  })
})

test_that("direct pinned Python 1.2 Matplotlib lines equal native mixed likelihood science",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python source Matplotlib mixed diagnostics oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fit<-.etr_mixed_artist_fixture()
  d<-etr_functional_mixed_effects_residual_diagnostics(fit,2L)
  sens<-etr_functional_mixed_effects_covariance_sensitivity(
    list(base=fit,replica=fit),"base",2L,strict_source_record=TRUE)
  .etr_mixed_artist_pdf({
    r_acf<-etr_plot_functional_mixed_effects_residual_acf(
      d,strict_source_record=TRUE)
    r_vg<-etr_plot_functional_mixed_effects_residual_variogram(
      d,strict_source_record=TRUE)
    r_coef<-etr_plot_covariance_sensitivity_coefficients(
      sens,"cue",strict_source_record=TRUE)
    r_var<-etr_plot_functional_variance_decomposition(
      sens,model="base",strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _et_mixed_plot_oracle(diagnostics,coefficient_frame,
                         variance_frame,unit):
    def obj(cls, **fields):
        x=object.__new__(cls)
        for k,v in fields.items():
            object.__setattr__(x,k,v)
        return x
    fit=obj(et.FunctionalMixedEffectsResult,time_unit=unit)
    diag=pd.DataFrame(diagnostics)
    residual=obj(et.FunctionalMixedEffectsResidualDiagnosticsResult,
        reference=fit,residual_scale='raw',
        trial_diagnostics=diag,
        participant_diagnostics=diag,
        overall_diagnostics=diag)
    specs=tuple(obj(et.FunctionalMixedEffectsCovarianceSpecification,
          name=name) for name in ('base','replica'))
    frame=pd.DataFrame(coefficient_frame)
    vframe=pd.DataFrame(variance_frame)
    sens=obj(et.FunctionalMixedEffectsCovarianceSensitivityResult,
        reference_label='base',
        fits={'base':fit,'replica':fit},
        specifications=specs,
        coefficient_frame=frame,
        variance_decomposition=vframe)
    axes={
      'acf':et.plot_functional_mixed_effects_residual_acf(residual),
      'variogram':et.plot_functional_mixed_effects_residual_variogram(residual),
      'coef':et.plot_covariance_sensitivity_coefficients(
           sens,coefficient='cue'),
      'variance':et.plot_functional_variance_decomposition(
           sens,model='base')
    }
    data={}
    for name,ax in axes.items():
        data[name]={
          'title':ax.get_title(),
          'xlabel':ax.get_xlabel(),
          'ylabel':ax.get_ylabel(),
          'lines':[
              {'x':np.asarray(line.get_xdata(),dtype=float),
               'y':np.asarray(line.get_ydata(),dtype=float),
               'label':line.get_label()}
              for line in ax.lines]}
        plt.close(ax.figure)
    return data
")
    py<-reticulate::py_call(
      reticulate::py_eval("_et_mixed_plot_oracle",convert=FALSE),
      diagnostics=d$overall_diagnostics,
      coefficient_frame=sens$coefficient_frame,
      variance_frame=sens$variance_decomposition,
      unit=fit$time_unit)
    get<-function(key)et_to_r(reticulate::py_get_item(py,key))
    pairs<-list(acf=r_acf,variogram=r_vg,
      coef=r_coef,variance=r_var)
    for(key in names(pairs)){
      actual<-pairs[[key]]$axes[[1L]]
      expected<-get(key)
      for(meta in c("title","xlabel","ylabel"))
        expect_identical(actual[[meta]],expected[[meta]],
          info=paste(key,meta))
      expect_identical(length(actual$lines),length(expected$lines),
        info=paste(key,"n_lines"))
      for(j in seq_along(actual$lines)){
        if(!isTRUE(actual$lines[[j]]$is_horizontal_reference)){
          expect_equal(actual$lines[[j]]$xdata,
            expected$lines[[j]]$x,tolerance=1e-10,
            ignore_attr=TRUE,info=paste(key,j,"x"))
        }
        expect_equal(actual$lines[[j]]$ydata,
          expected$lines[[j]]$y,tolerance=1e-10,
          ignore_attr=TRUE,info=paste(key,j,"y"))
        if(!isTRUE(actual$lines[[j]]$is_horizontal_reference))
          expect_identical(actual$lines[[j]]$label,
            expected$lines[[j]]$label,
            info=paste(key,j,"label"))
      }
    }
  })
})
