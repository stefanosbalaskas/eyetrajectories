# Wave 3: no real user data or participant labels. Synthetic-only fixtures.
Sys.setenv(ET_WAVE3_NO_AUTORUN="true")
source("scripts/qualify_wave3_field_disagreements.R",local=FALSE)

fake<-function(version="v1",aoi=c("A","B","C"),dur=c("55","65","75")){
  data.frame(trial=rep("t",3),fixation_index=as.character(0:2),
    original_fixation_index=as.character(0:2),reader_id=rep("r",3),
    text_id=rep("doc",3),text_domain=rep("a",3),
    aoi=aoi,is_fixation_adjusted=rep("0",3),version=rep(version,3),
    fixation_duration=dur,stringsAsFactors=FALSE)
}
p<-list(status="READ",data=fake(),capped=FALSE)
q<-list(status="READ",data=fake(version="v2"),capped=FALSE)
a<-.w3_compare(p,q,"scanpaths_vs_fixations",1L)
stopifnot(a$coverage$status=="COMPARABLE",
          a$coverage$matched_keys==3L,
          a$coverage$only_a==0L,a$coverage$only_b==0L)
fetch<-function(z,nm) z$fields[[match(nm,.w3_fields)]]
ver<-fetch(a,"version")
stopifnot(ver$status=="COMPARED",ver$exact_disagreements==3L,
          isTRUE(ver$entire_unit_disagrees),
          isTRUE(ver$constant_values_on_both_sides))
stopifnot(fetch(a,"text_domain")$exact_disagreements==0L)
stopifnot(fetch(a,"fixation_duration")$duration_numeric_different==0L)

# Report asymmetric missingness separately, rather than treating it as agreement.
u<-list(status="READ",data=fake(aoi=c("A",NA,"C")),capped=FALSE)
missing<-.w3_compare(p,u,"scanpaths_vs_fixations",2L)
stopifnot(fetch(missing,"aoi")$only_b_missing==1L,
          fetch(missing,"aoi")$exact_disagreements==0L)
dups<-list(status="READ",data=rbind(fake(),fake()[1L,,drop=FALSE]),capped=FALSE)
stopifnot(.w3_compare(p,dups,"x",3L)$coverage$status=="OK/DUPLICATE_KEY")
missing_field<-list(status="READ",data=fake()[,c("trial","fixation_index","version")],
                    capped=FALSE)
stopifnot(fetch(.w3_compare(p,missing_field,"x",4L),"aoi")$status=="FIELD_NOT_SHARED")

if(!nzchar(Sys.which("zip")))stop("ZIP CLI required for archive fixture test")
root<-tempfile("et_w3_");dir.create(root)
make_zip<-function(filename,folder,suffix,version) {
  dir.create(file.path(root,folder))
  x<-fake(version=version)
  for(key in c("reader1_p0","reader2_p0")){
    path<-file.path(root,folder,paste0(key,suffix,".tsv"))
    utils::write.table(x,path,sep="\t",row.names=FALSE,quote=FALSE)
  }
  old<-getwd();setwd(root);on.exit(setwd(old),add=TRUE)
  utils::zip(filename,files=paste0(folder,"/",list.files(folder)),flags="-q")
}
make_zip("scanpaths.zip","scanpaths","_scanpath","v1")
make_zip("scanpaths_merged.zip","scanpaths_merged","_merged_sp_rm","v1")
make_zip("fixations.zip","fixations","_fixations","v2")
archive<-list.files(root,pattern="\\.zip$",full.names=TRUE)
before<-tools::md5sum(archive)
res<-w3_run(root,max_units=2L,max_rows=100L)
stopifnot(identical(before,tools::md5sum(archive)))
sub<-res$summary
vs<-sub[sub$comparison=="scanpaths_vs_fixations" &
        sub$field=="version",,drop=FALSE]
stopifnot(nrow(vs)==1L,vs$compared_units==2L,
          vs$compared_nonmissing==6L,vs$exact_disagreements==6L,
          vs$entire_unit_disagreement_units==2L,
          vs$constant_both_sides_units==2L)
sm<-sub[sub$comparison=="scanpaths_vs_merged" &
         sub$field=="version",,drop=FALSE]
stopifnot(sm$exact_disagreements==0L)
stopifnot(all(res$coverage$status=="COMPARABLE"))
stopifnot(nrow(res$coverage)==6L)
for(file in c("comparison_coverage.csv","unit_field_diagnostics.csv",
              "field_comparison_summary.csv","WAVE3_SUMMARY.md",
              "R_session_info.txt")){
  stopifnot(file.exists(file.path(res$output,file)))
}
cat("WAVE3_FIELD_DIAGNOSTIC_SYNTHETIC_PASS\n")
