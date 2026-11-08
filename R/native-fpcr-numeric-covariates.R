# Frozen eyetrajectoriespy==1.2.0 prediction.py::_validate_covariates
# Cross-language source boundary: pandas DataFrame.to_numpy(dtype=float)
# accepts finite numeric text and Boolean columns; R uses native data.frame.
# Opaque Python objects, user-defined dtype conversions and exact exception
# classes are not claimed equivalent.
.etr_fpcr_numeric_covariates <- function(covariates, n, coerce_text=FALSE) {
  .etr_assert(is.logical(coerce_text) && length(coerce_text)==1L &&
    !is.na(coerce_text), "coerce_text must be an explicit logical flag")
  if (is.null(covariates)) return(NULL)
  .etr_assert(is.data.frame(covariates),
    "covariates must be a data.frame or NULL")
  .etr_assert(nrow(covariates) == n,
    "covariates must have one row per trajectory")
  nm <- names(covariates)
  .etr_assert(!anyNA(nm) && !anyDuplicated(nm),
    "covariate column names must be unique")
  .etr_assert(!any(nm == "const" | grepl("^FPC[0-9]+$", nm)),
    "covariate names cannot collide with const or FPC score columns")
  if (ncol(covariates) == 0L) {
    out <- matrix(numeric(), nrow=n, ncol=0L)
    colnames(out) <- character()
    return(out)
  }
  # Python float conversion accepts ASCII digits with optional single
  # underscores between adjacent digits; R's as.numeric() requires their
  # removal. Check the grammar BEFORE removing underscores to reject
  # malformed fields like '1__2' (unlike blindly deleting all '_').
  digits <- "[0-9](?:_?[0-9])*"
  decimal <- paste0("^[+-]?(?:(?:",digits,")",
    "(?:\\.(?:",digits,")?)?|\\.(?:",digits,"))",
    "(?:[eE][+-]?(?:",digits,"))?$")
  special <- "^[+-]?(?:inf(?:inity)?|nan)$"
  convert_column <- function(value) {
    .etr_assert(!is.factor(value) && is.atomic(value) &&
      is.null(dim(value)) && (is.numeric(value) ||
      is.logical(value) || is.character(value)),
      "covariates must be numeric")
    if (is.character(value)) {
      .etr_assert(isTRUE(coerce_text), "covariates must be numeric")
      raw <- trimws(value)
      .etr_assert(!anyNA(raw) && all(
        grepl(decimal,raw,perl=TRUE) |
        grepl(special,raw,perl=TRUE,ignore.case=TRUE)),
        "covariates must be numeric")
      value <- suppressWarnings(as.numeric(gsub("_","",raw,fixed=TRUE)))
    } else value <- as.numeric(value)
    .etr_assert(length(value)==n && all(is.finite(value)),
      "covariates contain non-finite values")
    value
  }
  columns <- lapply(covariates,convert_column)
  out <- do.call(cbind,columns)
  if(!is.matrix(out))out <- matrix(out,nrow=n)
  storage.mode(out) <- "double"
  dimnames(out) <- list(NULL,nm)
  out
}
