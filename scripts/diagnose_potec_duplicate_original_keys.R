# PoTeC duplicate-original-fixation-index diagnostic (R only; read-only).
# Designed after local 2026-11-17 validation found ONE ambiguous file
# (ordinal 182 / 900): corrected 1301 rows, uncorrected 1306 rows.
# The diagnostic NEVER resolves or deduplicates repeated fixation IDs by guess.
# It may certify only strict 1:1 original keys; ambiguous keys remain OPEN.
#
# Usage:
# Sys.setenv(ET_POTEC_DUP_NO_AUTORUN="true")
# source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/diagnose_potec_duplicate_original_keys.R"))
# result <- potec_diagnose_duplicate_stage(root="C:/.../eyetrajectoriesValidation")
#
# Outputs contain counts and unit ordinal, no reader, trial, raw AOI, timestamp
# or fixation index values. ZIPs are never changed or uploaded.

.pd_previous <- Sys.getenv("ET_POTEC_UNCORRECTED_NO_AUTORUN",unset=NA_character_)
Sys.setenv(ET_POTEC_UNCORRECTED_NO_AUTORUN="true")
.pd_helper <- file.path("scripts","validate_potec_uncorrected_stage.R")
if (file.exists(.pd_helper)) {
  source(.pd_helper,local=TRUE)
} else {
  source(base::url(paste0("https://raw.githubusercontent.com/stefanosbalaskas/",
       "eyetrajectories/44e7708ed1cff310c7a92adc7463dcec9d22b19c/",
       "scripts/validate_potec_uncorrected_stage.R")),local=TRUE)
}
if(is.na(.pd_previous))Sys.unsetenv("ET_POTEC_UNCORRECTED_NO_AUTORUN") else
  Sys.setenv(ET_POTEC_UNCORRECTED_NO_AUTORUN=.pd_previous)

