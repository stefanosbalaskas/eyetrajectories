# Stage 24: nine additional Python-free native descriptive science plots.
# Source names from published eyetrajectoriespy 1.2.0 plotting.py and
# nonlinear_plotting.py; native base R graphics are NOT Matplotlib Axes.

.etr_plot_validate_scalar <- function(x,label) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x),
    paste(label,"must be a finite scalar"))
}
.etr_plot_require_frame <- function(x,cl,cols,field="table") {
  t<-x[[field]]
  .etr_assert(inherits(x,cl)&&is.data.frame(t)&&nrow(t)>0L&&
    all(cols %in% names(t))&&
    all(vapply(t[cols],function(v)is.numeric(v)&&all(is.finite(v)),
      logical(1L))),
    paste("result must contain a complete finite native",cl,"table"))
  t
}

#' Plot bootstrap absolute matched FPCA similarities by retained component
#' @param result Native bootstrap component-stability result.
#' @param ... Base graphics options.
#' @return Invisible source similarity matrix.
#' @export
etr_plot_fpca_stability <- function(result,...) {
  .etr_assert(inherits(result,"etr_fpca_stability")&&
    is.matrix(result$similarities)&&is.numeric(result$similarities)&&
    nrow(result$similarities)>=1L&&ncol(result$similarities)>=1L&&
    all(is.finite(result$similarities))&&
    all(result$similarities>=0&result$similarities<=1)&&
    ncol(result$similarities)==result$reference$n_components,
    "result must be a valid native FPCA stability result")
  k<-ncol(result$similarities)
  graphics::boxplot(as.data.frame(result$similarities),
    names=paste0("FPC",seq_len(k)),ylim=c(0,1.02),
    ylab="Absolute matched functional similarity",
    main=sprintf("FPCA bootstrap stability (%d replicates)",
      nrow(result$similarities)),...)
  invisible(result$similarities)
}

#' Plot one declared leave-one-group-out influence column
#' @param result Native FPCA group influence result.
#' @param metric Numeric summary column to plot.
#' @param ... Base graphics options.
#' @return Invisible group and selected metric data.frame.
#' @export
etr_plot_fpca_influence <- function(result,
    metric="min_abs_component_similarity",...) {
  .etr_assert(inherits(result,"etr_fpca_influence")&&
    is.data.frame(result$summary)&&nrow(result$summary)>0L&&
    "group"%in%names(result$summary),
    "result must be a native leave-one-group-out FPCA influence summary")
  .etr_assert(is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%names(result$summary)&&
    is.numeric(result$summary[[metric]])&&
    all(is.finite(result$summary[[metric]])),
    "metric must identify a complete numeric influence summary column")
  out<-data.frame(group=as.character(result$summary$group),
    value=as.numeric(result$summary[[metric]]))
  graphics::plot(seq_len(nrow(out))-1L,out$value,type="o",pch=1,
    xaxt="n",xlab="Omitted group",ylab=gsub("_"," ",metric),
    main="Leave-one-group-out FPCA influence",...)
  graphics::axis(1,at=seq_len(nrow(out))-1L,labels=out$group,las=2)
  invisible(out)
}

#' Plot FPCA reconstruction robust-z versus score Mahalanobis distance
#' @param result Native score/reconstruction outlier-review result.
#' @param ... Base graphics options.
#' @return Invisible source diagnostic columns and thresholds.
#' @export
etr_plot_fpca_outlier_diagnostics <- function(result,...) {
  t<-.etr_plot_require_frame(result,"etr_fpca_outliers",
    c("reconstruction_robust_z","score_mahalanobis_sq","score_cutoff"),
    field="diagnostics")
  .etr_assert("review_flag"%in%names(t)&&
    is.logical(t$review_flag)&&!anyNA(t$review_flag)&&
    all(t$score_cutoff>=0),
    "outlier diagnostics require valid review flags and score cutoff")
  graphics::plot(t$reconstruction_robust_z,t$score_mahalanobis_sq,
    pch=1,xlab="Reconstruction robust z",
    ylab="Squared Mahalanobis distance in FPC score space",
    main="FPCA trajectory review diagnostics",...)
  threshold<-result$provenance$reconstruction_z_threshold
  if(!is.null(threshold)){
    .etr_plot_validate_scalar(threshold,"reconstruction threshold")
    graphics::abline(v=threshold,lty=2)
  }
  graphics::abline(h=t$score_cutoff[1L],lty=2)
  invisible(t[c("reconstruction_robust_z","score_mahalanobis_sq",
    "score_cutoff","review_flag")])
}

