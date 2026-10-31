# Hard gate for exactly the 380 source Python function symbols.
# A declared native analogue is NOT a scientific source certification.
test_that("every frozen Python 1.2 function has a uniquely exported R analogue",{
  catalog<-etr_native_parity_catalog()
  expect_identical(nrow(catalog),508L)
  functions<-catalog[catalog$is_python_function,,drop=FALSE]
  expect_identical(nrow(functions),380L)
  expect_identical(length(unique(functions$python_name)),380L)
  expect_true(all(functions$named_native_candidate))
  expect_true(all(nzchar(functions$native_r_candidate)))
  expect_true(all(functions$native_r_candidate%in%
    getNamespaceExports("eyetrajectories")))
  expect_false(any(grepl("stage",functions$native_r_candidate,
    ignore.case=TRUE)))
  expect_false(any(functions$one_to_one_native_contract_complete))
})

test_that("all newly mapped scientific alternatives remain explicitly uncertified",{
  recent<-c("fit_elastic_fpca","fit_sparse_mfpca",
    "run_sparse_mfpca_workflow","run_sparse_mfpca_async_workflow",
    "run_sparse_multilevel_workflow",
    "run_sparse_prediction_workflow",
    "functional_mixed_effects_covariance_sensitivity",
    "bootstrap_functional_mixed_effects_coefficients",
    "bootstrap_functional_mixed_effects_full_refit",
    "to_skfda_grid","to_skfda_basis",
    "detect_functional_outliers_skfda",
    "to_fdapy_irregular","fit_sparse_fpca_fdapy")
  catalog<-etr_native_parity_catalog()
  f<-catalog[match(recent,catalog$python_name),,drop=FALSE]
  expect_identical(nrow(f),length(recent))
  expect_true(all(f$is_python_function))
  expect_true(all(f$named_native_candidate))
  expect_false(any(f$one_to_one_native_contract_complete))
  # A native substitute never automatically receives a full-domain source
  # certificate just because an R name has been mapped and exported.
  expect_true(all(f$native_backend_or_estimand_differs_from_python))
  gap_path<-testthat::test_path("..","..","inst","extdata",
    "native_source_contract_gaps_stage22.csv")
  gap<-utils::read.csv(gap_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  expect_true(all(recent%in%gap$python_name))
  expect_true(all(gap$unresolved_source_gap))
  expect_identical(length(unique(gap$python_name)),nrow(gap))
})
