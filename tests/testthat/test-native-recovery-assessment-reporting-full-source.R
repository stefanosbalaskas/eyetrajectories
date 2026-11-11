# Full developer native-semantic review of frozen Python 1.2 recovery.py
# FunctionalRecoveryAssessment dataclass -> assessment_frame + reporting_text.
# Frozen commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Python dataclass/pandas class identity is not available natively in R.

.etr_source_recovery_pair_fixture<-function() {
  defs<-etr_functional_recovery_metric_catalog()
  custom<-list(name="  custom_β  ",quantity="  contrast \u2003",
    direction="higher_is_better",units=" score ",scope="curve",
    description="  Bounded mean difference\u00a0")
  list(values=list(
    list(metric=defs[["mean_ise"]],value=.125,
      component=0L,source=" curve_1 "),
    list(metric=defs[["score_correlation"]],value=0.8,
      component=NULL,source=NULL),
    list(metric=custom,value="1_2.5",component="2",
      source=TRUE),
    list(metric=list(name="numeric_field",quantity=2L,
      direction="lower_is_better",units=TRUE,scope=" aggregate ",
      description="Numeric and Boolean meta"),
      value=FALSE,component=1L,source=2L)),
    provenance=list(estimator=list(method="FPCA",resample=list(FALSE,2L))))
}

test_that("source assessment maps built-in, custom, and coerced dataclass fields",{
  x<-.etr_source_recovery_pair_fixture()
  frame<-etr_functional_recovery_assessment_frame(x,python_boundary_mode=TRUE)
  expect_identical(dim(frame),c(4L,9L))
  expect_identical(names(frame),c("metric","value","component","source",
    "quantity","direction","units","scope","description"))
  expect_identical(frame$metric,c("mean_ise","score_correlation",
    "custom_β","numeric_field"))
  expect_equal(frame$value,c(.125,.8,12.5,0),tolerance=0)
  expect_equal(frame$component,c(1,NA,3,2),tolerance=0)
  expect_identical(frame$source,c("curve_1",NA,"True","2"))
  expect_identical(frame$quantity[4L],"2")
  expect_identical(frame$units[4L],"True")
  expect_identical(frame$direction[3L],"higher_is_better")
  expect_identical(frame$description[3L],"Bounded mean difference")
  expect_identical(frame$scope[4L],"aggregate")
})

test_that("same source assessment generates sorted metric families and Python repr",{
  x<-.etr_source_recovery_pair_fixture()
  label<-etr_functional_recovery_reporting_text(x,
    python_boundary_mode=TRUE)
  expect_match(label,
    "estimator {'method': 'FPCA', 'resample': [False, 2]}",fixed=TRUE)
  expect_match(label,
    "Recorded metric families: custom_β, mean_ise, numeric_field, score_correlation.",
    fixed=TRUE)
  expect_match(label,"not an estimator-tuning input.",fixed=TRUE)
  x$provenance<-list(estimator=list(NULL,TRUE,Inf,NaN))
  label<-etr_functional_recovery_reporting_text(x,python_boundary_mode=TRUE)
  expect_match(label,"[None, True, inf, nan]",fixed=TRUE)
  x$provenance<-list()
  expect_match(etr_functional_recovery_reporting_text(x,TRUE),
    "estimator 'unspecified'",fixed=TRUE)
  x$provenance<-list(estimator=NULL)
  expect_match(etr_functional_recovery_reporting_text(x,TRUE),
    "estimator None",fixed=TRUE)
})

test_that("native source contract rejects constructor-invalid semantic assessments",{
  x<-.etr_source_recovery_pair_fixture()
  invalid<-list(
    list(values=list()),
    list(values=list(list(metric=x$values[[1L]]$metric,value=NaN))),
    list(values=list(list(metric=x$values[[1L]]$metric,value=Inf))),
    list(values=list(list(metric=x$values[[1L]]$metric,value=1,component=-1L))),
    list(values=list(list(metric=x$values[[1L]]$metric,value=1,source="  "))))
  for(z in invalid)
    expect_error(etr_functional_recovery_assessment_frame(z,TRUE))
  duplicate<-list(values=list(x$values[[1L]],x$values[[1L]]))
  expect_error(etr_functional_recovery_assessment_frame(duplicate,TRUE),
    "duplicate metric")
  wrong<-x;x$values[[4L]]$metric$direction<-"not_a_direction"
  expect_error(etr_functional_recovery_assessment_frame(x,TRUE),
    "valid direction")
  expect_error(etr_functional_recovery_assessment_frame(wrong,
    python_boundary_mode=NA),"TRUE or FALSE")
})

test_that("real frozen Python typed recovery assessment agrees in nine columns and text",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 typed semantic assessment oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.recovery import (
    FunctionalRecoveryMetric as _FM,
    FunctionalRecoveryValue as _FV,
    FunctionalRecoveryAssessment as _FA,
    METRIC_CATALOG as _MC,
    functional_recovery_assessment_frame as _frame,
    functional_recovery_reporting_text as _text)
def _recovery_pair_oracle():
    custom = _FM(name='  custom_β  ',quantity='  contrast \u2003',
        direction='higher_is_better',units=' score ',scope='curve',
        description='  Bounded mean difference\u00a0')
    mixed = _FM(name='numeric_field',quantity=2,
        direction='lower_is_better',units=True,scope=' aggregate ',
        description='Numeric and Boolean meta')
    values = (
        _FV(metric=_MC['mean_ise'],value=.125,
            component=0,source=' curve_1 '),
        _FV(metric=_MC['score_correlation'],value=.8),
        _FV(metric=custom,value='1_2.5',component='2',
            source=True),
        _FV(metric=mixed,value=False,component=1,source=2))
    assessment=_FA(values=values,
        provenance={'estimator':{
            'method':'FPCA','resample':[False,2]}})
    frame=_frame(assessment)
    return frame.to_dict(orient='list'),_text(assessment)
def _recovery_invalid_oracle():
    out=[]
    try: _FA(values=())
    except Exception as e: out.append(type(e).__name__)
    try: _FV(metric=_MC['mean_ise'],value=float('nan'))
    except Exception as e: out.append(type(e).__name__)
    try: _FV(metric=_MC['mean_ise'],value=1.0,component=-1)
    except Exception as e: out.append(type(e).__name__)
    try: _FA(values=(_FV(metric=_MC['mean_ise'],value=.1),)*2)
    except Exception as e: out.append(type(e).__name__)
    return out
")
  native<-.etr_source_recovery_pair_fixture()
  actual<-etr_functional_recovery_assessment_frame(native,TRUE)
  expected<-reticulate::py_to_r(reticulate::py_call(
    reticulate::py_eval("_recovery_pair_oracle",convert=FALSE)))
  source_cols<-expected[[1L]]
  expect_identical(names(actual),names(source_cols))
  for(col in names(actual)){
    target<-unlist(source_cols[[col]],use.names=FALSE)
    if(col=="component") {
      expect_equal(actual[[col]][!is.na(actual[[col]])],
        as.numeric(target[!is.na(target)]),tolerance=0)
      expect_identical(is.na(actual[[col]]),is.na(target))
    } else if(col=="value"){
      expect_equal(actual[[col]],as.numeric(target),tolerance=0)
    } else {
      expect_identical(actual[[col]],as.character(target))
    }
  }
  expect_identical(etr_functional_recovery_reporting_text(native,TRUE),
    as.character(expected[[2L]]))
  expect_identical(unlist(reticulate::py_to_r(reticulate::py_call(
    reticulate::py_eval("_recovery_invalid_oracle",convert=FALSE))),
    use.names=FALSE),rep("ValueError",4L))
})
