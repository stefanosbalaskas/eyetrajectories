# Source-scientific native R FPCA inference graphics.
# Frozen Python 1.2 plotting.py source commit:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Preserves numerical artists; native base graphics is not Matplotlib.

.etr_fpca_outlier_artist <- function(result,frame) {
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L&&
    all(c("reconstruction_robust_z","score_mahalanobis_sq",
      "score_cutoff","review_flag")%in%names(frame)),
    "native FPCA outlier source artists require complete diagnostics")
  cutoff<-as.numeric(frame$score_cutoff[[1L]])
  .etr_assert(length(cutoff)==1L&&is.finite(cutoff),
    "FPCA score cutoff must be finite")
  threshold<-result$provenance$reconstruction_z_threshold
  lines<-list()
  if(!is.null(threshold)){
    .etr_assert(is.numeric(threshold)&&length(threshold)==1L&&
      is.finite(threshold),
      "native reconstruction robust-z threshold must be finite")
    lines[[length(lines)+1L]]<-list(
      kind="vertical_reference",linestyle="--",
      xdata=c(threshold,threshold),ydata=c(0,1),
      y_transform="axes_fraction")
  }
  lines[[length(lines)+1L]]<-list(
    kind="horizontal_reference",linestyle="--",
    xdata=c(0,1),ydata=rep(cutoff,2L),
    x_transform="axes_fraction")
  axis<-list(
    title="FPCA trajectory review diagnostics",
    xlabel="Reconstruction robust z",
    ylabel="Squared Mahalanobis distance in FPC score space",
    artists=list(list(
      kind="scatter",marker="o",
      offsets=unname(cbind(
        as.numeric(frame$reconstruction_robust_z),
        as.numeric(frame$score_mahalanobis_sq))))),
    lines=lines,legend=FALSE)
  .etr_fpca_three_record(
    "plot_fpca_outlier_diagnostics",axis,
    source_options=list(
      reconstruction_z_threshold=threshold,
      score_cutoff=cutoff,
      n_review_flag=sum(frame$review_flag)))
}

.etr_fpca_subspace_artist <- function(result,metric,frame) {
  .etr_assert(is.data.frame(frame)&&
    identical(names(frame),c("replicate","value"))&&
    nrow(frame)>=1L&&all(is.finite(frame$value)),
    "native subspace plot requires original finite replicate metrics")
  ylab<-switch(metric,
    normalized_projector_distance="Normalized projector distance",
    max_principal_angle_degrees="Maximum principal angle (degrees)",
    min_principal_cosine="Minimum principal cosine")
  .etr_assert(is.character(ylab)&&length(ylab)==1L,
    "unsupported FPCA stability metric")
  comp<-as.integer(result$component_indices)
  .etr_assert(length(comp)>=1L&&all(is.finite(comp)),
    "source FPCA subspace must retain component indices")
  axis<-list(
    title=sprintf("FPCA subspace stability: FPC%d\u2013FPC%d",
      comp[[1L]]+1L,tail(comp,1L)+1L),
    xlabel="Bootstrap replicate",
    ylabel=ylab,
    artists=list(list(
      kind="line",label="_child0",
      marker="o",linestyle="none",
      xdata=as.numeric(frame$replicate),
      ydata=as.numeric(frame$value))),
    legend=FALSE)
  .etr_fpca_three_record("plot_fpca_subspace_stability",axis,
    source_options=list(metric=metric))
}

.etr_fpca_mean_band_artist <- function(result,dimension,frame) {
  .etr_assert(is.data.frame(frame)&&
    identical(names(frame),c("time","mean","lower","upper"))&&
    nrow(frame)>=2L&&all(is.finite(as.matrix(frame))),
    "source mean-band artist requires finite observed-grid bounds")
  .etr_assert(all(frame$lower<=frame$upper),
    "source functional band lower bound must not exceed upper")
  level<-as.numeric(result$confidence_level)
  .etr_assert(length(level)==1L&&is.finite(level)&&
    level>0&&level<1,
    "source confidence level must be between 0 and 1")
  band_label<-sprintf("%.1f%% simultaneous band",100*level)
  axis<-list(
    title=sprintf("Functional mean band: %s(t)",dimension),
    xlabel=sprintf("Time (%s)",result$time_unit),
    ylabel=dimension,
    artists=list(
      list(kind="fill_between",label=band_label,
        xdata=as.numeric(frame$time),
        lower=as.numeric(frame$lower),
        upper=as.numeric(frame$upper),
        alpha=0.2),
      list(kind="line",label="functional mean",
        xdata=as.numeric(frame$time),
        ydata=as.numeric(frame$mean))),
    legend=TRUE,
    legend_labels=c(band_label,"functional mean"))
  .etr_fpca_three_record("plot_functional_mean_band",axis,
    source_options=list(dimension=dimension,
      confidence_level=level))
}
