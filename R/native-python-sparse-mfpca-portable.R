# Explicit source-scientific Python 1.2 portable serialization for native
# sparse planar joint covariance/PACE. No reticulate or Python runtime used.
# Frozen references: portable_results.py, workflows/_sparse_mfpca.py,
# types.py::SparseMFPCAResult, at
# c1cd95ad718327550f7e55393ff38582872f7a94.
#
# This is intentionally an input-bounded scientific contract. It refuses
# unsupported records rather than claiming arbitrary Python dataclass parity.

.etr_python_mfpca_portable_module<-"eyetrajectoriespy.workflows._sparse_mfpca"
.etr_python_mfpca_core_module<-"eyetrajectoriespy.workflows._core"

.etr_python_mfpca_portable_value<-function(x,add_array,depth=0L,
    tuple=FALSE){
  .etr_assert(depth<48L,
    "sparse Python portable scientific record nesting is excessive")
  if(is.null(x))return(NULL)
  if(is.data.frame(x)){
    .etr_assert(!anyDuplicated(names(x))&&
      all(nzchar(names(x))),
      "Python portable scientific table requires unique column names")
    return(.etr_portable_writer_dataframe(x,
      index=seq_len(nrow(x))-1L,add_array=add_array))
  }
  if(is.array(x))
    return(add_array(unname(x)))
  if(tuple){
    .etr_assert(is.atomic(x)||is.list(x),
      "source Python tuple must be finite scalar/array elements")
    return(.etr_portable_writer_tuple(lapply(as.list(x),
      .etr_python_mfpca_portable_value,add_array=add_array,
      depth=depth+1L)))
  }
  if(is.list(x)){
    .etr_assert(!is.function(x),
      "portable scientific nested object cannot be a function")
    keys<-names(x)
    if(is.null(keys))
      return(lapply(x,.etr_python_mfpca_portable_value,
        add_array=add_array,depth=depth+1L))
    .etr_assert(!anyNA(keys)&&!anyDuplicated(keys)&&
      all(nzchar(keys)),
      "portable source scientific mapping keys must be unique strings")
    items<-lapply(x,.etr_python_mfpca_portable_value,
      add_array=add_array,depth=depth+1L)
    return(.etr_portable_writer_mapping(items))
  }
  .etr_assert(is.atomic(x)&&!is.factor(x)&&
    (is.numeric(x)||is.character(x)||is.logical(x)),
    "portable source scientific values must be numeric, character or logical")
  if(length(x)==1L){
    .etr_assert((!is.character(x)&&!is.logical(x))||!is.na(x),
      "portable scalar character and logical values cannot be missing")
    if(is.numeric(x)&&is.na(x))return(add_array(as.numeric(x)))
    return(unname(x))
  }
  if(length(x)==0L)return(list())
  return(add_array(unname(x)))
}

.etr_python_mfpca_portable_fit<-function(fit,add_array){
  if(inherits(fit,"etr_sparse_mfpca_source"))
    fit<-.etr_sparse_mfpca_w2_scientific_record(fit)
  .etr_assert(inherits(fit,"etr_sparse_mfpca_w2_scientific_record")&&
    identical(names(fit),.etr_sparse_mfpca_w2_fields),
    "Python sparse portable fit requires strict 29-field native PACE record")
  tuple_fields<-c("dimensions","curve_ids")
  fields<-lapply(names(fit),function(nm){
    .etr_python_mfpca_portable_value(fit[[nm]],add_array,
      tuple=nm%in%tuple_fields)
  })
  names(fields)<-names(fit)
  .etr_portable_writer_record("SparseMFPCAResult",fields,
    module="eyetrajectoriespy.types")
}

