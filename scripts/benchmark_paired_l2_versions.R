# eyetrajectories — source-pinned controlled L2 baseline versus fastpath.
# v0.4.3 exact pairwise-loop function body is extracted from the release tag.
# Main optimized function body is extracted from immutable commit 8920ec9.
# Both share identical validated trajectory inputs AND native scalar helpers.
# A minor compatibility shim accepts the old python_boundary_mode=FALSE arg.
# Thus this is an algorithmic matched-input benchmark, not running two
# independently installed release namespaces.
# Real data remain on local disk. All derived results are aggregate counts.
# Set ET_PAIRED_L2_NO_AUTORUN=true to load definitions without execution.

.pl_old_url <- paste0(
  "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/",
  "v0.4.3/R/native-distances.R")
.pl_fast_sha <- "8920ec907677b994078720bdb5ecd2afbcc832bb"
.pl_new_url <- paste0(
  "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/",
  .pl_fast_sha,"/R/native-distances.R")
.pl_old_blob <- "acc135d35133e07c1fd32e947aaa0c9a6d45be8b"
.pl_new_blob <- "8d243b0736da7bdc5d964678b17412baa24b9a13"

.pl_expr <- function(parsed,symbol){
  relevant<-Filter(function(expr)
    is.call(expr)&&identical(as.character(expr[[1L]]),"<-") &&
    length(expr)>=3L&&identical(as.character(expr[[2L]]),symbol),
    as.list(parsed))
  if(length(relevant)!=1L)stop("Expected one exact source function: ",symbol)
  relevant[[1L]][[3L]]
}
.pl_sources <- function(){
  # Try offline git tags first, then immutable GitHub sources.
  git<-Sys.which("git")
  readsrc<-function(ref,url){
    if(nzchar(git)&&dir.exists(".git")){
      z<-tryCatch(suppressWarnings(system2(git,
        c("show",paste0(ref,":R/native-distances.R")),
        stdout=TRUE,stderr=FALSE)),error=function(e)character())
      if(length(z)>100L && is.null(attr(z,"status")))return(z)
    }
    readLines(url(url),warn=FALSE)
  }
  old<-readsrc("v0.4.3",.pl_old_url)
  fast<-readsrc(.pl_fast_sha,.pl_new_url)
  list(old=parse(text=old),fast=parse(text=fast),
       old_source=.pl_old_url,fast_source=.pl_new_url)
}
.pl_algorithms <- function(){
  src<-.pl_sources()
  envir<-new.env(parent=asNamespace("eyetrajectories"))
  # Read exact published helper from development source, used unchanged for
  # both comparators except explicit backward-compatible FALSE-only argument.
  for(nm in c(".etr_dimweights",".etr_curve",".etr_points","etr_l2_distance")){
    envir[[nm]]<-eval(.pl_expr(src$fast,nm),envir=envir)
  }
  direct<-envir$etr_l2_distance
  envir$etr_l2_distance<-function(a,b,time,dimension_weights=NULL,
                                 python_boundary_mode=FALSE){
    if(!identical(python_boundary_mode,FALSE))
      stop("Only default native-R numerical boundary is compared")
    direct(a,b,time,dimension_weights)
  }
  original<-eval(.pl_expr(src$old,"etr_pairwise_l2"),envir=envir)
  optimized<-eval(.pl_expr(src$fast,"etr_pairwise_l2"),envir=envir)
  oldbody<-paste(deparse(body(original),width.cutoff=500L),collapse="\n")
  newbody<-paste(deparse(body(optimized),width.cutoff=500L),collapse="\n")
  if(!grepl("for \\(i in seq_len\\(n\\)\\)",oldbody) ||
     !grepl("stats::dist",newbody,fixed=TRUE))
    stop("Unexpected archived or optimized algorithm source: refusing benchmark")
  list(baseline=original,optimized=optimized)
}
.pl_independent_ref <- function(x,i,j){
  t<-x$time;dv<-diff(t)
  w<-c(dv[1L]/2L,if(length(dv)>1L)(dv[-1L]+dv[-length(dv)])/2L,
       tail(dv,1L)/2L)
  d<-x$values[i,,,drop=FALSE]-x$values[j,,,drop=FALSE]
  a<-matrix(d,nrow=length(t),ncol=dim(x$values)[3L])
  sqrt(sum(rowSums(a*a)*w))
}
.pl_load_preparation <- function(){
  old<-Sys.getenv("ET_SCI_BENCH_NO_AUTORUN",unset=NA_character_)
  Sys.setenv(ET_SCI_BENCH_NO_AUTORUN="true")
  on.exit(if(is.na(old))Sys.unsetenv("ET_SCI_BENCH_NO_AUTORUN") else
    Sys.setenv(ET_SCI_BENCH_NO_AUTORUN=old))
  if(file.exists("scripts/science_benchmark_multiplatform.R"))
    source("scripts/science_benchmark_multiplatform.R",local=FALSE)
  else
    source(url(paste0(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/",
      .pl_fast_sha,"/scripts/science_benchmark_multiplatform.R")),local=FALSE)
}
.pl_summary <- function(rows){
  df<-do.call(rbind,rows)
  groups<-split(seq_len(nrow(df)),
    paste(df$data_source,df$n_curves,df$n_grid,sep="::"))
  combined<-lapply(groups,function(ix){
    sub<-df[ix,,drop=FALSE]
    base<-sub$elapsed_sec[sub$algorithm=="v0.4.3_nested_loops"]
    opt<-sub$elapsed_sec[sub$algorithm=="development_weighted_dist"]
    if(!length(base)||!length(opt))return(NULL)
    data.frame(source=sub$data_source[[1L]],n_curves=sub$n_curves[[1L]],
      n_grid=sub$n_grid[[1L]],paired_reps=length(base),
      median_baseline_sec=stats::median(base),
      median_optimized_sec=stats::median(opt),
      median_time_ratio=stats::median(base)/stats::median(opt),
      max_numeric_abs_error=max(sub$max_absolute_discrepancy),
      max_reference_abs_error=max(sub$max_independent_pair_error))
  })
  do.call(rbind,Filter(Negate(is.null),combined))
}
sci_benchmark_paired_l2 <- function(
  root=Sys.getenv("ET_SCI_ROOT",file.path(Sys.getenv("USERPROFILE"),
              "Downloads","eyetrajectoriesValidation")),
  source=Sys.getenv("ET_PAIRED_L2_SOURCE","real"),
  sizes=as.integer(strsplit(Sys.getenv("ET_PAIRED_L2_SIZES","250,500,1000"),
                           ",",fixed=TRUE)[[1L]]),
  grids=as.integer(strsplit(Sys.getenv("ET_PAIRED_L2_GRIDS","64,128"),
                           ",",fixed=TRUE)[[1L]]),
  repetitions=as.integer(Sys.getenv("ET_PAIRED_L2_REPS","3")),
  out=tempfile("L2_CONTROLLED_ALGORITHMS_",tmpdir=if(dir.exists(root))root else tempdir()),
  seed=20261117L){
  stopifnot(source %in% c("real","synthetic"),length(sizes)>=1L,
            all(is.finite(sizes)&sizes>=4L),all(grids>=4L),
            repetitions>=1L,repetitions<=10L)
  .pl_load_preparation()
  pair<-.pl_algorithms()
  if(!dir.create(out,recursive=TRUE))stop("Cannot create output directory")
  raw<-if(source=="real").sci_bench_real_input(root,max_rows=200000L) else NULL
  if(source=="real"&&is.null(raw))stop("Real OneStop ZIP not present")
  rows<-list()
  for(n in sizes)for(nt in grids){
    x<-if(source=="real").sci_bench_real(raw,n,nt) else .sci_bench_synth(n,nt)
    if(is.null(x)){
      message("No real input for ",n," curves; recorded NOT_RUN")
      next
    }
    # Verify identity before timing the original or fastpath.
    a<-pair$baseline(x);b<-pair$optimized(x)
    delta<-max(abs(a-b))
    idx<-utils::combn(min(n,10L),2L)
    oracle_diff<-max(vapply(seq_len(ncol(idx)),function(k){
      i<-idx[1L,k];j<-idx[2L,k]
      max(abs(a[i,j]-.pl_independent_ref(x,i,j)),
          abs(b[i,j]-.pl_independent_ref(x,i,j)))
    },numeric(1L)))
    if(!is.finite(delta)||delta>1e-8||!is.finite(oracle_diff)||
       oracle_diff>1e-8)stop("Numerical comparison failed: ",
                             n," curves grid ",nt)
    invisible(gc())
    for(rep in seq_len(repetitions)){
      set.seed(seed+n*100L+nt*10L+rep)
      order<-sample(c("v0.4.3_nested_loops","development_weighted_dist"))
      for(method in order){
        fn<-if(method=="v0.4.3_nested_loops")pair$baseline else pair$optimized
        elapsed<-unname(system.time(invisible(fn(x)))[["elapsed"]])
        rows[[length(rows)+1L]]<-data.frame(
          data_source=if(source=="real")"real_OneStop_normalized" else "synthetic",
          n_curves=n,n_grid=nt,replicate=rep,algorithm=method,
          elapsed_sec=elapsed,max_absolute_discrepancy=delta,
          max_independent_pair_error=oracle_diff,
          installed_version=as.character(utils::packageVersion("eyetrajectories")))
      }
    }
    message("PAIRED_L2_DONE n=",n," grid=",nt,
            " maxabsdiff=",format(delta,digits=3))
  }
  if(!length(rows))stop("No eligible benchmark input constructed")
  raw_df<-do.call(rbind,rows)
  utils::write.csv(raw_df,file.path(out,"paired_l2_repetitions.csv"),row.names=FALSE)
  summary<-.pl_summary(rows)
  utils::write.csv(summary,file.path(out,"paired_l2_summary.csv"),row.names=FALSE)
  notes<-c("# Controlled same-input L2 algorithmic comparison","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("Source mode: ",source,"; installed package version: ",
           as.character(utils::packageVersion("eyetrajectories"))),
    paste0("Original archived source: ",.pl_old_url),
    paste0("Archived R/native-distances.R Git blob: ",.pl_old_blob),
    paste0("Vectorized source: ",.pl_new_url),
    paste0("Vectorized R/native-distances.R Git blob: ",.pl_new_blob),
    "Both exact etr_pairwise_l2 function bodies are evaluated with",
    "one shared native-R helper implementation; archived boundary-mode",
    "FALSE is explicitly shimmed. This is a controlled algorithm",
    "comparison, NOT two fully installed release namespaces.",
    "Both functions receive the SAME trajectory object and reference.",
    "Warmups excluded, algorithm order randomized within repetitions;",
    "max elementwise matrix error and independent trapezoidal oracle checked.",
    "Real OneStop input is normalized-time interpolated fixation data, not",
    "raw eye-tracker samples. No raw data/identifiers written to results.",
    "Time units are per-platform elapsed wall seconds; no machine match.",
    "Actual v0.4.3 tag remains unchanged and still contains nested loops.")
  if(source=="real")notes<-c(notes,paste0("Input archive MD5: ",raw$input_md5),
                            paste0("Eligible input curves: ",raw$eligible),
                            paste0("Input row cap reached: ",raw$row_cap_reached))
  writeLines(notes,file.path(out,"PAIRED_BENCHMARK_PROTOCOL.md"))
  writeLines(capture.output(utils::sessionInfo()),file.path(out,"R_session_info.txt"))
  message("PAIRED_L2_RESULTS=",out)
  invisible(list(output=out,summary=summary,repetitions=raw_df))
}
if(!identical(tolower(Sys.getenv("ET_PAIRED_L2_NO_AUTORUN")),"true"))
  sci_benchmark_paired_l2()