#' Plot mean held-out FPCA reconstruction error and fold-standard errors
#' @param result Native FPCA held-out cross-validation result.
#' @param ... Base graphics options.
#' @return Invisible native CV summary with component counts and standard errors.
#' @export
etr_plot_fpca_cross_validation <- function(result,...) {
  .etr_assert(inherits(result,"etr_fpca_cv"),
    "result must be a native FPCA cross-validation object")
  t<-etr_summarise_fpca_cross_validation(result)
  .etr_assert(is.data.frame(t)&&nrow(t)>0L&&
    all(c("n_components","mean_rmse","se_rmse")%in%names(t))&&
    all(vapply(t[c("n_components","mean_rmse","se_rmse")],
      function(x)is.numeric(x)&&all(is.finite(x)),logical(1L)))&&
    all(t$se_rmse>=0),
    "FPCA held-out RMSE summary must contain finite standard errors")
  yr<-range(c(t$mean_rmse-t$se_rmse,t$mean_rmse+t$se_rmse))
  graphics::plot(t$n_components,t$mean_rmse,type="o",pch=1,
    ylim=yr,xlab="Retained functional principal components",
    ylab="Held-out integrated RMSE",
    main="FPCA reconstruction cross-validation",...)
  graphics::arrows(t$n_components,t$mean_rmse-t$se_rmse,
    t$n_components,t$mean_rmse+t$se_rmse,
    angle=90,code=3,length=.04)
  invisible(t)
}

#' Plot bootstrap FPCA eigenspace stability across replicates
#' @param result Native FPCA subspace stability result.
#' @param metric Declared projector-distance/cosine/angle metric.
#' @param ... Base graphics options.
#' @return Invisible source replicate/value table.
#' @export
etr_plot_fpca_subspace_stability <- function(result,
    metric="normalized_projector_distance",...) {
  .etr_assert(inherits(result,"etr_fpca_subspace_stability")&&
    is.matrix(result$principal_cosines)&&
    is.matrix(result$principal_angles_degrees)&&
    nrow(result$principal_cosines)>=1L&&
    identical(dim(result$principal_cosines),
      dim(result$principal_angles_degrees))&&
    length(result$component_indices)==ncol(result$principal_cosines),
    "result must be native FPCA subspace stability")
  labels<-c("normalized_projector_distance",
    "max_principal_angle_degrees","min_principal_cosine")
  .etr_assert(is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%labels,
    "metric must be normalized_projector_distance, max_principal_angle_degrees, or min_principal_cosine")
  y<-switch(metric,
    normalized_projector_distance=result$normalized_projector_distance,
    max_principal_angle_degrees=apply(result$principal_angles_degrees,
      1L,max),
    min_principal_cosine=apply(result$principal_cosines,1L,min))
  .etr_assert(is.numeric(y)&&length(y)==nrow(result$principal_cosines)&&
    all(is.finite(y)), "subspace stability metric must be finite")
  out<-data.frame(replicate=seq_along(y),value=as.numeric(y))
  graphics::plot(out$replicate,out$value,pch=1,
    xlab="Bootstrap replicate",ylab=gsub("_"," ",metric),
    main=sprintf("FPCA subspace stability: FPC%d-FPC%d",
      result$component_indices[1L]+1L,
      tail(result$component_indices,1L)+1L),...)
  invisible(out)
}

