# Author-side source replay; no developer gap closure or independent certification.
if(!file.exists("DESCRIPTION")||!dir.exists("tests/testthat"))
  stop("Run at eyetrajectories R package root",call.=FALSE)
for(pkg in c("pkgload","reticulate","jsonlite","digest","testthat","withr"))
  if(!requireNamespace(pkg,quietly=TRUE))
    stop("Missing source replay dependency: ",pkg,call.=FALSE)
pkgload::load_all(".",quiet=TRUE)
if(!identical(et_python_version(),"1.2.0"))
  stop("Require frozen eyetrajectoriespy==1.2.0",call.=FALSE)
# Testthat raises errors on any numeric, JSON, text or schema disagreement.
withr::with_envvar(c(ET_RUN_PYTHON_TESTS="true"),{
  testthat::test_local(".",filter="native-python-json-reporting-batch28",
    reporter="summary",stop_on_failure=TRUE,stop_on_warning=TRUE)
})
checks<-c("workflow_config_to_dict","workflow_steps_frame","workflow_decisions_frame",
  "workflow_summary_frame","workflow_reporting_text",
  "functional_simulation_scenario_frame",
  "functional_recovery_scenario_catalog_frame")
source_files<-c("R/native-python-json-contracts.R",
  "R/native-workflow-source-audit.R",
  "R/native-workflow-configuration.R",
  "R/native-functional-scenario-design.R",
  "tests/testthat/test-native-python-json-reporting-batch28.R",
  "scripts/capture_reporting_contract_evidence_batch28.R")
stopifnot(all(file.exists(source_files)))
digests<-vapply(source_files,function(x)digest::digest(x,algo="sha256",
  file=TRUE,serialize=FALSE),character(1L))
evidence<-list(
  protocol="native_reporting_source_replay_batch28_v1",
  python_version="1.2.0",
  frozen_python_commit="c1cd95ad718327550f7e55393ff38582872f7a94",
  functions_tested=checks,
  workflow_fixture_count=6L,
  scenario_replicate_regimes=c(1L,3L,7L),
  all_python_source_field_comparisons_passed=TRUE,
  source_input_runtime_representation_identical=FALSE,
  all_possible_python_input_and_error_domains_certified=FALSE,
  developer_full_contract_closures_granted=0L,
  independent_certifications_granted=0L,
  local_sha256=as.list(digests))
out<-"artifacts/native_full_contract_evidence/reporting_batch28_source_replay.json"
dir.create(dirname(out),recursive=TRUE,showWarnings=FALSE)
jsonlite::write_json(evidence,out,pretty=TRUE,auto_unbox=TRUE,null="null")
cat("BATCH28_REPORTING_SOURCE_REPLAY_PASS=",length(checks),
  ";NO_NEW_CLOSURES;INDEPENDENT=0\n",sep="")
cat("BATCH28_EVIDENCE_FILE=",out,"\n",sep="")
