# eyetrajectories Wave 3: diagnose exact shared fields behind Wave 2 mismatches
# R only, read-only ZIP access. No raw participant identifiers or values exported.
# Run: source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/qualify_wave3_field_disagreements.R"))
# To load functions only: Sys.setenv(ET_WAVE3_NO_AUTORUN="true")
# Optional: ET_WAVE3_ROOT, ET_WAVE3_MAX_UNITS (default 900), ET_WAVE3_MAX_ROWS (default 30000).

.w3_fields <- c("original_fixation_index", "reader_id", "text_id",
                "text_domain", "aoi", "is_fixation_adjusted", "version",
                "fixation_duration")
.w3_suffix <- c(scanpaths="_scanpath", merged="_merged_sp_rm", fixations="_fixations")
.w3_zipnames <- c(scanpaths="scanpaths.zip",
                  merged="scanpaths_merged.zip",fixations="fixations.zip")

.w3_members <- function(zip, suffix){
  listing <- utils::unzip(zip, list=TRUE)
  n <- listing$Name
  valid <- !is.na(n) & nzchar(n) & !grepl("/$",n) &
    !grepl("(^|/)__MACOSX(/|$)",n,ignore.case=TRUE) &
    !grepl("(^|/)\\._[^/]*$",n) &
    grepl(paste0(suffix,"\\.tsv$"),n,ignore.case=TRUE)
  paths <- n[valid]
  stems <- tolower(sub(paste0(suffix,"\\.tsv$"),"",
    basename(paths),ignore.case=TRUE))
  if (anyDuplicated(stems)) stop("Duplicate normalized unit stems in ",basename(zip))
  setNames(paths,stems)
}

.w3_read <- function(zip,member,max_rows){
  if(is.null(member)||length(member)!=1L||is.na(member))
    return(list(status="MISSING_MEMBER",data=NULL,capped=FALSE))
  con <- tryCatch(unz(zip,member,open="r"),error=function(e)e)
  if(inherits(con,"error"))return(list(status="OPEN_ERROR",data=NULL,capped=FALSE))
  on.exit(close(con),add=TRUE)
  h <- tryCatch(readLines(con,n=1L,warn=FALSE),error=function(e)character())
  if(length(h)!=1L)return(list(status="HEADER_ERROR",data=NULL,capped=FALSE))
  columns <- strsplit(sub("^\ufeff","",h),"\t",fixed=TRUE)[[1L]]
  columns <- gsub('^"|"$',"",columns)
  if(!length(columns)||anyDuplicated(columns))
    return(list(status="DUPLICATE_HEADER",data=NULL,capped=FALSE))
  keep <- unique(c("trial","fixation_index",.w3_fields))
  classes <- ifelse(columns %in% keep,"character","NULL")
  if(all(classes=="NULL"))
    return(list(status="NO_RELEVANT_FIELDS",data=NULL,capped=FALSE))
  d <- tryCatch(utils::read.table(con,sep="\t",header=FALSE,
     col.names=columns,colClasses=classes,nrows=max_rows,
     check.names=FALSE,stringsAsFactors=FALSE,quote="",comment.char="",
     blank.lines.skip=TRUE,fill=TRUE,na.strings=c("","NA","NaN","N/A")),
     error=function(e)e)
  if(inherits(d,"error"))return(list(status="PARSE_ERROR",data=NULL,capped=FALSE))
  list(status="READ",data=d,capped=nrow(d)>=max_rows)
}

.w3_keyed <- function(p){
  if(!identical(p$status,"READ")||
     !all(c("trial","fixation_index")%in%names(p$data)))
    return(list(status="UNAVAILABLE",keys=character(),data=NULL))
  d<-p$data
  valid<-!is.na(d$trial)&!is.na(d$fixation_index)&
    nzchar(d$trial)&nzchar(d$fixation_index)
  if(!all(valid))return(list(status="MISSING_KEY",keys=character(),data=NULL))
  key<-paste(d$trial,d$fixation_index,sep="\r")
  if(anyDuplicated(key))return(list(status="DUPLICATE_KEY",keys=character(),data=NULL))
  list(status="OK",keys=key,data=d)
}

