# Paired precomputed simultaneous band widths: frozen Python 1.2
# functional_mixed_effects_covariance_sensitivity.py, c1cd95ad718327550f7e55393ff38582872f7a94.
# This does not assert full Python statsmodels optimizer or Matplotlib identity.

.etr_paired_band_fixture <- function() {
  t<-c(0,.5,1)
  names<-c("Intercept","dose")
  a<-list(time=t,time_unit="s",coefficient_names=names)
  b<-a
  B<-4L
  sampled<-matrix(as.integer(c(0,1,1,0,0,0,1,1,1,1,0,0,1,0,1,0)),4L,4L)
  mk <- function(fit,amount,bootstrap_type="conditional_covariance",
                 scope="family",level=.9,draw=sampled) {
    lo<-matrix(0,2L,3L)
    hi<-matrix(amount,2L,3L)
    bootstrap<-list(
      bootstrap_type=bootstrap_type,
      sampled_participant_indices=draw,
      bootstrap_coefficient_functions=array(0,c(B,2L,3L)))
    structure(list(reference=fit,lower=lo,upper=hi,
      confidence_level=level,simultaneous_scope=scope,bootstrap=bootstrap),
      class="etr_mixed_effects_simultaneous_band")
  }
  list(fits=list(reference=a,alternative=b),
    bands=list(reference=mk(a,1),alternative=mk(b,1.5)),
    reference="reference",mk=mk,sampled=sampled)
}
.etr_paired_band_plot_pdf <- function(expr) {
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file)
  on.exit({grDevices::dev.off();unlink(file)},add=TRUE)
  force(expr)
}

test_that("frozen Python width-frame order and source numerical ratios are matched",{
  f<-.etr_paired_band_fixture()
  frame<-.etr_joint_source_band_width_frame(f$fits,f$bands,"reference")
  expect_identical(names(frame),c("model","coefficient","time",
    "band_width","reference_band_width","band_width_ratio_to_reference"))
  expect_identical(nrow(frame),12L)
  expect_identical(as.character(frame$model),
    rep(c("reference","alternative"),each=6L))
  expect_identical(as.character(frame$coefficient),
    rep(rep(c("Intercept","dose"),each=3L),2L))
  expect_equal(as.numeric(frame$time),rep(c(0,.5,1),4L))
  expect_equal(frame$band_width,c(rep(1,6L),rep(1.5,6L)))
  expect_equal(frame$reference_band_width,rep(1,12L))
  expect_equal(frame$band_width_ratio_to_reference,
    c(rep(1,6L),rep(1.5,6L)))
  # Partial set: Python skips successful models without supplied bands.
  frame_ref<-.etr_joint_source_band_width_frame(f$fits,
    list(reference=f$bands$reference),"reference")
  expect_identical(unique(frame_ref$model),"reference")
  expect_identical(nrow(frame_ref),6L)
  expect_identical(nrow(.etr_joint_source_band_width_frame(
    f$fits,NULL,"reference")),0L)
})

test_that("paired source band validation rejects unpaired resampling and scope drift",{
  f<-.etr_paired_band_fixture()
  run<-function(bands) .etr_joint_source_band_width_frame(
    f$fits,bands,"reference")
  b<-f$bands
  b$alternative$bootstrap$sampled_participant_indices[1,1]<-2L
  expect_error(run(b),"identical participant bootstrap draws")
  b<-f$bands;b$alternative$bootstrap$bootstrap_type<-"full_refit"
  expect_error(run(b),"same bootstrap contract")
  b<-f$bands;b$alternative$bootstrap$bootstrap_coefficient_functions<-
    array(0,c(3L,2L,3L))
  expect_error(run(b),"same number of bootstrap replicates")
  b<-f$bands;b$alternative$confidence_level<-.95
  expect_error(run(b),"same confidence level")
  b<-f$bands;b$alternative$simultaneous_scope<-"coefficient"
  expect_error(run(b),"same simultaneous scope")
  b<-f$bands;b$alternative$reference<-list(time=c(0,.5,2),
    time_unit="s",coefficient_names=c("Intercept","dose"))
  expect_error(run(b),"supplied fitted model")
  b<-f$bands;b$alternative$upper[1,1]<--1
  expect_error(run(b),"ordered")
  b<-f$bands;names(b)[2L]<-"unknown"
  expect_error(run(b),"without successful fits")
  expect_error(run(list(alternative=f$bands$alternative)),
    "band for the declared reference")
  b<-f$bands;b$reference$bootstrap$sampled_participant_indices<-NULL
  expect_error(run(b),"complete participant draw indices")
})

test_that("zero reference width creates NaN rather than false finite inference",{
  f<-.etr_paired_band_fixture()
  f$bands$reference$upper[2L,2L]<-0
  source<-.etr_joint_source_band_width_frame(f$fits,f$bands,"reference")
  special<-source$coefficient=="dose"&source$time==.5
  expect_true(all(is.nan(source$band_width_ratio_to_reference[special])))
  expect_equal(source$reference_band_width[special],c(0,0))
  # Source-style rendering: direct scientific record from a genuine
  # completed sensitivity must be checked for width/ratio consistency.
  res<-structure(list(
    specifications=list(list(name="reference"),list(name="alternative")),
    reference_label="reference",fits=list(
      reference=list(time_unit="s"),alternative=list(time_unit="s")),
    band_width_frame=source,
    provenance=list(source_paired_bootstrap_bands_validated=TRUE)),
    class="etr_mixed_w3_sensitivity_source_record")
  # The actual strict public mode additionally requires fitted nlme objects;
  # source numerical renderer is unit-tested here without inventing a fit.
  .etr_paired_band_plot_pdf({
    artist<-.etr_source_plot_sensitivity(res,"dose",width=TRUE,
      strict_source_record=FALSE)
    expect_true(is.nan(artist$value[artist$model=="reference"&
      artist$time==.5]))
  })
})

