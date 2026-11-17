# PoTeC 2026-11-18: two-row duplicate original-index provenance.
# Diagnostic only. Never infer which corrected row is "the" original.
# Reads the author's original uncorrected ZIP and corrected ZIP locally.
# Exports no reader/text IDs, original fixation indices, AOIs or timestamps.
# Author correction code stores ORIGINAL_CURRENT_FIX_INDEX then reindexes;
# historical duplicate may reflect an extra corrected row or index collision.
# Do not assume the cause until original report and correction record confirm.
#
# Run: source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/profile_potec_ambiguous_pair.R"))
# Optional ET_POTEC_PAIR_ORDINAL=182; ET_POTEC_PAIR_NO_AUTORUN=true.

.pp_prior<-Sys.getenv("ET_POTEC_DUP_NO_AUTORUN",unset=NA_character_)
Sys.setenv(ET_POTEC_DUP_NO_AUTORUN="true")
.pp_file<-file.path("scripts","diagnose_potec_duplicate_original_keys.R")
if(file.exists(.pp_file)) {
  source(.pp_file,local=TRUE)
} else {
  source(base::url(paste0(
    "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/",
    "090f309c0d0670b35834800a55ea419fd313127f/",
    "scripts/diagnose_potec_duplicate_original_keys.R")),local=TRUE)
}
if(is.na(.pp_prior))Sys.unsetenv("ET_POTEC_DUP_NO_AUTORUN") else
  Sys.setenv(ET_POTEC_DUP_NO_AUTORUN=.pp_prior)

