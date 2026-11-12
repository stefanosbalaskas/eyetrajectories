# Frozen Python eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94:
# plotting.py::plot_functional_mixed_effects_coefficient.
# Typed source scientific artists do not imply Python Matplotlib Axes identity.

.etr_mixed_coefficient_scientific_fixture<-function() {
  time<-c(0,.5,1)
  coef<-rbind(c(1,1.25,1.5),c(-.3,.0,.4))
  base<-structure(list(
    estimator="two_level_functional_method_of_moments",
    converged=TRUE,residual_functions=matrix(.2,4L,3L),
    time=time,time_unit="s",source_curve_ids=paste0("c",1:4),
    curve_participant_ids=c("p1","p1","p2","p2"),
    coefficient_names=c("Intercept","dose"),dimension_name="x",
    coefficient_functions=coef,
    coefficient_standard_errors=matrix(.05,2L,3L),
    random_basis=diag(length(time)),
    random_intercept_covariance=diag(.04,length(time)),
    residual_variance=.01),
    class="etr_functional_mixed_moments")
  band<-structure(list(reference=base,lower=coef-.2,
    upper=coef+.35,confidence_level=.9,
    simultaneous_scope="family"),
    class="etr_mixed_effects_simultaneous_band")
  list(fit=base,band=band)
}
.etr_mixed_coefficient_scientific_pdf<-function(code) {
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(file)
  },add=TRUE)
  force(code)
}
test_that("source mixed coefficient pointwise Wald artist preserves z and source order",{
  x<-.etr_mixed_coefficient_scientific_fixture()
  .etr_mixed_coefficient_scientific_pdf({
    r<-etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient="dose",strict_source_record=TRUE)
    expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
    expect_identical(r$source_export,
      "plot_functional_mixed_effects_coefficient")
    expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
    expect_false(r$matplotlib_object_identity)
    expect_false(r$independently_certified)
    expect_identical(r$source_options$interval_type,
      "pointwise_95_Wald_not_simultaneous")
    expect_false(r$source_options$simultaneous_band_input)
    expect_equal(r$source_options$normal_quantile_if_unbanded,
      1.959963984540054,tolerance=0)
    a<-r$axes[[1L]]
    expect_identical(a$title,"Functional mixed-effects coefficient: dose")
    expect_identical(a$xlabel,"Time (s)")
    expect_identical(a$ylabel,"Coefficient: x")
    expect_true(a$legend)
    expect_identical(a$legend_labels,
      c("95% pointwise Wald interval","dose"))
    expect_identical(vapply(a$artists,function(z)z$kind,character(1L)),
      c("fill_between","line","horizontal_reference"))
    b<-a$artists[[1L]]
    expect_identical(b$alpha,.2)
    expect_equal(b$xdata,c(0,.5,1))
    expect_equal(b$y1,c(-.3,0,.4)-1.959963984540054*.05,
      tolerance=1e-12)
    expect_equal(b$y2,c(-.3,0,.4)+1.959963984540054*.05,
      tolerance=1e-12)
    expect_equal(a$artists[[2L]]$xdata,c(0,.5,1))
    expect_equal(a$artists[[2L]]$ydata,c(-.3,0,.4))
    expect_identical(a$artists[[2L]]$label,"dose")
    expect_identical(a$artists[[3L]]$linestyle,"--")
    expect_equal(a$artists[[3L]]$ydata,c(0,0))
    numeric_index<-etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient=1L,strict_source_record=TRUE)
    expect_identical(numeric_index$axes[[1L]],a)
    legacy<-etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient="dose")
    expect_equal(legacy$estimate,c(-.3,0,.4))
    expect_identical(legacy$interval_type,
      rep("pointwise_95_Wald_not_simultaneous",3L))
  })
})
test_that("native simultaneous band is not relabelled or recalibrated as pointwise Wald",{
  x<-.etr_mixed_coefficient_scientific_fixture()
  .etr_mixed_coefficient_scientific_pdf({
    r<-etr_plot_functional_mixed_effects_coefficient(x$band,
      coefficient="dose",strict_source_record=TRUE)
    a<-r$axes[[1L]]
    expect_true(r$source_options$simultaneous_band_input)
    expect_true(r$source_options$calibration_reused)
    expect_identical(r$source_options$interval_type,
      "simultaneous_source_band")
    expect_null(r$source_options$normal_quantile_if_unbanded)
    expect_identical(a$legend_labels,
      c("90.0% simultaneous band (family)","dose"))
    expect_equal(a$artists[[1L]]$y1,c(-.5,-.2,.2))
    expect_equal(a$artists[[1L]]$y2,c(.05,.35,.75))
    expect_equal(a$artists[[2L]]$ydata,c(-.3,0,.4))
    expect_identical(a$artists[[3L]]$linestyle,"--")
    x$band$confidence_level<-.975
    x$band$simultaneous_scope<-"coefficient"
    t<-etr_plot_functional_mixed_effects_coefficient(x$band,
      coefficient="Intercept",strict_source_record=TRUE)
    expect_identical(t$axes[[1L]]$legend_labels,
      c("97.5% simultaneous band (coefficient)","Intercept"))
    expect_equal(t$axes[[1L]]$artists[[1L]]$y1,
      c(.8,1.05,1.3))
    expect_equal(t$axes[[1L]]$artists[[1L]]$y2,
      c(1.35,1.6,1.85))
  })
})
test_that("source mixed coefficient rejects malformed selection and impossible bands",{
  x<-.etr_mixed_coefficient_scientific_fixture()
  .etr_mixed_coefficient_scientific_pdf({
    expect_error(etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient=1,strict_source_record=TRUE),
      "zero-based integer")
    expect_error(etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient=TRUE,strict_source_record=TRUE),
      "zero-based integer")
    expect_error(etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient="unknown",strict_source_record=TRUE),
      "Unknown coefficient")
    expect_error(etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient=3L,strict_source_record=TRUE),
      "zero-based integer")
    expect_error(etr_plot_functional_mixed_effects_coefficient(x$fit,
      coefficient="dose",strict_source_record=1L),
      "strict_source_record")
    invalid<-x$fit
    invalid$coefficient_standard_errors[2L,2L]<-NaN
    expect_error(etr_plot_functional_mixed_effects_coefficient(invalid,
      coefficient="dose",strict_source_record=TRUE),
      "coefficient_standard_errors")
    invalid<-x$fit
    invalid$time<-c(0,0,1)
    expect_error(etr_plot_functional_mixed_effects_coefficient(invalid,
      coefficient="dose",strict_source_record=TRUE),
      "time grid")
    invalid<-x$band
    invalid$lower[2L,1L]<-100
    expect_error(etr_plot_functional_mixed_effects_coefficient(invalid,
      coefficient="dose",strict_source_record=TRUE),
      "lower bounds")
    invalid<-x$band
    invalid$confidence_level<-NA_real_
    expect_error(etr_plot_functional_mixed_effects_coefficient(invalid,
      coefficient="dose",strict_source_record=TRUE),
      "confidence_level")
    invalid<-x$band
    invalid$simultaneous_scope<-NULL
    expect_error(etr_plot_functional_mixed_effects_coefficient(invalid,
      coefficient="dose",strict_source_record=TRUE),
      "pointwise result requires coefficient_standard_errors|source mixed")
  })
})
test_that("pinned Python 1.2 mixed coefficient Matplotlib artists match both interval paths",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct public Python 1.2 Matplotlib scientific oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_mixed_coefficient_scientific_fixture()
  .etr_mixed_coefficient_scientific_pdf({
    native<-list(
      etr_plot_functional_mixed_effects_coefficient(x$fit,
        coefficient="dose",strict_source_record=TRUE),
      etr_plot_functional_mixed_effects_coefficient(x$band,
        coefficient="dose",strict_source_record=TRUE))
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

def _make(cls,**kw):
    obj=object.__new__(cls)
    for k,v in kw.items():object.__setattr__(obj,k,v)
    return obj
time=np.array([0.,.5,1.])
estimate=np.array([[1.,1.25,1.5],[-.3,0.,.4]])
fit=_make(et.FunctionalMixedEffectsResult,
    time=time,time_unit='s',dimension_name='x',
    coefficient_names=('Intercept','dose'),
    coefficient_functions=estimate,
    coefficient_standard_errors=np.full((2,3),.05))
band=_make(et.FunctionalMixedEffectsBandResult,
    reference=fit,lower=estimate-.2,upper=estimate+.35,
    confidence_level=.9,simultaneous_scope='family')
axes=[
    et.plot_functional_mixed_effects_coefficient(fit,
      coefficient='dose'),
    et.plot_functional_mixed_effects_coefficient(band,
      coefficient='dose')]
def _line(l):
    return {'x':np.asarray(l.get_xdata(),dtype=float),
      'y':np.asarray(l.get_ydata(),dtype=float),
      'linestyle':l.get_linestyle(),'label':l.get_label()}
def _oracle(ax):
    path=ax.collections[0].get_paths()[0].vertices
    return {'title':ax.get_title(),'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'legend':[] if ax.get_legend() is None else
        [e.get_text() for e in ax.get_legend().get_texts()],
      'alpha':ax.collections[0].get_alpha(),
      'polygon_vertices':np.asarray(path,dtype=float),
      'lines':[_line(l) for l in ax.lines]}
oracle=[_oracle(ax) for ax in axes]
plt.close('all')
")
    oracle<-et_to_r(reticulate::py_get_attr(reticulate::py,
      "oracle"))
    expect_length(oracle,2L)
    for(i in seq_along(native)){
      a<-native[[i]]$axes[[1L]]
      p<-oracle[[i]]
      for(key in c("title","xlabel","ylabel"))
        expect_identical(a[[key]],p[[key]])
      expect_identical(a$legend_labels,as.character(p$legend))
      expect_equal(a$artists[[1L]]$alpha,p$alpha,tolerance=0)
      expect_equal(a$artists[[2L]]$xdata,
        as.numeric(p$lines[[1L]]$x),tolerance=0)
      expect_equal(a$artists[[2L]]$ydata,
        as.numeric(p$lines[[1L]]$y),tolerance=0)
      expect_equal(a$artists[[3L]]$ydata,
        as.numeric(p$lines[[2L]]$y),tolerance=0)
      expect_identical(a$artists[[3L]]$linestyle,
        p$lines[[2L]]$linestyle)
      vertices<-as.matrix(p$polygon_vertices)
      u<-sort(unique(vertices[,1L]))
      expect_equal(u,a$artists[[1L]]$xdata,tolerance=0)
      for(j in seq_along(u)){
        bounds<-vertices[vertices[,1L]==u[j],2L]
        expect_equal(min(bounds),a$artists[[1L]]$y1[j],
          tolerance=1e-12)
        expect_equal(max(bounds),a$artists[[1L]]$y2[j],
          tolerance=1e-12)
      }
    }
  })
})
