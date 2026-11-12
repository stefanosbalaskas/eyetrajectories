# Stage 29: three native source TE visualization contracts, including
# direct published Python 1.2 real-result Matplotlib geometry probes.

.etr_test_transfer_entropy_pdf <- function(fn){
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  fn()
}
.etr_test_transfer_entropy_fixture <- function() {
  spec<-structure(list(
    table=data.frame(target_history=c(1L,1L,1L),
      source_history=c(1L,1L,1L),
      source_lag=c(1L,2L,3L),
      transfer_entropy_bits=c(.5,.75,.4)),
    parameter_columns=c("target_history","source_history","source_lag"),
    metric_columns="transfer_entropy_bits"),
    class="etr_transfer_entropy_sensitivity")
  surrogate<-c(.11,.29,.38,.53,.77,.91)
  te<-structure(list(
    surrogate_transfer_entropy_bits=surrogate,
    observed=list(transfer_entropy_bits=.42),
    shifts=c(1L,2L,3L,4L,5L,6L)),
    class="etr_transfer_entropy_circular_shift_test")
  cte<-structure(list(
    surrogate_conditional_transfer_entropy_bits=surrogate+.04,
    observed=list(conditional_transfer_entropy_bits=.46),
    shifts=c(1L,2L,3L,4L,5L,6L)),
    class="etr_conditional_transfer_entropy_circular_shift_test")
  list(spec=spec,te=te,cte=cte)
}

test_that("source TE sensitivity never averages tuning specifications",{
  z<-.etr_test_transfer_entropy_fixture()
  .etr_test_transfer_entropy_pdf(function(){
    x<-etr_plot_transfer_entropy_sensitivity(z$spec,
      parameter="source_lag")
    expect_identical(x$source_lag,c(1L,2L,3L))
    expect_equal(x$transfer_entropy_bits,c(.5,.75,.4))
    y<-z$spec
    y$table<-rbind(y$table,y$table[2L,,drop=FALSE])
    y$table$target_history[4L]<-2L
    expect_error(etr_plot_transfer_entropy_sensitivity(y,
      parameter="source_lag"),"multiple rows")
    x<-etr_plot_transfer_entropy_sensitivity(y,parameter="source_lag",
      filters=list(target_history=1L))
    expect_equal(nrow(x),3L)
    expect_error(etr_plot_transfer_entropy_sensitivity(y,
      parameter="source_lag",filters=list(target_history=9L)),
      "leave no")
    expect_error(etr_plot_transfer_entropy_sensitivity(z$spec,
      parameter="missing"),"parameter")
    expect_error(etr_plot_transfer_entropy_sensitivity(z$spec,
      parameter="source_lag",metric="p_value"),
      "metric")
  })
})

test_that("source-shift TE histograms preserve declared null samples",{
  z<-.etr_test_transfer_entropy_fixture()
  .etr_test_transfer_entropy_pdf(function(){
    a<-etr_plot_transfer_entropy_circular_shift_test(z$te,bins=4L)
    expect_equal(a$surrogate,z$te$surrogate_transfer_entropy_bits)
    expect_equal(a$observed,.42)
    expect_equal(length(a$counts),4L)
    expect_equal(sum(a$counts),6L)
    expect_equal(length(a$breaks),5L)
    expect_identical(a$binning,"explicit_equal_width")
    b<-etr_plot_conditional_transfer_entropy_circular_shift_test(
      z$cte,bins=4L)
    expect_equal(b$surrogate,
      z$cte$surrogate_conditional_transfer_entropy_bits)
    expect_equal(b$observed,.46)
    expect_equal(sum(b$counts),6L)
    expect_error(etr_plot_transfer_entropy_circular_shift_test(
      z$te,bins=0L),"bins")
    expect_error(etr_plot_conditional_transfer_entropy_circular_shift_test(
      z$cte,bins="nonsense"),"bins")
    broken<-z$te;broken$surrogate_transfer_entropy_bits[2L]<-NA_real_
    expect_error(etr_plot_transfer_entropy_circular_shift_test(
      broken,bins=4L),"finite")
  })
})

test_that("null results never claim causal identification",{
  z<-.etr_test_transfer_entropy_fixture()
  .etr_test_transfer_entropy_pdf(function(){
    a<-etr_plot_transfer_entropy_circular_shift_test(z$te)
    expect_identical(a$binning,"R_Sturges_not_numpy_auto")
    expect_equal(a$surrogate,z$te$surrogate_transfer_entropy_bits)
  })
})

