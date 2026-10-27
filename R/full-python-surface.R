# Complete public Python 1.2.0 export surface for R users.
# The 380 existing etpy_* wrappers are retained unchanged.
# This adds namespace-style access to ALL 508 declared upstream exports,
# including class constructors, constants, and methods on Python objects.
# The bridge is deliberately lazy: simply loading an R package or creating
# this namespace does not initialize Python or modify the interpreter.

.etpy_validate_boolean <- function(value, arg) {
  if (!is.logical(value) || length(value)!=1L || is.na(value))
    stop(arg," must be TRUE or FALSE",call.=FALSE)
  invisible(value)
}

.etpy_validate_symbol <- function(name) {
  if (!is.character(name) || length(name)!=1L || is.na(name) ||
      !grepl("^[A-Za-z_][A-Za-z0-9_]*$",name))
    stop("name must be one public Python identifier",call.=FALSE)
  invisible(name)
}

#' Full Python public API available through R
#'
#' Creates lazy, read-only \code{$root} and \code{$workflows} environments.
#' Every public function has a callable R closure. A public Python class
#' is exposed as its constructor and noncallable constants are returned as
#' values on first access. Python model results remain Python proxies by
#' default so subsequent method calls work. The 508 names are taken from
#' the frozen Python 1.2.0 export manifest; this is not native R parity.
#'
#' @param .convert Convert returned objects to R values by default. Leave
#'   FALSE for fitted models and other Python objects.
#' @param .verify Verify installed Python version and all public names before
#'   constructing the environments. FALSE delays Python startup until use.
#' @return A read-only list with \code{root} and \code{workflows}
#'   environments and a metadata \code{catalog}.
#' @export
etpy_full_surface <- function(.convert=FALSE,.verify=FALSE) {
  .etpy_validate_boolean(.convert,".convert")
  .etpy_validate_boolean(.verify,".verify")
  if (.verify) etpy_full_verify(strict=TRUE)
  manifest <- etpy_catalog(include_nonfunctions=TRUE)
  make_namespace <- function(namespace) {
    env <- new.env(parent=emptyenv())
    selected <- manifest[manifest$namespace==namespace,,drop=FALSE]
    for (j in seq_len(nrow(selected))) local({
      py_name <- selected$python_name[j]
      py_namespace <- namespace
      declared_kind <- selected$kind[j]
      default_convert <- .convert
      makeActiveBinding(py_name,function(value) {
        if (!missing(value))
          stop("The Python 1.2.0 API surface is read-only.",call.=FALSE)
        # Known functions do not need a Python import until invoked.
        if (declared_kind=="function") {
          return(function(...,.convert=default_convert)
            et_call(py_name,...,.namespace=py_namespace,
                    .convert=.convert))
        }
        obj <- etpy_get_export(py_name,.namespace=py_namespace,
                               .convert=FALSE)
        callable <- reticulate::py_to_r(
          reticulate::import_builtins(convert=FALSE)$callable(obj))
        if (isTRUE(callable)) {
          return(function(...,.convert=default_convert)
            et_call(py_name,...,.namespace=py_namespace,
                    .convert=.convert))
        }
        if (isTRUE(default_convert)) reticulate::py_to_r(obj) else obj
      },env)
    })
    lockEnvironment(env,bindings=TRUE)
    env
  }
  structure(list(
    root=make_namespace("root"),
    workflows=make_namespace("workflows"),
    catalog=manifest),
    class="etpy_full_surface")
}

#' Call a public Python class constructor or function by name
#'
#' Unlike the named wrappers this also addresses the 128 symbols recorded
#' as classes or constants, with an explicit fail-closed callable check.
#' @param name Public Python symbol name.
#' @param ... Arguments forwarded through reticulate to Python.
#' @param .namespace Python root or workflows namespace.
#' @param .convert Convert result to R (FALSE preserves Python objects).
#' @export
etpy_invoke <- function(name,...,.namespace=c("root","workflows"),
                        .convert=FALSE) {
  .etpy_validate_symbol(name)
  .namespace <- match.arg(.namespace)
  .etpy_validate_boolean(.convert,".convert")
  obj <- etpy_get_export(name,.namespace=.namespace,.convert=FALSE)
  callable <- reticulate::py_to_r(
    reticulate::import_builtins(convert=FALSE)$callable(obj))
  if (!isTRUE(callable))
    stop("Public Python export '",name,"' is not callable; ",
         "use etpy_get_export() to read its value.",call.=FALSE)
  result <- do.call(reticulate::py_call,c(list(obj),list(...)))
  if (.convert) reticulate::py_to_r(result) else result
}

