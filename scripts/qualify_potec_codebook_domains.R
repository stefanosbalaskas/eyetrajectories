# PoTeC Wave 5 — published-codebook anchored text-domain audit (R only).
# PoTeC: 75 readers x 12 texts. This corpus is NOT OneStop.
# Pinned upstream Wave 4 helper implementation is used only for ZIP parsing.
# All original archives are read-only; no original reader IDs or raw trials exported.
# Set ET_POTEC_NO_AUTORUN=true to load functions without running them.

.old_w4 <- Sys.getenv("ET_WAVE4_NO_AUTORUN",unset=NA_character_)
Sys.setenv(ET_WAVE4_NO_AUTORUN="true")
.w4_path <- file.path("scripts","qualify_wave4_text_domain_provenance.R")
if(file.exists(.w4_path)){
  source(.w4_path,local=TRUE)
} else {
  source(url(paste0(
    "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/",
    "5aee1bec8931070dd851ebfc38523830ccdfdb23/",
    "scripts/qualify_wave4_text_domain_provenance.R")),local=TRUE)
}
if(is.na(.old_w4))Sys.unsetenv("ET_WAVE4_NO_AUTORUN") else
  Sys.setenv(ET_WAVE4_NO_AUTORUN=.old_w4)

.p5_labels <- c("bio","biology","physics")
.p5_reference <- data.frame(
  source=rep(c("scanpaths","merged","fixations"),each=3L),
  label=rep(.p5_labels,3L),
  expected=c(4682L,200017L,199721L,
             4682L,200017L,199721L,
             203667L,1032L,199721L),
  stringsAsFactors=FALSE)