.etr_python_mfpca_portable_config<-function(cfg,add_array){
  .etr_assert(is.list(cfg)&&length(cfg)==22L&&
    identical(names(cfg),c(
      "n_components","evaluation_grid","measurement_error","dimensions",
      "mean_bandwidth","covariance_bandwidth","bandwidth_selection",
      "measurement_error_variance","measurement_error_covariance",
      "analysis_support_action","psd_action","psd_tolerance",
      "positive_eigen_tolerance","score_ridge","score_condition_limit",
      "min_score_time_points","score_failure_action",
      "mean_min_local_points","covariance_min_local_pairs",
      "score_uncertainty","observation_diagnostics","preprocessing")),
    "Python W2 portable sparse MFPCA configuration schema must be exact")
  .etr_assert(is.null(cfg$bandwidth_selection)&&
    is.null(cfg$score_uncertainty)&&
    is.null(cfg$observation_diagnostics),
    "portable sparse source v1 currently supports fixed bandwidth with no optional diagnostics")
  .etr_assert(is.list(cfg$preprocessing)&&
    identical(names(cfg$preprocessing),"steps")&&
    !length(cfg$preprocessing$steps),
    "portable sparse source refuses unrecorded preprocessing")
  tuple_fields<-c("dimensions","evaluation_grid",
    "measurement_error_variance")
  fields<-lapply(names(cfg),function(nm){
    if(identical(nm,"preprocessing"))
      return(.etr_portable_writer_record("PreprocessingPlan",
        list(steps=.etr_portable_writer_tuple(list())),
        .etr_python_mfpca_core_module))
    .etr_python_mfpca_portable_value(cfg[[nm]],add_array,
      tuple=nm%in%tuple_fields&&!is.null(cfg[[nm]]))
  })
  names(fields)<-names(cfg)
  .etr_portable_writer_record("SparseMFPCAWorkflowConfig",fields,
    module=.etr_python_mfpca_portable_module)
}

.etr_python_mfpca_portable_workflow<-function(result,add_array){
  .etr_assert(inherits(result,"etr_sparse_mfpca_paired_source_workflow")&&
    identical(result$workflow_contract,"sparse_mfpca:v1")&&
    identical(result$workflow_schema_version,1L),
    "portable paired W2 bundle requires strict sparse MFPCA source workflow")
  .etr_assert(identical(names(result),c(
    "workflow_schema_version","workflow_contract","config","fit",
    "bandwidth_selection","score_uncertainty","observation_diagnostics",
    "steps","decisions","provenance","reports","tables")),
    "Python source W2 portable workflow field names must be canonical")
  .etr_assert(is.null(result$bandwidth_selection)&&
    is.null(result$score_uncertainty)&&
    is.null(result$observation_diagnostics),
    "portable paired W2 source v1 supports the fixed-bandwidth fit-only domain")
  .etr_assert(length(result$steps)==1L&&
    identical(result$steps[[1L]]$name,"fit")&&
    is.list(result$decisions)&&
    is.list(result$reports)&&is.list(result$tables),
    "portable sparse W2 source requires one measured fit and named audit records")
  steps<-lapply(result$steps,function(step){
    .etr_assert(identical(names(step),c(
      "name","function","status","parameters",
      "elapsed_seconds","warnings"))&&
      is.finite(step$elapsed_seconds)&&step$elapsed_seconds>=0,
      "portable W2 source requires a genuine completed measured step")
    .etr_portable_writer_record("WorkflowStepRecord",list(
      name=step$name,`function`=step[["function"]],status=step$status,
      parameters=.etr_python_mfpca_portable_value(step$parameters,add_array),
      elapsed_seconds=step$elapsed_seconds,
      warnings=.etr_python_mfpca_portable_value(step$warnings,
        add_array,tuple=TRUE)),
      module=.etr_python_mfpca_core_module)
  })
  .etr_assert(!is.null(names(result$decisions))&&
    !anyDuplicated(names(result$decisions)),
    "portable source decisions require unique scientific names")
  decisions<-lapply(result$decisions,function(d){
    .etr_assert(is.list(d)&&!is.null(d$source),
      "portable source decision must include declared scientific source")
    .etr_portable_writer_record("WorkflowDecisionRecord",list(
      value=.etr_python_mfpca_portable_value(d$value,add_array),
      source=d$source,criterion=d$criterion),
      module=.etr_python_mfpca_core_module)
  })
  tables<-lapply(result$tables,function(x)
    .etr_python_mfpca_portable_value(x,add_array))
  fields<-list(
    workflow_schema_version=result$workflow_schema_version,
    workflow_contract=result$workflow_contract,
    config=.etr_python_mfpca_portable_config(result$config,add_array),
    fit=.etr_python_mfpca_portable_fit(result$fit,add_array),
    bandwidth_selection=NULL,score_uncertainty=NULL,
    observation_diagnostics=NULL,
    steps=.etr_portable_writer_tuple(steps),
    decisions=.etr_portable_writer_mapping(decisions),
    provenance=.etr_python_mfpca_portable_value(result$provenance,add_array),
    reports=.etr_python_mfpca_portable_value(result$reports,add_array),
    tables=.etr_portable_writer_mapping(tables))
  .etr_portable_writer_record("SparseMFPCAWorkflowResult",fields,
    module=.etr_python_mfpca_portable_module)
}

