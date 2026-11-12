# Three native R scientific FPCA visualization source records.
# Oracle: eyetrajectoriespy 1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94,
# src/eyetrajectoriespy/plotting.py.
#
# Strict output preserves the scientific data, Matplotlib artist
# coordinates, source labels, marker/errorbar settings and panel semantics.
# R base graphics does not return a Python Axes or pixel-equivalent chart.

.etr_fpca_three_validate <- function(result,strict,cls) {
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict))
    .etr_assert(inherits(result,cls),
      paste("strict source science requires genuine native",cls,"record"))
  invisible(TRUE)
}

.etr_fpca_three_record <- function(name,axis,source_options=list()) {
  .etr_assert(is.list(axis)&&is.list(axis$artists)&&
    length(axis$artists)>=1L,
    "source scientific FPCA plot must have at least one data artist")
  structure(list(
    source_export=name,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),
    axes=list(axis),
    source_options=source_options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_fpca_source_artist_record","list"))
}

.etr_fpca_stability_artist <- function(result) {
  dat<-result$similarities
  k<-ncol(dat)
  n<-nrow(dat)
  whisker<-lapply(seq_len(k),function(i){
    a<-as.numeric(dat[,i])
    q<-unname(stats::quantile(a,c(.25,.5,.75),type=7,names=FALSE))
    width<-q[3L]-q[1L]
    inside<-a[a>=q[1L]-1.5*width & a<=q[3L]+1.5*width]
    .etr_assert(length(inside)>0L,"source whisker requires finite data")
    list(
      label=paste0("FPC",i),
      raw=a,
      quartiles=q,
      whisker_low=min(inside),
      whisker_high=max(inside),
      fliers=a[a<min(inside)|a>max(inside)])
  })
  .etr_fpca_three_record("plot_fpca_stability",list(
    title=sprintf("FPCA bootstrap stability (%d replicates)",n),
    xlabel="",ylabel="Absolute matched functional similarity",
    ylim=c(0,1.02),
    xticklabels=paste0("FPC",seq_len(k)),
    artists=whisker,
    artist_kind="boxplot"))
}

.etr_fpca_influence_artist <- function(result,metric,frame) {
  .etr_assert(is.data.frame(frame)&&
    identical(names(frame),c("group","value")),
    "source influence requires original group and metric summary")
  n<-nrow(frame)
  axis<-list(
    title="Leave-one-group-out FPCA influence",
    xlabel="Omitted group",
    ylabel=gsub("_"," ",metric),
    xticks=as.numeric(seq_len(n)-1L),
    xticklabels=as.character(frame$group),
    xtick_rotation=90,
    artists=list(list(
      kind="line",
      label="_child0",marker="o",
      xdata=as.numeric(seq_len(n)-1L),
      ydata=as.numeric(frame$value))))
  .etr_fpca_three_record("plot_fpca_influence",axis,
    source_options=list(metric=metric))
}

.etr_fpca_cv_artist <- function(result,summary) {
  .etr_assert(is.data.frame(summary)&&
    all(c("n_components","mean_rmse","se_rmse")%in%names(summary))&&
    nrow(summary)>0L,
    "source CV artist requires complete held-out summary")
  x<-as.numeric(summary$n_components)
  y<-as.numeric(summary$mean_rmse)
  se<-as.numeric(summary$se_rmse)
  .etr_assert(all(is.finite(x))&&all(is.finite(y))&&
    all(is.finite(se))&&all(se>=0),
    "source CV error bars require finite nonnegative fold SE")
  axis<-list(
    title="FPCA reconstruction cross-validation",
    xlabel="Retained functional principal components",
    ylabel="Held-out integrated RMSE",
    artists=list(list(
      kind="errorbar",
      label="_nolegend_",
      marker="o",capsize=3,
      xdata=x,ydata=y,
      yerr=se,
      lower=y-se,upper=y+se)))
  .etr_fpca_three_record("plot_fpca_cross_validation",axis)
}