#' Plot complete observed-grid simultaneous functional mean band
#' @param result Native multiplier functional mean band.
#' @param dimension Optional named functional dimension.
#' @param ... Base graphics options.
#' @return Invisible time, mean, lower and upper in native units.
#' @export
etr_plot_functional_mean_band <- function(result,dimension=NULL,...) {
  .etr_assert(inherits(result,"etr_functional_mean_band")&&
    is.numeric(result$time)&&length(result$time)>=2L&&
    all(is.finite(result$time))&&
    is.matrix(result$mean)&&is.matrix(result$lower)&&
    is.matrix(result$upper)&&
    identical(dim(result$mean),dim(result$lower))&&
    identical(dim(result$mean),dim(result$upper))&&
    nrow(result$mean)==length(result$time)&&
    ncol(result$mean)==length(result$dimension_names)&&
    all(is.finite(result$mean))&&
    all(is.finite(result$lower))&&all(is.finite(result$upper))&&
    all(result$lower<=result$upper),
    "result must be a valid finite native functional mean band")
  if(is.null(dimension)) dimension<-result$dimension_names[1L]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%result$dimension_names,
    "dimension must identify an available native mean-band channel")
  j<-match(dimension,result$dimension_names)
  out<-data.frame(time=result$time,mean=result$mean[,j],
    lower=result$lower[,j],upper=result$upper[,j])
  graphics::plot(out$time,out$mean,type="l",
    ylim=range(c(out$lower,out$mean,out$upper)),
    xlab=sprintf("Time (%s)",result$time_unit),ylab=dimension,
    main=sprintf("Functional mean band: %s(t)",dimension),...)
  graphics::polygon(c(out$time,rev(out$time)),
    c(out$lower,rev(out$upper)),
    col=grDevices::adjustcolor("grey70",alpha.f=.3),border=NA)
  graphics::lines(out$time,out$mean,lwd=2)
  invisible(out)
}

#' Plot sparse-index geometry of exact joint recurrence without resampling
#' @param result Native synchronized joint recurrence matrix result.
#' @param max_points Maximum allowed recurrent cell count or NULL.
#' @param ... Base graphics options.
#' @return Invisible zero-based source index pairs.
#' @export
etr_plot_joint_recurrence <- function(result,max_points=200000L,...) {
  .etr_assert(inherits(result,"etr_joint_recurrence")&&
    is.matrix(result$matrix)&&
    nrow(result$matrix)==ncol(result$matrix)&&
    is.logical(result$matrix)&&!anyNA(result$matrix),
    "result must be a native joint recurrence matrix")
  .etr_assert(is.null(max_points)||
    (is.numeric(max_points)&&length(max_points)==1L&&
      !is.logical(max_points)&&is.finite(max_points)&&
      max_points==as.integer(max_points)&&max_points>=1L),
    "max_points must be a positive integer or NULL")
  count<-sum(result$matrix)
  .etr_assert(is.null(max_points)||count<=max_points,
    "joint recurrence matrix exceeds max_points")
  ij<-which(result$matrix,arr.ind=TRUE)
  out<-data.frame(col_index=as.integer(ij[,2L]-1L),
    row_index=as.integer(ij[,1L]-1L))
  n<-nrow(result$matrix)
  graphics::plot(out$col_index,out$row_index,pch=15,cex=.5,
    xlim=c(0,n-1L),ylim=c(n-1L,0),asp=1,
    xlab="State index",ylab="State index",
    main=sprintf("Joint recurrence (JRR=%.3f, components=%d)",
      result$joint_recurrence_rate,length(result$component_labels)),...)
  invisible(out)
}