# Frozen Python _core.py::export_workflow_bundle scientific artifact layout.
# Environment remains an explicitly identified R environment; it cannot
# faithfully become a Python interpreter capture.
.etr_export_python_sparse_mfpca_workflow_bundle<-function(result,directory){
  .etr_assert(inherits(result,"etr_sparse_mfpca_paired_source_workflow")&&
    identical(result$workflow_contract,"sparse_mfpca:v1"),
    "source sparse MFPCA Python bundle requires strict paired W2 workflow")
  .etr_portable_require("zip")
  .etr_native_bundle_validate_artifacts(result)
  .etr_assert(length(result$steps)==1L&&
    is.numeric(result$steps[[1L]]$elapsed_seconds)&&
    is.finite(result$steps[[1L]]$elapsed_seconds)&&
    result$steps[[1L]]$elapsed_seconds>=0,
    "Python sparse MFPCA source bundle requires a measured fit step")
  # Preflight before creating or publishing the destination.
  .etr_python_mfpca_portable_config(result$config,function(x)
    list('__portable_type__'="ndarray",
      key="preflight",dtype="float64",shape=as.list(dim(x))))
  temp<-.etr_native_bundle_temp_dir(directory)
  on.exit(unlink(temp,recursive=TRUE),add=TRUE)
  write_json<-function(value,name)
    .etr_native_bundle_write_text(
      .etr_workflow_json(value,name,empty_mapping=TRUE),
      file.path(temp,name))
  write_json(result$config,"config.json")
  write_json(result$provenance,"provenance.json")
  environment<-list(schema_version=1L,runtime="R",
    captured_at_utc=format(Sys.time(),
      "%Y-%m-%dT%H:%M:%OS6+00:00",tz="UTC"),
    package=list(name="eyetrajectories",
      version=as.character(getNamespaceVersion("eyetrajectories"))),
    r=list(version=as.character(getRversion()),
      platform=R.version$platform),python=NULL)
  write_json(environment,"environment.json")
  steps<-etr_workflow_steps_frame(result$steps)
  decisions<-etr_workflow_decisions_frame(result$decisions)
  steps$elapsed_seconds<-vapply(steps$elapsed_seconds,
    .etr_python_json_float,character(1L))
  .etr_write_python_workflow_csv(steps,file.path(temp,"steps.csv"))
  .etr_write_python_workflow_csv(decisions,file.path(temp,"decisions.csv"))
  portable_dir<-.etr_write_python_portable_result(
    file.path(temp,"result"),
    function(add_array)
      .etr_python_mfpca_portable_workflow(result,add_array),
    encode_manifest=.etr_python_json_encode)
  manifest<-jsonlite::fromJSON(file.path(portable_dir,"manifest.json"))
  artifacts<-.etr_native_bundle_write_artifacts(
    result,temp,portable=TRUE)
  frozen<-etr_frozen_workflow_values()
  write_json(list(
    schema_version=frozen$WORKFLOW_BUNDLE_SCHEMA_VERSION,
    format=frozen$WORKFLOW_BUNDLE_FORMAT,
    workflow_schema_version=result$workflow_schema_version,
    workflow_contract=result$workflow_contract,
    result_type=manifest$result_type,
    portable_result_directory="result",
    reports=as.list(artifacts$reports),
    tables=as.list(artifacts$tables),
    figure_export_included=FALSE,
    figure_export_status="deferred_to_later_workflow_plotting_tranche"),
    "workflow.json")
  .etr_native_bundle_publish(temp,directory,portable=TRUE)
}
