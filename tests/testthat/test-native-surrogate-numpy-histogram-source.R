# Frozen eyetrajectoriespy==1.2.0 nonlinear_plotting.py
# plot_surrogate_nonlinearity: Matplotlib hist(bins=int) -> NumPy edges.
# Bounded histogram geometry only, not backend/typed return equivalence.

.etr_surrogate_hist_source_result<-function(values){
  structure(list(surrogate_statistics=as.numeric(values),
    observed_statistic=.4,p_value=.3,statistic="largest_lyapunov",
    method="iaaft"),class="etr_surrogate_nonlinearity")
}
.etr_surrogate_hist_pdf<-function(fun){
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  fun()
}

test_that("NumPy histogram source mode preserves exact finite integer bins",{
  z<-.etr_surrogate_hist_source_result(c(0,1,2,3,4))
  .etr_surrogate_hist_pdf(function(){
    got<-etr_plot_surrogate_nonlinearity(z,bins=4L,
      python_boundary_mode=TRUE)
    expect_identical(got$python_matplotlib_histogram_binning_equivalent,TRUE)
    expect_equal(got$breaks,0:4,tolerance=0)
    expect_equal(got$counts,as.integer(c(1,1,1,2)),tolerance=0)
    expect_equal(sum(got$counts),5)
    expect_identical(got$observed,.4)
    expect_true(all(got$counts>=0L))
    old<-etr_plot_surrogate_nonlinearity(z,bins=4L)
    expect_false(old$python_matplotlib_histogram_binning_equivalent)
    expect_equal(sum(old$counts),5L)
  })
})

test_that("NumPy surrogate plot source mode distinguishes constant and skewed data",{
  for(z in list(.etr_surrogate_hist_source_result(rep(.6,11)),
    .etr_surrogate_hist_source_result(
      c(rep(.1,12),seq(.5,8,length.out=8L))))) {
    .etr_surrogate_hist_pdf(function(){
      h<-etr_plot_surrogate_nonlinearity(z,bins=20L,
        python_boundary_mode=TRUE)
      range<-range(z$surrogate_statistics)
      if(range[1]==range[2])range<-range+c(-.5,.5)
      expect_equal(h$breaks,
        seq(range[1],range[2],length.out=21L),tolerance=1e-12)
      expect_identical(length(h$counts),20L)
      expect_equal(sum(h$counts),length(z$surrogate_statistics))
    })
  }
})

test_that("Python integer-domain checks fail without relaxing ordinary R defaults",{
  z<-.etr_surrogate_hist_source_result(c(1,2,3,4))
  .etr_surrogate_hist_pdf(function(){
    expect_error(etr_plot_surrogate_nonlinearity(z,
      bins=2,python_boundary_mode=TRUE),
      "Python integer")
    expect_error(etr_plot_surrogate_nonlinearity(z,
      bins=TRUE,python_boundary_mode=TRUE),
      "Python integer")
    expect_error(etr_plot_surrogate_nonlinearity(z,
      bins=1L,python_boundary_mode=TRUE),
      "Python integer")
    expect_error(etr_plot_surrogate_nonlinearity(z,
      bins=10001L,python_boundary_mode=TRUE),
      "10000-bin")
    expect_error(etr_plot_surrogate_nonlinearity(z,
      python_boundary_mode=NA),"python_boundary_mode")
    expect_false(etr_plot_surrogate_nonlinearity(z,
      bins=2)$python_matplotlib_histogram_binning_equivalent)
    zbad<-z;zbad$surrogate_statistics[1L]<-Inf
    expect_error(etr_plot_surrogate_nonlinearity(zbad,bins=2L,
      python_boundary_mode=TRUE),"finite native")
  })
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("actual frozen Python 1.2 Matplotlib bars and NumPy breaks match native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 source NumPy/Matplotlib histogram oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_ET_NL_VALUES=np.array([0.,1.,2.,3.,4.],dtype=float)
_ET_NL_RESULT=et.SurrogateNonlinearityResult(
  observed_statistic=.4, surrogate_statistics=_ET_NL_VALUES,
  p_value=.3, alternative='greater',statistic='largest_lyapunov',
  method='iaaft',n_surrogates=5,random_state=0,
  convergence_iterations=np.zeros(5,dtype=int),
  spectral_errors=np.zeros(5,dtype=float),provenance={})
")
  plt<-reticulate::import("matplotlib.pyplot",convert=FALSE)
  on.exit(plt$close("all"),add=TRUE)
  for(bins in c(2L,4L,7L,20L)){
    obj<-reticulate::py_eval("_ET_NL_RESULT",convert=FALSE)
    ax<-reticulate::py_call(
      etpy_get_export("plot_surrogate_nonlinearity"),
      result=obj,bins=as.integer(bins))
    patch_n<-as.integer(reticulate::py_len(ax$patches))
    expect_identical(patch_n,bins)
    heights<-vapply(seq_len(patch_n)-1L,function(i)
      as.numeric(et_to_r(ax$patches[[as.integer(i)]]$get_height())),
      numeric(1L))
    np<-reticulate::import("numpy",convert=FALSE)
    edges<-as.numeric(et_to_r(np$histogram_bin_edges(
      reticulate::py_eval("_ET_NL_VALUES",convert=FALSE),
      bins=as.integer(bins))))
    .etr_surrogate_hist_pdf(function(){
      native<-etr_plot_surrogate_nonlinearity(
        .etr_surrogate_hist_source_result(0:4),bins=bins,
        python_boundary_mode=TRUE)
      expect_equal(native$breaks,edges,tolerance=1e-13)
      expect_equal(as.numeric(native$counts),heights,tolerance=0)
      expect_equal(sum(native$counts),5L)
    })
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
