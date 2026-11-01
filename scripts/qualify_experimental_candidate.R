#!/usr/bin/env Rscript
# A LOCAL release-candidate gate, NEVER a tag, GitHub release, CRAN submission,
# or full Python 1.2 parity certificate.
#
# From the root of the repository:
#   source("scripts/qualify_experimental_candidate.R")
#
# 1. Full source-package CRAN-style check and actual native smoke example.
# 2. Native and pinned frozen Python direct-source developer qualification.
#    (The qualification script handles ET_RUN_PYTHON_TESTS internally.)
# 3. Exact HEAD, version and LIMITED scope proof; no fake GitHub CI result.
#
# Check scripts themselves write rich, timestamped evidence bundles.

if(!file.exists("DESCRIPTION")||
    !identical(unname(read.dcf("DESCRIPTION","Package")[1L]),
      "eyetrajectories"))
  stop("Run candidate qualification from the package repository root.",
    call.=FALSE)
version<-unname(read.dcf("DESCRIPTION","Version")[1L])
head<-tryCatch(system2("git",c("rev-parse","HEAD"),stdout=TRUE),
  error=function(e)character())
if(length(head)!=1L||!grepl("^[0-9a-f]{40}$",head))
  stop("Refuse release-candidate qualification without exact Git HEAD",
    call.=FALSE)
start_time<-format(Sys.time(),"%Y-%m-%dT%H:%M:%S%z")
cat("EXPERIMENTAL_R_CANDIDATE_HEAD=",head,"\n",sep="")
cat("EXPERIMENTAL_R_CANDIDATE_VERSION=",version,"\n",sep="")
cat("RELEASE_SCOPE=limited R package; NOT 508 Python contracts\n")
cat("GITHUB_ACTIONS_RUNNER_GATE=UNRESOLVED; repository issue #3\n")
cat("CERTIFICATION=external 508 full-domain approvals remain separate\n")
cat("PUBLICATION=NOT ATTEMPTED\n")
if(grepl("\\.9000$",version))
  cat("DEV_VERSION_HOLD=TRUE; a publication version is not prepared\n")

# These scripts raise errors on failing required checks. An incoming CRAN
# NOTE can be reviewed explicitly; the external CRAN farm isn't reproduced.
cat("\n=== Fast parse preflight: source, tests and release R scripts ===\n")
source("scripts/preflight_release_source_syntax.R",local=TRUE)

cat("\n=== R CMD check --as-cran plus native source example ===\n")
cran_gate_error<-tryCatch({
  source("scripts/run_cran_qualification.R",local=TRUE)
  NULL
},error=function(e)conditionMessage(e))
if(!is.null(cran_gate_error))
  cat("EXPERIMENTAL_CRAN_GATE=FAIL: ",cran_gate_error,"\n",sep="")

cat("\n=== Native + pinned Python 1.2 scientific author qualification ===\n")
scientific_gate_error<-tryCatch({
  source("scripts/capture_native_source_qualification_evidence.R",
    local=TRUE)
  NULL
},error=function(e)conditionMessage(e))
if(!is.null(scientific_gate_error))
  cat("EXPERIMENTAL_SCIENTIFIC_GATE=FAIL: ",scientific_gate_error,
    "\n",sep="")

head_after<-tryCatch(system2("git",c("rev-parse","HEAD"),stdout=TRUE),
  error=function(e)character())
if(!identical(head_after,head))
  stop("Git HEAD changed during release qualification; refuse evidence",
    call.=FALSE)

outdir<-file.path("artifacts","experimental_release_candidates")
dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
file<-file.path(outdir,paste0("local_candidate_",
  substr(head,1L,12L),".txt"))
all_gates_passed<-is.null(cran_gate_error)&&is.null(scientific_gate_error)
writeLines(c(
  paste0("RESULT=",if(all_gates_passed)
    "LOCAL_TESTS_PASSED; NOT READY FOR PUBLICATION" else
    "FAIL; REQUIRED_QUALIFICATION_INCOMPLETE"),
  paste0("CRAN_GATE=",if(is.null(cran_gate_error))"PASS" else "FAIL"),
  paste0("SCIENTIFIC_GATE=",if(is.null(scientific_gate_error))"PASS" else "FAIL"),
  if(!is.null(cran_gate_error))
    paste0("CRAN_GATE_ERROR=",cran_gate_error),
  if(!is.null(scientific_gate_error))
    paste0("SCIENTIFIC_GATE_ERROR=",scientific_gate_error),
  paste0("GIT_HEAD=",head),
  paste0("PACKAGE_VERSION=",version),
  paste0("START=",start_time),
  paste0("END=",format(Sys.time(),"%Y-%m-%dT%H:%M:%S%z")),
  "CRAN_SOURCE_CHECK=performed through run_cran_qualification.R",
  "SCIENTIFIC_SOURCE_TESTS=performed through capture_native_source_qualification_evidence.R",
  "SCOPE=explicit supported native R scientific API only",
  "FROZEN_PYTHON_FULL_DOMAIN_PARITY=NOT_CLAIMED",
  "INDEPENDENT_508_CERTIFICATION=NOT_CLAIMED",
  "GITHUB_ACTIONS_RUNNER_ADMISSION=UNVERIFIED; see issue #3",
  "PUBLISH_OR_TAG=NO",
  if(grepl("\\.9000$",version))
    "VERSION_GATE=HOLD_DEV_VERSION_NOT_PUBLICATION_READY" else
    "VERSION_GATE=MANUAL_REVIEW_REQUIRED",
  "MANUAL_GATES=review NOTES, R CMD check platform matrix, license, metadata, README, CI provisioning"
),file,useBytes=TRUE)
cat("\nLOCAL_EXPERIMENTAL_CANDIDATE_EVIDENCE=",normalizePath(file,
  winslash="/",mustWork=TRUE),"\n",sep="")
cat("NO PACKAGE HAS BEEN PUBLISHED OR TAGGED.\n")
if(!all_gates_passed)
  stop("Experimental candidate FAILED: read both CRAN and scientific gate reports; no release approval.",call.=FALSE)
