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
