# Native R source-scientific artist geometry for the frozen Python 1.2
# univariate sparse PACE and native irregular trajectory plotting family.
# Frozen oracle: src/eyetrajectoriespy/plotting.py at commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
#
# These are inspectable scientific artist data, NOT Matplotlib Axes objects.
# Actual rendering remains native base R, without Python runtime dependencies.

.etr_su_artist_require<-function(result,strict,type){
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  if(!isTRUE(strict))return(invisible(TRUE))
  if(identical(type,"fit")){
    .etr_assert(inherits(result,"etr_sparse_fpca_native")&&
      identical(result$fit_method,"native_covariance")&&
      identical(result$score_method,"PACE"),
      "strict source sparse FPCA graphics require a genuine native covariance/PACE fit")
  }else{
    .etr_assert(identical(type,"irregular")&&
      inherits(result,"etr_irregular_trajectory_set"),
      "strict source irregular graphics require native irregular trajectories")
  }
  invisible(TRUE)
}

.etr_su_artist_record<-function(name,axes,source_options=list(),
    colorbar=NULL){
  .etr_assert(is.list(axes)&&length(axes)==1L&&is.list(axes[[1L]]),
    "source univariate geometry must represent one Matplotlib axis")
  structure(list(
    source_export=name,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),
    axes=axes,
    colorbar=colorbar,
    source_options=source_options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_sparse_univariate_artist_source_record","list"))
}

.etr_su_covariance_artist<-function(result){
  grid<-as.numeric(result$evaluation_grid)
  z<-unname(result$covariance)
  .etr_assert(is.matrix(z)&&is.numeric(z)&&
    identical(dim(z),c(length(grid),length(grid)))&&
    all(is.finite(z)),
    "source latent covariance image requires finite square operator")
  clim<-range(z)
  axis<-list(
    title="Sparse FPCA fitted latent covariance",
    xlabel=paste0("Time s (",result$time_unit,")"),
    ylabel=paste0("Time t (",result$time_unit,")"),
    image=z,
    image_origin="lower",
    image_aspect="auto",
    extent=c(grid[[1L]],tail(grid,1L),
      grid[[1L]],tail(grid,1L)),
    vmin=clim[[1L]],vmax=clim[[2L]],
    cmap="viridis")
  .etr_su_artist_record(
    "plot_sparse_fpca_covariance",list(axis),
    colorbar=list(label="Latent covariance",
      vmin=clim[[1L]],vmax=clim[[2L]]))
}

.etr_su_component_artist<-function(result,curves,component,multiplier){
  .etr_assert(is.data.frame(curves)&&
    identical(names(curves),c("time","mean","lower","upper")),
    "source sparse component requires mean/low/high fit geometry")
  k<-as.integer(component)+1L
  amount<-format(as.numeric(multiplier),trim=TRUE,scientific=FALSE)
  axis<-list(
    title=paste0("Sparse FPC",k,": ",result$dimension,"(t)"),
    xlabel=paste0("Time (",result$time_unit,")"),
    ylabel=result$dimension,
    lines=list(
      list(label="fitted mean",xdata=as.numeric(curves$time),
        ydata=as.numeric(curves$mean)),
      list(label=paste0("-",amount," SD"),
        xdata=as.numeric(curves$time),ydata=as.numeric(curves$lower)),
      list(label=paste0("+",amount," SD"),
        xdata=as.numeric(curves$time),ydata=as.numeric(curves$upper))),
    legend=TRUE)
  .etr_su_artist_record("plot_sparse_fpca_component",list(axis),
    source_options=list(component=as.integer(component),
      sd_multiplier=as.numeric(multiplier)))
}

.etr_su_irregular_artist<-function(source,time_unit){
  .etr_assert(is.list(source)&&all(c("curve_ids","time",
    "values","dimension")%in%names(source)),
    "source irregular geometry needs native sample traces")
  n<-length(source$curve_ids)
  .etr_assert(n==length(source$time)&&n==length(source$values)&&
    is.character(source$dimension)&&length(source$dimension)==1L,
    "native irregular source trace groups are incomplete")
  artists<-lapply(seq_len(n),function(i){
    .etr_assert(is.numeric(source$time[[i]])&&
      is.numeric(source$values[[i]])&&
      length(source$time[[i]])==length(source$values[[i]])&&
      all(is.finite(source$time[[i]]))&&
      all(is.finite(source$values[[i]])),
      "irregular scientific artist trace contains nonfinite values")
    list(label=source$curve_ids[[i]],
      xdata=as.numeric(source$time[[i]]),
      ydata=as.numeric(source$values[[i]]),
      marker="o",linewidth=1,alpha=.55)
  })
  axis<-list(
    title=paste0("Native irregular observations: ",source$dimension),
    xlabel=paste0("Time (",time_unit,")"),
    ylabel=source$dimension,
    lines=artists,
    legend=n<=12L)
  .etr_su_artist_record("plot_sparse_irregular_dimension",list(axis),
    source_options=list(dimension=source$dimension,
      n_curves=n))
}
