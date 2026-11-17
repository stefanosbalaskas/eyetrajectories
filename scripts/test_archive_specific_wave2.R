# Synthetic-only Wave 2 crosswalk qualification, no personal gaze data.
Sys.setenv(ET_WAVE2_NO_AUTORUN="true")
source("scripts/qualify_archive_specific_wave2.R",local=FALSE)
stopifnot(identical(.w2_stem("scanpaths/reader1_p0_scanpath.tsv","_scanpath"),"reader1_p0"))
stopifnot(identical(.w2_stem("scanpaths_merged/reader1_p0_merged_sp_rm.tsv","_merged_sp_rm"),"reader1_p0"))
stopifnot(identical(.w2_stem("fixations/reader1_p0_fixations.tsv","_fixations"),"reader1_p0"))

make <- function(dur=c(50,60,75)) data.frame(
  fixation_index=c("0","1","2"),original_fixation_index=c("0","1","2"),
  trial=rep("t1",3),reader_id=rep("r",3),text_id=rep("text1",3),
  text_domain=rep("a",3),fixation_duration=as.character(dur),
  aoi=c("w1","w2","w3"),is_fixation_adjusted=rep("0",3),
  version=rep("v1",3),check.names=FALSE)
x<-make();y<-make();z<-make(c(50,61,75))
expected<-.w2_crosswalk(x,y)
stopifnot(expected$comparison=="OBSERVED_KEY_CROSSWALK",
          expected$matched==3L,expected$only_a==0L,expected$only_b==0L,
          expected$shared_field_mismatches==0L,
          expected$duration_disagreements==0L)
different<-.w2_crosswalk(x,z)
stopifnot(different$duration_disagreements==1L)
duplicates<-rbind(x,x[1L,,drop=FALSE])
stopifnot(.w2_crosswalk(x,duplicates)$comparison=="NOT_COMPARABLE")
stopifnot(.w2_crosswalk(x,data.frame(other=1:3))$comparison=="NOT_COMPARABLE")
if (!nzchar(Sys.which("zip"))) stop("ZIP binary required for end-to-end CI")

root<-tempfile("et_wave2_")
dir.create(root)
for(nm in c("scanpaths","scanpaths_merged","fixations"))
  dir.create(file.path(root,nm))
dir.create(file.path(root,"asc_files"))
for(key in c("reader1_p0","reader2_p0")){
  for(nm in c("scanpaths","scanpaths_merged","fixations")){
    suffix<-switch(nm,scanpaths="_scanpath",scanpaths_merged="_merged_sp_rm",
                   fixations="_fixations")
    value<-if(nm=="scanpaths_merged" && key=="reader1_p0")z else x
    utils::write.table(value,file.path(root,nm,paste0(key,suffix,".tsv")),
      sep="\t",quote=FALSE,row.names=FALSE)
  }
}
for(nm in c("ia_Paragraph_repeated.csv","ia_Paragraph_ordinary.csv")){
  dat<-data.frame(participant_id=c("p1","p1","p2"),TRIAL_INDEX=c("1","1","2"),
    IA_ID=c("a","b","a"),IA_LEFT=c(1,1,10),IA_RIGHT=c(2,3,4),
    IA_TOP=c(1,2,3),IA_BOTTOM=c(4,5,6),
    IA_DWELL_TIME=c(90,-1,50),IA_FIXATION_COUNT=c(3,1,0),
    IA_FIRST_FIXATION_TIME=c(20,30,50),IA_LAST_FIXATION_TIME=c(40,50,40),
    IA_FIRST_RUN_START_TIME=c(10,10,20),IA_FIRST_RUN_END_TIME=c(50,20,35))
  utils::write.csv(dat,file.path(root,nm),row.names=FALSE)
}
writeLines(c("MSG 10 START","SFIX R 10","100 200 300 400","EFIX R 10 20 10 2 3"),
           file.path(root,"asc_files","1.asc"))
make_zip <- function(zip, members) {
  previous<-getwd();setwd(root)
  on.exit(setwd(previous),add=TRUE)
  utils::zip(zip, files=members, flags="-q")
}
for(nm in c("scanpaths","scanpaths_merged","fixations")){
  members<-paste0(nm,"/",list.files(file.path(root,nm)))
  make_zip(paste0(nm,".zip"),members)
}
for(nm in c("ia_Paragraph_repeated.csv","ia_Paragraph_ordinary.csv"))
  make_zip(paste0(nm,".zip"),nm)
make_zip("asc_files.zip","asc_files/1.asc")
sourceArchives<-list.files(root,pattern="\\.zip$",full.names=TRUE)
before<-tools::md5sum(sourceArchives)
result<-w2_run(root,max_units=2L,max_rows=100L,max_asc_files=1L,
               max_asc_lines=100L)
after<-tools::md5sum(sourceArchives)
stopifnot(identical(before,after),result$summary$matched_triplets==2L,
          result$summary$sampled_triplets==2L)
stopifnot(length(result$rows)==2L,
          sum(vapply(result$rows,function(z)z$scan_to_merged_duration_disagreements,
                     numeric(1L)))==1L)
stopifnot(all(vapply(result$ia,function(z)identical(z$status,"OBSERVED_NOT_CERTIFIED"),logical(1L))))
stopifnot(sum(vapply(result$ia,function(z)z$geometry_violations,numeric(1L)))==2L)
stopifnot(sum(vapply(result$ia,function(z)z$dwell_negative,numeric(1L)))==2L)
stopifnot(length(result$asc)==1L,result$asc[[1L]]$efix==1L,
          result$asc[[1L]]$sfix==1L)
for(f in c("family_manifest.csv","unit_crosswalk.csv","ia_quality.csv",
           "asc_event_samples.csv","WAVE2_SUMMARY.md","R_session_info.txt"))
  stopifnot(file.exists(file.path(result$output,f)))
stopifnot(!grepl("reader1_p0",paste(readLines(file.path(result$output,"WAVE2_SUMMARY.md")),
                                    collapse=" "),fixed=TRUE))
cat("ARCHIVE_SPECIFIC_WAVE2_SYNTHETIC_TEST_PASS\n")
