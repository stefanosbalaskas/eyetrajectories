# Frozen eyetrajectoriespy 1.2.0 nonlinear_plotting.py:
# plot_multivariate_surrogate_nonlinearity delegates integer-bin
# histograms to Matplotlib/NumPy. This is first-party numerical evidence,
# not independent full-domain source certification.

.etr_multiv_numpy_hist_result<-function(values){
  list(surrogate_statistics=as.numeric(values),
       observed_statistic=.36,statistic="joint_recurrence",p_value=.2)
}
.etr_multiv_numpy_hist_device<-function(f) {
  out<-tempfile(fileext=".pdf")
  grDevices::pdf(out)
  on.exit({grDevices::dev.off();unlink(out)},add=TRUE)
  f()
}

test_that("multivariate opt-in NumPy integer histogram preserves exact bins",{
  result<-.etr_multiv_numpy_hist_result(0:4)
  .etr_multiv_numpy_hist_device(function(){
    h<-etr_plot_multivariate_surrogate_nonlinearity(result,
      bins=4L,python_boundary_mode=TRUE)
    expect_equal(h$histogram$breaks,0:4,tolerance=0)
    expect_equal(as.numeric(h$histogram$counts),c(1,1,1,2),
      tolerance=0)
    expect_equal(sum(h$histogram$counts),5)
    expect_equal(h$histogram$density,
      h$histogram$counts/(5*diff(h$histogram$breaks)),
      tolerance=0)
    expect_equal(h$observed_statistic,.36)
    expect_equal(h$p_value,.2)
  })
})

test_that("NumPy constant histogram expands by fixed one-half on either side",{
  for(value in c(0,.1,2,100,-50)){
    result<-.etr_multiv_numpy_hist_result(rep(value,9L))
    .etr_multiv_numpy_hist_device(function(){
      np<-etr_plot_multivariate_surrogate_nonlinearity(result,bins=8L,
        python_boundary_mode=TRUE)$histogram
      expect_equal(np$breaks,seq(value-.5,value+.5,length.out=9L),
        tolerance=1e-13)
      expect_identical(length(np$counts),8L)
      expect_equal(sum(np$counts),9)
      expect_equal(np$counts[5L],9L)
      if(value!=0){
        native<-etr_plot_multivariate_surrogate_nonlinearity(result,
          bins=8L)
        if(abs(value)!=1)
          expect_false(isTRUE(all.equal(native$histogram$breaks,np$breaks)))
      }
    })
  }
})

test_that("NumPy multivariate source mode retains strict bin argument domain",{
  result<-.etr_multiv_numpy_hist_result(c(.1,.4,1,2,5))
  .etr_multiv_numpy_hist_device(function(){
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      result,bins=4,python_boundary_mode=TRUE),"Python integer")
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      result,bins=TRUE,python_boundary_mode=TRUE),"Python integer")
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      result,bins=1L,python_boundary_mode=TRUE),"Python integer")
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      result,bins=10001L,python_boundary_mode=TRUE),"10000-bin")
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      result,bins=4L,python_boundary_mode=NA),
      "python_boundary_mode")
    # Historical R mode still permits an integer-valued double.
    expect_length(etr_plot_multivariate_surrogate_nonlinearity(
      result,bins=4)$histogram$counts,4L)
  })
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("frozen Python 1.2 Matplotlib multivariate bars equal opt-in R bins",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 multivariate histogram oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _ET_MULTIV_PLOT_OBJ(values):
    cls=et.MultivariateSurrogateNonlinearityResult
    z=object.__new__(cls)
    object.__setattr__(z,'surrogate_statistics',np.asarray(values,dtype=float))
    object.__setattr__(z,'observed_statistic',.36)
    object.__setattr__(z,'statistic','joint_recurrence')
    object.__setattr__(z,'p_value',.2)
    return z
")
  plt<-reticulate::import("matplotlib.pyplot",convert=FALSE)
  on.exit(plt$close("all"),add=TRUE)
  np<-reticulate::import("numpy",convert=FALSE)
  source_fun<-etpy_get_export("plot_multivariate_surrogate_nonlinearity")
  py_make<-reticulate::py_eval("_ET_MULTIV_PLOT_OBJ",convert=FALSE)
  for(values in list(c(0,1,2,3,4),rep(2,9),
                     c(.1,.1,.1,.1,.5,1.8,9))){
    for(bins in c(2L,4L,8L)){
      py_values<-reticulate::r_to_py(as.numeric(values))
      py_obj<-reticulate::py_call(py_make,values=py_values)
      ax<-reticulate::py_call(source_fun,result=py_obj,
        bins=as.integer(bins))
      n<-as.integer(reticulate::py_len(ax$patches))
      expect_identical(n,bins)
      heights<-vapply(seq_len(n)-1L,function(i)
        as.numeric(et_to_r(ax$patches[[as.integer(i)]]$get_height())),
        numeric(1L))
      edges<-as.numeric(et_to_r(np$histogram_bin_edges(py_values,
        bins=as.integer(bins))))
      .etr_multiv_numpy_hist_device(function(){
        local<-etr_plot_multivariate_surrogate_nonlinearity(
          .etr_multiv_numpy_hist_result(values),
          bins=bins,python_boundary_mode=TRUE)$histogram
        expect_equal(local$breaks,edges,tolerance=1e-13)
        expect_equal(as.numeric(local$counts),heights,tolerance=0)
      })
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
