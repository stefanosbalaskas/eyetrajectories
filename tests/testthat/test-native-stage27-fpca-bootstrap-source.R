# Stage 27: exact published Python 1.2 FPCA uncertainty text and plots.
.etr27_fixture <- function(){
  sims<-matrix(c(.9,.8,.75,.85,.95,.8),nrow=3L,ncol=2L)
  scores<-structure(list(similarities=sims,n_components=2L,
    target_curve_ids=c("a","b"),
    reference_scores=matrix(c(.25,.45,-.1,.1),2L,2L),
    median=matrix(c(.2,.4,-.12,.13),2L,2L),
    lower=matrix(c(.15,.35,-.2,.1),2L,2L),
    upper=matrix(c(.3,.5,-.05,.2),2L,2L),
    resampling_unit="curve",target_source="external",level=.9,
    provenance=list(fpca_score_uncertainty=list(scaling="none"))),
    class="etr_fpca_score_uncertainty")
  ref<-list(
    n_components=2L,explained_variance=c(3,1.5),
    explained_variance_ratio=c(.6,.3),
    time=c(0,.5,1),time_unit="s",dimension_names="x",
    components=array(c(.1,.2,.3,-.3,.2,.1),c(2L,3L,1L)))
  spec<-structure(list(similarities=sims,n_components=2L,
    reference=ref,confidence_level=.95,simultaneous_scope="family",
    resampling_unit="curve",eigenvalue_lower=c(2.5,1.2),
    eigenvalue_upper=c(3.5,1.7),
    explained_variance_ratio_lower=c(.55,.25),
    explained_variance_ratio_upper=c(.65,.35),
    cumulative_variance_ratio_lower=c(.55,.85),
    cumulative_variance_ratio_upper=c(.65,.95)),
    class="etr_fpca_spectrum_uncertainty")
  comp<-structure(list(similarities=sims,n_components=2L,
    reference=ref,confidence_level=.95,simultaneous_scope="family",
    resampling_unit="curve",relative_gap_threshold=NULL,
    lower=ref$components-.05,upper=ref$components+.05),
    class="etr_fpca_component_band")
  mean<-structure(list(unit="curve",unit_ids=c("a","b"),
    confidence_level=.95,critical_value=2.4137,
    provenance=list(functional_mean_band=list(n_multiplier=100L))),
    class="etr_functional_mean_band")
  list(scores=scores,spec=spec,comp=comp,mean=mean)
}
.etr27_pdf <- function(fn) {
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  fn()
}

test_that("Stage 27 four report functions have fixed source scientific language",{
  x<-.etr27_fixture()
  a<-etr_fpca_score_uncertainty_reporting_text(x$scores)
  expect_match(a,"3 curve-level bootstrap refits")
  expect_match(a,"2 fixed external target")
  expect_match(a,"FPC1=0.800")
  expect_match(a,"do not include target measurement error")
  expect_identical(a,etr_fpca_score_uncertainty_reporting_text(x$scores))
  b<-etr_fpca_spectrum_uncertainty_reporting_text(x$spec)
  expect_match(b,"95.0% uncertainty intervals")
  expect_match(b,"familywise across the requested components")
  expect_match(b,"0.600")
  expect_match(b,"not clipped to the mathematical support")
  c<-etr_functional_mean_band_reporting_text(x$mean)
  expect_match(c,"2 curve-level inference units")
  expect_match(c,"100 multiplier replicates")
  expect_match(c,"critical value=2.414")
  expect_match(c,"continuous-domain coverage")
  d<-etr_fpca_component_band_reporting_text(x$comp)
  expect_match(d,"FPC1=0.80")
  expect_match(d,"No numerical near-tie threshold")
  expect_match(d,"near-tied individual FPC axis")
  x$comp$relative_gap_threshold<-.1
  x$comp$minimum_relative_gaps<-c(.4,.3)
  d2<-etr_fpca_component_band_reporting_text(x$comp)
  expect_match(d2,"threshold 0.100")
  expect_match(d2,"FPC1=0.400")
  expect_error(etr_fpca_score_uncertainty_reporting_text(x$scores,digits=-1L),
    "digits")
  expect_error(etr_fpca_component_band_reporting_text(x$comp,digits=NA),
    "digits")
})

test_that("Stage 27 target-score plot preserves source medians and envelope",{
  x<-.etr27_fixture()
  .etr27_pdf(function(){
    d<-etr_plot_fpca_score_uncertainty(x$scores,component=0L)
    expect_identical(d$target_curve_id,c("a","b"))
    expect_equal(d$median,c(.2,.4))
    expect_equal(d$reference,c(.25,.45))
    one<-etr_plot_fpca_score_uncertainty(x$scores,component=1L,
      max_targets=1L)
    expect_equal(one$median,-.12)
    expect_equal(one$lower,-.2)
    expect_error(etr_plot_fpca_score_uncertainty(x$scores,
      component=2L),"zero-based")
    expect_error(etr_plot_fpca_score_uncertainty(x$scores,
      max_targets=0L),"max_targets")
  })
})

