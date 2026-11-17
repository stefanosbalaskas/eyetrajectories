# eyetrajectories Wave 4 — text_domain source label provenance, privacy-first.
# Reads only local scanpaths.zip, scanpaths_merged.zip and fixations.zip.
# No ZIP data modification, no participant identifiers/raw fixations exported.
# Usage: source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/qualify_wave4_text_domain_provenance.R"))
# Env options: ET_WAVE4_ROOT, ET_WAVE4_MAX_UNITS (900), ET_WAVE4_MAX_ROWS (30000),
# ET_WAVE4_SAVE_LOCAL_LABEL_KEY ("false" by default; DO NOT SHARE THAT FILE).
# For test/source without executing: ET_WAVE4_NO_AUTORUN=true.

.w4_names <- c(scanpaths="scanpaths.zip",merged="scanpaths_merged.zip",fixations="fixations.zip")
.w4_suffix <- c(scanpaths="_scanpath",merged="_merged_sp_rm",fixations="_fixations")

.w4_manifest <- function(zip,suffix) {
  v<-utils::unzip(zip,list=TRUE)$Name
  keep<-!is.na(v)&nzchar(v)&!grepl("/$",v)&
    !grepl("(^|/)__MACOSX(/|$)",v,ignore.case=TRUE)&
    !grepl("(^|/)\\._[^/]*$",v)&
    grepl(paste0(suffix,"\\.tsv$"),v,ignore.case=TRUE)
  files<-v[keep]
  stems<-tolower(sub(paste0(suffix,"\\.tsv$"),"",basename(files),ignore.case=TRUE))
  if(anyDuplicated(stems))stop("Duplicate normalized filename stem in ",basename(zip))
  stats::setNames(files,stems)
}
.w4_get <- function(zip,member,max_rows) {
  if(length(member)!=1L||is.na(member))return(list(status="MISSING_MEMBER"))
  con<-tryCatch(unz(zip,member,open="r"),error=function(e)e)
  if(inherits(con,"error"))return(list(status="ZIP_READ_ERROR"))
  on.exit(close(con),add=TRUE)
  hdr<-tryCatch(readLines(con,n=1L,warn=FALSE),error=function(e)character())
  if(length(hdr)!=1L)return(list(status="HEADER_READ_ERROR"))
  fields<-strsplit(sub("^\ufeff","",hdr),"\t",fixed=TRUE)[[1L]]
  fields<-gsub('^"|"$',"",fields)
  if(anyDuplicated(fields))return(list(status="DUPLICATE_FIELDS"))
  requested<-c("trial","fixation_index","text_domain")
  if(!all(requested %in% fields))return(list(status="REQUIRED_FIELDS_MISSING"))
  classes<-ifelse(fields%in%requested,"character","NULL")
  d<-tryCatch(utils::read.table(con,header=FALSE,sep="\t",col.names=fields,
     colClasses=classes,nrows=max_rows,quote="",comment.char="",
     check.names=FALSE,stringsAsFactors=FALSE,fill=TRUE,
     na.strings=c("","NA","N/A","NaN")),error=function(e)e)
  if(inherits(d,"error"))return(list(status="TSV_PARSE_ERROR"))
  keys_ok<-!is.na(d$trial)&nzchar(d$trial)&
    !is.na(d$fixation_index)&nzchar(d$fixation_index)
  if(!all(keys_ok))return(list(status="MISSING_KEYS",rows=nrow(d)))
  keys<-paste(d$trial,d$fixation_index,sep="\r")
  if(anyDuplicated(keys))return(list(status="DUPLICATE_KEYS",rows=nrow(d)))
  domain<-as.character(d$text_domain)
  nonmissing<-unique(domain[!is.na(domain)])
  list(status="OK",key=keys,domain=domain,rows=nrow(d),
       capped=nrow(d)>=max_rows,
       constant=!anyNA(domain)&&length(nonmissing)==1L,
       constant_value=if(!anyNA(domain)&&length(nonmissing)==1L)nonmissing[[1L]] else NA_character_,
       domain_missing=sum(is.na(domain)),
       distinct_domain_labels=length(nonmissing))
}
.w4_match <- function(a,b) {
  out<-list(status="NOT_COMPARABLE",matched=NA_integer_,unmatched_a=NA_integer_,
            unmatched_b=NA_integer_,both_present=NA_integer_,
            disagreements=NA_integer_,different_only_whitespace=NA_integer_)
  if(!identical(a$status,"OK")||!identical(b$status,"OK"))return(out)
  common<-intersect(a$key,b$key)
  i<-match(common,a$key);j<-match(common,b$key)
  x<-a$domain[i];y<-b$domain[j]
  ok<-!is.na(x)&!is.na(y)
  unequal<-x[ok]!=y[ok]
  out$status<-"COMPARABLE"
  out$matched<-length(common)
  out$unmatched_a<-length(setdiff(a$key,b$key))
  out$unmatched_b<-length(setdiff(b$key,a$key))
  out$both_present<-sum(ok)
  out$disagreements<-sum(unequal)
  out$different_only_whitespace<-sum(unequal&trimws(x[ok])==trimws(y[ok]))
  out
}
.w4_frame<-function(rows){
  if(!length(rows))return(data.frame())
  do.call(rbind,lapply(rows,function(r)
    as.data.frame(r,stringsAsFactors=FALSE,check.names=FALSE)))
}
.w4_origin_group<-function(stem) {
  # Structural filename token, *not* semantic reading-category ground truth.
  x<-regmatches(stem,regexec("_([a-z])[0-9]+$",stem,perl=TRUE))[[1L]]
  if(length(x)==2L)toupper(x[[2L]]) else "OTHER"
}
.w4_category_code<-function(x,categories){
  if(is.na(x))return("MISSING_OR_NONCONSTANT")
  sprintf("CAT_%03d",match(x,categories))
}
.w4_aggregate<-function(unit_rows){
  # All source categories are pseudonymized first.
  if(!length(unit_rows))return(data.frame())
  rows<-lapply(unit_rows,function(z)list(
    filename_group=z$filename_group,
    scanpath_category=z$scanpath_category,
    fixation_category=z$fixation_category,
    merged_category=z$merged_category,
    units=1L,
    fixation_records=z$matched_records,
    discrepant_fixation_records=z$scan_fix_disagreements))
  keys<-vapply(rows,function(r)paste(r$filename_group,r$scanpath_category,
                     r$fixation_category,r$merged_category,sep="\r"),character(1L))
  groups<-split(seq_along(rows),keys)
  result<-lapply(groups,function(ids){
    ref<-rows[[ids[[1L]]]]
    ref$units<-length(ids)
    ref$fixation_records<-sum(vapply(rows[ids],function(z)z$fixation_records,numeric(1L)))
    ref$discrepant_fixation_records<-sum(vapply(rows[ids],function(z)
      z$discrepant_fixation_records,numeric(1L)))
    ref
  })
  z<-.w4_frame(result)
  z[order(z$filename_group,z$scanpath_category,z$fixation_category),,drop=FALSE]
}