#' Plot source curves of one declared windowed RQA functional metric
#' @param result Native windowed RQA functional trajectory result.
#' @param metric One metric present in the native functional result.
#' @param show_mean Draw the observed-grid across-curve mean.
#' @param max_curves Optional positive number of curves to plot.
#' @param ... Base graphics options.
#' @return Invisible source time and curve-value geometry.
#' @export
etr_plot_windowed_rqa_trajectories <- function(result,metric,
    show_mean=FALSE,max_curves=NULL,...) {
  .etr_assert(inherits(result,"etr_windowed_rqa_functional")&&
    inherits(result$trajectories,"etr_trajectory_set")&&
    is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%result$metrics,
    "metric must be a native functional windowed RQA dimension")
  .etr_assert(is.logical(show_mean)&&length(show_mean)==1L&&
    !is.na(show_mean),"show_mean must be TRUE or FALSE")
  .etr_assert(is.null(max_curves)||
    (is.numeric(max_curves)&&length(max_curves)==1L&&
      max_curves==as.integer(max_curves)&&is.finite(max_curves)&&
      max_curves>=1L),"max_curves must be positive or NULL")
  x<-result$trajectories
  j<-match(metric,x$dimension_names)
  .etr_assert(!is.na(j)&&length(dim(x$values))==3L,
    "native RQA metric absent from trajectory cube")
  n<-dim(x$values)[1L]
  k<-if(is.null(max_curves))n else min(n,as.integer(max_curves))
  v<-matrix(x$values[seq_len(k),,j,drop=FALSE],nrow=k)
  .etr_assert(any(is.finite(v)),"selected RQA metric is entirely undefined")
  yr<-range(v[is.finite(v)])
  graphics::plot(NA_real_,NA_real_,xlim=range(x$time),
    ylim=yr,xlab=sprintf("Window center (%s)",result$time_unit),
    ylab=metric,main=sprintf("Functional windowed RQA: %s",metric),...)
  for(i in seq_len(k))graphics::lines(x$time,v[i,],col=i)
  all_values<-matrix(x$values[,,j,drop=FALSE],nrow=n)
  mu<-colMeans(all_values,na.rm=TRUE)
  if(show_mean)graphics::lines(x$time,mu,lwd=3)
  invisible(list(time=x$time,curve_values=v,
    across_curve_mean=if(show_mean)mu else NULL))
}

#' Plot one unambiguous predeclared RQA parameter-sensitivity slice
#' @param result Native fixed-grid RQA sensitivity output.
#' @param parameter One source parameter column to vary.
#' @param metric One source RQA summary metric.
#' @param filters Optional list of exact values to hold constant.
#' @param ... Base graphics options.
#' @return Invisible selected parameter and metric table.
#' @export
etr_plot_rqa_sensitivity <- function(result,parameter,metric,
    filters=NULL,...) {
  .etr_assert(inherits(result,"etr_rqa_parameter_sensitivity")&&
    is.data.frame(result$table)&&
    is.character(parameter)&&length(parameter)==1L&&
    !is.na(parameter)&&parameter%in%result$parameter_columns&&
    is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%result$metric_columns,
    "parameter and metric must be native RQA sensitivity columns")
  t<-result$table
  if(!is.null(filters)){
    .etr_assert(is.list(filters)&&!is.null(names(filters))&&
      all(names(filters)%in%result$parameter_columns)&&
      !anyDuplicated(names(filters))&&
      !parameter%in%names(filters),
      "filters must be named independent declared RQA parameters")
    for(nm in names(filters)){
      .etr_assert(length(filters[[nm]])==1L,
        "each RQA sensitivity filter must be scalar")
      t<-t[!is.na(t[[nm]])&t[[nm]]==filters[[nm]],,drop=FALSE]
    }
  }
  other<-setdiff(result$parameter_columns,parameter)
  varying<-other[vapply(t[other],function(z)length(unique(z))>1L,
    logical(1L))]
  .etr_assert(!length(varying)&&nrow(t)>=1L&&
    is.numeric(t[[parameter]])&&is.numeric(t[[metric]])&&
    all(is.finite(t[[parameter]]))&&all(is.finite(t[[metric]])),
    "RQA parameter slice must fix other varying parameters and be finite")
  t<-t[order(t[[parameter]]),,drop=FALSE]
  graphics::plot(t[[parameter]],t[[metric]],type="o",pch=1,
    xlab=parameter,ylab=metric,
    main=sprintf("RQA parameter sensitivity: %s",result$curve_id),...)
  invisible(t[c(parameter,metric)])
}
