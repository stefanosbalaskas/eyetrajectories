# Stage 22: eight source-aligned, Python-free descriptive scientific plots.
# Important: graphics device + invisible R data != Matplotlib Axes.
# Consequently these are implementations, NOT 508-source full certifications.
.etr22_table <- function(x,kind,fields) {
  .etr_assert(inherits(x,kind)&&is.data.frame(x$table)&&
    all(fields%in%names(x$table))&&nrow(x$table)>=1L,
    paste("result must be",kind,"with a complete plot table"))
  for(col in fields) .etr_assert(is.numeric(x$table[[col]])&&
    length(x$table[[col]])==nrow(x$table),
    paste("invalid numeric plot column",col))
  x$table
}

#' Plot sample-lag AMI and autocorrelation diagnostics with separate axes
#' @param result Native embedding delay diagnostics.
#' @param ... Further native graphics options.
#' @return Invisible geometry including source time, AMI, ACF and marked minima.
#' @export
etr_plot_embedding_delay_diagnostics <- function(result,...) {
  t<-.etr22_table(result,"etr_embedding_delay_diagnostics",
    c("lag_time","average_mutual_information","autocorrelation"))
  .etr_assert("first_ami_local_minimum"%in%names(t)&&
    is.logical(t$first_ami_local_minimum)&&
    !anyNA(t$first_ami_local_minimum)&&
    all(is.finite(t$lag_time))&&
    all(is.finite(t$average_mutual_information))&&
    all(is.finite(t$autocorrelation)),
    "embedding delay diagnostic table contains invalid values")
  marks<-which(t$first_ami_local_minimum)
  graphics::plot(t$lag_time,t$average_mutual_information,
    type="o",pch=1,xlab=sprintf("Lag (%s)",result$time_unit),
    ylab="Average mutual information",
    main=sprintf("Embedding-delay diagnostics: %s / %s",
      result$curve_id,result$dimension),...)
  if(length(marks))graphics::points(t$lag_time[marks],
    t$average_mutual_information[marks],pch=4,cex=1.5)
  old<-graphics::par(no.readonly=TRUE)
  on.exit(graphics::par(old),add=TRUE)
  graphics::par(new=TRUE)
  graphics::plot(t$lag_time,t$autocorrelation,type="l",lty=2,
    axes=FALSE,xlab="",ylab="")
  graphics::axis(4)
  graphics::mtext("Autocorrelation",side=4,line=2.5)
  invisible(list(time=t$lag_time,ami=t$average_mutual_information,
    autocorrelation=t$autocorrelation,
    first_ami_local_minimum_indices=as.integer(marks-1L)))
}

#' Plot false-nearest-neighbor fractions by embedding dimension
#' @param result Native FNN embedding dimension diagnostics.
#' @param ... Native graphics options.
#' @return Invisibly, the source table used to render the curve.
#' @export
etr_plot_embedding_dimension_diagnostics <- function(result,...) {
  t<-.etr22_table(result,"etr_embedding_dimension_diagnostics",
    c("embedding_dimension","false_neighbor_fraction"))
  .etr_assert(all(is.finite(t$embedding_dimension))&&
    all(t$embedding_dimension>=1)&&
    all(is.finite(t$false_neighbor_fraction))&&
    all(t$false_neighbor_fraction>=0&t$false_neighbor_fraction<=1),
    "false-nearest-neighbor fractions must be finite within [0,1]")
  graphics::plot(t$embedding_dimension,t$false_neighbor_fraction,
    type="o",pch=1,ylim=c(0,max(1e-8,t$false_neighbor_fraction)),
    xlab="Embedding dimension",ylab="False-nearest-neighbor fraction",
    main=sprintf("FNN diagnostics: %s / %s",
      result$curve_id,result$dimension),...)
  invisible(t)
}

#' Plot recurrence network degree in source state-index space
#' @param result Native recurrence network.
#' @param normalized Whether to display normalized rather than raw degree.
#' @param ... Graphics options.
#' @return Invisibly, a zero-based index and degree data.frame.
#' @export
etr_plot_recurrence_network_degree <- function(result,normalized=TRUE,...) {
  .etr_assert(inherits(result,"etr_recurrence_network")&&
    is.numeric(result$degree)&&length(result$degree)>=2L&&
    all(is.finite(result$degree))&&
    is.numeric(result$normalized_degree)&&
    length(result$normalized_degree)==length(result$degree)&&
    all(is.finite(result$normalized_degree)),
    "result must be a valid native recurrence network")
  .etr_assert(is.logical(normalized)&&length(normalized)==1L&&
    !is.na(normalized),"normalized must be TRUE or FALSE")
  out<-data.frame(state_index=seq_along(result$degree)-1L,
    degree=if(normalized)as.numeric(result$normalized_degree)
      else as.numeric(result$degree))
  graphics::plot(out$state_index,out$degree,type="l",
    xlab="State index",ylab=if(normalized)"Normalized degree" else "Degree",
    main=sprintf("Recurrence-network degree (density=%.3f)",
      result$graph_density),...)
  invisible(out)
}

