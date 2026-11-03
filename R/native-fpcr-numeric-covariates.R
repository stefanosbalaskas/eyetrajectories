# Frozen eyetrajectoriespy 1.2.0 prediction.py::_validate_covariates
# and _design_matrix. This native subset accepts finite numeric/logical
# data-frame columns; other pandas coercions are not claimed equivalent.
#
# Covariate alignment is positional, as in Python's reset_index(drop=TRUE).
# No preprocessing parameters are learned from held-out observations.
.etr_fpcr_numeric_covariates <- function(covariates, n) {
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
  .etr_assert(all(vapply(covariates, function(x)
    (is.numeric(x) || is.logical(x)) && !is.factor(x), logical(1L))),
    "covariates must be numeric")
  if (ncol(covariates) == 0L) {
    out <- matrix(numeric(), nrow=n, ncol=0L)
    colnames(out) <- character()
    return(out)
  }
  out <- as.matrix(covariates)
  storage.mode(out) <- "double"
  .etr_assert(all(is.finite(out)),
    "covariates contain non-finite values")
  unname_rows <- dimnames(out)
  dimnames(out) <- list(NULL, nm)
  out
}
