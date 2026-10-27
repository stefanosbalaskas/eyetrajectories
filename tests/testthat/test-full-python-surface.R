test_that("full hybrid surface lazily exposes all 508 frozen symbols", {
  python_before <- reticulate::py_available(initialize=FALSE)
  surface <- etpy_full_surface()
  expect_s3_class(surface,"etpy_full_surface")
  expect_true(is.environment(surface$root))
  expect_true(is.environment(surface$workflows))
  expect_true(environmentIsLocked(surface$root))
  expect_true(environmentIsLocked(surface$workflows))
  expect_length(ls(surface$root,all.names=TRUE),458L)
  expect_length(ls(surface$workflows,all.names=TRUE),50L)
  expect_setequal(ls(surface$root,all.names=TRUE),
    etpy_catalog(include_nonfunctions=TRUE)$python_name[
      etpy_catalog(include_nonfunctions=TRUE)$namespace=="root"])
  expect_setequal(ls(surface$workflows,all.names=TRUE),
    etpy_catalog(include_nonfunctions=TRUE)$python_name[
      etpy_catalog(include_nonfunctions=TRUE)$namespace=="workflows"])
  expect_true(is.function(surface$root$fit_mfpca))
  expect_true(is.function(surface$workflows$run_fpca_workflow))
  expect_identical(reticulate::py_available(initialize=FALSE),python_before)
  expect_error(surface$root$fit_mfpca <- 3,
               "read-only|locked")
  expect_error(etpy_full_surface(.convert=NA),"must be TRUE or FALSE")
  expect_error(etpy_full_surface(.verify=NA),"must be TRUE or FALSE")
  expect_error(etpy_invoke("not a symbol"),"identifier")
  expect_error(etpy_attribute(list(),"bad"),"Python proxy")
  expect_error(etpy_method(list(),"invalid"),"Python proxy")
  expect_error(etpy_attribute(list(),"_hidden"),"public Python attributes")
})

test_that("all 508 public Python 1.2 exports can be resolved live", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Opt in to Python-backed exhaustive public export verification")
  inventory <- etpy_full_verify(strict=TRUE)
  expect_equal(nrow(inventory),508L)
  expect_equal(sum(inventory$kind=="function"),380L)
  expect_true(all(inventory$structurally_available))
  expect_true(all(inventory$version_qualified))
  expect_false(any(inventory$execution_tested))
  expect_false(any(inventory$numeric_parity_qualified))
  expect_true(all(inventory$installed_python_version=="1.2.0"))
  surface <- etpy_full_surface(.verify=TRUE)
  expect_length(ls(surface$root,all.names=TRUE),458L)
  expect_length(ls(surface$workflows,all.names=TRUE),50L)
  builtins <- reticulate::import_builtins(convert=FALSE)
  for (row in seq_len(nrow(inventory))) {
    ns <- inventory$namespace[row]
    name <- inventory$python_name[row]
    value <- if (ns=="root") surface$root[[name]] else
                               surface$workflows[[name]]
    callable <- reticulate::py_to_r(
      builtins$callable(etpy_get_export(name,.namespace=ns)))
    if (isTRUE(callable))
      expect_true(is.function(value),info=paste(ns,name))
    else
      expect_false(is.function(value),info=paste(ns,name))
  }
})

test_that("functional Python 1.2 workflows execute using R surface", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python runtime execution is opt-in")
  surface <- etpy_full_surface(.verify=TRUE)
  curves <- surface$root$simulate_planar_trajectories(
    n_participants=4L,trials_per_participant=2L,
    n_time=31L,random_state=2026L)
  expect_equal(as.integer(et_to_r(curves$n_curves)),8L)
  fit <- surface$root$fit_mfpca(curves,n_components=1L,
                                scaling="dimension_sd")
  from_surface <- surface$root$fpca_score_frame(fit,.convert=TRUE)
  from_wrapper <- etpy_fpca_score_frame(fit,.convert=TRUE)
  expect_s3_class(from_surface,"data.frame")
  expect_s3_class(from_wrapper,"data.frame")
  # reticulate attaches a pandas.index Python proxy to each conversion.
  # Independent conversions hold different external-pointer identities
  # even if the underlying Pandas index and scientific data are equal.
  # Assert R values, names, row identities and *index values*, not the
  # identity of reticulate's volatile Python index wrapper.
  left_index <- attr(from_surface,"pandas.index",exact=TRUE)
  right_index <- attr(from_wrapper,"pandas.index",exact=TRUE)
  expect_identical(is.null(left_index),is.null(right_index))
  if (!is.null(left_index)) {
    expect_equal(
      reticulate::py_to_r(left_index$tolist()),
      reticulate::py_to_r(right_index$tolist()))
  }
  attr(from_surface,"pandas.index") <- NULL
  attr(from_wrapper,"pandas.index") <- NULL
  expect_equal(from_surface,from_wrapper)
  expect_equal(nrow(from_surface),8L)
  config <- surface$workflows$FPCAWorkflowConfig(
    n_components=1L,scaling="dimension_sd")
  flow <- surface$workflows$run_fpca_workflow(
    curves,config=config)
  expect_true(reticulate::py_has_attr(flow,"fit"))
  expect_s3_class(
    surface$root$fpca_score_frame(
      etpy_attribute(flow,"fit"),.convert=TRUE),"data.frame")
  other <- etpy_invoke("FPCAWorkflowConfig",.namespace="workflows",
                       n_components=1L,scaling="dimension_sd")
  expect_true(reticulate::py_has_attr(other,"n_components"))
  signature <- etpy_signature("fit_mfpca")
  expect_type(signature,"character")
  expect_length(signature,1L)
  expect_false(is.na(signature))
})

test_that("Python result public attribute and method helper keep object identity", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python runtime execution is opt-in")
  builtins <- reticulate::import_builtins(convert=FALSE)
  item <- builtins$list(c(1L,2L))
  expect_true(inherits(item,"python.builtin.object"))
  expect_true(reticulate::py_has_attr(item,"append"))
  expect_true(reticulate::py_has_attr(item,"count"))
  etpy_method(item,"append",2L)
  expect_equal(as.integer(et_to_r(etpy_method(item,"count",2L))),2L)
  expect_error(etpy_method(item,"not_a_method"),
               "has no attribute")
  expect_error(etpy_method(item,"_private"),
               "public Python attributes")
  expect_error(etpy_invoke("WORKFLOW_SCHEMA_VERSION",
                           .namespace="workflows"),
               "not callable")
})


test_that("full Python reflection catalog covers 508 exported symbols", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Real Python runtime introspection is opt-in")
  runtime <- etpy_signature_catalog(strict=TRUE)
  expect_equal(nrow(runtime),508L)
  expect_true(all(runtime$structurally_available))
  expect_setequal(unique(runtime$runtime_kind),
                  intersect(c("callable","class","value"),
                            unique(runtime$runtime_kind)))
  expect_false(any(runtime$runtime_kind=="unknown"))
  expect_true(all(c("python_signature","python_module","runtime_kind") %in%
                  names(runtime)))
  m <- runtime[runtime$namespace=="root" &
               runtime$python_name=="fit_mfpca",,drop=FALSE]
  expect_equal(nrow(m),1L)
  expect_identical(m$runtime_kind,"callable")
  expect_false(is.na(m$python_signature))
  config <- runtime[runtime$namespace=="workflows" &
                    runtime$python_name=="FPCAWorkflowConfig",,
                    drop=FALSE]
  expect_equal(nrow(config),1L)
  expect_identical(config$runtime_kind,"class")
  expect_false(is.na(config$python_signature))
})
