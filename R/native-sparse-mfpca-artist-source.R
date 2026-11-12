# Source scientific artist *data* for four sparse planar MFPCA plots.
# Frozen Python 1.2 src/eyetrajectoriespy/sparse_multivariate_plotting.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Strict mode returns inspectable source-scientific Matplotlib artist
# GEOMETRY and draws with native R graphics. It does not and cannot return
# actual Python Matplotlib Axes or Figure objects.

.etr_sm_artist_require<-function(result,strict){
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict))
    .etr_assert(inherits(result,c("etr_sparse_mfpca_source",
      "etr_sparse_mfpca_w2_scientific_record")),
      "strict source graphics require a native fitted sparse MFPCA scientific result")
  invisible(TRUE)
}

.etr_sm_artist_record<-function(kind,axes,layout,source_options=list(),
    colorbar=NULL){
  .etr_assert(is.list(axes)&&length(axes)==prod(layout)&&
    all(vapply(axes,is.list,logical(1L))),
    "strict source plot axes must preserve native artist data")
  structure(list(
    source_export=kind,
    renderer="native_R_base_graphics",
    python_return_kind=if(length(axes)==1L)
      "matplotlib.axes.Axes" else "numpy.ndarray[matplotlib.axes.Axes]",
    panel_layout=as.integer(layout),
    axes=axes,
    colorbar=colorbar,
    source_options=source_options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_sparse_mfpca_artist_source_record","list"))
}

.etr_sm_artist_component<-function(result,modes,component,sd_multiplier){
  grid<-as.numeric(result$evaluation_grid)
  .etr_assert(length(modes)==2L&&
    identical(names(modes),as.character(result$dimensions)),
    "strict planar component requires both named coordinate modes")
  index<-as.integer(component)+1L
  fmt<-format(as.numeric(sd_multiplier),trim=TRUE,scientific=FALSE)
  axes<-lapply(seq_along(modes),function(d){
    curves<-modes[[d]]
    .etr_assert(is.data.frame(curves)&&
      identical(names(curves),c("time","mean","upper","lower")),
      "source component curves must have time, mean, upper and lower data")
    list(
      title=paste0(result$dimensions[[d]],": component ",index),
      xlabel=paste0("time (",result$time_unit,")"),
      ylabel=result$dimensions[[d]],
      xdata=grid,
      lines=list(
        list(label="mean",ydata=as.numeric(curves$mean)),
        list(label=paste0("mean + ",fmt," SD mode"),
          ydata=as.numeric(curves$upper)),
        list(label=paste0("mean - ",fmt," SD mode"),
          ydata=as.numeric(curves$lower))),
      legend=identical(d,1L))
  })
  .etr_sm_artist_record("plot_sparse_mfpca_component",
    axes,c(1L,2L),source_options=list(
      component=as.integer(component),
      sd_multiplier=as.numeric(sd_multiplier)))
}

.etr_sm_artist_heatmap<-function(result,blocks,stage,cross=FALSE){
  expected<-if(isTRUE(cross))c("xy","yx") else
    c("xx","xy","yx","yy")
  .etr_assert(identical(names(blocks),expected),
    "strict source heatmaps must preserve directional covariance block order")
  dims<-as.character(result$dimensions)
  .etr_assert(length(dims)==2L,
    "strict directional covariance requires two dimensions")
  names<-if(isTRUE(cross))
    c(paste0(dims[1L],dims[2L]),
      paste0(dims[2L],dims[1L])) else
    c(paste0(dims[1L],dims[1L]),
      paste0(dims[1L],dims[2L]),
      paste0(dims[2L],dims[1L]),
      paste0(dims[2L],dims[2L]))
  g<-as.numeric(result$evaluation_grid)
  vmax<-max(abs(unlist(blocks,use.names=FALSE)))
  if(!is.finite(vmax)||vmax<=0)vmax<-1
  extent<-c(g[[1L]],g[[length(g)]],g[[1L]],g[[length(g)]])
  axes<-lapply(seq_along(blocks),function(i)list(
    title=paste0("$C_{",names[[i]],"}(s,t)$"),
    xlabel=paste0("t (",result$time_unit,")"),
    ylabel=paste0("s (",result$time_unit,")"),
    image=unname(blocks[[i]]),
    image_origin="lower",
    image_aspect="auto",
    extent=extent,
    vmin=-vmax,
    vmax=vmax,
    cmap="coolwarm"))
  label<-if(isTRUE(cross))"cross-covariance" else "covariance"
  .etr_sm_artist_record(
    if(isTRUE(cross))"plot_sparse_mfpca_cross_covariance" else
      "plot_sparse_mfpca_covariance_blocks",
    axes,if(isTRUE(cross))c(1L,2L) else c(2L,2L),
    source_options=list(stage=stage),
    colorbar=list(
      label=label,shrink=.82,vmin=-vmax,vmax=vmax,
      figure_title=paste0(
        if(isTRUE(cross))
          "Sparse MFPCA directional cross-covariance (" else
          "Sparse MFPCA covariance blocks (",stage,")")))
}

.etr_sm_artist_points<-function(x,y){
  .etr_assert(length(x)==length(y)&&all(is.finite(x))&&
    all(is.finite(y)),
    "source scatter points require finite numeric pairs")
  matrix(c(as.numeric(x),as.numeric(y)),ncol=2L)
}

.etr_sm_artist_scores<-function(diagnostics){
  required<-c("n_time_points","condition_number","status_code")
  .etr_assert(is.data.frame(diagnostics)&&
    all(required%in%names(diagnostics)),
    "strict diagnostic source requires paired observations, condition and status")
  x<-as.numeric(diagnostics$n_time_points)
  y<-as.numeric(diagnostics$condition_number)
  ok<-diagnostics$status_code=="ok"
  finite<-is.finite(x)&is.finite(y)
  collections<-list()
  if(any(finite&ok))
    collections[[length(collections)+1L]]<-list(
      label="joint PACE solved",marker="o",
      offsets=.etr_sm_artist_points(x[finite&ok],y[finite&ok]))
  if(any(finite&!ok))
    collections[[length(collections)+1L]]<-list(
      label="flagged solve",marker="x",
      offsets=.etr_sm_artist_points(x[finite&!ok],y[finite&!ok]))
  if(any(!finite))
    collections[[length(collections)+1L]]<-list(
      label="non-finite / failed",marker="x",
      offsets=matrix(numeric(),ncol=2L,nrow=0L))
  axes<-list(list(
    title="Sparse MFPCA joint-PACE score diagnostics",
    xlabel="paired native observations",
    ylabel="conditional-system condition number",
    collections=collections,
    legend=length(collections)>0L,
    n_rows=nrow(diagnostics),
    n_nonfinite=sum(!finite)))
  .etr_sm_artist_record("plot_sparse_mfpca_score_diagnostics",
    axes,c(1L,1L))
}
