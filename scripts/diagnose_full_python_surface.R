# Diagnostic for the unmerged draft PR #7 Python-backed R interface.
# Run from the eyetrajectories checkout root:
#   source("scripts/diagnose_full_python_surface.R")
# Optionally test a live Python backend:
#   Sys.setenv(ET_PY_DIAG_LIVE="true")
#   source("scripts/diagnose_full_python_surface.R")
# Python import is OFF by default. This script does not change Git branches,
# Python configurations, requirements or release state.

if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Start R from the eyetrajectories repository root.",call.=FALSE)
if (!requireNamespace("pkgload",quietly=TRUE))
  stop("Install 'pkgload' for source-checkout diagnosis.",call.=FALSE)

check <- function(label,expression) {
  cat("\n",label,": ",sep="")
  out <- tryCatch(force(expression),error=function(e)e)
  if(inherits(out,"error")) {
    cat("FAIL\n  ",conditionMessage(out),"\n",sep="")
    return(FALSE)
  }
  cat("PASS\n")
  TRUE
}
cat("Python-to-R draft PR #7: diagnostics\n")
cat("Checkout: ",normalizePath(".",winslash="/"),"\n",sep="")
cat("R: ",R.version.string,"\n",sep="")
cat("Package source version: ",
    unname(read.dcf("DESCRIPTION",fields="Version")[1L]),"\n",sep="")
cat("RETICULATE_PYTHON: ",
    Sys.getenv("RETICULATE_PYTHON",unset="<not set>"),"\n",sep="")
cat("Live Python check requested: ",
    identical(Sys.getenv("ET_PY_DIAG_LIVE"),"true"),"\n",sep="")

stage1 <- check("1. Load this checkout without importing Python",{
  pkgload::load_all(".",quiet=TRUE)
  invisible(TRUE)
})
if (!stage1) stop("Cannot load the checked-out R package.",call.=FALSE)

required <- c("etpy_full_surface","etpy_full_verify",
              "etpy_invoke","etpy_method","etpy_attribute",
              "etpy_signature","etpy_signature_catalog",
              "etpy_enable_extras")
stage2 <- check("2. Verify source branch has the new draft interface",{
  symbols <- getNamespaceExports("eyetrajectories")
  missing <- setdiff(required,symbols)
  if(length(missing))
    stop("Missing new exports: ",paste(missing,collapse=", "),
         ". You may still be on main or research/native-parity-stage1, ",
         "rather than feat/full-python12-hybrid-parity-20261027.",
         call.=FALSE)
  invisible(TRUE)
})
if (!stage2) stop("The new PR #7 source is not loaded.",call.=FALSE)

stage3 <- check("3. Construct the lazy 508-symbol R namespace",{
  initialized <- reticulate::py_available(initialize=FALSE)
  surface <- eyetrajectories::etpy_full_surface()
  stopifnot(is.environment(surface$root),
            is.environment(surface$workflows),
            length(ls(surface$root,all.names=TRUE))==458L,
            length(ls(surface$workflows,all.names=TRUE))==50L,
            identical(reticulate::py_available(initialize=FALSE),
                      initialized))
  invisible(TRUE)
})

if(identical(Sys.getenv("ET_PY_DIAG_LIVE"),"true")){
  stage4 <- check("4. Inspect selected Python environment",{
    config <- reticulate::py_config()
    cat("\n  Python: ",config$python,"\n",sep="")
    cat("  Version: ",config$version_string,"\n",sep="")
    invisible(TRUE)
  })
  if(stage4){
    stage5 <- check("5. Verify all 508 installed Python exports",{
      x <- eyetrajectories::etpy_full_verify(strict=TRUE)
      stopifnot(nrow(x)==508L,all(x$structurally_available))
      invisible(TRUE)
    })
    if(stage5) check("6. Execute one actual Python trajectory function",{
      api <- eyetrajectories::etpy_full_surface()
      v <- api$root$simulate_planar_trajectories(
        n_participants=2L,trials_per_participant=2L,
        n_time=11L,random_state=7L)
      count <- as.integer(reticulate::py_to_r(v$n_curves))
      if(!identical(count,4L))
        stop("Expected 4 curves, obtained ",count,call.=FALSE)
      invisible(TRUE)
    })
  }
}
cat("\nDiagnostic finished. Share the printed FAIL stage and message ",
    "if any; no branch or Python environment was changed.\n",sep="")
