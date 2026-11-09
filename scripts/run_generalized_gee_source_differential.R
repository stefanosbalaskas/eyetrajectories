# Frozen Python 1.2 versus native R: source GEE and profile prediction wave.
# Real public Python exports through reticulate, and real native R routines.
# Developer evidence only; never auto-closes a source gap or approves 508 exports.
# source("scripts/run_generalized_gee_source_differential.R")

.etr_run_generalized_gee_source_differential<-function(){
  stopifnot(requireNamespace("reticulate",quietly=TRUE),
    requireNamespace("pkgload",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("tests/testthat/helper-native-generalized-gee-fixture.R",
    local=TRUE,encoding="UTF-8")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from eyetrajectoriespy.types import TrajectorySet
n=36
tt=np.linspace(0,1,7)
ii=np.arange(1,37)[:,None]
jj=np.arange(1,8)[None,:]
_ids=tuple(f'curve{i:02d}' for i in range(1,37))
_metadata=pd.DataFrame({'participant_id':[f'P{i:02d}' for i in range(1,13) for _ in range(3)]})
_design=pd.DataFrame({'curve_id':list(_ids),
'treatment':(np.arange(1,37)%4<2).astype(float)})
_wave_gee_cases={}
_poisson=((ii+2*jj+(ii*jj)%3)%6).astype(float)
_den=(3+(ii+jj)%3).astype(float)
_group=np.minimum((ii+2*jj)%4,_den).astype(float)
for _key,_values in (('poisson',_poisson),('grouped',_group),('exposure',_poisson)):
 _wave_gee_cases[_key]={
 'trajectories':TrajectorySet(time=tt,values=_values[:,:,None],
  curve_ids=_ids,dimension_names=('outcome',),
  metadata=_metadata.copy(),coordinate_system='unknown',time_unit='s'),
 'design':_design.copy(), 'den':_den.copy(),
 'exposure':np.full(n,2.5)}
_wave_gee_profiles=pd.DataFrame({
 'profile_id':['control','treated','extrapolated'],
 'treatment':[0.,1.,2.]})
")
  cases<-list()
  add<-function(name,fixture,field,status,max_abs=NA_real_,
      detail="",r_error="",py_error=""){
    cases[[length(cases)+1L]]<<-data.frame(
      python_name=name,source_fixture=fixture,field=field,
      outcome=status,max_abs_error=as.numeric(max_abs),
      note=detail,native_error=substr(r_error,1L,280L),
      python_error=substr(py_error,1L,280L),
      independent_full_contract_certified=FALSE,
      stringsAsFactors=FALSE)
  }
  pyitem<-function(key,field)reticulate::py_eval(
    paste0("_wave_gee_cases['",key,"']['",field,"']"),
    convert=FALSE)
  take<-function(call)tryCatch(
    list(ok=TRUE,value=call(),error=""),
    error=function(e)list(ok=FALSE,value=NULL,
      error=conditionMessage(e)))
  compare<-function(name,fixture,field,native,python,tol=5e-4){
    if(is.null(native)||reticulate::py_is_null_xptr(python)){
      add(name,fixture,field,
        if(is.null(native)&&reticulate::py_is_null_xptr(python))
          "PASS_BOTH_NULL" else "DIVERGENT_SCHEMA",
        detail="source/native optional field presence")
      return(invisible(NULL))
    }
    b<-tryCatch(et_to_r(python),error=function(e)NULL)
    if(!(is.numeric(native)||is.logical(native))||
       !(is.numeric(b)||is.logical(b))){
      add(name,fixture,field,"DIVERGENT_SCHEMA",
        detail="numeric source field type not retained")
      return(invisible(NULL))
    }
    if(!identical(dim(native),dim(b))||
       length(native)!=length(b)){
      add(name,fixture,field,"DIVERGENT_SCHEMA",
        detail=paste("native shape",paste(dim(native),collapse="x"),
          "source shape",paste(dim(b),collapse="x")))
      return(invisible(NULL))
    }
    a<-as.numeric(native);z<-as.numeric(b)
    if(!identical(is.nan(a),is.nan(z))||
       !identical(is.infinite(a),is.infinite(z))||
       !identical(is.finite(a),is.finite(z))){
      add(name,fixture,field,"DIVERGENT_NUMERIC",
        max_abs=Inf,detail="nonfinite pattern")
      return(invisible(NULL))
    }
    good<-is.finite(a)&is.finite(z)
    err<-if(any(good))max(abs(a[good]-z[good]))else 0
    scale<-if(any(good))max(abs(z[good]))else 0
    add(name,fixture,field,
      if(err<=tol*(1+scale))"PASS_NUMERIC"else"DIVERGENT_NUMERIC",
      max_abs=err,detail=paste0("rel_abs_tolerance=",tol))
  }
  fit_fields<-c("basis","coefficient_functions",
    "coefficient_standard_errors","parameter_covariance",
    "mean_functions","expanded_design_rank")
  pred_fields<-c("linear_predictor_functions",
    "linear_predictor_standard_errors","mean_functions",
    "mean_standard_errors","rate_functions",
    "expected_count_functions")
  fitted<-list();source_fitted<-list()
  for(key in c("poisson","grouped","exposure")){
    spec<-if(key=="grouped")"binomial" else "poisson"
    f<-.etr_native_gee_fixture(spec,grouped=key=="grouped")
    args<-list(trajectories=f$x,design=f$design,predictors="treatment",
      participant_column="participant_id",dimension="outcome",
      family=spec,basis_size=4L,spline_degree=3L)
    pyargs<-list(trajectories=pyitem(key,"trajectories"),
      design=pyitem(key,"design"),
      predictors=reticulate::py_eval("['treatment']",convert=FALSE),
      participant_column="participant_id",dimension="outcome",
      family=spec,basis_size=4L,spline_degree=3L)
    if(key=="grouped"){
      args$binomial_denominator<-f$den
      pyargs$binomial_denominator<-pyitem(key,"den")
    }
    if(key=="exposure"){
      args$exposure<-rep(2.5,36L)
      pyargs$exposure<-pyitem(key,"exposure")
    }
    native<-take(function()do.call(
      etr_fit_generalized_function_on_scalar_regression,args))
    python<-take(function()do.call(reticulate::py_call,
      c(list(etpy_get_export("fit_generalized_function_on_scalar_regression")),
        pyargs)))
    if(native$ok!=python$ok){
      add("fit_generalized_function_on_scalar_regression",key,
        "<call>","DIVERGENT_ACCEPTANCE",
        r_error=native$error,py_error=python$error)
      next
    }
    if(!native$ok){
      add("fit_generalized_function_on_scalar_regression",key,
        "<call>","PASS_BOTH_REJECT",
        detail="exceptions not class/message-certified",
        r_error=native$error,py_error=python$error)
      next
    }
    fitted[[key]]<-native$value
    source_fitted[[key]]<-python$value
    for(field in fit_fields){
      if(field=="expanded_design_rank"){
        # Python scalar int is an attribute, not an ndarray.
        py<-reticulate::py_get_attr(python$value,field)
        compare("fit_generalized_function_on_scalar_regression",
          key,field,as.numeric(native$value[[field]]),
          py,tol=0)
      }else compare("fit_generalized_function_on_scalar_regression",
        key,field,native$value[[field]],
        reticulate::py_get_attr(python$value,field))
    }
  }
  profiles<-data.frame(
    profile_id=c("control","treated","extrapolated"),
    treatment=c(0,1,2),stringsAsFactors=FALSE)
  for(key in c("poisson","grouped","exposure")){
    if(is.null(fitted[[key]]))next
    versions<-if(key=="exposure")c("rate","count") else "default"
    for(version in versions){
      label<-paste(key,version,sep="_")
      args<-list(result=fitted[[key]],profiles=profiles)
      pyargs<-list(result=source_fitted[[key]],
        profiles=reticulate::py_eval("_wave_gee_profiles",convert=FALSE))
      if(version=="count"){
        args$prediction_scale<-"expected_count"
        args$exposure_profiles<-c(2,3,4)
        pyargs$prediction_scale<-"expected_count"
        pyargs$exposure_profiles<-reticulate::py_eval(
          "np.array([2.,3.,4.])",convert=FALSE)
      }
      nr<-take(function()do.call(
        etr_generalized_function_on_scalar_predict,args))
      pr<-take(function()do.call(reticulate::py_call,
        c(list(etpy_get_export("generalized_function_on_scalar_predict")),
          pyargs)))
      if(!nr$ok||!pr$ok){
        add("generalized_function_on_scalar_predict",label,
          "<call>",if(nr$ok==pr$ok)"PASS_BOTH_REJECT"else
            "DIVERGENT_ACCEPTANCE",
          r_error=nr$error,py_error=pr$error)
      }else for(field in pred_fields)compare(
        "generalized_function_on_scalar_predict",label,field,
        nr$value[[field]],reticulate::py_get_attr(pr$value,field))
    }
  }
  # Explicit negative domain pairs, with both exception messages retained.
  if(!is.null(fitted[["poisson"]])){
    for(spec in list(
       list(name="unsupported_correlation",arg="working_correlation",
         value="exchangeable"),
       list(name="unsupported_covariance",arg="covariance_type",
         value="naive"),
       list(name="invalid_family",arg="family",value="gaussian"))){
      f<-.etr_native_gee_fixture()
      args<-list(trajectories=f$x,design=f$design,
        predictors="treatment",participant_column="participant_id",
        dimension="outcome",family="poisson",basis_size=4L,
        spline_degree=3L)
      pyargs<-list(trajectories=pyitem("poisson","trajectories"),
        design=pyitem("poisson","design"),
        predictors=reticulate::py_eval("['treatment']",convert=FALSE),
        participant_column="participant_id",dimension="outcome",
        family="poisson",basis_size=4L,spline_degree=3L)
      args[[spec$arg]]<-spec$value
      pyargs[[spec$arg]]<-spec$value
      n<-take(function()do.call(
        etr_fit_generalized_function_on_scalar_regression,args))
      p<-take(function()do.call(reticulate::py_call,
        c(list(etpy_get_export("fit_generalized_function_on_scalar_regression")),
          pyargs)))
      add("fit_generalized_function_on_scalar_regression",
        spec$name,"<call>",
        if(!n$ok&&!p$ok)"PASS_BOTH_REJECT"
        else if(n$ok==p$ok)"PASS_BOTH_ACCEPT"else
          "DIVERGENT_ACCEPTANCE",
        detail="error type and message retained, not certified",
        r_error=n$error,py_error=p$error)
    }
  }
  report<-do.call(rbind,cases)
  head<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  output<-file.path("artifacts","native_batch_numeric_diff",
    substr(head[[1L]],1L,12L),
    "generalized_functional_gee_source_cases_UNSIGNED.csv")
  dir.create(dirname(output),recursive=TRUE,showWarnings=FALSE)
  report$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  report$r_git_head<-head[[1L]]
  utils::write.csv(report,output,row.names=FALSE,na="")
  divergences<-sum(grepl("^DIVERGENT",report$outcome))
  cat("GENERALIZED_GEE_SOURCE_CASES=",nrow(report),
    ";DIFFERENCES=",divergences,
    ";FUNCTIONS=",length(unique(report$python_name)),"\n",sep="")
  cat("GENERALIZED_GEE_SOURCE_REPORT=",output,"\n",sep="")
  cat("GENERALIZED_GEE_SOURCE_INDEPENDENT_CERTIFICATIONS=0\n")
  if(identical(Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true")&&
    divergences>0L)
    stop("Frozen Python generalized GEE differential divergences require review")
  invisible(report)
}
.etr_run_generalized_gee_source_differential()
