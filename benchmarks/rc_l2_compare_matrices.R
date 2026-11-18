# Exact binary-to-binary numerical distance matrix comparison.
# Input: benchmark work directory; repetitions per version.
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L)
root<-normalizePath(args[1L],mustWork=TRUE)
reps<-as.integer(args[2L]);stopifnot(reps>=1L,reps<=5L)
cases<-utils::read.csv(file.path(root,"performance_summary.csv"))
stopifnot(nrow(cases)==6L)
out<-vector("list",nrow(cases)*reps)
k<-0L
for(i in seq_len(nrow(cases))){
 n<-cases$n_curves[i];g<-cases$grid_points[i]
 for(rep in seq_len(reps)){
  stem<-sprintf("n%04d_g%03d_rep%d_",n,g,rep)
  baseline<-readRDS(file.path(root,"matrices",paste0(stem,"baseline.rds")))
  candidate<-readRDS(file.path(root,"matrices",paste0(stem,"candidate.rds")))
  stopifnot(is.matrix(baseline),is.matrix(candidate),
    identical(dim(baseline),dim(candidate)),
    identical(dimnames(baseline),dimnames(candidate)),
    nrow(baseline)==n,ncol(baseline)==n,
    all(is.finite(baseline)),all(is.finite(candidate)),
    all(diag(baseline)==0),all(diag(candidate)==0),
    max(abs(candidate-t(candidate)))<1e-10)
  delta<-max(abs(baseline-candidate))
  relative<-max(abs(baseline-candidate)/(1+abs(baseline)))
  stopifnot(is.finite(delta),is.finite(relative),delta<=1e-8)
  k<-k+1L
  out[[k]]<-data.frame(n_curves=n,grid_points=g,repeat=rep,
     max_absolute_difference=delta,
     max_scale_adjusted_difference=relative,
     numerical_contract_pass=TRUE)
 }
}
summary<-do.call(rbind,out)
stopifnot(nrow(summary)==6L*reps)
utils::write.csv(summary,file.path(root,"exact_installed_numerical_comparisons.csv"),
  row.names=FALSE)
cat("EXACT_V043_VS_RC043_INSTALLED_L2_NUMERIC_PARITY_PASS",nrow(summary),
  "pairs, max error",format(max(summary$max_absolute_difference),
                           scientific=TRUE),"\n")
