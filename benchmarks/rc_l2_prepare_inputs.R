# Exact-version candidate scaling evidence, synthetic input generation.
# Called from CI with a baseline v0.4.3 library. No recorded human gaze.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L)
base_lib<-normalizePath(args[1L],mustWork=TRUE)
out<-args[2L]
suppressPackageStartupMessages(library(eyetrajectories,lib.loc=base_lib))
stopifnot(as.character(utils::packageVersion("eyetrajectories"))=="0.4.3")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
cases<-expand.grid(n_curves=c(250L,500L,1000L),
                   grid_points=c(64L,128L),
                   KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
for(k in seq_len(nrow(cases))){
 n<-cases$n_curves[k];nt<-cases$grid_points[k]
 set.seed(20261118L+n*11L+nt)
 t<-seq(0,1,length.out=nt)^1.14
 vals<-array(0,c(n,nt,2L))
 phase<-stats::runif(n,0,2*pi)
 for(i in seq_len(n)){
   vals[i,,1L]<-.5+.2*sin(2*pi*t+phase[i])+
     stats::rnorm(nt,sd=.016)
   vals[i,,2L]<-.5+.2*cos(2*pi*t+phase[i])+
     stats::rnorm(nt,sd=.016)
 }
 x<-etr_trajectory_set(t,vals,
   curve_ids=sprintf("synthetic_%04d",seq_len(n)),
   dimension_names=c("x","y"),coordinate_system="normalized",
   time_unit="normalized_trial")
 stopifnot(isTRUE(etr_validate(x,require_complete=TRUE)))
 file<-file.path(out,sprintf("n%04d_g%03d.rds",n,nt))
 saveRDS(x,file,version=3L)
 cat("SYNTHETIC_BENCH_INPUT",basename(file),
     "n",n,"grid",nt,"\n")
}
utils::write.csv(cases,file.path(out,"synthetic_cases.csv"),
                 row.names=FALSE)
cat("SIX_SYNTHETIC_INPUT_CASES_PASS\n")
