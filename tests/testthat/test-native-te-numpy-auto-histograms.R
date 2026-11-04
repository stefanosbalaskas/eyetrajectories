# Frozen eyetrajectoriespy 1.2.0 uses Matplotlib ax.hist(..., bins="auto").
# NumPy >=1.26 is not pinned by the published source; auto rules differ
# between supported versions. These are bounded numerical witnesses only.

.etr_test_numpy_auto_te_fixture <- function(values,conditional=FALSE) {
  if(conditional)
    return(structure(list(
      surrogate_conditional_transfer_entropy_bits=as.numeric(values),
      observed=list(conditional_transfer_entropy_bits=.4)),
      class="etr_conditional_transfer_entropy_circular_shift_test"))
  structure(list(surrogate_transfer_entropy_bits=as.numeric(values),
    observed=list(transfer_entropy_bits=.4)),
    class="etr_transfer_entropy_circular_shift_test")
}

.etr_test_numpy_auto_te_device <- function(fn) {
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  fn()
}

test_that("modern and classic NumPy auto policies are explicitly distinct",{
  null<-c(rep(.02,50L),seq(.3,8,length.out=10L))
  modern<-.etr_numpy_histogram_auto_breaks(null,"relaxed")
  classic<-.etr_numpy_histogram_auto_breaks(null,"classic")
  expect_equal(length(modern)-1L,16L)
  expect_equal(length(classic)-1L,7L)
  expect_equal(modern,seq(.02,8,length.out=17L),tolerance=1e-14)
  expect_equal(classic,seq(.02,8,length.out=8L),tolerance=1e-14)
  expect_equal(.etr_numpy_histogram_auto_breaks(rep(.5,18L),"relaxed"),
    c(0,1),tolerance=0)
  expect_equal(.etr_numpy_histogram_auto_breaks(rep(.5,18L),"classic"),
    c(0,1),tolerance=0)
  expect_error(.etr_numpy_histogram_auto_breaks(c(1,NaN)),
    "finite")
  expect_error(.etr_numpy_histogram_auto_breaks(c(1,2),"other"),
    "arg")
})

