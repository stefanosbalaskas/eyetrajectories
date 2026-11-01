# Frozen Python 1.2 pilot contract: deterministic scientific domain witnesses.
# Source paths: compositional.py, analysis.py, fpca.py.
# These are first-party source equivalence tests, NEVER independent approval.
.etr_pilot_adversarial_simplex<-function(){
  x<-array(0,c(4L,7L,3L))
  for(i in 1:4)for(t in 1:7){
    a<-.08+.015*i+.003*t
    b<-.34+.009*t+.002*i
    x[i,t,]<-c(a,b,1-a-b)
  }
  x[1L,1L,]<-c(0,.23,.77)
  x
}

test_that("pilot quadrature grids and truthy numeric flags have exact finite witnesses",{
  grids<-list(c(0,1),c(-2,-.5,1.25,3),
    c(1e-6,1e-4,1.7),list(0L,1L,3L))
  for(t in grids){
    x<-as.numeric(unlist(t))
    dt<-diff(x)
    w<-c(dt[1L]/2,if(length(x)>2L)
      (dt[-1L]+dt[-length(dt)])/2,tail(dt,1L)/2)
    expect_equal(etr_trapezoid_weights(t),w,tolerance=1e-14)
    for(flag in c(FALSE,0L,0,TRUE,1L,-2L,.5))
      expect_equal(etr_trapezoid_weights(t,normalize=flag),
        if(flag!=0)w/sum(w) else w,tolerance=1e-14)
  }
  for(flag in c("yes","0","", "FALSE", " ",
      "normalize")) {
    expected<-if(nzchar(flag))c(.5,1.5,1)/3 else c(.5,1.5,1)
    expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=flag),
      expected,tolerance=1e-14)
  }
  expect_error(etr_trapezoid_weights(c(0,1,3),
    normalize=NA_character_),"normalize")
  expect_error(etr_trapezoid_weights(c(0,1,3),
    normalize=c("a","b")),"normalize")
  expect_error(etr_trapezoid_weights(c(0,0,1)),
    "strictly increasing")
  expect_error(etr_trapezoid_weights(c(0,1,NA_real_)),
    "strictly increasing")
})

