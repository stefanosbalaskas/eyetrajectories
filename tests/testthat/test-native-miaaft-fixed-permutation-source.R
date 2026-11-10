# Frozen eyetrajectoriespy==1.2.0, multivariate_surrogates.py
# Exact PCG64 initial-permutation replay: no Python runtime inside native R.
.etr_miaaft_fixed_fixture <- function(n=32L) {
  tt<-seq(0,1,length.out=n)
  j<-seq_len(n)-1L
  vals<-array(0,c(2L,n,3L))
  for(k in 1:2) {
    vals[k,,1L]<-sin(.47*j+.21*k)+.11*cos(.83*j)+.013*j
    vals[k,,2L]<-cos(.37*j+.16*k)+.14*sin(.71*j)+.008*j
    vals[k,,3L]<-sin(.27*j+.11*k)+.07*cos(.51*j)+.019*j
  }
  etr_trajectory_set(tt,vals,c("a","b"),c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}
.etr_miaaft_fixed_orders <- function(b,n,d) {
  out<-array(0L,c(b,n,d))
  for(k in seq_len(b)) for(j in seq_len(d))
    out[k,,j]<-as.integer((seq_len(n)-1L + 3L*(j-1L) + k-1L)%%n)
  out
}
test_that("native fixed IAAFT initialization preserves ranks, spectral diagnostics and RNG", {
  for(n in c(23L,32L)) {
    x<-.etr_miaaft_fixed_fixture(n)
    orders<-.etr_miaaft_fixed_orders(2L,n,3L)
    set.seed(271L); old<-.Random.seed
    a<-etr_generate_multivariate_iaaft_surrogates(
      x,"a",c("z","x","y"),"x",n_surrogates=2L,
      max_iterations=100L,tolerance=.5,random_state=999L,
      initial_permutations=orders)
    expect_identical(old,.Random.seed)
    expect_identical(a$provenance$fixed_initialization_replay,TRUE)
    expect_identical(a$provenance$initialization_source,
      "fixed_numpy_compatible_permutation_replay")
    expect_false(a$provenance$source_python_equivalent_stochastic_draws)
    expect_identical(dim(a$surrogates),c(2L,n,3L))
    expect_identical(dim(a$spectral_errors),c(2L,3L))
    expect_identical(dim(a$cross_spectral_errors),c(2L,3L))
    expect_true(all(a$convergence_iterations>=1L))
    for(b in 1:2)for(d in 1:3)
      expect_equal(sort(a$surrogates[b,,d]),sort(a$source_values[,d]),tolerance=0)
    expect_true(all(is.finite(c(a$spectral_errors,a$cross_spectral_errors))))
    again<-etr_generate_multivariate_iaaft_surrogates(
      x,"a",c("z","x","y"),"x",n_surrogates=2L,
      max_iterations=100L,tolerance=.5,
      initial_permutations=orders)
    expect_identical(a$surrogates,again$surrogates)
    expect_identical(a$convergence_iterations,again$convergence_iterations)
  }
})
test_that("initial permutation replay rejects malformed, missing, duplicate, fractional and out-of-range orders", {
  x<-.etr_miaaft_fixed_fixture(23L)
  f<-function(z)etr_generate_multivariate_iaaft_surrogates(
    x,"a",c("z","x","y"),"x",n_surrogates=2L,
    max_iterations=100L,tolerance=.5,initial_permutations=z)
  good<-.etr_miaaft_fixed_orders(2L,23L,3L)
  expect_error(f(good[1L,,,drop=FALSE]),"initial_permutations")
  wrong<-good;wrong[1L,1L,1L]<-NA_integer_
  expect_error(f(wrong),"initial_permutations")
  wrong<-good;wrong[1L,1L,1L]<-wrong[1L,2L,1L]
  expect_error(f(wrong),"complete permutations")
  wrong<-good;wrong[1L,1L,1L]<-23L
  expect_error(f(wrong),"initial_permutations")
  wrong<-as.numeric(good);dim(wrong)<-dim(good)
  wrong[1L,1L,1L]<-0.5
  expect_error(f(wrong),"initial_permutations")
  wrong<-array("0",dim(good))
  expect_error(f(wrong),"initial_permutations")
})
test_that("public frozen Python 1.2 MIAAFT matches fixed initial permutations on even and odd grids", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python public multivariate IAAFT oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _et_public_miaaft_pair(values, times, n_surrogates, seed):
    vals = np.asarray(values, dtype=float)
    times = np.asarray(times, dtype=float)
    n, d = vals.shape[1], vals.shape[2]
    rng = np.random.default_rng(int(seed))
    orders = np.empty((n_surrogates, n, d), dtype=np.int64)
    for k in range(n_surrogates):
        for j in range(d):
            orders[k, :, j] = rng.permutation(n)
    sample = et.TrajectorySet(time=times, values=vals,
        curve_ids=('a','b'), dimension_names=('x','y','z'),
        coordinate_system='pixels', time_unit='s')
    source = et.generate_multivariate_iaaft_surrogates(
        sample, curve='a', dimensions=('z','x','y'),
        reference_dimension='x', n_surrogates=n_surrogates,
        max_iterations=100, tolerance=0.5, random_state=int(seed))
    return {'initial_permutations': orders,
        'surrogates':source.surrogates,
        'convergence_iterations':source.convergence_iterations,
        'spectral_errors':source.spectral_errors,
        'cross_spectral_errors':source.cross_spectral_errors,
        'source_values':source.source_values}
")
  oracle<-reticulate::py_eval("_et_public_miaaft_pair",convert=FALSE)
  for(n in c(23L,32L)) {
    x<-.etr_miaaft_fixed_fixture(n)
    py<-reticulate::py_to_r(reticulate::py_call(
      oracle,values=reticulate::r_to_py(x$values),
      times=reticulate::r_to_py(x$time),
      n_surrogates=as.integer(2L),seed=as.integer(89L)))
    orders<-array(as.integer(py$initial_permutations),
      dim=dim(py$initial_permutations))
    native<-etr_generate_multivariate_iaaft_surrogates(
      x,"a",c("z","x","y"),"x",n_surrogates=2L,
      max_iterations=100L,tolerance=.5,
      initial_permutations=orders)
    expect_equal(unname(native$source_values),unname(py$source_values),
      tolerance=0)
    expect_equal(unname(native$surrogates),unname(py$surrogates),
      tolerance=1e-12,ignore_attr=TRUE,
      info=paste("full public MIAAFT",n))
    expect_equal(as.integer(native$convergence_iterations),
      as.integer(py$convergence_iterations),tolerance=0)
    expect_equal(unname(native$spectral_errors),unname(py$spectral_errors),
      tolerance=1e-10,ignore_attr=TRUE)
    expect_equal(unname(native$cross_spectral_errors),
      unname(py$cross_spectral_errors),tolerance=1e-10,
      ignore_attr=TRUE)
    seeded<-etr_generate_multivariate_iaaft_surrogates(
      x,"a",c("z","x","y"),"x",n_surrogates=2L,
      max_iterations=100L,tolerance=.5,random_state=89L)
    expect_true(seeded$provenance$seeded_initialization_matches_numpy)
    expect_equal(seeded$surrogates,native$surrogates,tolerance=0)
    expect_identical(seeded$convergence_iterations,native$convergence_iterations)
  }
})

