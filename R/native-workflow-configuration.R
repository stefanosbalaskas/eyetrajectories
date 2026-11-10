# Python-free native workflow configuration records. Published Python 1.2.0
# source: workflows/_core.py at c1cd95ad718327550f7e55393ff38582872f7a94.
# R S3 record identity is NOT a Python dataclass identity; this contract
# difference remains open in the independent 508-export audit.

.etr_workflow_named_fields <- function(x, what) {
  .etr_assert(is.list(x) && !is.data.frame(x),
    paste0(what," must be a named list"))
  nm <- names(x)
  .etr_assert(!length(x) ||
      (!is.null(nm) && length(nm)==length(x) && !anyNA(nm) &&
        !anyDuplicated(nm)),
    paste0(what," must have unique character keys"))
  .etr_workflow_json(x,what,empty_mapping=TRUE,validate_only=TRUE)
  invisible(TRUE)
}

#' Explicit Python-free workflow configuration
#' @param fields Named JSON-compatible analyst-declared configuration fields.
#' @return Native S3 configuration; it does not pretend to be a Python dataclass.
#' @export
etr_workflow_config <- function(fields=list()) {
  .etr_workflow_named_fields(fields,"fields")
  structure(fields,class=c("etr_workflow_config","list"))
}

#' Explicit preprocessing step with no automatic scientific operation
#' @param function_name Nonempty preprocessing function identifier.
#' @param parameters Named JSON-compatible parameter mapping.
#' @param scientific_effect Nonempty description of the scientific effect.
#' @return Native S3 step configuration; no preprocessing is executed.
#' @export
etr_preprocessing_step_config <- function(function_name,parameters=list(),
    scientific_effect) {
  .etr_assert(is.character(function_name) && length(function_name)==1L &&
    !is.na(function_name) && nzchar(function_name),
    "preprocessing function_name must be nonempty")
  .etr_assert(is.character(scientific_effect) &&
    length(scientific_effect)==1L && !is.na(scientific_effect) &&
    nzchar(scientific_effect),
    "preprocessing scientific_effect must be explicitly described")
  .etr_workflow_named_fields(parameters,"parameters")
  structure(list(`function`=function_name,parameters=parameters,
    scientific_effect=scientific_effect),
    class=c("etr_preprocessing_step_config","list"))
}

#' Ordered explicit preprocessing plan
#' @param steps Ordered list of native preprocessing step configurations.
#' @return S3 plan. An empty plan never implies automatic preprocessing.
#' @export
etr_preprocessing_plan <- function(steps=list()) {
  .etr_assert(is.list(steps) &&
    all(vapply(steps,function(x)
      inherits(x,"etr_preprocessing_step_config"),logical(1L))),
    "steps must contain native preprocessing step configurations")
  for (step in steps) {
    .etr_assert(identical(names(unclass(step)),
      c("function","parameters","scientific_effect")),
      "preprocessing step schema must match the published source")
    .etr_workflow_named_fields(step$parameters,"parameters")
  }
  structure(list(steps=unname(steps)),
    class=c("etr_preprocessing_plan","list"))
}

.etr_workflow_config_jsonable <- function(x) {
  if (inherits(x,"etr_workflow_config") ||
      inherits(x,"etr_preprocessing_step_config") ||
      inherits(x,"etr_preprocessing_plan")) {
    x <- unclass(x)
  } else if (is.object(x) && !is.list(x)) {
    stop("unsupported workflow config object",call.=FALSE)
  }
  if (is.array(x))
    return(.etr_python_json_array_to_list(x))
  if (is.list(x))
    return(lapply(x,.etr_workflow_config_jsonable))
  x
}

#' Convert native workflow config to a JSON-compatible mapping
#' @param config Native workflow config, preprocessing step or plan.
#' @return Named R list retaining field names and ordered preprocessing steps.
#'   Numeric and logical arrays are projected to nested lists in source order.
#' @details Source analogue of Python workflow_config_to_dict. Unlike the
#'   Python API, input is a native S3 record, not a frozen dataclass. Full
#'   source-class, coercion and error parity is deliberately uncertified.
#' @export
etr_workflow_config_to_dict <- function(config) {
  .etr_assert(inherits(config,"etr_workflow_config") ||
      inherits(config,"etr_preprocessing_step_config") ||
      inherits(config,"etr_preprocessing_plan"),
    "config must be a native workflow configuration record")
  out <- .etr_workflow_config_jsonable(config)
  .etr_workflow_named_fields(out,"config")
  out
}
