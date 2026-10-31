test_that("static Python source-fixture inventory ignores missing R call arguments",{
  helper<-testthat::test_path("..","..","scripts",
    "source_fixture_static_attribution.R")
  expect_true(file.exists(helper))
  expect_silent(parse(file=helper,keep.source=FALSE))
  env<-new.env(parent=baseenv())
  sys.source(helper,envir=env)
  fixture<-tempfile(fileext=".R")
  on.exit(unlink(fixture),add=TRUE)
  writeLines(c(
    "test_that('index holes', {",
    "  x <- matrix(1:9, 3L, 3L)",
    "  first <- x[, 1L]",
    "  last <- x[1L, ]",
    "  out <- etpy_get_export('alr_transform')",
    "  # etpy_get_export('comment_only')",
    "  literal <- 'etpy_get_export(\\\"not_a_call\\\")'",
    "})",
    "testthat::test_that('second case', {",
    "  z <- etpy_get_export(\\"score_distance_matrix\\")",
    "})"
  ),fixture,useBytes=TRUE)
  inventory<-env$etr_source_fixture_static_inventory(fixture)
  expect_identical(inventory$cases,2L)
  expect_setequal(inventory$export_literals,
    c("alr_transform","score_distance_matrix"))
  expect_false("comment_only" %in% inventory$export_literals)
  expect_false("not_a_call" %in% inventory$export_literals)
})

test_that("static inventory stays noncertifying and never executes source fixtures",{
  helper<-testthat::test_path("..","..","scripts",
    "source_fixture_static_attribution.R")
  env<-new.env(parent=baseenv())
  sys.source(helper,envir=env)
  marker<-tempfile()
  fixture<-tempfile(fileext=".R")
  on.exit(unlink(c(marker,fixture)),add=TRUE)
  writeLines(c("test_that('parse only', {",
    paste0("  writeLines('executed', '",gsub("\\\\","/",marker),"')"),
    "  etpy_get_export('inverse_alr')",
    "})"),fixture,useBytes=TRUE)
  inventory<-env$etr_source_fixture_static_inventory(fixture)
  expect_identical(inventory$cases,1L)
  expect_true("inverse_alr" %in% inventory$export_literals)
  expect_false(file.exists(marker))
  expect_error(env$etr_source_fixture_static_inventory(
    paste0(fixture,".missing")),"Missing source fixture")
})
