# Frozen published Python 1.2 multivariate surrogate hypothesis test.
.etr_multivariate_lle_fixture<-function(){
  t<-seq(0,1,length.out=96L);j<-seq_len(96L)-1L
  a<-array(0,c(1L,96L,3L))
  a[1L,,1L]<-sin(2*pi*5*j/96)+.19*cos(2*pi*13*j/96)
  a[1L,,2L]<-cos(2*pi*5*j/96+.3)+.13*sin(2*pi*11*j/96)
  a[1L,,3L]<-.5*sin(2*pi*4*j/96+.4)+.28*cos(2*pi*9*j/96)
  etr_trajectory_set(t,a,"example",c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}
.etr_multivariate_lle_call<-function(x,alternative){
  etr_multivariate_surrogate_nonlinearity_test(x,curve="example",
    dimensions=c("x","y","z"),reference_dimension="y",
    statistic="largest_lyapunov",embedding_dimension=2L,delay=2L,
    theiler_window=3L,max_horizon=7L,fit_start=1L,fit_end=4L,
    n_surrogates=3L,max_iterations=100L,tolerance=.7,
    alternative=alternative,random_state=17L)
}
test_that("multivariate LLE surrogate test uses exact plus-one tails",{
  x<-.etr_multivariate_lle_fixture()
  set.seed(83);prior<-.Random.seed
  for(alt in c("greater","less","two-sided")){
    z<-.etr_multivariate_lle_call(x,alt)
    expect_identical(prior,.Random.seed)
    expect_s3_class(z,"etr_multivariate_surrogate_nonlinearity")
    expect_identical(length(z$surrogate_statistics),3L)
    expect_true(all(is.finite(z$surrogate_statistics)))
    expect_true(is.finite(z$observed_statistic))
    up<-(sum(z$surrogate_statistics>=z$observed_statistic)+1)/4
    low<-(sum(z$surrogate_statistics<=z$observed_statistic)+1)/4
    expected<-switch(alt,greater=up,less=low,
      "two-sided"=min(1,2*min(up,low)))
    expect_equal(z$p_value,expected,tolerance=0)
    expect_identical(z$surrogate_result$reference_dimension,"y")
    expect_false(z$provenance$source_python_equivalent_stochastic_draws)
  }
})
test_that("multivariate LLE refuses unsupported source domains",{
  x<-.etr_multivariate_lle_fixture()
  base<-function(...)etr_multivariate_surrogate_nonlinearity_test(
    x,"example",c("x","y"),"y","largest_lyapunov",2L,
    2L,3L,7L,1L,4L,...)
  expect_error(base(statistic="bad"),"matched by multiple")
  expect_error(base(alternative="bad"),"alternative")
  expect_error(base(delay_units="ms"),"sample units")
  expect_error(base(fit_end=1L),"matched by multiple")
})
test_that("pinned Python 1.2 independently verifies multivariate p-value rule",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 multivariate LLE and surrogate p-value oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  native<-.etr_multivariate_lle_call(.etr_multivariate_lle_fixture(),"two-sided")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
j=np.arange(96);t=np.linspace(0,1,96)
v=np.stack([np.sin(2*np.pi*5*j/96)+.19*np.cos(2*np.pi*13*j/96),
np.cos(2*np.pi*5*j/96+.3)+.13*np.sin(2*np.pi*11*j/96),
-.5*np.sin(2*np.pi*4*j/96+.4)+.28*np.cos(2*np.pi*9*j/96)],axis=-1)
x=et.TrajectorySet(time=t,values=v[None,:,:],curve_ids=('example',),
dimension_names=('x','y','z'),coordinate_system='pixels',time_unit='s')
res=et.multivariate_surrogate_nonlinearity_test(
 x,curve='example',dimensions=('x','y','z'),reference_dimension='y',
 statistic='largest_lyapunov',embedding_dimension=2,delay=2,
 theiler_window=3,max_horizon=7,fit_start=1,fit_end=4,
 n_surrogates=3,max_iterations=100,tolerance=.7,
 alternative='two-sided',random_state=17)
ref_p=min(1.,2*min((np.sum(res.surrogate_statistics>=res.observed_statistic)+1)/4,
                      (np.sum(res.surrogate_statistics<=res.observed_statistic)+1)/4))
")
  expected<-as.numeric(reticulate::py_to_r(
    reticulate::py_eval("ref_p",convert=FALSE)))
  actual<-as.numeric(reticulate::py_to_r(
    reticulate::py_eval("res.p_value",convert=FALSE)))
  expect_equal(actual,expected,tolerance=0)
  expect_equal(native$p_value,min(1,2*min(
    (sum(native$surrogate_statistics>=native$observed_statistic)+1)/4,
    (sum(native$surrogate_statistics<=native$observed_statistic)+1)/4)),
    tolerance=0)
  # Draw-level p-values can differ: R and NumPy PCG64 cannot replay seeds.
  expect_false(native$provenance$source_python_equivalent_stochastic_draws)
})
