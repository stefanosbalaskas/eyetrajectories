# Frozen Python public workflows._sparse_multilevel:
# run_sparse_multilevel_workflow, source pinned to
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer-only unsigned numerical evidence. No external approval.
.etr_spml_public_source_diff<-function(){
  stopifnot(requireNamespace("pkgload",quietly=TRUE),
    requireNamespace("reticulate",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-sparse-multilevel-source-fixture.R",
    encoding="UTF-8",local=TRUE)
  tr<-.etr_spml_fixture();args<-.etr_spml_options()
  native<-etr_run_sparse_multilevel_workflow(
    tr,c(list(backend="native_covariance"),args))
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _etr_spmlw_et
from eyetrajectoriespy.workflows._sparse_multilevel import (
  SparseMultilevelWorkflowConfig as _etr_spmlw_config,
  run_sparse_multilevel_workflow as _etr_spmlw_run,
)
def _etr_spmlw_input(times, values, ids, participants):
  if isinstance(ids,(str,bytes)) or isinstance(participants,(str,bytes)):
    raise TypeError('curve IDs and participants must be sequences')
  assert len(times)==len(values)==len(ids)==len(participants)
  return _etr_spmlw_et.IrregularTrajectorySet(
    time=tuple(np.asarray(t,dtype=float) for t in times),
    values=tuple(np.asarray(v,dtype=float) for v in values),
    curve_ids=tuple(str(x) for x in ids),
    dimension_names=('signal',),
    metadata=pd.DataFrame({'participant':list(participants)}),
    coordinate_system='degrees',time_unit='s')
_etr_spmlw_cfg=_etr_spmlw_config(
  dimension='signal',participant_column='participant',
  participant_components=1,trial_components=1,
  evaluation_grid=tuple(np.linspace(.08,.92,9)),
  mean_bandwidth=.75,total_covariance_bandwidth=.85,
  between_covariance_bandwidth=.85,
  noise_variance_method='fixed',measurement_error_variance=.05,
  analysis_support_action='restrict',weighting='observation',
  psd_action='project',score_ridge=.01,
  mean_min_local_points=3,total_covariance_min_local_pairs=6,
  between_covariance_min_local_pairs=6)
")
  mk<-reticulate::py_eval("_etr_spmlw_input",convert=FALSE)
  data<-reticulate::py_call(mk,
    times=reticulate::r_to_py(tr$time),
    values=reticulate::r_to_py(tr$values),
    ids=reticulate::r_to_py(as.list(as.character(tr$curve_ids))),
    participants=reticulate::r_to_py(
      as.list(as.character(tr$metadata$participant))))
  run<-reticulate::py_eval("_etr_spmlw_run",convert=FALSE)
  cfg<-reticulate::py_eval("_etr_spmlw_cfg",convert=FALSE)
  py<-reticulate::py_call(run,trajectories=data,config=cfg)
  read<-function(x,k)et_to_r(reticulate::py_get_attr(x,k))
  pyfit<-reticulate::py_get_attr(py,"fit")
  evidence<-list()
  record<-function(field,status,delta=NA_real_,note=""){
    evidence[[length(evidence)+1L]]<<-data.frame(
      python_name="run_sparse_multilevel_workflow",
      scientific_family="native_sparse_hierarchical_covariance_BLUP",
      source_fixture="fixed_noise_6participants_24trials",
      field=field,outcome=status,max_abs_error=as.numeric(delta),
      note=note,independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  numeric<-function(field,a,b){
    rshape<-as.integer(if(is.null(dim(a)))length(a)else dim(a))
    if(length(a)!=length(b)||!all(is.finite(as.numeric(a)))||
        !all(is.finite(as.numeric(b)))){
      record(field,"DIVERGENT_SCHEMA",
        note="numerical source field missing or has nonfinite values")
      return(invisible(FALSE))
    }
    delta<-max(abs(as.numeric(a)-as.numeric(b)))
    record(field,if(is.finite(delta)&&
      delta<=3e-6*(1+max(abs(as.numeric(b)))))
      "PASS_NUMERIC"else"DIVERGENT_NUMERIC",delta,
      note=paste("native shape",paste(rshape,collapse="x"),
        "; strictly matched full population value ordering"))
  }
  for(field in c("grand_mean","smoothed_total_covariance",
    "smoothed_between_covariance","smoothed_within_covariance",
    "total_covariance","between_covariance","within_covariance",
    "participant_eigenvalues","participant_eigenfunctions",
    "trial_eigenvalues","trial_eigenfunctions","noise_variance",
    "quadrature_weights","mean_support_counts",
    "total_covariance_support_counts",
    "between_covariance_support_counts")){
    source_field<-reticulate::py_get_attr(pyfit,field)
    expected_shape<-as.integer(unlist(et_to_r(
      reticulate::py_get_attr(source_field,"shape"))))
    native_shape<-as.integer(if(is.null(dim(native$fit[[field]])))
      length(native$fit[[field]]) else dim(native$fit[[field]]))
    if(!identical(expected_shape,native_shape)){
      record(field,"DIVERGENT_SCHEMA",note=paste(
        "native",paste(native_shape,collapse="x"),
        "source",paste(expected_shape,collapse="x")))
    }else numeric(field,native$fit[[field]],
      et_to_r(source_field))
  }
  tables<-reticulate::py_get_attr(py,"tables")
  for(key in c("participant_scores","trial_scores",
      "score_diagnostics")){
    rtable<-native$tables[[key]]
    source_table<-et_to_r(reticulate::py_get_item(tables,key))
    if(!identical(names(rtable),names(source_table))||
        nrow(rtable)!=nrow(source_table)){
      record(paste0("table_",key),"DIVERGENT_SCHEMA",
        note="table column names or row count differ")
    }else for(field in names(rtable)){
      a<-rtable[[field]];b<-source_table[[field]]
      if(is.numeric(a)&&is.numeric(b)){
        if(all(is.na(a))&&all(is.na(b)))record(
          paste0(key,".",field),"PASS_NUMERIC",
          note="both undefined for all curves")
        else if(all(is.finite(a))&&all(is.finite(b)))
          numeric(paste0(key,".",field),a,b)
        else record(paste0(key,".",field),"DIVERGENT_NUMERIC",
          note="numerical diagnostic nonfinite mismatch")
      }else record(paste0(key,".",field),
        if(identical(as.character(a),as.character(b)))
          "PASS_NUMERIC"else"DIVERGENT_SCHEMA")
    }
  }
  record("workflow_contract",
    if(identical(as.character(native$workflow_contract),
      as.character(read(py,"workflow_contract"))))
      "PASS_NUMERIC"else"DIVERGENT_SCHEMA")
  out<-do.call(rbind,evidence)
  sha<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(sha)==1L,nchar(sha[[1L]])==40L)
  out$r_git_head<-sha[[1L]]
  out$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  folder<-file.path("artifacts","native_batch_numeric_diff",
    substr(sha[[1L]],1L,12L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  dest<-file.path(folder,
    "sparse_multilevel_source_cases_UNSIGNED.csv")
  utils::write.csv(out,dest,row.names=FALSE,na="")
  diff<-grepl("^DIVERGENT",out$outcome)
  if(any(diff)){
    cat("SPARSE_MULTILEVEL_SOURCE_DETAILS:\n")
    print(out[diff,c("field","outcome","max_abs_error","note")],
      row.names=FALSE)
  }
  cat("SPARSE_MULTILEVEL_SOURCE_CASES=",nrow(out),
    ";DIFFERENCES=",sum(diff),
    ";PUBLIC_FUNCTIONS=1\n",sep="")
  cat("SPARSE_MULTILEVEL_SOURCE_REPORT=",dest,"\n",sep="")
  cat("SPARSE_MULTILEVEL_INDEPENDENT_CERTIFICATIONS=0\n")
  if(any(diff)&&identical(
    Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("native sparse hierarchical public source differences recorded",
      call.=FALSE)
  invisible(out)
}
.etr_spml_public_source_diff()
