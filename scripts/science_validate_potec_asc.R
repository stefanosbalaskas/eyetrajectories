# PoTeC ASC source-event integrity (R only, read-only).
# Data provenance: author PoTeC .asc = original EyeLink events; fixation TSVs
# are manually corrected and may be deleted/reindexed, without pixel coords.
# These outputs do NOT assert one-to-one equivalence to corrected fixations.
# source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/science_validate_potec_asc.R"))
# ET_SCI_ROOT: ZIP directory. ET_SCI_ASC_MAX_LINES: 200000 (0 for full files).
# ET_SCI_ASC_MAX_FILES: 78. ET_SCI_ASC_NO_AUTORUN=true: definitions only.

.sci_asc_members <- function(zip) {
  n <- utils::unzip(zip, list=TRUE)$Name
  n[!is.na(n) & nzchar(n) & !grepl("/$",n) &
      !grepl("(^|/)__MACOSX(/|$)",n,ignore.case=TRUE) &
      grepl("\\.asc$",n,ignore.case=TRUE)]
}
.sci_asc_analyze_lines <- function(lines) {
  starts <- grepl("(^|[[:space:]])SYNCTIME[._]sentence([[:space:]]|$)",lines)
  stops <- grepl("sentence[._]STOP([[:space:]]|$)",lines)
  event_type <- vapply(strsplit(trimws(lines),"[[:space:]]+"),
                       function(tok) if(length(tok))tok[1L] else "",character(1))
  count <- function(token) sum(event_type==token)
  ef <- lines[event_type=="EFIX"]
  er <- regexec("^EFIX[[:space:]]+[LR][[:space:]]+([0-9]+)[[:space:]]+([0-9]+)[[:space:]]+([0-9]+)",ef)
  mt <- regmatches(ef,er)
  valid <- lengths(mt)==4L
  timing <- if(any(valid))do.call(rbind,lapply(mt[valid],function(z)
    as.numeric(z[2:4]))) else matrix(numeric(),0L,3L)
  if(length(timing))timing<-matrix(timing,ncol=3L)
  broken <- if(nrow(timing))sum(timing[,2L]<timing[,1L] |
          abs(timing[,3L]-(timing[,2L]-timing[,1L]))>1) else 0L
  samples <- lines[grepl("^[[:space:]]*[0-9]+[[:space:]]",lines)]
  sample_times <- suppressWarnings(as.numeric(
    sub("^\\s*([0-9]+).*","\\1",samples)))
  sample_times <- sample_times[is.finite(sample_times)]
  c(asc_lines=length(lines),sample_lines=length(sample_times),
    sample_time_reversals=if(length(sample_times)>1L)
       sum(diff(sample_times)<0) else 0L,
    sentence_start_markers=sum(starts),
    sentence_stop_markers=sum(stops),
    EFIX=count("EFIX"),EFIX_parsed=sum(valid),EFIX_time_issues=broken,
    SFIX=count("SFIX"),SSACC=count("SSACC"),ESACC=count("ESACC"),
    SBLINK=count("SBLINK"),EBLINK=count("EBLINK"),
    MSG=count("MSG"),START=count("START"),END=count("END"))
}
.sci_asc_member <- function(zip,member,max_lines=200000L) {
  con<-tryCatch(unz(zip,member,open="r"),error=function(e)e)
  if(inherits(con,"error"))return(list(status="READ_ERROR",detail=conditionMessage(con)))
  on.exit(close(con),add=TRUE)
  chunk_size<-20000L; total<-0L
  event_counts<-NULL
  # streaming chunk parser; timestamp reversals across chunk boundaries
  last_timestamp<-NA_real_
  for(chunk_index in seq_len(100000L)){
    next_n<-if(max_lines==0L)chunk_size else min(chunk_size,max_lines-total)
    if(next_n<=0L)break
    lines<-tryCatch(readLines(con,n=next_n,warn=FALSE),error=function(e)e)
    if(inherits(lines,"error"))
      return(list(status="READ_ERROR",detail=conditionMessage(lines)))
    if(!length(lines))break
    counts<-.sci_asc_analyze_lines(lines)
    times<-suppressWarnings(as.numeric(sub("^\\s*([0-9]+).*","\\1",
       lines[grepl("^[[:space:]]*[0-9]+[[:space:]]",lines)])))
    times<-times[is.finite(times)]
    if(length(times)&&is.finite(last_timestamp))
      counts["sample_time_reversals"]<-counts["sample_time_reversals"]+
        as.integer(times[1L]<last_timestamp)
    if(length(times))last_timestamp<-tail(times,1L)
    if(is.null(event_counts))event_counts<-counts else
      event_counts<-event_counts+counts
    total<-total+length(lines)
    if(length(lines)<next_n)break
  }
  if(is.null(event_counts))event_counts<-.sci_asc_analyze_lines(character())
  # Hitting cap does not prove whether EOF was reached.
  cap_reached<-max_lines>0L && total>=max_lines
  c(list(status="READ",detail="",line_cap_reached=cap_reached),
    as.list(event_counts))
}
sci_validate_potec_asc <- function(
  root=Sys.getenv("ET_SCI_ROOT",file.path(Sys.getenv("USERPROFILE"),
                                         "Downloads","eyetrajectoriesValidation")),
  max_files=as.integer(Sys.getenv("ET_SCI_ASC_MAX_FILES","78")),
  max_lines=as.integer(Sys.getenv("ET_SCI_ASC_MAX_LINES","200000"))) {
  stopifnot(dir.exists(root),length(max_files)==1L,is.finite(max_files),
            max_files>=1L,length(max_lines)==1L,is.finite(max_lines),max_lines>=0L)
  zip<-file.path(root,"asc_files.zip")
  if(!file.exists(zip))stop("ASC source ZIP not found: ",zip)
  members<-.sci_asc_members(zip)
  if(!length(members))stop("No ASC members found")
  selected<-head(members,max_files)
  out<-tempfile("POTEC_ASC_SOURCE_INTEGRITY_",tmpdir=root)
  if(!dir.create(out))stop("Cannot create evidence output")
  rows<-vector("list",length(selected))
  for(i in seq_along(selected)) {
    rows[[i]]<-c(list(file_index=i),.sci_asc_member(zip,selected[[i]],max_lines))
    if(i%%10L==0L)message("ASC inspected ",i,"/",length(selected))
  }
  columns<-unique(unlist(lapply(rows,names),use.names=FALSE))
  df<-do.call(rbind,lapply(rows,function(r){
    x<-as.list(rep(NA,length(columns)));names(x)<-columns
    for(n in names(r))x[[n]]<-r[[n]]
    as.data.frame(x,stringsAsFactors=FALSE,check.names=FALSE)
  }))
  utils::write.csv(df,file.path(out,"asc_source_events.csv"),
                   row.names=FALSE,na="")
  all_read<-all(df$status=="READ")
  capped<-sum(df$line_cap_reached %in% TRUE)
  parse_issues<-sum(as.numeric(df$EFIX)-as.numeric(df$EFIX_parsed),na.rm=TRUE)
  duration_issues<-sum(as.numeric(df$EFIX_time_issues),na.rm=TRUE)
  reversal<-sum(as.numeric(df$sample_time_reversals),na.rm=TRUE)
  md<-c("# PoTeC raw ASC source integrity — bounded audit","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),"",
    paste0("ASC files enumerated: ",length(members),
           "; inspected: ",length(selected),"; all read: ",all_read,"."),
    paste0("Files at line cap: ",capped,
           "; max lines per member: ",max_lines," (0 means EOF)."),
    paste0("Unparsed EFIX event timings: ",parse_issues,
           "; malformed duration/window values: ",duration_issues,"."),
    paste0("Backwards sample-time transitions: ",reversal,
           " (investigate recording resets before interpretation)."),
    "",
    "Source-author pipeline: original ASC -> one-sample-per-line raw TSV ->",
    "Data Viewer fixation report -> per-reader uncorrected fixations ->",
    "manual vertical drift correction/remapping/deletion/reindexing ->",
    "published corrected fixations and scanpaths.",
    "",
    "**NOT AN ASC-to-CORRECTED-FIXATION AGREEMENT TEST.**",
    "The supplied corrected PoTeC fixations omit original pixel coordinates,",
    "and author correction can alter event-to-character mapping and row identity.",
    "There is no valid exact raw-to-corrected numerical oracle without the",
    "uncorrected fixation report, source stage alignment and correction records.",
    "",
    "ASC reader IDs may differ from derived files (source reader 21 maps to 0).",
    "Published raw/uncorrected trial counts can differ from 900 corrected trials;",
    "never interpret that alone as missing data.",
    "",
    "No raw samples, participant IDs or source ZIP bytes written to results.",
    "No claim of eye-tracker calibration or external fixation ground truth.")
  writeLines(md,file.path(out,"ASC_SCOPE_REPORT.md"))
  writeLines(capture.output(utils::sessionInfo()),file.path(out,"R_session_info.txt"))
  message("POTEC_ASC_SOURCE_AUDIT_FINISHED=",out)
  invisible(list(folder=out,evidence=df))
}
if(!identical(tolower(Sys.getenv("ET_SCI_ASC_NO_AUTORUN")),"true"))
  sci_validate_potec_asc()