test_that("multivariate source fixed initialization replays the complete LLE surrogate test", {
  # Known-valid 96-sample Lyapunov fixture, built locally for targeted filters.
  tt<-seq(0,1,length.out=96L);j<-seq_len(96L)-1L
  vals<-array(0,c(1L,96L,3L))
  vals[1L,,1L]<-sin(2*pi*5*j/96)+.19*cos(2*pi*13*j/96)
  vals[1L,,2L]<-cos(2*pi*5*j/96+.3)+.13*sin(2*pi*11*j/96)
  vals[1L,,3L]<-.5*sin(2*pi*4*j/96+.4)+.28*cos(2*pi*9*j/96)
  x<-etr_trajectory_set(tt,vals,"example",c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
  orders<-.etr_miaaft_fixed_orders(2L,96L,3L)
  call<-function(seed)etr_multivariate_surrogate_nonlinearity_test(
    x,curve="example",dimensions=c("x","y","z"),reference_dimension="y",
    statistic="largest_lyapunov",embedding_dimension=2L,delay=2L,
    theiler_window=3L,max_horizon=7L,fit_start=1L,fit_end=4L,
    n_surrogates=2L,max_iterations=100L,tolerance=.7,
    alternative="two-sided",random_state=seed,
    initial_permutations=orders)
  set.seed(871L);before<-.Random.seed
  a<-call(100L);b<-call(999L)
  expect_identical(before,.Random.seed)
  expect_equal(a$surrogate_result$surrogates,
    b$surrogate_result$surrogates,tolerance=0)
  expect_equal(a$surrogate_statistics,b$surrogate_statistics,tolerance=0)
  expect_equal(a$p_value,b$p_value,tolerance=0)
  expect_true(a$provenance$fixed_initialization_replay)
  up<-(sum(a$surrogate_statistics>=a$observed_statistic)+1)/3
  low<-(sum(a$surrogate_statistics<=a$observed_statistic)+1)/3
  expect_equal(a$p_value,min(1,2*min(up,low)),tolerance=0)
})