test_that("actual native joint-likelihood source integration retains audited paired bands",{
  skip_if_not_installed("nlme")
  # Fit one actual joint Gaussian model; reusing it twice isolates
  # source ratio/plot behavior from optimizer differences.
  time<-seq(0,1,length.out=7L)
  ids<-sprintf("c%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  dose<-rep(c(-1,0,1),8L)
  y<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    y[i,,1L]<-.7+.23*time+dose[i]*(.25-.15*time)+
      .18*sin(g*.6)+.13*cos(g*.31)*time+
      .06*sin(i*.7+time*4)+.035*cos(1.5*i*time)
  }
  tr<-etr_trajectory_set(time,y,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),dose=rev(dose))
  fit<-etr_fit_joint_bspline_functional_mixed_effects(
    tr,design,"dose","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE)
  bootstrap<-etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,random_state=11L)
  band<-etr_functional_mixed_effects_simultaneous_bands(
    bootstrap,confidence_level=.9,simultaneous_scope="family")
  source<-etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit,replica=fit),reference="reference",
    max_lag=2L,bands=list(reference=band,replica=band),
    strict_source_record=TRUE)
  expect_s3_class(source,"etr_mixed_w3_sensitivity_source_record")
  expect_true(source$provenance$source_paired_bootstrap_bands_validated)
  expect_identical(names(source$band_width_frame),c("model",
    "coefficient","time","band_width","reference_band_width",
    "band_width_ratio_to_reference"))
  expect_true(all(source$band_width_frame$band_width_ratio_to_reference==1))
  .etr_paired_band_plot_pdf({
    artist<-etr_plot_covariance_sensitivity_band_widths(
      source,coefficient="dose",strict_source_record=TRUE)
    expect_identical(artist$source_export,
      "plot_covariance_sensitivity_band_widths")
    expect_identical(artist$python_return_kind,"matplotlib.axes.Axes")
    expect_false(artist$matplotlib_object_identity)
    expect_false(artist$independently_certified)
    a<-artist$axes[[1L]]
    expect_identical(a$legend_labels,c("reference","replica"))
    expect_equal(a$lines[[1L]]$ydata,rep(1,length(time)))
    expect_equal(a$lines[[2L]]$ydata,rep(1,length(time)))
    expect_identical(a$lines[[3L]]$ydata,c(1,1))
    altered<-source
    altered$band_width_frame$band_width_ratio_to_reference[1L]<-2
    expect_error(etr_plot_covariance_sensitivity_band_widths(
      altered,"dose",strict_source_record=TRUE),
      "ratios must equal paired widths")
  })
})

test_that("frozen Python 1.2 width calculation and Matplotlib artists are source witnesses",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct frozen Python 1.2 scientific source oracle opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
from types import SimpleNamespace as S
import eyetrajectoriespy as et
import eyetrajectoriespy.functional_mixed_effects_covariance_sensitivity as mod
from eyetrajectoriespy.functional_mixed_effects_covariance_sensitivity import _band_width_frame
grid=np.array([0.,.5,1.])
def mkfit():
    return S(time=grid,time_unit='s',coefficient_names=('Intercept','dose'))
reference=mkfit()
alternative=mkfit()
def mkband(fit,width):
    return S(reference=fit,lower=np.zeros((2,3)),upper=np.full((2,3),width))
frame=_band_width_frame(
    {'reference':reference,'alternative':alternative},
    {'reference':mkband(reference,1.),'alternative':mkband(alternative,1.5)},
    reference='reference')
obj=object.__new__(et.FunctionalMixedEffectsCovarianceSensitivityResult)
for k,v in dict(
  specifications=(S(name='reference'),S(name='alternative')),
  reference_label='reference',
  fits={'reference':reference,'alternative':alternative},
  band_width_frame=frame).items():
    object.__setattr__(obj,k,v)
ax=et.plot_covariance_sensitivity_band_widths(obj,coefficient='dose')
native_python_w4=dict(
  labels=[line.get_label() for line in ax.lines[:2]],
  xs=[line.get_xdata().tolist() for line in ax.lines[:2]],
  ys=[line.get_ydata().tolist() for line in ax.lines[:2]],
  ref=ax.lines[-1].get_ydata().tolist(),
  title=ax.get_title(),xlabel=ax.get_xlabel(),ylabel=ax.get_ylabel())
")
  f<-.etr_paired_band_fixture()
  native<-.etr_joint_source_band_width_frame(f$fits,f$bands,"reference")
  source<-reticulate::py_eval("frame",convert=TRUE)
  expect_equal(native$band_width_ratio_to_reference,
    as.numeric(source$band_width_ratio_to_reference),tolerance=0)
  labels<-reticulate::py_eval("native_python_w4['labels']",convert=TRUE)
  expect_identical(as.character(unlist(labels)),c("reference","alternative"))
  y<-reticulate::py_eval("native_python_w4['ys']",convert=TRUE)
  expect_equal(as.numeric(unlist(y)),c(rep(1,3),rep(1.5,3)))
  expect_identical(reticulate::py_eval("native_python_w4['title']"),
    "Covariance sensitivity of band width: dose")
  expect_identical(reticulate::py_eval("native_python_w4['ylabel']"),
    "Band-width ratio to reference")
})
