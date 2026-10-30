# A syntax regression in the evidence runner must be caught before
# users invoke a full native/Python qualification cycle.
test_that("native source qualification evidence runner parses", {
  runner <- testthat::test_path(
    "..", "..", "scripts",
    "capture_native_source_qualification_evidence.R"
  )
  expect_true(file.exists(runner))
  expect_silent(parse(file = runner, keep.source = FALSE))
  lines <- readLines(runner, warn = FALSE)
  expect_false(any(trimws(lines) == "else"))
  expect_true(any(grepl("if(isTRUE(results[[1L]]$success)) {",
    lines, fixed = TRUE)))
  expect_true(any(grepl("} else {", lines, fixed = TRUE)))
})

test_that("new scientific source oracles are included in both qualification modes",{
  root<-testthat::test_path("..","..")
  runner<-readLines(file.path(root,"scripts",
    "capture_native_source_qualification_evidence.R"),warn=FALSE)
  dossier<-readLines(file.path(root,"scripts",
    "build_inference_contract_dossier.R"),warn=FALSE)
  for(name in c("native-generalized-fosr-prediction",
    "native-generalized-fosr-bootstrap-source",
    "native-generalized-fosr-contrast-source",
    "native-mixed-model-source-text","native-source-environment")){
    expect_true(any(grepl(name,runner,fixed=TRUE)))
  }
  for(name in c("generalized_function_on_scalar_predict",
    "functional_mixed_effects_reporting_text",
    "bootstrap_generalized_function_on_scalar_predictions",
    "generalized_function_on_scalar_prediction_bands",
    "generalized_function_on_scalar_mean_difference_band")){
    expect_true(any(grepl(name,dossier,fixed=TRUE)))
  }
  expect_true(any(grepl("nrow(queue)==58L",runner,fixed=TRUE)))
})
