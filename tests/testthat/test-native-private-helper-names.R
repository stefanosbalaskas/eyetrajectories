# The user-facing API and these internal scientific helpers are stage-free.
# Historical stage numbers in filenames, R test IDs and provenance catalogs
# are NOT public function identifiers and are intentionally retained.
test_that("cross-module native inference helpers use scientific names",{
  namespace <- asNamespace("eyetrajectories")
  obsolete <- c(".etr13_fos_result",".etr13_rng",".etr13_regularity",".etr13_histogram_mi",".etr14_fit",".etr14_boot",".etr14_scope",".etr14_block",".etr15_integer",".etr15_prob",".etr15_higher",".etr15_options",".etr15_target",".etr15_calibrate",".etr15_matrix",".etr16_states",".etr16_int",".etr16_key",".etr16_count",".etr16_hist",".etr16_data",".etr16_shifts",".etr16_roll",".etr16_frame",".etr17_integer",".etr17_curve",".etr17_embedding",".etr17_state",".etr17_lyapunov",".etr17_rqa_source",".etr18_fit",".etr18_psd",".etr18_cov",".etr18_aggregate")
  current <- c(".etr_function_scalar_result_check",".etr_simulation_rng",".etr_series_regular_spacing",".etr_histogram_mutual_information",".etr_fpca_stability_fit",".etr_fpca_stability_boot",".etr_fpca_stability_scope",".etr_fpca_stability_block",".etr_bootstrap_integer",".etr_bootstrap_probability",".etr_bootstrap_upper_tail",".etr_bootstrap_options",".etr_bootstrap_target",".etr_bootstrap_calibrate",".etr_bootstrap_matrix",".etr_transfer_states",".etr_transfer_integer",".etr_transfer_key",".etr_transfer_counts",".etr_transfer_history",".etr_transfer_data",".etr_transfer_shifts",".etr_transfer_roll",".etr_transfer_frame",".etr_nonlinear_integer",".etr_nonlinear_curve",".etr_nonlinear_embedding",".etr_nonlinear_state",".etr_nonlinear_lyapunov",".etr_rqa_inference_source",".etr_mixed_moments_fit",".etr_mixed_moments_psd",".etr_mixed_moments_cov",".etr_mixed_moments_aggregate")
  expect_true(all(vapply(current,function(x)
    exists(x,envir=namespace,inherits=FALSE) &&
      is.function(get(x,envir=namespace,inherits=FALSE)),
    logical(1L))))
  expect_false(any(vapply(obsolete,function(x)
    exists(x,envir=namespace,inherits=FALSE),logical(1L))))
  expect_false(any(grepl("stage[0-9]+|etr[0-9]+_",
    getNamespaceExports("eyetrajectories"),ignore.case=TRUE)))
})

test_that("all native package function names are stage-free",{
  namespace <- asNamespace("eyetrajectories")
  symbols <- ls(namespace,all.names=TRUE)
  functions <- symbols[vapply(symbols,function(name)
    is.function(get(name,envir=namespace,inherits=FALSE)),logical(1L))]
  expect_false(any(grepl("^\\.etr(?:s)?[0-9]+_",functions,perl=TRUE)))
  expect_false(any(grepl("stage[0-9]+",functions,ignore.case=TRUE)))
})

test_that("all parsed production and test calls use stage-free private symbols",{
  source_root <- normalizePath(file.path(testthat::test_path(),"..",".."),
    mustWork=TRUE)
  if(!dir.exists(file.path(source_root,"R")))
    skip("source files unavailable in installed-package tests")
  rfiles <- list.files(file.path(source_root,"R"),
    pattern="\\.R$",full.names=TRUE)
  tfiles <- list.files(file.path(source_root,"tests","testthat"),
    pattern="\\.R$",full.names=TRUE)
  all_symbols <- unique(unlist(lapply(c(rfiles,tfiles),function(path)
    all.names(parse(file=path),functions=TRUE,unique=TRUE)),
    use.names=FALSE))
  numeric_helper_refs <- grep("^\\.etr(?:s)?[0-9]+_",
    all_symbols,perl=TRUE,value=TRUE)
  expect_identical(numeric_helper_refs,character())
})

test_that("active native package and CI filenames are stage-free",{
  project_root <- normalizePath(file.path(testthat::test_path(),"..",".."),
    mustWork=TRUE)
  if (!dir.exists(file.path(project_root,"R")))
    skip("development checkout is unavailable")
  dirs <- file.path(project_root,c("R","tests/testthat","man",
    ".github/workflows"))
  names <- unlist(lapply(dirs[dir.exists(dirs)],function(x)
    basename(list.files(x,all.files=FALSE,recursive=TRUE))),
    use.names=FALSE)
  expect_false(any(grepl("stage[0-9]+",names,ignore.case=TRUE)))
})
