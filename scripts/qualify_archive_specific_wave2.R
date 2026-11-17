# eyetrajectories — Archive-specific OneStop / scanpath quality audit (Wave 2)
# R only, privacy-preserving aggregated output. Source ZIPs never modified.
# Usage: source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/qualify_archive_specific_wave2.R"))
# Optional env: ET_WAVE2_ROOT, ET_WAVE2_MAX_UNITS (default 900),
# ET_WAVE2_MAX_ROWS (default 30000), ET_WAVE2_ASC_FILES (default 3).
# Do not infer that the scanpath-family dataset and OneStop CSVs have matching
# participant identities; crosswalks below are WITHIN the three TSV archive families.

.w2_zip_members <- function(zip, extension = "\\.(csv|tsv|asc)$") {
  if (!file.exists(zip)) return(character())
  x <- tryCatch(utils::unzip(zip, list = TRUE)$Name, error = function(e) character())
  x[!is.na(x) & nzchar(x) &
      !grepl("/$", x) & !grepl("(^|/)__MACOSX(/|$)", x, ignore.case = TRUE) &
      !grepl("(^|/)\\._[^/]*$", x) &
      grepl(extension, x, ignore.case = TRUE)]
}

.w2_trim_header <- function(line, sep) {
  # Preserve exact original case; R is case sensitive.
  v <- strsplit(sub("^\ufeff", "", line), sep, fixed = TRUE)[[1L]]
  gsub('^"|"$', "", v)
}

.w2_read_subset <- function(zip, member, keep, sep, row_cap) {
  if (is.null(member) || !length(member) || is.na(member) || !nzchar(member))
    return(list(status="ABSENT_MEMBER", data=NULL, fields=character(), capped=FALSE))
  con <- tryCatch(unz(zip, member, open="r"), error=function(e) e)
  if (inherits(con, "error")) return(list(status=paste0("OPEN_ERROR: ", conditionMessage(con)),
                                            data=NULL, fields=character(), capped=FALSE))
  on.exit(close(con), add=TRUE)
  header <- tryCatch(readLines(con, n=1L, warn=FALSE), error=function(e) character())
  if (length(header)!=1L) return(list(status="EMPTY_OR_BAD_HEADER", data=NULL,
                                       fields=character(), capped=FALSE))
  fields <- .w2_trim_header(header, sep)
  if (anyDuplicated(fields) || !length(fields))
    return(list(status="DUPLICATE_OR_EMPTY_HEADER", data=NULL,
                fields=fields, capped=FALSE))
  class <- ifelse(fields %in% keep, "character", "NULL")
  if (all(class=="NULL")) return(list(status="FIELDS_NOT_APPLICABLE",data=NULL,
                                       fields=fields,capped=FALSE))
  dat <- tryCatch(utils::read.table(con, sep=sep, header=FALSE,
    col.names=fields, colClasses=class, nrows=row_cap,
    quote=if (identical(sep, ",")) '"' else "", comment.char="",
    blank.lines.skip=TRUE, check.names=FALSE, stringsAsFactors=FALSE,
    fill=TRUE, na.strings=c("", "NA", "NaN", "N/A")),
    error=function(e) e)
  if (inherits(dat, "error")) return(list(
    status=paste0("PARSE_ERROR: ",conditionMessage(dat)),
    data=NULL, fields=fields, capped=FALSE))
  list(status="READ",data=dat,fields=fields,
       capped=nrow(dat) >= row_cap)
}

.w2_num <- function(x) suppressWarnings(as.numeric(as.character(x)))
.w2_add <- function(out, key, value) { out[[key]] <- value; out }
.w2_diagnostic <- function(x, col, predicate, label) {
  if (is.null(x) || !(col %in% names(x)))
    return(c(tested=0L, violations=0L))
  v <- .w2_num(x[[col]])
  valid <- is.finite(v)
  c(tested=sum(valid), violations=sum(predicate(v[valid])))
}

