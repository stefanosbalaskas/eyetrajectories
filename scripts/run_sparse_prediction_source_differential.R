# Public frozen Python 1.2 run_sparse_prediction_workflow matched roles:
# proper training -> sparse covariance PACE -> exact-time conformal calibration
# -> simultaneous observed future prediction. Noncertifying, strict evidence.
.etr_sparse_prediction_diff<-function(){
  stopifnot(requireNamespace("pkgload",quietly=TRUE),
    requireNamespace("reticulate",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("scripts/sparse_workflow_source_records.R",local=TRUE)
  source("tests/testthat/helper-native-sparse-source-fixture.R",
    local=TRUE,encoding="UTF-8")
  source("tests/testthat/helper-native-sparse-partial-conformal-fixture.R",
    local=TRUE,encoding="UTF-8")
  proper<-.etr_spn_source_fixture()
  calibration<-.etr_spnpc_fixture()
  target<-.etr_spnp_partial_target_safe()
  training<-list(
    backend="native_covariance",dimension="signal",
    n_components=1L,
    evaluation_grid=seq(.08,.92,length.out=9L),
    mean_bandwidth=.5,covariance_bandwidth=.85,
    noise_variance_method="fixed",measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002)
  config<-list(
    backend="native_sparse_partial_conformal",
    training=training,history_cutoff=.5,
    prediction_grid=c(.60,.72,.84),
    alpha=.30,group_column="batch")
  native<-etr_run_sparse_prediction_workflow(
    proper,calibration,target,config)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from eyetrajectoriespy import IrregularTrajectorySet as _etr_sparse_workflow_data
from eyetrajectoriespy.workflows._sparse_fpca import SparseFPCAWorkflowConfig as _etr_sparse_workflow_fitconfig
from eyetrajectoriespy.workflows._sparse_prediction import (
    SparsePredictionWorkflowConfig as _etr_sparse_workflow_predconfig,
    run_sparse_prediction_workflow as _etr_sparse_workflow_run,
)
def _etr_sparse_workflow_irregular(time, values, ids, batch):
    if isinstance(ids,(str,bytes)) or isinstance(batch,(str,bytes)):
        raise TypeError('source workflow identifiers must be sequences')
    if not (len(time)==len(values)==len(ids)==len(batch)):
        raise AssertionError('source workflow role lengths do not match')
    return _etr_sparse_workflow_data(
      time=tuple(np.asarray(t,dtype=float) for t in time),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(x) for x in ids),
      dimension_names=('signal',),
      metadata=pd.DataFrame({'batch':list(batch)}),
      coordinate_system='degrees',time_unit='s')
_etr_sparse_workflow_training=_etr_sparse_workflow_fitconfig(
    dimension='signal',n_components=1,
    evaluation_grid=tuple(np.linspace(.08,.92,9)),
    mean_bandwidth=.5,covariance_bandwidth=.85,
    noise_variance_method='fixed',
    measurement_error_variance=.07,
    analysis_support_action='restrict',psd_action='project',
    score_ridge=.002)
_etr_sparse_workflow_config=_etr_sparse_workflow_predconfig(
    training=_etr_sparse_workflow_training,history_cutoff=.5,
    prediction_grid=(.60,.72,.84),alpha=.30,
    group_column='batch')
")
  build<-reticulate::py_eval(
    "_etr_sparse_workflow_irregular",convert=FALSE)
  pydata<-function(x)reticulate::py_call(build,
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    ids=reticulate::r_to_py(as.list(as.character(x$curve_ids))),
    batch=reticulate::r_to_py(as.list(as.character(x$metadata$batch))))
  sourceproper<-pydata(proper);sourcecal<-pydata(calibration)
  sourcetarget<-pydata(target)
  pyfunction<-reticulate::py_eval(
    "_etr_sparse_workflow_run",convert=FALSE)
  pycfg<-reticulate::py_eval(
    "_etr_sparse_workflow_config",convert=FALSE)
  py<-reticulate::py_call(pyfunction,
    proper_training=sourceproper,calibration=sourcecal,
    target=sourcetarget,config=pycfg)
  rows<-list()
  add<-function(fixture,field,status,max_abs=NA_real_,note="",
      r_error="",python_error=""){
    rows[[length(rows)+1L]]<<-data.frame(
      python_name="run_sparse_prediction_workflow",
      scientific_family="native_sparse_PACE_conformal_future",
      source_fixture=fixture,field=field,outcome=status,
      max_abs_error=as.numeric(max_abs),note=note,
      native_error=substr(r_error,1,300),
      python_error=substr(python_error,1,300),
      independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  read<-function(x,name)
    et_to_r(reticulate::py_get_attr(x,name))
  compare_records<-function(fixture,native,source){
    .etr_compare_sparse_workflow_records(native,source,function(field,ok)
      add(fixture,field,if(ok)"PASS_SCHEMA"else"DIVERGENT_SCHEMA"))
    add(fixture,"prediction_band_report",if(identical(native$reports$prediction_band,
      read(source,"reports")$prediction_band))"PASS_SCHEMA"else"DIVERGENT_SCHEMA")
  }
  compare_records("grouped_fixed_noise",native,py)
  source_tables<-reticulate::py_get_attr(py,"tables")
  source_band<-et_to_r(reticulate::py_get_item(
    source_tables,"prediction_band"))
  native_band<-native$tables$prediction_band
  for(field in c("time","conditional_mean",
      "observed_predictive_standard_error","lower","upper",
      "alpha","critical_value")){
    a<-native_band[[field]];b<-source_band[[field]]
    if(!is.numeric(a)||!is.numeric(b)||length(a)!=length(b)){
      add("grouped_fixed_noise",field,"DIVERGENT_SCHEMA",
        note="prediction frame field missing or incompatible")
    }else{
      delta<-max(abs(a-b))
      add("grouped_fixed_noise",field,
        if(is.finite(delta)&&delta<=3e-6*(1+max(abs(b))))
          "PASS_NUMERIC" else "DIVERGENT_NUMERIC",
        delta,note="same observed finite target grid")
    }
  }
  for(field in c("curve_id","dimension")){
    a<-as.character(native_band[[field]])
    b<-as.character(source_band[[field]])
    add("grouped_fixed_noise",field,
      if(identical(a,b))"PASS_NUMERIC" else "DIVERGENT_SCHEMA",
      note="exact workflow prediction identifiers")
  }
  source_cal<-read(py,"calibration")
  compare_result_fields<-function(fixture,left,right,fields){
    for(field in fields)
      add(fixture,field,if(field%in%names(left)&&
        .etr_sparse_source_record_equal(left[[field]],read(right,field)))
          "PASS_SCHEMA"else"DIVERGENT_SCHEMA")
  }
  compare_result_fields("calibration_record",native$calibration,source_cal,
    c("calibration_curve_ids","calibration_unit_ids","group_column",
      "history_cutoff","prediction_grid","min_history_observations",
      "condition_limit","history_ridge","n_calibration_curves",
      "n_calibration_units","method","provenance"))
  source_band_record<-read(py,"band")
  compare_result_fields("band_record",native$band,source_band_record,
    c("target_calibration_unit","method","provenance"))
  compare_result_fields("conditional_prediction_record",native$band$prediction,
    read(source_band_record,"prediction"),c("curve_id","dimension",
      "history_cutoff","history_times","history_values","prediction_grid",
      "conditional_mean","latent_covariance","latent_standard_errors",
      "observed_predictive_covariance","observed_predictive_standard_errors",
      "n_history","n_prediction","diagnostics","provenance"))
  for(field in c("critical_value","alpha")){
    a<-native$calibration[[field]]
    b<-read(source_cal,field)
    delta<-max(abs(a-b))
    add("grouped_fixed_noise",paste0("calibration_",field),
      if(delta<=3e-6*(1+abs(b)))"PASS_NUMERIC"
        else"DIVERGENT_NUMERIC",delta)
  }
  sc<-read(source_cal,"unit_scores")
  a<-native$calibration$unit_scores
  if(length(a)!=length(sc))
    add("grouped_fixed_noise","unit_scores","DIVERGENT_SCHEMA",
      note="number of independent exchangeability units differs")
  else{
    delta<-max(abs(a-sc))
    add("grouped_fixed_noise","unit_scores",
      if(delta<=3e-6*(1+max(abs(sc))))"PASS_NUMERIC"
        else"DIVERGENT_NUMERIC",delta)
  }
  source_curve_scores<-read(source_cal,"curve_scores")
  r_curve_scores<-native$calibration$curve_scores
  for(field in c("nonconformity_score","n_history","n_future_grid")){
    a<-r_curve_scores[[field]]
    b<-source_curve_scores[[field]]
    if(length(a)!=length(b))add("grouped_fixed_noise",
      paste0("curve_scores_",field),"DIVERGENT_SCHEMA")
    else{
      delta<-max(abs(a-b))
      add("grouped_fixed_noise",paste0("curve_scores_",field),
        if(delta<=3e-6*(1+max(abs(b))))"PASS_NUMERIC"
          else"DIVERGENT_NUMERIC",delta)
    }
  }
  add("grouped_fixed_noise","workflow_contract",
    if(identical(as.character(native$workflow_contract),
      as.character(read(py,"workflow_contract"))))
      "PASS_NUMERIC"else"DIVERGENT_SCHEMA")
  # Match the structured scientific code and details, separately from
  # the exact error message and language-specific exception representation.
  safe<-function(f)tryCatch(list(ok=TRUE,message="",value=f()),
    error=function(e)list(ok=FALSE,message=conditionMessage(e),value=e))
  invalid<-list(
    calibration_missing_future_grid=list(
      mutate=function(x) {
        x$time[[1L]][5L]<-.6005
        x
      },
      py_mutate=".time[0][4]=.6005"),
    insufficient_calibration_resolution=list(alpha=.01))
  for(nm in names(invalid)){
    spec<-invalid[[nm]]
    if(!is.null(spec$alpha)){
      badcfg<-config;badcfg$alpha<-spec$alpha
      left<-safe(function()etr_run_sparse_prediction_workflow(
        proper,calibration,target,badcfg))
      reticulate::py_run_string("
_etr_bad_pred_cfg=_etr_sparse_workflow_predconfig(
    training=_etr_sparse_workflow_training,
    history_cutoff=.5,prediction_grid=(.60,.72,.84),
    alpha=.01,group_column='batch')
")
      badpy<-reticulate::py_eval("_etr_bad_pred_cfg",convert=FALSE)
      right<-safe(function()reticulate::py_call(pyfunction,
        proper_training=sourceproper,calibration=sourcecal,
        target=sourcetarget,config=badpy))
    }else{
      badcal<-calibration
      badcal$time[[1L]][5L]<-.6005
      left<-safe(function()etr_run_sparse_prediction_workflow(
        proper,badcal,target,config))
      pybad<-pydata(badcal)
      right<-safe(function()reticulate::py_call(pyfunction,
        proper_training=sourceproper,calibration=pybad,
        target=sourcetarget,config=pycfg))
    }
    add(nm,"<call>",
      if(!left$ok&&!right$ok)"PASS_BOTH_REJECT"
        else"DIVERGENT_ACCEPTANCE",
      note="both-reject, exact exception semantics not yet certified",
      r_error=left$message,python_error=right$message)
    .etr_sparse_source_error_contract(function()left$value,
      function()right$value,function(field,ok)add(nm,field,
        if(ok)"PASS_SCHEMA"else"DIVERGENT_SCHEMA"))
  }
  mixed_groups<-calibration
  mixed_groups$metadata$batch<-rep(c("z","\u00e9","A","a"),each=3L)
  mixed_native<-etr_run_sparse_prediction_workflow(
    proper,mixed_groups,target,config)
  mixed_source<-reticulate::py_call(pyfunction,
    proper_training=sourceproper,calibration=pydata(mixed_groups),
    target=sourcetarget,config=pycfg)
  compare_result_fields("mixed_case_unicode_groups",mixed_native$calibration,
    read(mixed_source,"calibration"),c("calibration_unit_ids","unit_scores",
      "curve_scores","critical_value","provenance"))
  selected_cfg<-config
  selected_cfg$training$mean_bandwidth<-selected_cfg$training$covariance_bandwidth<-NULL
  selected_cfg$training$bandwidth_selection<-list(mean_bandwidths=c(.5,.6),
    covariance_bandwidths=.85,n_splits=3L,shuffle=FALSE)
  selected_cfg$training$score_uncertainty<-list()
  selected_native<-etr_run_sparse_prediction_workflow(
    proper,calibration,target,selected_cfg)
  reticulate::py_run_string("
from dataclasses import replace
from eyetrajectoriespy.workflows import SparseFPCABandwidthSelectionConfig, ScoreUncertaintyConfig
_etr_selected_training=replace(_etr_sparse_workflow_training,
    mean_bandwidth=None,covariance_bandwidth=None,
    score_uncertainty=ScoreUncertaintyConfig(),
    bandwidth_selection=SparseFPCABandwidthSelectionConfig(
        mean_bandwidths=(.5,.6),covariance_bandwidths=(.85,),n_splits=3,shuffle=False))
_etr_selected_prediction=replace(_etr_sparse_workflow_config,training=_etr_selected_training)
")
  selected_source<-reticulate::py_call(pyfunction,proper_training=sourceproper,
    calibration=sourcecal,target=sourcetarget,
    config=reticulate::py_eval("_etr_selected_prediction",convert=FALSE))
  compare_records("selected_proper_training",selected_native,selected_source)
  audit<-selected_native$training_workflow$bandwidth_selection
  source_audit<-reticulate::py_get_attr(reticulate::py_get_attr(
    selected_source,"training_workflow"),"bandwidth_selection")
  source_choice<-read(source_audit,"selected_bandwidths")
  add("selected_proper_training","candidate_id",if(identical(
    audit$selected_bandwidths$candidate_id,source_choice$candidate_id))
    "PASS_SCHEMA"else"DIVERGENT_SCHEMA")
  source_assignments<-read(source_audit,"assignments")
  add("selected_proper_training","fold_assignments",if(
    identical(audit$assignments$curve_id,as.character(source_assignments$curve_id))&&
    identical(audit$assignments$fold,as.integer(source_assignments$fold)))
    "PASS_SCHEMA"else"DIVERGENT_SCHEMA")
  source_selected_band<-et_to_r(reticulate::py_get_item(
    reticulate::py_get_attr(selected_source,"tables"),"prediction_band"))
  for(field in c("conditional_mean","observed_predictive_standard_error",
      "lower","upper","critical_value")){
    a<-selected_native$tables$prediction_band[[field]]
    b<-source_selected_band[[field]]
    if(!is.numeric(a)||!is.numeric(b)||length(a)!=length(b)){
      add("selected_proper_training",field,"DIVERGENT_SCHEMA")
    }else{
      delta<-max(abs(a-b))
      add("selected_proper_training",field,
        if(is.finite(delta)&&delta<=3e-6*(1+max(abs(b))))
          "PASS_NUMERIC"else"DIVERGENT_NUMERIC",delta)
    }
  }
  output<-do.call(rbind,rows)
  sha<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(sha)==1L,nchar(sha)==40L)
  output$r_git_head<-sha
  output$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  folder<-file.path("artifacts","native_batch_numeric_diff",
    substr(sha,1L,12L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  report<-file.path(folder,
    "sparse_prediction_source_cases_UNSIGNED.csv")
  utils::write.csv(output,report,row.names=FALSE,na="")
  mismatches<-grepl("^DIVERGENT",output$outcome)
  if(any(mismatches)){
    cat("SPARSE_PREDICTION_DIFFERENTIAL_DETAILS:\\n")
    print(output[mismatches,c("source_fixture","field",
      "outcome","max_abs_error","note","native_error",
      "python_error"),drop=FALSE],row.names=FALSE)
  }
  cat("SPARSE_PREDICTION_SOURCE_CASES=",nrow(output),
    ";DIFFERENCES=",sum(mismatches),";FUNCTIONS=1\\n",sep="")
  cat("SPARSE_PREDICTION_SOURCE_REPORT=",report,"\\n",sep="")
  cat("SPARSE_PREDICTION_SOURCE_INDEPENDENT_CERTIFICATIONS=0\\n")
  if(any(mismatches)&&identical(
    Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("native sparse prediction workflow source disagreement",
      call.=FALSE)
  invisible(output)
}
.etr_sparse_prediction_diff()
