# Inspect the last EXISTING staged CRAN 0.4.2 R CMD check from RStudio.
# No git checkout change, rebuild, retest, CRAN publication or status waiver.
# From the eyetrajectories repository root:
# source("scripts/inspect_staged_cran_failure.R", encoding="UTF-8")
if(!file.exists("DESCRIPTION")||
   !file.exists("scripts/inspect_staged_cran_failure.py"))
  stop("Run the staged check inspector from the eyetrajectories repository root.",
       call.=FALSE)
python<-Sys.getenv("ET_LOCAL_MATRIX_PYTHON",unset="")
if(!nzchar(python))python<-Sys.which("python")
if(!nzchar(python))
  stop("Python is required to inspect the previous staged check.",call.=FALSE)
args<-c(shQuote("scripts/inspect_staged_cran_failure.py"))
candidate<-Sys.getenv("ET_STAGED_CANDIDATE_PATH",unset="")
if(nzchar(candidate))args<-c(args,"--candidate",shQuote(candidate))
result<-system2(python,args=args,stdout="",stderr="")
if(!identical(as.integer(result),0L))
  stop("Staged CRAN diagnostic extraction FAILED; original check verdict unchanged.",
       call.=FALSE)
cat("STAGED_CRAN_INSPECTION_DONE; ORIGINAL CHECK VERDICT UNCHANGED.\n")
