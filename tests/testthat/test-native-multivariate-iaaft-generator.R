# Frozen Python 1.2 multivariate_surrogates.py source-matched MIAAFT.
.etr_miaaft_fixture<-function(){
  time<-seq(0,1,length.out=32L)
  j<-seq_len(32L)-1
  a<-array(0,c(2L,32L,3L))
  for(i in seq_len(2L)){
    a[i,,1L]<-sin(2*pi*3*j/32+i*.16)+.19*cos(2*pi*6*j/32)
    a[i,,2L]<-cos(2*pi*3*j/32-i*.21)+.17*sin(2*pi*7*j/32)
    a[i,,3L]<-(-0.5)*sin(2*pi*3*j/32+i*.4)+.28*cos(2*pi*4*j/32)
  }
  etr_trajectory_set(time,a,c("a","b"),c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}
test_that("source-matched MIAAFT fixture has the declared negative third channel",{
  x<-.etr_miaaft_fixture()
  j<-seq_len(32L)-1L
  target<-(-0.5)*sin(2*pi*3*j/32+0.4)+
    0.28*cos(2*pi*4*j/32)
  expect_equal(as.numeric(x$values[1L,,3L]),
    target,tolerance=0)
  expect_equal(x$values[1L,1L,3L],
    0.28-0.5*sin(0.4),tolerance=1e-13)
  expect_lt(x$values[1L,1L,3L],0.28)
})

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
  # Direct replay of frozen public MIAAFT under the same NumPy seed.
  # This verifies Python source determinism, not R/NumPy RNG equivalence.
  direct<-reticulate::py_call(
    etpy_get_export("generate_multivariate_iaaft_surrogates"),
    trajectories=reticulate::py_eval("p",convert=FALSE),
    curve="a",dimensions=reticulate::py_eval(
      "('z','x','y')",convert=FALSE),
    reference_dimension="x",n_surrogates=2L,
    max_iterations=120L,tolerance=.5,random_state=15L)
  for(field in c("surrogates","source_values",
    "spectral_errors","cross_spectral_errors")){
    a<-et_to_r(reticulate::py_get_attr(direct,field))
    b<-reticulate::py_eval(paste0("ref.",field),convert=TRUE)
    expect_equal(a,b,tolerance=1e-12,ignore_attr=TRUE,
      info=paste("replayed public IAAFT",field))
  }
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

# This broadband fixture is reserved for strict cross-language draw parity.
# The original exact-frequency harmonic fixture remains separately covered:
# its almost-zero Fourier bins have backend-dependent phases and do not
# support bitwise reproducibility between independently implemented FFTs.
.etr_miaaft_broadband_fixture<-function(){
  time<-seq(0,1,length.out=32L)
  j<-seq_len(32L)-1L
  a<-array(0,c(1L,32L,3L))
  a[1L,,1L]<-sin(2*pi*(3.13*j/32+.11*(j/32)^2)+.16)+
    .19*cos(2*pi*6.37*j/32+.11)+.015*j+.007*((j+1L)%%5L)
  a[1L,,2L]<-cos(2*pi*(2.69*j/32+.09*(j/32)^2)-.21)+
    .17*sin(2*pi*7.23*j/32)+.011*j+.006*((j+3L)%%9L)
  a[1L,,3L]<-(-.5)*sin(2*pi*(3.27*j/32+.12*(j/32)^2)+.4)+
    .28*cos(2*pi*4.41*j/32+.05)+.022*j+.009*((j*j)%%7L)
  etr_trajectory_set(time,a,"a",c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}

test_that("fixed-draw oracle has broadband nonzero spectra in every channel",{
  x<-.etr_miaaft_broadband_fixture()
  input<-x$values[1L,,c(3L,1L,2L)]
  spectrum<-.etr_multivariate_fft_half(input)
  expect_gt(min(Mod(spectrum)),1e-3)
  expect_equal(dim(spectrum),c(17L,3L))
  expect_true(all(is.finite(Re(spectrum))))
})

test_that("frozen Python public MIAAFT agrees with native R under identical initial ranks",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 fixed-permutation numerical differential opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_miaaft_broadband_fixture()
  B<-2L;nt<-length(x$time);d<-3L
  fixed<-array(0L,c(B,nt,d))
  for(i in seq_len(B))for(j in seq_len(d))
    fixed[i,,j]<-(7L*(seq_len(nt)-1L)+3L*i+5L*j)%%nt
  native<-etr_generate_multivariate_iaaft_surrogates(
    x,curve="a",dimensions=c("z","x","y"),
    reference_dimension="x",n_surrogates=B,
    max_iterations=120L,tolerance=.5,
    initial_permutations=fixed)
  # Avoid namespace-qualified assignment to reticulate::py inside
  # testthat: R's replacement assignment looks for an unattached
  # 'reticulate' object before the Python code can run.
  # Construct the exact zero-based permutations in Python itself and
  # assert that their array layout matches the native R fixture.
  reticulate::py_run_string("
import numpy as np
etr_miaaft_fixed_permutations=np.empty((2,32,3),dtype=np.int64)
for _i in range(2):
 for _j in range(3):
  etr_miaaft_fixed_permutations[_i,:,_j]=(
    7*np.arange(32,dtype=np.int64)+3*(_i+1)+5*(_j+1))%32
import eyetrajectoriespy as _etr_miaaft_public
import eyetrajectoriespy.multivariate_surrogates as _etr_miaaft_module
_j=np.arange(32,dtype=np.int64)
_jf=_j.astype(np.float64)
_src=np.stack([
 np.sin(2*np.pi*(3.13*_jf/32+.11*(_jf/32)**2)+.16)
   +.19*np.cos(2*np.pi*6.37*_jf/32+.11)
   +.015*_jf+.007*((_j+1)%5),
 np.cos(2*np.pi*(2.69*_jf/32+.09*(_jf/32)**2)-.21)
   +.17*np.sin(2*np.pi*7.23*_jf/32)
   +.011*_jf+.006*((_j+3)%9),
 -.5*np.sin(2*np.pi*(3.27*_jf/32+.12*(_jf/32)**2)+.4)
   +.28*np.cos(2*np.pi*4.41*_jf/32+.05)
   +.022*_jf+.009*((_j*_j)%7)
],axis=-1)
if np.min(np.abs(np.fft.rfft(_src,axis=0)))<=1e-3:
    raise AssertionError('Source differential fixture is spectrally ill-conditioned')
_tr=_etr_miaaft_public.TrajectorySet(
 time=np.linspace(0,1,32),values=_src[None,:,:],
 curve_ids=('a',),dimension_names=('x','y','z'),
 coordinate_system='pixels',time_unit='s')
_before=_etr_miaaft_module._multivariate_iaaft_one
_counter=[0]
def _etr_fixed_multivariate_oracle(values,*,reference_index,
                                  rng,max_iterations,tolerance):
    replicate=_counter[0]
    _counter[0]+=1
    if replicate>=etr_miaaft_fixed_permutations.shape[0]:
        raise AssertionError('Unexpected surrogate count')
    class Replay:
        def __init__(self): self.channel=0
        def permutation(self,channel_values):
            j=self.channel
            self.channel+=1
            if j>=etr_miaaft_fixed_permutations.shape[2]:
                raise AssertionError('Unexpected channel count')
            source_indices=etr_miaaft_fixed_permutations[replicate,:,j]
            return np.asarray(channel_values)[source_indices]
    return _before(values,reference_index=reference_index,
                   rng=Replay(),max_iterations=max_iterations,
                   tolerance=tolerance)
try:
    _etr_miaaft_module._multivariate_iaaft_one=_etr_fixed_multivariate_oracle
    _etr_fixed_public=_etr_miaaft_public.generate_multivariate_iaaft_surrogates(
      _tr,curve='a',dimensions=('z','x','y'),
      reference_dimension='x',n_surrogates=2,
      max_iterations=120,tolerance=.5,random_state=19)
finally:
    _etr_miaaft_module._multivariate_iaaft_one=_before
if _counter[0]!=2:
    raise AssertionError('Frozen public generator did not replay two draws')
")
  expect_equal(unname(reticulate::py_eval(
    "etr_miaaft_fixed_permutations",convert=TRUE)),
    unname(fixed),tolerance=0)
  src<-reticulate::py_eval("_etr_fixed_public",convert=FALSE)
  expect_equal(
    unname(native$source_values),
    unname(et_to_r(reticulate::py_get_attr(src,"source_values"))),
    tolerance=1e-12,ignore_attr=TRUE,
    info="Input fixture equality must precede numerical inference")
  expect_gt(as.numeric(reticulate::py_eval(
    "np.min(np.abs(np.fft.rfft(_src,axis=0)))",convert=TRUE)),1e-3)
  for(field in c("surrogates",
      "spectral_errors","cross_spectral_errors")){
    observed<-unname(native[[field]])
    published<-unname(et_to_r(reticulate::py_get_attr(src,field)))
    expect_equal(observed,published,tolerance=1e-7,
      ignore_attr=TRUE,info=paste("fixed multivariate IAAFT source",field))
  }
  expect_equal(as.integer(native$convergence_iterations),
    as.integer(et_to_r(reticulate::py_get_attr(src,
      "convergence_iterations"))),tolerance=0)
  expect_false(native$provenance$source_python_equivalent_stochastic_draws)
})
