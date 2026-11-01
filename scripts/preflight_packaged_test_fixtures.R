#!/usr/bin/env Rscript
# Read-only source-tarball fixture reproducibility preflight.
# scripts/ is intentionally excluded by .Rbuildignore. The five research
# test-only helpers must be packaged separately in tests/testthat/fixtures/.
# Never copy them into R/ or advertise production scientific methods.
if(!file.exists("DESCRIPTION")||
   !identical(unname(read.dcf("DESCRIPTION","Package")[1L]),
     "eyetrajectories"))
  stop("Run fixture preflight at the source package root",call.=FALSE)
fixture_names<-c("observation_process_fixture.R",
  "observation_ipw_research.R",
  "observation_hajek_research.R",
  "audit_missing_gaze_ipw_helpers.R",
  "analyze_missing_gaze_ipw_helpers.R")
for(name in fixture_names){
  original<-file.path("scripts",name)
  packaged<-file.path("tests","testthat","fixtures",name)
  if(!file.exists(original)||!file.exists(packaged))
    stop("Required research-only test fixture is missing: ",name,
      call.=FALSE)
  raw_source<-readBin(original,"raw",n=file.info(original)$size)
  raw_copy<-readBin(packaged,"raw",n=file.info(packaged)$size)
  if(!identical(raw_source,raw_copy))
    stop("Bundled fixture differs from canonical script: ",name,
      "; update the test copy before building",call.=FALSE)
}
cat("PACKAGED_RESEARCH_TEST_FIXTURES_PASS=",length(fixture_names),
  " byte-identical source helpers; no native production exports\n",sep="")
invisible(TRUE)