.w3_compare <- function(p,q,comparison,unit_index){
  a<-.w3_keyed(p);b<-.w3_keyed(q)
  coverage<-list(unit_index=unit_index,comparison=comparison,
    status=if(a$status=="OK"&&b$status=="OK")"COMPARABLE" else
      paste0(a$status,"/",b$status),
    keys_a=if(a$status=="OK")length(a$keys) else NA_integer_,
    keys_b=if(b$status=="OK")length(b$keys) else NA_integer_,
    matched_keys=NA_integer_,only_a=NA_integer_,only_b=NA_integer_,
    cap_a=p$capped,cap_b=q$capped)
  if(a$status!="OK"||b$status!="OK")
    return(list(coverage=coverage,fields=list()))
  keys<-intersect(a$keys,b$keys)
  coverage$matched_keys<-length(keys)
  coverage$only_a<-length(setdiff(a$keys,b$keys))
  coverage$only_b<-length(setdiff(b$keys,a$keys))
  ia<-match(keys,a$keys);ib<-match(keys,b$keys)
  fields<-lapply(.w3_fields,function(field){
    record<-list(unit_index=unit_index,comparison=comparison,field=field,
      status="FIELD_NOT_SHARED",matched_keys=length(keys),
      compared_nonmissing=NA_integer_,exact_disagreements=NA_integer_,
      only_a_missing=NA_integer_,only_b_missing=NA_integer_,
      both_missing=NA_integer_,trim_only_differences=NA_integer_,
      entire_unit_disagrees=FALSE,constant_values_on_both_sides=FALSE)
    if(!(field%in%names(a$data))||!(field%in%names(b$data)))
      return(record)
    x<-as.character(a$data[[field]][ia])
    y<-as.character(b$data[[field]][ib])
    ax<-is.na(x);by<-is.na(y)
    good<-!ax&!by
    ne<-sum(x[good]!=y[good])
    trim_ne<-sum(x[good]!=y[good] & trimws(x[good])==trimws(y[good]))
    if(field=="fixation_duration"){
      xn<-suppressWarnings(as.numeric(x[good]))
      yn<-suppressWarnings(as.numeric(y[good]))
      numeric_valid<-is.finite(xn)&is.finite(yn)
      # Preserve both raw text difference and numerical equivalence:
      # numeric values can agree despite harmless formatting differences.
      record$duration_numeric_compared<-sum(numeric_valid)
      record$duration_numeric_different<-sum(abs(xn[numeric_valid]-
                                                  yn[numeric_valid])>1e-7)
    }
    record$status<-"COMPARED"
    record$compared_nonmissing<-sum(good)
    record$exact_disagreements<-ne
    record$only_a_missing<-sum(ax&!by)
    record$only_b_missing<-sum(by&!ax)
    record$both_missing<-sum(ax&by)
    record$trim_only_differences<-trim_ne
    record$entire_unit_disagrees<-length(keys)>0L && all(good) && ne==length(keys)
    record$constant_values_on_both_sides<-
      isTRUE(record$entire_unit_disagrees) &&
      length(unique(x))==1L && length(unique(y))==1L
    record
  })
  list(coverage=coverage,fields=fields)
}

.w3_frame <- function(rows) {
  if(!length(rows))return(data.frame())
  all_names<-unique(unlist(lapply(rows,names),use.names=FALSE))
  pieces<-lapply(rows,function(row){
    r<-as.list(rep(NA,length(all_names)));names(r)<-all_names
    for(n in names(row))r[[n]]<-row[[n]]
    as.data.frame(r,stringsAsFactors=FALSE,check.names=FALSE)
  })
  do.call(rbind,pieces)
}

