# Python 1.2.0 sparse graphics equivalents implemented in base R.
# Frozen source: plotting.py and sparse_multivariate_plotting.py, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# These functions return geometry, NOT Matplotlib Axes objects.
# Source selection uses 'source', not historical Python parameter wording.

.etr_sparse_visual_grid <- function(grid) {
  .etr_assert(is.numeric(grid)&&is.null(dim(grid))&&
    length(grid)>=2L&&all(is.finite(grid))&&all(diff(grid)>0),
    "evaluation_grid must contain at least two strictly increasing finite times")
  as.numeric(grid)
}
.etr_sparse_visual_scalar <- function(x,name,positive=FALSE) {
  .etr_assert(is.numeric(x)&&!is.logical(x)&&length(x)==1L&&
    is.finite(x)&&(!positive||x>0),paste(name,"must be a finite",
    if(positive)"positive" else "numeric","scalar"))
  as.numeric(x)
}
.etr_sparse_visual_core <- function(result,multivariate=FALSE) {
  fields<-if(multivariate)
    c("evaluation_grid","mean","eigenfunctions","eigenvalues",
      "n_components","dimensions","time_unit") else
    c("evaluation_grid","mean","covariance","eigenfunctions",
      "eigenvalues","n_components","dimension","time_unit")
  .etr_scientific_frame_fields(result,fields,"sparse scientific result")
  grid<-.etr_sparse_visual_grid(result$evaluation_grid)
  n<-length(grid)
  k<-.etr_source_text_int(result$n_components,"n_components",min=1L)
  .etr_assert(is.numeric(result$eigenvalues)&&
    length(result$eigenvalues)==k&&all(is.finite(result$eigenvalues))&&
    all(result$eigenvalues>=0),
    "eigenvalues must be finite nonnegative components")
  .etr_source_text_word(result$time_unit,"time_unit")
  if(multivariate) {
    .etr_assert(is.character(result$dimensions)&&
      length(result$dimensions)==2L&&
      all(nzchar(result$dimensions))&&!anyDuplicated(result$dimensions),
      "dimensions must declare two unique planar identifiers")
    .etr_assert(is.matrix(result$mean)&&is.numeric(result$mean)&&
      identical(dim(result$mean),c(n,2L))&&
      all(is.finite(result$mean)),
      "mean must contain n_time-by-2 finite numeric values")
    .etr_assert(is.array(result$eigenfunctions)&&
      length(dim(result$eigenfunctions))==3L&&
      identical(dim(result$eigenfunctions),c(k,n,2L))&&
      is.numeric(result$eigenfunctions)&&
      all(is.finite(result$eigenfunctions)),
      "eigenfunctions must contain component-by-time-by-2 finite values")
  } else {
    .etr_source_text_word(result$dimension,"dimension")
    .etr_assert(is.numeric(result$mean)&&is.null(dim(result$mean))&&
      length(result$mean)==n&&all(is.finite(result$mean)),
      "mean must be a finite n_time vector")
    .etr_assert(is.matrix(result$covariance)&&
      identical(dim(result$covariance),c(n,n))&&
      is.numeric(result$covariance)&&
      all(is.finite(result$covariance)),
      "covariance must be a finite n_time square matrix")
    .etr_assert(is.matrix(result$eigenfunctions)&&
      identical(dim(result$eigenfunctions),c(k,n))&&
      is.numeric(result$eigenfunctions)&&
      all(is.finite(result$eigenfunctions)),
      "eigenfunctions must be a finite n_components-by-time matrix")
  }
  list(grid=grid,n=n,k=k)
}
.etr_sparse_visual_component <- function(component,k) {
  .etr_assert(is.numeric(component)&&!is.logical(component)&&
    length(component)==1L&&is.finite(component)&&
    component==floor(component)&&component>=0&&component<k,
    "component must be a zero-based integer inside the fitted range")
  as.integer(component)+1L
}
.etr_sparse_visual_source <- function(source) {
  .etr_assert(is.character(source)&&length(source)==1L&&
    !is.na(source)&&source%in%c("used","smoothed"),
    "source must be 'used' or 'smoothed'")
  source
}
.etr_sparse_visual_blocks <- function(result,source) {
  .etr_scientific_frame_fields(result,
    c("evaluation_grid","dimensions","time_unit"),"result")
  grid<-.etr_sparse_visual_grid(result$evaluation_grid)
  .etr_assert(length(result$dimensions)==2L&&
    is.character(result$dimensions)&&!anyNA(result$dimensions),
    "dimensions must contain two planar identifiers")
  .etr_source_text_word(result$time_unit,"time_unit")
  prefix<-if(identical(source,"used"))"covariance" else "smoothed"
  nm<-paste0(prefix,c("_cxx","_cxy","_cyx","_cyy"))
  .etr_scientific_frame_fields(result,nm,"covariance result")
  blocks<-lapply(nm,function(name)result[[name]])
  for(i in seq_along(blocks))
    .etr_assert(is.matrix(blocks[[i]])&&
      is.numeric(blocks[[i]])&&
      identical(dim(blocks[[i]]),c(length(grid),length(grid)))&&
      all(is.finite(blocks[[i]])),
      paste(nm[[i]],"must be finite n_time square covariance matrix"))
  names(blocks)<-c("xx","xy","yx","yy")
  list(blocks=blocks,grid=grid,dimensions=result$dimensions)
}
.etr_sparse_visual_heatmap <- function(grid,z,label,xlab,ylab,range) {
  # Python imshow(origin='lower') has rows along y, columns along x.
  if(range[1L]==range[2L])
    range<-range+c(-.05,.05)*max(1,abs(range[1L]))
  graphics::image(x=grid,y=grid,z=t(z),xlab=xlab,ylab=ylab,
    main=label,zlim=range,col=grDevices::hcl.colors(64,"Blue-Red 3"))
}

