# Native and real published Python 1.2 complete recovery-frame oracles.

.etr_test_recovery_fixture <- function() {
  metric<-list(name="mean_integrated_error",quantity="integrated_error",
    direction="lower_is_better",units="squared_units",scope="curve",
    description="Integrated reconstruction error")
  value<-function(v)list(metric=metric,value=v,component=0L,source="curve")
  key<-"mean_integrated_error.source_curve.component_1"
  records<-list(
    list(scenario_name="alpha",replicate=0L,seed=100L,status="ok",
      metrics=setNames(.1,key),metric_values=list(value(.1))),
    list(scenario_name="alpha",replicate=1L,seed=101L,status="ok",
      metrics=setNames(.3,key),metric_values=list(value(.3))),
    list(scenario_name="alpha",replicate=2L,seed=102L,
      status="fit_failed",metrics=numeric(0),
      error_type="RuntimeError",error_message="fitter did not converge"),
    list(scenario_name="beta",replicate=0L,seed=200L,status="ok",
      metrics=setNames(.2,key),metric_values=list(value(.2))),
    list(scenario_name="beta",replicate=1L,seed=201L,
      status="recovery_failed",metrics=numeric(0),
      error_type="RuntimeError",error_message="recovery metric undefined"))
  etr_functional_recovery_result(records,list(metric))
}
.etr_test_recovery_pdf<-function(f){
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  f()
}

test_that("native recovery failure inventory retains all attempted replicates",{
  r<-.etr_test_recovery_fixture()
  failures<-etr_functional_recovery_failure_frame(r)
  expect_identical(failures$scenario,c("alpha","beta"))
  expect_equal(failures$n_total,c(3L,2L))
  expect_equal(failures$n_success,c(2L,1L))
  expect_equal(failures$n_failed,c(1L,1L))
  expect_equal(failures$failure_proportion,c(1/3,.5))
  expect_equal(failures$failure_mcse,
    sqrt(c((1/3)*(2/3)/3,.5*.5/2)),tolerance=1e-15)
  expect_true(all(failures$failure_mcse>0))
  expect_error(etr_functional_recovery_result(list()),
    "nonempty")
  records<-r$records
  records[[3L]]$metrics<-c(err=1)
  expect_error(etr_functional_recovery_result(records,r$metric_definitions),
    "no metrics")
})

test_that("recovery evidence preserves semantic 1-based component reporting",{
  r<-.etr_test_recovery_fixture()
  value<-etr_functional_recovery_frame(r)
  expect_equal(nrow(value),3L)
  expect_identical(names(value),c("scenario","replicate","seed",
    "metric","value","component","source","quantity",
    "direction","units","scope"))
  expect_identical(value$scenario,c("alpha","alpha","beta"))
  expect_equal(value$replicate,c(0L,1L,0L))
  expect_equal(value$value,c(.1,.3,.2))
  expect_equal(value$component,rep(1L,3L))
  expect_identical(value$source,rep("curve",3L))
  expect_identical(value$quantity,rep("integrated_error",3L))
  bad<-r$records
  bad[[1L]]$metrics[1L]<-.2
  expect_error(etr_functional_recovery_result(bad,r$metric_definitions),
    "exactly match")
})

test_that("recovery summaries use source sample SD and linear NumPy quantiles",{
  r<-.etr_test_recovery_fixture()
  out<-etr_functional_recovery_summary_frame(r)
  expect_equal(nrow(out),2L)
  expect_identical(out$scenario,c("alpha","beta"))
  a<-out[out$scenario=="alpha",,drop=FALSE]
  expect_equal(a$n,2L)
  expect_equal(a$mean,.2)
  expect_equal(a$median,.2)
  expect_equal(a$sd,sqrt(.02),tolerance=1e-14)
  expect_equal(a$mcse_mean,.1,tolerance=1e-14)
  expect_equal(a$q05,.11,tolerance=1e-14)
  expect_equal(a$q25,.15,tolerance=1e-14)
  expect_equal(a$q75,.25,tolerance=1e-14)
  expect_equal(a$q95,.29,tolerance=1e-14)
  expect_equal(a$iqr,.10,tolerance=1e-14)
  expect_equal(a$n_total,3L)
  expect_equal(a$failure_proportion,1/3)
  b<-out[out$scenario=="beta",,drop=FALSE]
  expect_equal(b$n,1L)
  expect_equal(b$sd,0)
  expect_equal(b$mcse_mean,0)
  .etr_test_recovery_pdf(function(){
    # Includes a zero-width singleton-group IQR; plotting must not warn.
    expect_silent(etr_plot_functional_recovery_summary(out,
      metric="mean_integrated_error",statistic="median"))
    p<-etr_plot_functional_recovery_summary(out,
      metric="mean_integrated_error",statistic="median")
    expect_equal(p$x,c(0L,1L))
    expect_equal(p$estimate,c(.2,.2))
    expect_equal(p$lower,c(.15,.2))
    expect_equal(p$upper,c(.25,.2))
    expect_identical(p$label,c("alpha / curve / C1",
      "beta / curve / C1"))
    meanp<-etr_plot_functional_recovery_summary(out,
      metric="mean_integrated_error",statistic="mean")
    expect_true(all(is.na(meanp$lower)))
    expect_error(etr_plot_functional_recovery_summary(out,
      metric="missing"),"absent")
    expect_error(etr_plot_functional_recovery_summary(out,
      metric="mean_integrated_error",statistic="not_present"),
      "requires")
  })
})

