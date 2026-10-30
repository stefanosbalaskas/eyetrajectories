# Evidence hand-off for independent full source-contract review.
# Run from package root after refreshing PR #46:
# source("scripts/build_inference_contract_dossier.R")
# This creates an explicit READ-ONLY review queue. It does not approve a
# contract, alter the authoritative 508-export register, or initialize Python.
stopifnot(file.exists("DESCRIPTION"))
pkgload::load_all(".",quiet=TRUE)
api<-etr_native_parity_catalog()
readiness<-etr_native_certification_readiness_frame()
source_names<-c(
  "fpca_wild_bootstrap_projection_reporting_text",
  "fpca_regression_future_prediction_reporting_text",
  "fpca_regression_uncertainty_reporting_text",
  "fpca_regression_slope_band_reporting_text",
  "fpca_nested_regression_cv_reporting_text",
  "fpca_wild_bootstrap_family_test_reporting_text",
  "fpca_wild_bootstrap_monte_carlo_reporting_text",
  "fpca_wild_bootstrap_simultaneous_reporting_text",
  "fpca_regression_cv_reporting_text",
  "fpca_component_envelope_reporting_text",
  "fpca_wild_bootstrap_truncation_reporting_text"
)
stopifnot(length(source_names)==11L,!anyDuplicated(source_names))
idx<-match(source_names,readiness$python_name)
stopifnot(!anyNA(idx),all(readiness$kind[idx]=="function"),
  all(readiness$native_mapping_present[idx]),
  all(readiness$native_implementation_started[idx]),
  all(readiness$published_source_difference_open[idx]),
  !any(readiness$fully_certified[idx]))
source_idx<-match(source_names,api$python_name)
stopifnot(!anyNA(source_idx),all(api$source_git_sha[source_idx]==
  "7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed"),
  !any(api$one_to_one_native_contract_complete[source_idx]))
source_test<-ifelse(source_names %in%
  source_names[seq_len(8L)],
  "tests/testthat/test-native-inference-reporting.R",
  "tests/testthat/test-native-inference-reporting-extensions.R")
stopifnot(all(file.exists(source_test)))
data<-data.frame(
  python_name=source_names,
  native_r_function=readiness$native_r_candidate[idx],
  python_release="1.2.0",
  source_commit="c1cd95ad718327550f7e55393ff38582872f7a94",
  source_file="src/eyetrajectoriespy/reporting.py",
  oracle_test=source_test,
  mapped=readiness$native_mapping_present[idx],
  native_implementation_started=readiness$native_implementation_started[idx],
  source_difference_open=readiness$published_source_difference_open[idx],
  exact_text_fixture_test_state="requires_local_execution_and_artifact",
  accepted_input_domain_review="not_approved",
  output_and_error_schema_review="not_approved",
  numerical_text_oracle_review="not_approved",
  scientific_scope_review="not_approved",
  independent_reviewer_signoff="not_approved",
  fully_certified=readiness$fully_certified[idx],
  missing_evidence=readiness$all_unresolved_requirements[idx],
  stringsAsFactors=FALSE
)
stopifnot(nrow(data)==11L,!any(data$fully_certified))
output_dir<-file.path("artifacts","native_inference_contract_review")
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
output<-file.path(output_dir,"python_1_2_reporting_contract_review_queue.csv")
utils::write.csv(data,output,row.names=FALSE,na="")
message("Wrote unsigned source-contract review queue: ",
  normalizePath(output,winslash="/",mustWork=TRUE))
message("All 11 contracts remain uncertified pending full-domain and independent review.")
