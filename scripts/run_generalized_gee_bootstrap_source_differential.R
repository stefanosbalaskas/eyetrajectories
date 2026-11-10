# Author-side frozen Python 1.2 versus native R participant-case GEE
# bootstrap source differential. Needs 100 independently resampled full GEE
# fits per scientific family; not part of the quick every-commit gate.
# Uses the exact NumPy participant index matrix from Python to control
# initialization; never compares unrelated R and PCG64 random streams.
# Produces unsigned per-field output/shape/error evidence, not certification.
#
# source("scripts/run_generalized_gee_source_differential.R")
# source("scripts/run_generalized_gee_bootstrap_source_differential.R")

.etr_run_gee_bootstrap_source_diff<-function(){
  stopifnot(requireNamespace("reticulate",quietly=TRUE),
    requireNamespace("pkgload",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  # Initialize the same matched input fixtures as the already verified
  # 48-case GEE differential whenever this script is invoked standalone.
  prepared<-tryCatch(reticulate::py_eval(
    "'_wave_gee_cases' in globals()",convert=TRUE),
    error=function(e)FALSE)
  if(!isTRUE(prepared))
    source("scripts/run_generalized_gee_source_differential.R",
      encoding="UTF-8",local=TRUE)
  source("tests/testthat/helper-native-generalized-gee-fixture.R",
    encoding="UTF-8",local=TRUE)
  out<-list()
  add<-function(family,case,field,status,max_abs=NA_real_,
      detail="",native_error="",python_error=""){
    out[[length(out)+1L]]<<-data.frame(
      python_name="bootstrap_generalized_function_on_scalar_coefficients",
      scientific_family=family,case=case,field=field,
      outcome=status,max_abs_error=as.numeric(max_abs),
      note=detail,
      native_error=substr(native_error,1L,400L),
      python_error=substr(python_error,1L,400L),
      independent_full_contract_certified=FALSE,
      stringsAsFactors=FALSE)
  }
  pyitem<-function(key,field)reticulate::py_eval(
    paste0("_wave_gee_cases['",key,"']['",field,"']"),
    convert=FALSE)
  safe<-function(expr)tryCatch(list(ok=TRUE,result=expr(),error=""),
    error=function(e)list(ok=FALSE,result=NULL,
      error=conditionMessage(e)))
  getpy<-function(obj,name)et_to_r(reticulate::py_get_attr(obj,name))
  compare<-function(family,case,field,native,source,tol=1e-4){
    if(!identical(dim(native),dim(source))||
       length(native)!=length(source)){
      add(family,case,field,"DIVERGENT_SCHEMA",
        detail=paste0("native ",paste(dim(native),collapse="x"),
          " vs source ",paste(dim(source),collapse="x")))
      return(invisible(NULL))
    }
    a<-as.numeric(native);b<-as.numeric(source)
    if(!identical(is.finite(a),is.finite(b))||
       !identical(is.nan(a),is.nan(b))||
       !identical(is.infinite(a),is.infinite(b))){
      add(family,case,field,"DIVERGENT_NUMERIC",Inf,
        detail="nonfinite pattern differs")
      return(invisible(NULL))
    }
    good<-is.finite(a)
    delta<-if(any(good))max(abs(a[good]-b[good]))else 0
    scale<-if(any(good))max(abs(b[good]))else 0
    add(family,case,field,
      if(delta<=tol*(1+scale))"PASS_NUMERIC" else
        "DIVERGENT_NUMERIC",delta,
      detail=paste0("relative absolute tolerance=",tol))
  }
  for(key in c("poisson","grouped","exposure")){
    family<-if(key=="grouped")"binomial" else "poisson"
    fixture<-.etr_native_gee_fixture(family,grouped=key=="grouped")
    args<-list(trajectories=fixture$x,design=fixture$design,
      predictors="treatment",participant_column="participant_id",
      dimension="outcome",family=family,basis_size=4L,
      spline_degree=3L)
    pyargs<-list(trajectories=pyitem(key,"trajectories"),
      design=pyitem(key,"design"),
      predictors=reticulate::py_eval("['treatment']",convert=FALSE),
      participant_column="participant_id",dimension="outcome",
      family=family,basis_size=4L,spline_degree=3L)
    if(key=="grouped"){
      args$binomial_denominator<-fixture$den
      pyargs$binomial_denominator<-pyitem(key,"den")
    }
    if(key=="exposure"){
      args$exposure<-rep(2.5,36L)
      pyargs$exposure<-pyitem(key,"exposure")
    }
    # Full source and native fits, no saved objects or fitted-value
    # substitution. Exact input equality was asserted by the preceding
    # generalized source-runner when this object was initialized.
    nr<-safe(function()do.call(
      etr_fit_generalized_function_on_scalar_regression,args))
    pr<-safe(function()do.call(reticulate::py_call,
      c(list(etpy_get_export(
        "fit_generalized_function_on_scalar_regression")),pyargs)))
    if(!nr$ok||!pr$ok){
      add(key,"reference_fit","<call>",
        if(nr$ok==pr$ok)"PASS_BOTH_REJECT"else
          "DIVERGENT_ACCEPTANCE",
        native_error=nr$error,python_error=pr$error)
      next
    }
    nres<-nr$result;pres<-pr$result
    # Each runtime performs 100 whole-participant refits from the same
    # integer seed. Compare the independently generated index matrices.
    ps<-safe(function()reticulate::py_call(
      etpy_get_export(
        "bootstrap_generalized_function_on_scalar_coefficients"),
      result=pres,n_bootstrap=100L,random_state=20261109L))
    if(!ps$ok){
      add(key,"bootstrap","<call>","SOURCE_EXCEPTION",
        python_error=ps$error)
      next
    }
    sampled<-safe(function()getpy(ps$result,
      "sampled_participant_indices"))
    if(!sampled$ok){
      add(key,"bootstrap","sampled_participant_indices",
        "DIVERGENT_SCHEMA",detail=sampled$error)
      next
    }
    ns<-safe(function()
      etr_bootstrap_generalized_function_on_scalar_coefficients(
        nres,n_bootstrap=100L,random_state=20261109L))
    if(!ns$ok){
      add(key,"bootstrap","<call>","DIVERGENT_ACCEPTANCE",
        native_error=ns$error)
      next
    }
    native<-ns$result;python<-ps$result
    add(key,"bootstrap","native_pcg64",
      if(identical(native$provenance$generalized_function_on_scalar_bootstrap$
        native_random_engine,"numpy_pcg64"))"PASS_SCHEMA"else"DIVERGENT_SCHEMA")
    compare(key,"bootstrap","sampled_participant_indices",
      native$sampled_participant_indices,sampled$result,tol=0)
    compare(key,"bootstrap","bootstrap_coefficient_functions",
      native$bootstrap_coefficient_functions,
      getpy(python,"bootstrap_coefficient_functions"))
    # Preserve exact identities and new cluster names, including duplicate
    # participant draws that must be assigned distinct group IDs.
    for(field in c("sampled_source_participant_ids",
        "sampled_bootstrap_participant_ids")){
      a<-native[[field]]
      b<-getpy(python,field)
      count_equal<-length(a)==length(b)&&
        all(lengths(a)==lengths(b))
      same<-count_equal&&identical(as.character(unlist(a)),
        as.character(unlist(b)))
      add(key,"bootstrap",field,
        if(same)"PASS_SCHEMA"else"DIVERGENT_SCHEMA",
        detail=paste0("replicate audit, ",length(a)," native draws"))
    }
    for(spec in list(
       list(name="bootstrap_count_boundary",n_bootstrap=99L),
       list(name="no_silent_redraw",n_bootstrap=100L,
         failed_replicate_policy="drop"))){
      opt<-spec;which<-opt$name;opt$name<-NULL
      pyc<-safe(function()do.call(reticulate::py_call,
        c(list(etpy_get_export(
          "bootstrap_generalized_function_on_scalar_coefficients")),
          list(result=pres),opt)))
      rc<-safe(function()do.call(
        etr_bootstrap_generalized_function_on_scalar_coefficients,
        c(list(result=nres),opt)))
      add(key,which,"<call>",
        if(!pyc$ok&&!rc$ok)"PASS_BOTH_REJECT"
        else if(pyc$ok==rc$ok)"PASS_BOTH_ACCEPT"
        else "DIVERGENT_ACCEPTANCE",
        detail="exception classes/messages retained; not source-certified",
        native_error=rc$error,python_error=pyc$error)
    }
  }
  report<-do.call(rbind,out)
  head<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(head)==1L,nchar(head[[1L]])==40L)
  report$r_git_head<-head[[1L]]
  report$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  path<-file.path("artifacts","native_batch_numeric_diff",
    substr(head[[1L]],1L,12L),
    "generalized_gee_bootstrap_source_cases_UNSIGNED.csv")
  dir.create(dirname(path),showWarnings=FALSE,recursive=TRUE)
  utils::write.csv(report,path,row.names=FALSE,na="")
  bad<-sum(grepl("^(DIVERGENT|SOURCE_EXCEPTION)",report$outcome))
  cat("GENERALIZED_GEE_BOOTSTRAP_CASES=",nrow(report),
    ";SOURCE_DIFFERENCES=",bad,
    ";FAMILIES=",length(unique(report$scientific_family)),
    "\n",sep="")
  cat("GENERALIZED_GEE_BOOTSTRAP_REPORT=",path,"\n",sep="")
  cat("GENERALIZED_GEE_BOOTSTRAP_INDEPENDENT_CERTIFICATIONS=0\n")
  if(bad>0L&&identical(
      Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("Frozen Python participant bootstrap disagreements need review",
      call.=FALSE)
  invisible(report)
}
.etr_run_gee_bootstrap_source_diff()
