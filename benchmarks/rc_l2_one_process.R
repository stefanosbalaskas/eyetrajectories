# Isolated benchmark run: one installed package, one R process, one dataset.
# Args: library, expected version, input RDS, output-prefix
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==4L)
lib<-normalizePath(args[1L],mustWork=TRUE)
expected_version<-args[2L];input<-normalizePath(args[3L],mustWork=TRUE)
prefix<-args[4L]
suppressPackageStartupMessages(library(eyetrajectories,lib.loc=lib))
actual<-as.character(utils::packageVersion("eyetrajectories"))
stopifnot(identical(actual,expected_version))
x<-readRDS(input);etr_validate(x,require_complete=TRUE)
gc()
# Windows elapsed clocks round fast single calls to 0.00 seconds.
# Repeat only candidate calls to obtain a measurable interval, then
# divide by the exact repetition count. Baseline stays at one call.
batch_count <- if (expected_version=="0.4.3.9000") {
  if (dim(x$values)[1L] <= 500L) 30L else 5L
} else 1L
elapsed_total <- unname(system.time({
  for (batch in seq_len(batch_count)) result<-etr_pairwise_l2(x)
})["elapsed"])
elapsed <- elapsed_total / batch_count
stopifnot(is.finite(elapsed),elapsed>0,
          all(is.finite(result)),all(diag(result)==0),
          isTRUE(all.equal(result,t(result),tolerance=1e-10)),
          identical(dimnames(result),list(x$curve_ids,x$curve_ids)))
dir.create(dirname(prefix),recursive=TRUE,showWarnings=FALSE)
saveRDS(result,paste0(prefix,".rds"),version=3L)
utils::write.csv(data.frame(
  version=actual,n_curves=dim(x$values)[1L],
  grid_points=dim(x$values)[2L],
  channels=dim(x$values)[3L],elapsed_seconds=elapsed,
  batch_count=batch_count,total_timed_seconds=elapsed_total,
  stringsAsFactors=FALSE),
  paste0(prefix,".csv"),row.names=FALSE)
cat("ISOLATED_INSTALLED_L2_BENCHMARK_PASS",actual,dim(result)[1L],elapsed,"\n")