.pp_num<-function(x)suppressWarnings(as.numeric(as.character(x)))
.pp_bool<-function(x) {
  z<-tolower(trimws(as.character(x)))
  z %in% c("true","t","yes","1")
}
.pp_profile<-function(a,b,ordinal) {
  if(!identical(a$status,"READ")||!identical(b$status,"READ"))
    stop("Source inputs unreadable")
  ka<-.pd_keys(a$data,"fixation_index")
  kb<-.pd_keys(b$data,"original_fixation_index")
  if(!identical(ka$status,"READ")||!identical(kb$status,"READ"))
    stop("Fixation original-key fields missing")
  dup<-names(kb$counts)[kb$counts>1L]
  if(!length(dup))stop("No corrected original-index duplicate in unit ",ordinal)
  n<-nrow(b$data)
  corr_idx_unique<-NA
  if("fixation_index" %in% names(b$data)) {
    v<-as.character(b$data$fixation_index)
    corr_idx_unique<-all(!is.na(v)&nzchar(v))&&!anyDuplicated(v)
  }
  rows<-lapply(seq_along(dup),function(i){
    key<-dup[[i]]
    ia<-ka$valid_rows[which(ka$keys==key)]
    ib<-kb$valid_rows[which(kb$keys==key)]
    srcduration<-if("fixation_duration"%in%names(a$data)) .pp_num(a$data$fixation_duration[ia]) else numeric()
    cduration<-if("fixation_duration"%in%names(b$data)) .pp_num(b$data$fixation_duration[ib]) else numeric()
    comparisons<-if(length(srcduration)==1L&&is.finite(srcduration) &&
                    length(cduration)==length(ib))
      sum(is.finite(cduration)&abs(cduration-srcduration)<=1e-7) else NA_integer_
    distinct_durations<-if(length(cduration))length(unique(cduration)) else NA_integer_
    aoi<-if("aoi"%in%names(b$data))as.character(b$data$aoi[ib]) else character()
    source_aoi<-if("aoi"%in%names(a$data))as.character(a$data$aoi[ia]) else character()
    flags<-if("is_fixation_adjusted"%in%names(b$data))
      .pp_bool(b$data$is_fixation_adjusted[ib]) else logical()
    # Previous exports only reported marginal duration/AOI match counts.
    # Count their intersection on the SAME corrected row without exporting
    # identifiers or any original values; this is still not identity truth.
    possible_joint<-length(srcduration)==1L&&is.finite(srcduration) &&
      length(cduration)==length(ib)&&length(aoi)==length(ib) &&
      length(source_aoi)==1L&&!is.na(source_aoi)
    joint_count<-if(possible_joint)sum(
      is.finite(cduration)&abs(cduration-srcduration)<=1e-7 &
      !is.na(aoi)&aoi==source_aoi) else NA_integer_
    duration_only<-if(possible_joint)sum(
      is.finite(cduration)&abs(cduration-srcduration)<=1e-7 &
      (is.na(aoi)|aoi!=source_aoi)) else NA_integer_
    aoi_only<-if(possible_joint)sum(
      !is.na(aoi)&aoi==source_aoi &
      !(is.finite(cduration)&abs(cduration-srcduration)<=1e-7)) else NA_integer_
    list(unit_ordinal=ordinal,duplicate_group_ordinal=i,
      corrected_group_size=length(ib),uncorrected_group_size=length(ia),
      duplicate_extra_corrected_rows=length(ib)-1L,
      distinct_corrected_durations=distinct_durations,
      corrected_durations_equal_source_count=comparisons,
      corrected_AOI_nonmissing=if(length(aoi))sum(!is.na(aoi)) else NA_integer_,
      corrected_AOI_distinct_nonmissing=if(length(aoi))
         length(unique(aoi[!is.na(aoi)])) else NA_integer_,
      corrected_AOI_equal_to_source_count=if(length(aoi)&&length(source_aoi)==1L&&
        !is.na(source_aoi))sum(!is.na(aoi)&aoi==source_aoi) else NA_integer_,
      same_row_duration_and_AOI_match_count=joint_count,
      duration_match_but_AOI_not_match_count=duration_only,
      AOI_match_but_duration_not_match_count=aoi_only,
      corrected_adjustment_flags=if(length(flags))sum(flags) else NA_integer_,
      corrected_rows_adjacent=if(length(ib)>1L)
        all(diff(sort(ib))==1L) else NA,
      corrected_fixation_index_unique_for_unit=corr_idx_unique,
      source_original_key_unique=length(ia)==1L,
      row_cap_reached=isTRUE(a$capped)||isTRUE(b$capped),
      status="UNRESOLVED_DO_NOT_AUTO_PAIR")
  })
  do.call(rbind,lapply(rows,function(x)as.data.frame(x,
    stringsAsFactors=FALSE,check.names=FALSE)))
}
potec_profile_duplicate_pair<-function(
  root=Sys.getenv("ET_SCI_ROOT",file.path(Sys.getenv("USERPROFILE"),
    "Downloads","eyetrajectoriesValidation")),
  ordinal=as.integer(Sys.getenv("ET_POTEC_PAIR_ORDINAL","182")),
  max_rows=as.integer(Sys.getenv("ET_POTEC_PAIR_MAX_ROWS","50000"))) {
  stopifnot(dir.exists(root),length(ordinal)==1L,is.finite(ordinal),
            ordinal>=1L,length(max_rows)==1L,is.finite(max_rows),max_rows>=100L)
  origzip<-file.path(root,"fixations_uncorrected.zip")
  corrzip<-file.path(root,"fixations.zip")
  if(!file.exists(origzip)||!file.exists(corrzip))
    stop("Source ZIPs absent: require uncorrected and corrected PoTeC files")
  stems_a<-.pu_clean_members(origzip,"_uncorrected_fixations")
  stems_b<-.pu_clean_members(corrzip,"_fixations")
  common<-sort(intersect(names(stems_a),names(stems_b)))
  if(ordinal>length(common))stop("Ordinal exceeds common unit count")
  stem<-common[[ordinal]]
  a<-.pu_read(origzip,stems_a[[stem]],c("trial","fixation_index",
          "fixation_duration","aoi"),max_rows)
  b<-.pu_read(corrzip,stems_b[[stem]],c("trial","original_fixation_index",
          "fixation_index","fixation_duration","aoi","is_fixation_adjusted"),max_rows)
  if(isTRUE(a$capped)||isTRUE(b$capped))
    stop("Source input reached cap: never certify incomplete member")
  profile<-.pp_profile(a,b,ordinal)
  out<-tempfile("POTEC_DUPLICATE_PAIR_PROFILE_",tmpdir=root)
  if(!dir.create(out))stop("Cannot create result directory")
  utils::write.csv(profile,file.path(out,"duplicate_pair_metadata.csv"),
                   row.names=FALSE,na="")
  description<-c("# PoTeC duplicated original-index pair — metadata only","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),"",
    paste0("Unit ordinal: ",ordinal,". Duplicate groups: ",nrow(profile),"."),
    paste0("Distinct corrected group sizes: ",
           paste(profile$corrected_group_size,collapse=", "),"."),
    paste0("Source original-index group sizes: ",
           paste(profile$uncorrected_group_size,collapse=", "),"."),
    paste0("Duration matches to unique source (candidate counts): ",
           paste(profile$corrected_durations_equal_source_count,collapse=", "),"."),
    paste0("Corrected AOI labels within each group: ",
           paste(profile$corrected_AOI_distinct_nonmissing,collapse=", "),
           " distinct nonmissing values."),
    paste0("SAME corrected row matching BOTH source duration and AOI: ",
           paste(profile$same_row_duration_and_AOI_match_count,collapse=", "),"."),
    paste0("Duration match with AOI mismatch: ",
           paste(profile$duration_match_but_AOI_not_match_count,collapse=", "),"."),
    paste0("AOI match with duration mismatch: ",
           paste(profile$AOI_match_but_duration_not_match_count,collapse=", "),"."),
    "",
    "**No unique correction-stage pairing has been established for the",
    "two originally ambiguous corrected rows.** Duration equality, adjacency",
    "and AOI values are insufficient to assign physical/event identity.",
    "The published correction script may drop rows and reindex corrected",
    "fixation IDs. Actual duplicate cause requires additional stage provenance.",
    "All raw source ZIPs remain unchanged. No personal IDs or raw values exported.",
    "",
    "Upstream correction logic:",
    "https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/correct_fixations.py",
    "Original exported fixation report is described by the authors, but",
    "availability of a machine-readable full report on the local PC is",
    "not assumed by this run.")
  writeLines(description,file.path(out,"DUPLICATE_PAIR_SCOPE.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(out,"R_session_info.txt"))
  message("POTEC_DUPLICATE_PAIR_PROFILE=",out)
  invisible(list(output=out,profile=profile))
}
if(!identical(tolower(Sys.getenv("ET_POTEC_PAIR_NO_AUTORUN")),"true"))
  potec_profile_duplicate_pair()
