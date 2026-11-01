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
    'native_nonfunction_contract_review_v1.csv',
    'NATIVE_R_NONFUNCTION_REPRESENTATION_MISSING',
    'FULL_DOMAIN_SCIENTIFIC_AND_EXTERNAL_REVIEW_MISSING',
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

test_that("nonfunction native representations are not silently inferred",{
  reg<-utils::read.csv(testthat::test_path("..","..","inst",
    "extdata","native_nonfunction_contract_review_v1.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  expect_equal(nrow(reg),128L)
  expect_true(all(c("namespace","python_name",
    "native_representation")%in%names(reg)))
  expect_false(anyDuplicated(paste(reg$namespace,reg$python_name,sep="::"))>0L)
  # Blank native class mappings are unresolved scientific work, not
  # enough evidence to set any approval or claim 128 source classes.
  populated<-!is.na(reg$native_representation)&
    nzchar(trimws(reg$native_representation))
  expected<-c(
    "root::TrajectorySet"="etr_trajectory_set",
    "workflows::WORKFLOW_SCHEMA_VERSION"=
      "etr_frozen_workflow_values()$WORKFLOW_SCHEMA_VERSION",
    "workflows::WORKFLOW_BUNDLE_SCHEMA_VERSION"=
      "etr_frozen_workflow_values()$WORKFLOW_BUNDLE_SCHEMA_VERSION",
    "workflows::WORKFLOW_BUNDLE_FORMAT"=
      "etr_frozen_workflow_values()$WORKFLOW_BUNDLE_FORMAT")
  schema_names<-unique(etr_frozen_workflow_schema()$class_name)
  expected<-c(expected,setNames(
    paste0("etr_frozen_py12_",schema_names),
    paste0("workflows::",schema_names)))
  expect_equal(sum(populated),32L)
  observed<-setNames(reg$native_representation[populated],
    paste(reg$namespace[populated],reg$python_name[populated],sep="::"))
  expect_setequal(names(observed),names(expected))
  expect_identical(unname(observed[names(expected)]),unname(expected))
  expect_true(all(reg$evidence_state[populated]=="not_reviewed"))
  expect_true(all(!reg$numerical_or_value_approved))
  expect_true(all(!reg$schema_boundary_approved))
  expect_true(all(!reg$scientific_scope_approved))
  expect_true(all(!reg$independent_reviewer_approved))
})
