# Dense FPCA workflow mapping to the frozen Python 1.2 bundle schema.
.etr_write_python_workflow_csv <- function(table,path) {
  for(i in seq_along(table)) {
    column <- table[[i]]
    if(is.logical(column)) table[[i]] <- ifelse(column,"True","False")
    else if(is.character(column)) table[[i]] <- enc2utf8(column)
  }
  # Windows text-mode CSV writes can turn embedded LF in a quoted warnings
  # field into CRLF. Python's pandas round-trip preserves the original LF.
  # A binary UTF-8 connection retains literal scientific text in the CSV.
  con <- file(path,open="wb")
  on.exit(close(con),add=TRUE)
  utils::write.csv(table,con,row.names=FALSE,na="")
}

.etr_portable_writer_fpca_workflow <- function(result, config, add_array) {
  dense_module <- "eyetrajectoriespy.workflows._dense_regression"
  core_module <- "eyetrajectoriespy.workflows._core"
  encode <- function(x) .etr_portable_writer_json(x,add_array=add_array)
  encode_mapping <- function(x) .etr_portable_writer_mapping(lapply(x,encode))
  config$preprocessing <- .etr_portable_writer_record("PreprocessingPlan",
    list(steps=.etr_portable_writer_tuple(list())),core_module)
  steps <- lapply(result$steps,function(step){
    .etr_portable_writer_record("WorkflowStepRecord",list(
      name=as.character(step$name),`function`=as.character(step[["function"]]),
      status=as.character(step$status),
      parameters=encode_mapping(step$parameters),
      elapsed_seconds=as.numeric(step$elapsed_seconds),
      warnings=.etr_portable_writer_tuple(step$warnings)),core_module)
  })
  decisions <- lapply(result$decisions,function(decision){
    .etr_portable_writer_record("WorkflowDecisionRecord",list(
      value=encode(decision$value),source=as.character(decision$source),
      criterion=if(is.null(decision$criterion))NULL else as.character(decision$criterion)),core_module)
  })
  tables <- lapply(result$tables,function(table){
    index <- rownames(table)
    if(identical(index,as.character(seq_len(nrow(table)))))
      index <- seq_len(nrow(table))-1L
    .etr_portable_writer_dataframe(table,index,add_array)
  })
  .etr_portable_writer_record("FPCAWorkflowResult",list(
    workflow_schema_version=result$workflow_schema_version,
    workflow_contract=result$workflow_contract,
    config=.etr_portable_writer_record("FPCAWorkflowConfig",config,dense_module),
    fit=.etr_portable_writer_fpca(result$fit,add_array),
    steps=.etr_portable_writer_tuple(steps),
    decisions=.etr_portable_writer_mapping(decisions),
    provenance=encode_mapping(result$provenance),
    reports=encode_mapping(result$reports),
    tables=.etr_portable_writer_mapping(tables)),dense_module)
}

.etr_export_python_fpca_workflow_bundle <- function(result,directory) {
  .etr_assert(inherits(result,"etr_fpca_workflow")&&
    identical(result$workflow_contract,"fpca:v1"),
    "Python 1.2 bundle format supports native dense FPCA workflows")
  .etr_portable_require("zip")
  fields <- c("n_components","scaling","preprocessing")
  .etr_workflow_named_fields(result$config,"config")
  .etr_assert(setequal(names(result$config),fields)&&
    is.list(result$config$preprocessing)&&length(result$config$preprocessing)==0L,
    "Python 1.2 FPCA bundle requires declared config and empty preprocessing")
  declared <- etr_frozen_fpca_workflow_config(result$config$n_components,
    result$config$scaling)
  config <- list(n_components=declared$n_components,scaling=declared$scaling,
    preprocessing=list(steps=list()))
  .etr_assert(length(result$steps)>0L&&all(vapply(result$steps,function(step)
    is.list(step)&&!is.null(step$elapsed_seconds),logical(1L))),
    "Python 1.2 FPCA bundles require elapsed times from measure_time = TRUE")
  steps <- etr_workflow_steps_frame(result$steps)
  decisions <- etr_workflow_decisions_frame(result$decisions)
  .etr_workflow_named_fields(result$provenance,"provenance")
  .etr_native_bundle_validate_artifacts(result)

  temp <- .etr_native_bundle_temp_dir(directory)
  on.exit(unlink(temp,recursive=TRUE),add=TRUE)
  write_json <- function(value,name) .etr_native_bundle_write_text(
    .etr_workflow_json(value,name,empty_mapping=TRUE),file.path(temp,name))
  write_json(config,"config.json")
  write_json(result$provenance,"provenance.json")
  environment <- list(schema_version=1L,runtime="R",
    captured_at_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%OS6+00:00",tz="UTC"),
    package=list(name="eyetrajectories",version=as.character(getNamespaceVersion("eyetrajectories"))),
    r=list(version=as.character(getRversion()),platform=R.version$platform),
    python=NULL)
  write_json(environment,"environment.json")
  # Preserve the measured double through both the audit CSV and JSON snapshot.
  steps$elapsed_seconds <- vapply(steps$elapsed_seconds,.etr_python_json_float,character(1L))
  .etr_write_python_workflow_csv(steps,file.path(temp,"steps.csv"))
  .etr_write_python_workflow_csv(decisions,file.path(temp,"decisions.csv"))
  portable_dir <- .etr_write_python_portable_result(file.path(temp,"result"),
    function(add_array) .etr_portable_writer_fpca_workflow(result,config,add_array),
    encode_manifest=.etr_python_json_encode)
  portable <- jsonlite::fromJSON(file.path(portable_dir,"manifest.json"))
  artifacts <- .etr_native_bundle_write_artifacts(result,temp,portable=TRUE)
  frozen <- etr_frozen_workflow_values()
  write_json(list(schema_version=frozen$WORKFLOW_BUNDLE_SCHEMA_VERSION,
    format=frozen$WORKFLOW_BUNDLE_FORMAT,
    workflow_schema_version=result$workflow_schema_version,
    workflow_contract=result$workflow_contract,result_type=portable$result_type,
    portable_result_directory="result",reports=as.list(artifacts$reports),
    tables=as.list(artifacts$tables),figure_export_included=FALSE,
    figure_export_status="deferred_to_later_workflow_plotting_tranche"),"workflow.json")
  .etr_native_bundle_publish(temp,directory,portable=TRUE)
}