test_that("pilot ALR/inverse retain simplex mass and zero clipping across references",{
  vals<-.etr_pilot_adversarial_simplex()
  for(epsilon in c(1e-8,.01,.07)){
    for(ref in c(-1L,0L,1L,2L)){
      z<-etr_alr_transform(vals,reference_dimension=ref,epsilon=epsilon)
      expect_identical(dim(z),c(4L,7L,2L))
      inverse<-etr_inverse_alr(z,reference_dimension=ref,
        n_dimensions=3L)
      expect_identical(dim(inverse),dim(vals))
      expect_true(all(is.finite(inverse)))
      expect_true(all(inverse>=0))
      expect_equal(as.numeric(apply(inverse,c(1L,2L),sum)),
        rep(1,28L),tolerance=1e-14)
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("four pinned Python 1.2 pilot public source numerical witnesses match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 pilot boundary-source numerical witnesses opt-in")
  expect_identical(et_python_version(),"1.2.0")
  grids<-list(c(0,1),c(-2,-.5,1.25,3),
    c(1e-6,1e-4,1.7))
  for(tt in grids)for(flag in c(0L,1L,-2L)){
    py<-reticulate::py_call(
      etpy_get_export("functional_trapezoid_weights"),
      time=reticulate::r_to_py(tt),normalize=flag)
    expect_equal(as.numeric(etr_trapezoid_weights(tt,normalize=flag)),
      as.numeric(et_to_r(py)),tolerance=1e-12)
  }
  for(flag in c("yes","0","", "FALSE", " ")) {
    py<-reticulate::py_call(
      etpy_get_export("functional_trapezoid_weights"),
      time=reticulate::r_to_py(c(0,1,3)),normalize=flag)
    expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=flag),
      as.numeric(et_to_r(py)),tolerance=1e-14,
      info=paste("Python scalar string normalization",flag))
  }
  vals<-.etr_pilot_adversarial_simplex()
  for(epsilon in c(1e-8,.01,.07))for(ref in c(-1L,0L,1L,2L)){
    rz<-etr_alr_transform(vals,reference_dimension=ref,epsilon=epsilon)
    pz<-reticulate::py_call(etpy_get_export("alr_transform"),
      values=reticulate::r_to_py(vals),
      reference_dimension=as.integer(ref),epsilon=epsilon)
    expect_equal(unname(rz),unname(et_to_r(pz)),tolerance=1e-12)
    ri<-etr_inverse_alr(rz,reference_dimension=ref,n_dimensions=3L)
    py_inverse<-reticulate::py_call(etpy_get_export("inverse_alr"),
      transformed=pz,reference_dimension=as.integer(ref),
      n_dimensions=as.integer(3L))
    expect_equal(unname(ri),unname(et_to_r(py_inverse)),tolerance=1e-12)
  }
  t<-seq(0,1,length.out=9L);v<-array(0,c(5L,9L,2L))
  for(i in 1:5){
    v[i,,1L]<-sin(2*base::pi*t)+i*.07*cos(base::pi*t)
    v[i,,2L]<-cos(2*base::pi*t)+i*.04*sin(base::pi*t)
  }
  tr<-etr_trajectory_set(t,v,paste0("curve",seq_len(5L)),c("x","y"))
  fit<-etr_fit_mfpca(tr,n_components=2L)
  types<-reticulate::import("types")
  py_fit<-types$SimpleNamespace(
    scores=reticulate::r_to_py(fit$scores),
    n_components=as.integer(fit$n_components))
  for(k in c(1L,2L)){
    py<-reticulate::py_call(etpy_get_export("score_distance_matrix"),
      fpca=py_fit,n_components=as.integer(k))
    r<-etr_score_distance_matrix(fit,n_components=k)
    expect_equal(unname(r),unname(et_to_r(py)),tolerance=1e-10)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("frozen Python 1.2 first-pilot boundary differences remain explicit",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Source-specific exceptional-domain Python probes are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  # NumPy permits a final +Inf grid because source checks diff(time)>0;
  # native scientific quadrature intentionally rejects nonfinite time.
  inf_grid<-c(0,1,Inf)
  py_weights<-reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(inf_grid))
  expect_true(any(is.infinite(as.numeric(et_to_r(py_weights)))))
  expect_error(etr_trapezoid_weights(inf_grid),"strictly increasing")
  # Python's finite character scalar truthiness now matches
  # the native scientific subset; arbitrary Python objects remain open.
  py_truthy<-reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(c(0,1,3)),normalize="yes")
  expect_equal(as.numeric(et_to_r(py_truthy)),
    c(.5,1.5,1)/3,tolerance=1e-14)
  expect_equal(etr_trapezoid_weights(c(0,1,3),normalize="yes"),
    as.numeric(et_to_r(py_truthy)),tolerance=1e-14)
  # Source inverse uses unguarded exp; at very large finite logits it
  # returns nonfinite output. The native contract fails closed instead.
  z<-array(c(1000,-1),c(1L,1L,2L))
  # Scope suppression to the two EXPECTED NumPy floating-point warnings,
  # leaving Python exceptions and testthat failures fully observable.
  np<-reticulate::import("numpy",convert=FALSE)
  py_inverse<-with(np$errstate(over="ignore",invalid="ignore"),
    reticulate::py_call(etpy_get_export("inverse_alr"),
      transformed=reticulate::r_to_py(z),
      reference_dimension=as.integer(0L),n_dimensions=as.integer(3L)))
  expect_true(any(!is.finite(et_to_r(py_inverse))))
  expect_error(etr_inverse_alr(z,0L,3L),"overflowed")
  # NumPy's epsilon<=0 check admits NaN, which propagates NaN
  # ratios. The native estimator deliberately rejects an invalid floor.
  v<-.etr_pilot_adversarial_simplex()
  py_nan_eps<-reticulate::py_call(etpy_get_export("alr_transform"),
    values=reticulate::r_to_py(v),epsilon=NaN)
  expect_true(all(is.nan(et_to_r(py_nan_eps))))
  expect_error(etr_alr_transform(v,epsilon=NaN),"epsilon")
  # A new numerical alignment is not a full-domain source certification.
  differences<-etr_native_parity_catalog()
  pilot_names<-c("functional_trapezoid_weights","inverse_alr",
    "score_distance_matrix","alr_transform")
  expect_true(all(differences$source_contract_gap_unresolved[
    differences$python_name %in% pilot_names]))
  expect_false(any(differences$one_to_one_native_contract_complete))
})