#' Sparse univariate fitted latent covariance image
#' @param result Explicit native univariate sparse FPCA fitted record.
#' @param strict_source_record Return source Matplotlib scientific image
#'   geometry with native R class, without claiming Python Axes identity.
#' @return Invisibly grid and latent covariance, or source artist data.
#' @export
etr_plot_sparse_fpca_covariance <- function(result,
    strict_source_record=FALSE) {
  .etr_su_artist_require(result,strict_source_record,"fit")
  v<-.etr_sparse_visual_core(result)
  grid<-v$grid
  .etr_sparse_visual_heatmap(grid,result$covariance,
    "Sparse FPCA fitted latent covariance",
    paste0("Time s (",result$time_unit,")"),
    paste0("Time t (",result$time_unit,")"),
    range(result$covariance))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_su_covariance_artist(result)))
  invisible(list(grid=grid,covariance=result$covariance))
}

#' Sparse univariate mean and principal-component variation
#' @param result Explicit sparse univariate FPCA fitted record.
#' @param component Zero-based retained principal-component index.
#' @param sd_multiplier Strictly positive scalar standard-deviation multiple.
#' @param strict_source_record Return Python-ordered source line data and
#'   labels as a native R artist record; not Matplotlib Axes identity.
#' @return Invisibly three plotted curves or source artist geometry.
#' @export
etr_plot_sparse_fpca_component <- function(result,component=0L,
    sd_multiplier=2,strict_source_record=FALSE) {
  .etr_su_artist_require(result,strict_source_record,"fit")
  v<-.etr_sparse_visual_core(result)
  i<-.etr_sparse_visual_component(component,v$k)
  m<-.etr_sparse_visual_scalar(sd_multiplier,"sd_multiplier",
    positive=TRUE)
  displacement<-m*sqrt(result$eigenvalues[i])*
    as.numeric(result$eigenfunctions[i,])
  low<-result$mean-displacement
  high<-result$mean+displacement
  graphics::matplot(v$grid,cbind(result$mean,low,high),type="l",
    lty=c(1L,2L,2L),lwd=2,
    xlab=paste0("Time (",result$time_unit,")"),
    ylab=result$dimension,
    main=paste0("Sparse FPC",i,": ",result$dimension,"(t)"))
  graphics::legend("topright",
    legend=c("fitted mean",paste0("-",m," SD"),paste0("+",m," SD")),
    lty=c(1L,2L,2L),bty="n")
  curves<-data.frame(time=v$grid,mean=result$mean,
    lower=low,upper=high)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_su_component_artist(result,curves,
      component,m)))
  invisible(curves)
}

