# Unsigned author numerical differential: real native sparse FPCA/PACE
# against the pinned *public* Python 1.2 fit_sparse_fpca implementation.
# Experimental unit: one complete irregular sparse trajectory collection.
# No independence, full-domain, or certification claims are inferred.
# Invocation is opt-in through ET_RUN_SPARSE_SOURCE_DIFF=true.

.etr_sparse_source_diff<-function(){
  stopifnot(requireNamespace("pkgload",quietly=TRUE),
    requireNamespace("reticulate",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-sparse-source-fixture.R",
    encoding="UTF-8",local=TRUE)
  tr<-.etr_spn_source_fixture()
  native<-.etr_spn_fit_from_fixture(tr)
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_sparse_src
def _etr_sparse_make_irregular(times, values, ids):
    return _etr_sparse_src.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(x) for x in ids),
      dimension_names=('signal',),
      coordinate_system='degrees',time_unit='s')
")
  x<-reticulate::py_call(
    reticulate::py_eval("_etr_sparse_make_irregular",convert=FALSE),
    times=reticulate::r_to_py(tr$time),
    values=reticulate::r_to_py(tr$values),
    ids=reticulate::r_to_py(tr$curve_ids))
  args<-list(
    trajectories=x,dimension="signal",n_components=1L,
    evaluation_grid=reticulate::r_to_py(seq(.08,.92,length.out=9L)),
    mean_bandwidth=.50,covariance_bandwidth=.85,
    noise_variance_method="fixed",measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
  fit_fn<-etpy_get_export("fit_sparse_fpca")
  py<-do.call(reticulate::py_call,c(list(fit_fn),args))
  out<-list()
  add<-function(case,field,status,max_abs=NA_real_,
      detail="",native_error="",python_error=""){
    out[[length(out)+1L]]<<-data.frame(
      python_name="fit_sparse_fpca",
      scientific_family="native_sparse_fpca_PACE",
      source_fixture=case,field=field,
      outcome=status,max_abs_error=as.numeric(max_abs),
      note=detail,native_error=substr(native_error,1L,300L),
      python_error=substr(python_error,1L,300L),
      independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  # Array shape is a source contract. reticulate may represent
  # NumPy one-dimensional ndarrays as either dimensioned or plain R
  # vectors. Inspect Python ndarray.shape itself, and represent a native
  # R plain vector as a 1D array of its length. Never flatten matrices.
  native_shape<-function(x)
    as.integer(if(is.null(dim(x)))length(x) else dim(x))
  source_shape<-function(x)
    as.integer(unlist(et_to_r(reticulate::py_get_attr(x,"shape"))))
  for(field in c("mean","covariance","eigenvalues",
      "eigenfunctions","scores","quadrature_weights",
      "mean_support_counts","covariance_support_counts")){
    a<-native[[field]]
    pyfield<-reticulate::py_get_attr(py,field)
    b<-et_to_r(pyfield)
    rshape<-native_shape(a)
    pshape<-source_shape(pyfield)
    if(!identical(rshape,pshape)||length(a)!=length(b)){
      add("fixed_noise",paste0("fitted_",field),"DIVERGENT_SCHEMA",detail=paste0(
          "native R logical shape=",paste(rshape,collapse="x"),
          " Python ndarray.shape=",paste(pshape,collapse="x"),
          "; converted R shape=",paste(dim(b),collapse="x")))
    }else{
      av<-as.numeric(a);bv<-as.numeric(b)
      error<-max(abs(av-bv))
      if(!all(is.finite(av))||!all(is.finite(bv)))
        add("fixed_noise",field,"DIVERGENT_NUMERIC",Inf,
          detail="nonfinite fitted population result")
      else add("fixed_noise",field,
        if(error<=2e-6*(1+max(abs(bv))))"PASS_NUMERIC"
        else "DIVERGENT_NUMERIC",
        error,detail="absolute tolerance 2e-6*(1+max(abs(source)))")
    }
  }
  # Public accepted/rejected boundary behavior: no test is counted as
  # source-law numerical equivalence unless *both* backends reject it.
  checks<-list(
    negative_noise=list(
      py=list(measurement_error_variance=-1),
      r=list(measurement_error_variance=-1)),
    wrong_dimension=list(py=list(dimension="unknown"),
      r=list(dimension="unknown")),
    invalid_components=list(py=list(n_components=0L),
      r=list(n_components=0L)),
    outside_support=list(py=list(analysis_support_action="error"),
      r=list(analysis_support_action="error")))
  native_args<-list(trajectories=tr,dimension="signal",
    n_components=1L,evaluation_grid=seq(.08,.92,length.out=9L),
    mean_bandwidth=.5,covariance_bandwidth=.85,
    noise_variance_method="fixed",measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
  safe<-function(f)tryCatch(list(ok=TRUE,value=f(),message=""),
    error=function(e)list(ok=FALSE,value=NULL,
      message=conditionMessage(e)))
  for(name in names(checks)){
    par<-checks[[name]]
    pyargs<-modifyList(args,par$py)
    rargs<-modifyList(native_args,par$r)
    pyout<-safe(function()
      do.call(reticulate::py_call,c(list(fit_fn),pyargs)))
    rout<-safe(function()
      do.call(etr_fit_sparse_fpca_native,rargs))
    add(name,"<call>",
      if(!pyout$ok&&!rout$ok)"PASS_BOTH_REJECT"else
        "DIVERGENT_ACCEPTANCE",
      detail="invalid-domain acceptance only; exact exception classes not proven",
      native_error=rout$message,python_error=pyout$message)
  }
  result<-do.call(rbind,out)
  head<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(head)==1L,nchar(head[[1L]])==40L)
  result$r_git_head<-head[[1L]]
  result$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  dest<-file.path("artifacts","native_batch_numeric_diff",
    substr(head[[1L]],1L,12L),
    "sparse_fpca_source_cases_UNSIGNED.csv")
  dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
  utils::write.csv(result,dest,row.names=FALSE,na="")
  mismatch<-sum(grepl("^DIVERGENT",result$outcome))
  if(mismatch>0L){
    cat("SPARSE_FPCA_DIFFERENTIAL_DETAILS:\n")
    columns<-c("source_fixture","field","outcome",
      "max_abs_error","note","native_error","python_error")
    print(result[grepl("^DIVERGENT",result$outcome),
      columns,drop=FALSE],row.names=FALSE,right=FALSE)
  }
  cat("SPARSE_FPCA_SOURCE_CASES=",nrow(result),
    ";DIFFERENCES=",mismatch,
    ";UNIQUE_FUNCTIONS=1\n",sep="")
  cat("SPARSE_FPCA_SOURCE_REPORT=",dest,"\n",sep="")
  cat("SPARSE_FPCA_SOURCE_INDEPENDENT_CERTIFICATIONS=0\n")
  if(mismatch>0L&&identical(
    Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("sparse FPCA finite-domain source disagreements need review",
      call.=FALSE)
  invisible(result)
}
.etr_sparse_source_diff()
