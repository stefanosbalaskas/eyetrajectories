# Frozen Python eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# reporting.py::function_on_scalar_reporting_text and
# reporting.py::conformal_fpca_anomaly_reporting_text.
# Typed, identity-matched Python object oracle vs native scientific R records.

.etr_two_report_fos_fixture <- function(variant="curve",replicates=1L) {
  stopifnot(variant%in%c("curve","participant","unicode"))
  unit<-if(variant=="participant")"participant" else "curve"
  ids<-if(unit=="participant")c("participant-A","participant-B") else
    c("curve-A","curve-B")
  predictor<-if(variant=="unicode")c("fish's β","treatment") else
    c("dose","treatment")
  fit<-structure(list(
    design_matrix=matrix(1,2L,2L),
    coefficients=array(0,dim=c(2L,3L,1L)),
    standard_errors=array(.1,dim=c(2L,3L,1L)),
    fitted_functions=array(0,dim=c(2L,3L,1L)),
    residual_functions=array(0,dim=c(2L,3L,1L)),
    predictor_names=predictor,dimension_names=
      if(variant=="unicode")"μικροκίνηση" else "pupil",
    unit=unit,unit_ids=ids,
    source_curve_ids=if(unit=="participant")paste0("curve-",1:4) else ids),
    class="etr_function_on_scalar")
  boot<-list(bootstrap_coefficients=array(0,
    dim=c(as.integer(replicates),2L,3L,1L)),multiplier="mammen")
  band<-structure(list(reference=fit,bootstrap=boot,
    confidence_level=.90,simultaneous_scope="joint"),
    class="etr_function_on_scalar_band")
  list(result=fit,band=band)
}
.etr_two_report_conformal_fixture<-function(kind="rmse"){
  stopifnot(kind%in%c("rmse","empirical","robust","all_flagged"))
  cal<-c(.1,.25,.3,.7)
  targets<-if(kind=="all_flagged")c(1.,1.5) else c(.15,.35,.8)
  p<-vapply(targets,function(s)
    (1+sum(cal>=s))/(length(cal)+1),numeric(1L))
  list(
    calibration_scores=cal,target_scores=targets,
    p_values=p,review_flags=p<=.25,
    n_components=if(kind=="robust")3L else 2L,
    alpha=.25,nonconformity=if(kind=="rmse"||
      kind=="all_flagged")"reconstruction_rmse" else
        "score_mahalanobis",
    mahalanobis_covariance=if(kind=="empirical")"empirical" else
      if(kind=="robust")"robust" else NULL)
}
test_that("FOS source reporting accepts a one-replicate typed band and Unicode",{
  for(variant in c("curve","participant","unicode")){
    z<-.etr_two_report_fos_fixture(variant,1L)
    text<-etr_function_on_scalar_reporting_text(z$result,z$band)
    expect_type(text,"character")
    expect_length(text,1L)
    expect_match(text,"1 mammen multiplier replicates",fixed=TRUE)
    if(variant=="participant")
      expect_match(text,"participant-average",fixed=TRUE)
    if(variant=="unicode")
      expect_match(text,"fish's β",fixed=TRUE)
    expect_false(grepl("mixed-effects model was fitted",text,fixed=TRUE))
  }
  z<-.etr_two_report_fos_fixture("curve",100L)
  expect_match(etr_function_on_scalar_reporting_text(z$result,z$band),
    "100 mammen multiplier replicates",fixed=TRUE)
  expect_false(grepl("Wild-bootstrap",
    etr_function_on_scalar_reporting_text(z$result),fixed=TRUE))
  bad<-z$band;bad$reference<-list()
  expect_error(etr_function_on_scalar_reporting_text(z$result,bad),
    "band.reference")
  bad<-z$band;bad$bootstrap$bootstrap_coefficients<-array(0,
    dim=c(0L,2L,3L,1L))
  expect_error(etr_function_on_scalar_reporting_text(z$result,bad),
    "bootstrap metadata")
})
test_that("source conformal text reads FPCA count and Mahalanobis metadata",{
  for(kind in c("rmse","empirical","robust","all_flagged")){
    z<-.etr_two_report_conformal_fixture(kind)
    for(digits in c(0L,1L,3L,6L,12L)){
      text<-etr_conformal_fpca_anomaly_reporting_text(z,digits=digits)
      expect_length(text,1L)
      expect_match(text,paste0(z$n_components," component(s)"),
        fixed=TRUE)
      if(!is.null(z$mahalanobis_covariance))
        expect_match(text,paste("using",z$mahalanobis_covariance,
          "score covariance"),fixed=TRUE)
      else expect_false(grepl("score covariance",text,fixed=TRUE))
      expect_match(text,z$nonconformity,fixed=TRUE)
    }
  }
  z<-.etr_two_report_conformal_fixture("rmse")
  bad<-z;bad$review_flags<-c(TRUE,FALSE)
  expect_error(etr_conformal_fpca_anomaly_reporting_text(bad),
    "review_flags")
  bad<-z;bad$alpha<-NaN
  expect_error(etr_conformal_fpca_anomaly_reporting_text(bad),"alpha")
  expect_error(etr_conformal_fpca_anomaly_reporting_text(z,
    n_components=3L),"disagrees")
  expect_error(etr_conformal_fpca_anomaly_reporting_text(z,
    digits=13L),"digits")
  legacy<-list(calibration=data.frame(curve_id="c",score=.2),
    test=data.frame(curve_id="t",score=.5),
    cutoff=list(alpha=.2),training_ids=c("a","b"))
  expect_error(etr_conformal_fpca_anomaly_reporting_text(legacy),
    "n_components")
  expect_match(etr_conformal_fpca_anomaly_reporting_text(
    legacy,n_components=2L),"2 component(s)",fixed=TRUE)
})
test_that("source Python 1.2 exact strings match nine typed FOS/conformal variants",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 typed reporting source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_two_report_new(cls,**data):",
    "    o=object.__new__(cls)",
    "    for k,v in data.items():object.__setattr__(o,k,v)",
    "    return o",
    "def _etr_two_report_fos(variant,n):",
    "    participant=(variant=='participant')",
    "    ids=('participant-A','participant-B') if participant else ('curve-A','curve-B')",
    "    predictors=(\"fish's β\",'treatment') if variant=='unicode' else ('dose','treatment')",
    "    fit=_etr_two_report_new(et.FunctionOnScalarResult,",
    "      predictor_names=predictors,",
    "      dimension_names=('μικροκίνηση',) if variant=='unicode' else ('pupil',),",
    "      unit='participant' if participant else 'curve',",
    "      unit_ids=ids,",
    "      source_curve_ids=tuple('curve-'+str(i) for i in range(1,5)) if participant else ids)",
    "    boot=_etr_two_report_new(et.FunctionOnScalarBootstrapResult,",
    "      bootstrap_coefficients=np.zeros((n,2,3,1)),multiplier='mammen')",
    "    band=_etr_two_report_new(et.FunctionOnScalarBandResult,",
    "      reference=fit,bootstrap=boot,confidence_level=.90,",
    "      simultaneous_scope='joint')",
    "    return (et.function_on_scalar_reporting_text(fit),",
    "      et.function_on_scalar_reporting_text(fit,band=band))",
    "def _etr_two_report_conformal(kind,digits):",
    "    cal=np.array([.1,.25,.3,.7])",
    "    targets=np.array([1.,1.5]) if kind=='all_flagged' else np.array([.15,.35,.8])",
    "    pp=np.array([(1+np.sum(cal>=x))/(1+len(cal)) for x in targets])",
    "    nc=3 if kind=='robust' else 2",
    "    nonc='reconstruction_rmse' if kind in ('rmse','all_flagged') else 'score_mahalanobis'",
    "    cov='empirical' if kind=='empirical' else 'robust' if kind=='robust' else None",
    "    z=_etr_two_report_new(et.ConformalFunctionalAnomalyResult,",
    "      calibration_scores=cal,target_scores=targets,p_values=pp,",
    "      review_flags=pp<=.25,n_components=nc,alpha=.25,",
    "      nonconformity=nonc,mahalanobis_covariance=cov)",
    "    return et.conformal_fpca_anomaly_reporting_text(z,digits=digits)"
  ),collapse="\n"),convert=FALSE)
  fosOracle<-reticulate::py_get_attr(reticulate::py,
    "_etr_two_report_fos")
  conOracle<-reticulate::py_get_attr(reticulate::py,
    "_etr_two_report_conformal")
  for(variant in c("curve","participant","unicode")){
    for(n in c(1L,100L)){
      z<-.etr_two_report_fos_fixture(variant,n)
      expected<-reticulate::py_to_r(reticulate::py_call(
        fosOracle,variant,n))
      expect_identical(etr_function_on_scalar_reporting_text(z$result),
        as.character(expected[[1L]]),
        info=paste("FOS no band",variant,n))
      expect_identical(etr_function_on_scalar_reporting_text(
        z$result,z$band),as.character(expected[[2L]]),
        info=paste("FOS band",variant,n))
    }
  }
  for(kind in c("rmse","empirical","robust","all_flagged")){
    z<-.etr_two_report_conformal_fixture(kind)
    for(digits in c(0L,1L,3L,6L,12L)){
      expected<-reticulate::py_to_r(reticulate::py_call(
        conOracle,kind,digits))
      actual<-etr_conformal_fpca_anomaly_reporting_text(z,digits=digits)
      expect_identical(actual,as.character(expected),
        info=paste("Conformal",kind,digits))
    }
  }
})
