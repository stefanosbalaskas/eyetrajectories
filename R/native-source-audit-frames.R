# Native provenance and diagnostic frames pinned to eyetrajectoriespy==1.2.0.
# Python source SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# These are READ-ONLY R list adapters, not new statistical estimators.

.etr_frame_record <- function(x,required,what) {
  .etr_assert(is.list(x)&&!is.null(names(x))&&
    all(required%in%names(x)),
    paste0(what," must be a named native record with fields: ",
      paste(required,collapse=", ")))
  invisible(TRUE)
}
.etr_frame_ids <- function(x,what) {
  .etr_assert(is.character(x)&&length(x)>0L&&!anyNA(x)&&
    all(nzchar(x))&&!anyDuplicated(x),
    paste0(what," must be nonempty unique character identifiers"))
  x
}
.etr_frame_time <- function(x) {
  .etr_assert(is.numeric(x)&&length(x)>=1L&&
    all(is.finite(x))&&
    (length(x)==1L||all(diff(x)>0)),
    "time must be finite and strictly increasing")
  as.numeric(x)
}
.etr_frame_matrix <- function(x,nr,nc,what) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&
    identical(dim(x),as.integer(c(nr,nc)))&&all(is.finite(x)),
    paste0(what," must be a finite matrix with expected shape"))
  x
}
.etr_frame_vector <- function(x,n,what) {
  .etr_assert(is.numeric(x)&&length(x)==n&&!anyNA(x)&&
    all(is.finite(x)),paste0(what," must be a finite numeric vector"))
  as.numeric(x)
}

# Convert the already fitted native R/nlme result to the six source
# participant-BLUP frame fields, with no statistical refit or input mutation.
.etr_joint_fit_random_effect_record <- function(fit) {
  .etr_assert(inherits(fit,"etr_joint_bspline_mixed"),
    "fit must be a native joint B-spline mixed model")
  dimension <- if(!is.null(fit$dimension_name)) fit$dimension_name
    else fit$dimension
  intercept <- if(!is.null(fit$random_intercept_functions))
    fit$random_intercept_functions else fit$random_effect_functions
  slope <- if(!is.null(fit$random_slope_functions))
    fit$random_slope_functions else fit$random_slope_effect_functions
  list(participant_ids=fit$participant_ids,
    time=fit$time,dimension_name=dimension,
    random_intercept_functions=intercept,
    random_slope_functions=slope,
    random_slope_predictor=fit$random_slope_predictor)
}

#' Source-ordered participant-level random functional effect frame
#' @param result Explicit native record of a realized functional mixed fit.
#' @param effect Either "intercept" or "slope".
#' @return One row per participant and time, in source order.
#' @export
etr_functional_random_effect_frame <- function(result,effect="intercept") {
  # Accept a real fitted native joint Gaussian model directly; retain the
  # pre-existing strict source-shaped list adapter unchanged otherwise.
  if(inherits(result,"etr_joint_bspline_mixed"))
    result <- .etr_joint_fit_random_effect_record(result)
  .etr_frame_record(result,c("participant_ids","time","dimension_name",
    "random_intercept_functions"),"result")
  .etr_assert(is.character(effect)&&length(effect)==1L&&
    effect%in%c("intercept","slope"),
    "effect must be intercept or slope")
  ids<-.etr_frame_ids(result$participant_ids,"participant_ids")
  time<-.etr_frame_time(result$time)
  .etr_assert(is.character(result$dimension_name)&&
    length(result$dimension_name)==1L&&
    !is.na(result$dimension_name)&&nzchar(result$dimension_name),
    "dimension_name must be a nonempty string")
  source<-if(effect=="intercept")result$random_intercept_functions else{
    .etr_assert(!is.null(result$random_slope_functions),
      "result does not contain a participant random functional slope")
    result$random_slope_functions
  }
  source<-.etr_frame_matrix(source,length(ids),length(time),
    paste0("random_",effect,"_functions"))
  predictor<-if(effect=="intercept")NA_character_ else{
    .etr_assert(is.character(result$random_slope_predictor)&&
      length(result$random_slope_predictor)==1L&&
      !is.na(result$random_slope_predictor)&&
      nzchar(result$random_slope_predictor),
      "random_slope_predictor must name the random slope")
    result$random_slope_predictor
  }
  index<-rep(seq_along(ids),each=length(time))
  tid<-rep(seq_along(time),times=length(ids))
  data.frame(participant_id=ids[index],time=time[tid],
    dimension=rep(result$dimension_name,length(index)),
    effect=rep(effect,length(index)),
    random_slope_predictor=rep(predictor,length(index)),
    estimate=source[cbind(index,tid)],stringsAsFactors=FALSE)
}

