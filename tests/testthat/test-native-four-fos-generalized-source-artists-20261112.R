# Four source-scientific plotting paths against frozen eyetrajectoriespy==1.2.0,
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R scientific source artist records are not Python Matplotlib Axes.

.etr_four_fos_plot_fixtures <- function() {
  grid<-c(0,.5,1)
  fit<-list(time=grid,time_unit="seconds",family="poisson",
    link="log",coefficient_names=c("Intercept","group"),
    coefficient_functions=matrix(c(1,2,3,-1,0,1),2L,3L,byrow=TRUE))
  prediction<-list(reference=fit,profile_ids=c("A","B"),
    mean_functions=matrix(c(2,3,4,1,2,3),2L,3L,byrow=TRUE),
    extrapolation_flags=c(FALSE,TRUE),prediction_scale="rate")
  pred_band<-list(prediction=prediction,
    mean_lower=prediction$mean_functions-.5,
    mean_upper=prediction$mean_functions+.5)
  contrast<-list(prediction_bootstrap=list(prediction=prediction),
    estimate=c(1,1,1),lower=c(.5,.6,.7),upper=c(1.5,1.4,1.3),
    confidence_level=.95,contrast_scale="rate_ratio",
    profile_a="A",profile_b="B")
  coef_band<-list(reference=fit,
    lower=fit$coefficient_functions-.2,
    upper=fit$coefficient_functions+.2,confidence_level=.9)
  time<-as.numeric(0:2)
  dose<-c(-2,-1,0,1,2,3)
  val<-array(0,dim=c(length(dose),length(time),1L))
  for(i in seq_along(dose))
    val[i,,1L]<-1+.2*time+dose[i]*(.3+.04*time)+
      .05*cos(time+i/2)
  ids<-paste0("f",seq_along(dose))
  curves<-etr_trajectory_set(time,val,curve_ids=ids,
    dimension_names="x",coordinate_system="unknown",time_unit="s")
  design<-data.frame(curve_id=ids,dose=dose)
  fos<-etr_fit_function_on_scalar_regression(
    curves,design,predictors="dose")
  b<-structure(list(reference=fos,
    lower=fos$coefficients-.08,upper=fos$coefficients+.08,
    confidence_level=.95,simultaneous_scope="coefficient"),
    class="etr_function_on_scalar_band")
  list(fit=fit,prediction=prediction,prediction_band=pred_band,
    contrast=contrast,coefficient_band=coef_band,
    fos=fos,fos_band=b)
}

.etr_four_fos_pdf <- function(code) {
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path,width=10,height=7)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(code)
}

test_that("generalized FoSR profile source lines and fill geometry preserve source order",{
  z<-.etr_four_fos_plot_fixtures()
  .etr_four_fos_pdf({
    plain<-etr_plot_generalized_function_on_scalar_predictions(
      z$prediction,strict_source_record=TRUE)
    band<-etr_plot_generalized_function_on_scalar_predictions(
      z$prediction_band,strict_source_record=TRUE)
    expect_s3_class(band,"etr_nonlinear_scientific_artist_record")
    expect_identical(band$source_export,
      "plot_generalized_function_on_scalar_predictions")
    expect_false(band$matplotlib_object_identity)
    expect_false(band$independently_certified)
    expect_identical(band$python_return_kind,
      "matplotlib.axes.Axes")
    a<-band$axes[[1L]]
    expect_identical(a$title,
      "Generalized FoSR fixed-profile marginal predictions")
    expect_identical(a$xlabel,"Time (seconds)")
    expect_identical(a$ylabel,"Marginal exposure-adjusted rate")
    expect_true(a$legend)
    expect_identical(a$legend_labels,c("A","B (extrapolation)"))
    expect_length(a$artists,4L)
    expect_identical(vapply(a$artists,function(x)x$kind,character(1L)),
      c("line","fill_between","line","fill_between"))
    expect_equal(a$artists[[1L]]$xdata,c(0,.5,1))
    expect_equal(a$artists[[1L]]$ydata,c(2,3,4))
    expect_equal(a$artists[[2L]]$y1,c(1.5,2.5,3.5))
    expect_equal(a$artists[[2L]]$y2,c(2.5,3.5,4.5))
    expect_identical(a$artists[[2L]]$alpha,.2)
    expect_equal(a$artists[[3L]]$ydata,c(1,2,3))
    expect_length(plain$axes[[1L]]$artists,2L)
    expect_identical(plain$source_options$banded,FALSE)
    expect_identical(band$source_options$banded,TRUE)
    legacy<-etr_plot_generalized_function_on_scalar_predictions(
      z$prediction_band)
    expect_equal(nrow(legacy),6L)
    expect_equal(legacy$upper[legacy$profile_id=="A"],
      c(2.5,3.5,4.5))
    expect_error(etr_plot_generalized_function_on_scalar_predictions(
      z$prediction,strict_source_record=1L),"strict_source_record")
    invalid<-z$prediction_band
    invalid$mean_lower[1L,1L]<-Inf
    expect_error(etr_plot_generalized_function_on_scalar_predictions(
      invalid,strict_source_record=TRUE),"mean_lower")
  })
})

