# Frozen eyetrajectoriespy==1.2.0 @ c1cd95ad718327550f7e55393ff38582872f7a94
# Typed Python scientific results vs Python-free native R S3 semantic records.
.etr_four_fpca_reporting_source_fixture <- function(variant="base") {
  stopifnot(variant %in% c("base","alternate"))
  alt<-identical(variant,"alternate")
  similarities<-matrix(c(.90,.80,.75,.85,.95,.80),3L,2L)
  score<-structure(list(
    similarities=similarities,n_components=2L,
    target_curve_ids=c("a","b"),median=matrix(0,2L,2L),
    level=.9,resampling_unit="curve",target_source="external",
    provenance=list(fpca_score_uncertainty=list(
      scaling=if(alt) "Fisher's σ" else "none"))),
    class="etr_fpca_score_uncertainty")
  spectrum<-structure(list(
    similarities=similarities,reference=list(explained_variance_ratio=c(.6,.3)),
    confidence_level=.95,simultaneous_scope=if(alt) "component" else "family",
    resampling_unit="participant"),
    class="etr_fpca_spectrum_uncertainty")
  band<-structure(list(
    similarities=similarities,confidence_level=.95,
    simultaneous_scope=if(alt) "component" else "family",
    resampling_unit="curve",
    relative_gap_threshold=if(alt) .1 else NULL,
    minimum_relative_gaps=c(.4,.3)),
    class="etr_fpca_component_band")
  mean<-structure(list(
    confidence_level=.95,critical_value=2.4137,
    unit="participant",unit_ids=c("a","b"),
    provenance=list(functional_mean_band=list(
      n_multiplier=137L,
      estimand=if(alt) "Student's weighted mean" else "unspecified"))),
    class="etr_functional_mean_band")
  list(score=score,spectrum=spectrum,band=band,mean=mean)
}
.etr_four_fpca_reporting_source_texts <- function(z,digits) {
  c(
    etr_fpca_score_uncertainty_reporting_text(z$score,digits),
    etr_fpca_spectrum_uncertainty_reporting_text(z$spectrum,digits),
    etr_fpca_component_band_reporting_text(z$band,digits),
    etr_functional_mean_band_reporting_text(z$mean,digits))
}
test_that("four uncertainty manuscript contracts retain complete caveats", {
  base<-.etr_four_fpca_reporting_source_texts(
    .etr_four_fpca_reporting_source_fixture(),3L)
  alt<-.etr_four_fpca_reporting_source_texts(
    .etr_four_fpca_reporting_source_fixture("alternate"),2L)
  expect_identical(length(base),4L)
  expect_true(all(nzchar(base)))
  expect_match(base[[1L]],"FPC1=0.800",fixed=TRUE)
  expect_match(base[[1L]],"do not include target measurement error",fixed=TRUE)
  expect_match(base[[2L]],"familywise across the requested",fixed=TRUE)
  expect_match(base[[2L]],"not clipped to the mathematical support",fixed=TRUE)
  expect_match(base[[3L]],"No numerical near-tie threshold",fixed=TRUE)
  expect_match(base[[3L]],"does not establish continuous-domain",fixed=TRUE)
  expect_match(base[[4L]],"137 multiplier replicates",fixed=TRUE)
  expect_match(base[[4L]],"critical value=2.414",fixed=TRUE)
  expect_match(alt[[1L]],'scaling="Fisher\'s σ"',fixed=TRUE)
  expect_match(alt[[3L]],"minimum adjacent gaps: FPC1=0.400",fixed=TRUE)
  expect_match(alt[[4L]],'estimand="Student\'s weighted mean"',fixed=TRUE)
})
test_that("full-source uncertainty reports reject malformed native records", {
  z<-.etr_four_fpca_reporting_source_fixture()
  score<-z$score;score$median<-matrix(0,1L,2L)
  expect_error(etr_fpca_score_uncertainty_reporting_text(score),"geometry")
  score<-z$score;score$similarities[1L,1L]<-Inf
  expect_error(etr_fpca_score_uncertainty_reporting_text(score),"similarities")
  spec<-z$spectrum;spec$simultaneous_scope<-"unknown"
  expect_error(etr_fpca_spectrum_uncertainty_reporting_text(spec),"scope")
  band<-z$band;band$relative_gap_threshold<-.1
  band$minimum_relative_gaps<-1
  expect_error(etr_fpca_component_band_reporting_text(band),"relative-gap")
  mean<-z$mean;mean$critical_value<-NA_real_
  expect_error(etr_functional_mean_band_reporting_text(mean),"valid native")
  expect_error(etr_fpca_component_band_reporting_text(z$band,-1L),"digits")
  expect_error(etr_functional_mean_band_reporting_text(z$mean,NA),"digits")
})
test_that("32 typed frozen Python 1.2 reporting strings agree exactly with native R", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen typed Python 1.2 source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_four_typed(cls,**fields):",
    "    x=object.__new__(cls)",
    "    for k,v in fields.items(): object.__setattr__(x,k,v)",
    "    return x",
    "def _etr_four_uncertainty_text(variant,digits):",
    "    alt=(variant=='alternate')",
    "    sims=np.array([[.90,.85],[.80,.95],[.75,.80]])",
    "    reference=_etr_four_typed(et.FPCAResult,",
    "      explained_variance_ratio=np.array([.6,.3]))",
    "    score=_etr_four_typed(et.FPCAScoreUncertaintyResult,",
    "      similarities=sims,bootstrap_scores=np.zeros((3,2,2)),",
    "      resampling_unit='curve',target_source='external',level=.9,",
    "      provenance={'fpca_score_uncertainty':",
    "         {'scaling': \"Fisher's σ\" if alt else 'none'}})",
    "    spectrum=_etr_four_typed(et.FPCASpectrumUncertaintyResult,",
    "      reference=reference,similarities=sims,",
    "      bootstrap_eigenvalues=np.zeros((3,2)),",
    "      confidence_level=.95,simultaneous_scope='component' if alt else 'family',",
    "      resampling_unit='participant')",
    "    band=_etr_four_typed(et.FPCAComponentBandResult,",
    "      similarities=sims,confidence_level=.95,",
    "      simultaneous_scope='component' if alt else 'family',",
    "      resampling_unit='curve',relative_gap_threshold=.1 if alt else None,",
    "      minimum_relative_gaps=np.array([.4,.3]))",
    "    mean=_etr_four_typed(et.FunctionalMeanBandResult,",
    "      confidence_level=.95,critical_value=2.4137,",
    "      unit='participant',unit_ids=('a','b'),",
    "      provenance={'functional_mean_band':",
    "         {'n_multiplier':137,",
    "          'estimand':\"Student's weighted mean\" if alt else 'unspecified'}})",
    "    return [",
    "      et.fpca_score_uncertainty_reporting_text(score,digits=digits),",
    "      et.fpca_spectrum_uncertainty_reporting_text(spectrum,digits=digits),",
    "      et.fpca_component_band_reporting_text(band,digits=digits),",
    "      et.functional_mean_band_reporting_text(mean,digits=digits)]"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_four_uncertainty_text")
  for(variant in c("base","alternate")) {
    z<-.etr_four_fpca_reporting_source_fixture(variant)
    for(digits in c(0L,2L,3L,5L)) {
      expected<-reticulate::py_to_r(
        reticulate::py_call(oracle,variant,as.integer(digits)))
      actual<-.etr_four_fpca_reporting_source_texts(z,digits)
      expect_identical(length(actual),length(expected))
      for(i in seq_along(actual))
        expect_identical(actual[[i]],as.character(expected[[i]]),
          info=paste(variant,digits,i))
    }
  }
})