.w2_ia <- function(zip, member, max_rows) {
  fields <- c("participant_id","TRIAL_INDEX","IA_ID","IA_LABEL",
              "IA_LEFT","IA_RIGHT","IA_TOP","IA_BOTTOM","IA_DWELL_TIME",
              "IA_FIXATION_COUNT","IA_FIRST_FIXATION_TIME",
              "IA_LAST_FIXATION_TIME","IA_FIRST_RUN_START_TIME",
              "IA_FIRST_RUN_END_TIME","IA_REGRESSION_IN_COUNT",
              "IA_REGRESSION_OUT_COUNT","TRIAL_FIXATION_COUNT")
  p <- .w2_read_subset(zip,member,fields,",",max_rows)
  ans <- list(archive=basename(zip),status=p$status,rows_sampled=0L,
              row_cap_reached=FALSE,
              missing_participant_trial=NA_integer_,
              duplicate_participant_trial_ia=NA_integer_,
              geometry_tested=0L,geometry_violations=0L,
              dwell_tested=0L,dwell_negative=0L,
              count_tested=0L,count_negative=0L,
              first_last_tested=0L,first_last_violations=0L,
              run_time_tested=0L,run_time_violations=0L)
  if(!identical(p$status,"READ")) return(ans)
  z<-p$data
  ans$rows_sampled<-nrow(z);ans$row_cap_reached<-p$capped
  if(all(c("participant_id","TRIAL_INDEX") %in% names(z))){
    bad <- is.na(z$participant_id)|!nzchar(z$participant_id)|
           is.na(z$TRIAL_INDEX)|!nzchar(z$TRIAL_INDEX)
    ans$missing_participant_trial<-sum(bad)
    if("IA_ID" %in% names(z)){
      valid<-!bad&!is.na(z$IA_ID)&nzchar(z$IA_ID)
      ids<-paste(z$participant_id[valid],z$TRIAL_INDEX[valid],z$IA_ID[valid],sep="\r")
      ans$duplicate_participant_trial_ia<-sum(duplicated(ids))
    }
  }
  if(all(c("IA_LEFT","IA_RIGHT","IA_TOP","IA_BOTTOM") %in% names(z))){
    a<-.w2_num(z$IA_LEFT);b<-.w2_num(z$IA_RIGHT)
    c1<-.w2_num(z$IA_TOP);d<-.w2_num(z$IA_BOTTOM)
    valid<-is.finite(a)&is.finite(b)&is.finite(c1)&is.finite(d)
    ans$geometry_tested<-sum(valid)
    ans$geometry_violations<-sum(a[valid]>b[valid]|c1[valid]>d[valid])
  }
  d<-.w2_diagnostic(z,"IA_DWELL_TIME",function(x)x<0,"dwell")
  ans$dwell_tested<-unname(d["tested"]);ans$dwell_negative<-unname(d["violations"])
  names_counts<-intersect(c("IA_FIXATION_COUNT","IA_REGRESSION_IN_COUNT",
                            "IA_REGRESSION_OUT_COUNT","TRIAL_FIXATION_COUNT"), names(z))
  for (nm in names_counts){
    cc<-.w2_diagnostic(z,nm,function(x)x<0,"count")
    ans$count_tested<-ans$count_tested+unname(cc["tested"])
    ans$count_negative<-ans$count_negative+unname(cc["violations"])
  }
  for (term in list(c("IA_FIRST_FIXATION_TIME","IA_LAST_FIXATION_TIME"),
                    c("IA_FIRST_RUN_START_TIME","IA_FIRST_RUN_END_TIME"))){
    if (!all(term %in% names(z))) next
    a<-.w2_num(z[[term[1L]]]);b<-.w2_num(z[[term[2L]]])
    valid<-is.finite(a)&is.finite(b)
    if(identical(term[1L],"IA_FIRST_FIXATION_TIME")){
      ans$first_last_tested<-sum(valid)
      ans$first_last_violations<-sum(a[valid]>b[valid])
    }else{
      ans$run_time_tested<-sum(valid)
      ans$run_time_violations<-sum(a[valid]>b[valid])
    }
  }
  ans$status<-"OBSERVED_NOT_CERTIFIED"
  ans
}