#' Sparse bivariate PACE principal-component perturbations
#' @param result Native sparse bivariate PACE fitted record.
#' @param component Zero-based retained component identifier.
#' @param sd_multiplier Positive standard-deviation multiple.
#' @param strict_source_record Return frozen Python 1.2 Matplotlib
#'   source-scientific artist geometry as a native R record; never Python Axes.
#' @return Invisibly per-dimension mean and perturbation trajectories,
#'   or source-scientific artist geometry in strict mode.
#' @export
etr_plot_sparse_mfpca_component <- function(result,component=0L,
    sd_multiplier=2,strict_source_record=FALSE) {
  .etr_sm_artist_require(result,strict_source_record)
  v<-.etr_sparse_visual_core(result,multivariate=TRUE)
  i<-.etr_sparse_visual_component(component,v$k)
  m<-.etr_sparse_visual_scalar(sd_multiplier,"sd_multiplier",
    positive=TRUE)
  old<-graphics::par(mfrow=c(1L,2L))
  on.exit(graphics::par(old),add=TRUE)
  modes<-lapply(seq_len(2L),function(d){
    center<-result$mean[,d]
    displacement<-m*sqrt(result$eigenvalues[i])*
      result$eigenfunctions[i,,d]
    high<-center+displacement
    low<-center-displacement
    graphics::matplot(v$grid,cbind(center,high,low),type="l",
      lty=c(1L,2L,2L),lwd=2,
      xlab=paste0("time (",result$time_unit,")"),
      ylab=result$dimensions[d],
      main=paste0(result$dimensions[d],": component ",i))
    if(d==1L)
      graphics::legend("topright",
        legend=c("mean",paste0("mean + ",m," SD mode"),
          paste0("mean - ",m," SD mode")),
        lty=c(1L,2L,2L),bty="n",cex=.75)
    data.frame(time=v$grid,mean=center,upper=high,lower=low)
  })
  names(modes)<-result$dimensions
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sm_artist_component(
      result,modes,component,m)))
  invisible(modes)
}

#' Covariance operator blocks from native sparse bivariate FPCA
#' @param result Native sparse multivariate PACE fitted record.
#' @param source Whether to display the used PSD-qualified operator or the
#'   pre-repair smoothed covariance surfaces.
#' @param stage Frozen Python 1.2 stage name, 'used' or 'smoothed'.
#'   If supplied, must agree with an explicitly supplied source value.
#' @param strict_source_record Return native R source-scientific Matplotlib
#'   heatmap geometry with shared signed color limits, not actual Python Axes.
#' @return Invisibly four source-order numeric covariance matrices,
#'   or a source-scientific artist geometry record in strict mode.
#' @export
etr_plot_sparse_mfpca_covariance_blocks <- function(result,
    source="used",stage=NULL,strict_source_record=FALSE) {
  .etr_sm_artist_require(result,strict_source_record)
  if(!is.null(stage)){
    stage<-.etr_sparse_visual_source(stage)
    .etr_assert(missing(source)||identical(source,stage),
      "source and stage must agree when both supplied")
    source<-stage
  }
  source<-.etr_sparse_visual_source(source)
  v<-.etr_sparse_visual_blocks(result,source)
  old<-graphics::par(mfrow=c(2L,2L))
  on.exit(graphics::par(old),add=TRUE)
  ceiling<-max(abs(unlist(v$blocks)))
  if(ceiling==0)ceiling<-1
  titles<-c(paste0("C",v$dimensions[1L],v$dimensions[1L]),
    paste0("C",v$dimensions[1L],v$dimensions[2L]),
    paste0("C",v$dimensions[2L],v$dimensions[1L]),
    paste0("C",v$dimensions[2L],v$dimensions[2L]))
  for(i in seq_len(4L))
    .etr_sparse_visual_heatmap(v$grid,v$blocks[[i]],titles[i],
      paste0("t (",result$time_unit,")"),
      paste0("s (",result$time_unit,")"),
      c(-ceiling,ceiling))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sm_artist_heatmap(
      result,v$blocks,source,cross=FALSE)))
  invisible(v$blocks)
}