test_that("recovery all-failed source keeps failures and empty typed summary",{
  rows<-list(
    list(scenario_name="all_fail",replicate=0L,seed=9L,
      status="simulation_failed",metrics=numeric(0),
      error_type="ValueError",error_message="bad generator"))
  r<-etr_functional_recovery_result(rows)
  expect_equal(ncol(etr_functional_recovery_frame(r)),0L)
  failure<-etr_functional_recovery_failure_frame(r)
  expect_equal(failure$failure_proportion,1)
  expect_equal(failure$failure_mcse,0)
  summary<-etr_functional_recovery_summary_frame(r)
  expect_equal(nrow(summary),0L)
  expect_equal(ncol(summary),19L)
})

test_that("recovery public function names are stable and fail closed",{
  z<-etr_native_parity_catalog()
  fn<-c("functional_recovery_frame",
    "functional_recovery_failure_frame",
    "functional_recovery_summary_frame",
    "plot_functional_recovery_summary")
  for(n in fn) {
    row<-z[z$python_name==n&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",n))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_gte(sum(z$named_native_candidate&z$is_python_function),236L)
  expect_gte(sum(z$native_implementation_started),211L)
  expect_lte(sum(z$is_python_function&!z$named_native_candidate),144L)
  expect_gte(sum(z$source_contract_gap_unresolved),57L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_false(any(grepl("stage[0-9]+|etr[0-9]+_",
    getNamespaceExports("eyetrajectories"),ignore.case=TRUE)))
})

test_that("real Python 1.2 recovery records verify all frames and plotted points",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 typed recovery evidence oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  sim<-reticulate::import("eyetrajectoriespy.simulate")
  rec<-reticulate::import("eyetrajectoriespy.recovery")
  plt<-reticulate::import("matplotlib.pyplot")
  on.exit(plt$close("all"),add=TRUE)
  native<-.etr_test_recovery_fixture()
  def<-native$metric_definitions[[1L]]
  pd<-reticulate::py_call(rec$FunctionalRecoveryMetric,
    name=def$name,quantity=def$quantity,direction=def$direction,
    units=def$units,scope=def$scope,description=def$description)
  rows<-lapply(native$records,function(z) {
    values<-lapply(if(is.null(z$metric_values))list() else z$metric_values,function(x)
      reticulate::py_call(rec$FunctionalRecoveryValue,
        metric=pd,value=x$value,
        component=as.integer(x$component),source=x$source))
    metrics<-reticulate::dict()
    for(key in names(z$metrics))metrics[[key]]<-as.numeric(z$metrics[[key]])
    reticulate::py_call(sim$FunctionalRecoveryRecord,
      scenario_name=z$scenario_name,
      replicate=as.integer(z$replicate),seed=as.integer(z$seed),
      status=z$status,metrics=metrics,
      metric_values=reticulate::r_to_py(values),
      error_type=if(is.null(z$error_type))NULL else z$error_type,
      error_message=if(is.null(z$error_message))NULL else z$error_message)
  })
  py<-reticulate::py_call(sim$FunctionalRecoveryResult,
    records=reticulate::r_to_py(rows),
    metric_definitions=reticulate::r_to_py(list(pd)))
  ctab<-function(name){
    fn<-etpy_get_export(name)
    as.data.frame(et_to_r(reticulate::py_call(fn,result=py)),
      stringsAsFactors=FALSE)
  }
  for(entry in list(
    list(name="functional_recovery_frame",
      native=etr_functional_recovery_frame(native)),
    list(name="functional_recovery_failure_frame",
      native=etr_functional_recovery_failure_frame(native)),
    list(name="functional_recovery_summary_frame",
      native=etr_functional_recovery_summary_frame(native)))) {
    expected<-ctab(entry$name)
    actual<-entry$native
    expect_identical(names(actual),names(expected))
    expect_equal(nrow(actual),nrow(expected))
    for(k in names(actual)){
      if(is.numeric(actual[[k]]))
        expect_equal(as.numeric(actual[[k]]),
          as.numeric(expected[[k]]),tolerance=1e-12,
          info=paste("source column",entry$name,k))
      else
        expect_identical(as.character(actual[[k]]),
          as.character(expected[[k]]),
          info=paste("source column",entry$name,k))
    }
  }
  summary<-etr_functional_recovery_summary_frame(native)
  pd_frame<-reticulate::import("pandas")$DataFrame(
    reticulate::r_to_py(as.list(summary)))
  ax<-reticulate::py_call(etpy_get_export(
    "plot_functional_recovery_summary"),
    summary=pd_frame,metric="mean_integrated_error")
  xy<-as.matrix(et_to_r(ax$lines[[0L]]$get_xydata()))
  .etr_test_recovery_pdf(function(){
    x<-etr_plot_functional_recovery_summary(summary,
      metric="mean_integrated_error")
    expect_equal(as.numeric(x$x),xy[,1L],tolerance=0)
    expect_equal(as.numeric(x$estimate),xy[,2L],tolerance=1e-12)
  })
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})
