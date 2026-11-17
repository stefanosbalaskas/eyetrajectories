# Wave 4 synthetic tests, no real gaze or participant data.
Sys.setenv(ET_WAVE4_NO_AUTORUN="true",ET_WAVE4_SAVE_LOCAL_LABEL_KEY="false")
source("scripts/qualify_wave4_text_domain_provenance.R",local=FALSE)
stopifnot(.w4_origin_group("reader45_b2")=="B")
stopifnot(.w4_origin_group("reader66_p0")=="P")
stopifnot(.w4_origin_group("unrecognized")=="OTHER")
fake<-function(domain, trials=c("trial","trial","trial")) {
  keys<-paste(trials,0:2,sep="\r")
  list(status="OK",key=keys,domain=rep(domain,3),
       rows=3L,capped=FALSE,constant=TRUE,
       constant_value=domain,domain_missing=0L,
       distinct_domain_labels=1L)
}
a<-fake("alpha");b<-fake("beta");c<-fake("alpha")
stopifnot(.w4_match(a,b)$disagreements==3L)
stopifnot(.w4_match(a,c)$disagreements==0L)
stopifnot(.w4_match(a,b)$unmatched_a==0L)
d<-fake("beta",c("trial","trial","different"))
stopifnot(.w4_match(a,d)$matched==2L)
stopifnot(.w4_match(a,d)$unmatched_a==1L)
stopifnot(.w4_category_code("alpha",c("alpha","beta"))=="CAT_001")
stopifnot(.w4_category_code("beta",c("alpha","beta"))=="CAT_002")
stopifnot(.w4_category_code(NA_character_,c("alpha","beta"))=="MISSING_OR_NONCONSTANT")
stopifnot(nrow(.w4_aggregate(list(
  list(filename_group="B",scanpath_category="CAT_001",fixation_category="CAT_002",
       merged_category="CAT_001",matched_records=3L,scan_fix_disagreements=3L),
  list(filename_group="B",scanpath_category="CAT_001",fixation_category="CAT_002",
       merged_category="CAT_001",matched_records=4L,scan_fix_disagreements=4L))))==1L)
if(!nzchar(Sys.which("zip")))stop("zip executable required for synthetic fixtures")
root<-tempfile("w4test_");dir.create(root)
for(nm in c("scanpaths","scanpaths_merged","fixations"))dir.create(file.path(root,nm))
write_file<-function(folder,suffix,key,domain){
  dat<-data.frame(trial=rep("t1",3),fixation_index=as.character(0:2),
                  text_domain=rep(domain,3),stringsAsFactors=FALSE)
  utils::write.table(dat,file.path(root,folder,paste0(key,suffix,".tsv")),
     sep="\t",quote=FALSE,row.names=FALSE)
}
for(stem in c("reader1_b0","reader1_p1")){
 for(nm in c("scanpaths","scanpaths_merged","fixations")){
   suffix<-switch(nm,scanpaths="_scanpath",scanpaths_merged="_merged_sp_rm",
                  fixations="_fixations")
   domain<-if(nm=="fixations" && grepl("_b",stem,fixed=TRUE))"beta" else "alpha"
   write_file(nm,suffix,stem,domain)
 }
}
makezip<-function(folder,filename){
  previous<-getwd();setwd(root);on.exit(setwd(previous),add=TRUE)
  utils::zip(filename,files=paste0(folder,"/",list.files(folder)),flags="-q")
}
makezip("scanpaths","scanpaths.zip")
makezip("scanpaths_merged","scanpaths_merged.zip")
makezip("fixations","fixations.zip")
zipfiles<-list.files(root,pattern="\\.zip$",full.names=TRUE)
before<-tools::md5sum(zipfiles)
result<-w4_run(root,max_units=2L,max_rows=100L)
stopifnot(identical(before,tools::md5sum(zipfiles)))
stopifnot(nrow(result$units)==2L)
stopifnot(sum(result$units$scan_fix_disagreements)==3L)
stopifnot(sum(result$units$scan_merged_disagreements)==0L)
stopifnot(sum(result$units$fix_merged_disagreements)==3L)
stopifnot(any(result$units$filename_group=="B"))
stopifnot(any(result$units$filename_group=="P"))
stopifnot(all(result$units$status=="COMPARABLE"))
stopifnot(!file.exists(file.path(result$output,
                      "LOCAL_ONLY_DOMAIN_CATEGORY_KEY_DO_NOT_UPLOAD.csv")))
stopifnot(all(grepl("^CAT_",result$units$scanpath_category)))
stopifnot(!any(c("scan_raw","fix_raw","merged_raw")%in%names(result$units)))
stopifnot(sum(result$summary$discrepant_fixation_records)==3L)
stopifnot(file.exists(file.path(result$output,"WAVE4_SUMMARY.md")))
cat("WAVE4_DOMAIN_PROVENANCE_SYNTHETIC_PASS\n")