#' Source-ordered nested trial random functional effect frame
#' @param result Explicit realized mixed-model trial effect record.
#' @return One row per source curve and time; curve_index is zero-based.
#' @export
etr_functional_trial_random_effect_frame <- function(result) {
  if(inherits(result,"etr_joint_bspline_mixed_nested_trial") ||
     inherits(result,"etr_joint_bspline_mixed_nested_slope")) {
    .etr_assert(identical(result$trial_random_effect,"functional_intercept"),
      "result does not contain a trial functional random intercept")
    return(etr_nested_source_trial_effect_frame(result))
  }
  fields<-c("source_curve_ids","curve_participant_ids",
    "curve_trial_ids","trial_ids","time","trial_random_effect",
    "trial_random_effect_functions")
  .etr_frame_record(result,fields,"result")
  .etr_assert(identical(result$trial_random_effect,"functional_intercept"),
    "result does not contain a trial functional random intercept")
  ids<-.etr_frame_ids(result$source_curve_ids,"source_curve_ids")
  n<-length(ids);t<-.etr_frame_time(result$time)
  for(nm in c("curve_participant_ids","curve_trial_ids","trial_ids"))
    .etr_assert(is.character(result[[nm]])&&
      length(result[[nm]])==n&&!anyNA(result[[nm]]),
      paste0(nm," must match source curve identifiers"))
  v<-.etr_frame_matrix(result$trial_random_effect_functions,n,length(t),
    "trial_random_effect_functions")
  a<-rep(seq_len(n),each=length(t));b<-rep(seq_along(t),times=n)
  data.frame(curve_index=as.integer(a-1L),curve_id=ids[a],
    participant_id=result$curve_participant_ids[a],
    source_trial_id=result$curve_trial_ids[a],
    trial_id=result$trial_ids[a],time=t[b],
    effect=rep("trial_functional_intercept",length(a)),
    value=v[cbind(a,b)],stringsAsFactors=FALSE)
}

.etr_bootstrap_identifiers <- function(bootstrap){
  fields<-c("sampled_participant_indices","sampled_source_participant_ids",
    "bootstrap_participant_ids")
  .etr_frame_record(bootstrap,fields,"bootstrap")
  ix<-bootstrap$sampled_participant_indices
  .etr_assert(is.matrix(ix)&&is.numeric(ix)&&
    nrow(ix)>=1L&&ncol(ix)>=1L&&
    all(is.finite(ix))&&all(ix>=0)&
    all(ix==floor(ix)),"sampled_participant_indices must be a nonnegative integer matrix")
  for(nm in c("sampled_source_participant_ids","bootstrap_participant_ids")){
    groups<-bootstrap[[nm]]
    .etr_assert(is.list(groups)&&length(groups)==nrow(ix)&&
      all(vapply(groups,function(x)
        is.character(x)&&length(x)==ncol(ix)&&!anyNA(x),
        logical(1L))),paste0(nm," must align with each bootstrap draw"))
  }
  list(ix=ix,nb=nrow(ix),np=ncol(ix))
}

#' Long form source and bootstrap participant identities for full refits
#' @param bootstrap Explicit native R bootstrap provenance record.
#' @return Zero-based bootstrap and draw indices with original IDs.
#' @export
etr_functional_mixed_effects_full_refit_audit_frame <- function(bootstrap) {
  z<-.etr_bootstrap_identifiers(bootstrap)
  row<-rep(seq_len(z$nb),each=z$np)
  col<-rep(seq_len(z$np),times=z$nb)
  data.frame(bootstrap_replicate=as.integer(row-1L),
    draw_index=as.integer(col-1L),
    source_participant_index=as.integer(z$ix[cbind(row,col)]),
    source_participant_id=vapply(seq_along(row),function(i)
      bootstrap$sampled_source_participant_ids[[row[i]]][[col[i]]],
      character(1L)),
    bootstrap_participant_id=vapply(seq_along(row),function(i)
      bootstrap$bootstrap_participant_ids[[row[i]]][[col[i]]],
      character(1L)),stringsAsFactors=FALSE)
}

