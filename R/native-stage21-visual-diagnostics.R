# Stage 21: Python-free descriptive graphics for published Python 1.2
# plotting.py public entrypoints. Graphic backends and return values differ:
# R base graphics does NOT return a matplotlib.axes.Axes object.
# Source contract status: native implementation, not complete parity.

.etr21_plot_count <- function(max_curves,n) {
  if(is.null(max_curves))return(as.integer(n))
  .etr_assert(is.numeric(max_curves) && length(max_curves)==1L &&
    is.finite(max_curves) && max_curves>=1 &&
    max_curves==as.integer(max_curves),
    "max_curves must be a positive integer or NULL")
  as.integer(min(max_curves,n))
}

#' Plot native planar trajectories without Python
#' @param trajectories Native complete trajectory set with >=2 dimensions.
#' @param max_curves Maximum plotted curves, NULL for all.
#' @param alpha Line opacity in (0,1].
#' @param invert_y Reverse the screen-space vertical axis.
#' @param ... Additional base graphics plot options.
#' @return Invisibly, selected curve IDs and plot limits. Unlike the Python
#'   callable, a base R plot is drawn rather than a Matplotlib Axes returned.
#' @export
etr_plot_planar_trajectories <- function(trajectories,max_curves=40L,
    alpha=0.35,invert_y=TRUE,...) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(length(trajectories$dimension_names)>=2L,
    "planar plotting requires at least two dimensions")
  n<-.etr21_plot_count(max_curves,length(trajectories$curve_ids))
  .etr_assert(n>=1L,"no curves available for planar plotting")
  .etr_assert(is.numeric(alpha)&&length(alpha)==1L&&
    is.finite(alpha)&&alpha>0&&alpha<=1,
    "alpha must lie in (0,1]")
  .etr_assert(is.logical(invert_y)&&length(invert_y)==1L&&
    !is.na(invert_y),"invert_y must be TRUE or FALSE")
  a<-trajectories$values[seq_len(n),,1L,drop=FALSE]
  b<-trajectories$values[seq_len(n),,2L,drop=FALSE]
  xlim<-range(a); ylim<-range(b)
  if(invert_y)ylim<-rev(ylim)
  graphics::plot(NA_real_,NA_real_,type="n",xlim=xlim,ylim=ylim,asp=1,
    xlab=trajectories$dimension_names[1L],
    ylab=trajectories$dimension_names[2L],
    main=sprintf("Planar gaze trajectories (n=%d)",n),...)
  for(i in seq_len(n))graphics::lines(trajectories$values[i,,1L],
    trajectories$values[i,,2L],
    col=grDevices::adjustcolor("steelblue",alpha.f=alpha))
  invisible(list(curve_ids=trajectories$curve_ids[seq_len(n)],
    xlim=xlim,ylim=ylim,alpha=alpha,invert_y=invert_y,
    backend="base_R_graphics_not_matplotlib"))
}

#' Draw an FPCA component's mean and plus/minus score-SD profiles
#' @param result Compatible native FPCA fit.
#' @param component Zero-based component index.
#' @param dimension Existing dimension name, or NULL for first channel.
#' @param sd_multiplier Strictly positive score SD multiplier.
#' @param ... Additional base graphics options.
#' @return Invisibly, the three exact curve vectors for audit.
#' @export
etr_plot_fpca_component <- function(result,component=0L,
    dimension=NULL,sd_multiplier=2,...) {
  .etr_fpca_diagnostic_fit(result)
  .etr_assert(is.numeric(component)&&length(component)==1L&&
    is.finite(component)&&component==as.integer(component)&&
    component>=0&&component<result$n_components,
    "component is outside the fitted range")
  if(is.null(dimension))dimension<-result$dimension_names[1L]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%result$dimension_names,
    "dimension is not a fitted functional channel")
  .etr_assert(is.numeric(sd_multiplier)&&length(sd_multiplier)==1L&&
    is.finite(sd_multiplier)&&sd_multiplier>0,
    "sd_multiplier must be positive and finite")
  d<-match(dimension,result$dimension_names)
  curves<-etr_component_trajectories(result,as.integer(component),
    sd_multipliers=c(-sd_multiplier,0,sd_multiplier))
  y<-data.frame(time=result$time,lower=as.numeric(curves[1L,,d]),
    mean=as.numeric(curves[2L,,d]),upper=as.numeric(curves[3L,,d]))
  graphics::plot(y$time,y$mean,type="l",ylim=range(c(y$lower,y$mean,y$upper)),
    xlab=sprintf("Time (%s)",result$time_unit),ylab=dimension,
    main=sprintf("FPC%d: %s(t)",as.integer(component)+1L,dimension),...)
  graphics::lines(y$time,y$lower,lty=2L)
  graphics::lines(y$time,y$upper,lty=3L)
  graphics::legend("topright",legend=c("mean",
    sprintf("-%g SD",sd_multiplier),sprintf("+%g SD",sd_multiplier)),
    lty=1:3,bty="n")
  invisible(y)
}

