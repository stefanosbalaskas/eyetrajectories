# Four-track scientific qualification infrastructure smoke, synthetic only.
# No CRAN, PoTeC or OneStop scientific validity claim arises from these tests.
Sys.setenv(ET_SCI_ASC_NO_AUTORUN="true",
           ET_SCI_MODEL_NO_AUTORUN="true",
           ET_SCI_MC_NO_AUTORUN="true",
           ET_SCI_BENCH_NO_AUTORUN="true")
for(script in c("science_validate_potec_asc.R","science_validate_models.R",
                "science_inference_calibration.R","science_benchmark_multiplatform.R"))
  source(file.path("scripts",script),local=FALSE)

sample_asc <- c("START 100", "MSG 101 SYNCTIME.sentence",
  "110 101 202 3.1", "130 101 203 3.2",
  "SFIX R 120", "EFIX R 120 140 20 101 201 3.3",
  "SSACC R 145", "ESACC R 145 155 10 0 0 4 4",
  "MSG 160 sentence.STOP", "END 161")
stats <- .sci_asc_analyze_lines(sample_asc)
stopifnot(stats[["sentence_start_markers"]]==1L,
          stats[["sentence_stop_markers"]]==1L,
          stats[["EFIX"]]==1L,stats[["EFIX_parsed"]]==1L,
          stats[["EFIX_time_issues"]]==0L,
          stats[["sample_lines"]]==2L,
          stats[["sample_time_reversals"]]==0L)
bad <- .sci_asc_analyze_lines(c("EFIX R 140 120 20 1 2 3",
                               "155 1 2 3","153 1 2 3"))
stopifnot(bad[["EFIX_time_issues"]]==1L,
          bad[["sample_time_reversals"]]==1L)

if(nzchar(Sys.which("zip"))) {
  root<-tempfile("science_asc_");dir.create(root)
  dir.create(file.path(root,"asc_files"))
  writeLines(sample_asc,file.path(root,"asc_files","fixture.asc"))
  old<-getwd();setwd(root)
  utils::zip("asc_files.zip",files="asc_files/fixture.asc",flags="-q")
  setwd(old)
  zip<-file.path(root,"asc_files.zip")
  hash<-unname(tools::md5sum(zip))
  output<-sci_validate_potec_asc(root,max_files=1L,max_lines=0L)
  stopifnot(nrow(output$evidence)==1L,
            output$evidence$EFIX_parsed==1L,
            output$evidence$line_cap_reached==FALSE,
            identical(hash,unname(tools::md5sum(zip))))
  stopifnot(file.exists(file.path(output$folder,"ASC_SCOPE_REPORT.md")))
} else message("ASC ZIP synthetic roundtrip skipped: ZIP executable not available")

model_out<-tempfile("science_model_")
models<-sci_validate_models(out=model_out,run_sparse=FALSE)
stopifnot(nrow(models)>=5L,
          !any(models$status %in% c("FAIL","ERROR")),
          all(models$status %in% c("PASS","NOT_RUN")),
          file.exists(file.path(model_out,"model_oracles.csv")))

mc_out<-tempfile("science_mc_")
cal<-sci_calibrate_inference(out=mc_out,repetitions=5L,B=39L,
                           n_subjects=8L,seed=5141L)
stopifnot(nrow(cal)==4L,
          all(is.finite(cal$simultaneous_coverage)),
          all(cal$simultaneous_coverage>=0&
              cal$simultaneous_coverage<=1),
          all(cal$simultaneous_low<=cal$simultaneous_coverage),
          all(cal$simultaneous_high>=cal$simultaneous_coverage),
          file.exists(file.path(mc_out,"monte_carlo_replicates.csv")))

bench_out<-tempfile("science_bench_")
bench<-sci_benchmark_multiplatform(source_mode="synthetic",
  sizes=c(8L),grids=c(16L),repetitions=2L,out=bench_out)
stopifnot(nrow(bench)==2L,all(bench$median_sec>=0),
          file.exists(file.path(bench_out,"benchmark_repetitions.csv")))
cat("ALL_FOUR_TRACK_SYNTHETIC_SMOKE_PASS\n")
