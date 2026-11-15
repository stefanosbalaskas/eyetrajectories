test_that("all 508 published exports receive a fail-closed evidence queue",{
  api<-etr_native_parity_catalog()
  readiness<-etr_native_certification_readiness_frame()
  expect_identical(nrow(readiness),508L)
  expect_identical(nrow(etr_native_certification_readiness_frame(
    include_nonfunctions=FALSE)),380L)
  expect_identical(nrow(etr_native_certification_readiness_frame(
    only_unapproved=TRUE)),508L)
  expect_identical(readiness$python_name,api$python_name)
  expect_identical(readiness$kind,api$kind)
  expect_identical(readiness$fully_certified,
    api$one_to_one_native_contract_complete)
  expect_gte(sum(readiness$native_mapping_present[
    api$is_python_function]),332L)
  expect_gte(sum(readiness$native_implementation_started[
    api$is_python_function]),307L)
  # Active source flags can be closed by bounded author-side review,
  # but this must NEVER elevate independent full-contract certification.
  callable<-utils::read.csv(.etr_test_extdata(
    "native_source_contract_gaps_stage22.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  other<-utils::read.csv(.etr_test_extdata(
    "native_nonfunction_source_gaps_v1.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  expect_identical(nrow(callable),203L)
  expect_identical(nrow(other),1L)
  expect_identical(sum(readiness$published_source_difference_open),
    sum(callable$unresolved_source_gap))
  expect_identical(sum(readiness$nonfunction_source_difference_open),
    sum(other$unresolved))
  class_gap<-readiness[readiness$python_name=="TrajectorySet",,drop=FALSE]
  expect_identical(nrow(class_gap),1L)
  expect_identical(class_gap$nonfunction_source_difference_open,
    other$unresolved)
  expect_identical(class_gap$first_unresolved_requirement,
    if(other$unresolved)
      "unresolved_nonfunction_source_difference"
    else "approved_numerical_oracle_missing")
  expect_false(class_gap$fully_certified)
  expect_equal(sum(readiness$fully_certified),0L)
  expect_true(all(nzchar(readiness$first_unresolved_requirement)))
  expect_true(all(nzchar(readiness$all_unresolved_requirements)))
  mapped<-readiness[readiness$python_name%in%
    c("plot_fpca_regression_cv","plot_nested_fpca_regression_cv",
      "plot_functional_mixed_effects_bootstrap_comparison",
      "plot_fpca_wild_bootstrap_truncation_scan"),,drop=FALSE]
  expect_identical(nrow(mapped),4L)
  expect_true(all(mapped$native_mapping_present))
  expect_true(all(mapped$native_implementation_started))
  mapped_expected<-callable$unresolved_source_gap[
    match(mapped$python_name,callable$python_name)]
  expect_false(anyNA(mapped_expected))
  expect_identical(mapped$published_source_difference_open,
    mapped_expected)
  expect_true(all(mapped$first_unresolved_requirement==
    ifelse(mapped_expected,"unresolved_published_source_difference",
      "approved_numerical_oracle_missing")))
  expect_true(all(grepl("independent_review_approval_missing",
    mapped$all_unresolved_requirements,fixed=TRUE)))
  # Every frozen Python function now has a real exported native R
  # analogue. This is 100% *mapping* coverage, NOT source parity.
  # A previous test required an unmapped function and became invalid
  # when the native source mapping census reached 380/380.
  functions<-readiness[readiness$kind=="function",,drop=FALSE]
  expect_identical(nrow(functions),380L)
  expect_true(all(functions$native_mapping_present))
  # A previously omitted implementation marker blocked 111-row source
  # evidence capture despite the exported native quadrature implementation.
  weights<-functions[functions$python_name=="functional_trapezoid_weights",
    ,drop=FALSE]
  expect_identical(nrow(weights),1L)
  expect_true(weights$native_implementation_started)
  # First author-reviewed source-semantic closure; independent
  # numerical replay and reviewer certification remain unsigned.
  expect_false(weights$published_source_difference_open)
  expect_false(weights$fully_certified)
  # Implemented vs mapped are separate tracked states. If any
  # mapped candidate has not started implementation, retain its
  # explicit unresolved requirement instead of fabricating progress.
  unstarted<-functions[!functions$native_implementation_started,,drop=FALSE]
  if(nrow(unstarted)){
    expect_true(all(unstarted$first_unresolved_requirement==
      "native_implementation_missing"))
    expect_true(all(grepl("native_implementation_missing",
      unstarted$all_unresolved_requirements,fixed=TRUE)))
  }
  expect_true(all(nzchar(functions$native_r_candidate)))
  expect_true(all(functions$native_r_candidate%in%
    getNamespaceExports("eyetrajectories")))
  missing<-functions[!functions$native_mapping_present,,drop=FALSE]
  expect_identical(nrow(missing),0L)
  expect_false(any(grepl("native_mapping_missing",
    functions$all_unresolved_requirements,fixed=TRUE)))
  # Mapping completion must never elevate scientific source contracts:
  # retain all unsigned source, numeric, schema, and independent-review
  # gates, including the 128 nonfunction exports.
  expect_identical(sum(readiness$fully_certified),0L)
  # A full-source certificate is impossible for explicitly declared
  # native method/backend alternatives until the source algorithm and its
  # input/output domain are independently reviewed and implemented.
  alternatives<-readiness[readiness$native_backend_or_estimand_differs,,drop=FALSE]
  expect_gte(nrow(alternatives),19L)
  expect_true(all(alternatives$native_mapping_present))
  expect_false(any(alternatives$fully_certified))
  expect_true(all(grepl("native_backend_or_estimand_not_source_equivalent",
    alternatives$all_unresolved_requirements,fixed=TRUE)))

  expect_true(all(grepl("independent_review_approval_missing",
    readiness$all_unresolved_requirements,fixed=TRUE)))
  expect_true(all(grepl("approved_numerical_oracle_missing",
    readiness$all_unresolved_requirements,fixed=TRUE)))
  # A newly implemented source subset must remain blocked for scientific
  # source-domain and independently approved contract gaps.
  simulated<-readiness[readiness$python_name==
    "simulate_functional_process",,drop=FALSE]
  expect_identical(nrow(simulated),1L)
  expect_true(simulated$native_mapping_present)
  expect_true(simulated$native_implementation_started)
  sim_open<-callable$unresolved_source_gap[
    match(simulated$python_name,callable$python_name)]
  expect_identical(simulated$published_source_difference_open,sim_open)
  expect_identical(simulated$first_unresolved_requirement,
    if(sim_open)"unresolved_published_source_difference"
    else "approved_numerical_oracle_missing")
  expect_false(simulated$fully_certified)
  expect_true(grepl("independent_review_approval_missing",
    simulated$all_unresolved_requirements,fixed=TRUE))
  expect_true(any(readiness$kind!="function"))
})

test_that("source certification readiness rejects malformed controls",{
  expect_error(etr_native_certification_readiness_frame(
    include_nonfunctions=NA),"include_nonfunctions")
  expect_error(etr_native_certification_readiness_frame(
    only_unapproved=1L),"only_unapproved")
  expect_error(etr_native_certification_readiness_frame(
    include_nonfunctions=c(TRUE,FALSE)),"include_nonfunctions")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