.p5_norm <- function(v){
  x<-tolower(trimws(as.character(v)))
  x[x=="bio"] <- "biology"
  x[is.na(v)|!(x %in% c("biology","physics"))] <- NA_character_
  x
}
.p5_pair <- function(a,b) {
  if(!identical(a$status,"OK")||!identical(b$status,"OK"))
    return(c(matched=NA_real_,key_loss=NA_real_,
             raw_diff=NA_real_,normalized_diff=NA_real_))
  common<-intersect(a$key,b$key)
  ia<-match(common,a$key);ib<-match(common,b$key)
  x<-a$domain[ia];y<-b$domain[ib]
  nx<-.p5_norm(x);ny<-.p5_norm(y)
  c(matched=length(common),
    key_loss=length(setdiff(a$key,b$key))+length(setdiff(b$key,a$key)),
    raw_diff=sum(is.na(x)|is.na(y)|x!=y,na.rm=TRUE),
    normalized_diff=sum(is.na(nx)|is.na(ny)|nx!=ny,na.rm=TRUE))
}
.p5_expected <- function(stem){
  if(grepl("_b[0-5]$",stem))return("biology")
  if(grepl("_p[0-5]$",stem))return("physics")
  NA_character_
}
.p5_source_counts <- function(z,source){
  x<-tolower(trimws(as.character(z$domain)))
  data.frame(source=source,label=.p5_labels,
             observed=as.integer(table(factor(x,levels=.p5_labels))),
             unknown=sum(is.na(.p5_norm(z$domain))))
}
.p5_rows <- function(x){
  do.call(rbind,lapply(x,function(y)as.data.frame(y,
       stringsAsFactors=FALSE,check.names=FALSE)))
}
potec_codebook_audit <- function(
  root=Sys.getenv("ET_POTEC_ROOT",file.path(
    Sys.getenv("USERPROFILE"),"Downloads","eyetrajectoriesValidation")),
  max_units=as.integer(Sys.getenv("ET_POTEC_MAX_UNITS","900")),
  max_rows=as.integer(Sys.getenv("ET_POTEC_MAX_ROWS","30000"))){
  stopifnot(dir.exists(root),length(max_units)==1L,is.finite(max_units),
            max_units>=1L,length(max_rows)==1L,is.finite(max_rows),max_rows>=100L)
  names_zip<-c(scanpaths="scanpaths.zip",merged="scanpaths_merged.zip",
               fixations="fixations.zip")
  suffix<-c(scanpaths="_scanpath",merged="_merged_sp_rm",
            fixations="_fixations")
  paths<-file.path(root,unname(names_zip));names(paths)<-names(names_zip)
  if(!all(file.exists(paths)))stop("Required PoTeC archives missing")
  manifests<-lapply(names(paths),function(k).w4_manifest(paths[[k]],suffix[[k]]))
  names(manifests)<-names(paths)
  stems<-sort(Reduce(intersect,lapply(manifests,names)))
  selected<-head(stems,max_units)
  out<-tempfile("EYETRAJECTORIES_POTEC_CODEBOOK_AUDIT_",tmpdir=root)
  if(!dir.create(out))stop("Cannot create unique evidence folder")
  totals<-data.frame(source=.p5_reference$source,label=.p5_reference$label,
                     observed=rep(0,9L))
  rows<-list()
  for(i in seq_along(selected)){
    stem<-selected[[i]]
    z<-lapply(names(paths),function(k)
      .w4_get(paths[[k]],manifests[[k]][[stem]],max_rows))
    names(z)<-names(paths)
    okay<-all(vapply(z,function(s)identical(s$status,"OK"),logical(1L)))
    if(!okay){
      rows[[i]]<-list(unit=i,status="SOURCE_ERROR",
        group="UNAVAILABLE",matched=NA_integer_,raw_differences=NA_integer_,
        canonical_differences=NA_integer_,crosswalk_key_loss=NA_integer_,
        unexpected_domain_cells=NA_integer_,stem_domain_mismatches=NA_integer_,
        capped=NA)
      next
    }
    for(k in names(z)){
      counts<-.p5_source_counts(z[[k]],k)
      ix<-which(totals$source==k)
      totals$observed[ix]<-totals$observed[ix]+counts$observed
    }
    pairs<-list(.p5_pair(z$scanpaths,z$fixations),
                .p5_pair(z$scanpaths,z$merged),
                .p5_pair(z$fixations,z$merged))
    expected<-.p5_expected(stem)
    unknown<-sum(vapply(z,function(s)sum(is.na(.p5_norm(s$domain))),
                        integer(1L)))
    stem_bad<-if(is.na(expected))sum(vapply(z,function(s)s$rows,integer(1L)))
      else sum(vapply(z,function(s)
        sum(is.na(.p5_norm(s$domain))|
            .p5_norm(s$domain)!=expected,na.rm=TRUE),integer(1L)))
    rows[[i]]<-list(unit=i,status="READ",
      group=if(is.na(expected))"UNRECOGNIZED" else expected,
      matched=unname(pairs[[1]]["matched"]),
      raw_differences=unname(pairs[[1]]["raw_diff"]),
      canonical_differences=sum(vapply(pairs,
        function(p)unname(p["normalized_diff"]),numeric(1L))),
      crosswalk_key_loss=sum(vapply(pairs,
        function(p)unname(p["key_loss"]),numeric(1L))),
      unexpected_domain_cells=unknown,stem_domain_mismatches=stem_bad,
      capped=any(vapply(z,function(s)isTRUE(s$capped),logical(1L))))
    if(i%%100L==0L)message("POTEC_CODEBOOK_UNITS=",i,"/",length(selected))
  }
  audit<-.p5_rows(rows)
  utils::write.csv(audit,file.path(out,"potec_unit_contracts.csv"),
                   row.names=FALSE,na="")
  frequencies<-merge(totals,.p5_reference,by=c("source","label"),sort=FALSE)
  frequencies$count_difference<-frequencies$observed-frequencies$expected
  utils::write.csv(frequencies,file.path(out,"potec_codebook_frequencies.csv"),
                   row.names=FALSE)
  full<-length(stems)==900L && length(selected)==900L &&
     all(vapply(manifests,length,integer(1L))==900L) &&
     all(audit$status=="READ") && !any(audit$capped)
  sumcol<-function(name)sum(as.numeric(audit[[name]]),na.rm=TRUE)
  aligned<-full &&
    sumcol("canonical_differences")==0 &&
    sumcol("crosswalk_key_loss")==0 &&
    sumcol("unexpected_domain_cells")==0 &&
    sumcol("stem_domain_mismatches")==0
  codebook_match<-full && all(frequencies$count_difference==0L)
  state<-if(aligned&&codebook_match)
    "POTEC_CODEBOOK_SOURCE_LABEL_RECONCILIATION_PASS" else
    "CHECK_INCOMPLETE_OR_DIFFERING_INPUTS"
  md<-c("# PoTeC codebook reconciliation, Wave 5","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),"",
    paste0("**Status: ",state,"**"),"",
    "This source is PoTeC, not the separate OneStop fixation corpus.",
    "Official codebook: https://github.com/DiLi-Lab/PoTeC/blob/main/CODEBOOK.md",
    "Article: Jakobi et al. (2025), DOI 10.3758/s13428-024-02536-8.",
    "",
    paste0("File units: ",length(stems),"; inspected: ",length(selected)),
    paste0("Matched fixation records: ",sumcol("matched")),
    paste0("Raw scanpath/fixation text_domain differences: ",
           sumcol("raw_differences")),
    paste0("All three pairwise canonical-label differences: ",
           sumcol("canonical_differences")),
    paste0("Key losses across all three comparisons: ",
           sumcol("crosswalk_key_loss")),
    paste0("Unexpected text_domain cells: ",
           sumcol("unexpected_domain_cells")),
    paste0("Disagreement with biology/physics text-ID filename: ",
           sumcol("stem_domain_mismatches")),
    paste0("Exact published source-label counts reproduced: ",codebook_match),
    "",
    "| Source | Raw label | Observed | Published | Difference |",
    "| --- | --- | ---: | ---: | ---: |")
  for(i in seq_len(nrow(frequencies))){
    f<-frequencies[i,]
    md<-c(md,sprintf("| %s | %s | %d | %d | %d |",
      f$source,f$label,f$observed,f$expected,f$count_difference))
  }
  md<-c(md,"",
    "Canonical mapping used in memory only: bio -> biology; biology -> biology;",
    "physics -> physics. Unknown text labels fail the contract.",
    "This is a codebook-anchored source consistency result, NOT independent",
    "gaze calibration, event truth, statistical validity or certification of",
    "every scientific method in eyetrajectories.",
    "Original ZIPs and frozen version 0.4.3 remain unchanged.",
    "OneStop and PoTeC are distinct datasets and are never joined.")
  writeLines(md,file.path(out,"POTEC_CODEBOOK_RECONCILIATION.md"))
  writeLines(capture.output(utils::sessionInfo()),file.path(out,"R_session_info.txt"))
  message("POTEC_CODEBOOK_AUDIT=",state," OUTPUT=",out)
  invisible(list(status=state,output=out,counts=frequencies,units=audit))
}
if(!identical(tolower(Sys.getenv("ET_POTEC_NO_AUTORUN")),"true"))
  potec_codebook_audit()
