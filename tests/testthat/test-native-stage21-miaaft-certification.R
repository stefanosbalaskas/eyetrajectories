# Stage 21: native reference-anchored multivariate IAAFT and
# explicit 508-source certification gates.

.etr21_fixture<-function(){
  n<-64L;t<-seq(0,1,length.out=n)
  z<-array(0,c(3L,n,3L))
  for(i in 1:3){
    z[i,,1L]<-sin(4*pi*t+.12*i)+.15*cos(10*pi*t+.1*i)
    z[i,,2L]<-.6*sin(4*pi*t+.12*i+.6)+.2*cos(6*pi*t+.13*i)
    z[i,,3L]<-.4*cos(4*pi*t+.12*i+.4)+.2*sin(8*pi*t+.2*i)
  }
  etr_trajectory_set(t,z,paste0("c",1:3),c("x","y","z"),
    time_unit="s",coordinate_system="normalized")
}

test_that("Stage 21 reference-anchored IAAFT exactly preserves all declared marginal samples",{
  x<-.etr21_fixture()
  set.seed(210);old<-.Random.seed
  z<-etr_generate_multivariate_iaaft_surrogates(x,"c1",c("y","x","z"),
    reference_dimension="x",n_surrogates=3L,
    max_iterations=12L,tolerance=10,random_state=5L)
  expect_identical(old,.Random.seed)
  expect_s3_class(z,"etr_multivariate_iaaft")
  expect_identical(dim(z$surrogates),c(3L,64L,3L))
  expect_identical(dim(z$source_values),c(64L,3L))
  expect_identical(dim(z$spectral_errors),c(3L,3L))
  expect_identical(dim(z$cross_spectral_errors),c(3L,3L))
  expect_identical(z$dimension_names,c("y","x","z"))
  expect_identical(z$reference_dimension,"x")
  expect_true(all(z$convergence_iterations>=2L&
    z$convergence_iterations<=12L))
  expect_true(all(is.finite(z$spectral_errors)&
    z$spectral_errors>=0))
  expect_true(all(is.finite(z$cross_spectral_errors)&
    z$cross_spectral_errors>=0))
  for(b in 1:3)for(j in 1:3)
    expect_equal(sort(z$surrogates[b,,j]),
      sort(z$source_values[,j]),tolerance=0)
  zz<-etr_generate_multivariate_iaaft_surrogates(x,"c1",c("y","x","z"),
    reference_dimension="x",n_surrogates=3L,
    max_iterations=12L,tolerance=10,random_state=5L)
  expect_identical(z$surrogates,zz$surrogates)
  expect_false(z$provenance$source_python_equivalent_stochastic_draws)
})

test_that("Stage 21 spectral and cross-spectral errors reproduce exact declared Fourier formulas",{
  x<-.etr21_fixture()
  z<-etr_generate_multivariate_iaaft_surrogates(x,curve=0L,
    dimensions=c("x","y","z"),reference_dimension="y",
    n_surrogates=2L,tolerance=10,random_state=9L)
  fft<-function(a)stats::fft(a)[seq_len(33L)]
  src<-vapply(1:3,function(j)fft(z$source_values[,j]),complex(33L))
  target<-Mod(src)
  for(b in 1:2){
    val<-matrix(z$surrogates[b,,],nrow=64L,ncol=3L)
    test<-vapply(1:3,function(j)fft(val[,j]),complex(33L))
    for(j in 1:3){
      num<-sqrt(sum((Mod(test[,j])-target[,j])^2))
      den<-max(sqrt(sum(target[,j]^2)),.Machine$double.eps)
      expect_equal(z$spectral_errors[b,j],num/den,tolerance=1e-13)
    }
    for(pair in 1:3){
      a<-list(c(1L,2L),c(1L,3L),c(2L,3L))[[pair]]
      original<-src[,a[1L]]*Conj(src[,a[2L]])
      current<-test[,a[1L]]*Conj(test[,a[2L]])
      den<-max(sqrt(sum(Mod(original[-1L])^2)),.Machine$double.eps)
      err<-sqrt(sum(Mod(current[-1L]-original[-1L])^2))/den
      expect_equal(z$cross_spectral_errors[b,pair],err,tolerance=1e-13)
    }
  }
})