#' Plot exact recurrence rate over analyst-declared radius grid
#' @param result Native recurrence radius profile.
#' @param ... Graphics options.
#' @return Invisibly, the exact source profile table.
#' @export
etr_plot_recurrence_rate_curve <- function(result,...) {
  t<-.etr22_table(result,"etr_recurrence_radius_profile",
    c("radius","recurrence_rate"))
  .etr_assert(all(is.finite(t$radius))&&all(t$radius>=0)&&
    all(is.finite(t$recurrence_rate))&&
    all(t$recurrence_rate>=0&t$recurrence_rate<=1),
    "radius/rate entries must be finite and recurrence rates in [0,1]")
  graphics::plot(t$radius,t$recurrence_rate,type="o",pch=1,
    ylim=c(0,1),xlab=sprintf("Radius (%s state-space distance)",
      result$metric),ylab="Recurrence rate",
    main=sprintf("Recurrence radius profile: %s",result$curve_id),...)
  invisible(t)
}

#' Plot declared windowed RQA metrics over the physical center-time grid
#' @param result Native windowed RQA result.
#' @param metrics Nonempty unique selected metric columns.
#' @param ... Graphics options.
#' @return Invisible data.frame of the original plotted metric values.
#' @export
etr_plot_windowed_rqa <- function(result,
    metrics=c("recurrence_rate","determinism","laminarity"),...) {
  .etr_assert(inherits(result,"etr_windowed_rqa")&&
    is.data.frame(result$table)&&
    "center_time"%in%names(result$table),
    "result must be native windowed RQA")
  .etr_assert(is.character(metrics)&&length(metrics)>=1L&&
    !anyNA(metrics)&&!anyDuplicated(metrics)&&
    all(metrics%in%names(result$table)),
    "metrics must contain distinct existing numeric RQA columns")
  t<-result$table
  .etr_assert(is.numeric(t$center_time)&&
    all(is.finite(t$center_time))&&
    all(vapply(t[metrics],function(x)is.numeric(x)&&
      all(is.finite(x)|is.na(x)),logical(1L))),
    "RQA center times and selected metrics must be numeric")
  v<-as.matrix(t[metrics])
  .etr_assert(any(is.finite(v)),
    "all requested RQA metrics are undefined")
  xr<-range(t$center_time);yr<-range(v[is.finite(v)])
  graphics::plot(NA_real_,NA_real_,xlim=xr,ylim=yr,
    xlab=sprintf("Window center (%s)",result$time_unit),
    ylab="RQA metric",main="Windowed recurrence dynamics",...)
  for(i in seq_along(metrics))
    graphics::lines(t$center_time,v[,i],type="o",pch=i,col=i)
  graphics::legend("topright",legend=metrics,col=seq_along(metrics),
    lty=1,pch=seq_along(metrics),bty="n")
  invisible(t[c("center_time",metrics)])
}

#' Plot Rosenstein/Kantz divergence and optional declared Lyapunov fit
#' @param result Native divergence or fitted Lyapunov output.
#' @param ... Graphics options.
#' @return Invisibly, the original divergence curve and optional fitted values.
#' @export
etr_plot_local_divergence <- function(result,...) {
  fitted<-inherits(result,"etr_largest_lyapunov")
  divergence<-if(fitted)result$divergence else result
  .etr_assert(inherits(divergence,c("etr_local_divergence",
    "etr_kantz_divergence"))&&
    is.numeric(divergence$time_lags)&&
    is.numeric(divergence$mean_log_divergence)&&
    length(divergence$time_lags)==length(
      divergence$mean_log_divergence)&&
    length(divergence$time_lags)>=2L&&
    all(is.finite(divergence$time_lags)),
    "result must contain a native divergence curve")
  t<-divergence$time_lags;y<-divergence$mean_log_divergence
  ok<-is.finite(y)
  .etr_assert(any(ok),"divergence contains no finite log distances")
  out<-data.frame(time_lag=t,mean_log_divergence=y)
  ylim<-range(y[ok])
  fit_y<-rep(NA_real_,length(t))
  if(fitted) {
    mask<-t>=result$fit_start&t<=result$fit_end&ok
    units<-tolower(divergence$time_unit)
    factor<-if(units%in%c("ms","millisecond","milliseconds"))
      1e-3 else 1
    fit_y[mask]<-result$intercept+result$exponent*t[mask]*factor
    if(any(mask))ylim<-range(c(ylim,fit_y[mask]))
  }
  graphics::plot(t,y,type="o",pch=1,ylim=ylim,
    xlab=sprintf("Divergence lag (%s)",divergence$time_unit),
    ylab="Mean log distance",
    main=sprintf("%s: %s",
      divergence$provenance$estimator_family,divergence$curve_id),...)
  if(fitted)graphics::lines(t,fit_y,lty=2)
  graphics::legend("topright",legend=if(fitted)
    c("Mean log divergence",sprintf("LLE fit: %.3g %s",
      result$exponent,result$exponent_unit)) else
    "Mean log divergence",lty=if(fitted)1:2 else 1,bty="n")
  out$fit<-fit_y
  invisible(out)
}

