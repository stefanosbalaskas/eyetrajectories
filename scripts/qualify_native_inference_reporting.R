# Execute at the eyetrajectories repository root in RStudio:
# source("scripts/qualify_native_inference_reporting.R")
# This script runs the native R evidence suite and then the pinned published
# eyetrajectoriespy 1.2.0 direct-source oracle. It never promotes certification.
stopifnot(file.exists("DESCRIPTION"))
pkgload::load_all(".",quiet=TRUE)
testthat::set_max_fails(Inf)

qualifying_filter <- paste(
  "native-inference-reporting",
  "native-scientific-source-frames",
  "native-source-text-inference",
  "native-source-model-reports",
  "native-source-diagnostic-frames",
  "native-certification-readiness",
  "native-private-helper-names",
  "native-source-evidence-runner",
  "native-sparse-scientific-graphics",
  "native-generalized-mixed-source-graphics",
  "native-mixed-residual-comparison",
  "native-fpca-inference-source-graphics",
  "native-wild-monte-carlo-source-contracts",
  "native-wild-simultaneous-source-calibration",
  "native-source-contract-gaps",
  "full-native-r-parity-ledger",
  sep="|"
)

Sys.unsetenv("ET_RUN_PYTHON_TESTS")
cat("\n=== Native R offline scientific reporting qualification ===\n")
testthat::test_local(".",filter=qualifying_filter,reporter="summary",stop_on_failure=TRUE)
invisible(stopifnot(sum(etr_native_parity_catalog()$
  one_to_one_native_contract_complete)==0L))

cat("\n=== Pinned published Python 1.2.0 direct-source oracle ===\n")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter=qualifying_filter,reporter="summary",stop_on_failure=TRUE),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS")
)
cat("\nQualification suites finished. This does NOT sign off full contracts.\n")