#' Plot an audited native dynamic time warping alignment
#' @param result Native DTW result generated with return_path=TRUE.
#' @param ... Additional base graphics options.
#' @return Invisibly, the zero-based path used for plotting.
#' @export
etr_plot_dynamic_time_warping_alignment <- function(result,...) {
  .etr_assert(inherits(result,"etr_dtw_result") &&
    is.matrix(result$path)&&ncol(result$path)==2L&&
    nrow(result$path)>=1L&&is.numeric(result$path)&&
    all(is.finite(result$path)),
    "result must be a native DTW result with a valid alignment path")
  p<-result$path
  .etr_assert(all(p==as.integer(p))&&all(p>=0L)&&
    all(p[,1L]<result$n_points_a)&&
    all(p[,2L]<result$n_points_b)&&
    all(p[1L,]==c(0,0))&&
    all(p[nrow(p),]==c(result$n_points_a-1L,
                       result$n_points_b-1L))&&
    (nrow(p)==1L||all(diff(p[,1L])>=0&diff(p[,2L])>=0)),
    "DTW alignment path must be bounded, monotone and endpoint-complete")
  limit<-max(result$n_points_a-1L,result$n_points_b-1L)
  norm<-isTRUE(result$provenance$normalization_requested)
  label<-if(norm)"normalized" else "raw"
  window<-if(is.null(result$window_radius))"unconstrained" else
    sprintf("window=%d",result$window_radius)
  graphics::plot(p[,2L],p[,1L],type="o",pch=1L,
    xlim=c(-.5,max(result$n_points_b-.5,.5)),
    ylim=c(-.5,max(result$n_points_a-.5,.5)),
    xlab="Sequence B sample index",ylab="Sequence A sample index",
    main=sprintf("DTW alignment: %s, %s, %s=%.4g",
      result$step_pattern,window,label,result$distance),...)
  graphics::lines(c(0,limit),c(0,limit),lty=2L)
  graphics::legend("topleft",legend=c("alignment","same index"),
    lty=c(1L,2L),bty="n")
  invisible(p)
}

#' Heatmap of descriptive distance-specification rank agreement
#' @param result Native distance sensitivity output from
#'   etr_trajectory_distance_sensitivity().
#' @param ... Additional base graphics options.
#' @return Invisibly, the symmetric Spearman correlation matrix.
#' @export
etr_plot_trajectory_distance_rank_correlations <- function(result,...) {
  .etr_assert(inherits(result,"etr_trajectory_distance_sensitivity"),
    "result must be a native trajectory distance sensitivity result")
  labels<-result$specification_names
  .etr_assert(is.character(labels)&&length(labels)>=2L&&
    !anyNA(labels)&&!anyDuplicated(labels),
    "specification names must be distinct")
  n<-length(labels)
  comparison<-result$comparison_table
  .etr_assert(is.data.frame(comparison)&&all(c(
    "specification_a","specification_b",
    "spearman_rank_correlation")%in%names(comparison)),
    "comparison table lacks rank-correlation fields")
  m<-diag(1,n);dimnames(m)<-list(labels,labels)
  seen<-matrix(FALSE,n,n)
  for(i in seq_len(nrow(comparison))){
    a<-match(comparison$specification_a[i],labels)
    b<-match(comparison$specification_b[i],labels)
    .etr_assert(!is.na(a)&&!is.na(b)&&a!=b&&!seen[a,b],
      "comparison table has an unknown or duplicate specification pair")
    v<-comparison$spearman_rank_correlation[i]
    .etr_assert(is.numeric(v)&&length(v)==1L&&
      (is.nan(v)||(is.finite(v)&&abs(v)<=1+1e-10)),
      "Spearman rank correlation must be in [-1,1] or NaN")
    m[a,b]<-m[b,a]<-v
    seen[a,b]<-seen[b,a]<-TRUE
  }
  .etr_assert(all(seen[row(seen)!=col(seen)]),
    "comparison table is missing a specification pair")
  graphics::image(seq_len(n),seq_len(n),m,zlim=c(-1,1),
    col=grDevices::colorRampPalette(c("navy","white","firebrick"))(101L),
    xaxt="n",yaxt="n",xlab="",ylab="",
    main="Trajectory-distance rank agreement",...)
  graphics::axis(1L,at=seq_len(n),labels=labels,las=2L)
  graphics::axis(2L,at=seq_len(n),labels=labels,las=2L)
  for(i in seq_len(n))for(j in seq_len(n))
    graphics::text(i,j,if(is.nan(m[i,j]))"nan" else
      sprintf("%.2f",m[i,j]),cex=.7)
  invisible(m)
}