test_that("finite numeric-string inverse-ALR arrays retain NumPy geometry",{
  text_logits<-array(c("-0.5","0.0","0.25","1.0"),
    c(1L,2L,2L))
  numeric_logits<-array(as.numeric(text_logits),dim(text_logits))
  native<-etr_inverse_alr(text_logits,0L,3L)
  expect_identical(dim(native),c(1L,2L,3L))
  expect_equal(native,etr_inverse_alr(numeric_logits,0L,3L),
    tolerance=1e-14)
  expect_true(all(is.finite(native)))
  expect_equal(as.numeric(apply(native,c(1L,2L),sum)),
    rep(1,2L),tolerance=1e-14)
  bad<-text_logits;bad[1L,1L,1L]<-"not-numeric"
  expect_error(etr_inverse_alr(bad,0L,3L),
    "incompatible dimensions or nonfinite")
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python inverse-ALR numeric-string coercion oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  published<-reticulate::py_call(etpy_get_export("inverse_alr"),
    transformed=reticulate::r_to_py(text_logits),
    reference_dimension=as.integer(0L),n_dimensions=as.integer(3L))
  expect_equal(unname(native),unname(et_to_r(published)),
    tolerance=1e-12)
  expect_true(etr_native_parity_catalog()$source_contract_gap_unresolved[
    etr_native_parity_catalog()$python_name=="inverse_alr"])
})

test_that("finite numeric-string simplex arrays match the source ALR contract",{
  source_values<-.etr_pilot_adversarial_simplex()
  character_values<-array(as.character(source_values),dim(source_values))
  numeric_values<-array(as.numeric(character_values),
    dim(character_values))
  for(ref in c(-1L,0L,1L,2L)){
    for(epsilon in c(1e-8,1e-3)){
      native<-etr_alr_transform(character_values,
        reference_dimension=ref,epsilon=epsilon)
      expected<-etr_alr_transform(numeric_values,
        reference_dimension=ref,epsilon=epsilon)
      expect_identical(dim(native),c(4L,7L,2L))
      expect_equal(unname(native),unname(expected),tolerance=1e-14)
      expect_true(all(is.finite(native)))
    }
  }
  bad<-character_values;bad[1L,1L,1L]<-"not-a-number"
  expect_error(etr_alr_transform(bad))
  missing<-character_values;missing[1L,1L,1L]<-"NaN"
  expect_error(etr_alr_transform(missing))
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python ALR numeric-string array oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  for(ref in c(-1L,0L,1L,2L)){
    native<-etr_alr_transform(character_values,
      reference_dimension=ref,epsilon=1e-3)
    published<-reticulate::py_call(etpy_get_export("alr_transform"),
      values=reticulate::r_to_py(character_values),
      reference_dimension=as.integer(ref),epsilon=1e-3)
    expect_equal(unname(native),unname(et_to_r(published)),
      tolerance=1e-12)
  }
  expect_true(etr_native_parity_catalog()$source_contract_gap_unresolved[
    etr_native_parity_catalog()$python_name=="alr_transform"])
})

test_that("Boolean ALR and inverse arrays match published numeric coercion",{
  simplex<-array(FALSE,c(2L,3L,2L))
  simplex[,,1L]<-TRUE
  simplex[1L,2L,1L]<-FALSE
  simplex[1L,2L,2L]<-TRUE
  numeric_simplex<-array(as.numeric(simplex),dim(simplex))
  logits<-array(c(TRUE,FALSE,TRUE,FALSE),c(1L,2L,2L))
  numeric_logits<-array(as.numeric(logits),dim(logits))
  for(ref in c(0L,1L)) {
    native<-etr_alr_transform(simplex,reference_dimension=ref)
    expect_equal(native,
      etr_alr_transform(numeric_simplex,reference_dimension=ref),
      tolerance=0)
    inverse<-etr_inverse_alr(logits,reference_dimension=ref,
      n_dimensions=3L)
    expect_equal(inverse,etr_inverse_alr(numeric_logits,
      reference_dimension=ref,n_dimensions=3L),tolerance=0)
    if(identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true")) {
      expect_identical(et_python_version(),"1.2.0")
      source_alr<-reticulate::py_call(etpy_get_export("alr_transform"),
        values=reticulate::r_to_py(simplex),
        reference_dimension=as.integer(ref))
      source_inverse<-reticulate::py_call(
        etpy_get_export("inverse_alr"),
        transformed=reticulate::r_to_py(logits),
        reference_dimension=as.integer(ref),
        n_dimensions=as.integer(3L))
      expect_equal(unname(native),unname(et_to_r(source_alr)),
        tolerance=1e-12)
      expect_equal(unname(inverse),unname(et_to_r(source_inverse)),
        tolerance=1e-12)
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