.w2_stem <- function(member,suffix){
  base<-tolower(basename(member))
  sub(paste0(suffix,"\\.tsv$"),"",base,ignore.case=TRUE)
}
.w2_family <- function(zip,suffix){
  members<-.w2_zip_members(zip,"\\.tsv$")
  matches<-grepl(paste0(suffix,"\\.tsv$"),members,ignore.case=TRUE)
  members<-members[matches]
  keys<-vapply(members,.w2_stem,character(1L),suffix=suffix)
  duplicated_keys<-sum(duplicated(keys))
  if(duplicated_keys) {
    # Do not silently choose between duplicated names.
    keep<-!duplicated(keys)&!duplicated(keys,fromLast=TRUE)
    keys<-keys[keep];members<-members[keep]
  }
  list(members=setNames(members,keys),original_count=sum(matches),
       duplicate_stems=duplicated_keys)
}

.w2_tsv_fields <- c("fixation_index","original_fixation_index","trial",
  "reader_id","text_id","text_domain","fixation_duration","aoi",
  "is_fixation_adjusted","version")

.w2_metrics <- function(p){
  out<-list(status=p$status,rows=NA_integer_,row_cap_reached=p$capped,
            key_duplicates=NA_integer_,key_missing=NA_integer_,
            duration_tested=0L,duration_negative=0L,
            fixation_index_tested=0L,index_nonpositive=0L)
  if(!identical(p$status,"READ"))return(out)
  z<-p$data
  out$rows<-nrow(z)
  if("fixation_duration" %in% names(z)){
    d<-.w2_num(z$fixation_duration);good<-is.finite(d)
    out$duration_tested<-sum(good)
    out$duration_negative<-sum(d[good]<0)
  }
  if("fixation_index" %in% names(z)){
    v<-.w2_num(z$fixation_index);good<-is.finite(v)
    out$fixation_index_tested<-sum(good)
    out$index_nonpositive<-sum(v[good]<0)
  }
  if(all(c("trial","fixation_index") %in% names(z))){
    valid<-!is.na(z$trial)&!is.na(z$fixation_index)&
      nzchar(z$trial)&nzchar(z$fixation_index)
    keys<-paste(z$trial[valid],z$fixation_index[valid],sep="\r")
    out$key_missing<-sum(!valid)
    out$key_duplicates<-sum(duplicated(keys))
  }
  out
}

.w2_crosswalk <- function(a,b){
  out<-list(comparison="NOT_COMPARABLE",keys_a=0L,keys_b=0L,
            only_a=NA_integer_,only_b=NA_integer_,
            matched=0L,shared_field_mismatches=NA_integer_,
            duration_comparable=0L,duration_disagreements=NA_integer_)
  if(is.null(a)||is.null(b))return(out)
  if(!all(c("trial","fixation_index") %in% names(a))||
     !all(c("trial","fixation_index") %in% names(b)))return(out)
  keyed<-function(z){
    valid<-!is.na(z$trial)&!is.na(z$fixation_index)&
      nzchar(z$trial)&nzchar(z$fixation_index)
    key<-paste(z$trial[valid],z$fixation_index[valid],sep="\r")
    list(key=key,data=z[valid,,drop=FALSE],
         safe= !anyDuplicated(key) && length(key)>0)
  }
  ka<-keyed(a);kb<-keyed(b)
  if(!ka$safe||!kb$safe)return(out)
  out$keys_a<-length(ka$key);out$keys_b<-length(kb$key)
  common<-intersect(ka$key,kb$key)
  out$only_a<-length(setdiff(ka$key,kb$key))
  out$only_b<-length(setdiff(kb$key,ka$key))
  out$matched<-length(common)
  out$comparison<-"OBSERVED_KEY_CROSSWALK"
  if(!length(common)){
    out$shared_field_mismatches<-0L
    out$duration_disagreements<-0L
    return(out)
  }
  ia<-match(common,ka$key);ib<-match(common,kb$key)
  shared<-intersect(c("original_fixation_index","reader_id","text_id",
                       "text_domain","aoi","is_fixation_adjusted","version"),
                    intersect(names(a),names(b)))
  mismatch<-0L
  for(nm in shared){
    x<-as.character(ka$data[[nm]][ia])
    y<-as.character(kb$data[[nm]][ib])
    good<-!is.na(x)&!is.na(y)
    mismatch<-mismatch+sum(x[good]!=y[good])
  }
  out$shared_field_mismatches<-mismatch
  if("fixation_duration" %in% names(a) && "fixation_duration" %in% names(b)){
    x<-.w2_num(ka$data$fixation_duration[ia])
    y<-.w2_num(kb$data$fixation_duration[ib])
    good<-is.finite(x)&is.finite(y)
    out$duration_comparable<-sum(good)
    out$duration_disagreements<-sum(abs(x[good]-y[good])>1e-7)
  }
  out
}

