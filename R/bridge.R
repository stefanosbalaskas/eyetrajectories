#' @keywords internal
.et_import <- function(namespace = c("root", "workflows")) {
  namespace <- match.arg(namespace)
  module <- if (identical(namespace, "root")) {
    "eyetrajectoriespy"
  } else {
    "eyetrajectoriespy.workflows"
  }
  tryCatch(
    reticulate::import(module, convert = FALSE),
    error = function(e) {
      stop(
        sprintf(
          paste0(
            "Cannot import Python module '%s': %s\n",
            "Install/use Python 3.11-3.13 with eyetrajectoriespy 1.2.0, ",
            "or let reticulate manage the environment via py_require(). ",
            "Inspect reticulate::py_config() for interpreter selection."
          ),
          module, conditionMessage(e)
        ),
        call. = FALSE
      )
    }
  )
}

#' Return the underlying eyetrajectoriespy Python module
#'
#' This initializes Python on first use. Loading the R package itself does not.
#' @export
et_python <- function() {
  .et_import("root")
}

#' Read the installed Python distribution version
#'
#' This initializes Python if it has not already been initialized.
#' @export
et_python_version <- function() {
  .et_import("root")
  metadata <- reticulate::import("importlib.metadata", convert = FALSE)
  reticulate::py_to_r(metadata$version("eyetrajectoriespy"))
}

#' Call a public Python API member
#'
#' Names must appear in the selected module's \code{__all__}. Python objects
#' are preserved by default so fitted models can be passed between calls.
#' @param name Name of the exported Python callable.
#' @param ... Arguments forwarded to Python.
#' @param .namespace Either "root" or "workflows".
#' @param .convert Convert result to R (some Python model objects remain Python).
#' @export
et_call <- function(name, ..., .namespace = c("root", "workflows"), .convert = FALSE) {
  if (!is.character(name) || length(name) != 1L ||
      is.na(name) || !grepl("^[A-Za-z][A-Za-z0-9_]*$", name)) {
    stop("name must be a single public Python identifier", call. = FALSE)
  }
  .namespace <- match.arg(.namespace)
  if (!is.logical(.convert) || length(.convert) != 1L || is.na(.convert)) {
    stop(".convert must be TRUE or FALSE", call. = FALSE)
  }
  module <- .et_import(.namespace)
  public <- reticulate::py_to_r(reticulate::py_get_attr(module, "__all__"))
  if (!name %in% public) {
    stop(
      sprintf("'%s' is not exported by eyetrajectoriespy namespace '%s'", name, .namespace),
      call. = FALSE
    )
  }
  target <- reticulate::py_get_attr(module, name)
  result <- do.call(reticulate::py_call, c(list(target), list(...)))
  if (isTRUE(.convert)) reticulate::py_to_r(result) else result
}

#' Explicitly convert a Python result into R data
#' @param x Python object returned from the bridge.
#' @export
et_to_r <- function(x) {
  reticulate::py_to_r(x)
}
