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
_wave_gee_profile_text=pd.DataFrame({
 'profile_id':[1.,2.,3.], 'treatment':['0.',' 1e0 ','+2']})
_wave_gee_profile_bool=pd.DataFrame({
 'profile_id':[False,True], 'treatment':[False,True]})
_wave_gee_design_text=pd.DataFrame({
 'treatment':_design['treatment'].map(lambda x:f' {x:.1e} ')})
_wave_gee_text_exposure=['2_0']*n
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
    # Python None is a live Python singleton, NOT a NULL external pointer.
    # Convert once and compare actual optional-value semantics, not pointer
    # validity. Fail visibly on an unconvertible source field.
    conversion<-tryCatch(list(ok=TRUE,value=et_to_r(python)),
      error=function(e)list(ok=FALSE,value=NULL))
    if(!conversion$ok){
      add(name,fixture,field,"DIVERGENT_SCHEMA",
        detail="failed to convert frozen Python field")
      return(invisible(NULL))
    }
    b<-conversion$value
    if(is.character(native)){
      if(is.list(b)&&all(vapply(b,function(x)
        is.character(x)&&length(x)==1L,logical(1L))))
        b<-unlist(b,use.names=FALSE)
      matched<-is.character(b)&&identical(unname(native),unname(b))
      add(name,fixture,field,if(matched)"PASS_SCHEMA" else "DIVERGENT_SCHEMA",
        detail="source/native character content and order")
      return(invisible(NULL))
    }
    if(is.null(native)||is.null(b)){
      add(name,fixture,field,
        if(is.null(native)&&is.null(b))
          "PASS_BOTH_NULL" else "DIVERGENT_SCHEMA",
        detail="source/native optional field presence")
      return(invisible(NULL))
    }
    if(!(is.numeric(native)||is.logical(native))||
       !(is.numeric(b)||is.logical(b))){
      add(name,fixture,field,"DIVERGENT_SCHEMA",
        detail="numeric source field type not retained")
      return(invisible(NULL))
    }
    # A native vector represents a one-dimensional source ndarray.
    if(is.null(dim(native))&&identical(dim(b),as.integer(length(native))))
      dim(b)<-NULL
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
    # A paired numerical test is meaningful only if both interpreters
    # received identical arrays, curve IDs, predictors, denominators and
    # exposure. Explicitly distinguish broken fixtures from estimator gaps.
    fixture<-tryCatch({
      pytr<-pyitem(key,"trajectories")
      pyval<-reticulate::py_to_r(reticulate::py_get_attr(pytr,"values"))
      pyt<-as.numeric(reticulate::py_to_r(
        reticulate::py_get_attr(pytr,"time")))
      pyids<-as.character(unlist(reticulate::py_to_r(
        reticulate::py_get_attr(pytr,"curve_ids"))))
      .etr_assert(identical(dim(pyval),dim(f$x$values))&&
        all(abs(pyval-f$x$values)<1e-12),
        "response value arrays differ")
      .etr_assert(identical(length(pyt),length(f$x$time))&&
        all(abs(pyt-f$x$time)<1e-12),
        "common time grids differ")
      .etr_assert(identical(pyids,as.character(f$x$curve_ids)),
        "curve IDs or order differ")
      pyd<-reticulate::py_to_r(pyitem(key,"design"))
      align<-match(as.character(f$design$curve_id),
        as.character(pyd$curve_id))
      .etr_assert(!anyNA(align)&&
        all(abs(as.numeric(pyd$treatment[align])-
          f$design$treatment)<1e-12),
        "predictor values or curve alignment differ")
      if(key=="grouped"){
        den<-reticulate::py_to_r(pyitem(key,"den"))
        .etr_assert(identical(dim(den),dim(f$den))&&
          all(abs(den-f$den)<1e-12),
          "grouped-binomial denominators differ")
      }
      if(key=="exposure"){
        expy<-reticulate::py_to_r(pyitem(key,"exposure"))
        .etr_assert(length(expy)==36L&&
          all(abs(as.numeric(expy)-2.5)<1e-12),
          "Poisson exposures differ")
      }
      list(ok=TRUE,error="")
    },error=function(e)list(ok=FALSE,error=conditionMessage(e)))
    if(!fixture$ok){
      add("fit_generalized_function_on_scalar_regression",key,
        "<input_fixture>","INVALID_FIXTURE",
        detail=fixture$error)
      next
    }
    add("fit_generalized_function_on_scalar_regression",key,
      "<input_fixture>","SOURCE_INPUT_MATCH",
      max_abs=0,
      detail="source and native values, times, curve IDs, predictors and optional arrays checked")
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
  # Real frozen workflow execution with ordered design rows, decimal
  # predictor text and the separate NumPy float conversion of exposure.
  f<-.etr_native_gee_fixture()
  order<-match(f$x$curve_ids,f$design$curve_id)
  text_design<-data.frame(treatment=sprintf(" %.1e ",f$design$treatment[order]))
  native_cfg<-list(predictors="treatment",participant_column="participant_id",
    dimension="outcome",family=" POISSON ",basis_size=4L,spline_degree=3L,
    exposure=rep("2_0",length(order)),exposure_units=" person / hours ")
  py_cfg<-reticulate::py_call(etpy_get_export(
    "GeneralizedFunctionalWorkflowConfig",.namespace="workflows"),
    predictors=reticulate::py_eval("['treatment']",convert=FALSE),
    participant_column=native_cfg$participant_column,dimension=native_cfg$dimension,
    family=native_cfg$family,basis_size=native_cfg$basis_size,
    spline_degree=native_cfg$spline_degree,exposure=reticulate::py_eval(
      "_wave_gee_text_exposure",convert=FALSE),exposure_units=native_cfg$exposure_units)
  wn<-take(function()etr_run_generalized_functional_workflow(
    f$x,text_design,native_cfg,python_boundary_mode=TRUE))
  wp<-take(function()reticulate::py_call(etpy_get_export(
    "run_generalized_functional_workflow",.namespace="workflows"),
    trajectories=pyitem("poisson","trajectories"),
    design=reticulate::py_eval("_wave_gee_design_text",convert=FALSE),config=py_cfg))
  wname<-"run_generalized_functional_workflow"
  wcase<-"source_order_text_exposure"
  if(!wn$ok||!wp$ok){
    add(wname,wcase,"<call>",if(!wp$ok)"SOURCE_EXCEPTION" else
      "DIVERGENT_ACCEPTANCE",r_error=wn$error,py_error=wp$error)
  }else{
    native_w<-wn$value;python_w<-wp$value
    pfit<-reticulate::py_get_attr(python_w,"fit")
    for(field in c(fit_fields,"scalar_design_matrix","exposure",
      "linear_predictor_count","exposure_units","family"))
      compare("fit_generalized_function_on_scalar_regression",wcase,field,
        native_w$fit[[field]],reticulate::py_get_attr(pfit,field))
    compare(wname,wcase,"workflow_contract",native_w$workflow_contract,
      reticulate::py_get_attr(python_w,"workflow_contract"))
    compare(wname,wcase,"workflow_schema_version",native_w$workflow_schema_version,
      reticulate::py_get_attr(python_w,"workflow_schema_version"),tol=0)
    compare(wname,wcase,"fit_report",native_w$reports$fit,
      reticulate::py_get_item(reticulate::py_get_attr(python_w,"reports"),"fit"))
    for(frame in c("workflow_steps_frame","workflow_decisions_frame",
      "workflow_summary_frame")){
      native_frame<-switch(frame,
        workflow_steps_frame=etr_workflow_steps_frame(native_w$steps),
        workflow_decisions_frame=etr_workflow_decisions_frame(native_w$decisions),
        workflow_summary_frame=etr_workflow_summary_frame(native_w))
      target<-switch(frame,workflow_steps_frame=reticulate::py_get_attr(python_w,"steps"),
        workflow_decisions_frame=reticulate::py_get_attr(python_w,"decisions"),
        workflow_summary_frame=python_w)
      py_frame<-et_to_r(reticulate::py_call(etpy_get_export(frame,
        .namespace="workflows"),target))
      if(!identical(names(native_frame),names(py_frame))){
        add(wname,wcase,frame,"DIVERGENT_SCHEMA",detail="ordered frame columns differ")
        next
      }
      for(field in setdiff(names(native_frame),c("elapsed_seconds","criterion")))
        compare(wname,wcase,paste(frame,field,sep="."),
          native_frame[[field]],py_frame[[field]],tol=0)
    }
  }
  for(kind in c("text","bool")){
    if(is.null(fitted[["exposure"]]))next
    np<-if(kind=="text")data.frame(profile_id=c(1,2,3),
      treatment=c("0."," 1e0 ","+2")) else
        data.frame(profile_id=c(FALSE,TRUE),treatment=c(FALSE,TRUE))
    ne<-if(kind=="text")c("2_0","3.0","4e0") else c(TRUE,TRUE)
    pe<-reticulate::r_to_py(as.list(ne))
    nr<-take(function()etr_generalized_function_on_scalar_predict(
      fitted[["exposure"]],np,exposure_profiles=ne,
      prediction_scale="expected_count",python_boundary_mode=TRUE))
    pr<-take(function()reticulate::py_call(etpy_get_export(
      "generalized_function_on_scalar_predict"),
      result=source_fitted[["exposure"]],profiles=reticulate::py_eval(
        paste0("_wave_gee_profile_",kind),convert=FALSE),
      exposure_profiles=pe,prediction_scale="expected_count"))
    name<-"generalized_function_on_scalar_predict"
    label<-paste("coerced_profiles",kind,sep="_")
    if(!nr$ok||!pr$ok){
      add(name,label,"<call>",if(!pr$ok)"SOURCE_EXCEPTION" else
        "DIVERGENT_ACCEPTANCE",r_error=nr$error,py_error=pr$error)
    }else{
      for(field in c(pred_fields,"profile_ids","profile_design_matrix",
        "predictor_values","exposure_profiles","prediction_scale","extrapolation_flags"))
        compare(name,label,field,nr$value[[field]],
          reticulate::py_get_attr(pr$value,field),
          tol=if(field=="extrapolation_flags")0 else 5e-4)
    }
  }
  fit_name<-"fit_generalized_function_on_scalar_regression"
  boundary_rejections<-c(
    score_too_large="GEE did not converge",
    subthreshold_rank="scalar design matrix",
    rank_deficient="scalar design matrix",
    zero_counts="first guess on the deviance")
  for(key in c("one_update","weighted_grouped","separated",
    "nearly_rank_deficient","numeric_curve_id",names(boundary_rejections))){
    label<-paste0("source_gee_",key)
    args<-.etr_native_gee_boundary_case(key)
    n<-take(function()do.call(etr_fit_generalized_function_on_scalar_regression,args))
    p<-take(function().etr_python_gee_boundary_call(args))
    if(key%in%names(boundary_rejections)){
      phrase<-boundary_rejections[[key]]
      matched<-!n$ok&&!p$ok&&grepl(phrase,n$error,fixed=TRUE)&&
        grepl(phrase,p$error,fixed=TRUE)
      add(fit_name,label,"<call>",
        if(matched)"PASS_BOTH_REJECT" else "DIVERGENT_ACCEPTANCE",
        detail=paste("expected rejection at",phrase),
        r_error=n$error,py_error=p$error)
      next
    }
    if(!n$ok||!p$ok){
      add(fit_name,label,"<call>","DIVERGENT_ACCEPTANCE",
        r_error=n$error,py_error=p$error)
      next
    }
    for(field in c(fit_fields,"basis_coefficients","basis_knots",
      "observed_functions","scalar_design_matrix","linear_predictor_functions",
      "linear_predictor_rate","linear_predictor_count","log_exposure",
      "exposure","rate_functions","binomial_successes","binomial_denominators",
      "binomial_observed_proportions","binomial_expected_successes",
      "binomial_denominator_expanded_from_curve","exposure_expanded_from_curve",
      "scale","maxiter","ctol","converged","family","link","exposure_units"))
      compare(fit_name,label,field,n$value[[field]],
        reticulate::py_get_attr(p$value,field),tol=1e-9)
    warnings<-as.character(unlist(et_to_r(
      reticulate::py_get_attr(p$value,"backend_warnings")),use.names=FALSE))
    compare(fit_name,label,"backend_warnings",n$value$backend_warnings,warnings)
    model<-reticulate::py_get_attr(p$value,"model")
    updates<-reticulate::py_len(reticulate::py_get_item(
      reticulate::py_get_attr(model,"fit_history"),"params"))
    compare(fit_name,label,"gee_score_iterations",
      n$value$provenance$gee_score_iterations,updates,tol=0)
    compare(fit_name,label,"gee_score_norm",n$value$provenance$gee_score_norm,
      reticulate::py_get_attr(model,"score_norm"),tol=1e-11)
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
  divergences<-sum(grepl("^(DIVERGENT|INVALID_FIXTURE|SOURCE_EXCEPTION)",report$outcome))
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