test_that("three actual Python source names are mapped and unsigned",{
  z<-etr_native_parity_catalog()
  for(name in c("plot_transfer_entropy_sensitivity",
    "plot_transfer_entropy_circular_shift_test",
    "plot_conditional_transfer_entropy_circular_shift_test")){
    x<-z[z$python_name==name&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(x),1L)
    expect_identical(x$native_r_candidate,paste0("etr_",name))
    expect_identical(x$native_implementation_stage,29L)
    expect_true(x$native_implementation_started)
    expect_false(x$source_contract_gap_unresolved)
    expect_false(x$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_gte(sum(z$named_native_candidate&z$is_python_function),236L)
  expect_gte(sum(z$native_implementation_started),211L)
  expect_lte(sum(z$is_python_function&!z$named_native_candidate),144L)
  expect_lte(sum(z$source_contract_gap_unresolved),28L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})

test_that("published Python 1.2 source Axes geometry is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Real published Python 1.2 TE plots oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  plt<-reticulate::import("matplotlib.pyplot")
  on.exit(plt$close("all"),add=TRUE)
  source<-as.integer((seq_len(60L)*7L)%%3L)
  target<-as.integer((seq_len(60L)+floor(seq_len(60L)/3L))%%2L)
  condition<-as.integer(seq_len(60L)%%2L)
  shifts<-as.integer(c(3L,5L,11L,17L,23L,29L))
  py_source<-reticulate::r_to_py(source)
  py_target<-reticulate::r_to_py(target)
  py_cond<-reticulate::r_to_py(condition)
  py_shifts<-reticulate::r_to_py(shifts)

  py_te<-reticulate::py_call(
    etpy_get_export("transfer_entropy_circular_shift_test"),
    source=py_source,target=py_target,target_history=1L,
    source_history=1L,source_lag=1L,shifts=py_shifts)
  source_null<-as.numeric(et_to_r(py_te$surrogate_transfer_entropy_bits))
  source_observed<-as.numeric(et_to_r(py_te$observed$transfer_entropy_bits))
  native_te<-structure(list(
    surrogate_transfer_entropy_bits=source_null,
    observed=list(transfer_entropy_bits=source_observed)),
    class="etr_transfer_entropy_circular_shift_test")
  ax<-reticulate::py_call(
    etpy_get_export("plot_transfer_entropy_circular_shift_test"),
    result=py_te,bins=as.integer(6L))
  expect_equal(as.integer(reticulate::py_len(ax$patches)),6L)
  expect_equal(as.integer(reticulate::py_len(ax$lines)),1L)
  expect_equal(as.numeric(et_to_r(ax$lines[[0L]]$get_xdata())),
    rep(source_observed,2L),tolerance=1e-12)
  py_counts<-vapply(0:5,function(i)
    as.numeric(et_to_r(ax$patches[[as.integer(i)]]$get_height())),
    numeric(1L))
  .etr_test_transfer_entropy_pdf(function(){
    r<-etr_plot_transfer_entropy_circular_shift_test(
      native_te,bins=6L)
    expect_equal(r$surrogate,source_null,tolerance=0)
    expect_equal(r$observed,source_observed,tolerance=0)
    expect_equal(as.numeric(r$counts),py_counts,tolerance=0)
  })

  py_cte<-reticulate::py_call(
    etpy_get_export("conditional_transfer_entropy_circular_shift_test"),
    source=py_source,target=py_target,condition=py_cond,
    target_history=1L,source_history=1L,condition_history=1L,
    source_lag=1L,condition_lag=1L,shifts=py_shifts)
  source_cnull<-as.numeric(et_to_r(
    py_cte$surrogate_conditional_transfer_entropy_bits))
  source_cobs<-as.numeric(et_to_r(
    py_cte$observed$conditional_transfer_entropy_bits))
  native_cte<-structure(list(
    surrogate_conditional_transfer_entropy_bits=source_cnull,
    observed=list(conditional_transfer_entropy_bits=source_cobs)),
    class="etr_conditional_transfer_entropy_circular_shift_test")
  ax_cte<-reticulate::py_call(
    etpy_get_export("plot_conditional_transfer_entropy_circular_shift_test"),
    result=py_cte,bins=as.integer(6L))
  expect_equal(as.integer(reticulate::py_len(ax_cte$patches)),6L)
  expect_equal(as.numeric(et_to_r(ax_cte$lines[[0L]]$get_xdata())),
    rep(source_cobs,2L),tolerance=1e-12)
  py_ccounts<-vapply(0:5,function(i)
    as.numeric(et_to_r(ax_cte$patches[[as.integer(i)]]$get_height())),
    numeric(1L))
  .etr_test_transfer_entropy_pdf(function(){
    r<-etr_plot_conditional_transfer_entropy_circular_shift_test(
      native_cte,bins=6L)
    expect_equal(r$surrogate,source_cnull,tolerance=0)
    expect_equal(r$observed,source_cobs,tolerance=0)
    expect_equal(as.numeric(r$counts),py_ccounts,tolerance=0)
  })

  py_spec<-reticulate::py_call(
    etpy_get_export("transfer_entropy_parameter_sensitivity"),
    source=py_source,target=py_target,
    target_histories=reticulate::r_to_py(list(1L)),
    source_histories=reticulate::r_to_py(list(1L)),
    source_lags=reticulate::r_to_py(list(1L,2L,3L)))
  py_ax<-reticulate::py_call(
    etpy_get_export("plot_transfer_entropy_sensitivity"),
    result=py_spec,parameter="source_lag")
  xy<-as.matrix(et_to_r(py_ax$lines[[0L]]$get_xydata()))
  native_spec<-structure(list(
    table=as.data.frame(et_to_r(py_spec$table)),
    parameter_columns=as.character(et_to_r(py_spec$parameter_columns)),
    metric_columns=as.character(et_to_r(py_spec$metric_columns))),
    class="etr_transfer_entropy_sensitivity")
  .etr_test_transfer_entropy_pdf(function(){
    tab<-etr_plot_transfer_entropy_sensitivity(native_spec,
      parameter="source_lag")
    expect_equal(as.numeric(tab$source_lag),xy[,1L],tolerance=0)
    expect_equal(as.numeric(tab$transfer_entropy_bits),
      xy[,2L],tolerance=1e-12)
  })
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})