#' Directional sparse bivariate cross-covariance surfaces
#' @inheritParams etr_plot_sparse_mfpca_covariance_blocks
#' @return Invisibly the directional xy and yx covariance matrices.
#' @export
etr_plot_sparse_mfpca_cross_covariance <- function(result,
    source="used",stage=NULL,strict_source_record=FALSE) {
  .etr_sm_artist_require(result,strict_source_record)
  if(!is.null(stage)){
    stage<-.etr_sparse_visual_source(stage)
    .etr_assert(missing(source)||identical(source,stage),
      "source and stage must agree when both supplied")
    source<-stage
  }
  source<-.etr_sparse_visual_source(source)
  v<-.etr_sparse_visual_blocks(result,source)
  old<-graphics::par(mfrow=c(1L,2L))
  on.exit(graphics::par(old),add=TRUE)
  blocks<-v$blocks[c("xy","yx")]
  ceiling<-max(abs(unlist(blocks)))
  if(ceiling==0)ceiling<-1
  titles<-c(paste0("C",v$dimensions[1L],v$dimensions[2L]),
    paste0("C",v$dimensions[2L],v$dimensions[1L]))
  for(i in seq_len(2L))
    .etr_sparse_visual_heatmap(v$grid,blocks[[i]],titles[i],
      paste0("t (",result$time_unit,")"),
      paste0("s (",result$time_unit,")"),
      c(-ceiling,ceiling))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sm_artist_heatmap(
      result,blocks,source,cross=TRUE)))
  invisible(blocks)
}

#' Sparse multivariate PACE condition-number diagnostic scatter
#' @param result Native sparse multivariate fit with score diagnostics.
#' @param strict_source_record Return source-scientific finite/flagged and
#'   nonfinite placeholder scatter artist geometry. No Python Axes identity.
#' @return Invisibly finite per-curve diagnostics or strict artist geometry.
#' @export
etr_plot_sparse_mfpca_score_diagnostics <- function(result,
    strict_source_record=FALSE) {
  .etr_sm_artist_require(result,strict_source_record)
  .etr_scientific_frame_fields(result,c("score_diagnostics"),
    "sparse result")
  d<-result$score_diagnostics
  required<-c("n_time_points","condition_number","status_code")
  .etr_assert(is.data.frame(d)&&all(required%in%names(d)),
    "score_diagnostics must include n_time_points, condition_number and status_code")
  .etr_assert(is.numeric(d$n_time_points)&&
    is.numeric(d$condition_number)&&
    is.character(d$status_code)&&
    !anyNA(d$status_code),
    "score_diagnostics requires numeric observations and condition numbers")
  valid<-is.finite(d$n_time_points)&is.finite(d$condition_number)
  solved<-d$status_code=="ok"
  finite<-d[valid,required,drop=FALSE]
  if(nrow(finite)){
    graphics::plot(finite$n_time_points,finite$condition_number,
      type="n",xlab="paired native observations",
      ylab="conditional-system condition number",
      main="Sparse MFPCA joint-PACE score diagnostics")
  }else{
    # Matplotlib plots an empty Axes with an explicit legend placeholder
    # when every conditioning observation is nonfinite/failed.
    graphics::plot(NA_real_,NA_real_,type="n",
      xlim=c(0,1),ylim=c(0,1),
      xlab="paired native observations",
      ylab="conditional-system condition number",
      main="Sparse MFPCA joint-PACE score diagnostics")
  }
  good<-finite$status_code=="ok"
  if(any(good))graphics::points(
    finite$n_time_points[good],finite$condition_number[good],pch=1L)
  if(any(!good))graphics::points(
    finite$n_time_points[!good],finite$condition_number[!good],pch=4L)
  legend<-character();pch<-integer()
  if(any(good)){legend<-c(legend,"joint PACE solved");pch<-c(pch,1L)}
  if(any(!good)){legend<-c(legend,"flagged solve");pch<-c(pch,4L)}
  if(any(!valid)){legend<-c(legend,"non-finite / failed");pch<-c(pch,4L)}
  if(length(legend))graphics::legend("topright",legend=legend,
    pch=pch,bty="n")
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sm_artist_scores(d)))
  invisible(list(finite=finite,nonfinite_count=sum(!valid),
    solved_count=sum(valid&solved)))
}

