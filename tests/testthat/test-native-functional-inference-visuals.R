# Stable public scientific names; historical stage numbers are audit metadata.
.etr_test_inference_pdf <- function(f) {
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  f()
}
.etr_test_fos_fixture <- function() {
  time<-as.numeric(0:6)
  dose<-as.numeric(c(-2,-1,0,1,2,3))
  values<-array(NA_real_,c(length(dose),length(time),1L))
  for(i in seq_along(dose))
    values[i,,1L]<-1+.2*time+dose[i]*(.3+.04*time)+
      .08*cos(time+i/2)
  ids<-paste0("curve_",seq_along(dose))
  x<-etr_trajectory_set(time,values,curve_ids=ids,
    dimension_names="x",coordinate_system="arbitrary",time_unit="s")
  design<-data.frame(curve_id=ids,dose=dose)
  list(x=x,design=design,
    fit=etr_fit_function_on_scalar_regression(x,design,predictors="dose"))
}
.etr_test_conformal_fixture <- function() {
  cal<-data.frame(curve_id=c("cal1","cal2","cal3","cal4"),
    score=c(.1,.3,.4,.5))
  test<-data.frame(curve_id=c("t1","t2","t3"),
    score=c(.2,.5,.9))
  list(calibration=cal,test=test,
    cutoff=list(alpha=.2,n_calibration=nrow(cal),threshold=.5),
    training_ids=paste0("train",1:8))
}
.etr_test_mixed_fixture <- function() {
  time<-as.numeric(0:4)
  structure(list(estimator="two_level_functional_method_of_moments",
    converged=TRUE,residual_functions=matrix(0.2,6L,5L),
    time=time,time_unit="s",source_curve_ids=paste0("c",1:6),
    curve_participant_ids=rep(paste0("p",1:3),each=2L),
    coefficient_names=c("Intercept","dose"),
    dimension_name="x",
    coefficient_functions=rbind(1+.1*time,.2+.03*time),
    coefficient_standard_errors=matrix(.05,2L,5L),
    random_basis=diag(length(time)),
    random_intercept_covariance=diag(.04,length(time)),
    residual_variance=.01),
    class="etr_functional_mixed_moments")
}
.etr_test_rqa_bootstrap_fixture <- function(){
  summary<-data.frame(metric=c("recurrence_rate","determinism"),
    mean=c(.45,.6),lower=c(.3,.4),upper=c(.65,.75))
  structure(list(summary_table=summary,
    metrics=summary$metric,unit="curve"),
    class="etr_rqa_metric_bootstrap")
}
test_that("seven new public implementations are scientific and source-blocked",{
  z<-etr_native_parity_catalog()
  funcs<-c("plot_function_on_scalar_coefficients",
    "function_on_scalar_reporting_text",
    "plot_functional_mixed_effects_coefficient",
    "plot_conformal_fpca_anomaly",
    "conformal_fpca_anomaly_reporting_text",
    "plot_rqa_metric_mean_bootstrap",
    "plot_functional_variance_decomposition")
  for(n in funcs) {
    row<-z[z$python_name==n&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",n))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
    expect_true(is.function(get(paste0("etr_",n))))
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate&z$is_python_function),232L)
  expect_equal(sum(z$native_implementation_started),207L)
  expect_equal(sum(z$is_python_function&!z$named_native_candidate),148L)
  expect_equal(sum(z$source_contract_gap_unresolved),53L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_false(any(grepl("stage[0-9]+|etr[0-9]+_",
    getNamespaceExports("eyetrajectories"),ignore.case=TRUE)))
})

test_that("source FOS plot preserves exact observed-grid fit and refuses incorrect bands",{
  x<-.etr_test_fos_fixture()
  .etr_test_inference_pdf(function(){
    curve<-etr_plot_function_on_scalar_coefficients(x$fit,
      coefficient="dose",dimension="x")
    expect_equal(curve$time,x$x$time)
    expect_equal(curve$estimate,as.numeric(x$fit$coefficients[2L,,1L]))
    expect_null(curve$lower)
    by_index<-etr_plot_function_on_scalar_coefficients(x$fit,coefficient=1L)
    expect_equal(curve$estimate,by_index$estimate)
    expect_error(etr_plot_function_on_scalar_coefficients(x$fit,
      coefficient=2L),"zero-based")
    expect_error(etr_plot_function_on_scalar_coefficients(x$fit,
      coefficient="unknown"),"coefficient")
    expect_error(etr_plot_function_on_scalar_coefficients(x$fit,
      coefficient="dose",dimension="invalid"),"dimension")
  })
})

test_that("source FOS reporting does not invent mixed-model or continuous bands",{
  x<-.etr_test_fos_fixture()
  text<-etr_function_on_scalar_reporting_text(x$fit)
  expect_match(text,"ordinary least squares")
  expect_match(text,"predictors: dose; functional dimensions: x")
  expect_match(text,"6 curve-level functional responses")
  expect_match(text,"HC1 sandwich")
  expect_match(text,"not a functional mixed-effects model")
  expect_false(grepl("Wild-bootstrap",text,fixed=TRUE))
  expect_identical(text,etr_function_on_scalar_reporting_text(x$fit))
  expect_error(etr_function_on_scalar_reporting_text(x$fit,band=list()),
    "band.reference")
  bootstrap<-etr_bootstrap_function_on_scalar_coefficients(
    x$fit,n_bootstrap=100L,random_state=71L)
  band<-etr_function_on_scalar_simultaneous_bands(
    bootstrap,confidence_level=.9,simultaneous_scope="coefficient")
  words<-etr_function_on_scalar_reporting_text(x$fit,band=band)
  expect_match(words,"100 rademacher multiplier replicates")
  expect_match(words,"90.0% simultaneous coefficient bands")
  .etr_test_inference_pdf(function(){
    image<-etr_plot_function_on_scalar_coefficients(
      x$fit,coefficient="dose",band=band)
    expect_equal(image$lower,as.numeric(band$lower[2L,,1L]))
    expect_equal(image$upper,as.numeric(band$upper[2L,,1L]))
  })
})

test_that("conformal plot reconstructs conservative greater-or-equal marginal p",{
  x<-.etr_test_conformal_fixture()
  .etr_test_inference_pdf(function(){
    out<-etr_plot_conformal_fpca_anomaly(x)
    # Four calibration scores, p=(1+count(cal>=score))/5
    expect_equal(out$p_value,c(.8,.4,.2))
    expect_identical(out$curve_id,c("t1","t2","t3"))
    expect_equal(out$target_index,c(0L,1L,2L))
    one<-etr_plot_conformal_fpca_anomaly(x,max_targets=1L)
    expect_equal(nrow(one),1L)
    expect_error(etr_plot_conformal_fpca_anomaly(x,
      max_targets=0L),"max_targets")
  })
  text<-etr_conformal_fpca_anomaly_reporting_text(x,n_components=2L)
  expect_match(text,"2 component\\(s\\)")
  expect_match(text,"4 calibration trajectory")
  expect_match(text,"minimum attainable p-value was 0.200")
  expect_match(text,"At alpha=0.200, 1 of 3")
  expect_match(text,"no calibration-conditional",ignore.case=TRUE)
  expect_error(etr_conformal_fpca_anomaly_reporting_text(x),
    "n_components")
})

test_that("mixed model pointwise Wald graphics are not called simultaneous",{
  fit<-.etr_test_mixed_fixture()
  .etr_test_inference_pdf(function(){
    r<-etr_plot_functional_mixed_effects_coefficient(fit,coefficient="dose")
    expect_equal(r$time,fit$time)
    expect_equal(r$estimate,.2+.03*fit$time)
    expect_equal(r$lower,r$estimate-1.959963984540054*.05,
      tolerance=1e-14)
    expect_true(all(r$interval_type=="pointwise_95_Wald_not_simultaneous"))
    expect_error(etr_plot_functional_mixed_effects_coefficient(fit,
      coefficient=2L),"zero-based")
    v<-etr_plot_functional_variance_decomposition(fit)
    expect_equal(unique(v$component),
      c("participant_intercept_variance","residual_variance"))
    expect_equal(v$value[v$component=="residual_variance"],
      rep(.01,5L))
  })
})

test_that("RQA population bootstrap plot retains source percentile geometry",{
  z<-.etr_test_rqa_bootstrap_fixture()
  .etr_test_inference_pdf(function(){
    d<-etr_plot_rqa_metric_mean_bootstrap(z)
    expect_equal(d$mean,c(.45,.6))
    expect_equal(d$lower,c(.3,.4))
    expect_equal(d$upper,c(.65,.75))
    subset<-etr_plot_rqa_metric_mean_bootstrap(z,
      metrics="determinism")
    expect_identical(subset$metric,"determinism")
    expect_error(etr_plot_rqa_metric_mean_bootstrap(z,
      metrics="wrong"),"metrics")
    wrong<-z;wrong$summary_table$lower[1L]<-.6
    expect_error(etr_plot_rqa_metric_mean_bootstrap(wrong),
      "must contain")
  })
})

test_that("published Python 1.2 direct FOS and conformal source oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 real FOS and conformal figure source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  plt<-reticulate::import("matplotlib.pyplot")
  types<-reticulate::import("types")
  pd<-reticulate::import("pandas")
  on.exit(plt$close("all"),add=TRUE)
  x<-.etr_test_fos_fixture()
  py_x<-reticulate::py_call(
    etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$x$time),
    values=reticulate::r_to_py(x$x$values),
    curve_ids=reticulate::r_to_py(as.list(x$x$curve_ids)),
    dimension_names=reticulate::r_to_py(as.list(x$x$dimension_names)),
    coordinate_system="arbitrary",time_unit="s")
  py_design<-pd$DataFrame(reticulate::r_to_py(as.list(x$design)))
  py_fit<-reticulate::py_call(
    etpy_get_export("fit_function_on_scalar_regression"),
    trajectories=py_x,design=py_design,
    predictors=reticulate::r_to_py(list("dose")))
  py_text<-reticulate::py_call(
    etpy_get_export("function_on_scalar_reporting_text"),
    result=py_fit)
  expect_identical(etr_function_on_scalar_reporting_text(x$fit),
    as.character(et_to_r(py_text)))
  ax<-reticulate::py_call(
    etpy_get_export("plot_function_on_scalar_coefficients"),
    result=py_fit,coefficient="dose",dimension="x")
  source_xy<-as.matrix(et_to_r(ax$lines[[0L]]$get_xydata()))
  .etr_test_inference_pdf(function(){
    our<-etr_plot_function_on_scalar_coefficients(x$fit,coefficient="dose")
    expect_equal(our$time,source_xy[,1L],tolerance=0)
    expect_equal(our$estimate,source_xy[,2L],tolerance=1e-10)
  })

  con<-.etr_test_conformal_fixture()
  p<-vapply(con$test$score,function(s)
    (1+sum(con$calibration$score>=s))/
    (1+nrow(con$calibration)),numeric(1L))
  py_con<-types$SimpleNamespace(
    p_values=reticulate::r_to_py(p),
    alpha=.2,n_targets=as.integer(length(p)),
    target_curve_ids=reticulate::r_to_py(as.list(con$test$curve_id)),
    n_components=as.integer(2L),
    n_calibration=as.integer(nrow(con$calibration)),
    nonconformity="integrated_reconstruction_error",
    mahalanobis_covariance=reticulate::r_to_py(NULL),
    review_flags=reticulate::r_to_py(p<=.2),
    minimum_attainable_p=.2)
  python_text<-reticulate::py_call(
    etpy_get_export("conformal_fpca_anomaly_reporting_text"),
    result=py_con,digits=as.integer(3L))
  expect_identical(etr_conformal_fpca_anomaly_reporting_text(
    con,n_components=2L),
    as.character(et_to_r(python_text)))
  ax2<-reticulate::py_call(
    etpy_get_export("plot_conformal_fpca_anomaly"),result=py_con)
  source_offsets<-as.matrix(et_to_r(
    ax2$collections[[0L]]$get_offsets()))
  .etr_test_inference_pdf(function(){
    out<-etr_plot_conformal_fpca_anomaly(con)
    expect_equal(out$target_index,source_offsets[,1L],tolerance=0)
    expect_equal(out$p_value,source_offsets[,2L],tolerance=0)
  })
})
