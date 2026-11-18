# Real OneStop exact-installed R release-candidate benchmark. R-only.
#
# Source the script from its immutable GitHub candidate commit, then run:
# etr_qualify_real_onestop_l2(
#   root=file.path(Sys.getenv("USERPROFILE"),"Downloads","eyetrajectoriesValidation"),
#   candidate_sha="<qualified v0.4.4 candidate exact commit SHA>"
# )
#
# Operates on original zipped OneStop fixation CSV, locally. DOES NOT upload
# the ZIP, any reader IDs, raw gaze samples, personal information or full input
# arrays. Outputs contain only opaque synthetic curve IDs and aggregates.
# A separate installed library is created for each source revision.
# Existing installed eyetrajectories packages are not overwritten.
# Requires GitHub download access and the Windows R build toolchain if needed.

.etr_rc_validate_sha <- function(x) {
  .stop <- function()stop("candidate_sha must be a 40-character Git SHA")
  if(length(x)!=1L || is.na(x) || !grepl("^[0-9a-f]{40}$",x)) .stop()
  invisible(x)
}
.etr_rc_checked_status <- function(cmd,args,kind) {
  out <- suppressWarnings(tryCatch(system2(cmd,args=args,
    stdout=TRUE,stderr=TRUE),
    error=function(e)stop(kind,": ",conditionMessage(e))))
  stat <- attr(out,"status")
  if(!is.null(stat) && stat!=0L)
    stop(kind," failed (",stat,"): ",paste(tail(out,35L),collapse="\n"))
  out
}
.etr_rc_source_archive <- function(ref,dir) {
  stopifnot(dir.exists(dir))
  # Branch names are forbidden: source identity must be pinned to full SHA
  # (or the published v0.4.3 source tag for historical baseline).
  stopifnot(identical(ref,"v0.4.3") ||
              (length(ref)==1L&&grepl("^[0-9a-f]{40}$",ref)))
  archive<-file.path(dir,paste0(ref,".zip"))
  url<-paste0("https://github.com/stefanosbalaskas/eyetrajectories/archive/",
              ref,".zip")
  utils::download.file(url,archive,mode="wb",quiet=FALSE)
  if(!file.exists(archive)||file.info(archive)$size<100000)
    stop("Source download incomplete: ",ref)
  listing<-utils::unzip(archive,list=TRUE)
  tops<-unique(sub("/.*$","",listing$Name))
  tops<-tops[nzchar(tops)]
  if(length(tops)!=1L)stop("Unexpected source-archive structure")
  utils::unzip(archive,exdir=dir)
  source<-file.path(dir,tops)
  stopifnot(file.exists(file.path(source,"DESCRIPTION")))
  list(path=source,archive=archive,md5=unname(tools::md5sum(archive)))
}
.etr_rc_install_isolated <- function(source,lib,version) {
  dir.create(lib,recursive=TRUE,showWarnings=FALSE)
  rcmd<-if(.Platform$OS.type=="windows"){
     file.path(R.home("bin"),"R.exe")
  }else file.path(R.home("bin"),"R")
  stopifnot(file.exists(rcmd))
  out<-.etr_rc_checked_status(rcmd,c("CMD","INSTALL",
          paste0("--library=",shQuote(normalizePath(lib,mustWork=TRUE))),
          shQuote(normalizePath(source,mustWork=TRUE))),"R CMD INSTALL")
  package_dcf<-file.path(lib,"eyetrajectories","DESCRIPTION")
  if(!file.exists(package_dcf))stop("No installed package in isolated library")
  observed<-as.character(read.dcf(package_dcf,fields="Version")[1,1])
  if(observed!=version)stop("Installed package mismatch: ",observed,
                            " versus ",version)
  invisible(out)
}
.etr_rc_onestop_read <- function(root,max_rows=200000L) {
  zip<-file.path(root,"fixations_Paragraph_repeated.csv.zip")
  if(!file.exists(zip))stop("Required original OneStop ZIP missing: ",zip)
  md5<-unname(tools::md5sum(zip))
  if(!identical(tolower(md5),"650d93a8c73af6a9b3ca19a7c4e542fb"))
    stop("OneStop ZIP has changed from the authenticated baseline. MD5: ",md5,
         " (no benchmark executed)")
  entries<-utils::unzip(zip,list=TRUE)$Name
  member<-entries[basename(entries)=="fixations_Paragraph_repeated.csv"]
  if(length(member)!=1L)stop("Exactly one OneStop fixation CSV required")
  con<-unz(zip,member,open="r")
  on.exit(close(con),add=TRUE)
  first<-readLines(con,n=1L,warn=FALSE)
  columns<-strsplit(sub("^\ufeff","",first),",",fixed=TRUE)[[1L]]
  columns<-gsub('^"|"$',"",columns)
  keep<-c("participant_id","TRIAL_INDEX","CURRENT_FIX_START",
          "CURRENT_FIX_X","CURRENT_FIX_Y")
  if(!all(keep%in%columns))stop("Unexpected OneStop CSV column schema")
  cl<-ifelse(columns%in%keep,"character","NULL")
  d<-utils::read.table(con,sep=",",header=FALSE,
        col.names=columns,colClasses=cl,nrows=max_rows,
        fill=TRUE,quote='"',comment.char="",check.names=FALSE,
        stringsAsFactors=FALSE)
  nrows<-nrow(d)
  if(nrows>=max_rows)stop("OneStop fixed row cap reached; not a full input")
  num<-function(x)suppressWarnings(as.numeric(x))
  tm<-num(d$CURRENT_FIX_START)
  xx<-num(d$CURRENT_FIX_X)
  yy<-num(d$CURRENT_FIX_Y)
  who<-as.character(d$participant_id)
  trial<-as.character(d$TRIAL_INDEX)
  valid<-is.finite(tm)&is.finite(xx)&is.finite(yy)&
    !is.na(who)&nzchar(who)&!is.na(trial)&nzchar(trial)
  idx<-which(valid)
  keys<-paste(who[idx],trial[idx],sep="\r")
  groups<-split(idx,keys)
  selected<-list()
  for(key in sort(names(groups))){
    ix<-groups[[key]]
    ix<-ix[order(tm[ix],seq_along(ix))]
    ix<-ix[!duplicated(tm[ix])]
    if(length(ix)>=24L&&diff(range(tm[ix]))>0)
      selected[[length(selected)+1L]]<-ix
  }
  if(length(selected)<1000L)
    stop("Fewer than 1000 eligible complete OneStop trajectories")
  list(time=tm,x=xx,y=yy,selected=selected,
       eligible=length(selected),md5=md5,valid=sum(valid),
       rows=nrows)
}
.etr_rc_onestop_grid <- function(raw,n,nt){
  stopifnot(raw$eligible>=n,nt>=4L)
  t<-seq(0,1,length.out=nt)
  a<-array(0,c(n,nt,2L))
  for(i in seq_len(n)){
    ids<-raw$selected[[i]]
    ti<-raw$time[ids]
    tn<-(ti-min(ti))/(max(ti)-min(ti))
    a[i,,1]<-stats::approx(tn,raw$x[ids],xout=t,
                           rule=2,ties="ordered")$y
    a[i,,2]<-stats::approx(tn,raw$y[ids],xout=t,
                           rule=2,ties="ordered")$y
  }
  stopifnot(all(is.finite(a)))
  # Store no participant, trial, raw timestamp or archive pathname.
  list(time=t,values=a,curve_ids=sprintf("opaque_%04d",seq_len(n)))
}
.etr_rc_independent_trapezoid <- function(raw,i,j) {
  t<-raw$time;w<-diff(t)
  qw<-c(w[1]/2,
         if(length(w)>1L)(w[-1]+w[-length(w)])/2,
         tail(w,1)/2)
  d<-raw$values[i,,]-raw$values[j,,]
  sqrt(sum(rowSums(d*d)*qw))
}
.etr_rc_child <- function(args) {
  if(length(args)!=4L)stop("Child requires lib,version,input,prefix")
  lib<-normalizePath(args[[1L]],mustWork=TRUE)
  version<-args[[2L]]
  xraw<-readRDS(args[[3L]])
  # Only the specified isolated installation is placed on the search path.
  suppressPackageStartupMessages(library(eyetrajectories,
      lib.loc=lib,character.only=FALSE))
  stopifnot(as.character(utils::packageVersion("eyetrajectories",
       lib.loc=lib))==version)
  x<-eyetrajectories::etr_trajectory_set(
    xraw$time,xraw$values,curve_ids=xraw$curve_ids,
    dimension_names=c("x","y"),coordinate_system="pixels",
    time_unit="within_trial_normalized")
  eyetrajectories::etr_validate(x,require_complete=TRUE)
  n<-dim(x$values)[1L]
  batch<-if(version=="0.4.4") {
    if(n<=500L)30L else 8L
  }else 1L
  gc()
  seconds_total<-unname(system.time({
    for(i in seq_len(batch))
      result<-eyetrajectories::etr_pairwise_l2(x)
  })[["elapsed"]])
  seconds<-seconds_total/batch
  stopifnot(is.finite(seconds),seconds>0,all(is.finite(result)),
    identical(dimnames(result),list(x$curve_ids,x$curve_ids)))
  rss<-NA_real_
  rss_method<-"NOT_MEASURED"
  if(requireNamespace("bench",quietly=TRUE)){
    v<-tryCatch(bench::bench_process_memory(),error=function(e)NULL)
    if(!is.null(v)&&"max"%in%names(v)){
      z<-as.numeric(v[["max"]])/1024^2
      if(is.finite(z)&&z>0&&z<1e5){
        rss<-z
        rss_method<-"process_peak_since_Rscript_start_not_per_operation"
      }
    }
  }
  prefix<-args[[4L]]
  dir.create(dirname(prefix),recursive=TRUE,showWarnings=FALSE)
  saveRDS(result,paste0(prefix,".rds"),version=3L)
  utils::write.csv(data.frame(version=version,n=n,grid=length(x$time),
      seconds=seconds,batch=batch,total=seconds_total,
      process_peak_RSS_mib=rss,process_memory_method=rss_method),
     paste0(prefix,".csv"),row.names=FALSE,na="")
  cat("RC_ONESTOP_CHILD_PASS ",version," ",n," ",length(x$time),"\n",sep="")
}
etr_qualify_real_onestop_l2 <- function(
  root=file.path(Sys.getenv("USERPROFILE"),"Downloads",
                 "eyetrajectoriesValidation"),
  candidate_sha=Sys.getenv("ET_RC_CANDIDATE_SHA"),
  sizes=c(250L,500L,1000L),grids=c(64L,128L),
  repetitions=3L,max_rows=200000L){
  .etr_rc_validate_sha(candidate_sha)
  stopifnot(dir.exists(root),identical(sort(sizes),c(250L,500L,1000L)),
    identical(sort(grids),c(64L,128L)),repetitions>=2L,repetitions<=5L)
  if(!requireNamespace("reticulate",quietly=TRUE))
    stop("Installed stable source dependency reticulate is required")
  archive<-.etr_rc_onestop_read(root,max_rows)
  folder<-tempfile("EXACT_INSTALLED_ONESTOP_RC043_",tmpdir=root)
  dir.create(folder)
  srcs<-file.path(folder,"isolated_sources");dir.create(srcs)
  baseline<-.etr_rc_source_archive("v0.4.3",srcs)
  candidate<-.etr_rc_source_archive(candidate_sha,srcs)
  libs<-file.path(folder,"isolated_libraries",c("baseline","candidate"))
  .etr_rc_install_isolated(baseline$path,libs[[1L]],"0.4.3")
  .etr_rc_install_isolated(candidate$path,libs[[2L]],"0.4.4")
  testscript<-file.path(folder,"rc_onestop_runner.R")
  # Obtain this same program from exact candidate revision; source differs
  # only in execution flags, and provenance records the fetched SHA.
  url<-paste0("https://raw.githubusercontent.com/stefanosbalaskas/",
     "eyetrajectories/",candidate_sha,
     "/benchmarks/rc_l2_onestop_real_release_audit.R")
  utils::download.file(url,testscript,mode="wb",quiet=TRUE)
  if(!file.exists(testscript)||file.info(testscript)$size<8000)
    stop("Cannot fetch pinned child audit source")
  executable<-Sys.which("Rscript")
  if(!nzchar(executable))stop("Rscript executable not available")
  rows<-list();summary<-list()
  for(n in sizes)for(g in grids){
    input<-file.path(folder,sprintf("onestop_n%d_grid%d.rds",n,g))
    x<-.etr_rc_onestop_grid(archive,n,g)
    saveRDS(x,input,version=3L)
    for(rep in seq_len(repetitions)){
      order<-if(rep%%2L) c("baseline","candidate")
             else c("candidate","baseline")
      pair<-list()
      for(mode in order){
        v<-if(mode=="baseline")"0.4.3" else "0.4.4"
        lib<-if(mode=="baseline")libs[[1L]] else libs[[2L]]
        output<-file.path(folder,"matrices",
                        sprintf("n%d_g%d_rep%d_%s",n,g,rep,mode))
        args<-c("--vanilla",shQuote(testscript),"--child",
                shQuote(lib),v,shQuote(input),shQuote(output))
        result<-.etr_rc_checked_status(executable,args,"Pinned installed R benchmark")
        metrics<-utils::read.csv(paste0(output,".csv"))
        stopifnot(nrow(metrics)==1L,metrics$version==v,
                  metrics$n==n,metrics$grid==g)
        pair[[mode]]<-readRDS(paste0(output,".rds"))
        rows[[length(rows)+1L]]<-data.frame(n=n,grid=g,
           repetition=rep,installed_version=v,mode=mode,
           elapsed_s=metrics$seconds,batch_count=metrics$batch,
           process_peak_RSS_mib=metrics$process_peak_RSS_mib,
           process_memory_method=metrics$process_memory_method)
        message(sprintf("REAL_QUALIFIED %d curves × %d grid, rep %d, %s: %.4fs",
                 n,g,rep,mode,metrics$seconds))
      }
      b<-pair$baseline;f<-pair$candidate
      stopifnot(identical(dim(b),dim(f)),
          identical(dimnames(b),dimnames(f)),
          all(diag(b)==0),all(diag(f)==0))
      diff<-max(abs(b-f))
      pairs<-utils::combn(seq_len(min(9L,n)),2L)
      oracle<-max(vapply(seq_len(ncol(pairs)),function(k){
         i<-pairs[1,k];j<-pairs[2,k]
         truth<-.etr_rc_independent_trapezoid(x,i,j)
         max(abs(b[i,j]-truth),abs(f[i,j]-truth))
      },numeric(1L)))
      if(!is.finite(diff)||!is.finite(oracle)||
         diff>1e-8||oracle>1e-8)
        stop("OneStop installed numerical oracle failed: n=",n," g=",g)
      summary[[length(summary)+1L]]<-data.frame(n=n,grid=g,
        repetition=rep,max_abs_error=diff,independent_oracle_max=oracle)
    }
  }
  percall<-do.call(rbind,rows)
  numerics<-do.call(rbind,summary)
  grouped<-split(percall,paste(percall$n,percall$grid,sep="_"))
  stats<-do.call(rbind,lapply(grouped,function(x){
    old<-stats::median(x$elapsed_s[x$mode=="baseline"])
    new<-stats::median(x$elapsed_s[x$mode=="candidate"])
    data.frame(n=x$n[1],grid=x$grid[1],
       median_old_s=old,median_candidate_s=new,
       ratio_of_medians=old/new)
  }))
  utils::write.csv(percall,file.path(folder,"real_candidate_repetitions.csv"),
    row.names=FALSE)
  utils::write.csv(numerics,file.path(folder,"real_candidate_numerical_checks.csv"),
    row.names=FALSE)
  utils::write.csv(stats,file.path(folder,"real_candidate_summary.csv"),
    row.names=FALSE)
  writeLines(c("# Real OneStop: exact installed v0.4.3 versus candidate",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("Qualified candidate source revision: ",candidate_sha),
    paste0("v0.4.3 downloaded source ZIP MD5: ",baseline$md5),
    paste0("Candidate downloaded source ZIP MD5: ",candidate$md5),
    paste0("Unmodified original OneStop ZIP MD5: ",archive$md5),
    paste0("OneStop complete eligible trial groups: ",archive$eligible),
    paste0("Rows read: ",archive$rows,"; valid rows: ",archive$valid),
    "Input is REAL repeated-paragraph fixation CSV, not raw 1000Hz samples.",
    "Common 0–1 within-trial grid uses declared interpolation.",
    "No participant IDs are exported; all trial IDs replaced by opaque labels.",
    "Each comparator was genuinely installed in an isolated R library.",
    "Each execution happened in a separate Rscript process.",
    "Short fast operations timed with per-call batch averages.",
    "Process RSS, when available, is a whole-process high-water mark,",
    "NOT attributable solely to the matrix operation.",
    "Exactly 3 repeat measurements per method and grid by default.",
    "Every paired run compared entire matrices and an independent trapezoid oracle.",
    "No raw source ZIP, underlying gaze CSV or per-trial arrays uploaded.",
    "This method-specific benchmark is not a general scientific certification."),
    file.path(folder,"REAL_ONESTOP_RELEASE_AUDIT.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(folder,"R_session_info.txt"))
  message("EXACT_REAL_ONESTOP_INSTALLED_RC_L2_PASS=",folder)
  invisible(list(folder=folder,summary=stats,checks=numerics))
}
if(length(commandArgs(trailingOnly=TRUE))>0L&&
   identical(commandArgs(trailingOnly=TRUE)[[1L]],"--child"))
  .etr_rc_child(tail(commandArgs(trailingOnly=TRUE),-1L))