.w2_asc <- function(zip,member,max_lines){
  ans<-list(status="NOT_RUN",sampled_lines=0L,
            cap_reached=FALSE,msg=0L,sfix=0L,efix=0L,
            ssacc=0L,esacc=0L,sblink=0L,eblink=0L,
            timestamp_sample_lines=0L)
  p<-tryCatch(unz(zip,member,open="r"),error=function(e)e)
  if(inherits(p,"error")){ans$status="READ_ERROR";return(ans)}
  on.exit(close(p),add=TRUE)
  x<-tryCatch(readLines(p,n=max_lines,warn=FALSE),error=function(e)e)
  if(inherits(x,"error")){ans$status="READ_ERROR";return(ans)}
  ans$sampled_lines<-length(x);ans$cap_reached<-length(x)>=max_lines
  for(nm in c("MSG","SFIX","EFIX","SSACC","ESACC","SBLINK","EBLINK")){
    ans[[tolower(nm)]]<-sum(grepl(paste0("^",nm,"[[:space:]]"),x))
  }
  ans$timestamp_sample_lines<-sum(grepl("^[[:space:]]*[0-9]+[[:space:]]",x))
  ans$status<-"EVENT_SAMPLE_ONLY_NOT_CALIBRATED"
  ans
}

.w2_csv <- function(path,rows){
  if(!length(rows)){writeLines("",path);return(invisible())}
  df<-do.call(rbind,lapply(rows,function(x)
    as.data.frame(x,stringsAsFactors=FALSE,check.names=FALSE)))
  utils::write.csv(df,path,row.names=FALSE,na="")
}

