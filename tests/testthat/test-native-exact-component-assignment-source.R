# Exact native R assignment versus frozen Python 1.2 stability.py.
# Source: eyetrajectoriespy@c1cd95ad718327550f7e55393ff38582872f7a94
# First-party numerical source witnesses, never independent certification.

.etr_assignment_source_fits <- function(k=16L) {
  tt<-seq(0,1,length.out=k)
  w<-etr_trapezoid_weights(tt)
  basis<-array(0,c(k,k,1L))
  for(i in seq_len(k))basis[i,i,1L]<-1/sqrt(w[i])
  reference<-structure(list(time=tt,curve_ids=paste0("id",seq_len(k+3L)),
    dimension_names="x",coordinate_system="unknown",time_unit="s",
    mean=matrix(0,k,1L),components=basis,
    scores=matrix(0,k+3L,k),weights=w,scale=1,
    explained_variance=as.numeric(rev(seq_len(k))),
    explained_variance_ratio=rev(seq_len(k))/sum(seq_len(k)),
    n_components=k,scaling="none"),class="etr_fpca")
  # Deliberately nontrivial component reorder and alternating sign.
  perm<-as.integer(c(seq.int(k,1L,by=-2L),
    seq.int(k-1L,1L,by=-2L)))
  # For odd k, the descending-by-two lists overlap only if the parity
  # of k-1 and k matches; rebuild deterministically if necessary.
  if(length(perm)!=k || anyDuplicated(perm))
    perm<-as.integer(c(seq(2L,k,by=2L),seq(1L,k,by=2L)))
  signs<-rep(c(1,-1),length.out=k)
  candidate<-reference
  candidate$components<-sweep(basis[perm,,,drop=FALSE],
    1L,signs,"*")
  list(reference=reference,candidate=candidate,
    expected=as.integer(match(seq_len(k),perm)-1L),
    expected_sign=as.numeric(signs[match(seq_len(k),perm)]))
}

test_that("Hungarian assignment is globally optimal, not greedy, at k=13",{
  k<-13L;cost<-matrix(1000,k,k)
  diag(cost)<-0
  cost[1L,1L]<-1
  cost[1L,2L]<-2
  cost[2L,1L]<-1
  cost[2L,2L]<-100
  assigned<-eyetrajectories:::.etr_exact_assignment_hungarian(cost)
  expect_identical(length(assigned),k)
  expect_identical(sort(assigned),as.integer(0:(k-1L)))
  expect_identical(assigned[1:2],as.integer(c(1,0)))
  expect_equal(sum(cost[cbind(seq_len(k),assigned+1L)]),3,
    tolerance=0)
  expect_error(eyetrajectories:::.etr_exact_assignment_hungarian(
    matrix(c(1,Inf,1,1),2L)),"finite square")
})

test_that("native exact FPCA matching supports more than twelve components",{
  for(k in c(13L,16L,24L)){
    fit<-.etr_assignment_source_fits(k)
    result<-etr_match_fpca_components(fit$reference,fit$candidate,
      n_components=k)
    expect_identical(result$assignments,fit$expected)
    expect_equal(result$signed_similarity,fit$expected_sign,
      tolerance=1e-12)
    expect_equal(sum(abs(result$signed_similarity)),k,tolerance=1e-12)
    expect_identical(sort(result$assignments),as.integer(0:(k-1L)))
    sim<-etr_component_similarity_matrix(fit$reference,fit$candidate,
      n_components=k)
    expect_identical(dim(sim),c(k,k))
    expect_equal(abs(sim[cbind(seq_len(k),result$assignments+1L)]),
      rep(1,k),tolerance=1e-12)
  }
})

test_that("legacy 12-component exact DP remains correct and unchanged",{
  fit<-.etr_assignment_source_fits(12L)
  r<-etr_match_fpca_components(fit$reference,fit$candidate)
  expect_identical(r$assignments,fit$expected)
  expect_equal(r$signed_similarity,fit$expected_sign,tolerance=1e-12)
})

test_that("frozen Python SciPy assignment matches native 13-to-24 FPCs",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 >12-component SciPy source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  types<-reticulate::import("types",convert=FALSE)
  np<-reticulate::import("numpy",convert=FALSE)
  as_source<-function(f) {
    # reticulate::r_to_py() may leave an atomic vector as Python list,
    # depending on conversion and environment. The frozen Python source
    # requires NumPy indexing weights[:, None] and scale[None, None, :].
    # Explicitly build genuine NumPy arrays for each numeric source field.
    types$SimpleNamespace(
      time=np$asarray(reticulate::r_to_py(f$time),dtype="float64"),
      dimension_names=reticulate::r_to_py(as.list(f$dimension_names)),
      n_components=as.integer(f$n_components),
      weights=np$asarray(reticulate::r_to_py(f$weights),dtype="float64"),
      components=np$asarray(reticulate::r_to_py(f$components),
        dtype="float64"),
      scale=np$asarray(reticulate::r_to_py(as.list(f$scale)),
        dtype="float64"))
  }
  for(k in c(13L,16L,24L)) {
    fit<-.etr_assignment_source_fits(k)
    native<-etr_match_fpca_components(fit$reference,fit$candidate,
      n_components=k)
    py_reference<-as_source(fit$reference)
    py_candidate<-as_source(fit$candidate)
    # Assert source fixture shape/ndarray contracts BEFORE invoking
    # the scientific oracle so a bridge failure is independently located.
    for(py_fit in list(py_reference,py_candidate)) {
      expect_identical(as.character(et_to_r(py_fit$weights$dtype$name)),
        "float64")
      expect_identical(as.integer(et_to_r(py_fit$weights$shape)),as.integer(k))
      expect_identical(as.integer(et_to_r(py_fit$scale$shape)),1L)
      expect_identical(as.integer(et_to_r(py_fit$components$shape)),
        c(as.integer(k),as.integer(k),1L))
    }
    py<-reticulate::py_call(etpy_get_export("match_fpca_components"),
      reference=py_reference,
      candidate=py_candidate,n_components=k)
    result<-et_to_r(py)
    expect_identical(native$assignments,as.integer(result[[1L]]))
    expect_equal(native$signed_similarity,as.numeric(result[[2L]]),
      tolerance=1e-12)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
