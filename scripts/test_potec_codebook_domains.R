# Synthetic-only unit and ZIP integration fixtures for official PoTeC labels.
Sys.setenv(ET_POTEC_NO_AUTORUN="true")
source("scripts/qualify_potec_codebook_domains.R",local=FALSE)
stopifnot(identical(.p5_norm(c("bio","biology","physics","unknown",NA_character_)),
                    c("biology","biology","physics",NA_character_,NA_character_)))
stopifnot(.p5_expected("reader1_b0")=="biology",
          .p5_expected("reader1_p5")=="physics",
          is.na(.p5_expected("unrecognized")))
left<-list(status="OK",key=c("x\r0","x\r1"),
           domain=c("biology","biology"),rows=2L,capped=FALSE)
right<-list(status="OK",key=c("x\r0","x\r1"),
            domain=c("bio","bio"),rows=2L,capped=FALSE)
p<-.p5_pair(left,right)
stopifnot(unname(p["matched"])==2,
          unname(p["raw_diff"])==2,
          unname(p["normalized_diff"])==0,
          unname(p["key_loss"])==0)
right$domain[2L]<-"unexpected"
stopifnot(unname(.p5_pair(left,right)["normalized_diff"])==1)

if(!nzchar(Sys.which("zip")))stop("ZIP command required for CI")
root<-tempfile("potec_fixture_");dir.create(root)
for(folder in c("scanpaths","scanpaths_merged","fixations"))
  dir.create(file.path(root,folder))
write_member<-function(folder,stem,suffix,labels){
  d<-data.frame(trial=c(1,1,1),fixation_index=c(1,2,3),
                text_domain=labels,stringsAsFactors=FALSE)
  utils::write.table(d,file.path(root,folder,paste0(stem,suffix,".tsv")),
                     quote=FALSE,sep="\t",row.names=FALSE)
}
for(stem in c("reader1_b0","reader1_p0","reader2_b1")){
 for(folder in c("scanpaths","scanpaths_merged","fixations")){
   suffix<-switch(folder,scanpaths="_scanpath",
                  scanpaths_merged="_merged_sp_rm",fixations="_fixations")
   labs<-if(stem=="reader1_p0")rep("physics",3) else
     if(stem=="reader1_b0" && folder=="fixations")rep("bio",3) else
     if(stem=="reader2_b1")c("bio","biology","bio") else rep("biology",3)
   write_member(folder,stem,suffix,labs)
 }
}
makezip<-function(folder,filename){
 old<-getwd();setwd(root);on.exit(setwd(old),add=TRUE)
 utils::zip(filename,files=paste0(folder,"/",list.files(folder)),flags="-q")
}
makezip("scanpaths","scanpaths.zip")
makezip("scanpaths_merged","scanpaths_merged.zip")
makezip("fixations","fixations.zip")
files<-list.files(root,pattern="\\.zip$",full.names=TRUE)
hash_before<-tools::md5sum(files)
z<-potec_codebook_audit(root,max_units=3L,max_rows=100L)
stopifnot(identical(hash_before,tools::md5sum(files)))
stopifnot(nrow(z$units)==3L,
          sum(z$units$matched)==9,
          sum(z$units$raw_differences)==3,
          sum(z$units$canonical_differences)==0,
          sum(z$units$stem_domain_mismatches)==0,
          sum(z$units$unexpected_domain_cells)==0,
          sum(z$units$crosswalk_key_loss)==0,
          all(z$units$status=="READ"),
          identical(z$status,"CHECK_INCOMPLETE_OR_DIFFERING_INPUTS"))
stopifnot(all(file.exists(file.path(z$output,
  c("potec_unit_contracts.csv","potec_codebook_frequencies.csv",
    "POTEC_CODEBOOK_RECONCILIATION.md","R_session_info.txt")))))
stopifnot(!any(grepl("reader1",readLines(
  file.path(z$output,"POTEC_CODEBOOK_RECONCILIATION.md")),fixed=TRUE)))
cat("POTEC_CODEBOOK_SYNTHETIC_ZIP_RECONCILIATION_PASS\n")
