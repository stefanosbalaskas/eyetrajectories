# Batch differential measurement, not a source-contract certificate.
# 33 fixed source probes across four numerical input/error contracts.
# Uses *real* frozen eyetrajectoriespy 1.2.0 via reticulate, not fixture
# formulas substituted for the published source.
# This writes only untracked evidence under artifacts/native_batch_numeric_diff.
#
# source("scripts/run_batched_numeric_source_differential.R")
# Set ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE=true to block on mismatches.

.etr_batch_native_python_diff <- function() {
  stopifnot(file.exists("DESCRIPTION"),
            requireNamespace("pkgload",quietly=TRUE),
            requireNamespace("reticulate",quietly=TRUE))
  pkgload::load_all(".",quiet=TRUE)
  stopifnot(identical(et_python_version(),"1.2.0"))
  head <- system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  stopifnot(length(head)==1L,nchar(head)==40L)
  set.seed(20261109L)
  cases <- list()
  add <- function(id,name,r_name,r_args,py_args) {
    stopifnot(is.character(id),length(id)==1L,
      is.character(name),length(name)==1L,
      is.character(r_name),length(r_name)==1L)
    cases[[length(cases)+1L]] <<- list(id=id,python_name=name,
      r_name=r_name,r_args=r_args,py_args=py_args)
  }
  grid <- c(0,1,3)
  t_specs <- list(
    list("grid_plain",grid,FALSE),
    list("grid_unit",grid,TRUE),
    list("grid_zero_flag",grid,0L),
    list("grid_one_flag",grid,1L),
    list("grid_text_true",grid,"0"),
    list("grid_text_false",grid,""),
    list("grid_irregular",c(0,.1,.6,1.5),TRUE),
    list("grid_pair",c(0,1),FALSE),
    list("grid_list",list(0,1,3),FALSE),
    list("grid_strings",c("0","1","3"),FALSE),
    list("grid_repeat",c(0,1,1),FALSE),
    list("grid_reverse",c(0,2,1),FALSE))
  for(z in t_specs) {
    v <- z[[2L]];flag <- z[[3L]]
    add(z[[1L]],"functional_trapezoid_weights",
      "etr_trapezoid_weights",
      list(time=v,normalize=flag,python_boundary_mode=TRUE),
      list(time=reticulate::r_to_py(v),normalize=flag))
  }
  x <- array(0,dim=c(2L,3L,3L))
  for(i in seq_len(2L))for(j in seq_len(3L))
    x[i,j,] <- c(.15+.02*i,.35+.01*j,.5-.02*i-.01*j)
  for(ref in c(-1L,0L,1L,2L)) {
    add(paste0("alr_ref_",ref),"alr_transform","etr_alr_transform",
      list(values=x,reference_dimension=ref,epsilon=1e-8,
        python_boundary_mode=TRUE),
      list(values=reticulate::r_to_py(x),
        reference_dimension=as.integer(ref),epsilon=1e-8))
  }
  for(spec in list(
    list("alr_epsilon_small",1e-4),
    list("alr_epsilon_boolean",TRUE),
    list("alr_epsilon_rejected",-1))) {
    e <- spec[[2L]]
    add(spec[[1L]],"alr_transform","etr_alr_transform",
      list(values=x,reference_dimension=-1L,epsilon=e,
        python_boundary_mode=TRUE),
      list(values=reticulate::r_to_py(x),
        reference_dimension=as.integer(-1L),epsilon=e))
  }
  inverse_specs <- list(
    list("inverse_zero",array(0,c(2L,3L,2L))),
    list("inverse_moderate",array(seq(-.7,.6,length.out=12L),
      c(2L,3L,2L))))
  for(spec in inverse_specs)for(ref in 0:2) {
    z <- spec[[2L]];r <- as.integer(ref)
    add(paste0(spec[[1L]],"_",r),"inverse_alr","etr_inverse_alr",
      list(transformed=z,reference_dimension=r,n_dimensions=3L,
        python_boundary_mode=TRUE),
      list(transformed=reticulate::r_to_py(z),
        reference_dimension=r,n_dimensions=as.integer(3L)))
  }
  bad_inverse <- array(0,c(1L,2L,3L))
  add("inverse_shape_rejected","inverse_alr","etr_inverse_alr",
    list(transformed=bad_inverse,reference_dimension=0L,
      n_dimensions=3L,python_boundary_mode=TRUE),
    list(transformed=reticulate::r_to_py(bad_inverse),
      reference_dimension=0L,n_dimensions=3L))
  scores <- matrix(c(0,1,2,3,4,5),nrow=3L,ncol=2L)
  bool_scores <- matrix(c(TRUE,FALSE,TRUE,FALSE,TRUE,FALSE),
    nrow=3L,ncol=2L)
  text_scores <- matrix(c("0","3","1","5"),nrow=2L)
  types <- reticulate::import("types",convert=FALSE)
  for(spec in list(
    list("score_default",scores,NULL),
    list("score_one",scores,1L),
    list("score_two",scores,2L),
    list("score_boolean_slice",scores,TRUE),
    list("score_boolean_matrix",bool_scores,2L),
    list("score_text_matrix",text_scores,2L),
    list("score_zero_rejected",scores,0L))) {
    vals <- spec[[2L]];k <- spec[[3L]]
    native <- list(fpca=list(scores=vals,n_components=2L),
      python_boundary_mode=TRUE)
    python <- list(fpca=types$SimpleNamespace(
      scores=reticulate::r_to_py(vals),
      n_components=as.integer(2L)))
    if(!is.null(k)) {
      native$n_components <- k
      python$n_components <- k
    }
    add(spec[[1L]],"score_distance_matrix",
      "etr_score_distance_matrix",native,python)
  }
  stopifnot(length(cases)==33L,
    length(unique(vapply(cases,`[[`,character(1L),"id")))==33L)
  compare <- function(r,py,name,tolerance=1e-11) {
    a <- r;b <- et_to_r(py)
    if(!is.numeric(a) && !is.logical(a))return(list(
      ok=FALSE,max_abs=Inf,reason="native_non_numeric"))
    if(!is.numeric(b) && !is.logical(b))return(list(
      ok=FALSE,max_abs=Inf,reason="python_non_numeric"))
    da <- dim(a);db <- dim(b)
    if(!identical(name,"functional_trapezoid_weights") &&
        !identical(da,db))return(list(ok=FALSE,max_abs=Inf,
          reason=paste0("shape:",paste(da,collapse="x")," vs ",
            paste(db,collapse="x"))))
    a <- as.numeric(a);b <- as.numeric(b)
    if(length(a)!=length(b))return(list(
      ok=FALSE,max_abs=Inf,reason="length_mismatch"))
    nan_match <- identical(is.nan(a),is.nan(b))
    inf_match <- identical(is.infinite(a),is.infinite(b)) &&
      identical(sign(a[is.infinite(a)]),sign(b[is.infinite(b)]))
    if(!nan_match||!inf_match)return(list(
      ok=FALSE,max_abs=Inf,reason="nonfinite_pattern"))
    finite <- is.finite(a)&is.finite(b)
    if(!identical(is.finite(a),is.finite(b)))return(list(
      ok=FALSE,max_abs=Inf,reason="finite_pattern"))
    error <- if(any(finite))max(abs(a[finite]-b[finite])) else 0
    list(ok=is.finite(error) && error<=tolerance*(1+
      if(any(finite))max(abs(b[finite])) else 0),
      max_abs=error,reason="numeric")
  }
  observed <- lapply(cases,function(c) {
    run <- function(f,args)tryCatch(
      list(ok=TRUE,value=do.call(f,args),error=""),
      error=function(e)list(ok=FALSE,value=NULL,
        error=conditionMessage(e)))
    native_fn <- getExportedValue("eyetrajectories",c$r_name)
    py_fn <- etpy_get_export(c$python_name)
    native <- run(native_fn,c$r_args)
    python <- run(function(...)reticulate::py_call(py_fn,...),
      c$py_args)
    if(!native$ok && !python$ok) {
      status <- "PASS_BOTH_REJECT";gap <- NA_real_
      note <- "error classes/messages NOT necessarily identical"
    } else if(native$ok!=python$ok) {
      status <- "DIVERGENT_ACCEPTANCE";gap <- Inf
      note <- "Only one runtime accepted the case"
    } else {
      d <- compare(native$value,python$value,c$python_name)
      status <- if(d$ok)"PASS_NUMERIC" else "DIVERGENT_NUMERIC"
      gap <- d$max_abs;note <- d$reason
    }
    data.frame(case_id=c$id,python_name=c$python_name,
      native_r_candidate=c$r_name,
      outcome=status,max_abs_error=gap,
      native_error=substr(native$error,1L,360L),
      python_error=substr(python$error,1L,360L),
      note=note,frozen_python_commit=
        "c1cd95ad718327550f7e55393ff38582872f7a94",
      r_git_head=head[[1L]],
      independently_certified=FALSE,
      stringsAsFactors=FALSE)
  })
  frame <- do.call(rbind,observed)
  dir <- file.path("artifacts","native_batch_numeric_diff",
    substr(head[[1L]],1L,12L))
  dir.create(dir,recursive=TRUE,showWarnings=FALSE)
  file <- file.path(dir,"source_numeric_cases_UNSIGNED.csv")
  utils::write.csv(frame,file,row.names=FALSE,na="")
  tab <- table(frame$outcome)
  cat("BATCH_NUMERIC_SOURCE_PROBES=",nrow(frame),
    ";UNIQUE_FUNCTIONS=",length(unique(frame$python_name)),
    ";PASS_NUMERIC=",sum(frame$outcome=="PASS_NUMERIC"),
    ";PASS_BOTH_REJECT=",sum(frame$outcome=="PASS_BOTH_REJECT"),
    ";DIVERGENCES=",sum(grepl("^DIVERGENT",frame$outcome)),
    "\n",sep="")
  cat("BATCH_NUMERIC_SOURCE_REPORT=",file,"\n",sep="")
  cat("BATCH_NUMERIC_SOURCE_INDEPENDENT_CERTIFICATIONS=0\n")
  if(identical(Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true") &&
     any(grepl("^DIVERGENT",frame$outcome)))
    stop("Direct frozen Python numerical source differences require review")
  invisible(frame)
}
.etr_batch_native_python_diff()
