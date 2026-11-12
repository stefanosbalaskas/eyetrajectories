# Frozen Python eyetrajectoriespy==1.2.0 source artists:
# plotting.py::plot_functional_random_effects,
# functional_mixed_effects_nested.py::plot_functional_trial_random_effects,
# plotting.py::plot_conformal_fpca_anomaly.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Typed native scientific geometry is NOT a live Python Matplotlib Axes.

.etr_mixed_participant_source_artist <- function(result,geometry) {
  ids<-as.character(geometry$participant_ids)
  frame<-geometry$lines
  time<-as.numeric(result$time)
  effect<-geometry$effect
  .etr_assert(is.data.frame(frame)&&length(ids)>=1L&&
    all(c("participant_id","time","estimate")%in%names(frame))&&
    nrow(frame)==length(ids)*length(time)&&
    all(is.finite(frame$estimate))&&all(is.finite(frame$time)),
    "participant source scientific artist requires complete finite random functions")
  alpha<-geometry$alpha
  artists<-lapply(seq_along(ids),function(i) {
    part<-frame[as.character(frame$participant_id)==ids[i],,drop=FALSE]
    .etr_assert(nrow(part)==length(time)&&
      isTRUE(all.equal(as.numeric(part$time),time,tolerance=0,
        check.attributes=FALSE)),
      "participant source effect time and source order must match")
    list(kind="line",marker="None",linestyle="-",
      xdata=time,ydata=as.numeric(part$estimate),alpha=as.numeric(alpha),
      label=if(length(ids)<=12L)ids[i] else NULL)
  })
  artists[[length(artists)+1L]]<-list(kind="horizontal_reference",
    xdata=c(0,1),ydata=c(0,0),x_transform="axes_fraction",
    linestyle="--")
  ax<-list(title=if(identical(effect,"intercept"))
      "Participant functional random intercepts" else
      paste0("Participant functional random slopes: ",
        result$random_slope_predictor),
    xlabel=paste0("Time (",result$time_unit,")"),
    ylabel=paste0("Random ",effect,": ",result$dimension_name),
    legend=length(ids)<=12L,
    legend_labels=if(length(ids)<=12L)ids else character(0),
    artists=artists)
  .etr_nonlinear_artist_record("plot_functional_random_effects",
    list(ax),options=list(effect=effect,alpha=alpha,
      participant_ids=ids,n_plotted=length(ids),
      source_blup_estimates_reused=TRUE))
}

.etr_mixed_trial_source_artist <- function(result,geometry) {
  ids<-as.character(geometry$trial_ids)
  frame<-geometry$lines
  .etr_assert(length(ids)>=1L&&is.data.frame(frame)&&
    all(c("trial_id","time","value")%in%names(frame))&&
    all(is.finite(frame$time))&&all(is.finite(frame$value)),
    "trial source scientific artist requires finite original BLUP time series")
  artists<-lapply(ids,function(id) {
    part<-frame[as.character(frame$trial_id)==id,,drop=FALSE]
    .etr_assert(nrow(part)>0L,
      "source trial selection must contain original observed rows")
    list(kind="line",marker="None",linestyle="-",label=id,
      xdata=as.numeric(part$time),ydata=as.numeric(part$value))
  })
  artists[[length(artists)+1L]]<-list(kind="horizontal_reference",
    xdata=c(0,1),ydata=c(0,0),x_transform="axes_fraction",
    linestyle="-",linewidth=1.0)
  participant<-geometry$participant_id
  ax<-list(title=paste0("Trial-level functional random effects",
      if(is.null(participant))"" else paste0(": ",participant)),
    xlabel=paste0("Time (",result$time_unit,")"),
    ylabel="Trial functional random intercept",
    legend=length(ids)<=12L,
    legend_labels=if(length(ids)<=12L)ids else character(0),
    artists=artists)
  .etr_nonlinear_artist_record("plot_functional_trial_random_effects",
    list(ax),options=list(participant_id=participant,trial_ids=ids,
      n_plotted=length(ids),source_trial_blups_reused=TRUE))
}

.etr_conformal_source_pvalue_frame <- function(result,max_targets) {
  .etr_assert(is.list(result)&&
    all(c("target_curve_ids","p_values","alpha")%in%names(result)),
    "strict conformal source requires original target_curve_ids, p_values and alpha")
  ids<-result$target_curve_ids;p<-result$p_values;alpha<-result$alpha
  .etr_assert(is.character(ids)&&length(ids)>=1L&&!anyNA(ids)&&
    all(nzchar(ids))&&!anyDuplicated(ids)&&
    is.numeric(p)&&!is.logical(p)&&length(p)==length(ids)&&
    all(is.finite(p))&&all(p>=0&p<=1)&&
    is.numeric(alpha)&&!is.logical(alpha)&&length(alpha)==1L&&
    is.finite(alpha)&&alpha>0&&alpha<1,
    "strict conformal source p-values/IDs/alpha must be valid")
  if("review_flags"%in%names(result)) {
    .etr_assert(is.logical(result$review_flags)&&
      length(result$review_flags)==length(ids)&&
      !anyNA(result$review_flags)&&
      identical(as.logical(result$review_flags),as.logical(p<=alpha)),
      "source conformal review_flags must match source p-values and alpha")
  }
  n<-min(as.integer(max_targets),length(ids))
  data.frame(curve_id=ids[seq_len(n)],
    target_index=seq_len(n)-1L,
    p_value=as.numeric(p[seq_len(n)]),stringsAsFactors=FALSE)
}

.etr_conformal_pvalue_source_artist <- function(result,coords) {
  alpha<-as.numeric(result$alpha)
  alpha_text<-format(alpha,scientific=FALSE,trim=TRUE)
  ax<-list(title="Split-conformal FPCA anomaly review",
    xlabel="Target trajectory",ylabel="Marginal conformal p-value",
    ylim=c(0,1),
    xticks=as.numeric(coords$target_index),
    xticklabels=as.character(coords$curve_id),
    tick_rotation=90,
    artists=list(
      list(kind="scatter",marker="o",offsets=unname(cbind(
        as.numeric(coords$target_index),as.numeric(coords$p_value)))),
      list(kind="horizontal_reference",xdata=c(0,1),
        ydata=c(alpha,alpha),x_transform="axes_fraction",
        linestyle="--",label=paste0("alpha=",alpha_text))),
    legend=TRUE,legend_labels=paste0("alpha=",alpha_text))
  .etr_nonlinear_artist_record("plot_conformal_fpca_anomaly",
    list(ax),options=list(n_targets=nrow(coords),
      source_pvalues_direct=TRUE,alpha=alpha,
      no_reconstructed_calibration_scores=TRUE,
      marginal_not_familywise=TRUE))
}
