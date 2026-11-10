# Public fixed-bandwidth sparse workflows, compared with frozen Python 1.2.
# Unsigned evidence for the covered fit, reporting and uncertainty paths.
.etr_sparse_workflow_differential<-function(){
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-sparse-source-fixture.R",local=TRUE)
  source("tests/testthat/helper-native-sparse-mfpca-fixture.R",local=TRUE)
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy import IrregularTrajectorySet
def _etr_sparse_workflow_input(times, values, ids, dimensions, metadata):
    return IrregularTrajectorySet(
        time=tuple(np.asarray(t, dtype=float) for t in times),
        values=tuple(np.asarray(v, dtype=float) for v in values),
        curve_ids=tuple(ids), dimension_names=tuple(dimensions),
        metadata=metadata, coordinate_system='degrees', time_unit='s')
")
  python<-reticulate::import("eyetrajectoriespy.workflows",convert=FALSE)
  attr<-reticulate::py_get_attr
  item<-reticulate::py_get_item
  table<-function(workflow,key)et_to_r(item(attr(workflow,"tables"),key))
  rows<-list()
  record<-function(name,fixture,field,outcome,delta=NA_real_){
    rows[[length(rows)+1L]]<<-data.frame(python_name=name,
      scientific_family="sparse_fixed_bandwidth_workflow_PACE",
      source_fixture=fixture,field=field,outcome=outcome,
      max_abs_error=as.numeric(delta),independently_certified=FALSE,
      stringsAsFactors=FALSE)
  }
  compare<-function(name,fixture,field,a,b){
    if(length(a)!=length(b)||!identical(dim(a),dim(b))||
        !identical(is.numeric(a),is.numeric(b))){
      record(name,fixture,field,"DIVERGENT_SCHEMA")
    }else if(!is.numeric(a)){
      record(name,fixture,field,if(identical(a,b))
        "PASS_SCHEMA"else"DIVERGENT_SCHEMA")
    }else{
      finite<-is.finite(a)&is.finite(b)
      same<-finite|(is.na(a)&is.na(b))|
        (is.infinite(a)&is.infinite(b)&a==b)
      delta<-max(c(0,abs(a[finite]-b[finite])))
      scale<-max(c(1,abs(b[finite])))
      record(name,fixture,field,if(all(same)&&delta<=3e-6*scale)
        "PASS_NUMERIC"else"DIVERGENT_NUMERIC",delta)
    }
  }
  frame<-function(name,fixture,label,a,b){
    schema<-is.data.frame(a)&&is.data.frame(b)&&
      identical(names(a),names(b))&&nrow(a)==nrow(b)
    record(name,fixture,paste0(label,".schema"),if(schema)
      "PASS_SCHEMA"else"DIVERGENT_SCHEMA")
    if(schema)for(column in names(a))compare(name,fixture,
      paste0(label,".",column),a[[column]],b[[column]])
  }
  cases<-list(
    fpca=list(data=.etr_spn_source_fixture(),
      runner=etr_run_sparse_fpca_workflow,config="SparseFPCAWorkflowConfig",
      prefix="sparse_fpca",score_min="min_score_samples",
      args=list(dimension="signal",n_components=1L,
        evaluation_grid=seq(.08,.92,length.out=9L),
        mean_bandwidth=.5,covariance_bandwidth=.85,
        noise_variance_method="fixed",measurement_error_variance=.07,
        analysis_support_action="restrict",psd_action="project",score_ridge=.002)),
    mfpca=list(data=.etr_spnm_fixture(),
      runner=etr_run_sparse_mfpca_workflow,config="SparseMFPCAWorkflowConfig",
      prefix="sparse_mfpca",score_min="min_score_time_points",
      args=.etr_spnm_args()))
  for(case in cases){
    tr<-case$data
    source_tr<-reticulate::py_call(
      reticulate::py_eval("_etr_sparse_workflow_input",convert=FALSE),
      times=tr$time,values=tr$values,ids=as.list(tr$curve_ids),
      dimensions=as.list(tr$dimension_names),metadata=tr$metadata)
    name<-paste0("run_",case$prefix,"_workflow")
    frame_name<-paste0(case$prefix,"_score_frame")
    report_name<-paste0(case$prefix,"_reporting_text")
    for(fixture in c("fixed_bandwidth","retained_score_failure")){
      args<-case$args
      if(fixture=="retained_score_failure"){
        args[[case$score_min]]<-max(lengths(tr$time))+1L
        args$score_failure_action<-"retain_nan"
      }
      uncertainty<-list(failure_action="retain_nan")
      native<-case$runner(tr,c(list(backend="native_covariance",
        score_uncertainty=uncertainty),args))
      if(case$prefix=="sparse_mfpca"){
        args$dimensions<-reticulate::tuple("x","y")
        args$measurement_error_variance<-reticulate::tuple(.08,.10)
      }
      args$score_uncertainty<-reticulate::py_call(attr(python,
        "ScoreUncertaintyConfig"),failure_action="retain_nan")
      cfg<-do.call(reticulate::py_call,c(list(attr(python,case$config)),args))
      source<-reticulate::py_call(attr(python,name),trajectories=source_tr,config=cfg)
      source_fit<-attr(source,"fit")
      source_scores<-et_to_r(reticulate::py_call(
        etpy_get_export(frame_name),result=source_fit))
      frame(frame_name,fixture,"scores",native$tables$scores,source_scores)
      frame(name,fixture,"scores_table",native$tables$scores,table(source,"scores"))
      frame(name,fixture,"conditional_score_uncertainty",
        native$tables$score_uncertainty,table(source,"score_uncertainty"))
      compare(name,fixture,"score_uncertainty_requested",
        native$decisions$score_uncertainty_requested$value,
        et_to_r(attr(item(attr(source,"decisions"),"score_uncertainty_requested"),"value")))
      compare(name,fixture,"score_uncertainty_step",
        native$steps[[2L]]$name,et_to_r(attr(item(attr(source,"steps"),1L),"name")))
      report<-et_to_r(reticulate::py_call(etpy_get_export(report_name),result=source_fit))
      compare(report_name,fixture,"fit_report",native$reports$fit,report)
      if(!identical(native$reports$fit,report))
        cat("Fit report differs for ",name," (",fixture,
          ")\nR: ",native$reports$fit,"\nPython: ",report,"\n",sep="")
    }
  }
  out<-do.call(rbind,rows)
  head<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(head)==1L,nchar(head)==40L)
  out$r_git_head<-head
  out$frozen_python_commit<-"c1cd95ad718327550f7e55393ff38582872f7a94"
  folder<-file.path("artifacts","native_batch_numeric_diff",substr(head,1L,12L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  report<-file.path(folder,"sparse_workflow_source_cases_UNSIGNED.csv")
  utils::write.csv(out,report,row.names=FALSE,na="")
  bad<-grepl("^DIVERGENT",out$outcome)
  if(any(bad))print(out[bad,c("python_name","source_fixture","field","outcome")],
    row.names=FALSE)
  cat("SPARSE_WORKFLOW_SOURCE_CASES=",nrow(out),";DIFFERENCES=",sum(bad),
    ";FUNCTIONS=",length(unique(out$python_name)),"\n",sep="")
  if(any(bad)&&identical(Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("sparse workflow source discrepancies",call.=FALSE)
  invisible(out)
}
.etr_sparse_workflow_differential()
