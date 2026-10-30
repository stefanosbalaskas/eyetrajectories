# Evidence-only source contract readiness for 508 frozen Python exports.
# No parity approval is inferred from a mapping, runnable test, or source plot.

#' Audit remaining evidence needed for all 508 full Python source contracts
#' @param include_nonfunctions Include classes, constants and configurations.
#' @param only_unapproved Show only contracts not fully independently approved.
#' @return Ordered source-contract readiness data frame with every unmet
#'   numerical, structural, scientific and reviewer evidence requirement.
#' @details This function evaluates the authoritative certification registers
#'   without changing them. A successful test is not automatically an
#'   independent reviewer sign-off. All unresolved full-contract differences
#'   remain explicit and block certification.
#' @export
etr_native_certification_readiness_frame <- function(
    include_nonfunctions=TRUE,only_unapproved=FALSE){
  for(nm in c("include_nonfunctions","only_unapproved")){
    x<-get(nm)
    .etr_assert(is.logical(x)&&length(x)==1L&&!is.na(x),
      paste0(nm," must be TRUE or FALSE"))
  }
  api<-etr_native_parity_catalog()
  .etr_assert(nrow(api)==508L&&!anyDuplicated(paste(
    api$namespace,api$python_name,sep="::")),
    "frozen Python API must contain exactly 508 unique exports")
  needed<-c("namespace","python_name","kind","is_python_function",
    "native_r_candidate","named_native_candidate",
    "native_implementation_started","source_contract_gap_unresolved",
    "contract_certification_evidence_state",
    "independent_numeric_parity_pass","behavioral_schema_parity_pass",
    "scientific_inference_qualified","independent_contract_review_pass",
    "one_to_one_native_contract_complete")
  .etr_assert(all(needed%in%names(api)),
    "certification review register does not contain required evidence fields")
  names_out<-c("native_mapping_missing","native_implementation_missing",
    "unresolved_published_source_difference","approved_numerical_oracle_missing",
    "complete_behavioral_schema_review_missing",
    "scientific_scope_approval_missing","independent_review_approval_missing",
    "reproducible_source_evidence_missing")
  reasons<-lapply(seq_len(nrow(api)),function(i){
    if(isTRUE(api$one_to_one_native_contract_complete[i]))
      return(character())
    out<-character()
    if(isTRUE(api$is_python_function[i])){
      if(!isTRUE(api$named_native_candidate[i]))
        out<-c(out,names_out[1L])
      if(!isTRUE(api$native_implementation_started[i]))
        out<-c(out,names_out[2L])
    }
    if(isTRUE(api$source_contract_gap_unresolved[i]))
      out<-c(out,names_out[3L])
    if(!isTRUE(api$independent_numeric_parity_pass[i]))
      out<-c(out,names_out[4L])
    if(!isTRUE(api$behavioral_schema_parity_pass[i]))
      out<-c(out,names_out[5L])
    if(!isTRUE(api$scientific_inference_qualified[i]))
      out<-c(out,names_out[6L])
    if(!isTRUE(api$independent_contract_review_pass[i]))
      out<-c(out,names_out[7L])
    if(!identical(api$contract_certification_evidence_state[i],
      "approved_and_reproducible"))
      out<-c(out,names_out[8L])
    out
  })
  first<-vapply(reasons,function(x)
    if(length(x))x[[1L]] else "unqualified_evidence_inconsistency",
    character(1L))
  all<-vapply(reasons,function(x)
    if(length(x))paste(x,collapse=";") else "",
    character(1L))
  approved<-as.logical(api$one_to_one_native_contract_complete)
  first[approved]<-"complete"
  ans<-data.frame(namespace=api$namespace,python_name=api$python_name,
    kind=api$kind,native_r_candidate=api$native_r_candidate,
    frozen_source_sha=api$source_git_sha,
    native_mapping_present=api$named_native_candidate,
    native_implementation_started=api$native_implementation_started,
    published_source_difference_open=api$source_contract_gap_unresolved,
    numerical_oracle_approved=api$independent_numeric_parity_pass,
    source_schema_approved=api$behavioral_schema_parity_pass,
    scientific_scope_approved=api$scientific_inference_qualified,
    independent_reviewer_approved=api$independent_contract_review_pass,
    fully_certified=approved,
    first_unresolved_requirement=first,all_unresolved_requirements=all,
    stringsAsFactors=FALSE)
  if(!include_nonfunctions)ans<-ans[api$is_python_function,,drop=FALSE]
  if(only_unapproved)ans<-ans[!ans$fully_certified,,drop=FALSE]
  rownames(ans)<-NULL
  ans
}
