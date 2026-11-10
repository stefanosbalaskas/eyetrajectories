# Frozen Python public workflows._sparse_async:
# run_sparse_mfpca_async_workflow, exact union-of-native-timestamps.
# Developer-only unsigned finite-domain evidence, not certification.
.etr_spna_public_diff<-function(){
  stopifnot(requireNamespace("pkgload",quietly=TRUE),
    requireNamespace("reticulate",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-sparse-mfpca-async-fixture.R",
    encoding="UTF-8",local=TRUE)
  tr<-.etr_spna_fixture()
  args<-.etr_spna_options()
  native<-etr_run_sparse_mfpca_async_workflow(tr,
    c(list(backend="native_covariance"),args))
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _etr_spna_et
from eyetrajectoriespy.workflows._sparse_async import (
    SparseMFPCAAsyncWorkflowConfig as _etr_spna_cfg,
    run_sparse_mfpca_async_workflow as _etr_spna_run,
)
import importlib
_etr_spna_source_fit=importlib.import_module(
    'eyetrajectoriespy.sparse_multivariate_async').fit_sparse_mfpca_async
def _etr_spna_input(times, values, ids, batch):
    if isinstance(ids,(str,bytes)) or isinstance(batch,(str,bytes)):
        raise TypeError('curve IDs and metadata must be collections')
    assert len(times)==len(values)==len(ids)==len(batch)
    return _etr_spna_et.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(z) for z in ids),
      dimension_names=('x','y'),
      metadata=pd.DataFrame({'batch':list(batch)}),
      coordinate_system='degrees',time_unit='s')
_etr_spna_config=_etr_spna_cfg(
    dimensions=('x','y'),n_components=2,
    evaluation_grid=tuple(np.linspace(.10,.86,9)),
    mean_bandwidth=.7,covariance_bandwidth=.85,
    measurement_error='fixed_matrix',
    measurement_error_covariance=np.array([[.09,.015],[.015,.08]]),
    analysis_support_action='restrict',
    same_time_tolerance=0.,psd_action='project',
    score_ridge=.003,score_condition_limit=1e12,
    min_score_observations=2,
    mean_min_local_points=3,covariance_min_local_pairs=6)
