# Finite-domain direct R/Python 1.2 numerical comparison of the *public*
# sparse_multivariate.fit_sparse_mfpca two-channel joint covariance PACE.
# Unsigned developer source evidence; no full-domain or independent approval.

.etr_run_joint_sparse_diff<-function(){
  stopifnot(requireNamespace("pkgload",quietly=TRUE),
            requireNamespace("reticulate",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-sparse-mfpca-fixture.R",
    local=TRUE,encoding="UTF-8")
  tr<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  native<-do.call(etr_fit_sparse_mfpca_native,c(
    list(trajectories=tr),args))
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_spnm_diff_et
def _etr_spnm_diff_input(times, values, ids):
    return _etr_spnm_diff_et.IrregularTrajectorySet(
      time=tuple(np.asarray(x,dtype=float) for x in times),
      values=tuple(np.asarray(x,dtype=float) for x in values),
      curve_ids=tuple(str(x) for x in ids),
      dimension_names=('x','y'),coordinate_system='degrees',time_unit='s')
")
  pytr<-reticulate::py_call(
    reticulate::py_eval("_etr_spnm_diff_input",convert=FALSE),
    times=reticulate::r_to_py(tr$time),
    values=reticulate::r_to_py(tr$values),
    ids=reticulate::r_to_py(tr$curve_ids))
  pyargs<-args
  pyargs$dimensions<-reticulate::tuple("x","y")
  pyargs$measurement_error_variance<-reticulate::tuple(.08,.10)
  pyargs$evaluation_grid<-reticulate::r_to_py(pyargs$evaluation_grid)
  public<-etpy_get_export("fit_sparse_mfpca")
  pyfit<-do.call(reticulate::py_call,c(
    list(public,trajectories=pytr),pyargs))
  cases<-list()
  record<-function(fixture,field,outcome,error=NA_real_,note="",
      native_exception="",python_exception=""){
    cases[[length(cases)+1L]]<<-data.frame(
      python_name="fit_sparse_mfpca",
      scientific_family="native_joint_sparse_mfpca_PACE",
      source_fixture=fixture,field=field,outcome=outcome,
      max_abs_error=as.numeric(error),note=note,
      native_error=substr(native_exception,1L,300L),
      python_error=substr(python_exception,1L,300L),
      independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  match_numeric<-function(fixture,field,a,b){
    if(!identical(dim(a),dim(b))||length(a)!=length(b)){
      record(fixture,field,"DIVERGENT_SCHEMA",
        note=paste0("R dim ",paste(dim(a),collapse="x"),
          " Python dim ",paste(dim(b),collapse="x")))
      return(invisible(NULL))
    }
    a<-as.numeric(a);b<-as.numeric(b)
    if(!all(is.finite(a))||!all(is.finite(b))){
      record(fixture,field,"DIVERGENT_NUMERIC",Inf,
        "nonfinite expected population array")
      return(invisible(NULL))
    }
    delta<-max(abs(a-b))
    status<-if(delta<=3e-6*(1+max(abs(b))))"PASS_NUMERIC"
      else "DIVERGENT_NUMERIC"
    record(fixture,field,status,delta,
      "3e-6 relative-to-source-scale absolute tolerance")
  }
  get<-function(o,name)
    et_to_r(reticulate::py_get_attr(o,name))
  for(field in c("mean","eigenvalues","eigenfunctions","scores",
      "smoothed_cxx","smoothed_cxy","smoothed_cyx","smoothed_cyy",
      "covariance_cxx","covariance_cxy","covariance_cyx","covariance_cyy",
      "quadrature_weights","measurement_error_covariance",
      "mean_support_counts")){
    match_numeric("diagonal_noise",field,native[[field]],
      get(pyfit,field))
  }
  support<-reticulate::py_get_attr(pyfit,"covariance_support_counts")
  for(key in c("cxx","cxy","cyy")){
    match_numeric("diagonal_noise",paste0("support_",key),
      native$covariance_support_counts[[key]],
      et_to_r(reticulate::py_get_item(support,key)))
  }
  errors<-list(
    negative_diagonal_noise=list(measurement_error_variance=c(.08,-.1)),
    invalid_components=list(n_components=0L),
    outside_support=list(analysis_support_action="error"),
    bad_measurement_mode=list(measurement_error="estimated_noise"))
  safe<-function(x)tryCatch(list(ok=TRUE,error="",value=x()),
    error=function(e)list(ok=FALSE,error=conditionMessage(e),value=NULL))
  for(name in names(errors)){
    new<-errors[[name]]
    r_args<-modifyList(args,new)
    py_args<-modifyList(pyargs,new)
    if("measurement_error_variance"%in%names(new))
      py_args$measurement_error_variance<-reticulate::tuple(.08,-.1)
    left<-safe(function()do.call(
      etr_fit_sparse_mfpca_native,c(list(trajectories=tr),r_args)))
    right<-safe(function()do.call(reticulate::py_call,
      c(list(public,trajectories=pytr),py_args)))
    record(name,"<call>",if(!left$ok&&!right$ok)
      "PASS_BOTH_REJECT"else"DIVERGENT_ACCEPTANCE",
      note="both rejected; exception-class parity not yet established",
      native_exception=left$error,python_exception=right$error)
  }
  output<-do.call(rbind,cases)
  sha<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(sha)==1L,nchar(sha[[1L]])==40L)
  output$r_git_head<-sha[[1L]]
  output$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  folder<-file.path("artifacts","native_batch_numeric_diff",
    substr(sha[[1L]],1L,12L))
  dir.create(folder,showWarnings=FALSE,recursive=TRUE)
  file<-file.path(folder,"sparse_mfpca_source_cases_UNSIGNED.csv")
  utils::write.csv(output,file,row.names=FALSE,na="")
  disagreements<-sum(grepl("^DIVERGENT",output$outcome))
  cat("SPARSE_MFPCA_SOURCE_CASES=",nrow(output),
      ";DIFFERENCES=",disagreements,";FUNCTIONS=1\n",sep="")
  cat("SPARSE_MFPCA_SOURCE_REPORT=",file,"\n",sep="")
  cat("SPARSE_MFPCA_INDEPENDENT_CERTIFICATIONS=0\n")
  if(disagreements>0L&&identical(
    Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("native joint sparse MFPCA source deviations recorded",call.=FALSE)
  invisible(output)
}
.etr_run_joint_sparse_diff()
