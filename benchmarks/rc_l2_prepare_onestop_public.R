# Prepare six source-version-pinned real OneStop repeated-fixation inputs.
# Uses upstream publicly released official ZIP and validates exact archived MD5.
# Does NOT save participant names, trial IDs or raw source dataset in CI artifacts.
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L)
root<-normalizePath(args[[1L]],mustWork=TRUE)
out<-args[[2L]]
dir.create(out,recursive=TRUE,showWarnings=FALSE)
source("candidate/benchmarks/rc_l2_onestop_real_release_audit.R",
       local=TRUE,encoding="UTF-8")
raw<-.etr_rc_onestop_read(root,max_rows=200000L)
stopifnot(raw$eligible>=1000L,raw$rows<200000L,
          identical(tolower(raw$md5),
             "650d93a8c73af6a9b3ca19a7c4e542fb"))
cases<-expand.grid(n_curves=c(250L,500L,1000L),
                   grid_points=c(64L,128L),
                   KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
for(i in seq_len(nrow(cases))){
 n<-cases$n_curves[[i]];g<-cases$grid_points[[i]]
 x<-.etr_rc_onestop_grid(raw,n,g)
 stopifnot(is.array(x$values),identical(dim(x$values),c(n,g,2L)),
           all(is.finite(x$values)),length(x$curve_ids)==n,
           all(grepl("^opaque_",x$curve_ids)))
 file<-file.path(out,sprintf("n%04d_g%03d.rds",n,g))
 saveRDS(x,file,version=3L)
 cat("ONE_STOP_REAL_COMMON_GRID_PREPARED n=",n," grid=",g,"\n",sep="")
}
utils::write.csv(cases,file.path(out,"benchmark_cases.csv"),row.names=FALSE)
provenance<-data.frame(
  source="OneStop repeated reading fixation-level",
  reference="https://github.com/lacclab/OneStop-Eye-Movements",
  official_download_script_commit="481a87a00b700ba5c775bb76d92910547aae28df",
  official_osf_resource="83ctd",
  archive_md5=raw$md5,
  eligible_trajectories=raw$eligible,
  rows_read=raw$rows,
  valid_rows=raw$valid,
  max_rows=200000L,
  row_cap_reached=FALSE,
  interpolation="stats::approx, linear, common within-trial 0-1 grid",
  raw_1000hz_samples=FALSE,
  stringsAsFactors=FALSE)
utils::write.csv(provenance,file.path(out,"source_provenance.csv"),
                 row.names=FALSE)
stopifnot(nrow(utils::read.csv(file.path(out,"source_provenance.csv")))==1L)
cat("PUBLIC_ONESTOP_MD5_VERIFIED_REAL_INPUT_PREPARATION_PASS\n")