w3_run <- function(root=Sys.getenv("ET_WAVE3_ROOT",
         file.path(Sys.getenv("USERPROFILE"),"Downloads","eyetrajectoriesValidation")),
         max_units=as.integer(Sys.getenv("ET_WAVE3_MAX_UNITS","900")),
         max_rows=as.integer(Sys.getenv("ET_WAVE3_MAX_ROWS","30000"))){
  stopifnot(dir.exists(root),length(max_units)==1L,is.finite(max_units),
    max_units>=1L,length(max_rows)==1L,is.finite(max_rows),max_rows>=100L)
  paths<-file.path(root,.w3_zipnames)
  names(paths)<-names(.w3_zipnames)
  if(!all(file.exists(paths)))
    stop("Missing source archive(s): ",paste(basename(paths[!file.exists(paths)]),collapse=", "))
  families<-lapply(names(paths),function(nm).w3_members(paths[[nm]],.w3_suffix[[nm]]))
  names(families)<-names(paths)
  common<-sort(Reduce(intersect,lapply(families,names)))
  selected<-head(common,max_units)
  out<-tempfile("EYETRAJECTORIES_WAVE3_FIELD_AUDIT_",tmpdir=root)
  if(!dir.create(out))stop("Cannot create evidence folder")
  cover<-list();details<-list()
  comparisons<-list(c("scanpaths","fixations"),
                    c("scanpaths","merged"),c("fixations","merged"))
  for(i in seq_along(selected)){
    key<-selected[[i]]
    p<-lapply(names(paths),function(nm)
      .w3_read(paths[[nm]],families[[nm]][[key]],max_rows))
    names(p)<-names(paths)
    for(pair in comparisons){
      comp<-paste(pair,collapse="_vs_")
      result<-.w3_compare(p[[pair[1L]]],p[[pair[2L]]],comp,i)
      cover[[length(cover)+1L]]<-result$coverage
      details<-c(details,result$fields)
    }
    if(i%%100L==0L)message("WAVE3_UNITS=",i,"/",length(selected))
  }
  coverage<-.w3_frame(cover)
  field_units<-.w3_frame(details)
  utils::write.csv(coverage,file.path(out,"comparison_coverage.csv"),
                   row.names=FALSE,na="")
  # Keep full field evidence without raw participant data or field values.
  utils::write.csv(field_units,file.path(out,"unit_field_diagnostics.csv"),
                   row.names=FALSE,na="")
  summaries<-list()
  for(comp in unique(field_units$comparison)){
    for(field in .w3_fields){
      z<-field_units[field_units$comparison==comp & field_units$field==field,,drop=FALSE]
      available<-z$status=="COMPARED"
      colsum<-function(n)sum(as.numeric(z[[n]][available]),na.rm=TRUE)
      summaries[[length(summaries)+1L]]<-list(comparison=comp,field=field,
        inspected_units=nrow(z),compared_units=sum(available),
        field_unavailable_units=sum(!available),
        compared_nonmissing=colsum("compared_nonmissing"),
        exact_disagreements=colsum("exact_disagreements"),
        only_a_missing=colsum("only_a_missing"),
        only_b_missing=colsum("only_b_missing"),
        both_missing=colsum("both_missing"),
        trim_only_differences=colsum("trim_only_differences"),
        entire_unit_disagreement_units=sum(z$entire_unit_disagrees[available]),
        constant_both_sides_units=sum(z$constant_values_on_both_sides[available]))
    }
  }
  sumframe<-.w3_frame(summaries)
  utils::write.csv(sumframe,file.path(out,"field_comparison_summary.csv"),
                   row.names=FALSE,na="")
  denom<-coverage[coverage$comparison=="scanpaths_vs_fixations",,drop=FALSE]
  md<-c("# Wave 3: source-specific per-field discrepancy diagnostics","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    "**Source ZIPs remain local and unchanged; no personal IDs or raw values exported.**","",
    paste0("Shared file units found: ",length(common),
           "; units inspected: ",length(selected),"."),
    paste0("Comparable scanpath vs fixation units: ",
           sum(denom$status=="COMPARABLE"),"."),
    paste0("Matched trial/fixation keys (scanpath vs fixation): ",
           sum(denom$matched_keys,na.rm=TRUE),"."),
    "",
    "| Comparison | Field | Compared cells | Exact unequal cells | Missingness mismatches |",
    "| --- | --- | ---: | ---: | ---: |")
  for(i in seq_len(nrow(sumframe))){
    x<-sumframe[i,,drop=FALSE]
    md<-c(md,sprintf("| %s | %s | %s | %s | %s |",
      x$comparison,x$field,x$compared_nonmissing,x$exact_disagreements,
      x$only_a_missing+x$only_b_missing))
  }
  md<-c(md,"",
   "Differences are per-field comparisons on matched (trial, fixation_index) keys.",
   "The same record can contribute more than one discrepancy; never interpret",
   "a field-cell disagreement total as a distinct participant or trial count.",
   "Fields absent from either side are recorded as unavailable, not as zero.",
   "A constant difference across a file may reflect a versioning or",
   "representation convention; it is NOT evidence of which file is correct.",
   "",
   "## Scientific limitations",
   "- This is a source-consistency diagnostic, not fixation truth, calibration",
   "  evidence, psychological interpretation or inferential calibration.",
   "- No OneStop paragraph CSVs are joined to these separate reader-file archives.",
   "- Check field definitions and preprocessing code before correcting values.",
   "- No published release, original input ZIP or historical result is modified.")
  writeLines(md,file.path(out,"WAVE3_SUMMARY.md"))
  writeLines(capture.output(utils::sessionInfo()),file.path(out,"R_session_info.txt"))
  message("WAVE3_FIELD_AUDIT_COMPLETED=",out)
  invisible(list(output=out,summary=sumframe,coverage=coverage,
                 unit_diagnostics=field_units))
}

if(!identical(tolower(Sys.getenv("ET_WAVE3_NO_AUTORUN")),"true"))w3_run()
