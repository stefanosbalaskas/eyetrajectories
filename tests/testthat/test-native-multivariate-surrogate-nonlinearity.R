# Frozen published Python 1.2 multivariate surrogate hypothesis test.
test_that("multivariate LLE source fixture preserves third-channel sign",{
  x<-.etr_multivariate_lle_fixture()
  expect_equal(x$values[1L,1L,3L],
    0.28-0.5*sin(0.4),tolerance=1e-13)
})

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
  base<-function(statistic="largest_lyapunov",fit_end=4L,...)
    etr_multivariate_surrogate_nonlinearity_test(
      x,"example",c("x","y"),"y",statistic,2L,
      2L,3L,7L,1L,fit_end,...)
  expect_error(base(statistic="bad"),"statistic")
  expect_error(base(alternative="bad"),"alternative")
  expect_error(base(delay_units="ms"),"sample units")
  expect_error(base(fit_end=1L),"fit_end")
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
  source_test<-function(trajectories)reticulate::py_call(
    etpy_get_export("multivariate_surrogate_nonlinearity_test"),
    trajectories=trajectories,
    curve="example",dimensions=reticulate::py_eval(
      "('x','y','z')",convert=FALSE),reference_dimension="y",
    statistic="largest_lyapunov",embedding_dimension=2L,delay=2L,
    theiler_window=3L,max_horizon=7L,fit_start=1L,fit_end=4L,
    n_surrogates=3L,max_iterations=100L,tolerance=.7,
    alternative="two-sided",random_state=17L)
  direct<-source_test(reticulate::py_eval("x",convert=FALSE))
  for(field in c("observed_statistic","surrogate_statistics","p_value")){
    replay<-et_to_r(reticulate::py_get_attr(direct,field))
    source<-reticulate::py_eval(paste0("res.",field),convert=TRUE)
    expect_equal(replay,source,tolerance=1e-12,ignore_attr=TRUE,
      info=paste("replayed nonlinear source",field))
  }
  expected<-as.numeric(reticulate::py_to_r(
    reticulate::py_eval("ref_p",convert=FALSE)))
  actual<-as.numeric(reticulate::py_to_r(
    reticulate::py_eval("res.p_value",convert=FALSE)))
  expect_equal(actual,expected,tolerance=0)
  expect_equal(native$p_value,min(1,2*min(
    (sum(native$surrogate_statistics>=native$observed_statistic)+1)/4,
    (sum(native$surrogate_statistics<=native$observed_statistic)+1)/4)),
    tolerance=0)
  expect_true(native$surrogate_result$provenance$seeded_initialization_matches_numpy)
  expect_false(native$provenance$source_python_equivalent_stochastic_draws)

  # Broadband perturbations populate the reference Fourier harmonics.
  separated<-.etr_multivariate_lle_fixture()
  for(j in seq_len(3L))
    separated$values[1L,,j]<-separated$values[1L,,j]+
      .01*sin(seq_len(96L)*sqrt(2)*(1+j/7))
  py_input<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=separated$time,values=separated$values,
    curve_ids=reticulate::tuple("example"),dimension_names=reticulate::tuple("x","y","z"),
    coordinate_system=separated$coordinate_system,time_unit=separated$time_unit)
  native_separated<-.etr_multivariate_lle_call(separated,"two-sided")
  python_separated<-source_test(py_input)
  for(field in c("observed_statistic","surrogate_statistics","p_value"))
    expect_equal(native_separated[[field]],
      et_to_r(reticulate::py_get_attr(python_separated,field)),
      tolerance=1e-8,ignore_attr=TRUE,info=paste("seeded native nonlinear source",field))
})

test_that("replay resolves periodic source phase conditioning before rank remapping",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 periodic MIAAFT oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_multivariate_lle_fixture()
  source<-.etr_miaaft_python_trace(x)
  replay<-.etr_miaaft_phase_replay_from_trace(source)
  native<-.etr_multivariate_lle_call(x,"two-sided",phase_replay=replay)
  expect_identical(native$surrogate_result$surrogates,source$surrogates)
  expect_identical(native$surrogate_result$convergence_iterations,
    as.integer(source$iterations))
  expect_equal(native$surrogate_result$spectral_errors,source$spectral_errors,
    tolerance=1e-10)
  expect_equal(native$observed_statistic,source$observed,tolerance=1e-10)
  expect_equal(native$surrogate_statistics,as.numeric(source$stats),
    tolerance=1e-10)
  expect_identical(native$p_value,source$p)
  expect_true(native$provenance$phase_replay_applied)
  expect_identical(
    native$surrogate_result$provenance$ambiguous_target_reference_bins_zero_based,
    c(4L,9L,13L))
  expect_gt(native$surrogate_result$provenance$target_phases_replayed,0)
  expect_true(all(native$surrogate_result$provenance$reference_phases_replayed>0))

  trace<-.etr_miaaft_native_trace(x,source,replay)
  expect_true(all(trace$max_abs_previous==0))
  expect_true(all(trace$max_abs_transformed<1e-10))
  expect_true(all(trace$different_rank_positions==0L))
  expect_true(all(trace$max_abs_ranked==0))
})
