# Synthetic-only PoTeC original-index stage crosswalk and paired algorithm CI.
Sys.setenv(ET_POTEC_UNCORRECTED_NO_AUTORUN="true",
           ET_PAIRED_L2_NO_AUTORUN="true")
source("scripts/validate_potec_uncorrected_stage.R",local=FALSE)
source("scripts/benchmark_paired_l2_versions.R",local=FALSE)

uncorrected<-list(status="READ",data=data.frame(
  trial=c("1","1","1","1"),fixation_index=c("1","2","3","4"),
  fixation_duration=c("100","125","60","80"),aoi=c("5","7","8","9"),
  stringsAsFactors=FALSE))
corrected<-list(status="READ",data=data.frame(
  trial=c("1","1","1"),original_fixation_index=c("1","3","4"),
  fixation_duration=c("100","60","80"),aoi=c("5","18","9"),
  is_fixation_adjusted=c("FALSE","TRUE","FALSE"),
  stringsAsFactors=FALSE))
x<-.pu_match(uncorrected,corrected)
stopifnot(x$status=="SOURCE_ORIGINAL_INDEX_CROSSWALK",
          x$uncorrected_rows==4L,x$corrected_rows==3L,
          x$matched_original_keys==3L,x$uncorrected_only_keys==1L,
          x$corrected_only_keys==0L,x$duration_disagreements==0L,
          x$aoi_differences==1L,x$flagged_corrections==1L)
incorrect<-corrected
incorrect$data$fixation_duration[2L]<-"120"
stopifnot(.pu_match(uncorrected,incorrect)$duration_disagreements==1L)
incorrect2<-corrected
incorrect2$data$original_fixation_index[3L]<-"3"
stopifnot(.pu_match(uncorrected,incorrect2)$status=="OK/DUPLICATE_TRIAL_ORIGINAL_INDEX")

if(!nzchar(Sys.which("zip")))stop("CI requires ZIP program")
root<-tempfile("potec_fixture_");dir.create(root)
for(folder in c("fixations","fixations_uncorrected"))dir.create(file.path(root,folder))
for(k in c("reader1_b0","reader2_p1")){
  a<-uncorrected$data;b<-corrected$data
  utils::write.table(a,file.path(root,"fixations_uncorrected",
    paste0(k,"_uncorrected_fixations.tsv")),sep="\t",quote=FALSE,row.names=FALSE)
  utils::write.table(b,file.path(root,"fixations",
    paste0(k,"_fixations.tsv")),sep="\t",quote=FALSE,row.names=FALSE)
}
zipfile<-function(folder,name){
  wd<-getwd();setwd(root);on.exit(setwd(wd),add=TRUE)
  utils::zip(name,paste0(folder,"/",list.files(folder)),flags="-q")
}
zipfile("fixations","fixations.zip")
zipfile("fixations_uncorrected","fixations_uncorrected.zip")
before<-tools::md5sum(list.files(root,pattern="\\.zip$",full.names=TRUE))
qa<-sci_validate_potec_uncorrected(root,max_files=2L,max_rows=100L)
after<-tools::md5sum(list.files(root,pattern="\\.zip$",full.names=TRUE))
stopifnot(identical(before,after),nrow(qa$unit_summary)==2L,
          all(qa$unit_summary$matched_original_keys==3L),
          all(qa$unit_summary$uncorrected_only_keys==1L),
          all(qa$unit_summary$corrected_only_keys==0L),
          all(qa$unit_summary$duration_disagreements==0L),
          file.exists(file.path(qa$output,"STAGE_PROVENANCE.md")))

# Source-pinned original released implementation versus development version;
# all curves and helper quadrature are shared, without raw participant data.
data_dir<-tempfile("benchfixture_");dir.create(data_dir)
paired<-sci_benchmark_paired_l2(root=data_dir,source="synthetic",
  sizes=c(16L,32L),grids=c(16L,32L),repetitions=2L,
  out=file.path(data_dir,"paired"))
stopifnot(nrow(paired$summary)==4L,
          nrow(paired$repetitions)==16L,
          all(paired$summary$max_numeric_abs_error<=1e-8),
          all(paired$summary$max_reference_abs_error<=1e-8),
          all(paired$summary$paired_reps==2L),
          file.exists(file.path(paired$output,"PAIRED_BENCHMARK_PROTOCOL.md")))
cat("POTEC_UNCORRECTED_STAGE_AND_SOURCE_PINNED_L2_SYNTHETIC_PASS\n")
