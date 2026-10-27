#!/usr/bin/env Rscript
# Exact public-symbol native R parity inventory (no Python import).
# Run from repository root: source("scripts/report_full_native_r_parity.R")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Run from eyetrajectories repository root.",call.=FALSE)
if (!requireNamespace("pkgload",quietly=TRUE))
  stop("Install pkgload for source-checkout analysis.",call.=FALSE)
pkgload::load_all(".",quiet=TRUE)
catalog <- eyetrajectories::etr_native_parity_catalog()
if(nrow(catalog)!=508L ||
   sum(catalog$is_python_function)!=380L ||
   sum(!catalog$is_python_function)!=128L)
  stop("Frozen 508-symbol inventory unexpectedly changed.",call.=FALSE)
if(any(catalog$one_to_one_native_contract_complete) ||
   any(catalog$independent_numeric_parity_pass))
  stop("Unjustified full parity qualification; review source register.",
       call.=FALSE)
summary <- as.data.frame(table(catalog$status),
                         stringsAsFactors=FALSE)
names(summary) <- c("port_status","public_symbol_count")
out_root <- file.path("artifacts","full_native_r_parity")
out <- file.path(out_root,paste0("audit_",
 format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if(dir.exists(out)) stop("Refusing to overwrite prior audit.",call.=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
if(!dir.exists(out)) stop("Could not create audit directory.",call.=FALSE)
utils::write.csv(catalog,
  file.path(out,"complete_508_native_port_register.csv"),
  row.names=FALSE,na="")
utils::write.csv(summary,file.path(out,"port_status_counts.csv"),
                 row.names=FALSE)
writeLines(c(
  "ONE-TO-ONE NATIVE R PARITY AUDIT — NOT COMPLETE",
  paste("r_package:",unname(read.dcf("DESCRIPTION",fields="Version"))),
  paste("public_python_symbols:",nrow(catalog)),
  paste("python_functions:",sum(catalog$is_python_function)),
  paste("other_python_public_symbols:",sum(!catalog$is_python_function)),
  paste("bridge_function_wrappers:",sum(catalog$is_python_function &
                                        catalog$python_bridge_available)),
  paste("native_name_analogues:",sum(catalog$named_native_candidate)),
  paste("new_native_geometry_methods:",sum(catalog$native_implementation_started)),
  paste("independently_verified_contracts:",
        sum(catalog$one_to_one_native_contract_complete)),
  "Native names/methods do NOT establish numerical or behavioral parity.",
  "R methods are research-only pending R + Python numerical-oracle tests.",
  "Python classes/configs/constants require separate native representation review.",
  "Python inferential interval and MNAR scientific qualification remains open.",
  "No CRAN release or research branch merge."
),file.path(out,"MANIFEST.txt"))
cat("NATIVE R ONE-TO-ONE PARITY AUDIT (NOT YET COMPLETE)\n",
    "Source exports: ",nrow(catalog),"\n",
    "Function contracts: ",sum(catalog$is_python_function),"\n",
    "Nonfunction contracts: ",sum(!catalog$is_python_function),"\n",
    "Named R analogues (unqualified): ",
      sum(catalog$named_native_candidate),"\n",
    "New independent native implementations: ",
      sum(catalog$native_implementation_started),"\n",
    "Independently qualified exact contracts: ",
      sum(catalog$one_to_one_native_contract_complete),"\n",
    "Saved: ",normalizePath(out,winslash="/"),"\n",sep="")
print(summary,row.names=FALSE)
