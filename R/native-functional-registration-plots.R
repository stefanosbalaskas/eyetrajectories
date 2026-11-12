# Semantic, unnumbered public plotting API for native functional data.
# Source alignment with published eyetrajectoriespy 1.2 plotting.py.

.etr_validate_registration_plot <- function(result) {
  .etr_assert(inherits(result,"etr_landmark_registration")&&
    inherits(result$original,"etr_trajectory_set")&&
    inherits(result$registered,"etr_trajectory_set")&&
    is.matrix(result$warping_functions)&&
    identical(dim(result$warping_functions),
      c(length(result$original$curve_ids),length(result$original$time)))&&
    identical(result$original$time,result$registered$time)&&
    identical(result$original$curve_ids,result$registered$curve_ids)&&
    identical(result$original$dimension_names,
      result$registered$dimension_names)&&
    all(is.finite(result$warping_functions)),
    "result must contain matching complete native registration trajectories and warps")
  etr_validate(result$original,require_complete=TRUE)
  etr_validate(result$registered,require_complete=TRUE)
  invisible(result)
}

#' Source-aligned functional PCA integrated reconstruction curve
#' @param reconstruction_summary Native FPCA reconstruction summary frame.
#' @param ... Base graphics parameters.
#' @param strict_source_record Return source scientific Matplotlib line
#'   geometry as a native R record, without Python Axes identity.
#' @return Invisible original numeric geometry or strict scientific artist.
#' @export
etr_plot_reconstruction_curve <- function(reconstruction_summary,
    strict_source_record=FALSE,...) {
  .etr_reg_artist_validate_strict(strict_source_record)
  .etr_assert(is.data.frame(reconstruction_summary)&&
    all(c("n_components","mean_integrated_rmse")%in%
      names(reconstruction_summary))&&nrow(reconstruction_summary)>=1L,
    "reconstruction_summary must contain n_components and mean_integrated_rmse")
  x<-reconstruction_summary[["n_components"]]
  y<-reconstruction_summary[["mean_integrated_rmse"]]
  .etr_assert(is.numeric(x)&&is.numeric(y)&&
    all(is.finite(x))&&all(is.finite(y))&&
    all(x>=0)&&all(x==as.integer(x))&&all(y>=0),
    "reconstruction summary source coordinates must be finite")
  graphics::plot(x,y,type="o",pch=1,
    xlab="Retained functional principal components",
    ylab="Mean integrated RMSE",
    main="FPCA reconstruction curve",...)
  frame<-data.frame(n_components=x,mean_integrated_rmse=y)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_reg_reconstruction_artist(frame)))
  invisible(frame)
}

#' Original versus registered native functional curves, in two panels
#' @param result Native landmark-registration object.
#' @param dimension Optional named functional channel.
#' @param max_curves Maximum number of curves drawn in each panel.
#' @param ... Base R graphics options.
#' @param strict_source_record Return original Python two-panel scientific
#'   line geometry, alpha and titles as R data, not Python Figure/Axes.
#' @return Invisible original numerical panels or strict artist record.
#' @export
etr_plot_registration <- function(result,dimension=NULL,max_curves=20L,
    strict_source_record=FALSE,...) {
  .etr_reg_artist_validate_strict(strict_source_record)
  .etr_validate_registration_plot(result)
  if(is.null(dimension))dimension<-result$original$dimension_names[1L]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%result$original$dimension_names,
    "dimension must be one fitted registration channel")
  .etr_assert(is.numeric(max_curves)&&length(max_curves)==1L&&
    !is.logical(max_curves)&&is.finite(max_curves)&&
    max_curves==as.integer(max_curves)&&max_curves>=1L,
    "max_curves must be a positive integer")
  k<-match(dimension,result$original$dimension_names)
  n<-min(as.integer(max_curves),length(result$original$curve_ids))
  make<-function(x) {
    data.frame(curve_id=rep(x$curve_ids[seq_len(n)],
      each=length(x$time)),
      time=rep(x$time,n),
      value=as.vector(t(x$values[seq_len(n),,k,drop=FALSE][,,1L])),
      stringsAsFactors=FALSE)
  }
  original<-make(result$original)
  registered<-make(result$registered)
  ylimits<-range(c(original$value,registered$value))
  before<-graphics::par(no.readonly=TRUE)
  on.exit(graphics::par(before),add=TRUE)
  graphics::par(mfrow=c(1L,2L))
  for(side in c("Original","Registered")){
    z<-if(side=="Original")original else registered
    graphics::plot(NA_real_,NA_real_,
      xlim=range(result$original$time),ylim=ylimits,
      xlab=sprintf("Time (%s)",result$original$time_unit),
      ylab=dimension,main=side,...)
    for(i in seq_len(n)){
      ix<-z$curve_id==result$original$curve_ids[i]
      graphics::lines(z$time[ix],z$value[ix],col=i)
    }
  }
  source<-list(original=original,registered=registered,
    dimension=dimension,curve_ids=result$original$curve_ids[seq_len(n)])
  if(isTRUE(strict_source_record))
    return(invisible(.etr_reg_registration_artist(result,source)))
  invisible(source)
}

#' Native landmark time warping function or displacement plot
#' @param result Native landmark registration output.
#' @param displacement If TRUE plot h(t)-t; otherwise plot source time h(t).
#' @param ... Base R graphics options.
#' @param strict_source_record Return a typed native source-scientific
#'   warp/identity artist with actual line coordinates and alpha.
#' @return Invisible time-by-curve warp geometry or strict artist data.
#' @export
etr_plot_warping_functions <- function(result,displacement=FALSE,
    strict_source_record=FALSE,...) {
  .etr_reg_artist_validate_strict(strict_source_record)
  .etr_validate_registration_plot(result)
  .etr_assert(is.logical(displacement)&&length(displacement)==1L&&
    !is.na(displacement),"displacement must be one logical value")
  time<-result$original$time
  warp<-result$warping_functions
  if(displacement)warp<-sweep(warp,2L,time,"-")
  .etr_assert(all(is.finite(warp)),"warping source values must be finite")
  out<-data.frame(
    curve_id=rep(result$original$curve_ids,each=length(time)),
    time=rep(time,nrow(warp)),
    value=as.vector(t(warp)),
    stringsAsFactors=FALSE)
  graphics::plot(NA_real_,NA_real_,xlim=range(time),
    ylim=range(c(warp,if(displacement)0 else time)),
    xlab=sprintf("Reference time (%s)",result$original$time_unit),
    ylab=if(displacement)"h(t) - t" else "Warped source time",...)
  for(i in seq_len(nrow(warp)))
    graphics::lines(time,warp[i,],col=i)
  if(displacement)graphics::abline(h=0,lty=2)
  else graphics::abline(a=0,b=1,lty=2)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_reg_warp_artist(result,out,displacement)))
  invisible(out)
}