test_that("source-mode NumPy bins preserve native nulls and exact edge counts",{
  null<-c(rep(.02,50L),seq(.3,8,length.out=10L))
  z<-.etr_test_numpy_auto_te_fixture(null)
  zc<-.etr_test_numpy_auto_te_fixture(null+.02,conditional=TRUE)
  .etr_test_numpy_auto_te_device(function(){
    modern<-etr_plot_transfer_entropy_circular_shift_test(z,
      bins="auto",python_boundary_mode=TRUE,
      numpy_auto_policy="relaxed")
    classic<-etr_plot_transfer_entropy_circular_shift_test(z,
      bins="auto",python_boundary_mode=TRUE,
      numpy_auto_policy="classic")
    expect_identical(modern$binning,"numpy_auto_relaxed")
    expect_identical(classic$binning,"numpy_auto_classic")
    expect_equal(length(modern$counts),16L)
    expect_equal(length(classic$counts),7L)
    expect_equal(sum(modern$counts),length(null))
    expect_equal(sum(classic$counts),length(null))
    expect_equal(modern$breaks,seq(.02,8,length.out=17L),
      tolerance=1e-12)
    expect_equal(modern$surrogate,null,tolerance=0)
    expect_equal(modern$observed,.4,tolerance=0)
    expect_true(all(modern$counts>=0))
    # A point at the last right edge is included exactly once.
    expect_equal(tail(modern$counts,1L),1L)
    condition<-etr_plot_conditional_transfer_entropy_circular_shift_test(
      zc,bins="auto",python_boundary_mode=TRUE,
      numpy_auto_policy="relaxed")
    expect_identical(condition$binning,"numpy_auto_relaxed")
    expect_equal(sum(condition$counts),length(null))
    expect_equal(condition$breaks,modern$breaks+.02,tolerance=1e-12)
    baseline<-etr_plot_transfer_entropy_circular_shift_test(z)
    expect_identical(baseline$binning,"R_Sturges_not_numpy_auto")
    fixed<-etr_plot_transfer_entropy_circular_shift_test(z,bins=6L)
    expect_identical(fixed$binning,"explicit_equal_width")
    expect_equal(length(fixed$counts),6L)
    expect_error(etr_plot_transfer_entropy_circular_shift_test(z,
      python_boundary_mode=NA),"python_boundary_mode")
    expect_error(etr_plot_transfer_entropy_circular_shift_test(z,
      python_boundary_mode=TRUE,numpy_auto_policy="unknown"),
      "numpy_auto_policy")
  })
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("pinned Python 1.2 Matplotlib auto histogram counts match selected NumPy policy",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 real transfer-entropy plots oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  mpl<-reticulate::import("matplotlib")
  mpl$use("Agg")
  plt<-reticulate::import("matplotlib.pyplot")
  on.exit(plt$close("all"),add=TRUE)
  np<-reticulate::import("numpy")
  # Determine which of the TWO supported NumPy width formulas the
  # installed source environment actually uses. Neither is silently
  # assumed for all versions of numpy>=1.26.
  diagnostic<-c(rep(.02,50L),seq(.3,8,length.out=10L))
  py_diag<-as.numeric(et_to_r(np$histogram_bin_edges(
    reticulate::r_to_py(diagnostic),bins="auto")))
  policy<-if(isTRUE(all.equal(py_diag,
      .etr_numpy_histogram_auto_breaks(diagnostic,"relaxed"),
      tolerance=1e-12)))"relaxed" else
    if(isTRUE(all.equal(py_diag,
      .etr_numpy_histogram_auto_breaks(diagnostic,"classic"),
      tolerance=1e-12)))"classic" else
    stop("Installed NumPy auto policy requires a new source-domain implementation")
  source<-as.integer((seq_len(90L)*7L)%%3L)
  target<-as.integer((seq_len(90L)+floor(seq_len(90L)/3L))%%2L)
  condition<-as.integer(seq_len(90L)%%2L)
  shifts<-as.integer(c(3L,5L,11L,17L,23L,29L,31L,37L,41L,
    43L,47L,53L,59L,61L,67L,71L,73L,79L))
  py_source<-reticulate::r_to_py(source)
  py_target<-reticulate::r_to_py(target)
  py_cond<-reticulate::r_to_py(condition)
  py_shifts<-reticulate::r_to_py(shifts)
  for(conditional in c(FALSE,TRUE)){
    py_result<-if(conditional)
      reticulate::py_call(
        etpy_get_export("conditional_transfer_entropy_circular_shift_test"),
        source=py_source,target=py_target,condition=py_cond,
        target_history=1L,source_history=1L,
        condition_history=1L,source_lag=1L,
        condition_lag=1L,shifts=py_shifts) else
      reticulate::py_call(
        etpy_get_export("transfer_entropy_circular_shift_test"),
        source=py_source,target=py_target,target_history=1L,
        source_history=1L,source_lag=1L,shifts=py_shifts)
    py_ax<-reticulate::py_call(etpy_get_export(
      if(conditional)
        "plot_conditional_transfer_entropy_circular_shift_test"
      else "plot_transfer_entropy_circular_shift_test"),
      result=py_result,bins="auto")
    null<-as.numeric(et_to_r(if(conditional)
      py_result$surrogate_conditional_transfer_entropy_bits else
      py_result$surrogate_transfer_entropy_bits))
    observed<-as.numeric(et_to_r(if(conditional)
      py_result$observed$conditional_transfer_entropy_bits else
      py_result$observed$transfer_entropy_bits))
    edges<-as.numeric(et_to_r(np$histogram_bin_edges(
      reticulate::r_to_py(null),bins="auto")))
    patch_count<-as.integer(reticulate::py_len(py_ax$patches))
    py_counts<-vapply(seq_len(patch_count)-1L,function(i)
      as.numeric(et_to_r(py_ax$patches[[as.integer(i)]]$get_height())),
      numeric(1L))
    native<-if(conditional)
      structure(list(
        surrogate_conditional_transfer_entropy_bits=null,
        observed=list(conditional_transfer_entropy_bits=observed)),
        class="etr_conditional_transfer_entropy_circular_shift_test") else
      structure(list(surrogate_transfer_entropy_bits=null,
        observed=list(transfer_entropy_bits=observed)),
        class="etr_transfer_entropy_circular_shift_test")
    .etr_test_numpy_auto_te_device(function(){
      actual<-if(conditional)
        etr_plot_conditional_transfer_entropy_circular_shift_test(
          native,python_boundary_mode=TRUE,numpy_auto_policy=policy) else
        etr_plot_transfer_entropy_circular_shift_test(
          native,python_boundary_mode=TRUE,numpy_auto_policy=policy)
      expect_equal(actual$breaks,edges,tolerance=1e-11)
      expect_equal(as.numeric(actual$counts),py_counts,tolerance=0)
      expect_equal(sum(actual$counts),length(null))
      expect_equal(actual$observed,observed,tolerance=0)
      expect_identical(actual$binning,paste0("numpy_auto_",policy))
    })
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
