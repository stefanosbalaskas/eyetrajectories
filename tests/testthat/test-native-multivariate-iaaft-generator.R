# Frozen Python 1.2 multivariate_surrogates.py source-matched MIAAFT.
.etr_miaaft_fixture<-function(){
  time<-seq(0,1,length.out=32L)
  j<-seq_len(32L)-1
  a<-array(0,c(2L,32L,3L))
  for(i in seq_len(2L)){
    a[i,,1L]<-sin(2*pi*3*j/32+i*.16)+.19*cos(2*pi*6*j/32)
    a[i,,2L]<-cos(2*pi*3*j/32-i*.21)+.17*sin(2*pi*7*j/32)
    a[i,,3L]<-.5*sin(2*pi*3*j/32+i*.4)+.28*cos(2*pi*4*j/32)
  }
  etr_trajectory_set(time,a,c("a","b"),c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}
test_that("native MIAAFT retains exact channel ranks and measured cross-spectrum",{
  x<-.etr_miaaft_fixture()
  set.seed(83);old<-.Random.seed
  a<-etr_generate_multivariate_iaaft_surrogates(
    x,"a",c("z","x","y"),"x",n_surrogates=3L,
    max_iterations=120L,tolerance=.5,random_state=11L)
  expect_identical(old,.Random.seed)
  expect_s3_class(a,"etr_multivariate_iaaft")
  expect_identical(dim(a$surrogates),c(3L,32L,3L))
  expect_identical(dim(a$spectral_errors),c(3L,3L))
  expect_identical(dim(a$cross_spectral_errors),c(3L,3L))
  expect_identical(a$dimension_names,c("z","x","y"))
  expect_identical(a$reference_dimension,"x")
  expect_true(all(a$convergence_iterations>=2L))
  expect_true(all(a$convergence_iterations<=120L))
  expect_true(all(is.finite(a$spectral_errors)))
  expect_true(all(is.finite(a$cross_spectral_errors)))
  for(b in seq_len(3L))for(d in seq_len(3L))
    expect_equal(sort(a$surrogates[b,,d]),
      sort(a$source_values[,d]),tolerance=0)
  again<-etr_generate_multivariate_iaaft_surrogates(
    x,"a",c("z","x","y"),"x",n_surrogates=3L,
    max_iterations=120L,tolerance=.5,random_state=11L)
  expect_identical(a$surrogates,again$surrogates)
  expect_identical(a$cross_spectral_errors,again$cross_spectral_errors)
  expect_false(a$provenance$source_python_equivalent_stochastic_draws)
})
test_that("native MIAAFT rejects declared domain violations",{
  x<-.etr_miaaft_fixture()
  f<-etr_generate_multivariate_iaaft_surrogates
  expect_error(f(x,"a","x","x"),"at least two")
  expect_error(f(x,"a",c("x","x"),"x"),"distinct")
  expect_error(f(x,"a",c("x","y"),"z"),"reference_dimension")
  expect_error(f(x,"a",c("x","q"),"x"),"existing")
  expect_error(f(x,"a",c("x","y"),"x",n_surrogates=0L),"n_surrogates")
  expect_error(f(x,"a",c("x","y"),"x",tolerance=0),"tolerance")
  bad<-x;bad$values[1,,2]<-2
  expect_error(f(bad,"a",c("x","y"),"x"),"nonconstant")
  irregular<-x;irregular$time[[16L]]<-irregular$time[[16L]]+.003
  expect_error(f(irregular,"a",c("x","y"),"x"),"regular")
})
test_that("pinned Python 1.2 verifies native MIAAFT spectra and exact marginals",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 multivariate IAAFT numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_miaaft_fixture()
  native<-etr_generate_multivariate_iaaft_surrogates(
    x,"a",c("z","x","y"),"x",n_surrogates=2L,
    max_iterations=120L,tolerance=.5,random_state=15L)
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy.multivariate_surrogates import _spectrum_errors
import eyetrajectoriespy as et
def native_miaaft_source_diagnostics(surrogates,source):
    base=np.fft.rfft(source,axis=0)
    pairs=tuple((i,j) for i in range(source.shape[1])
                for j in range(i+1,source.shape[1]))
    cross=tuple(base[:,i]*np.conj(base[:,j]) for i,j in pairs)
    amps=np.abs(base)
    result=[_spectrum_errors(surrogates[k],
        target_amplitudes=amps,
        target_cross_spectra=cross,pairs=pairs)
        for k in range(surrogates.shape[0])]
    return np.stack([v[0] for v in result]),np.stack([v[1] for v in result])
")
  fn<-reticulate::py_eval("native_miaaft_source_diagnostics",
    convert=FALSE)
  scientific<-reticulate::py_to_r(reticulate::py_call(fn,
    reticulate::r_to_py(native$surrogates),
    reticulate::r_to_py(native$source_values)))
  expect_equal(unname(native$spectral_errors),unname(scientific[[1L]]),
    tolerance=1e-10)
  expect_equal(unname(native$cross_spectral_errors),unname(scientific[[2L]]),
    tolerance=1e-10)
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
tt=np.linspace(0,1,32);j=np.arange(32)
r=np.stack([
 np.sin(2*np.pi*3*j/32+.16)+.19*np.cos(2*np.pi*6*j/32),
 np.cos(2*np.pi*3*j/32-.21)+.17*np.sin(2*np.pi*7*j/32),
 .5*-np.sin(2*np.pi*3*j/32+.4)+.28*np.cos(2*np.pi*4*j/32)
],axis=-1)
p=et.TrajectorySet(time=tt,values=r[None,:,:],
 curve_ids=('a',),dimension_names=('x','y','z'),
 coordinate_system='pixels',time_unit='s')
ref=et.generate_multivariate_iaaft_surrogates(
 p,curve='a',dimensions=('z','x','y'),
 reference_dimension='x',n_surrogates=2,
 max_iterations=120,tolerance=.5,random_state=15)
")
  ref<-reticulate::py_eval("ref",convert=FALSE)
  expect_equal(as.integer(native$n_surrogates),
    as.integer(reticulate::py_to_r(ref$n_surrogates)))
  expect_identical(native$dimension_names,
    as.character(reticulate::py_to_r(ref$dimension_names)))
  expect_identical(native$reference_dimension,
    as.character(reticulate::py_to_r(ref$reference_dimension)))
  # Different RNG engines: compare conservation laws, not individual draws.
  reference<-reticulate::py_to_r(ref$surrogates)
  source<-reticulate::py_to_r(ref$source_values)
  for(b in seq_len(dim(reference)[1L]))for(d in seq_len(dim(reference)[3L]))
    expect_equal(sort(reference[b,,d]),sort(source[,d]),tolerance=0)
})
