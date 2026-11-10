# Frozen Python 1.2 functional scientific core differential
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Mathematical contracts: quadrature weights, ALR/inverse, FPCA score
# Euclidean distances, and exact-centre windowed RQA sensitivity.
# This runner emits bounded UNSIGNED evidence; it never certifies parity.
.etr_functional_core_differential<-function(){
  stopifnot(requireNamespace("reticulate",quietly=TRUE),
    requireNamespace("pkgload",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _etr_fcd
import importlib
_etr_fcd_rqa=importlib.import_module('eyetrajectoriespy.functional_rqa')
def _etr_fcd_tr(time,values,ids,batch):
  if isinstance(ids,(str,bytes)) or isinstance(batch,(str,bytes)):
    raise TypeError('IDs/metadata must be proper sequences')
  assert len(ids)==len(batch)==np.asarray(values).shape[0]
  return _etr_fcd.TrajectorySet(
    time=np.asarray(time,dtype=float),
    values=np.asarray(values,dtype=float),
    curve_ids=tuple(str(x) for x in ids),
    dimension_names=('x',),
    metadata=pd.DataFrame({'participant':list(batch)}),
    coordinate_system='arbitrary',
    time_unit='s')
")
  results<-list()
  add<-function(name,fixture,field,outcome,delta=NA_real_,
      note="",native_error="",python_error=""){
    results[[length(results)+1L]]<<-data.frame(
      python_name=name,
      scientific_family="functional_core_numeric_source_contract",
      source_fixture=fixture,field=field,outcome=outcome,
      max_abs_error=as.numeric(delta),note=note,
      native_error=substr(native_error,1L,250L),
      python_error=substr(python_error,1L,250L),
      independently_certified=FALSE,stringsAsFactors=FALSE)
  }
  numeric_case<-function(name,fixture,field,a,b,tolerance=1e-8){
    shape<-function(x)as.integer(if(is.null(dim(x)))length(x)
      else dim(x))
    if(!identical(shape(a),shape(b))||length(a)!=length(b)){
      add(name,fixture,field,"DIVERGENT_SCHEMA",
        note=paste("native:",paste(shape(a),collapse="x"),
                   "Python:",paste(shape(b),collapse="x")))
      return(invisible(NULL))
    }
    x<-as.numeric(a);y<-as.numeric(b)
    finite<-is.finite(x)&is.finite(y)
    same_nan<-is.nan(x)&is.nan(y)
    if(!all(finite|same_nan)){
      add(name,fixture,field,"DIVERGENT_NUMERIC",
        note="nonfinite location or value differs")
      return(invisible(NULL))
    }
    delta<-if(any(finite))max(abs(x[finite]-y[finite])) else 0
    scale<-if(any(finite))max(1,abs(y[finite])) else 1
    add(name,fixture,field,
      if(delta<=tolerance*scale)"PASS_NUMERIC"else"DIVERGENT_NUMERIC",
      delta)
  }
  strict_frame<-function(name,fixture,which,a,b){
    if(!is.data.frame(a)||!is.data.frame(b)||!identical(names(a),names(b))||
        nrow(a)!=nrow(b)){
      add(name,fixture,paste0(which,"_schema"),"DIVERGENT_SCHEMA",
        note=paste("R columns:",paste(names(a),collapse=","),
          "Python:",paste(names(b),collapse=",")))
      return(invisible(NULL))
    }
    add(name,fixture,paste0(which,"_schema"),"PASS_NUMERIC")
    for(field in names(a)){
      x<-a[[field]];y<-b[[field]]
      if(is.numeric(x)&&is.numeric(y)){
        numeric_case(name,fixture,paste0(which,".",field),x,y,2e-8)
      }else{
        add(name,fixture,paste0(which,".",field),
          if(identical(as.character(x),as.character(y)))
            "PASS_NUMERIC" else "DIVERGENT_SCHEMA")
      }
    }
  }
  pyfunc<-function(name)etpy_get_export(name)
  # 1. Quadrature; irregular and two-point grids and normalization.
  for(i in seq_along(list(
      c(0,.02,.08,.20,.40,1),
      c(.15,2.65),seq(0,1,length.out=11L)))){
    grids<-list(c(0,.02,.08,.20,.40,1),
      c(.15,2.65),seq(0,1,length.out=11L))
    t<-grids[[i]]
    for(normalize in c(FALSE,TRUE)){
      a<-etr_trapezoid_weights(t,normalize,
        python_boundary_mode=TRUE)
      b<-et_to_r(reticulate::py_call(
        pyfunc("functional_trapezoid_weights"),
        time=reticulate::r_to_py(t),
        normalize=normalize))
      numeric_case("functional_trapezoid_weights",
        paste0("grid",i,"_normalize",normalize),"weights",a,b,1e-12)
    }
  }
  # 2. Forward and inverse simplex transforms. Exact zeros and rotated
  # reference dimensions are scientific, not just formatting, domains.
  simplex<-array(0,c(4L,7L,3L))
  for(i in seq_len(4L))for(t in seq_len(7L)){
    v<-c(.5+.2*sin(i+t/4),
      .4+.1*cos(t/2+i),.2+.1*sin(i-t/3))
    v<-pmax(v,0)
    if(i==2L&&t==3L)v[2L]<-0
    if(i==4L&&t==5L)v[3L]<-0
    simplex[i,t,]<-v/sum(v)
  }
  for(ref in c(-1L,0L,1L)){
    pyindex<-as.integer(ref)
    native<-etr_alr_transform(simplex,
      reference_dimension=pyindex,epsilon=1e-7,
      python_boundary_mode=TRUE)
    source<-et_to_r(reticulate::py_call(
      pyfunc("alr_transform"),
      values=reticulate::r_to_py(simplex),
      reference_dimension=pyindex,epsilon=1e-7))
    numeric_case("alr_transform",paste0("reference_",ref),
      "log_ratio",native,source,1e-10)
    # Reconstruct with the same source reference order; inverse uses
    # Python exp rather than the separately provided stable alternative.
    rn<-etr_inverse_alr(native,reference_dimension=pyindex,
      n_dimensions=3L,python_boundary_mode=TRUE)
    pn<-et_to_r(reticulate::py_call(pyfunc("inverse_alr"),
      transformed=reticulate::r_to_py(source),
      reference_dimension=pyindex,n_dimensions=3L))
    numeric_case("inverse_alr",paste0("reference_",ref),
      "simplex",rn,pn,1e-10)
    numeric_case("inverse_alr",paste0("reference_",ref),
      "roundtrip",rn,simplex,1e-7)
  }
  # 3. FPCA full score distances are invariant to singular-vector sign.
  time<-seq(0,1,length.out=13L);n<-8L
  X<-array(0,c(n,length(time),1L))
  for(i in seq_len(n))
    X[i,,1L]<-sin(pi*time)*(i/7)+
      cos(time*(i+1)/3)+time^2*cos(i)
  ids<-sprintf("curve_%02d",seq_len(n))
  batches<-rep(sprintf("participant_%02d",seq_len(n/2)),each=2L)
  traj<-etr_trajectory_set(time,X,curve_ids=ids,dimension_names="x",
    metadata=data.frame(participant=batches),
    coordinate_system="arbitrary",time_unit="s")
  source_tr<-reticulate::py_call(
    reticulate::py_eval("_etr_fcd_tr",convert=FALSE),
    time=reticulate::r_to_py(time),
    values=reticulate::r_to_py(X),
    ids=reticulate::r_to_py(as.list(ids)),
    batch=reticulate::r_to_py(as.list(batches)))
  rfit<-etr_fit_fpca(traj,n_components=3L)
  pfit<-reticulate::py_call(pyfunc("fit_fpca"),
    trajectories=source_tr,n_components=3L)
  for(k in c(1L,2L,3L)){
    rd<-etr_score_distance_matrix(rfit,n_components=k,
      python_boundary_mode=TRUE)
    pd<-et_to_r(reticulate::py_call(
      pyfunc("score_distance_matrix"),fpca=pfit,n_components=k))
    numeric_case("score_distance_matrix",paste0("rank_",k),
      "pairwise_euclidean",rd,pd,1e-7)
  }
  # 4. Entire windowed RQA sensitivity *public source result*:
  # fixed sample windows, overlap reuse, exact shared centres, descriptive
  # profile shape; no resampling, interpolation, or automatic selection.
  trqa<-0:17;v<-array(NA_real_,c(4L,length(trqa),1L))
  for(i in seq_len(4L))v[i,,1L]<-sin(trqa/3+i/5)+
    .06*trqa+.04*i*cos(trqa/4)
  qids<-paste0("curve_",seq_len(4L))
  group<-c("p1","p1","p2","p2")
  rx<-etr_trajectory_set(as.numeric(trqa),v,
    curve_ids=qids,dimension_names="x",
    metadata=data.frame(participant=group),
    coordinate_system="arbitrary",time_unit="s")
  px<-reticulate::py_call(
    reticulate::py_eval("_etr_fcd_tr",convert=FALSE),
    time=reticulate::r_to_py(as.numeric(trqa)),
    values=reticulate::r_to_py(v),
    ids=reticulate::r_to_py(as.list(qids)),
    batch=reticulate::r_to_py(as.list(group)))
  local<-etr_windowed_rqa_sensitivity(rx,
    metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L),c(7L,3L)),
    radius=1)
  source<-reticulate::py_call(reticulate::py_get_attr(
    reticulate::py_eval("_etr_fcd_rqa",convert=FALSE),
    "windowed_rqa_sensitivity"),
    trajectories=px,metrics=reticulate::tuple("recurrence_rate"),
    window_step_pairs=reticulate::tuple(
      reticulate::tuple(5L,2L),reticulate::tuple(7L,3L)),
    radius=1)
  for(table_name in c("design_table","summary_table","pairwise_table")){
    pytable<-et_to_r(reticulate::py_get_attr(source,table_name))
    strict_frame("windowed_rqa_sensitivity","fixed_two_sample_specs",
      table_name,local[[table_name]],pytable)
  }
  for(i in seq_along(local$analyses)){
    a<-local$analyses[[i]]$trajectories
    b<-reticulate::py_get_attr(
      reticulate::py_get_item(
        reticulate::py_get_attr(source,"analyses"),as.integer(i-1L)),
      "trajectories")
    numeric_case("windowed_rqa_sensitivity",
      paste0("derived_profile_spec_",i),
      "time",a$time,et_to_r(reticulate::py_get_attr(b,"time")))
    numeric_case("windowed_rqa_sensitivity",
      paste0("derived_profile_spec_",i),
      "derived_RQA",a$values,
      et_to_r(reticulate::py_get_attr(b,"values")))
  }
  # Recorded BOTH_REJECT outcomes require actual Python invocation;
  # do not count R-only errors as source comparisons.
  safe<-function(fun)tryCatch(
    list(ok=TRUE,message=""),error=function(e)
      list(ok=FALSE,message=conditionMessage(e)))
  for(bad in list(
      list(kind="duplicate",pairs=list(c(5L,2L),c(5L,2L))),
      list(kind="fractional",pairs=list(c(5L,2.5))),
      list(kind="missing_radius",pairs=list(c(5L,2L))))){
    lhs<-safe(function()etr_windowed_rqa_sensitivity(rx,
      metrics="recurrence_rate",window_step_pairs=bad$pairs,
      radius=if(bad$kind=="missing_radius")NULL else 1))
    py_pairs<-reticulate::r_to_py(lapply(bad$pairs,
      function(x)reticulate::tuple(as.list(x))))
    rhs<-safe(function()reticulate::py_call(
      reticulate::py_get_attr(
        reticulate::py_eval("_etr_fcd_rqa",convert=FALSE),
        "windowed_rqa_sensitivity"),
      trajectories=px,metrics=reticulate::tuple("recurrence_rate"),
      window_step_pairs=py_pairs,
      radius=if(bad$kind=="missing_radius")NULL else 1))
    add("windowed_rqa_sensitivity",bad$kind,"<call>",
      if(!lhs$ok&&!rhs$ok)"PASS_BOTH_REJECT"
      else"DIVERGENT_ACCEPTANCE",
      note="Both source and native must reject; exact exception class not signed",
      native_error=lhs$message,python_error=rhs$message)
  }
  out<-do.call(rbind,results)
  sha<-system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(sha)==1L,nchar(sha)==40L)
  out$r_git_head<-sha
  out$frozen_python_commit<-
    "c1cd95ad718327550f7e55393ff38582872f7a94"
  folder<-file.path("artifacts","native_batch_numeric_diff",
    substr(sha,1L,12L))
  dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  report<-file.path(folder,
    "functional_core_source_cases_UNSIGNED.csv")
  utils::write.csv(out,report,row.names=FALSE,na="")
  failures<-grepl("^(DIVERGENT|SOURCE_EXCEPTION|INVALID)",out$outcome)
  if(any(failures)){
    cat("FUNCTIONAL_CORE_SOURCE_DIFFERENCES:\n")
    print(out[failures,c("python_name","source_fixture","field",
      "outcome","max_abs_error","note"),drop=FALSE],
      row.names=FALSE)
  }
  cat("FUNCTIONAL_CORE_SOURCE_CASES=",nrow(out),
    ";DIFFERENCES=",sum(failures),
    ";FUNCTIONS=",length(unique(out$python_name)),"\n",sep="")
  cat("FUNCTIONAL_CORE_SOURCE_REPORT=",report,"\n",sep="")
  cat("FUNCTIONAL_CORE_SOURCE_INDEPENDENT_CERTIFICATIONS=0\n")
  if(any(failures)&&identical(Sys.getenv(
      "ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
    stop("functional core source numerical differences",call.=FALSE)
  invisible(out)
}
.etr_functional_core_differential()