#' Long form source/bootstrap trial identity audit for full refits
#' @param bootstrap Explicit bootstrap trial provenance; may be empty.
#' @return Five-column data frame; bootstrap replicate is zero-based.
#' @export
etr_functional_mixed_effects_full_refit_trial_audit_frame <- function(bootstrap) {
  .etr_frame_record(bootstrap,"bootstrap_trial_audit","bootstrap")
  sets<-bootstrap$bootstrap_trial_audit
  .etr_assert(is.list(sets),"bootstrap_trial_audit must be a list of replicate records")
  fields<-c("source_participant_id","bootstrap_participant_id",
    "source_trial_id","bootstrap_trial_id")
  out<-data.frame(bootstrap_replicate=integer(),
    source_participant_id=character(),
    bootstrap_participant_id=character(),
    source_trial_id=character(),
    bootstrap_trial_id=character(),stringsAsFactors=FALSE)
  frames<-lapply(seq_along(sets),function(i){
    records<-sets[[i]]
    if(!length(records))return(NULL)
    .etr_assert(is.list(records),
      "each bootstrap trial audit replicate must be a list")
    if(is.data.frame(records)){
      .etr_frame_record(records,fields,"bootstrap trial audit replicate")
      records<-records[fields]
      .etr_assert(all(vapply(records,function(column)
        is.character(column)&&is.null(dim(column))&&!anyNA(column),
        logical(1L))),"trial audit identifiers must be nonmissing character columns")
    }else{
      rows<-lapply(records,function(record){
        .etr_assert(is.character(record)&&length(record)==4L&&
          !anyNA(record),"trial audit record must have four source/target identifiers")
        unname(record)
      })
      records<-as.data.frame(do.call(rbind,rows),stringsAsFactors=FALSE)
      names(records)<-fields
    }
    data.frame(bootstrap_replicate=rep(i-1L,nrow(records)),
      records,stringsAsFactors=FALSE)
  })
  out<-do.call(rbind,c(list(out),frames))
  rownames(out)<-NULL;out
}

#' Source-ordered wild-bootstrap truncation scan audit frame
#' @param result Native record of already computed scan matrices and targets.
#' @return One row for each candidate h and target; no selection performed.
#' @export
etr_fpca_wild_bootstrap_truncation_scan_frame <- function(result) {
  cols<-c("reference_projections","reference_se","critical_values",
    "lower","upper","centers","widths")
  .etr_frame_record(result,c("candidate_components","target_curve_ids",cols),
    "result")
  h<-result$candidate_components
  .etr_assert(is.numeric(h)&&length(h)>=1L&&
    all(is.finite(h))&&all(h>=1)&&all(h==floor(h))&&
    !anyDuplicated(h),"candidate_components must be distinct positive integers")
  ids<-.etr_frame_ids(result$target_curve_ids,"target_curve_ids")
  nh<-length(h);nc<-length(ids)
  for(nm in cols).etr_frame_matrix(result[[nm]],nh,nc,nm)
  row<-rep(seq_len(nh),each=nc);col<-rep(seq_len(nc),times=nh)
  out<-data.frame(curve_id=ids[col],inference_components=as.integer(h[row]),
    reference_projection=result$reference_projections[cbind(row,col)],
    heteroscedastic_se=result$reference_se[cbind(row,col)],
    critical_value=result$critical_values[cbind(row,col)],
    lower=result$lower[cbind(row,col)],
    upper=result$upper[cbind(row,col)],
    center=result$centers[cbind(row,col)],
    width=result$widths[cbind(row,col)],stringsAsFactors=FALSE)
  out
}

#' Source-ordered wild-bootstrap truncation selection audit frame
#' @param result Native record of an already-computed FPCA truncation selection.
#' @return One row per target; unavailable components remain NA_integer_.
#' @export
etr_fpca_wild_bootstrap_truncation_selection_frame <- function(result) {
  cols<-c("selected_components","selected_centers","selected_widths",
    "selected_lower","selected_upper")
  .etr_frame_record(result,c("scan",cols),"result")
  .etr_frame_record(result$scan,"target_curve_ids","result$scan")
  ids<-.etr_frame_ids(result$scan$target_curve_ids,"target_curve_ids")
  n<-length(ids)
  s<-result$selected_components
  .etr_assert(is.numeric(s)&&length(s)==n&&
    all(is.na(s)|is.finite(s))&&
    all(is.na(s)|s==floor(s))&&
    all(is.na(s)|s>=1),
    "selected_components must contain positive integers or NA")
  for(nm in cols[-1L]){
    v<-result[[nm]]
    .etr_assert(is.numeric(v)&&length(v)==n&&
      all(is.na(v)|is.finite(v)),
      paste0(nm," must match targets and be finite or NA"))
  }
  data.frame(curve_id=ids,
    selected_inference_components=as.integer(s),
    selected_center=as.numeric(result$selected_centers),
    selected_width=as.numeric(result$selected_widths),
    selected_lower=as.numeric(result$selected_lower),
    selected_upper=as.numeric(result$selected_upper),
    stringsAsFactors=FALSE)
}