test_that("generalized FoSR contrast source interval and rate-ratio null are scientific",{
  z<-.etr_four_fos_plot_fixtures()
  .etr_four_fos_pdf({
    a<-etr_plot_generalized_function_on_scalar_mean_difference(
      z$contrast,strict_source_record=TRUE)
    expect_identical(a$source_export,
      "plot_generalized_function_on_scalar_mean_difference")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,"Generalized FoSR rate ratio: A - B")
    expect_identical(ax$xlabel,"Time (seconds)")
    expect_identical(ax$ylabel,"Marginal rate ratio")
    expect_identical(ax$legend_labels,
      c("estimate","95% simultaneous band"))
    expect_identical(vapply(ax$artists,function(x)x$kind,character(1L)),
      c("line","fill_between","horizontal_reference"))
    expect_equal(ax$artists[[1L]]$xdata,c(0,.5,1))
    expect_equal(ax$artists[[1L]]$ydata,c(1,1,1))
    expect_equal(ax$artists[[2L]]$y1,c(.5,.6,.7))
    expect_equal(ax$artists[[2L]]$y2,c(1.5,1.4,1.3))
    expect_identical(ax$artists[[2L]]$alpha,.2)
    expect_equal(ax$artists[[3L]]$ydata,c(1,1))
    expect_identical(ax$artists[[3L]]$linestyle,"-")
    expect_identical(ax$artists[[3L]]$linewidth,1.0)
    diff<-z$contrast;diff$contrast_scale<-"rate_difference"
    zero<-etr_plot_generalized_function_on_scalar_mean_difference(
      diff,strict_source_record=TRUE)
    expect_equal(zero$axes[[1L]]$artists[[3L]]$ydata,c(0,0))
    expect_identical(zero$axes[[1L]]$ylabel,
      "Marginal rate difference")
    legacy<-etr_plot_generalized_function_on_scalar_mean_difference(
      z$contrast)
    expect_equal(legacy$estimate,c(1,1,1))
    expect_error(etr_plot_generalized_function_on_scalar_mean_difference(
      z$contrast,strict_source_record="yes"),"strict_source_record")
  })
})

test_that("generalized FoSR link-scale coefficients preserve source lines and 90 percent band",{
  z<-.etr_four_fos_plot_fixtures()
  .etr_four_fos_pdf({
    a<-etr_plot_generalized_function_on_scalar_coefficients(
      z$coefficient_band,coefficient="group",strict_source_record=TRUE)
    ax<-a$axes[[1L]]
    expect_identical(a$source_export,
      "plot_generalized_function_on_scalar_coefficients")
    expect_identical(ax$title,
      "Generalized function-on-scalar coefficient: group")
    expect_identical(ax$ylabel,"group coefficient (log scale)")
    expect_identical(ax$xlabel,"Time (seconds)")
    expect_identical(ax$legend_labels,
      c("estimate","90% simultaneous band"))
    expect_length(ax$artists,3L)
    expect_identical(vapply(ax$artists,function(x)x$kind,character(1L)),
      c("line","fill_between","horizontal_reference"))
    expect_equal(ax$artists[[1L]]$ydata,c(-1,0,1))
    expect_equal(ax$artists[[2L]]$y1,c(-1.2,-.2,.8))
    expect_equal(ax$artists[[2L]]$y2,c(-.8,.2,1.2))
    expect_equal(ax$artists[[3L]]$ydata,c(0,0))
    plain<-etr_plot_generalized_function_on_scalar_coefficients(
      z$fit,coefficient="group",strict_source_record=TRUE)
    expect_length(plain$axes[[1L]]$artists,2L)
    expect_identical(plain$axes[[1L]]$legend_labels,"estimate")
    legacy<-etr_plot_generalized_function_on_scalar_coefficients(
      z$coefficient_band,coefficient="group")
    expect_equal(legacy$estimate,c(-1,0,1))
    invalid<-z$coefficient_band
    invalid$confidence_level<-NA_real_
    expect_error(etr_plot_generalized_function_on_scalar_coefficients(
      invalid,coefficient="group",strict_source_record=TRUE),
      "confidence_level")
    expect_error(etr_plot_generalized_function_on_scalar_coefficients(
      z$fit,coefficient="unknown",strict_source_record=TRUE),
      "Unknown coefficient")
    expect_error(etr_plot_generalized_function_on_scalar_coefficients(
      z$fit,coefficient="group",strict_source_record=0L),
      "strict_source_record")
  })
})

