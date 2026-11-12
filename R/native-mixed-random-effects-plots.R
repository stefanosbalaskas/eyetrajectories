# Native source-aligned Python 1.2 mixed-effects random-function visual audits.
# Source: plotting.py and functional_mixed_effects_nested.py, pinned
# c1cd95ad718327550f7e55393ff38582872f7a94.
# No Python graphics or estimators invoked.

.etr_random_effect_plot_time_unit <- function(result) {
  unit<-result$time_unit
  .etr_assert(is.character(unit)&&length(unit)==1L&&!is.na(unit)&&
    nzchar(unit),"result$time_unit must be a nonempty string")
  unit
}

#' Native participant functional random-effect plot
#' @param result Explicit realized participant mixed-model random-effect record.
#' @param effect Participant functional intercept or slope.
#' @param max_participants Positive number of participant functions, or NULL.
#' @param alpha Opacity in (0, 1].
#' @return Invisible R list with unaltered source-order line geometries.
#' @details Draws using base R; Python source returns Matplotlib Axes.
#' @export
etr_plot_functional_random_effects <- function(result,
    effect="intercept",max_participants=NULL,alpha=.35,
    strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if(isTRUE(strict_source_record)&&!is.null(max_participants))
    .etr_assert(is.integer(max_participants),
      "strict source max_participants must be a Python-style integer")
  frame<-etr_functional_random_effect_frame(result,effect=effect)
  ids<-result$participant_ids
  time<-.etr_frame_time(result$time)
  unit<-.etr_random_effect_plot_time_unit(result)
  if(!is.null(max_participants)){
    .etr_assert(is.numeric(max_participants)&&
      length(max_participants)==1L&&is.finite(max_participants)&&
      max_participants==floor(max_participants)&&max_participants>=1,
      "max_participants must be a positive integer or NULL")
  }
  .etr_assert(is.numeric(alpha)&&length(alpha)==1L&&
    is.finite(alpha)&&alpha>0&&alpha<=1,
    "alpha must lie in (0, 1]")
  n<-if(is.null(max_participants))length(ids) else
    min(length(ids),max_participants)
  ids<-ids[seq_len(n)]
  lines<-frame[frame$participant_id%in%ids,,drop=FALSE]
  .etr_assert(nrow(lines)==n*length(time),
    "participant source frame does not match the plotting domain")
  yr<-range(c(0,lines$estimate))
  if(diff(yr)==0)yr<-yr+c(-.5,.5)
  title<-if(effect=="intercept")
    "Participant functional random intercepts"
  else paste0("Participant functional random slopes: ",
    result$random_slope_predictor)
  graphics::plot(time,as.numeric(lines$estimate[seq_along(time)]),
    type="l",col=grDevices::adjustcolor("black",alpha.f=alpha),
    xlab=paste0("Time (",unit,")"),
    ylab=paste0("Random ",effect,": ",result$dimension_name),
    main=title,ylim=yr)
  if(n>1L)for(j in 2:n){
    loc<-(j-1L)*length(time)+seq_along(time)
    graphics::lines(time,lines$estimate[loc],
      col=grDevices::adjustcolor("black",alpha.f=alpha))
  }
  graphics::abline(h=0,lty=2)
  if(n<=12L)graphics::legend("topright",legend=ids,lty=1,bty="n")
  rownames(lines)<-NULL
  out<-list(lines=lines,participant_ids=ids,
    n_plotted=as.integer(n),effect=effect,alpha=alpha,
    provenance=list(backend="base_R",
      source_operation="plot_functional_random_effects",
      python_axes_return_equivalence=FALSE))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_mixed_participant_source_artist(result,out)))
  invisible(out)
}

#' Native trial functional random-intercept plot
#' @param result Explicit realized nested trial functional random-effect record.
#' @param participant_id Optional source participant name; NULL for all.
#' @param max_trials Positive number of first-seen source trial functions.
#' @return Invisible source-aligned line geometry and retained trial IDs.
#' @export
etr_plot_functional_trial_random_effects <- function(
    result,participant_id=NULL,max_trials=12L,
    strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if(isTRUE(strict_source_record))
    .etr_assert(is.integer(max_trials),
      "strict source max_trials must be a Python-style integer")
  frame<-etr_functional_trial_random_effect_frame(result)
  unit<-.etr_random_effect_plot_time_unit(result)
  .etr_assert(is.numeric(max_trials)&&length(max_trials)==1L&&
    is.finite(max_trials)&&max_trials==floor(max_trials)&&max_trials>=1,
    "max_trials must be a positive integer")
  if(!is.null(participant_id)){
    .etr_assert(is.character(participant_id)&&
      length(participant_id)==1L&&!is.na(participant_id)&&
      nzchar(participant_id),
      "participant_id must be an existing nonempty name or NULL")
    frame<-frame[frame$participant_id==participant_id,,drop=FALSE]
    .etr_assert(nrow(frame)>0L,"Unknown participant_id")
  }
  ids<-head(unique(frame$trial_id),max_trials)
  selected<-frame[frame$trial_id%in%ids,,drop=FALSE]
  .etr_assert(nrow(selected)>0L,
    "selected trial source must contain observed time points")
  yr<-range(c(0,selected$value))
  if(diff(yr)==0)yr<-yr+c(-.5,.5)
  xr<-range(selected$time)
  if(diff(xr)==0)xr<-xr+c(-.5,.5)
  graphics::plot(0,0,type="n",xlim=xr,ylim=yr,
    xlab=paste0("Time (",unit,")"),
    ylab="Trial functional random intercept",
    main=paste0("Trial-level functional random effects",
      if(!is.null(participant_id))paste0(": ",participant_id) else ""))
  for(id in ids){
    part<-selected[selected$trial_id==id,,drop=FALSE]
    graphics::lines(part$time,part$value)
  }
  graphics::abline(h=0)
  if(length(ids)<=12L)graphics::legend("topright",legend=ids,lty=1,bty="n")
  rownames(selected)<-NULL
  out<-list(lines=selected,trial_ids=ids,
    n_plotted=as.integer(length(ids)),participant_id=participant_id,
    provenance=list(backend="base_R",
      source_operation="plot_functional_trial_random_effects",
      python_axes_return_equivalence=FALSE))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_mixed_trial_source_artist(result,out)))
  invisible(out)
}
