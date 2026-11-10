# Pinned Python 1.2: simulate.py::FunctionalRecoveryRecord.__post_init__,
# functional_recovery_frame, functional_recovery_failure_frame and
# functional_recovery_summary_frame. Native-language semantic mapping only.

.etr_recovery_source_records_fixture <- function() {
  new_record <- function(scenario, replicate, seed, metrics,
                         status="ok", error_type=NULL, error_message=NULL) {
    list(scenario_name=scenario,replicate=as.integer(replicate),
      seed=as.integer(seed),metrics=metrics,metric_values=list(),
      status=status,error_type=error_type,error_message=error_message)
  }
  list(
    new_record("β",0L,11L,
      stats::setNames(c("1.5","2.5"),c(" score ","score"))),
    new_record("β",1L,12L,numeric(0),status="fit_failed",
      error_type="  RuntimeError ",error_message=" fit failed "),
    new_record("α",0L,13L,stats::setNames(TRUE," score ")),
    new_record("β",2L,14L,stats::setNames(5.5,"score")),
    new_record("α",1L,15L,numeric(0),status="simulation_failed",
      error_type="  ValueError ",error_message=" bad simulation "),
    new_record("γ",0L,16L,numeric(0),status="recovery_failed",
      error_type="  ArithmeticError ",error_message=" bad recovery ")
  )
}

test_that("source constructor trims, coerces and last-wins duplicate metric keys", {
  result<-etr_functional_recovery_result(.etr_recovery_source_records_fixture())
  expect_s3_class(result,"etr_functional_recovery_result")
  expect_identical(names(result$records[[1L]]$metrics),"score")
  expect_equal(unname(result$records[[1L]]$metrics),2.5,tolerance=0)
  expect_identical(result$records[[3L]]$metrics,c(score=1))
  expect_identical(result$records[[2L]]$error_type,"RuntimeError")
  expect_identical(result$records[[2L]]$error_message,"fit failed")
  expect_identical(result$records[[5L]]$error_type,"ValueError")
  expect_identical(result$records[[6L]]$error_type,"ArithmeticError")

  records<-.etr_recovery_source_records_fixture()
  records[[1L]]$metrics<-stats::setNames(1,"  ")
  expect_error(etr_functional_recovery_result(records),
    "nonblank names")
  records[[1L]]$metrics<-stats::setNames("not a number","score")
  expect_error(etr_functional_recovery_result(records),
    "finite numeric values")
  records[[1L]]$metrics<-stats::setNames("Inf","score")
  expect_error(etr_functional_recovery_result(records),
    "finite numeric values")
  records<-.etr_recovery_source_records_fixture()
  records[[2L]]$error_type<-"  "
  expect_error(etr_functional_recovery_result(records),
    "error type and message")
})

test_that("Python float ASCII literal semantics are preserved in recovery metrics", {
  good<-c("1_000"," +1_2.5_0e+1_0 "," .5_0 ","-0_0","1_0.")
  expected<-c(1000,125000000000,0.5,0,10)
  for(i in seq_along(good)) {
    records<-.etr_recovery_source_records_fixture()
    records[[1L]]$metrics<-stats::setNames(good[[i]],"score")
    native<-etr_functional_recovery_result(records)
    expect_equal(unname(native$records[[1L]]$metrics),expected[[i]],
      tolerance=0,info=good[[i]])
  }
  for(bad in c("1__0","1_.0","1._0","1e+_2","0x1p2","0b10",
               "1,000","NaN","Infinity")) {
    records<-.etr_recovery_source_records_fixture()
    records[[1L]]$metrics<-stats::setNames(bad,"score")
    expect_error(etr_functional_recovery_result(records),
      "finite numeric values",info=bad)
  }
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python source float() comparison requires Python oracle")
  expect_identical(et_python_version(),"1.2.0")
  for(i in seq_along(good)) {
    literal<-sprintf("%s",encodeString(good[[i]],quote='"'))
    python<-reticulate::py_eval(paste0("float(",literal,")"),convert=TRUE)
    expect_equal(expected[[i]],as.numeric(python),tolerance=0,info=good[[i]])
  }
  for(bad in c("1__0","1_.0","1._0","1e+_2","0x1p2","0b10","1,000")) {
    literal<-encodeString(bad,quote='"')
    expect_error(reticulate::py_eval(paste0("float(",literal,")"),
      convert=TRUE),info=bad)
  }
})

test_that("heterogeneous recovery mappings normalize without losing source order", {
  records<-.etr_recovery_source_records_fixture()
  records[[1L]]$metrics<-stats::setNames(
    list(TRUE,"1_000",2.5),c(" s ","s","t"))
  native<-etr_functional_recovery_result(records)
  expect_identical(native$records[[1L]]$metrics,c(s=1000,t=2.5))
  expect_identical(names(native$records[[1L]]$metrics),c("s","t"))
  records[[1L]]$metrics<-list()
  expect_error(etr_functional_recovery_result(records),
    "successful records require at least one metric")
  records[[1L]]$metrics<-list(score=1+1i)
  expect_error(etr_functional_recovery_result(records),"finite named numeric-like")
  records[[1L]]$metrics<-list(score=c(1,2))
  expect_error(etr_functional_recovery_result(records),"finite numeric values")
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Heterogeneous dict oracle requires frozen Python 1.2")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.simulate import FunctionalRecoveryRecord as _Rec
_hetero = _Rec(scenario_name='beta',replicate=0,seed=11,
  metrics={' s ':True,'s':'1_000','t':2.5})
_hetero_keys = list(_hetero.metrics)
_hetero_values = list(_hetero.metrics.values())
")
  expect_identical(as.character(reticulate::py_to_r(reticulate::py_eval(
    "_hetero_keys",convert=FALSE))),c("s","t"))
  expect_equal(as.numeric(reticulate::py_to_r(reticulate::py_eval(
    "_hetero_values",convert=FALSE))),unname(native$records[[1L]]$metrics),
    tolerance=0)
})