test_that("ordinary FOS accepts native band as primary source record and respects scope",{
  z<-.etr_four_fos_plot_fixtures()
  .etr_four_fos_pdf({
    source<-etr_plot_function_on_scalar_coefficients(z$fos_band,
      coefficient="dose",strict_source_record=TRUE)
    expect_s3_class(source,"etr_nonlinear_scientific_artist_record")
    expect_identical(source$source_export,
      "plot_function_on_scalar_coefficients")
    expect_false(source$matplotlib_object_identity)
    ax<-source$axes[[1L]]
    expect_identical(ax$title,"Function-on-scalar coefficient: dose")
    expect_identical(ax$xlabel,"Time (s)")
    expect_identical(ax$ylabel,"Coefficient: x")
    expect_identical(ax$legend_labels,
      c("95.0% simultaneous band (coefficient)","dose"))
    expect_identical(vapply(ax$artists,function(x)x$kind,character(1L)),
      c("fill_between","line","horizontal_reference"))
    expect_identical(ax$artists[[1L]]$alpha,.2)
    expect_equal(ax$artists[[1L]]$y1,
      as.numeric(z$fos_band$lower[2L,,1L]))
    expect_equal(ax$artists[[1L]]$y2,
      as.numeric(z$fos_band$upper[2L,,1L]))
    expect_equal(ax$artists[[2L]]$ydata,
      as.numeric(z$fos$coefficients[2L,,1L]))
    expect_identical(ax$artists[[3L]]$linestyle,"--")
    expect_equal(ax$artists[[3L]]$ydata,c(0,0))
    unbanded<-etr_plot_function_on_scalar_coefficients(z$fos,
      coefficient="dose",strict_source_record=TRUE)
    expect_length(unbanded$axes[[1L]]$artists,2L)
    expect_identical(unbanded$axes[[1L]]$legend_labels,"dose")
    default<-etr_plot_function_on_scalar_coefficients(z$fos,
      coefficient="dose")
    expect_equal(default$estimate,
      as.numeric(z$fos$coefficients[2L,,1L]))
    expect_null(default$lower)
    expect_error(etr_plot_function_on_scalar_coefficients(
      z$fos_band,coefficient="dose",band=z$fos_band,
      strict_source_record=TRUE),"second band")
    expect_error(etr_plot_function_on_scalar_coefficients(
      z$fos,coefficient="dose",strict_source_record=NA),
      "strict_source_record")
  })
})