w4_run<-function(root=Sys.getenv("ET_WAVE4_ROOT",
                file.path(Sys.getenv("USERPROFILE"),"Downloads","eyetrajectoriesValidation")),
             max_units=as.integer(Sys.getenv("ET_WAVE4_MAX_UNITS","900")),
             max_rows=as.integer(Sys.getenv("ET_WAVE4_MAX_ROWS","30000"))) {
  stopifnot(dir.exists(root),length(max_units)==1L,is.finite(max_units),
            max_units>=1L,length(max_rows)==1L,is.finite(max_rows),max_rows>=100L)
  paths<-file.path(root,unname(.w4_names));names(paths)<-names(.w4_names)
  if(!all(file.exists(paths)))stop("Required local ZIP files absent")
  manifests<-lapply(names(paths),function(nm).w4_manifest(paths[[nm]],.w4_suffix[[nm]]))
  names(manifests)<-names(paths)
  common<-sort(Reduce(intersect,lapply(manifests,names)))
  selected<-head(common,max_units)
  out<-tempfile("EYETRAJECTORIES_WAVE4_DOMAIN_PROVENANCE_",tmpdir=root)
  if(!dir.create(out))stop("Cannot create new evidence directory")
  rows<-list();category_pool<-character()
  for(i in seq_along(selected)){
    stem<-selected[[i]]
    z<-lapply(names(paths),function(nm)
      .w4_get(paths[[nm]],manifests[[nm]][[stem]],max_rows))
    names(z)<-names(paths)
    a<-.w4_match(z$scanpaths,z$fixations)
    b<-.w4_match(z$scanpaths,z$merged)
    c1<-.w4_match(z$fixations,z$merged)
    safe<-all(vapply(z,function(x)identical(x$status,"OK"),logical(1L)))
    if(safe) {
      for(nm in names(z))if(isTRUE(z[[nm]]$constant))
        category_pool<-c(category_pool,z[[nm]]$constant_value)
    }
    rows[[i]]<-list(unit_index=i,filename_group=.w4_origin_group(stem),
       status=if(safe&&all(c(a$status,b$status,c1$status)=="COMPARABLE"))"COMPARABLE"
              else "SOURCE_OR_KEY_ERROR",
       scanpath_status=z$scanpaths$status,
       fixation_status=z$fixations$status,
       merged_status=z$merged$status,
       constant_scanpath=if(safe)z$scanpaths$constant else FALSE,
       constant_fixation=if(safe)z$fixations$constant else FALSE,
       constant_merged=if(safe)z$merged$constant else FALSE,
       missing_domain_cells=if(safe)sum(vapply(z,function(x)x$domain_missing,integer(1L))) else NA_integer_,
       capped=if(safe)any(vapply(z,function(x)x$capped,logical(1L))) else NA,
       matched_records=a$matched,
       scan_fix_disagreements=a$disagreements,
       scan_merged_disagreements=b$disagreements,
       fix_merged_disagreements=c1$disagreements,
       shared_key_loss=if(safe)sum(c(a$unmatched_a,a$unmatched_b,
                             b$unmatched_a,b$unmatched_b,c1$unmatched_a,c1$unmatched_b)) else NA_integer_,
       scan_raw=if(safe)z$scanpaths$constant_value else NA_character_,
       fix_raw=if(safe)z$fixations$constant_value else NA_character_,
       merged_raw=if(safe)z$merged$constant_value else NA_character_)
    if(i%%100L==0L)message("WAVE4_DOMAIN_UNITS=",i,"/",length(selected))
  }
  # All raw category labels are held only in memory unless explicitly opted in.
  category_pool<-sort(unique(category_pool))
  if(isTRUE(identical(tolower(Sys.getenv("ET_WAVE4_SAVE_LOCAL_LABEL_KEY")),
                      "true"))) {
    key<-data.frame(code=sprintf("CAT_%03d",seq_along(category_pool)),
                    original_text_domain=category_pool)
    utils::write.csv(key,file.path(out,"LOCAL_ONLY_DOMAIN_CATEGORY_KEY_DO_NOT_UPLOAD.csv"),
                     row.names=FALSE)
  }
  safe_rows<-lapply(rows,function(r){
    r$scanpath_category<-.w4_category_code(r$scan_raw,category_pool)
    r$fixation_category<-.w4_category_code(r$fix_raw,category_pool)
    r$merged_category<-.w4_category_code(r$merged_raw,category_pool)
    r$scan_raw<-NULL;r$fix_raw<-NULL;r$merged_raw<-NULL
    r
  })
  frame<-.w4_frame(safe_rows)
  utils::write.csv(frame,file.path(out,"domain_unit_diagnostics.csv"),
                   row.names=FALSE,na="")
  valid_rows<-safe_rows[vapply(safe_rows,function(r)
    r$status=="COMPARABLE"&&r$constant_scanpath&&r$constant_fixation&&
    r$constant_merged,logical(1L))]
  transitions<-.w4_aggregate(valid_rows)
  utils::write.csv(transitions,file.path(out,"domain_category_transitions.csv"),
                   row.names=FALSE,na="")
  count<-function(field)sum(vapply(safe_rows,function(r)
    if(is.na(r[[field]]))0 else as.numeric(r[[field]]),numeric(1L)))
  affected<-sum(vapply(safe_rows,function(r)
    !is.na(r$scan_fix_disagreements) && r$scan_fix_disagreements>0L,logical(1L)))
  # Only a descriptive check: when multiple categories map to one target
  # a one-to-one recoding cannot be inferred.
  byscan<-split(transitions$fixation_category,transitions$scanpath_category)
  byfix<-split(transitions$scanpath_category,transitions$fixation_category)
  one_to_one<-length(valid_rows)==length(safe_rows) &&
    all(vapply(byscan,function(z)length(unique(z))==1L,logical(1L))) &&
    all(vapply(byfix,function(z)length(unique(z))==1L,logical(1L)))
  summary<-c("# Wave 4 — text_domain label provenance, without raw IDs","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),"",
    "**Read-only local quality audit, not independent scientific validation.**","",
    paste0("Comparable family stems: ",length(common),
           "; inspected units: ",length(selected),"."),
    paste0("Observed distinct domain labels (pseudonymized): ",
           length(category_pool),"."),
    paste0("Units with scanpath/fixation domain disagreement: ",affected,"."),
    paste0("Affected matched fixation records: ",count("scan_fix_disagreements"),"."),
    paste0("Scanpath/merged disagreements: ",count("scan_merged_disagreements"),"."),
    paste0("Domains constant in all three sources for every inspected unit: ",
           if(length(valid_rows)==length(safe_rows))"YES" else "NO","."),
    paste0("Dataset-wide category-code bijection (descriptive): ",
           if(one_to_one)"YES" else "NO or UNDETERMINED","."),
    "",
    "## Category transitions (pseudonymous labels; filename suffix is structural only)",
    "",
    "| Filename group | Scanpath category | Fixation category | Merged category | Units | Records | Domain discrepancies |",
    "| --- | --- | --- | --- | ---: | ---: | ---: |")
  if(nrow(transitions))for(i in seq_len(nrow(transitions))){
    r<-transitions[i,]
    summary<-c(summary,sprintf("| %s | %s | %s | %s | %d | %d | %d |",
      r$filename_group,r$scanpath_category,r$fixation_category,
      r$merged_category,r$units,r$fixation_records,r$discrepant_fixation_records))
  }
  summary<-c(summary,"",
    "Labels CAT_### preserve equality across archives in this run but do not",
    "reveal raw text_domain strings. Filename group B/P/OTHER does not",
    "establish the scientific meaning of text types.",
    "",
    "## Evidence needed to adjudicate correctness",
    "- Identify upstream export code or authoritative schema defining text_domain.",
    "- Compare labels to that independently documented definition.",
    "- Do not replace, harmonize or publish raw subject-level data based",
    "  on this descriptive mismatch audit.",
    "- No claim about calibration, behavioral inference or participant validity.",
    "- Do not join these 900 TSV units to separate OneStop paragraph CSVs",
    "  without a verified identity crosswalk.")
  writeLines(summary,file.path(out,"WAVE4_SUMMARY.md"))
  writeLines(capture.output(utils::sessionInfo()),file.path(out,"R_session_info.txt"))
  message("WAVE4_DOMAIN_PROVENANCE_COMPLETED=",out)
  invisible(list(output=out,summary=transitions,units=frame))
}
if(!identical(tolower(Sys.getenv("ET_WAVE4_NO_AUTORUN")),"true"))w4_run()
