test_that("public bridge validates names before importing Python", {
  expect_error(et_call("_private"), "single public Python identifier")
  expect_error(et_call("bad-name"), "single public Python identifier")
  expect_error(et_call(character()), "single public Python identifier")
  expect_error(et_call("fit_fpca", .convert = NA), ".convert must")
  expect_error(et_call("fit_fpca", .namespace = "not-a-namespace"), "arg")
})

test_that("long data frame failures are local and informative", {
  x <- data.frame(time = 0:2, x = 1:3, y = 3:1)
  expect_error(et_from_long(x, curve_columns = "participant_id"), "Missing columns")
  expect_error(et_from_long(matrix(1:4, 2L), curve_columns = "participant_id"),
               "data must be an R data.frame")
  expect_error(et_from_long(x, curve_columns = character()),
               "curve_columns must")
  expect_error(et_from_long(x, curve_columns = "x", value_columns = c("x", "")),
               "value_columns must")
})

test_that("argument validation does not need an initialized Python runtime", {
  expect_error(et_explained_variance(NULL, cumulative = NA), "cumulative must")
  expect_error(et_save_plot(NULL, ""), "file must be")
})
