# Developer-side first-wave signature inventory guard. Source signature
# strings provide hints to reviewers, never proof of Python/R equivalence.
test_that("first-wave signature inventory is source-pinned and never approving",{
  root<-testthat::test_path("..","..")
  file<-file.path(root,"scripts",
    "capture_first_wave_source_interfaces.R")
  expect_true(file.exists(file))
  expect_silent(parse(file=file,keep.source=FALSE))
  env<-new.env(parent=globalenv())
  sys.source(file,envir=env)
  expect_true(is.function(
    env$etr_capture_first_wave_source_interfaces))
  code<-paste(readLines(file,warn=FALSE),collapse="\n")
  for(token in c("etpy_get_export(name,.namespace=ns_name)",
    'reticulate::import("inspect"',
    'get0(native_name,envir=ns,inherits=FALSE,mode="function")',
    'source_full_domain_certified=FALSE',
    'independently_reproduced=FALSE',
    'signature_text_is_not_semantic_parity=TRUE',
    'first_wave_source_interface_inventory_sha256.csv')){
    expect_true(grepl(token,code,fixed=TRUE),
      info=paste("Missing source-interface audit gate",token))
  }
  expect_false(grepl("source_full_domain_certified=TRUE",code,fixed=TRUE))
  expect_false(grepl("independently_reproduced=TRUE",code,fixed=TRUE))
  expect_true(all(!etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

# The source API contains two module namespaces. These three objects are
# catalogued ONLY under workflows, not under root. Live frozen-source
# lookups require the opt-in pinned Python 1.2 environment.
test_that("workflows exports are inspected in their recorded namespace",{
  names<-c("PreprocessingPlan","FPCAWorkflowConfig",
    "FPCAWorkflowResult")
  catalog<-etpy_catalog(include_nonfunctions=TRUE)
  for(nm in names){
    rows<-catalog[catalog$python_name==nm,,drop=FALSE]
    expect_equal(nrow(rows),1L)
    expect_identical(rows$namespace,"workflows")
    expect_identical(rows$kind,"other_export")
  }
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 workflows namespace oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  for(nm in names){
    obj<-etpy_get_export(nm,.namespace="workflows")
    expect_true(reticulate::py_has_attr(obj,"__class__"))
    expect_error(etpy_get_export(nm,.namespace="root"),
      "not in installed public exports")
  }
})