test_that("Stage 21 diagnostics preserve source-shaped summary fields and sample indexing",{
  x<-.etr21_fixture()
  z<-etr_generate_multivariate_iaaft_surrogates(x,curve="c2",
    dimensions=c("x","y"),reference_dimension="x",
    n_surrogates=2L,tolerance=10,random_state=8L)
  frame<-etr_multivariate_iaaft_diagnostics_frame(z)
  expect_identical(names(frame),c("surrogate","iterations",
    "max_spectral_error","max_cross_spectral_error",
    "mean_spectral_error","mean_cross_spectral_error"))
  expect_equal(nrow(frame),2L)
  expect_identical(frame$surrogate,0:1)
  expect_equal(frame$iterations,z$convergence_iterations)
  expect_equal(frame$max_spectral_error,
    apply(z$spectral_errors,1L,max))
  expect_equal(frame$mean_cross_spectral_error,
    rowMeans(z$cross_spectral_errors))
  expect_error(etr_multivariate_iaaft_diagnostics_frame(list()),
    "native multivariate")
})

test_that("Stage 21 source fail-closed contracts reject invalid channels/iterations",{
  x<-.etr21_fixture()
  args<-list(trajectories=x,curve="c1",
    dimensions=c("x","y"),reference_dimension="x",
    n_surrogates=1L,max_iterations=12L,tolerance=10,random_state=7L)
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    modifyList(args,list(dimensions=c("x","x")))),"distinct")
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    modifyList(args,list(reference_dimension="z"))),"reference_dimension")
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    modifyList(args,list(n_surrogates=0L))),"n_surrogates")
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    modifyList(args,list(tolerance=0))),"tolerance")
  flat<-x;flat$values[1L,,2L]<-1
  expect_error(etr_generate_multivariate_iaaft_surrogates(flat,"c1",
    c("x","y"),"x",n_surrogates=1L,tolerance=10,random_state=2L),
    "nonconstant")
})

test_that("Stage 21 ledger records two mappings without unreviewed source approvals",{
  was<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),173L)
  expect_equal(sum(z$native_implementation_started),148L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),207L)
  expect_equal(sum(z$native_implementation_stage==21L,na.rm=TRUE),2L)
  expect_equal(sum(z$contract_numerical_fixture_pass),3L)
  expect_equal(sum(z$contract_certification_candidate),3L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 21 independent pinned Python v1.2 spectral diagnostic oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 21 source Python 1.2 multivariate spectral oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr21_fixture()
  native<-etr_generate_multivariate_iaaft_surrogates(x,"c1",
    c("x","y"),"x",n_surrogates=2L,tolerance=10,random_state=6L)
  # Compare *properties and formula-based errors*, not stochastic
  # realizations from different R/NumPy random generators.
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    time_unit="s",coordinate_system="normalized")
  py<-reticulate::py_call(etpy_get_export(
    "generate_multivariate_iaaft_surrogates"),
    trajectories=pyx,curve="c1",dimensions=as.list(c("x","y")),
    reference_dimension="x",n_surrogates=as.integer(2L),
    max_iterations=as.integer(1000L),tolerance=10,
    random_state=as.integer(6L))
  pys<-et_to_r(py$surrogates)
  expect_identical(dim(pys),dim(native$surrogates))
  for(b in 1:2)for(j in 1:2){
    expect_equal(sort(pys[b,,j]),sort(native$source_values[,j]),
      tolerance=1e-12)
    expect_equal(sort(native$surrogates[b,,j]),
      sort(native$source_values[,j]),tolerance=0)
  }
  pyframe<-reticulate::py_call(etpy_get_export(
    "multivariate_iaaft_diagnostics_frame"),result=py)
  a<-et_to_r(pyframe)
  b<-etr_multivariate_iaaft_diagnostics_frame(native)
  expect_identical(names(a),names(b))
  expect_equal(nrow(a),nrow(b))
  expect_equal(b$iterations,native$convergence_iterations)
  expect_true(all(is.finite(as.numeric(as.matrix(a[,3:6])))))
  expect_true(all(is.finite(as.numeric(as.matrix(b[,3:6])))))
  # NO claim that exact surrogate draws or their spectral errors
  # match across independent RNG engines.
})
