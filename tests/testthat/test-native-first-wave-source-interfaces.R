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
  for(token in c("etpy_get_export(name)",
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