#' Native irregular samples for a predeclared functional channel
#' @param trajectories Irregular trajectories with per-curve native times.
#' @param dimension A named dimension, not an inferred coordinate.
#' @param strict_source_record Return source line/scatter artist data,
#'   per-curve legend flags and labels, without a Python plotting object.
#' @return Invisibly original IDs, times, values or source artist geometry.
#' @export
etr_plot_sparse_irregular_dimension <- function(trajectories,dimension,
    strict_source_record=FALSE) {
  .etr_su_artist_require(trajectories,strict_source_record,"irregular")
  .etr_scientific_frame_fields(trajectories,
    c("dimension_names","curve_ids","time","values","time_unit"),
    "irregular trajectories")
  dims<-.etr_scientific_frame_ids(trajectories$dimension_names,
    "dimension_names")
  ids<-.etr_scientific_frame_ids(trajectories$curve_ids,"curve_ids")
  name<-.etr_source_text_word(dimension,"dimension")
  .etr_assert(name%in%dims,
    paste("Unknown dimension",name))
  n<-length(ids)
  .etr_assert(is.list(trajectories$time)&&is.list(trajectories$values)&&
    length(trajectories$time)==n&&length(trajectories$values)==n,
    "time and values must contain one native trajectory per curve")
  selected<-match(name,dims)
  times<-vector("list",n)
  values<-vector("list",n)
  for(i in seq_len(n)){
    ti<-trajectories$time[[i]]
    va<-trajectories$values[[i]]
    .etr_assert(is.numeric(ti)&&is.null(dim(ti))&&length(ti)>=2L&&
      all(is.finite(ti))&&all(diff(ti)>0),
      paste("time[",i,"] must be strictly increasing",sep=""))
    .etr_assert(is.matrix(va)&&is.numeric(va)&&
      identical(dim(va),c(length(ti),length(dims)))&&
      all(is.finite(va)),
      paste("values[",i,"] must be finite native-time matrix",sep=""))
    times[[i]]<-ti;values[[i]]<-va[,selected]
  }
  .etr_source_text_word(trajectories$time_unit,"time_unit")
  rngx<-range(unlist(times))
  rngy<-range(unlist(values))
  if(rngy[1L]==rngy[2L])
    rngy<-rngy+c(-.05,.05)*max(1,abs(rngy[1L]))
  graphics::plot(NA_real_,NA_real_,type="n",xlim=rngx,ylim=rngy,
    xlab=paste0("Time (",trajectories$time_unit,")"),
    ylab=name,main=paste0("Native irregular observations: ",name))
  for(i in seq_len(n))
    graphics::lines(times[[i]],values[[i]],type="o",pch=1L)
  if(n<=12L)graphics::legend("topright",legend=ids,
    lty=1L,bty="n",cex=.65)
  source<-list(curve_ids=ids,time=times,
    values=values,dimension=name)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_su_irregular_artist(
      source,trajectories$time_unit)))
  invisible(source)
}