")
  mk<-reticulate::py_eval("_etr_spna_input",convert=FALSE)
  ptr<-reticulate::py_call(mk,
    times=reticulate::r_to_py(tr$time),
    values=reticulate::r_to_py(tr$values),
    ids=reticulate::r_to_py(as.list(as.character(tr$curve_ids))),
    batch=reticulate::r_to_py(
      as.list(as.character(tr$metadata$batch))))
  call<-reticulate::py_eval("_etr_spna_run",convert=FALSE)
  cfg<-reticulate::py_eval("_etr_spna_config",convert=FALSE)
  py<-reticulate::py_call(call,trajectories=ptr,config=cfg)
  pyfit<-reticulate::py_get_attr(py,"fit")
  rows<-list()
  record<-function(field,status,delta=NA_real_,note="",
      fixture="async_correlated_noise"){
    rows[[length(rows)+1L]]<<-data.frame(
      python_name="run_sparse_mfpca_async_workflow",
      scientific_family="native_asynchronous_joint_PACE",
      source_fixture=fixture,field=field,outcome=status,
      max_abs_error=as.numeric(delta),note=note,
      independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  shape<-function(x)as.integer(if(is.null(dim(x)))length(x)
    else dim(x))
  compare<-function(field,a,source){
    b<-et_to_r(source)
    pyshape<-if(reticulate::py_has_attr(source,"shape"))
      as.integer(unlist(et_to_r(
        reticulate::py_get_attr(source,"shape"))))else integer()
    rshape<-if(length(pyshape)==0L&&length(a)==1L)integer()
      else shape(a)
    if(!identical(rshape,pyshape)||length(a)!=length(b)){
      record(field,"DIVERGENT_SCHEMA",note=paste(
        "native shape",paste(rshape,collapse="x"),
        "Python shape",paste(pyshape,collapse="x")))
      return(invisible(FALSE))
    }
    x<-as.numeric(a);y<-as.numeric(b)
    if(any(!is.finite(x))||any(!is.finite(y))){
      record(field,"DIVERGENT_NUMERIC",Inf,
        "nonfinite compared population field")
      return(invisible(FALSE))
    }
    delta<-max(abs(x-y))
    record(field,if(delta<=3e-6*(1+max(abs(y))))
      "PASS_NUMERIC"else"DIVERGENT_NUMERIC",delta)
  }
  fields<-c("scores","eigenvalues","eigenfunctions","mean",
    "quadrature_weights",
    "smoothed_cxx","smoothed_cxy","smoothed_cyx","smoothed_cyy",
    "covariance_cxx","covariance_cxy","covariance_cyx",
    "covariance_cyy","measurement_error_covariance",
    "mean_support_counts")
  for(field in fields)compare(field,native$fit[[field]],
    reticulate::py_get_attr(pyfit,field))
  for(k in c("cxx","cxy","cyy")){
    support<-reticulate::py_get_attr(pyfit,
      "covariance_support_counts")
    compare(paste0("support_",k),
      native$fit$covariance_support_counts[[k]],
      reticulate::py_get_item(support,k))
  }
  for(k in c("xx","xy","yy")){
    pycount<-reticulate::py_get_item(
      reticulate::py_get_attr(pyfit,"covariance_pair_counts"),k)
    compare(paste0("pairs_",k),
      native$fit$covariance_pair_counts[[k]],pycount)
  }
  sourcediag<-et_to_r(reticulate::py_get_attr(
    pyfit,"score_diagnostics"))
  for(field in c("n_x_observations","n_y_observations",
    "n_scalar_observations","n_simultaneous_pairs",
    "measurement_error_cross_links","status_code",
    "solve_status","observation_order")){
    a<-native$fit$score_diagnostics[[field]]
    b<-sourcediag[[field]]
    record(paste0("score_diag_",field),
      if(identical(as.character(a),as.character(b)))
        "PASS_NUMERIC"else"DIVERGENT_SCHEMA")
  }
  support<-et_to_r(reticulate::py_get_attr(
    pyfit,"support_diagnostics"))
  for(field in c("cross_candidate_pair_count",
    "cross_same_time_pair_count_excluded",
    "cross_retained_pair_count",
    "analysis_x_sample_counts","analysis_y_sample_counts")){
    a<-native$fit$support_diagnostics[[field]]
    b<-support[[field]]
    record(paste0("source_support_",field),
      if(identical(as.character(a),as.character(b)))
        "PASS_NUMERIC"else"DIVERGENT_SCHEMA")
  }
  if(identical(as.character(native$workflow_contract),
    as.character(et_to_r(reticulate::py_get_attr(
      py,"workflow_contract")))))
    record("workflow_contract","PASS_NUMERIC")
  else record("workflow_contract","DIVERGENT_SCHEMA")
  pytable<-et_to_r(reticulate::py_get_item(
    reticulate::py_get_attr(py,"tables"),"scores"))
  rtable<-native$tables$scores
  if(!identical(names(rtable),names(pytable))||
      nrow(rtable)!=nrow(pytable))record(
    "scores_table_schema","DIVERGENT_SCHEMA",
    note="source R workflow score frame column or row mismatch")
  else{
    record("scores_table_schema","PASS_NUMERIC")
    for(key in names(rtable)){
      a<-rtable[[key]];b<-pytable[[key]]
      if(is.numeric(a)&&is.numeric(b)){
        delta<-max(abs(a-b))
        record(paste0("scores_table_",key),
          if(delta<=3e-6*(1+max(abs(b))))
            "PASS_NUMERIC"else"DIVERGENT_NUMERIC",delta)
      }else record(paste0("scores_table_",key),
        if(identical(as.character(a),as.character(b)))
          "PASS_NUMERIC"else"DIVERGENT_SCHEMA")
    }
  }
  # Additional frozen Python 1.2 accepted/error-domain source tests.
  # These compare behavior, not Python exception subclasses, and do not
  # imply full accepted-domain certification.
  pyfit<-reticulate::py_eval("_etr_spna_source_fit",convert=FALSE)
  source_args<-args
  source_args$dimensions<-reticulate::tuple("x","y")
  source_args$evaluation_grid<-
    reticulate::r_to_py(args$evaluation_grid)
  source_args$measurement_error_covariance<-
    reticulate::r_to_py(args$measurement_error_covariance)
  safe<-function(fn)tryCatch(
    list(ok=TRUE,message="",result=fn()),
    error=function(e)list(ok=FALSE,message=conditionMessage(e),
      result=NULL))
  bad_cases<-list(
    zero_components=list(n_components=0L),
    negative_ridge=list(score_ridge=-.001),
    negative_same_time_tolerance=list(same_time_tolerance=-.1),
    unsupported_noise_mode=list(measurement_error="estimated"),
    non_psd_noise_matrix=list(
      measurement_error_covariance=matrix(c(.09,.3,.3,.08),2L)),
    reject_outside_support=list(analysis_support_action="error"))
  for(key in names(bad_cases)){
    changed<-bad_cases[[key]]
    rr<-modifyList(args,changed)
    pp<-modifyList(source_args,changed)
    if("measurement_error_covariance"%in%names(changed))
      pp$measurement_error_covariance<-
        reticulate::r_to_py(changed$measurement_error_covariance)
    left<-safe(function()do.call(etr_fit_sparse_mfpca_async_native,
      c(list(trajectories=tr),rr)))
    right<-safe(function()do.call(reticulate::py_call,
      c(list(pyfit,trajectories=ptr),pp)))
    status<-if(!left$ok&&!right$ok)"PASS_BOTH_REJECT"
      else"DIVERGENT_ACCEPTANCE"
    record(paste0("invalid_",key),status,
      note=paste0("native: ",substr(left$message,1L,100L),
        " | Python: ",substr(right$message,1L,100L)))
  }
  # A distinct valid diagonal-noise estimand must match the source's
  # diagonal-mode law; it is not subsumed by full-matrix source cases.
  r_diag<-args
  r_diag$measurement_error<-"diagonal"
  r_diag$measurement_error_covariance<-NULL
  r_diag$measurement_error_variance<-c(.09,.08)
  p_diag<-source_args
  p_diag$measurement_error<-"diagonal"
  p_diag$measurement_error_covariance<-NULL
  p_diag$measurement_error_variance<-reticulate::tuple(.09,.08)
  dr<-safe(function()do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=tr),r_diag)))
  dp<-safe(function()do.call(reticulate::py_call,
    c(list(pyfit,trajectories=ptr),p_diag)))
  if(!dr$ok||!dp$ok){
    record("diagonal_mode_acceptance","DIVERGENT_ACCEPTANCE",
      note=paste("native:",dr$message,"Python:",dp$message))
  }else for(field in c("scores","eigenvalues","mean",
      "covariance_cxy","measurement_error_covariance")){
    a<-dr$result[[field]]
    b<-et_to_r(reticulate::py_get_attr(dp$result,field))
    if(!identical(shape(a),shape(b))||length(a)!=length(b))
      record(paste0("diagonal_",field),"DIVERGENT_SCHEMA")
    else{
      delta<-max(abs(as.numeric(a)-as.numeric(b)))
      record(paste0("diagonal_",field),
        if(is.finite(delta)&&
          delta<=3e-6*(1+max(abs(as.numeric(b)))))
          "PASS_NUMERIC" else "DIVERGENT_NUMERIC",delta)
    }
  }
  output<-do.call(rbind,rows)
  head<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(head)==1L,nchar(head[[1L]])==40L)
  output$r_git_head<-head[[1L]]
  output$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  dir<-file.path("artifacts","native_batch_numeric_diff",
    substr(head[[1L]],1L,12L))
  dir.create(dir,showWarnings=FALSE,recursive=TRUE)
  file<-file.path(dir,"sparse_mfpca_async_source_cases_UNSIGNED.csv")
  utils::write.csv(output,file,row.names=FALSE,na="")
  bad<-grepl("^DIVERGENT",output$outcome)
  if(any(bad)){
    cat("SPARSE_MFPCA_ASYNC_SOURCE_DETAILS:\n")
    print(output[bad,c("field","outcome","max_abs_error","note")],
      row.names=FALSE)
  }
  cat("SPARSE_MFPCA_ASYNC_SOURCE_CASES=",nrow(output),
    ";DIFFERENCES=",sum(bad),";FUNCTIONS=1\n",sep="")
  cat("SPARSE_MFPCA_ASYNC_SOURCE_REPORT=",file,"\n",sep="")
  cat("SPARSE_MFPCA_ASYNC_INDEPENDENT_CERTIFICATIONS=0\n")
  if(any(bad)&&identical(Sys.getenv(
      "ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("asynchronous joint PACE numerical divergence",call.=FALSE)
  invisible(output)
}
.etr_spna_public_diff()