.pd_keys <- function(d,index_field){
  if(!all(c("trial",index_field)%in%names(d)))
    return(list(status="KEY_COLUMNS_MISSING"))
  t<-as.character(d$trial)
  k<-as.character(d[[index_field]])
  okay<-!is.na(t)&nzchar(t)&!is.na(k)&nzchar(k)
  keys<-paste(t[okay],k[okay],sep="\r")
  counts<-table(keys)
  list(status="READ",keys=keys,valid_rows=which(okay),
       invalid_rows=sum(!okay),counts=counts,
       duplicate_groups=sum(counts>1L),
       duplicate_extra_rows=sum(pmax(0,counts-1L)),
       rows_in_duplicate_groups=sum(counts[counts>1L]),
       max_group_size=if(length(counts))max(counts) else 0L,
       distinct_trials=length(unique(t[!is.na(t)&nzchar(t)])),
       original_index_without_trial_duplicates=
           sum(duplicated(k[!is.na(k)&nzchar(k)])))
}
.pd_unit_evidence <- function(a,b,ordinal){
  common_fields<-list(ordinal=as.integer(ordinal),
    source_status=a$status,corrected_status=b$status,
    source_rows=if(identical(a$status,"READ"))nrow(a$data) else NA_integer_,
    corrected_rows=if(identical(b$status,"READ"))nrow(b$data) else NA_integer_,
    status="NOT_COMPARABLE",
    source_key_missing=NA_integer_,corrected_key_missing=NA_integer_,
    source_duplicate_groups=NA_integer_,
    corrected_duplicate_groups=NA_integer_,
    source_duplicate_extra_rows=NA_integer_,
    corrected_duplicate_extra_rows=NA_integer_,
    corrected_rows_in_ambiguous_keys=NA_integer_,
    source_rows_in_ambiguous_keys=NA_integer_,
    corrected_max_multiplicity=NA_integer_,
    original_index_duplicates_without_trial=NA_integer_,
    distinct_corrected_trial_labels=NA_integer_,
    strictly_unique_matched_keys=NA_integer_,
    strictly_unique_source_only=NA_integer_,
    strictly_unique_corrected_only=NA_integer_,
    unique_key_duration_compared=NA_integer_,
    unique_key_duration_differences=NA_integer_,
    unique_key_AOI_compared=NA_integer_,
    unique_key_AOI_differences=NA_integer_,
    unique_key_AOI_missing=NA_integer_)
  if(!identical(a$status,"READ")||!identical(b$status,"READ"))
    return(common_fields)
  ax<-.pd_keys(a$data,"fixation_index")
  bx<-.pd_keys(b$data,"original_fixation_index")
  if(ax$status!="READ"||bx$status!="READ"){
    common_fields$status=paste(ax$status,bx$status,sep="/")
    return(common_fields)
  }
  common_fields$source_key_missing<-ax$invalid_rows
  common_fields$corrected_key_missing<-bx$invalid_rows
  common_fields$source_duplicate_groups<-ax$duplicate_groups
  common_fields$corrected_duplicate_groups<-bx$duplicate_groups
  common_fields$source_duplicate_extra_rows<-ax$duplicate_extra_rows
  common_fields$corrected_duplicate_extra_rows<-bx$duplicate_extra_rows
  common_fields$corrected_max_multiplicity<-bx$max_group_size
  common_fields$original_index_duplicates_without_trial <-
    bx$original_index_without_trial_duplicates
  common_fields$distinct_corrected_trial_labels<-bx$distinct_trials
  # If the same key repeats in either source, NONE of those records is
  # eligible for unambiguous cross-stage row matching.
  ambiguous<-union(names(ax$counts)[ax$counts>1L],
                   names(bx$counts)[bx$counts>1L])
  common_fields$corrected_rows_in_ambiguous_keys <-
    sum(as.integer(bx$counts[intersect(names(bx$counts),ambiguous)]))
  common_fields$source_rows_in_ambiguous_keys <-
    sum(as.integer(ax$counts[intersect(names(ax$counts),ambiguous)]))
  good_a<-setdiff(names(ax$counts)[ax$counts==1L],ambiguous)
  good_b<-setdiff(names(bx$counts)[bx$counts==1L],ambiguous)
  both<-intersect(good_a,good_b)
  common_fields$strictly_unique_matched_keys<-length(both)
  common_fields$strictly_unique_source_only<-length(setdiff(good_a,good_b))
  common_fields$strictly_unique_corrected_only<-length(setdiff(good_b,good_a))
  common_fields$status<-if(!length(ambiguous)&&!ax$invalid_rows&&!bx$invalid_rows)
    "ALL_KEYS_UNIQUE" else "PARTIAL_UNAMBIGUOUS_ONLY"
  if(!length(both))return(common_fields)
  # Mapping keys themselves never leave this process.
  ai<-ax$valid_rows[match(both,ax$keys)]
  bi<-bx$valid_rows[match(both,bx$keys)]
  if(all(c("fixation_duration")%in%names(a$data)) &&
     all(c("fixation_duration")%in%names(b$data))){
    da<-suppressWarnings(as.numeric(a$data$fixation_duration[ai]))
    db<-suppressWarnings(as.numeric(b$data$fixation_duration[bi]))
    good<-is.finite(da)&is.finite(db)
    common_fields$unique_key_duration_compared<-sum(good)
    common_fields$unique_key_duration_differences<-
      sum(abs(da[good]-db[good])>1e-7)
  }
  if("aoi"%in%names(a$data)&&"aoi"%in%names(b$data)){
    va<-as.character(a$data$aoi[ai])
    vb<-as.character(b$data$aoi[bi])
    good<-!is.na(va)&!is.na(vb)
    common_fields$unique_key_AOI_compared<-sum(good)
    common_fields$unique_key_AOI_missing<-sum(!good)
    common_fields$unique_key_AOI_differences<-sum(va[good]!=vb[good])
  }
  common_fields
}
potec_diagnose_duplicate_stage <- function(
  root=Sys.getenv("ET_SCI_ROOT",file.path(Sys.getenv("USERPROFILE"),
       "Downloads","eyetrajectoriesValidation")),
  ordinals=as.integer(strsplit(Sys.getenv("ET_POTEC_DUP_ORDINALS","182"),
                       ",",fixed=TRUE)[[1L]]),
  max_rows=as.integer(Sys.getenv("ET_POTEC_DUP_MAX_ROWS","50000"))){
  stopifnot(dir.exists(root),length(ordinals)>=1L,
            all(is.finite(ordinals)&ordinals>=1L),
            length(max_rows)==1L,is.finite(max_rows),max_rows>=100L)
  uncorrected_zip <- file.path(root,"fixations_uncorrected.zip")
  corrected_zip <- file.path(root,"fixations.zip")
  if(!all(file.exists(c(uncorrected_zip,corrected_zip))))
    stop("Both original PoTeC source ZIPs must be present locally")
  orig<-.pu_clean_members(uncorrected_zip,"_uncorrected_fixations")
  corrected<-.pu_clean_members(corrected_zip,"_fixations")
  common<-sort(intersect(names(orig),names(corrected)))
  if(any(ordinals>length(common)))stop("Ordinal outside matched file range")
  out<-tempfile("POTEC_ORIGINAL_INDEX_DIAGNOSTIC_",tmpdir=root)
  if(!dir.create(out))stop("Failed creating new result folder")
  rows<-list()
  for(i in seq_along(ordinals)){
    ordinal<-ordinals[[i]]
    stem<-common[[ordinal]]
    a<-.pu_read(uncorrected_zip,orig[[stem]],
      c("trial","fixation_index","fixation_duration","aoi"),max_rows)
    b<-.pu_read(corrected_zip,corrected[[stem]],
      c("trial","original_fixation_index","fixation_duration","aoi"),max_rows)
    if(isTRUE(a$capped)||isTRUE(b$capped))
      stop("Row cap reached: increase ET_POTEC_DUP_MAX_ROWS; no partial pass")
    rows[[i]]<-.pd_unit_evidence(a,b,ordinal)
  }
  df<-.pu_rows_df(rows)
  utils::write.csv(df,file.path(out,"ambiguous_index_diagnostics.csv"),
                   row.names=FALSE,na="")
  md<-c("# PoTeC correction-stage ambiguous original-index diagnostic","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("File sets inspected: ",length(ordinals),"; ordinals: ",
           paste(ordinals,collapse=", ")),"",
    "| Ordinal | Status | Source repeated-key groups | Corrected repeated-key groups | Corrected rows in ambiguous groups | Strictly unique matched keys | Strict unique duration disagreements |",
    "| --- | --- | ---: | ---: | ---: | ---: | ---: |")
  for(i in seq_len(nrow(df))){
    x<-df[i,]
    md<-c(md,sprintf("| %d | %s | %s | %s | %s | %s | %s |",
      x$ordinal,x$status,x$source_duplicate_groups,
      x$corrected_duplicate_groups,x$corrected_rows_in_ambiguous_keys,
      x$strictly_unique_matched_keys,x$unique_key_duration_differences))
  }
  md<-c(md,"",
    "Only keys occurring EXACTLY ONCE on BOTH sides are paired.",
    "Repeated keys are not resolved with row order, duration or AOI heuristics.",
    "Original uncorr fixation_index is matched to corrected",
    "original_fixation_index inside one common reader/text stem.",
    "This is NOT raw ASC event-time validation or eye-tracker calibration.",
    "No original IDs, trial labels, AOIs or coordinates are exported.",
    "Any unresolved repeated groups require source-author provenance or",
    "stage-specific additional event ID before scientific certification.",
    "All original source ZIPs remain unchanged.")
  writeLines(md,file.path(out,"AMBIGUITY_DIAGNOSTIC.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(out,"R_session_info.txt"))
  message("POTEC_DUPLICATE_DIAGNOSTIC_RESULTS=",out)
  invisible(list(output=out,diagnostics=df))
}
if(!identical(tolower(Sys.getenv("ET_POTEC_DUP_NO_AUTORUN")),"true"))
  potec_diagnose_duplicate_stage()
