# Source-contract boundary probes against the exact published Python 1.2.
# These tests intentionally document non-equivalent accepted inputs/results.
# A green probe NEVER upgrades any of the 508 full-contract approval flags.

test_that("source-contract approval cannot be inferred from numeric fixtures",{
  z<-etr_native_parity_catalog()
  candidates<-z[z$contract_certification_candidate,,drop=FALSE]
  expect_setequal(candidates$python_name,
    c("alr_transform","inverse_alr","score_distance_matrix"))
  expect_true(all(candidates$contract_numerical_fixture_pass))
  expect_false(any(candidates$independent_numeric_parity_pass))
  expect_false(any(candidates$behavioral_schema_parity_pass))
  expect_false(any(candidates$independent_contract_review_pass))
  expect_false(any(candidates$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
    "NOT complete")
})

test_that("published Python 1.2 accepts inputs that strict native R rejects",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Direct pinned published Python 1.2 boundary probes are opt-in")
  expect_identical(et_python_version(),"1.2.0")

  # Python converts nested regular sequences with np.asarray. Native
  # R now supports the corresponding rectangular numeric 3-D inputs.
  nested<-list(list(c(0.2,0.3,0.5)))
  py_alr<-reticulate::py_call(etpy_get_export("alr_transform"),
    values=reticulate::r_to_py(nested))
  alr_values<-et_to_r(py_alr)
  expect_equal(dim(alr_values),c(1L,1L,2L))
  expect_equal(unname(etr_alr_transform(nested)),unname(alr_values),
    tolerance=1e-12)
  expect_error(etr_alr_transform(list(list(c(.2,.3,.5)),
    list(c(.2,.3),c(.3,.3,.4)))),"rectangular")

  # Published inverse_alr uses np.exp and ordinary numpy division,
  # yielding nonfinite entries for extreme log-ratios; strict native R
  # rejects nonfinite normalization instead of returning it.
  extreme<-array(c(1000,0),c(1L,1L,2L))
  py_inverse<-suppressWarnings(reticulate::py_call(
    etpy_get_export("inverse_alr"),
    transformed=reticulate::r_to_py(extreme),
    reference_dimension=as.integer(2L),
    n_dimensions=as.integer(3L)))
  expect_true(any(!is.finite(as.numeric(et_to_r(py_inverse)))))
  expect_error(etr_inverse_alr(extreme,2L,3L),
    "overflow")

  # Python reads .scores and .n_components on any compatible object,
  # without requiring a concrete fitted FPCA dataclass. The R
  # implementation requires a validated native etr_fpca fit.
  sc<-matrix(c(0,1,2,3,4,5),nrow=3L,ncol=2L)
  ns<-reticulate::import("types")$SimpleNamespace(
    scores=reticulate::r_to_py(sc),
    n_components=as.integer(2L))
  py_distance<-reticulate::py_call(etpy_get_export(
    "score_distance_matrix"),fpca=ns,
    n_components=as.integer(2L))
  expect_equal(unname(et_to_r(py_distance)),
    unname(as.matrix(stats::dist(sc))),tolerance=1e-12)
  expect_error(etr_score_distance_matrix(
    list(scores=sc,n_components=2L)),
    "compatible native FPCA")

  z<-etr_native_parity_catalog()
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})