#' Histogram of the IAAFT surrogate statistic and observed marker
#' @param result Native surrogate nonlinearity diagnostic.
#' @param bins Finite integer count (>=2) for R histogram binning.
#' @param ... Graphics options.
#' @return Invisibly, breaks and counts alongside observed statistic.
#' @export
etr_plot_surrogate_nonlinearity <- function(result,bins=20L,...) {
  .etr_assert(inherits(result,"etr_surrogate_nonlinearity")&&
    is.numeric(result$surrogate_statistics)&&
    length(result$surrogate_statistics)>=1L&&
    all(is.finite(result$surrogate_statistics))&&
    is.numeric(result$observed_statistic)&&
    length(result$observed_statistic)==1L&&
    is.finite(result$observed_statistic)&&
    is.finite(result$p_value)&&result$p_value>=0&&result$p_value<=1,
    "result must be a finite native IAAFT nonlinearity diagnostic")
  .etr_assert(is.numeric(bins)&&length(bins)==1L&&
    is.finite(bins)&&bins==as.integer(bins)&&bins>=2L,
    "bins must be an integer >= 2")
  h<-graphics::hist(result$surrogate_statistics,
    breaks=as.integer(bins),plot=FALSE)
  graphics::plot(h,xlab=result$statistic,ylab="Surrogate count",
    main=sprintf("%s surrogate test (p=%.3g)",
      toupper(result$method),result$p_value),...)
  graphics::abline(v=result$observed_statistic,lty=2)
  graphics::legend("topright",legend="Observed",lty=2,bty="n")
  invisible(list(breaks=h$breaks,counts=h$counts,
    observed=result$observed_statistic,
    python_matplotlib_histogram_binning_equivalent=FALSE))
}

#' Plot one-dimensional empirical Poincare return map without projection
#' @param crossings Native one-dimensional Poincare crossing result.
#' @param fit Optional native affine local return-map result.
#' @param ... Graphics options.
#' @return Invisibly, consecutive states and optional fitted affine curve.
#' @export
etr_plot_poincare_return_map <- function(crossings,fit=NULL,...) {
  .etr_assert(inherits(crossings,"etr_poincare_crossings")&&
    is.matrix(crossings$states)&&is.numeric(crossings$states)&&
    ncol(crossings$states)==1L&&nrow(crossings$states)>=2L&&
    all(is.finite(crossings$states)),
    "return-map plot requires >=2 one-dimensional crossings")
  y<-as.numeric(crossings$states)
  out<-data.frame(current=y[-length(y)],next_state=y[-1L])
  lim<-range(c(out$current,out$next_state))
  graphics::plot(out$current,out$next_state,pch=1,
    xlab=sprintf("%s at crossing n",crossings$state_dimensions[1L]),
    ylab=sprintf("%s at crossing n+1",crossings$state_dimensions[1L]),
    main="Empirical Poincare return map",...)
  graphics::abline(a=0,b=1,lty=3)
  if(!is.null(fit)){
    .etr_assert(inherits(fit,"etr_local_return_map")&&
      length(fit$reference_state)==1L&&
      length(fit$intercept)==1L&&is.matrix(fit$jacobian)&&
      identical(dim(fit$jacobian),c(1L,1L))&&
      all(is.finite(c(fit$reference_state,fit$intercept,
        fit$jacobian))),
      "fit must be a compatible one-dimensional native local affine map")
    grid<-seq(lim[1L],lim[2L],length.out=100L)
    predicted<-fit$reference_state[1L]+fit$intercept[1L]+
      fit$jacobian[1L,1L]*(grid-fit$reference_state[1L])
    graphics::lines(grid,predicted,lty=2)
    attr(out,"fit_curve")<-data.frame(x=grid,y=predicted)
  }
  graphics::legend("topleft",
    legend=if(is.null(fit))c("Successive crossings","Identity") else
      c("Successive crossings","Identity","Local affine fit"),
    lty=if(is.null(fit))c(NA,3) else c(NA,3,2),
    pch=if(is.null(fit))c(1,NA) else c(1,NA,NA),bty="n")
  invisible(out)
}