#' Read an attribute of a Python model, result, or configuration
#'
#' The caller supplies an explicit Python proxy (not an R list). Private
#' underscore-prefixed attributes are excluded from this public interface.
#' @param object Python model/result proxy returned by the bridge.
#' @param name Public attribute name.
#' @param .convert Convert attribute to an R value.
#' @export
etpy_attribute <- function(object,name,.convert=FALSE) {
  .etpy_validate_symbol(name)
  .etpy_validate_boolean(.convert,".convert")
  if (startsWith(name,"_"))
    stop("Only public Python attributes are accessible.",call.=FALSE)
  if (!inherits(object,"python.builtin.object") &&
      !inherits(object,"python.builtin.type"))
    stop("object must be a Python proxy; use .convert=FALSE.",
         call.=FALSE)
  if (!reticulate::py_has_attr(object,name))
    stop("Python object has no attribute '",name,"'.",call.=FALSE)
  value <- reticulate::py_get_attr(object,name)
  if (.convert) reticulate::py_to_r(value) else value
}

#' Call a public method on a Python model or result
#' @param object Python model/result proxy.
#' @param name Public method name.
#' @param ... Python method arguments.
#' @param .convert Convert the return value to R.
#' @export
etpy_method <- function(object,name,...,.convert=FALSE) {
  .etpy_validate_boolean(.convert,".convert")
  method <- etpy_attribute(object,name,.convert=FALSE)
  is_callable <- reticulate::py_to_r(
    reticulate::import_builtins(convert=FALSE)$callable(method))
  if (!isTRUE(is_callable))
    stop("Python attribute '",name,"' is not callable.",call.=FALSE)
  result <- do.call(reticulate::py_call,c(list(method),list(...)))
  if (.convert) reticulate::py_to_r(result) else result
}

#' Inspect the public Python callable signature
#' @param name Public class or function.
#' @param .namespace Python namespace.
#' @return A character signature, or NA when inspect.signature is unsupported.
#' @export
etpy_signature <- function(name,.namespace=c("root","workflows")) {
  .etpy_validate_symbol(name)
  .namespace <- match.arg(.namespace)
  obj <- etpy_get_export(name,.namespace=.namespace,.convert=FALSE)
  inspect <- reticulate::import("inspect",convert=FALSE)
  tryCatch({
    sig <- inspect$signature(obj)
    as.character(reticulate::py_to_r(
      reticulate::import_builtins(convert=FALSE)$str(sig)))
  },error=function(e) NA_character_)
}

#' Verify the complete installed public Python API against the frozen 1.2.0
#'
#' Checks the 508 recorded symbols, their namespace __all__ membership,
#' callable function contracts, and the installed distribution version.
#' This is a structural availability gate, not a claim that all 380 methods
#' have been exercised end-to-end or scientifically qualified.
#' @param strict Stop on missing/noncallable or a non-1.2.0 distribution.
#' @return One-row-per-symbol catalog with structural state.
#' @export
etpy_full_verify <- function(strict=TRUE) {
  .etpy_validate_boolean(strict,"strict")
  inventory <- etpy_verify_api(include_nonfunctions=TRUE,strict=FALSE)
  if (nrow(inventory)!=508L)
    stop("Expected 508 frozen public Python symbols.",call.=FALSE)
  expected <- etpy_catalog(include_nonfunctions=TRUE)
  if (!identical(inventory[,names(expected),drop=FALSE],expected))
    stop("The verification catalog differs from the frozen manifest.",
         call.=FALSE)
  actual <- as.character(inventory$installed_python_version)
  inventory$version_qualified <- !is.na(actual) & actual=="1.2.0"
  inventory$structurally_available <-
    inventory$available &
    (inventory$kind!="function" |
       (!is.na(inventory$callable) & inventory$callable)) &
    inventory$version_qualified
  inventory$execution_tested <- FALSE
  inventory$numeric_parity_qualified <- FALSE
  if (strict && any(!inventory$structurally_available)) {
    misses <- which(!inventory$structurally_available)
    stop("Frozen Python 1.2.0 hybrid surface FAILED on ",
         length(misses)," public exports (e.g. ",
         paste(utils::head(paste0(inventory$namespace[misses],":",
                                  inventory$python_name[misses]),8L),
               collapse=", "),"). Check reticulate::py_config() and ",
         "eyetrajectoriespy==1.2.0.",call.=FALSE)
  }
  inventory
}

#' @export
print.etpy_full_surface <- function(x,...) {
  cat("Python 1.2.0 hybrid surface: ",
      sum(x$catalog$namespace=="root")," root + ",
      sum(x$catalog$namespace=="workflows"),
      " workflow public symbols (lazy)\n",sep="")
  cat("R closures delegate to Python when called; ",
      "this is not 508 native R algorithms.\n",sep="")
  invisible(x)
}