test_that("frozen Python 1.2 four public FoSR and generalized FoSR Matplotlib artists match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 Matplotlib source artist oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_four_fos_plot_fixtures()
  .etr_four_fos_pdf({
    native<-list(
      etr_plot_generalized_function_on_scalar_predictions(
        z$prediction_band,strict_source_record=TRUE),
      etr_plot_generalized_function_on_scalar_mean_difference(
        z$contrast,strict_source_record=TRUE),
      etr_plot_generalized_function_on_scalar_coefficients(
        z$coefficient_band,coefficient="group",
        strict_source_record=TRUE),
      etr_plot_function_on_scalar_coefficients(
        z$fos_band,coefficient="dose",strict_source_record=TRUE))
    reticulate::py$fos_coef<-reticulate::r_to_py(z$fos$coefficients)
    reticulate::py$fos_lower<-reticulate::r_to_py(z$fos_band$lower)
    reticulate::py$fos_upper<-reticulate::r_to_py(z$fos_band$upper)
    reticulate::py$fos_time<-reticulate::r_to_py(z$fos$time)
    reticulate::py$fos_names<-reticulate::r_to_py(
      as.list(z$fos$coefficient_names))
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

def _mk(cls,**kw):
    obj=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(obj,k,v)
    return obj
t=np.array([0.,.5,1.])
fit=_mk(et.GeneralizedFunctionOnScalarResult,
  time=t,time_unit='seconds',family='poisson',link='log',
  coefficient_names=('Intercept','group'),
  coefficient_functions=np.array([[1.,2.,3.],[-1.,0.,1.]]))
pred=_mk(et.GeneralizedFunctionOnScalarPredictionResult,
  reference=fit,profile_ids=('A','B'),
  mean_functions=np.array([[2.,3.,4.],[1.,2.,3.]]),
  extrapolation_flags=np.array([False,True]),
  prediction_scale='rate')
predband=_mk(et.GeneralizedFunctionOnScalarPredictionBandResult,
  prediction=pred,
  mean_lower=np.array([[1.5,2.5,3.5],[.5,1.5,2.5]]),
  mean_upper=np.array([[2.5,3.5,4.5],[1.5,2.5,3.5]]))
contrast=_mk(et.GeneralizedFunctionOnScalarMeanDifferenceResult,
  prediction_bootstrap=_mk(et.GeneralizedFunctionOnScalarPredictionBootstrapResult,
    prediction=pred),
  estimate=np.array([1.,1.,1.]),lower=np.array([.5,.6,.7]),
  upper=np.array([1.5,1.4,1.3]),confidence_level=.95,
  contrast_scale='rate_ratio',profile_a='A',profile_b='B')
coefficient_band=_mk(et.GeneralizedFunctionOnScalarBandResult,
  reference=fit,lower=fit.coefficient_functions-.2,
  upper=fit.coefficient_functions+.2,confidence_level=.9)
fosfit=_mk(et.FunctionOnScalarResult,
  time=np.asarray(fos_time,dtype=float),time_unit='s',
  coefficient_names=tuple(fos_names),dimension_names=('x',),
  coefficients=np.asarray(fos_coef,dtype=float))
fosband=_mk(et.FunctionOnScalarBandResult,
  reference=fosfit,lower=np.asarray(fos_lower,dtype=float),
  upper=np.asarray(fos_upper,dtype=float),
  confidence_level=.95,simultaneous_scope='coefficient')
axes=[
  et.plot_generalized_function_on_scalar_predictions(predband),
  et.plot_generalized_function_on_scalar_mean_difference(contrast),
  et.plot_generalized_function_on_scalar_coefficients(
    coefficient_band,coefficient='group'),
  et.plot_function_on_scalar_coefficients(
    fosband,coefficient='dose')]
def _line(line):
    return {'x':np.asarray(line.get_xdata(),dtype=float),
      'y':np.asarray(line.get_ydata(),dtype=float),
      'label':line.get_label(),
      'linestyle':line.get_linestyle()}
def _axis(ax):
    return {'title':ax.get_title(),'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'lines':[_line(x) for x in ax.lines],
      'fills':[col.get_alpha() for col in ax.collections],
      'legend':[] if ax.get_legend() is None else
        [x.get_text() for x in ax.get_legend().get_texts()]}
oracle=[_axis(x) for x in axes]
plt.close('all')
")
    py<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    expect_length(py,4L)
    for(i in seq_along(native)) {
      ax<-native[[i]]$axes[[1L]]
      for(n in c("title","xlabel","ylabel"))
        expect_identical(ax[[n]],py[[i]][[n]],
          info=paste("frozen source plot",i,n))
      expect_identical(ax$legend_labels,
        as.character(py[[i]]$legend))
      source_lines<-Filter(function(a)
        a$kind%in%c("line","horizontal_reference"),ax$artists)
      expect_equal(length(source_lines),length(py[[i]]$lines))
      for(j in seq_along(source_lines)) {
        expect_equal(source_lines[[j]]$xdata,
          as.numeric(py[[i]]$lines[[j]]$x),tolerance=0)
        expect_equal(source_lines[[j]]$ydata,
          as.numeric(py[[i]]$lines[[j]]$y),tolerance=1e-12)
        expect_identical(source_lines[[j]]$linestyle,
          py[[i]]$lines[[j]]$linestyle)
      }
      source_fills<-Filter(function(a)identical(a$kind,"fill_between"),
        ax$artists)
      expect_equal(length(source_fills),length(py[[i]]$fills))
      for(j in seq_along(source_fills))
        expect_equal(source_fills[[j]]$alpha,
          py[[i]]$fills[[j]],tolerance=0)
    }
  })
})
