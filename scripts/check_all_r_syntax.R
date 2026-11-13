# All-file R syntax gate. Base R only; no pkgload, reticulate or Python.
# Run from package root:
#   source("scripts/check_all_r_syntax.R")
# A failing source file cannot be hidden by an earlier load_all() stop.

dirs <- c("R", file.path("tests", "testthat"))
targets <- unlist(lapply(dirs, function(d) {
  if (!dir.exists(d))
    stop("Package source directory not found: ", d, call. = FALSE)
  list.files(d, pattern = "\\.R$", recursive = TRUE,
             full.names = TRUE, ignore.case = TRUE)
}), use.names = FALSE)
targets <- sort(unique(targets))
if (!length(targets))
  stop("No R source files found (wrong working directory?)", call. = FALSE)

failures <- character()
for (path in targets) {
  result <- tryCatch({
    parse(file = path, keep.source = FALSE, encoding = "UTF-8")
    NULL
  }, error = function(e) conditionMessage(e))
  if (!is.null(result)) {
    failures <- c(failures, paste0(path, " :: ", result))
    cat("PARSE FAIL:", path, "\n", result, "\n\n", sep = "")
  }
}
cat("R syntax audit: ", length(targets), " files checked; ",
    length(failures), " failures.\n", sep = "")
if (length(failures))
  stop("R syntax audit failed: fix all listed files before pkgload::load_all().",
       call. = FALSE)
cat("PASS: all package R and testthat sources parse in base R.\n")
