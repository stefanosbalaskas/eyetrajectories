# Fast, Python-free PR source preflight. These tests are developer-side
# safeguards, not numerical parity or independent certification evidence.

test_that("scientific PR gate detects reticulate py_call callable shadowing",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  helper<-new.env(parent=globalenv())
  withr::with_envvar(
    c(ET_SCIENTIFIC_PREFLIGHT_DEFINITIONS_ONLY="true"),
    sys.source(file.path(root,"scripts","preflight_scientific_pr.R"),
      envir=helper)
  )
  bad<-parse(text="reticulate::py_call(oracle, x=py_values, ref=0L)")
  good<-parse(text="reticulate::py_call(oracle, array_data=py_values, ref=0L)")
  nested<-parse(text=paste0("check(reticulate::py_call(oracle,",
    " x=py_values, ref=0L))"))
  expect_identical(helper$.etr_fast_pycall_x_sites(bad),1L)
  expect_identical(helper$.etr_fast_pycall_x_sites(good),0L)
  expect_identical(helper$.etr_fast_pycall_x_sites(nested),1L)
  expect_identical(helper$.etr_fast_pycall_x_sites(
    parse(text="reticulate::py_call(oracle, value=5, x=2)")),1L)
  # Missing AST arguments occur in ordinary source such as matrix[, 1L].
  # The walker must not bind R_MissingArg to a for-loop variable.
  expect_identical(helper$.etr_fast_pycall_x_sites(
    parse(text="z <- measurements[, 1L]")),0L)
  expect_identical(helper$.etr_fast_pycall_x_sites(
    parse(text="reticulate::py_call(oracle, measurements[, 1L], ref=0L)")),0L)
  expect_identical(helper$.etr_fast_pycall_x_sites(
    parse(text="check(fn(, 4L), reticulate::py_call(oracle, x=values))")),1L)
})

test_that("scientific PR gate detects nonexistent complex setters",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  helper<-new.env(parent=globalenv())
  withr::with_envvar(
    c(ET_SCIENTIFIC_PREFLIGHT_DEFINITIONS_ONLY="true"),
    sys.source(file.path(root,"scripts","preflight_scientific_pr.R"),
      envir=helper)
  )
  cases<-c("Im(z) <- c(1,2)","Re(x)<-0",
    "w <- complex(real=1,imaginary=2)",
    "# Im(z) <- 0")
  expect_identical(helper$.etr_fast_complex_setter_sites(cases),c(1L,2L))
})

test_that("fast scientific gate precedes source qualification and CRAN staging",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  path<-file.path(root,"scripts","preflight_scientific_pr.R")
  expect_true(file.exists(path))
  r_source<-readLines(file.path(root,"scripts",
    "capture_native_source_qualification_evidence.R"),warn=FALSE)
  r_stage<-readLines(file.path(root,"scripts",
    "stage_local_release_candidate.R"),warn=FALSE)
  guard<-'source("scripts/preflight_scientific_pr.R", local = TRUE)'
  expect_true(any(grepl(guard,r_source,fixed=TRUE)))
  expect_true(any(grepl(guard,r_stage,fixed=TRUE)))
  expect_true(which(grepl(guard,r_source,fixed=TRUE))[1L] <
    which(grepl('pkgload::load_all(',r_source,fixed=TRUE))[1L])
  expect_true(which(grepl(guard,r_stage,fixed=TRUE))[1L] <
    which(grepl('exit_code <- system2(',r_stage,fixed=TRUE))[1L])
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
