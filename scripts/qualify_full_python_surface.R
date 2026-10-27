#!/usr/bin/env Rscript
# Full upstream Python 1.2.0 R hybrid-access qualification.
# Run from eyetrajectories repository checkout:
#   source("scripts/qualify_full_python_surface.R")
#
# This validates presence/callability of ALL 508 public exports and
# actually executes the selected FPCA/MFPCA + workflow/model-proxy smoke tests.
# It does NOT claim all 380 functions have passed individual behavioral
# tests, or independent native-R numerical/scientific equivalence.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Run from repository root.",call.=FALSE)
if (!requireNamespace("testthat",quietly=TRUE) ||
    !requireNamespace("pkgload",quietly=TRUE))
  stop("Please install testthat and pkgload.",call.=FALSE)
prior <- Sys.getenv(c("ET_RUN_PYTHON_TESTS","MPLBACKEND"),unset=NA_character_)
on.exit_status <- function() {
  for (i in seq_along(prior)) {
    if (is.na(prior[i])) Sys.unsetenv(names(prior)[i])
    else do.call(Sys.setenv,
      stats::setNames(list(prior[i]),names(prior)[i]))
  }
}
# Script is typically sourced into a user's R session, so restore envvars
# explicitly at exit rather than relying on top-level on.exit().
status <- tryCatch({
  Sys.setenv(ET_RUN_PYTHON_TESTS="true",MPLBACKEND="Agg")
  pkgload::load_all(".",quiet=TRUE)
  testthat::test_local(".",filter="full-python-surface",
                       reporter="summary",stop_on_failure=TRUE)
  full <- eyetrajectories::etpy_signature_catalog(strict=TRUE)
  if (nrow(full)!=508L || sum(full$kind=="function")!=380L ||
      sum(full$namespace=="root")!=458L ||
      sum(full$namespace=="workflows")!=50L ||
      !all(full$structurally_available))
    stop("Public Python 1.2.0 export audit failed.",call.=FALSE)
  full
},error=function(e){
  on.exit_status()
  stop("HYBRID PYTHON 1.2 QUALIFICATION FAILED: ",
       conditionMessage(e),call.=FALSE)
})
on.exit_status()

out_root <- file.path("artifacts","full_python_surface")
out <- file.path(out_root,paste0("run_",
 format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if(dir.exists(out)) stop("Refuse to overwrite parity archive.",call.=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
if(!dir.exists(out)) stop("Cannot create parity archive.",call.=FALSE)
utils::write.csv(status,file.path(out,"all_508_exports.csv"),
                 row.names=FALSE,na="")
writeLines(c(
  "Python 1.2.0 from R full public surface audit — structurally PASS",
  paste("date_utc:",format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC")),
  paste("R_version:",R.version.string),
  paste("Python_dist_version:",unique(status$installed_python_version)),
  paste("public_symbols:",nrow(status)),
  paste("function_symbols:",sum(status$kind=="function")),
  paste("other_public_symbols:",sum(status$kind!="function")),
  paste("available_and_version_matched:",sum(status$structurally_available)),
  "508 public exports were individually reflected for signatures and runtime types.",
  paste("supported_signatures:",sum(!is.na(status$python_signature))),
  paste("runtime_classes:",sum(status$runtime_kind=="class")),
  "Selected FPCA/MFPCA and workflow calls were run by the opt-in tests.",
  "The 380 functions were NOT all behaviorally executed one-by-one.",
  "All function calls execute Python code: not 380 native R algorithms.",
  "No separate numerical equivalence or statistical calibration is certified."
),file.path(out,"manifest.txt"))
cat("FULL PYTHON 1.2 PUBLIC R SURFACE: STRUCTURAL PASS\n",
 "508/508 public symbols structurally available;\n",
 "380 Python function bridges; 128 other Python class/constant exports;\n",
 "All 508 public symbols introspected for runtime type/signature;\n",
 "Full-surface R tests completed on selected real Python calls;\n",
 "Archive: ",normalizePath(out,winslash="/"),"\n",
 "NOT native algorithmic/scientific parity. No release authorized.\n",sep="")