test_that("source-normalized records feed three native recovery frames", {
  result<-etr_functional_recovery_result(.etr_recovery_source_records_fixture())
  values<-etr_functional_recovery_frame(result)
  expect_identical(values$scenario,c("β","α","β"))
  expect_identical(values$metric,rep("score",3))
  expect_equal(values$value,c(2.5,1,5.5),tolerance=0)
  expect_identical(as.integer(values$seed),c(11L,13L,14L))
  failure<-etr_functional_recovery_failure_frame(result)
  expect_identical(failure$scenario,c("α","β","γ"))
  expect_identical(failure$n_total,c(2L,3L,1L))
  expect_identical(failure$n_success,c(1L,2L,0L))
  expect_identical(failure$n_failed,c(1L,1L,1L))
  expect_equal(failure$failure_proportion,c(.5,1/3,1))
  expect_equal(failure$failure_mcse,
    sqrt(c(.5*.5/2,(1/3)*(2/3)/3,0)),tolerance=1e-15)
  summary<-etr_functional_recovery_summary_frame(
    result,python_boundary_mode=TRUE)
  expect_identical(summary$scenario,c("α","β"))
  expect_identical(summary$n,c(1L,2L))
  expect_equal(summary$mean,c(1,4),tolerance=1e-14)
  expect_equal(summary$median,c(1,4),tolerance=1e-14)
  expect_equal(summary$failure_proportion,c(.5,1/3))
})

test_that("all three recovery frames agree with the frozen Python record oracle", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 recovery record normalization oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy.simulate import (
  FunctionalRecoveryRecord as _R,
  FunctionalRecoveryResult as _Result,
  functional_recovery_frame as _frame,
  functional_recovery_failure_frame as _failure,
  functional_recovery_summary_frame as _summary
)
_etr_records = (
 _R(scenario_name='β',replicate=0,seed=11,
    metrics={' score ':'1.5','score':'2.5'}),
 _R(scenario_name='β',replicate=1,seed=12,
    metrics={},status='fit_failed',
    error_type='  RuntimeError ',error_message=' fit failed '),
 _R(scenario_name='α',replicate=0,seed=13,metrics={' score ':True}),
 _R(scenario_name='β',replicate=2,seed=14,metrics={'score':5.5}),
 _R(scenario_name='α',replicate=1,seed=15,
    metrics={},status='simulation_failed',
    error_type='  ValueError ',error_message=' bad simulation '),
 _R(scenario_name='γ',replicate=0,seed=16,
    metrics={},status='recovery_failed',
    error_type='  ArithmeticError ',error_message=' bad recovery ')
)
_etr_result = _Result(records=_etr_records)
_etr_value_table = _frame(_etr_result)
_etr_failure_table = _failure(_etr_result)
_etr_summary_table = _summary(_etr_result)
_etr_source_mapping = dict(_etr_records[0].metrics)
_etr_source_error = (_etr_records[1].error_type,
                     _etr_records[1].error_message)
")
  native<-etr_functional_recovery_result(
    .etr_recovery_source_records_fixture())
  expect_equal(as.numeric(reticulate::py_eval(
    "_etr_source_mapping['score']",convert=TRUE)),
    as.numeric(native$records[[1L]]$metrics[[1L]]),tolerance=0)
  expect_identical(as.character(reticulate::py_eval(
    "_etr_source_error[0]",convert=TRUE)),native$records[[2L]]$error_type)
  expect_identical(as.character(reticulate::py_eval(
    "_etr_source_error[1]",convert=TRUE)),native$records[[2L]]$error_message)
  comparisons<-list(
    list(py="_etr_value_table",native=etr_functional_recovery_frame(native),
      character=c("scenario","metric"),numeric=c("replicate","seed","value")),
    list(py="_etr_failure_table",
      native=etr_functional_recovery_failure_frame(native),
      character="scenario",
      numeric=c("n_total","n_success","n_failed",
        "failure_proportion","failure_mcse")),
    list(py="_etr_summary_table",
      native=etr_functional_recovery_summary_frame(
        native,python_boundary_mode=TRUE),
      character=c("scenario","metric"),
      numeric=c("n","mean","sd","median","iqr","q05","q25",
        "q75","q95","mcse_mean","n_total","n_success",
        "n_failed","failure_proportion","failure_mcse"))
  )
  for(spec in comparisons){
    columns<-reticulate::py_to_r(reticulate::py_eval(
      paste0("list(",spec$py,".columns)"),convert=FALSE))
    expect_identical(names(spec$native),
      unname(unlist(columns,use.names=FALSE)),
      info=spec$py)
    for(key in spec$character) {
      wanted<-reticulate::py_to_r(reticulate::py_eval(
        paste0(spec$py,"['",key,"'].tolist()"),convert=FALSE))
      expect_identical(as.character(spec$native[[key]]),
        as.character(unlist(wanted,use.names=FALSE)),
        info=paste(spec$py,key))
    }
    for(key in spec$numeric) {
      wanted<-reticulate::py_to_r(reticulate::py_eval(
        paste0(spec$py,"['",key,"'].tolist()"),convert=FALSE))
      expect_equal(as.numeric(spec$native[[key]]),
        as.numeric(unlist(wanted,use.names=FALSE)),
        tolerance=1e-13,info=paste(spec$py,key))
    }
  }
})
