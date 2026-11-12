# Native scientific Matplotlib artist geometry for three functional registration
# visualization exports, frozen eyetrajectoriespy==1.2.0 source:
# src/eyetrajectoriespy/plotting.py at commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
#
# These records reflect source line coordinates, labels, styles, and panels.
# Native R draws using base graphics; it cannot return Python Axes or Figure.

.etr_reg_artist_validate_strict <- function(strict) {
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  invisible(TRUE)
}

.etr_reg_artist_record <- function(name,axes,layout,kind,options=list()) {
  .etr_assert(is.list(axes)&&length(axes)==prod(layout)&&
    all(vapply(axes,function(a)
      is.list(a)&&is.character(a$title)&&
      is.character(a$xlabel)&&is.character(a$ylabel)&&
      is.list(a$lines),logical(1L))),
    "registration artist must retain all original scientific plot axes")
  structure(list(
    source_export=name,
    renderer="native_R_base_graphics",
    python_return_kind=kind,
    panel_layout=as.integer(layout),
    axes=axes,
    source_options=options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_registration_source_artist_record","list"))
}

.etr_reg_reconstruction_artist <- function(frame) {
  .etr_assert(is.data.frame(frame)&&
    identical(names(frame),c("n_components","mean_integrated_rmse"))&&
    nrow(frame)>=1L&&
    all(is.finite(frame$n_components))&&
    all(is.finite(frame$mean_integrated_rmse)),
    "reconstruction source lines require observed held-out metrics")
  axis<-list(
    title="FPCA reconstruction curve",
    xlabel="Retained functional principal components",
    ylabel="Mean integrated RMSE",
    lines=list(list(
      kind="line",marker="o",linestyle="-",
      label="_child0",
      xdata=as.numeric(frame$n_components),
      ydata=as.numeric(frame$mean_integrated_rmse))),
    legend=FALSE)
  .etr_reg_artist_record("plot_reconstruction_curve",list(axis),
    c(1L,1L),"matplotlib.axes.Axes")
}

.etr_reg_registration_artist <- function(result,source) {
  names<-c("Original","Registered")
  .etr_assert(is.list(source)&&
    all(c("original","registered","dimension","curve_ids")%in%
      names(source))&&
    identical(names(source$original),c("curve_id","time","value"))&&
    identical(names(source$registered),c("curve_id","time","value")),
    "registration source panels need original and registered actual samples")
  ids<-as.character(source$curve_ids)
  unit<-result$original$time_unit
  axes<-lapply(seq_along(names),function(d){
    frame<-if(d==1L)source$original else source$registered
    lines<-lapply(seq_along(ids),function(i){
      idx<-frame$curve_id==ids[[i]]
      list(kind="line",label=paste0("_child",i-1L),
        alpha=.25,linestyle="-",marker="none",
        xdata=as.numeric(frame$time[idx]),
        ydata=as.numeric(frame$value[idx]))
    })
    list(title=names[[d]],xlabel=paste0("Time (",unit,")"),
      ylabel=source$dimension,lines=lines,legend=FALSE)
  })
  .etr_reg_artist_record("plot_registration",axes,c(1L,2L),
    "tuple[matplotlib.figure.Figure,numpy.ndarray[matplotlib.axes.Axes]]",
    options=list(dimension=source$dimension,max_curves=length(ids),
      curve_ids=ids,figure_size_inches=c(10,4)))
}

.etr_reg_warp_artist <- function(result,frame,displacement) {
  .etr_assert(is.data.frame(frame)&&
    identical(names(frame),c("curve_id","time","value")),
    "warping source trace table requires actual fitted warp trajectories")
  ids<-as.character(result$original$curve_ids)
  lines<-lapply(seq_along(ids),function(i){
    idx<-frame$curve_id==ids[[i]]
    list(kind="line",label=paste0("_child",i-1L),
      alpha=.3,linestyle="-",marker="none",
      xdata=as.numeric(frame$time[idx]),
      ydata=as.numeric(frame$value[idx]))
  })
  time<-as.numeric(result$original$time)
  lines[[length(lines)+1L]]<-if(isTRUE(displacement))
    list(kind="horizontal_reference",label="_child_reference",
      linestyle="--",xdata=c(0,1),ydata=c(0,0),
      x_transform="axes_fraction") else
    list(kind="line",label="identity",linestyle="--",
      xdata=time,ydata=time)
  axis<-list(title="",xlabel=paste0("Reference time (",
    result$original$time_unit,")"),
    ylabel=if(displacement)"h(t) - t" else "Warped source time",
    lines=lines,legend=!displacement,
    legend_labels=if(displacement)character() else "identity")
  .etr_reg_artist_record("plot_warping_functions",list(axis),
    c(1L,1L),"matplotlib.axes.Axes",
    options=list(displacement=isTRUE(displacement)))
}
