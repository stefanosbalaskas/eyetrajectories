# eyetrajectories — PoTeC correction-stage provenance audit, R only.
# Sources: authors' public OSF fixations_uncorrected.zip (d8pyg) and the
# previously validated local fixations.zip (manually corrected).
# Explicitly NOT a timestamp-level ASC-to-EFIX identity matcher:
# the split uncorrected files omit original event start/end timestamps.
# No original ZIPs changed. Output only deidentified aggregate counts.
#
# Usage in RStudio:
# source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/validate_potec_uncorrected_stage.R"))
# The original uncorrected ZIP is OFF by default: opt in to fetching official
# OSF only when needed: Sys.setenv(ET_POTEC_FETCH_UNCORRECTED="true")
# To load without running, set ET_POTEC_UNCORRECTED_NO_AUTORUN="true".

.pu_original_url <- "https://osf.io/download/d8pyg"
.pu_clean_members <- function(zip,suffix) {
  listed<-utils::unzip(zip,list=TRUE)$Name
  good<-!is.na(listed)&nzchar(listed)&!grepl("/$",listed)&
    !grepl("(^|/)__MACOSX(/|$)",listed,ignore.case=TRUE)&
    !grepl("(^|/)\\._[^/]*$",listed)&
    grepl(paste0(suffix,"\\.tsv$"),listed,ignore.case=TRUE)
  members<-listed[good]
  stem<-tolower(sub(paste0(suffix,"\\.tsv$"),"",
                 basename(members),ignore.case=TRUE))
  if(anyDuplicated(stem))stop("Duplicate normalized PoTeC filename stem")
  stats::setNames(members,stem)
}
.pu_read <- function(zip,member,keep,max_rows) {
  con<-tryCatch(unz(zip,member,open="r"),error=function(e)e)
  if(inherits(con,"error"))return(list(status="ZIP_OPEN_ERROR",data=NULL))
  on.exit(close(con),add=TRUE)
  h<-tryCatch(readLines(con,n=1L,warn=FALSE),error=function(e)character())
  if(length(h)!=1L)return(list(status="EMPTY_HEADER",data=NULL))
  fields<-gsub('^"|"$',"",strsplit(sub("^\ufeff","",h),"\t",fixed=TRUE)[[1L]])
  if(!length(fields)||anyDuplicated(fields))return(list(status="DUPLICATE_HEADER",data=NULL))
  classes<-ifelse(fields%in%keep,"character","NULL")
  d<-tryCatch(utils::read.table(con,header=FALSE,sep="\t",col.names=fields,
    colClasses=classes,nrows=max_rows,stringsAsFactors=FALSE,check.names=FALSE,
    quote="",comment.char="",fill=TRUE,
    na.strings=c("","NA","NaN","N/A",".")),error=function(e)e)
  if(inherits(d,"error"))return(list(status="PARSE_ERROR",data=NULL))
  list(status="READ",data=d,capped=nrow(d)>=max_rows)
}
.pu_key <- function(d,field) {
  if(!all(c("trial",field)%in%names(d)))
    return(list(status="KEY_COLUMNS_MISSING"))
  t<-as.character(d$trial); f<-as.character(d[[field]])
  valid<-!is.na(t)&nzchar(t)&!is.na(f)&nzchar(f)
  if(!all(valid))return(list(status="KEY_VALUES_MISSING"))
  k<-paste(t,f,sep="\r")
  if(anyDuplicated(k))return(list(status="DUPLICATE_TRIAL_ORIGINAL_INDEX"))
  list(status="OK",keys=k)
}
.pu_match <- function(original,corrected) {
  result<-list(status="NOT_COMPARABLE",uncorrected_rows=NA_integer_,
    corrected_rows=NA_integer_,matched_original_keys=NA_integer_,
    uncorrected_only_keys=NA_integer_,corrected_only_keys=NA_integer_,
    duration_tested=NA_integer_,duration_disagreements=NA_integer_,
    aoi_tested=NA_integer_,aoi_differences=NA_integer_,
    flagged_corrections=NA_integer_)
  if(!identical(original$status,"READ")||!identical(corrected$status,"READ"))
    return(result)
  a<-original$data;b<-corrected$data
  result$uncorrected_rows<-nrow(a);result$corrected_rows<-nrow(b)
  ka<-.pu_key(a,"fixation_index")
  kb<-.pu_key(b,"original_fixation_index")
  if(ka$status!="OK"||kb$status!="OK"){
    result$status<-paste(ka$status,kb$status,sep="/");return(result)
  }
  keys<-intersect(ka$keys,kb$keys)
  ia<-match(keys,ka$keys);ib<-match(keys,kb$keys)
  result$matched_original_keys<-length(keys)
  result$uncorrected_only_keys<-length(setdiff(ka$keys,kb$keys))
  result$corrected_only_keys<-length(setdiff(kb$keys,ka$keys))
  if("fixation_duration"%in%names(a)&&"fixation_duration"%in%names(b)){
    da<-suppressWarnings(as.numeric(a$fixation_duration[ia]))
    db<-suppressWarnings(as.numeric(b$fixation_duration[ib]))
    ok<-is.finite(da)&is.finite(db)
    result$duration_tested<-sum(ok)
    result$duration_disagreements<-sum(abs(da[ok]-db[ok])>1e-7)
  }
  if("aoi"%in%names(a)&&"aoi"%in%names(b)){
    av<-as.character(a$aoi[ia]);bv<-as.character(b$aoi[ib])
    ok<-!is.na(av)&!is.na(bv)
    result$aoi_tested<-sum(ok)
    result$aoi_differences<-sum(av[ok]!=bv[ok])
  }
  if("is_fixation_adjusted"%in%names(b)){
    flag<-tolower(trimws(as.character(b$is_fixation_adjusted)))
    result$flagged_corrections<-sum(flag%in%c("true","1","t","yes"),na.rm=TRUE)
  }
  result$status<-"SOURCE_ORIGINAL_INDEX_CROSSWALK"
  result
}
.pu_rows_df <- function(rows) {
  do.call(rbind,lapply(rows,function(r)
    as.data.frame(r,stringsAsFactors=FALSE,check.names=FALSE)))
}
.pu_download_official <- function(root){
  target<-file.path(root,"fixations_uncorrected.zip")
  if(file.exists(target))return(target)
  if(!identical(tolower(Sys.getenv("ET_POTEC_FETCH_UNCORRECTED")),"true"))
    stop("Missing fixations_uncorrected.zip. Download the authors' official ",
         .pu_original_url," to ",target,
         " or explicitly enable ET_POTEC_FETCH_UNCORRECTED=true")
  part<-tempfile("official_potec_uncorrected_",tmpdir=root,fileext=".zip")
  on.exit(if(file.exists(part))unlink(part),add=TRUE)
  utils::download.file(.pu_original_url,part,mode="wb",quiet=FALSE)
  x<-tryCatch(utils::unzip(part,list=TRUE),error=function(e)e)
  if(inherits(x,"error")||!any(grepl("_uncorrected_fixations\\.tsv$",
                                     x$Name,ignore.case=TRUE)))
    stop("Downloaded OSF resource failed archive integrity/header preflight")
  if(!file.rename(part,target))stop("Could not safely finalize official ZIP")
  target
}
sci_validate_potec_uncorrected <- function(
  root=Sys.getenv("ET_SCI_ROOT",file.path(Sys.getenv("USERPROFILE"),
               "Downloads","eyetrajectoriesValidation")),
  max_files=as.integer(Sys.getenv("ET_POTEC_STAGE_MAX_FILES","1000")),
  max_rows=as.integer(Sys.getenv("ET_POTEC_STAGE_MAX_ROWS","50000"))) {
  stopifnot(dir.exists(root),is.finite(max_files),max_files>=1L,
            is.finite(max_rows),max_rows>=100L)
  original_zip<-.pu_download_official(root)
  corrected_zip<-file.path(root,"fixations.zip")
  if(!file.exists(corrected_zip))stop("Missing local corrected fixations.zip")
  old<-.pu_clean_members(original_zip,"_uncorrected_fixations")
  new<-.pu_clean_members(corrected_zip,"_fixations")
  common<-sort(intersect(names(old),names(new)))
  chosen<-head(common,max_files)
  output<-tempfile("POTEC_UNCORRECTED_STAGE_AUDIT_",tmpdir=root)
  if(!dir.create(output))stop("Cannot create audit output")
  a_fields<-c("trial","fixation_index","fixation_duration","aoi",
              "fixation_position_x","fixation_position_y")
  b_fields<-c("trial","original_fixation_index","fixation_duration","aoi",
              "is_fixation_adjusted","fixation_index")
  rows<-list()
  for(i in seq_along(chosen)){
    stem<-chosen[[i]]
    a<-.pu_read(original_zip,old[[stem]],a_fields,max_rows)
    b<-.pu_read(corrected_zip,new[[stem]],b_fields,max_rows)
    compare<-.pu_match(a,b)
    rows[[i]]<-c(list(ordinal=i,
                     original_status=a$status,corrected_status=b$status,
                     original_row_cap=isTRUE(a$capped),
                     corrected_row_cap=isTRUE(b$capped)),compare)
    if(i%%100L==0L)message("Uncorrected/corrected units ",i,"/",length(chosen))
  }
  df<-.pu_rows_df(rows)
  utils::write.csv(df,file.path(output,"stage_unit_audit.csv"),
                   row.names=FALSE,na="")
  audit_sum<-function(x)sum(as.numeric(df[[x]]),na.rm=TRUE)
  state<-if(length(common)==900L && length(chosen)==900L &&
            all(df$status=="SOURCE_ORIGINAL_INDEX_CROSSWALK") &&
            !any(df$original_row_cap|df$corrected_row_cap) &&
            audit_sum("corrected_only_keys")==0 &&
            audit_sum("duration_disagreements")==0)
      "CORRECTION_STAGE_KEY_DURATION_CONSISTENCY_PASS" else
      "PARTIAL_OR_DISCREPANT_REVIEW_OUTPUTS"
  md<-c("# PoTeC original-uncorrected vs corrected fixation stage audit","",
    paste0("Date: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("Status: ",state),"",
    paste0("Original source ZIP: ",basename(original_zip)),
    paste0("Official upstream source: ",.pu_original_url),
    paste0("Source ZIP MD5 (provenance only): ",unname(tools::md5sum(original_zip))),
    paste0("Corrected ZIP MD5: ",unname(tools::md5sum(corrected_zip))),
    paste0("Uncorrected file stems: ",length(old),
       "; corrected stems: ",length(new),
       "; matched: ",length(common),"; inspected: ",length(chosen)),
    paste0("Only-uncorrected stems: ",length(setdiff(names(old),names(new))),
       "; only-corrected stems: ",length(setdiff(names(new),names(old)))),
    paste0("Matched original fixation IDs: ",audit_sum("matched_original_keys")),
    paste0("Uncorrected-only original IDs: ",audit_sum("uncorrected_only_keys")),
    paste0("Corrected-only original IDs: ",audit_sum("corrected_only_keys")),
    paste0("Matching-duration disagreements: ",
           audit_sum("duration_disagreements")),
    paste0("AOI label disagreements: ",audit_sum("aoi_differences"),
           " / ",audit_sum("aoi_tested")),
    paste0("Flagged manual correction records: ",
           audit_sum("flagged_corrections")),"",
    "Matched rows are aligned on (trial, ORIGINAL fixation index), NOT",
    "the newly reindexed corrected fixation_index. Uncorrected-only IDs",
    "can represent author-deleted events. AOI differences may be intended",
    "manual vertical drift correction, NOT a raw event detection failure.",
    "",
    "This source ZIP lacks the original EFIX start/end time columns.",
    "It therefore cannot by itself prove timestamp correspondence to raw",
    "ASC EFIX events. For that, use the original full Data Viewer report",
    "with event start timestamps, trial-specific markers and reader/session",
    "crosswalks; reader 21 and reader 0 have documented equivalence.",
    "The 78-file ASC inventory is from raw session recordings, not 900",
    "necessarily one-to-one reader/text source files.",
    "Source ZIPs unchanged; no raw subject identifiers or samples exported.")
  writeLines(md,file.path(output,"STAGE_PROVENANCE.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(output,"R_session_info.txt"))
  message("POTEC_STAGE_AUDIT=",state," OUTPUT=",output)
  invisible(list(status=state,output=output,unit_summary=df))
}
if(!identical(tolower(Sys.getenv("ET_POTEC_UNCORRECTED_NO_AUTORUN")),"true"))
  sci_validate_potec_uncorrected()
