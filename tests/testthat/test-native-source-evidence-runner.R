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