w2_run <- function(root=Sys.getenv("ET_WAVE2_ROOT",
                   file.path(Sys.getenv("USERPROFILE"),"Downloads","eyetrajectoriesValidation")),
                   max_units=as.integer(Sys.getenv("ET_WAVE2_MAX_UNITS","900")),
                   max_rows=as.integer(Sys.getenv("ET_WAVE2_MAX_ROWS","30000")),
                   max_asc_files=as.integer(Sys.getenv("ET_WAVE2_ASC_FILES","3")),
                   max_asc_lines=as.integer(Sys.getenv("ET_WAVE2_ASC_LINES","100000"))){
  stopifnot(dir.exists(root),is.finite(max_units),max_units>=1L,
    is.finite(max_rows),max_rows>=100L,is.finite(max_asc_files),max_asc_files>=0L,
    is.finite(max_asc_lines),max_asc_lines>=100L)
  namesZip<-c(scanpaths="scanpaths.zip",merged="scanpaths_merged.zip",
              fixations="fixations.zip")
  paths<-stats::setNames(file.path(root,unname(namesZip)),names(namesZip))
  if(!all(file.exists(paths)))stop("Missing scanpath-family archive(s): ",
    paste(basename(paths[!file.exists(paths)]),collapse=", "))
  other<-file.path(root,c("ia_Paragraph_repeated.csv.zip",
                            "ia_Paragraph_ordinary.csv.zip","asc_files.zip"))
  if(!all(file.exists(other)))stop("Missing IA or ASC archive(s): ",
    paste(basename(other[!file.exists(other)]),collapse=", "))
  suffixes<-c(scanpaths="_scanpath",merged="_merged_sp_rm",fixations="_fixations")
  family<-lapply(namesZip,function(x)NULL)
  for (nm in names(namesZip))
    family[[nm]]<-.w2_family(paths[[nm]],suffixes[[nm]])
  common<-Reduce(intersect,lapply(family,function(x)names(x$members)))
  common<-sort(common)
  allkeys<-Reduce(union,lapply(family,function(x)names(x$members)))
  sampled<-head(common,max_units)
  out<-tempfile("EYETRAJECTORIES_ARCHIVE_SPECIFIC_WAVE2_",tmpdir=root)
  if(!dir.create(out))stop("Failed to create output directory")
  summary_counts<-list(matched_triplets=length(common),
                       union_units=length(allkeys),
                       sampled_triplets=length(sampled),
                       cap_reached=length(sampled)<length(common))
  rows<-list()
  aggregate<-list()
  for(i in seq_along(sampled)){
    key<-sampled[[i]]
    readings<-list();metrics<-list()
    for(nm in names(namesZip)){
      member<-family[[nm]]$members[[key]]
      readings[[nm]]<-.w2_read_subset(paths[[nm]],member,
                                     .w2_tsv_fields,"\t",max_rows)
      metrics[[nm]]<-.w2_metrics(readings[[nm]])
    }
    ab<-.w2_crosswalk(readings$scanpaths$data,readings$fixations$data)
    ac<-.w2_crosswalk(readings$scanpaths$data,readings$merged$data)
    bc<-.w2_crosswalk(readings$fixations$data,readings$merged$data)
    # Per-unit index only: no participant, text or filename IDs emitted.
    row<-list(unit_index=i,scanpath_rows=metrics$scanpaths$rows,
      merged_rows=metrics$merged$rows,fixation_rows=metrics$fixations$rows,
      scanpath_duplicate_keys=metrics$scanpaths$key_duplicates,
      merged_duplicate_keys=metrics$merged$key_duplicates,
      fixation_duplicate_keys=metrics$fixations$key_duplicates,
      scanpath_negative_durations=metrics$scanpaths$duration_negative,
      merged_negative_durations=metrics$merged$duration_negative,
      fixation_negative_durations=metrics$fixations$duration_negative,
      scanpath_cap=metrics$scanpaths$row_cap_reached,
      merged_cap=metrics$merged$row_cap_reached,
      fixation_cap=metrics$fixations$row_cap_reached,
      scan_to_fix_status=ab$comparison,
      scan_to_fix_only_scan=ab$only_a,scan_to_fix_only_fix=ab$only_b,
      scan_to_fix_matched=ab$matched,
      scan_to_fix_field_disagreements=ab$shared_field_mismatches,
      scan_to_fix_duration_disagreements=ab$duration_disagreements,
      scan_to_merged_status=ac$comparison,
      scan_to_merged_only_scan=ac$only_a,scan_to_merged_only_merged=ac$only_b,
      scan_to_merged_matched=ac$matched,
      scan_to_merged_field_disagreements=ac$shared_field_mismatches,
      scan_to_merged_duration_disagreements=ac$duration_disagreements,
      fix_to_merged_status=bc$comparison,
      fix_to_merged_only_fix=bc$only_a,fix_to_merged_only_merged=bc$only_b,
      fix_to_merged_matched=bc$matched,
      fix_to_merged_field_disagreements=bc$shared_field_mismatches,
      fix_to_merged_duration_disagreements=bc$duration_disagreements)
    rows[[length(rows)+1L]]<-row
    if(i %% 50L==0L)message("Wave 2 crosswalk: ",i,"/",length(sampled))
  }
  ia<-list()
  for(zip in other[1:2]){
    members<-.w2_zip_members(zip,"\\.csv$")
    ia[[length(ia)+1L]]<-if(length(members)) .w2_ia(zip,members[[1L]],max_rows)
      else list(archive=basename(zip),status="NO_CSV_MEMBER",rows_sampled=0L,
        row_cap_reached=FALSE,missing_participant_trial=NA_integer_,
        duplicate_participant_trial_ia=NA_integer_,geometry_tested=0L,
        geometry_violations=0L,dwell_tested=0L,dwell_negative=0L,
        count_tested=0L,count_negative=0L,first_last_tested=0L,
        first_last_violations=0L,run_time_tested=0L,run_time_violations=0L)
  }
  asc_members<-.w2_zip_members(other[[3L]],"\\.asc$")
  asc<-lapply(head(asc_members,max_asc_files),function(member)
    .w2_asc(other[[3L]],member,max_asc_lines))
  manifest<-lapply(names(family),function(nm)list(
    family=nm,archive=namesZip[[nm]],members=family[[nm]]$original_count,
    duplicate_stems=family[[nm]]$duplicate_stems,
    unmatched_stems=length(setdiff(names(family[[nm]]$members),common)),
    common_stems=length(common),inspected_units=length(sampled)))
  .w2_csv(file.path(out,"family_manifest.csv"),manifest)
  .w2_csv(file.path(out,"unit_crosswalk.csv"),rows)
  .w2_csv(file.path(out,"ia_quality.csv"),ia)
  .w2_csv(file.path(out,"asc_event_samples.csv"),asc)
  # Aggregation is descriptive; no unsupported scientific PASS designation.
  getTotal<-function(field){
    if(!length(rows))return(NA_integer_)
    z<-vapply(rows,function(r)as.numeric(r[[field]]),numeric(1))
    if(all(is.na(z))) NA_real_ else sum(z,na.rm=TRUE)
  }
  md<-c("# Wave 2: archive-specific real-data evidence intake","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    "",
    "**Scope:** local input-integrity diagnostics, not scientific certification.",
    "Source ZIPs unchanged; no reader or participant IDs exported.","",
    "| TSV family | Members | Duplicate stems | Unmatched stems |",
    "| --- | ---: | ---: | ---: |")
  for(m in manifest)md<-c(md,sprintf("| %s | %d | %d | %d |",
    m$family,m$members,m$duplicate_stems,m$unmatched_stems))
  md<-c(md,"",paste0("Common units across all three archives: ",
    length(common),". Inspected: ",length(sampled),"."),
    if(length(sampled)<length(common))
      "WARNING: unit cap reached; this is not an exhaustive record audit."
    else "All common units were selected for record-level crosswalk checks.",
    "",
    paste0("Scanpath ↔ fixation unmatched keys in inspected units: ",
           getTotal("scan_to_fix_only_scan"), " and ",getTotal("scan_to_fix_only_fix"),"."),
    paste0("Scanpath ↔ merged unmatched keys in inspected units: ",
           getTotal("scan_to_merged_only_scan"), " and ",getTotal("scan_to_merged_only_merged"),"."),
    paste0("Fixation ↔ merged unmatched keys in inspected units: ",
           getTotal("fix_to_merged_only_fix"), " and ",getTotal("fix_to_merged_only_merged"),"."),
    "",
    "Key correspondence tests use (trial, fixation_index); duplicate or",
    "unavailable keys are marked NOT_COMPARABLE rather than silently joined.",
    "Shared-field and duration discrepancies are recorded separately, and",
    "do not imply which derived representation is scientifically correct.",
    "",
    "## Interest-area quality diagnostics",
    "")
  for(x in ia)md<-c(md,paste0("- ",x$archive,": ",x$status,
      "; rows=",x$rows_sampled,"; geometry violations=",
      x$geometry_violations,"/",x$geometry_tested,
      "; negative dwell=",x$dwell_negative,"/",x$dwell_tested,
      "; negative counts=",x$count_negative,"/",x$count_tested,
      "; row cap=",x$row_cap_reached))
  md<-c(md,"","## ASC provenance (sampled lines only)",
    paste0("ASC files in archive: ",length(asc_members),
           "; inspected: ",length(asc),"."),
    "Balances between opening and closing event markers must not be inferred",
    "from truncated line samples. No calibration or raw 1,000 Hz claim.",
    "",
    "## Interpretation",
    "- The OneStop paragraph CSVs were not joined to the 900-file",
    "  scanpath family: their identity equivalence is not established.",
    "- Good field consistency supports data-pipeline reproducibility but",
    "  does not validate physical gaze accuracy or behavioral inference.",
    "- AOI definitions, external ground truth, participant dependence and",
    "  statistical coverage still require independent scientific validation.",
    "- This audit does not modify v0.4.3 software or historical benchmarks.",
    "")
  writeLines(md,file.path(out,"WAVE2_SUMMARY.md"))
  writeLines(capture.output(utils::sessionInfo()),file.path(out,"R_session_info.txt"))
  message("WAVE2_AUDIT_FINISHED=",out)
  invisible(list(output=out,manifest=manifest,summary=summary_counts,
                 rows=rows,ia=ia,asc=asc))
}

if (!identical(tolower(Sys.getenv("ET_WAVE2_NO_AUTORUN")), "true")) w2_run()
