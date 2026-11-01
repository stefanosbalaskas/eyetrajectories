# Frozen source eyetrajectoriespy 1.2.0, exact commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Scalar value representation is NOT workflow format interoperability.
test_that("native source workflow scalar values are exact, typed, and unapproved",{
  v<-etr_frozen_workflow_values()
  expected<-list(
    WORKFLOW_SCHEMA_VERSION=1L,
    WORKFLOW_BUNDLE_SCHEMA_VERSION=1L,
    WORKFLOW_BUNDLE_FORMAT="eyetrajectoriespy-workflow-bundle")
  expect_identical(v,expected)
  expect_identical(etr_frozen_workflow_values(),expected)
  # The native R portable bundle has a DISTINCT format.
  expect_false(identical(v$WORKFLOW_BUNDLE_FORMAT,
    "etr_native_r_workflow_bundle_v1"))
  cat<-etpy_catalog(include_nonfunctions=TRUE)
  symbols<-names(expected)
  rows<-cat[cat$python_name%in%symbols,,drop=FALSE]
  expect_identical(nrow(rows),3L)
  expect_true(all(rows$namespace=="workflows"))
  expect_true(all(rows$kind=="other_export"))
  reg<-utils::read.csv(testthat::test_path("..","..","inst","extdata",
    "native_nonfunction_contract_review_v1.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  mapped<-reg[reg$python_name%in%symbols&
    reg$namespace=="workflows",,drop=FALSE]
  expect_identical(nrow(mapped),3L)
  for(i in seq_len(nrow(mapped))){
    symbol<-mapped$python_name[[i]]
    expect_identical(mapped$native_representation[[i]],
      paste0("etr_frozen_workflow_values()$",symbol))
  }
  expect_true(all(mapped$evidence_state=="not_reviewed"))
  expect_false(any(mapped$numerical_or_value_approved))
  expect_false(any(mapped$schema_boundary_approved))
  expect_false(any(mapped$scientific_scope_approved))
  expect_false(any(mapped$independent_reviewer_approved))
  audit<-etr_native_parity_catalog()
  expect_identical(nrow(audit),508L)
  expect_identical(sum(audit$one_to_one_native_contract_complete),0L)
  for(nm in symbols){
    row<-audit[audit$python_name==nm&
      audit$namespace=="workflows",,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_false(row$one_to_one_native_contract_complete)
    expect_identical(row$nonfunction_native_representation,
      paste0("etr_frozen_workflow_values()$",nm))
  }
})

test_that("all three R workflow scalar representations match frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 workflow source-scalar oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  native<-etr_frozen_workflow_values()
  for(symbol in names(native)){
    source<-etpy_get_export(symbol,.namespace="workflows")
    observed<-reticulate::py_to_r(source)
    if(symbol=="WORKFLOW_BUNDLE_FORMAT")
      expect_identical(as.character(observed),native[[symbol]])
    else
      expect_identical(as.integer(observed),native[[symbol]])
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("Python workflow allowed plot tuple is not misrepresented as native support",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python workflow plot tuple witness is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  py<-etpy_get_export("SUPPORTED_WORKFLOW_PLOTS",
    .namespace="workflows")
  plots<-as.character(reticulate::py_to_r(py))
  expect_identical(plots,c("fpca_component","sparse_fpca_component",
    "sparse_mfpca_component","function_on_scalar_coefficient",
    "functional_mixed_effects_coefficient",
    "generalized_functional_coefficient","recurrence"))
  # The native dispatcher supports a strict subset, and must never be
  # described as implementing the seven-source plot domain.
  native_dispatch<-paste(readLines(testthat::test_path("..","..",
    "R","native-workflow-plot-dispatch.R"),warn=FALSE),
    collapse="\n")
  expect_true(grepl('plot%in%c("fpca_component",',
    native_dispatch,fixed=TRUE))
  expect_false(grepl('plot%in%c("fpca_component","sparse_fpca_component"',
    native_dispatch,fixed=TRUE))
})