#' Declare optional Python scientific backends from R
#'
#' The stable Python package exposes some functionality only when extras
#' are installed (e.g., FDApy, scikit-fda or fdasrsf). This function
#' declares the corresponding *published* extras requirements using
#' reticulate::py_require() so the managed Python environment can resolve
#' them. This does not initialize Python or guarantee optional wheels
#' exist on every OS/Python version. Prefer calling before first import.
#'
#' @param extra One of "fda", "sparse", "elastic", or "all".
#'   For "sparse"/"all", Python 3.11-3.12 is recommended because the
#'   upstream 1.2.0 sparse extra excludes Python 3.13.
#' @return Invisibly the pinned requirement string.
#' @export
# Literal specs copied from the published eyetrajectoriespy v1.2.0
# [project.optional-dependencies] metadata. Do not substitute unpinned
# extra requirements or alter the base package version.
.etpy_extra_dependencies <- function(extra) {
  specs <- c(
    fda="scikit-fda>=0.10.1,<0.11",
    fda_aux="multimethod>=1.12,<2",
    sparse="FDApy>=1.0.3,<1.1; python_version < '3.13'",
    elastic="fdasrsf>=2.7"
  )
  switch(extra,
    fda=unname(specs[c("fda","fda_aux")]),
    sparse=unname(specs["sparse"]),
    elastic=unname(specs["elastic"]),
    all=unname(specs),
    stop("Unknown Python extras group.",call.=FALSE))
}

# Match requirements by normalized distribution name, not by full spec.
# A post-initialization py_require() may only ADD genuinely new names.
.etpy_requirement_basename <- function(x) {
  x <- sub(";.*$","",x)
  x <- sub("\\[.*$","",x)
  x <- sub("[[:space:]<>=!~].*$","",x)
  tolower(gsub("[-_.]+","-",trimws(x)))
}

#' @rdname etpy_full_surface
#' @export
etpy_enable_extras <- function(extra=c("all","fda","sparse","elastic")) {
  extra <- match.arg(extra)
  requirement <- paste0("eyetrajectoriespy[",extra,"]==1.2.0")
  initialized <- isTRUE(reticulate::py_available(initialize=FALSE))
  if (!initialized) {
    # Before import, reticulate can merge the base package's .onLoad()
    # requirement with its exact, published optional-extra variant.
    constraint <- if (extra %in% c("all","sparse"))
      ">=3.11,<3.13" else ">=3.11,<3.14"
    reticulate::py_require(
      packages=requirement,python_version=constraint,action="add")
    return(invisible(requirement))
  }

  # After initialization, reticulate rejects another specification of
  # the existing "eyetrajectoriespy" distribution, even with [all].
  # Its documented permitted operation is adding *new* distributions.
  # Resolve the stable v1.2.0 extras to their exact published packages.
  version <- reticulate::py_config()$version_string
  if(extra %in% c("all","sparse") &&
     grepl("^3\\.13(\\.|$)",version))
    stop("The FDApy sparse backend is not declared on Python 3.13. ",
         "Restart R and select managed Python 3.11 or 3.12 before ",
         "calling etpy_enable_extras('",extra,"').",call.=FALSE)

  wanted <- .etpy_extra_dependencies(extra)
  already <- reticulate::py_require()$packages
  is_new <- !.etpy_requirement_basename(wanted) %in%
    .etpy_requirement_basename(already)
  if (any(!is_new)) {
    message("Optional packages already declared: ",
      paste(.etpy_requirement_basename(wanted[!is_new]),collapse=", "),
      ". Their versions cannot be replaced in this Python session.")
  }
  if (any(is_new))
    reticulate::py_require(packages=wanted[is_new],action="add")
  invisible(requirement)
}

#' Inspect signatures and runtime types for every Python public export
#'
#' Returns the installed Python 1.2.0 signature, module provenance and
#' runtime distinction between function, class constructor and constant
#' for ALL 508 public symbols. This initializes Python and does not
#' execute any scientific fitting routine.
#' @param strict Run the full 508-symbol version/callability gate first.
#' @return A 508-row data frame with public exported names and signatures;
#'   NA for Python objects that do not support inspect.signature().
#' @export
etpy_signature_catalog <- function(strict=TRUE) {
  .etpy_validate_boolean(strict,"strict")
  verified <- etpy_full_verify(strict=strict)
  inspect <- reticulate::import("inspect",convert=FALSE)
  builtins <- reticulate::import_builtins(convert=FALSE)
  n <- nrow(verified)
  sig <- rep(NA_character_,n)
  module_name <- rep(NA_character_,n)
  runtime_kind <- rep("unknown",n)
  for (ns in c("root","workflows")) {
    module <- .et_import(ns)
    indices <- which(verified$namespace==ns)
    for (i in indices) {
      if (!isTRUE(verified$available[i])) next
      obj <- reticulate::py_get_attr(module,verified$python_name[i])
      isclass <- isTRUE(reticulate::py_to_r(inspect$isclass(obj)))
      iscallable <- isTRUE(reticulate::py_to_r(builtins$callable(obj)))
      runtime_kind[i] <- if(isclass) "class" else
        if(iscallable) "callable" else "value"
      sig[i] <- tryCatch(
        as.character(reticulate::py_to_r(
          builtins$str(inspect$signature(obj)))),
        error=function(e) NA_character_)
      if (reticulate::py_has_attr(obj,"__module__")) {
        module_name[i] <- tryCatch(
          as.character(reticulate::py_to_r(
            reticulate::py_get_attr(obj,"__module__"))),
          error=function(e) NA_character_)
      }
    }
  }
  verified$runtime_kind <- runtime_kind
  verified$python_signature <- sig
  verified$python_module <- module_name
  verified
}
