# Compare explicit candidate-sample diagnostics and all four native sparse
# workflow entry points against the frozen Python 1.2 source.
.etr_sparse_observation_differential<-function(){
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("scripts/sparse_workflow_source_records.R",local=TRUE)
  for(file in c("observation-process-fixture","sparse-source-fixture",
      "sparse-mfpca-fixture","sparse-mfpca-async-fixture","sparse-multilevel-source-fixture"))
    source(file.path("tests/testthat",paste0("helper-native-",file,".R")),local=TRUE)
  source_api<-reticulate::import("eyetrajectoriespy.observation_process",convert=FALSE)
  workflows<-reticulate::import("eyetrajectoriespy.workflows",convert=FALSE)
  attr<-reticulate::py_get_attr
  item<-reticulate::py_get_item
  call<-reticulate::py_call
  read<-function(object,name)et_to_r(attr(object,name))
  source_process<-function(input){
    for(key in c("candidate_predictors","coordinate_columns"))input[[key]]<-as.list(input[[key]])
    do.call(call,c(list(attr(source_api,"observation_process_data")),input))
  }
  source_options<-function(options){
    for(key in c("history_predictors","time_bins","eccentricity_reference")){
      value<-options[[key]]
      if(length(value)>1L||key=="history_predictors")
        options[key]<-list(as.list(value))
    }
    options
  }
  difference<-function(a,b,unordered=FALSE){
    if(!is.data.frame(a)||!is.data.frame(b)||nrow(a)!=nrow(b))
      return("row count or frame type differs")
    if(!(if(unordered)setequal(names(a),names(b))else identical(names(a),names(b))))
      return(paste("columns",paste(names(a),collapse=","),"versus",paste(names(b),collapse=",")))
    if(!nrow(a))return("")
    for(key in names(a)){
      x<-a[[key]];y<-b[[key]]
      if(is.numeric(x)&&is.numeric(y)){
        equal<-isTRUE(all.equal(as.numeric(x),as.numeric(y),tolerance=1e-10))
      }else{
        equal<-identical(as.character(x),as.character(y))
      }
      if(!equal)return(paste("column differs",key))
    }
    ""
  }
  fields<-c(global="global_summary",curves="curve_summary",groups="group_summary",
    time="time_summary",support="support_summary",associations="associations",
    profiles="profiles",failures="failures",candidates="candidate_frame")
  report_source<-function(result)et_to_r(call(attr(source_api,
    "observation_process_reporting_text"),result=result))
  standalone<-0L
  for(fixture in c("after_observed","all_candidates","without_coordinates","numeric_identifiers")){
    input<-.etr_obs_fixture_input()
    opts<-.etr_obs_fixture_options()
    if(fixture!="after_observed"){
      opts$risk_set<-"all_candidates"
      opts$time_bins<-4L
    }
    if(fixture=="without_coordinates"){
      input$coordinate_columns<-character()
      input$group_column<-NULL
    }
    if(fixture=="numeric_identifiers"){
      input$frame$curve<-rep(c(2,10,-.5),c(6L,6L,5L))
      input$frame$participant<-rep(c(1,2),c(12L,5L))
    }
    process<-do.call(etr_observation_process_data,input)
    source<-source_process(input)
    native<-do.call(etr_diagnose_observation_process,c(list(process),opts))
    expected<-do.call(call,c(list(attr(source_api,"diagnose_observation_process"),
      process=source),source_options(opts)))
    for(key in names(fields)){
      a<-etr_observation_process_frame(native,key)
      b<-et_to_r(call(attr(source_api,"observation_process_frame"),result=expected,table=key))
      mismatch<-difference(a,b,unordered=key=="candidates")
      if(nzchar(mismatch))stop(fixture," ",key," ",mismatch,call.=FALSE)
      standalone<-standalone+1L
    }
    stopifnot(identical(etr_observation_process_reporting_text(native),report_source(expected)))
  }
  cat("OBSERVATION_STANDALONE_TABLES_MATCHED=",standalone,"\n",sep="")

  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy import IrregularTrajectorySet
def _etr_obs_workflow_input(times, values, ids, dimensions, metadata):
    return IrregularTrajectorySet(
        time=tuple(np.asarray(t,dtype=float) for t in times),
        values=tuple(np.asarray(v,dtype=float) for v in values),
        curve_ids=tuple(ids),dimension_names=tuple(dimensions),
        metadata=metadata,coordinate_system='degrees',time_unit='s')
")
  build<-reticulate::py_eval("_etr_obs_workflow_input",convert=FALSE)
  cases<-list(
    run_sparse_fpca_workflow=list(tr=.etr_spn_source_fixture(),runner=etr_run_sparse_fpca_workflow,
      type="SparseFPCAWorkflowConfig",params=list(dimension="signal",n_components=1L,
        evaluation_grid=seq(.08,.92,length.out=9L),mean_bandwidth=.5,covariance_bandwidth=.85,
        analysis_support_action="restrict",noise_variance_method="fixed",
        measurement_error_variance=.07,psd_action="project")),
    run_sparse_mfpca_workflow=list(tr=.etr_spnm_fixture(),runner=etr_run_sparse_mfpca_workflow,
      type="SparseMFPCAWorkflowConfig",params=.etr_spnm_args()),
    run_sparse_mfpca_async_workflow=list(tr=.etr_spna_fixture(),
      runner=etr_run_sparse_mfpca_async_workflow,type="SparseMFPCAAsyncWorkflowConfig",
      params=.etr_spna_options()),
    run_sparse_multilevel_workflow=list(tr=.etr_spml_fixture(),
      runner=etr_run_sparse_multilevel_workflow,type="SparseMultilevelWorkflowConfig",
      params=.etr_spml_options()))
  rows<-list()
  record<-function(name,field,note=""){
    rows[[length(rows)+1L]]<<-data.frame(python_name=name,
      scientific_family="sparse_candidate_observation_process",
      source_fixture="explicit_candidate_rows_after_observed",
      field=field,outcome=if(nzchar(note))"DIVERGENT_SCHEMA"else"PASS_SCHEMA",
      max_abs_error=NA_real_,note=note,independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  opts<-.etr_obs_fixture_options()
  py_opts<-do.call(call,c(list(attr(workflows,"ObservationDiagnosticConfig")),source_options(opts)))
  for(name in names(cases)){
    case<-cases[[name]]
    tr<-case$tr
    input<-.etr_obs_fixture_input(.etr_obs_fixture_frame(tr$curve_ids[1:3]))
    native_process<-do.call(etr_observation_process_data,input)
    reference_process<-source_process(input)
    params<-case$params
    selection_type<-switch(case$type,
      SparseFPCAWorkflowConfig="SparseFPCABandwidthSelectionConfig",
      SparseMFPCAWorkflowConfig="SparseMFPCABandwidthSelectionConfig")
    if(!is.null(selection_type)){
      params$mean_bandwidth<-params$covariance_bandwidth<-NULL
      params$bandwidth_selection<-list(mean_bandwidths=c(.55,.65),
        covariance_bandwidths=.95,n_splits=3L,shuffle=FALSE)
      params$score_uncertainty<-list(failure_action="retain_nan")
    }
    native<-case$runner(tr,c(list(backend="native_covariance",
      observation_diagnostics=opts),params),native_process)
    if(!is.null(selection_type)){
      params$bandwidth_selection$covariance_bandwidths<-
        as.list(params$bandwidth_selection$covariance_bandwidths)
      params$bandwidth_selection<-do.call(call,
        c(list(attr(workflows,selection_type)),params$bandwidth_selection))
      params$score_uncertainty<-do.call(call,
        c(list(attr(workflows,"ScoreUncertaintyConfig")),params$score_uncertainty))
    }
    if(!is.null(params$dimensions))params$dimensions<-as.list(params$dimensions)
    if(length(params$measurement_error_variance)>1L)
      params$measurement_error_variance<-as.list(params$measurement_error_variance)
    params$observation_diagnostics<-py_opts
    cfg<-do.call(call,c(list(attr(workflows,case$type)),params))
    py_data<-call(build,times=tr$time,values=tr$values,ids=as.list(tr$curve_ids),
      dimensions=as.list(tr$dimension_names),metadata=tr$metadata)
    source<-call(attr(workflows,name),trajectories=py_data,config=cfg,
      observation_process=reference_process)
    .etr_compare_sparse_workflow_records(native,source,function(field,ok)
      record(name,field,if(ok)""else"workflow field differs"))
    record(name,"fit_report",if(identical(native$reports$fit,
      et_to_r(item(attr(source,"reports"),"fit"))))""else"fit report differs")
    expected<-attr(source,"observation_diagnostics")
    for(key in c("observation_global","observation_time","observation_associations"))
      record(name,key,difference(native$tables[[key]],
        et_to_r(item(attr(source,"tables"),key))))
    record(name,"support",difference(native$observation_diagnostics$support_summary,
      read(expected,"support_summary")))
    record(name,"diagnostic_failures",difference(native$observation_diagnostics$failures,
      read(expected,"failures")))
    record(name,"diagnostic_report",if(identical(native$reports$observation_diagnostics,
      report_source(expected)))""else"report differs")
    step<-item(attr(source,"steps"),length(native$steps)-1L)
    record(name,"diagnostic_step",if(identical(tail(native$steps,1L)[[1L]]$name,
      read(step,"name")))""else"step order differs")
    decision<-item(attr(source,"decisions"),"observation_diagnostics_requested")
    record(name,"diagnostic_decision",if(identical(native$decisions$observation_diagnostics_requested$value,
      read(decision,"value")))""else"diagnostic decision differs")
    scope<-c("history_uses_past_information_only","time_summary_uses_selected_risk_set",
      "support_summary_uses_full_candidate_denominator","sparse_estimator_modified")
    r_scope<-native$observation_diagnostics$provenance[scope]
    p_scope<-read(expected,"provenance")[scope]
    record(name,"diagnostic_scope",if(identical(r_scope,p_scope))""else"scientific scope differs")
  }
  out<-do.call(rbind,rows)
  head<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(head)==1L,nchar(head)==40L)
  out$r_git_head<-head
  out$frozen_python_commit<-"c1cd95ad718327550f7e55393ff38582872f7a94"
  folder<-file.path("artifacts","native_batch_numeric_diff",substr(head,1L,12L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  utils::write.csv(out,file.path(folder,"sparse_observation_source_cases_UNSIGNED.csv"),
    row.names=FALSE,na="")
  bad<-out$outcome!="PASS_SCHEMA"
  if(any(bad))print(out[bad,c("python_name","field","note")],row.names=FALSE)
  cat("SPARSE_OBSERVATION_SOURCE_CASES=",nrow(out),";DIFFERENCES=",sum(bad),"\n",sep="")
  if(any(bad)&&identical(Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("sparse observation source discrepancies",call.=FALSE)
  invisible(out)
}
.etr_sparse_observation_differential()
