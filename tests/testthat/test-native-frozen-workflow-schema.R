# Entire source-backed 28-class / 303-field native R schema batch.
# Frozen Python 1.2 source commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native records are useful field-ordered containers, NOT Python dataclasses
# and NOT scientific estimators or independent full-domain certificates.
test_that("28 frozen Python workflow schema manifest is complete and ordered",{
  schema<-etr_frozen_workflow_schema()
  expect_identical(nrow(schema),303L)
  expect_identical(length(unique(schema$class_name)),28L)
  expect_true(all(schema$namespace=="workflows"))
  expect_true(all(schema$frozen_python_commit==
    "c1cd95ad718327550f7e55393ff38582872f7a94"))
  expect_false(anyDuplicated(paste(schema$class_name,
    schema$field_name,sep="::"))>0L)
  for(class_name in unique(schema$class_name)){
    z<-etr_frozen_workflow_schema(class_name)
    expect_identical(z$field_order,seq_len(nrow(z)))
    expect_true(all(!z$required | z$python_default_expression==""))
    expect_true(all(z$required | nzchar(z$python_default_expression)))
    expect_true(all(nzchar(z$annotation)))
  }
  expect_error(etr_frozen_workflow_schema("ArbitraryObject"),
    "unknown frozen Python")
})

test_that("all 28 native workflow schema records preserve exactly ordered source fields",{
  all<-etr_frozen_workflow_schema()
  for(name in unique(all$class_name)){
    z<-etr_frozen_workflow_schema(name)
    values<-setNames(rep(list(NULL),nrow(z)),z$field_name)
    if(grepl("WorkflowResult$",name)){
      values$workflow_schema_version<-1L
      values$workflow_contract<-"schema_only_not_a_fit:v1"
      for(field in c("steps","decisions","provenance","reports","tables"))
        values[[field]]<-list()
    }
    record<-etr_frozen_workflow_record(name,
      values[rev(names(values))])
    expect_s3_class(record,paste0("etr_frozen_py12_",name))
    expect_identical(names(record),z$field_name)
    expect_identical(attr(record,"frozen_python_class"),name)
    expect_false(attr(record,"source_scientific_parity_certified"))
    expect_false(attr(record,"independent_full_domain_certification"))
    expect_true(attr(record,"complete_source_field_names"))
    if(length(values)){
      expect_error(etr_frozen_workflow_record(name,values[-1L]),
        "requires all exact frozen Python fields")
    }
  }
  expect_error(etr_frozen_workflow_record("PreprocessingPlan",
    list(steps=list(),steps=list())),"uniquely named")
  expect_error(etr_frozen_workflow_record("PreprocessingPlan",
    list(other=list())),"requires all exact frozen Python fields")
  expect_error(etr_frozen_workflow_record("FPCAWorkflowResult",
    setNames(rep(list(NULL),9L),
      etr_frozen_workflow_schema("FPCAWorkflowResult")$field_name)),
    "valid schema version")
})

test_that("existing native FPCA workflow returns source-field-ordered R view",{
  times<-seq(0,1,length.out=5L)
  values<-array(0,c(6L,length(times),1L))
  for(i in seq_len(6L))
    values[i,,1L]<-sin(2*pi*times+i/10)+i/15
  trajectories<-etr_trajectory_set(times,values,
    curve_ids=paste0("c",seq_len(6L)),dimension_names="x")
  result<-etr_run_fpca_workflow(trajectories,
    config=list(n_components=1L))
  expected<-etr_frozen_workflow_schema("FPCAWorkflowResult")$field_name
  view<-etr_native_workflow_result_view(result)
  expect_s3_class(view,"etr_frozen_py12_FPCAWorkflowResult")
  expect_identical(names(view),expected)
  expect_identical(view$fit$result_version,NULL)
  expect_identical(view$workflow_contract,"fpca:v1")
  expect_equal(view$fit$scores,result$fit$scores,tolerance=0)
  expect_false(attr(view,"source_scientific_parity_certified"))
  expect_error(etr_native_workflow_result_view(trajectories),
    "no native workflow result-view adapter")
})

test_that("source module fields match all 28 pinned Python 1.2 dataclasses",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 dataclass fields oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  dataclasses<-reticulate::import("dataclasses",convert=FALSE)
  manifest<-etr_frozen_workflow_schema()
  for(name in unique(manifest$class_name)){
    pyclass<-etpy_get_export(name,.namespace="workflows")
    expect_true(reticulate::py_to_r(dataclasses$is_dataclass(pyclass)))
    pyfields<-reticulate::iterate(dataclasses$fields(pyclass),
      function(field)reticulate::py_to_r(field$name))
    expected<-etr_frozen_workflow_schema(name)$field_name
    expect_identical(unname(as.character(unlist(pyfields))),expected,
      info=paste("frozen Python dataclass fields",name))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