test_that("Stage 27 spectrum plot leaves unbounded bootstrap intervals intact",{
  x<-.etr27_fixture()
  .etr27_pdf(function(){
    d<-etr_plot_fpca_spectrum_uncertainty(x$spec,
      metric="explained_variance_ratio")
    expect_equal(d$estimate,c(.6,.3))
    expect_equal(d$lower,c(.55,.25))
    e<-etr_plot_fpca_spectrum_uncertainty(x$spec,
      metric="eigenvalue")
    expect_equal(e$estimate,c(3,1.5))
    expect_equal(e$upper,c(3.5,1.7))
    f<-etr_plot_fpca_spectrum_uncertainty(x$spec,
      metric="cumulative_variance_ratio")
    expect_equal(f$estimate,c(.6,.9))
    expect_error(etr_plot_fpca_spectrum_uncertainty(x$spec,
      metric="invalid"),"metric")
  })
})

test_that("Stage 27 component band plot returns exact observed-grid FPC source",{
  x<-.etr27_fixture()
  .etr27_pdf(function(){
    out<-etr_plot_fpca_component_band(x$comp,
      component=0L,dimension="x")
    expect_equal(out$time,c(0,.5,1))
    expect_equal(out$estimate,as.numeric(x$comp$reference$components[1L,,1L]))
    expect_equal(out$lower,as.numeric(x$comp$lower[1L,,1L]))
    expect_equal(out$upper,as.numeric(x$comp$upper[1L,,1L]))
    expect_error(etr_plot_fpca_component_band(x$comp,
      component=-1L),"zero-based")
    expect_error(etr_plot_fpca_component_band(x$comp,
      dimension="unknown"),"dimension")
  })
})

test_that("Stage 27 seven source names map uniquely, uncertified",{
  was<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  names<-c("fpca_score_uncertainty_reporting_text",
    "fpca_spectrum_uncertainty_reporting_text",
    "functional_mean_band_reporting_text",
    "fpca_component_band_reporting_text",
    "plot_fpca_score_uncertainty",
    "plot_fpca_spectrum_uncertainty",
    "plot_fpca_component_band")
  for(p in names){
    r<-z[z$python_name==p&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(r),1L)
    expect_identical(r$native_r_candidate,paste0("etr_",p))
    expect_identical(r$native_implementation_stage,27L)
    expect_true(r$native_implementation_started)
    expect_true(r$source_contract_gap_unresolved)
    expect_false(r$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$native_implementation_started),194L)
  expect_equal(sum(z$named_native_candidate&z$is_python_function),219L)
  expect_equal(sum(z$is_python_function&!z$named_native_candidate),161L)
  expect_equal(sum(z$source_contract_gap_unresolved),40L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 27 direct pinned Python 1.2 report-text oracles are opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 reporting text source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr27_fixture()
  types<-reticulate::import("types")
  mk<-function(...)types$SimpleNamespace(...)
  rpy<-reticulate::r_to_py
  ps<-mk(similarities=rpy(x$scores$similarities),
    n_bootstrap=3L,n_components=2L,n_targets=2L,
    resampling_unit="curve",target_source="external",level=.9,
    provenance=rpy(list(fpca_score_uncertainty=list(scaling="none"))))
  po<-reticulate::py_call(etpy_get_export(
    "fpca_score_uncertainty_reporting_text"),result=ps)
  expect_identical(etr_fpca_score_uncertainty_reporting_text(x$scores),
    as.character(et_to_r(po)))
  sp<-mk(similarities=rpy(x$spec$similarities),
    n_bootstrap=3L,resampling_unit="curve",
    confidence_level=.95,simultaneous_scope="family",
    reference=mk(explained_variance_ratio=rpy(c(.6,.3))))
  po<-reticulate::py_call(etpy_get_export(
    "fpca_spectrum_uncertainty_reporting_text"),result=sp)
  expect_identical(etr_fpca_spectrum_uncertainty_reporting_text(x$spec),
    as.character(et_to_r(po)))
  mean<-mk(n_units=2L,unit="curve",confidence_level=.95,
    critical_value=2.4137,
    provenance=rpy(list(functional_mean_band=list(n_multiplier=100L))))
  po<-reticulate::py_call(etpy_get_export(
    "functional_mean_band_reporting_text"),result=mean)
  expect_identical(etr_functional_mean_band_reporting_text(x$mean),
    as.character(et_to_r(po)))
  bp<-mk(similarities=rpy(x$comp$similarities),
    n_bootstrap=3L,resampling_unit="curve",confidence_level=.95,
    simultaneous_scope="family",relative_gap_threshold=rpy(NULL))
  po<-reticulate::py_call(etpy_get_export(
    "fpca_component_band_reporting_text"),result=bp)
  expect_identical(etr_fpca_component_band_reporting_text(x$comp),
    as.character(et_to_r(po)))
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})
