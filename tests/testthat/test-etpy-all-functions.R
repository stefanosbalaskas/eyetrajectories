test_that("all source Python callable exports have explicit R proxy functions", {
  cat <- etpy_catalog()
  expect_equal(nrow(cat), 380L)
  expect_equal(sum(cat$namespace == "root"), 362L)
  expect_equal(sum(cat$namespace == "workflows"), 18L)
  expect_equal(length(unique(cat$r_wrapper)), 380L)
  expect_true(all(cat$kind == "function"))
  for (name in cat$r_wrapper)
    expect_true(exists(name, mode = "function", inherits = FALSE,
                       envir = asNamespace("eyetrajectories")),
                info = name)
  all <- etpy_catalog(include_nonfunctions = TRUE)
  expect_equal(nrow(all), 508L)
  expect_equal(sum(all$namespace == "root"), 458L)
  expect_equal(sum(all$namespace == "workflows"), 50L)
  expect_equal(sum(all$kind == "other_export"), 128L)
  expect_error(etpy_catalog(NA), "include_nonfunctions")
  expect_error(etpy_verify_api(strict = NA), "strict")
  expect_error(etpy_get_export("invalid symbol"), "identifier")
})

test_that("actual installed Python exports are callable where declared", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("Full Python function verification is opt-in")
  live <- etpy_verify_api(strict = FALSE)
  expect_equal(nrow(live), 380L)
  failed <- live$python_name[!live$available | !live$callable]
  expect_length(failed, 0L, info = paste(utils::head(failed, 20L), collapse = ", "))
  expect_identical(unique(live$installed_python_version), "1.2.0")
  expect_true(reticulate::py_is_callable(etpy_get_export("fit_fpca")))
  expect_true(reticulate::py_is_callable(
    etpy_get_export("run_fpca_workflow", .namespace = "workflows")))
})
