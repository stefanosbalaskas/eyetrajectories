# Frozen Python 1.2 plotting.py simulation artists, pinned at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Scientific plot arrays and semantic artist metadata; actual rendering
# remains native R. No Python Matplotlib Axes or Figure impersonation.

.etr_sim_artist_check<-function(result,strict){
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict))
    .etr_assert(inherits(result,"etr_functional_simulation_result"),
      "strict simulation artist requires genuine native functional simulation result")
  invisible(TRUE)
}

.etr_sim_artist_record<-function(kind,axis,options=list()){
  .etr_assert(is.list(axis)&&
    is.character(axis$title)&&length(axis$title)==1L&&
    is.character(axis$xlabel)&&is.character(axis$ylabel),
    "source simulation artist requires a complete scientific axis")
  structure(list(
    source_export=kind,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    axes=list(axis),panel_layout=c(1L,1L),
    source_options=options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_functional_simulation_artist_source_record","list"))
}

.etr_sim_curve_artist<-function(geometry,time_unit,show_pre_missing,
    source_curve,source_dimension){
  .etr_assert(is.list(geometry)&&
    all(c("curve_id","dimension","latent","observed","removed")%in%
      names(geometry)),
    "source simulation curve geometry requires observed and latent truth")
  line<-list(
    label="latent truth",
    xdata=as.numeric(geometry$latent$time),
    ydata=as.numeric(geometry$latent$value))
  points<-list(list(
    label="observed",marker="o",
    offsets=unname(as.matrix(geometry$observed))))
  if(isTRUE(show_pre_missing)&&nrow(geometry$removed))
    points[[2L]]<-list(
      label="removed/missing by design",marker="x",
      offsets=unname(as.matrix(geometry$removed)))
  axis<-list(
    title=paste0("Functional simulation truth audit: ",geometry$curve_id),
    xlabel=paste0("Time (",time_unit,")"),
    ylabel=geometry$dimension,
    lines=list(line),
    collections=points,
    legend=TRUE)
  .etr_sim_artist_record("plot_functional_simulation_curve",axis,
    options=list(curve=as.integer(source_curve),
      dimension=as.integer(source_dimension),
      show_pre_missing=isTRUE(show_pre_missing)))
}

.etr_sim_warps_artist<-function(geometry,time_unit,max_curves){
  .etr_assert(is.matrix(geometry$warps)&&
    nrow(geometry$warps)==geometry$n_plotted,
    "source simulation warp matrix does not match retained curve count")
  g<-as.numeric(geometry$time)
  lines<-c(list(list(
    label="identity warp",linestyle="--",alpha=1,
    xdata=g,ydata=as.numeric(geometry$identity))),
    lapply(seq_len(geometry$n_plotted),function(i)
      list(label=paste0("_child",i),linestyle="-",
        alpha=as.numeric(geometry$alpha),
        xdata=g,ydata=as.numeric(geometry$warps[i,]))))
  axis<-list(
    title=paste0("Retained phase warps (n=",geometry$n_plotted,")"),
    xlabel=paste0("Observed time (",time_unit,")"),
    ylabel=paste0("Latent/process time (",time_unit,")"),
    lines=lines,legend=TRUE)
  .etr_sim_artist_record("plot_functional_simulation_phase_warps",
    axis,options=list(max_curves=max_curves,
      alpha=as.numeric(geometry$alpha)))
}

.etr_sim_variance_artist<-function(geometry){
  .etr_assert(is.data.frame(geometry$geometry)&&
    all(c("component_index","source","kind","variance","center","width")%in%
      names(geometry$geometry)),
    "source simulation variance plot requires retained six-source bars")
  bars<-geometry$geometry
  source_order<-c("curve declared","curve realized",
    "participant declared","participant realized",
    "trial declared","trial realized")
  group<-paste(bars$source,bars$kind)
  .etr_assert(all(group%in%source_order)&&
    nrow(bars)==length(unique(bars$component_index))*6L&&
    all(is.finite(bars$variance))&&all(bars$variance>=0),
    "source population variance bars require finite declared and realized values")
  patches<-lapply(seq_len(nrow(bars)),function(i)
    list(label=group[[i]],
      x=as.numeric(bars$center[[i]]-bars$width[[i]]/2),
      center=as.numeric(bars$center[[i]]),
      height=as.numeric(bars$variance[[i]]),
      width=as.numeric(bars$width[[i]])))
  k<-length(unique(bars$component_index))
  axis<-list(
    title="Functional simulation score-source variance audit",
    xlabel="",ylabel="Score variance",
    xticks=as.numeric(seq_len(k)-1L),
    xticklabels=paste("component",seq_len(k)),
    patches=patches,
    legend_labels=c("curve declared","curve realized",
      "participant declared","participant realized",
      "trial declared","trial realized"),
    variance_ddof=0L,
    legend=TRUE)
  .etr_sim_artist_record("plot_functional_simulation_score_variances",
    axis)
}
