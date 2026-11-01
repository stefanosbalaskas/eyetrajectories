# Source-backed native record/schema containers for 28 Python 1.2 workflow
# dataclasses, frozen at c1cd95ad718327550f7e55393ff38582872f7a94.
# This is a Python-free R field-schema layer, not a dataclass implementation,
# not an estimator, and NOT independent full-domain scientific equivalence.

#' Inspect 28 frozen Python 1.2 workflow dataclass field schemas
#'
#' The exact source-order field names, annotations, required-argument states,
#' and Python default expressions are pinned to the 1.2 source snapshot.
#' Expressions are descriptive strings and are NEVER evaluated by R.
#' @param class_name A single exported workflow dataclass or NULL for all.
#' @return Source-pinned data frame of field descriptors.
#' @export
etr_frozen_workflow_schema <- function(class_name=NULL){
  file<-system.file("extdata",
    "native_workflow_28_class_field_schema_v1.csv",package="eyetrajectories")
  .etr_assert(nzchar(file)&&file.exists(file),
    "missing native source-pinned workflow class schema manifest")
  x<-utils::read.csv(file,stringsAsFactors=FALSE,check.names=FALSE,
    na.strings=character())
  needed<-c("namespace","class_name","source_module","field_order",
    "field_name","annotation","required","python_default_expression",
    "frozen_python_commit")
  .etr_assert(identical(names(x),needed)&&nrow(x)==303L&&
    length(unique(x$class_name))==28L&&
    all(x$namespace=="workflows")&&
    all(x$frozen_python_commit==
      "c1cd95ad718327550f7e55393ff38582872f7a94")&&
    all(!is.na(x$field_name)&nzchar(x$field_name))&&
    !anyDuplicated(paste(x$class_name,x$field_name,sep="::"))&&
    is.logical(x$required)&&!anyNA(x$required),
    "frozen workflow 28-dataclass field manifest has invalid schema")
  for(z in split(x,x$class_name)){
    .etr_assert(identical(z$field_order,seq_len(nrow(z)))&&
      all(!z$required|z$python_default_expression=="")&&
      all(z$required|nzchar(z$python_default_expression)),
      "frozen workflow source field order/default metadata is inconsistent")
  }
  if(!is.null(class_name)){
    .etr_assert(is.character(class_name)&&length(class_name)==1L&&
      !is.na(class_name)&&class_name%in%x$class_name,
      "unknown frozen Python 1.2 workflow dataclass")
    x<-x[x$class_name==class_name,,drop=FALSE]
  }
  rownames(x)<-NULL
  x
}

#' Construct a native R field record of a frozen Python workflow dataclass
#'
#' This constructor requires every source field explicitly, including optional
#' fields. It does not execute Python defaults, type-coerce Python values,
#' validate hidden Python __post_init__ rules, run a scientific fit, or certify
#' interoperability. Use the schema to supply required source fields, and
#' pass NULL explicitly for optional absent Python None fields as appropriate.
#' @param class_name One of 28 exported frozen workflow dataclass names.
#' @param fields Named list containing exactly the documented source fields.
#' @return A native S3 record in Python dataclass declaration field order;
#'   source_scientific_parity_certified is always FALSE.
#' @export
etr_frozen_workflow_record <- function(class_name,fields){
  schema<-etr_frozen_workflow_schema(class_name)
  .etr_assert(is.list(fields)&&!is.data.frame(fields)&&
    !is.null(names(fields))&&
    length(names(fields))==length(fields)&&
    !anyNA(names(fields))&&all(nzchar(names(fields)))&&
    !anyDuplicated(names(fields)),
    "fields must be a uniquely named R list")
  expected<-schema$field_name
  .etr_assert(length(fields)==length(expected)&&
    setequal(names(fields),expected),
    paste0(class_name,
      " requires all exact frozen Python fields; no implicit defaults"))
  ordered<-fields[expected]
  # Prevent a malformed result envelope from being mistaken for an
  # estimator output, even though this container remains uncertified.
  if(grepl("WorkflowResult$",class_name)){
    .etr_assert(is.numeric(ordered$workflow_schema_version)&&
      length(ordered$workflow_schema_version)==1L&&
      !is.na(ordered$workflow_schema_version)&&
      identical(as.integer(ordered$workflow_schema_version),1L)&&
      is.character(ordered$workflow_contract)&&
      length(ordered$workflow_contract)==1L&&
      !is.na(ordered$workflow_contract)&&
      nzchar(ordered$workflow_contract)&&
      is.list(ordered$steps)&&is.list(ordered$decisions)&&
      is.list(ordered$provenance)&&is.list(ordered$reports)&&
      is.list(ordered$tables),
      "workflow result needs valid schema version, contract and audit lists")
  }
  structure(ordered,
    class=c(paste0("etr_frozen_py12_",class_name),
      "etr_frozen_workflow_record","list"),
    frozen_python_class=class_name,
    frozen_python_commit="c1cd95ad718327550f7e55393ff38582872f7a94",
    complete_source_field_names=TRUE,
    source_scientific_parity_certified=FALSE,
    independent_full_domain_certification=FALSE)
}

#' Wrap an existing native R result in its frozen workflow field schema
#'
#' No source dataclass behavior is fabricated: native estimator, audit times,
#' plots and result tables retain their original R semantics. This only
#' provides a field-ordered R view for inspection and explicitly cannot be
#' used as a published Python workflow result without independent review.
#' @param result Native R FPCA or function-on-scalar workflow result.
#' @return Native schema-record view with scientific parity flags FALSE.
#' @export
etr_native_workflow_result_view <- function(result){
  class_name<-if(inherits(result,"etr_fpca_workflow"))
    "FPCAWorkflowResult" else if(inherits(result,
      "etr_function_on_scalar_workflow"))
    "FunctionOnScalarWorkflowResult" else
    stop("no native workflow result-view adapter for this class",
      call.=FALSE)
  schema<-etr_frozen_workflow_schema(class_name)
  .etr_assert(is.list(result)&&
    all(schema$field_name%in%names(result)),
    "native workflow lacks a required frozen source result field")
  etr_frozen_workflow_record(class_name,result[schema$field_name])
}
