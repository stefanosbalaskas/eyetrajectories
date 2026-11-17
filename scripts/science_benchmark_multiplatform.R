# Cross-platform OneStop/synthetic numerical benchmark (R only).
# Time repeated warm runs; peakRAM expression peak (not process RSS).
# Linux additionally records /proc/self/status VmHWM high-water process RSS,
# which is an entire-process maximum since launch (NOT run-attributable delta).
# No true portable process-peak claim on Windows/macOS is made.
# source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/science_benchmark_multiplatform.R"))
# ET_SCI_BENCH_NO_AUTORUN=true to load functions only.
# ET_SCI_BENCH_SOURCE=auto|real|synthetic; auto uses local OneStop ZIP if present.
# ET_SCI_BENCH_SIZES=250,500,1000; ET_SCI_BENCH_GRIDS=64,128; ET_SCI_BENCH_REPS=3.

.sci_bench_sizes <- function(value) {
  y<-as.integer(strsplit(value,",",fixed=TRUE)[[1L]])
  if(!length(y)||anyNA(y)||any(y<4L))stop("Invalid positive sizes")
  unique(y)
}
.sci_bench_synth <- function(n,nt,seed=991L){
  set.seed(seed+n+nt)
  t<-seq(0,1,length.out=nt)
  y<-array(0,c(n,nt,2L))
  a<-stats::rnorm(n);b<-stats::rnorm(n)
  for(i in seq_len(n)){
    y[i,,1]<-100+30*sin(2*pi*t)+a[i]*sin(pi*t)+b[i]
    y[i,,2]<-220+20*cos(pi*t)+a[i]*cos(3*pi*t)-b[i]*sin(pi*t)
  }
  eyetrajectories::etr_trajectory_set(t,y,
    curve_ids=paste0("simulation_",seq_len(n)),
    dimension_names=c("x","y"),coordinate_system="synthetic_pixels",
    time_unit="normalized_trial")
}
.sci_bench_real_input <- function(root,max_rows=200000L) {
  zip<-file.path(root,"fixations_Paragraph_repeated.csv.zip")
  if(!file.exists(zip))return(NULL)
  listing<-utils::unzip(zip,list=TRUE)$Name
  member<-listing[basename(listing)=="fixations_Paragraph_repeated.csv"]
  if(length(member)!=1L)stop("OneStop ZIP member not uniquely found")
  con<-unz(zip,member,open="r")
  on.exit(close(con),add=TRUE)
  hdr<-readLines(con,n=1L,warn=FALSE)
  columns<-strsplit(sub("^\ufeff","",hdr),",",fixed=TRUE)[[1L]]
  columns<-gsub('^"|"$',"",columns)
  required<-c("participant_id","TRIAL_INDEX","CURRENT_FIX_START",
              "CURRENT_FIX_X","CURRENT_FIX_Y")
  if(!all(required %in% columns))stop("Unrecognized real OneStop fixation schema")
  classes<-ifelse(columns %in% required,"character","NULL")
  d<-utils::read.table(con,sep=",",header=FALSE,col.names=columns,
    colClasses=classes,nrows=max_rows,fill=TRUE,quote='"',
    comment.char="",check.names=FALSE,stringsAsFactors=FALSE)
  nrows<-nrow(d)
  to_number<-function(x)suppressWarnings(as.numeric(x))
  tm<-to_number(d$CURRENT_FIX_START)
  xx<-to_number(d$CURRENT_FIX_X)
  yy<-to_number(d$CURRENT_FIX_Y)
  who<-as.character(d$participant_id);trial<-as.character(d$TRIAL_INDEX)
  good<-is.finite(tm)&is.finite(xx)&is.finite(yy)&
    !is.na(who)&nzchar(who)&!is.na(trial)&nzchar(trial)
  ix<-which(good)
  keys<-paste(who[ix],trial[ix],sep="\r")
  groups<-split(ix,keys)
  selected<-list()
  for(key in sort(names(groups))){
    ids<-groups[[key]]
    ids<-ids[order(tm[ids],seq_along(ids))]
    ids<-ids[!duplicated(tm[ids])]
    if(length(ids)>=24L && diff(range(tm[ids]))>0)
      selected[[length(selected)+1L]]<-ids
  }
  list(time=tm,x=xx,y=yy,selected=selected,
       eligible=length(selected),valid_rows=sum(good),
       rows_read=nrows,row_cap_reached=nrows>=max_rows,
       input_md5=unname(tools::md5sum(zip)))
}
.sci_bench_real <- function(raw,n,nt) {
  if(raw$eligible<n)return(NULL)
  t<-seq(0,1,length.out=nt)
  y<-array(0,c(n,nt,2L))
  for(i in seq_len(n)){
    ids<-raw$selected[[i]]
    ti<-raw$time[ids]
    tn<-(ti-min(ti))/(max(ti)-min(ti))
    y[i,,1]<-stats::approx(tn,raw$x[ids],xout=t,rule=2,ties="ordered")$y
    y[i,,2]<-stats::approx(tn,raw$y[ids],xout=t,rule=2,ties="ordered")$y
  }
  eyetrajectories::etr_trajectory_set(t,y,
    curve_ids=sprintf("opaque_%04d",seq_len(n)),
    dimension_names=c("x","y"),coordinate_system="pixels",
    time_unit="within_trial_normalized")
}
.sci_linux_peak_rss_kib <- function() {
  if(Sys.info()[["sysname"]]!="Linux")return(NA_real_)
  p<-"/proc/self/status"
  if(!file.exists(p))return(NA_real_)
  z<-grep("^VmHWM:",readLines(p,warn=FALSE),value=TRUE)
  if(!length(z))return(NA_real_)
  as.numeric(gsub("[^0-9]","",z[[1L]]))
}
.sci_bench_once <- function(fun) {
  # 'peakRAM' estimates max RAM allocated within expression, not peak
  # resident set size. Each configured invocation is a separate repetition.
  if(requireNamespace("peakRAM",quietly=TRUE)){
    p<-peakRAM::peakRAM(fun())
    return(list(time=as.numeric(p$Elapsed_Time_sec[[1L]]),
       expression_peak_MiB=as.numeric(p$Peak_RAM_Used_MiB[[1L]]),
       memory_method="peakRAM_expression"))
  }
  timed<-system.time(fun())
  list(time=unname(timed[["elapsed"]]),expression_peak_MiB=NA_real_,
       memory_method="NOT_MEASURED_peakRAM_not_installed")
}
sci_benchmark_multiplatform <- function(
  root=Sys.getenv("ET_SCI_ROOT",file.path(Sys.getenv("USERPROFILE"),
                   "Downloads","eyetrajectoriesValidation")),
  source_mode=Sys.getenv("ET_SCI_BENCH_SOURCE","auto"),
  sizes=.sci_bench_sizes(Sys.getenv("ET_SCI_BENCH_SIZES","250,500,1000")),
  grids=.sci_bench_sizes(Sys.getenv("ET_SCI_BENCH_GRIDS","64,128")),
  repetitions=as.integer(Sys.getenv("ET_SCI_BENCH_REPS","3")),
  out=tempfile("SCIENCE_BENCH_MULTIPLATFORM_")){
  stopifnot(source_mode %in% c("auto","real","synthetic"),
            length(repetitions)==1L,repetitions>=1L,repetitions<=10L)
  if(!dir.create(out,recursive=TRUE))stop("Cannot create output folder")
  path<-file.path(root,"fixations_Paragraph_repeated.csv.zip")
  real<-source_mode=="real" ||
    (source_mode=="auto" && file.exists(path))
  raw<-if(real).sci_bench_real_input(root) else NULL
  if(real && is.null(raw))stop("Explicit real-data benchmark source absent")
  rows<-list()
  for(n in sizes)for(nt in grids){
    obj<-if(real).sci_bench_real(raw,n,nt) else
      .sci_bench_synth(n,nt)
    if(is.null(obj)){
      rows[[length(rows)+1L]]<-data.frame(
        source="real_OneStop_fixation",n_curves=n,n_grid=nt,
        function_name="etr_pairwise_l2",replicate=NA_integer_,
        elapsed_sec=NA_real_,expression_peak_MiB=NA_real_,
        linux_process_VmHWM_kib=NA_real_,
        status="NOT_RUN_NOT_ENOUGH_CURVES",memory_method="NOT_RUN")
      next
    }
    for(f in c("etr_pairwise_l2","etr_fit_mfpca")){
      fun<-switch(f,etr_pairwise_l2=function()
        eyetrajectories::etr_pairwise_l2(obj),
        etr_fit_mfpca=function()
          eyetrajectories::etr_fit_mfpca(obj,n_components=2L))
      invisible(fun()) # warmup; exclude cold compilation/startup
      for(rep in seq_len(repetitions)){
        result<-.sci_bench_once(fun)
        rows[[length(rows)+1L]]<-data.frame(
          source=if(real)"real_OneStop_fixation" else "synthetic",
          n_curves=n,n_grid=nt,function_name=f,replicate=rep,
          elapsed_sec=result$time,
          expression_peak_MiB=result$expression_peak_MiB,
          linux_process_VmHWM_kib=.sci_linux_peak_rss_kib(),
          status="MEASURED",memory_method=result$memory_method)
      }
    }
    message("BENCHMARK_DONE curves=",n," grid=",nt)
  }
  results<-do.call(rbind,rows)
  utils::write.csv(results,file.path(out,"benchmark_repetitions.csv"),
                   row.names=FALSE,na="")
  subset<-results[results$status=="MEASURED",,drop=FALSE]
  groups<-split(seq_len(nrow(subset)),
     paste(subset$source,subset$n_curves,subset$n_grid,
           subset$function_name,sep=":"))
  summary<-do.call(rbind,lapply(groups,function(ix){
    z<-subset[ix,,drop=FALSE]
    data.frame(source=z$source[1],n_curves=z$n_curves[1],
      n_grid=z$n_grid[1],function_name=z$function_name[1],
      median_sec=stats::median(z$elapsed_sec),
      min_sec=min(z$elapsed_sec),max_sec=max(z$elapsed_sec),
      max_expression_peak_MiB=if(all(is.na(z$expression_peak_MiB)))
        NA_real_ else max(z$expression_peak_MiB,na.rm=TRUE),
      linux_process_VmHWM_kib=if(all(is.na(z$linux_process_VmHWM_kib)))
        NA_real_ else max(z$linux_process_VmHWM_kib,na.rm=TRUE),
      replicates=nrow(z))
  }))
  utils::write.csv(summary,file.path(out,"benchmark_summary.csv"),
                   row.names=FALSE,na="")
  notes<-c("# Cross-platform R performance, explicit memory semantics","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("System: ",Sys.info()[["sysname"]]," / ",R.version.string),
    paste0("Data source: ",if(real)"REAL OneStop fixation CSV" else
      "SYNTHETIC trajectories"),
    paste0("Eligible real curves: ",if(real)raw$eligible else "NOT_APPLICABLE"),
    paste0("Real input row cap: ",if(real)raw$row_cap_reached else "NOT_APPLICABLE"),
    paste0("Real archive MD5: ",if(real)raw$input_md5 else "NOT_APPLICABLE"),
    "",
    "R-only native functions measured after one warmup with repeated runtimes.",
    "peakRAM Peak_RAM_Used_MiB reports expression allocation peak, not a",
    "portable measurement of peak resident process RSS. Linux /proc/self/status",
    "VmHWM is whole-process high-water RSS since process start, not per-call",
    "attributable peak. Windows/macOS VmHWM is NOT_MEASURED.",
    "No cross-platform CPU standardization, cold-start timing, competitor",
    "package speed comparison, energy or numerical convergence certification.",
    "Two corpora remain distinct; PoTeC correction is not used as OneStop input.")
  writeLines(notes,file.path(out,"BENCHMARK_SCOPE.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(out,"R_session_info.txt"))
  message("BENCHMARK_RESULTS=",out)
  invisible(summary)
}
if(!identical(tolower(Sys.getenv("ET_SCI_BENCH_NO_AUTORUN")),"true"))
  sci_benchmark_multiplatform()
