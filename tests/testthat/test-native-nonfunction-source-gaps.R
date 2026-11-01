# A mapped native S3 scientific object is NOT a complete frozen Python
# dataclass/schema contract. Nonfunction gaps are separate from the 203
# recorded callable-function gaps and must block independent certification.
test_that("TrajectorySet class source differences remain explicit, unsigned and blocking",{
  root<-testthat::test_path("..","..")
  path<-file.path(root,"inst","extdata",
    "native_nonfunction_source_gaps_v1.csv")
  expect_true(file.exists(path))
  gaps<-utils::read.csv(path,stringsAsFactors=FALSE,check.names=FALSE)
  expect_equal(nrow(gaps),1L)
  expect_identical(gaps$namespace,"root")
  expect_identical(gaps$python_name,"TrajectorySet")
  expect_identical(gaps$native_r_candidate,"etr_trajectory_set")
  expect_identical(gaps$frozen_python_commit,
    "c1cd95ad718327550f7e55393ff38582872f7a94")
  expect_true(gaps$unresolved)
  expect_true(grepl("np.nan",gaps$known_source_difference,fixed=TRUE))
  expect_true(grepl("zero-based",gaps$known_source_difference,fixed=TRUE))
  api<-etr_native_parity_catalog()
  expect_identical(nrow(api),508L)
  expect_equal(sum(api$source_contract_gap_unresolved),203L)
  expect_identical(sum(api$nonfunction_source_gap_unresolved),1L)
  row<-api[api$python_name=="TrajectorySet"&api$namespace=="root",,
    drop=FALSE]
  expect_equal(nrow(row),1L)
  expect_true(row$nonfunction_source_gap_unresolved)
  expect_false(row$one_to_one_native_contract_complete)
  readiness<-etr_native_certification_readiness_frame()
  z<-readiness[readiness$python_name=="TrajectorySet"&
    readiness$namespace=="root",,drop=FALSE]
  expect_equal(nrow(z),1L)
  expect_true(z$nonfunction_source_difference_open)
  expect_identical(z$first_unresolved_requirement,
    "unresolved_nonfunction_source_difference")
  expect_false(z$fully_certified)
  expect_true(grepl("independent_review_approval_missing",
    z$all_unresolved_requirements,fixed=TRUE))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
    "NOT complete")
})

test_that("native TrajectorySet represented only as partial S3 class candidate",{
  registry<-utils::read.csv(testthat::test_path("..","..",
    "inst","extdata","native_nonfunction_contract_review_v1.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  expect_identical(nrow(registry),128L)
  mapped<-registry[!is.na(registry$native_representation)&
    nzchar(registry$native_representation),,drop=FALSE]
  expect_identical(nrow(mapped),4L)
  trajectory<-mapped[mapped$python_name=="TrajectorySet",,drop=FALSE]
  expect_identical(nrow(trajectory),1L)
  expect_identical(trajectory$native_representation,"etr_trajectory_set")
  expect_true(all(mapped$evidence_state=="not_reviewed"))
  expect_false(any(mapped$numerical_or_value_approved))
  expect_false(any(mapped$schema_boundary_approved))
  expect_false(any(mapped$scientific_scope_approved))
  expect_false(any(mapped$independent_reviewer_approved))
  expect_true(is.function(get("etr_with_values",
    envir=asNamespace("eyetrajectories"))))
})

test_that("published Python accepts NaN gaps but native S3 source domain rejects NaN",{
  x<-array(c(1,NaN,3),dim=c(1L,3L,1L))
  expect_error(etr_trajectory_set(c(0,1,2),x,
    "c","x"),"NaN or infinity")
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 source class NaN acceptance oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  cls<-etpy_get_export("TrajectorySet",.namespace="root")
  py_obj<-reticulate::py_call(cls,
    time=reticulate::r_to_py(c(0,1,2)),
    values=reticulate::r_to_py(x),
    # pandas.Index(...) requires a collection; r_to_py("c") yields
    # a scalar Python str and fails before the scientific NaN oracle.
    curve_ids=reticulate::r_to_py(list("c")),
    dimension_names=reticulate::r_to_py(list("x")))
  actual<-reticulate::py_to_r(py_obj$values)
  expect_true(is.nan(actual[1L,2L,1L]))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
