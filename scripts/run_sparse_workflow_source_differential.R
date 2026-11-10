# Public sparse workflows compared with frozen Python 1.2.
# Unsigned evidence for fitted, uncertainty and bandwidth-selection paths.
.etr_sparse_workflow_differential<-function(){
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-sparse-source-fixture.R",local=TRUE)
  source("tests/testthat/helper-native-sparse-mfpca-fixture.R",local=TRUE)
  source("scripts/sparse_workflow_source_records.R",local=TRUE)
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
      scientific_family="sparse_workflow_PACE",
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
  frame<-function(name,fixture,label,a,b,selector=FALSE){
    schema<-is.data.frame(a)&&is.data.frame(b)&&
      identical(names(a),names(b))&&nrow(a)==nrow(b)
    record(name,fixture,paste0(label,".schema"),if(schema)
      "PASS_SCHEMA"else"DIVERGENT_SCHEMA")
    if(schema)for(column in names(a)){
      left<-a[[column]];right<-b[[column]]
      if(selector&&column%in%c("failure_code","failure_message")){
        nullable<-function(values)vapply(values,function(value)
          if(is.null(value)||is.na(value))NA_character_ else as.character(value),
          character(1L),USE.NAMES=FALSE)
        left<-nullable(left);right<-nullable(right)
        # Native and Python exceptions retain their own wording. Compare
        # failure codes and whether a diagnostic message was preserved.
        if(column=="failure_message"){
          left<-!is.na(left)&nzchar(left);right<-!is.na(right)&nzchar(right)
        }
      }
      if(selector&&column=="noise_bandwidth"){
        left<-as.numeric(left);right<-as.numeric(right)
      }
      compare(name,fixture,paste0(label,".",column),left,right)
    }
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
    source_input<-function(x)reticulate::py_call(
      reticulate::py_eval("_etr_sparse_workflow_input",convert=FALSE),
      times=x$time,values=x$values,ids=as.list(x$curve_ids),
      dimensions=as.list(x$dimension_names),metadata=x$metadata)
    source_tr<-source_input(tr)
    name<-paste0("run_",case$prefix,"_workflow")
    frame_name<-paste0(case$prefix,"_score_frame")
    report_name<-paste0(case$prefix,"_reporting_text")
    fixtures<-c("fixed_bandwidth","retained_score_failure",
      "selected_seeded_curve","selected_group_with_failed_candidate",
      "selected_three_groups_mixed_sizes")
    if(case$prefix=="sparse_fpca")fixtures<-c(fixtures,"selected_diagonal_difference")
    for(fixture in fixtures){
      args<-case$args
      native_tr<-tr
      reference_tr<-source_tr
      if(fixture=="retained_score_failure"){
        args[[case$score_min]]<-max(lengths(tr$time))+1L
        args$score_failure_action<-"retain_nan"
      }
      selected<-startsWith(fixture,"selected_")
      if(selected){
        args$mean_bandwidth<-args$covariance_bandwidth<-NULL
        selector<-list(mean_bandwidths=c(.65,.55,.65),
          covariance_bandwidths=c(.95,.85),n_splits=3L,random_state=41L)
        if(fixture=="selected_group_with_failed_candidate"){
          selector$mean_bandwidths<-c(.002,.65)
          selector$resampling_unit<-"group"
          selector$group_column<-names(tr$metadata)[1L]
          if(case$prefix=="sparse_mfpca"){
            args$measurement_error<-"fixed_matrix"
            args$measurement_error_variance<-NULL
            args$measurement_error_covariance<-matrix(c(.08,.015,.015,.10),2L)
          }
        }
        if(fixture=="selected_three_groups_mixed_sizes"){
          native_tr$metadata$fold_group<-rep(c("Z","a","z"),c(6L,12L,6L))
          reference_tr<-source_input(native_tr)
          selector$resampling_unit<-"group"
          selector$group_column<-"fold_group"
        }
        if(fixture=="selected_diagonal_difference"){
          native_tr$values<-.etr_seed_scope(224L,function()
            lapply(tr$values,function(v)v+stats::rnorm(length(v),sd=.2)))
          reference_tr<-source_input(native_tr)
          args$noise_variance_method<-"diagonal_difference"
          args$measurement_error_variance<-NULL
          args$noise_bandwidth<-.45
          args$noise_support<-c(.20,.80)
          selector$shuffle<-FALSE
        }
        args$bandwidth_selection<-selector
      }
      uncertainty<-list(failure_action="retain_nan")
      native<-case$runner(native_tr,c(list(backend="native_covariance",
        score_uncertainty=uncertainty),args))
      if(case$prefix=="sparse_mfpca"){
        args$dimensions<-reticulate::tuple("x","y")
        if(args$measurement_error=="diagonal")
          args$measurement_error_variance<-reticulate::tuple(.08,.10)
      }
      if(selected){
        selector_class<-sub("WorkflowConfig$","BandwidthSelectionConfig",case$config)
        args$bandwidth_selection<-do.call(reticulate::py_call,
          c(list(attr(python,selector_class)),selector))
      }
      args$score_uncertainty<-reticulate::py_call(attr(python,
        "ScoreUncertaintyConfig"),failure_action="retain_nan")
      cfg<-do.call(reticulate::py_call,c(list(attr(python,case$config)),args))
      source<-reticulate::py_call(attr(python,name),trajectories=reference_tr,config=cfg)
      .etr_compare_sparse_workflow_records(native,source,function(field,ok)
        record(name,fixture,field,if(ok)"PASS_SCHEMA"else"DIVERGENT_SCHEMA"))
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
        native$steps[[length(native$steps)]]$name,
        et_to_r(attr(item(attr(source,"steps"),length(native$steps)-1L),"name")))
      report<-et_to_r(reticulate::py_call(etpy_get_export(report_name),result=source_fit))
      compare(report_name,fixture,"fit_report",native$reports$fit,report)
      if(!identical(native$reports$fit,report))
        cat("Fit report differs for ",name," (",fixture,
          ")\nR: ",native$reports$fit,"\nPython: ",report,"\n",sep="")
      if(selected){
        audit<-native$bandwidth_selection
        source_audit<-attr(source,"bandwidth_selection")
        for(key in c("assignments","candidates","fold_results","curve_losses","candidate_summary"))
          frame(name,fixture,paste0("selector.",key),audit[[key]],
            et_to_r(attr(source_audit,key)),selector=TRUE)
        chosen<-et_to_r(attr(source_audit,"selected_bandwidths"))
        for(key in c("candidate_id","mean_bandwidth","covariance_bandwidth"))
          compare(name,fixture,paste0("selector.selected.",key),
            audit$selected_bandwidths[[key]],chosen[[key]])
        for(key in c("mean_bandwidth","covariance_bandwidth"))
          compare(name,fixture,paste0("selector.refit.",key),native$decisions[[key]]$source,
            et_to_r(attr(item(attr(source,"decisions"),key),"source")))
      }
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
