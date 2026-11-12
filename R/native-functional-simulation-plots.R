# Three source-grounded native R views of realized Python 1.2 simulation truth.
# Published reference: eyetrajectoriespy 1.2.0 plotting.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Plots use base R, retain exact numeric geometry, never import Python.
# Python Matplotlib Axes and native R geometry are distinct return contracts.

.etr_simulation_plot_index <- function(value,n,ids,kind){
  if(is.character(value)){
    .etr_assert(length(value)==1L&&!is.na(value)&&value%in%ids,
      paste0(kind," must identify an existing name"))
    return(as.integer(match(value,ids)))
  }
  .etr_assert(is.numeric(value)&&length(value)==1L&&is.finite(value)&&
    value==floor(value)&&value>=1&&value<=n,
    paste0(kind," must be a native one-based index or valid name"))
  as.integer(value)
}

#' Native latent-versus-observed functional simulation audit plot
#' @param result Explicit realized source-compatible simulation record.
#' @param curve Native one-based curve index or recorded curve ID.
#' @param dimension Native one-based channel index or declared channel name.
#' @param show_pre_missing Show measurement values removed by design.
#' @param strict_source_record Return source-ordered scientific artist
#'   geometry; numeric curve and dimension become zero-based as in Python.
#'   Strict mode needs a genuinely simulated native result, not a Python Axes.
#' @return Invisibly: numerical line and point geometry and plotted curve ID.
#' @details Native plotting is R graphics, not Python Matplotlib Axes;
#'   the axes return type is an unresolved source-contract difference.
#' @export
etr_plot_functional_simulation_curve <- function(result,curve=1L,
    dimension=1L,show_pre_missing=FALSE,strict_source_record=FALSE){
  .etr_sim_artist_check(result,strict_source_record)
  # Default Python plot selects source curve and coordinate index 0,
  # while legacy native R selects index 1. Explicit caller inputs are
  # not silently altered except for declared strict zero-based indexing.
  if(isTRUE(strict_source_record)){
    if(missing(curve))curve<-0L
    if(missing(dimension))dimension<-0L
  }
  x<-.etr_simulation_audit_fields(result)
  truth<-x$truth;obs<-result$observations
  if(isTRUE(strict_source_record)&&is.numeric(curve)){
    .etr_assert(length(curve)==1L&&is.finite(curve)&&
      curve==floor(curve)&&curve>=0&&curve<x$n,
      "source curve must be a valid zero-based integer")
    curve<-as.integer(curve)+1L
  }
  ci<-.etr_simulation_plot_index(curve,x$n,x$ids,"curve")
  dn<-truth$dimension_names
  .etr_assert(is.character(dn)&&length(dn)>=1L&&
    !anyNA(dn)&&all(nzchar(dn))&&!anyDuplicated(dn),
    "truth dimension_names must be distinct nonempty strings")
  if(isTRUE(strict_source_record)&&is.numeric(dimension)){
    .etr_assert(length(dimension)==1L&&is.finite(dimension)&&
      dimension==floor(dimension)&&dimension>=0&&
      dimension<length(dn),
      "source dimension must be a valid zero-based integer")
    dimension<-as.integer(dimension)+1L
  }
  di<-.etr_simulation_plot_index(dimension,length(dn),dn,"dimension")
  .etr_assert(is.logical(show_pre_missing)&&
    length(show_pre_missing)==1L&&!is.na(show_pre_missing),
    "show_pre_missing must be TRUE or FALSE")
  latent<-truth$latent_on_truth_grid
  .etr_assert(is.array(latent)&&is.numeric(latent)&&
    length(dim(latent))==3L&&
    identical(dim(latent),c(as.integer(x$n),
      as.integer(length(x$grid)),as.integer(length(dn))))&&
    all(is.finite(latent)),
    "truth latent_on_truth_grid must be a complete n-by-time-by-channel array")
  tline<-x$grid;yline<-as.numeric(latent[ci,,di])
  times<-x$times[[ci]]
  vals<-obs$values
  if(is.array(vals)&&length(dim(vals))==3L){
    .etr_assert(dim(vals)[1L]==x$n&&dim(vals)[3L]==length(dn)&&
      dim(vals)[2L]==length(times),
      "dense observed array must match the source schedule and channels")
    observed<-as.numeric(vals[ci,,di])
  }else{
    .etr_assert(is.list(vals)&&length(vals)==x$n&&
      is.matrix(vals[[ci]])&&is.numeric(vals[[ci]])&&
      nrow(vals[[ci]])==length(times)&&
      ncol(vals[[ci]])==length(dn),
      "irregular observed matrix must match the source schedule and channels")
    observed<-as.numeric(vals[[ci]][,di])
  }
  keep<-is.finite(observed)
  removed<-data.frame(time=numeric(),value=numeric())
  if(show_pre_missing){
    .etr_assert(is.list(truth$observed_pre_missing)&&
      length(truth$observed_pre_missing)==x$n&&
      is.matrix(truth$observed_pre_missing[[ci]])&&
      nrow(truth$observed_pre_missing[[ci]])==length(x$pre[[ci]])&&
      ncol(truth$observed_pre_missing[[ci]])==length(dn),
      "truth observed_pre_missing must match the original sample schedule")
    missing<-x$masks[[ci]]
    removed<-data.frame(time=x$pre[[ci]][missing],
      value=as.numeric(truth$observed_pre_missing[[ci]][missing,di]))
  }
  limits<-range(c(yline,observed[keep],removed$value))
  graphics::plot(tline,yline,type="l",xlab=paste0("Time (",truth$time_unit,")"),
    ylab=dn[[di]],main=paste0("Functional simulation truth audit: ",x$ids[[ci]]),
    ylim=if(diff(limits)>0)limits else limits+c(-.5,.5))
  if(any(keep))graphics::points(times[keep],observed[keep],pch=16)
  if(nrow(removed))graphics::points(removed$time,removed$value,pch=4)
  graphics::legend("topleft",
    legend=c("latent truth","observed",
      if(nrow(removed))"removed/missing by design"),
    lty=c(1,NA,if(nrow(removed))NA),
    pch=c(NA,16,if(nrow(removed))4),bty="n")
  geometry<-list(curve_id=x$ids[[ci]],dimension=dn[[di]],
    latent=data.frame(time=tline,value=yline),
    observed=data.frame(time=times[keep],value=observed[keep]),
    removed=removed,
    provenance=list(backend="base_R",
      source_operation="plot_functional_simulation_curve",
      python_axes_return_equivalence=FALSE))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sim_curve_artist(geometry,truth$time_unit,
      show_pre_missing,ci-1L,di-1L)))
  invisible(geometry)
}

#' Native functional simulation phase-warp audit plot
#' @param result Explicit realized simulation record.
#' @param max_curves Positive integer plotted-curve limit or NULL.
#' @param alpha Transparency for observed phase warps.
#' @param strict_source_record Emit source-scientific identity and warp
#'   line-artist data while preserving native base R graphics.
#' @return Invisibly: numerical source-aligned identity and phase-warp lines.
#' @export
etr_plot_functional_simulation_phase_warps <- function(result,
    max_curves=20L,alpha=.35,strict_source_record=FALSE){
  .etr_sim_artist_check(result,strict_source_record)
  x<-.etr_simulation_audit_fields(result)
  if(!is.null(max_curves))
    .etr_assert(is.numeric(max_curves)&&length(max_curves)==1L&&
      is.finite(max_curves)&&max_curves>=1&&max_curves==floor(max_curves),
      "max_curves must be a positive integer or NULL")
  .etr_assert(is.numeric(alpha)&&length(alpha)==1L&&
    is.finite(alpha)&&alpha>0&&alpha<=1,
    "alpha must be within (0, 1]")
  n<-if(is.null(max_curves))x$n else min(x$n,as.integer(max_curves))
  time_unit<-x$truth$time_unit
  .etr_assert(is.character(time_unit)&&length(time_unit)==1L&&
    !is.na(time_unit)&&nzchar(time_unit),"truth must declare time_unit")
  warps<-x$warp[seq_len(n),,drop=FALSE]
  limits<-range(c(x$grid,warps))
  graphics::plot(x$grid,x$grid,type="l",lty=2,
    xlab=paste0("Observed time (",time_unit,")"),
    ylab=paste0("Latent/process time (",time_unit,")"),
    main=paste0("Retained phase warps (n=",n,")"),ylim=limits)
  col<-grDevices::adjustcolor("black",alpha.f=alpha)
  for(i in seq_len(n))graphics::lines(x$grid,warps[i,],col=col)
  graphics::legend("topleft",legend="identity warp",lty=2,bty="n")
  geometry<-list(time=x$grid,identity=x$grid,warps=warps,
    n_plotted=as.integer(n),alpha=alpha,
    provenance=list(backend="base_R",
      source_operation="plot_functional_simulation_phase_warps",
      python_axes_return_equivalence=FALSE))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sim_warps_artist(
      geometry,time_unit,max_curves)))
  invisible(geometry)
}

#' Native declared versus realized simulation score variance audit plot
#' @param result Explicit realized simulation record with retained score sources.
#' @param strict_source_record Return Python-ordered source scientific bar
#'   artist metadata while preserving the actual native population variance.
#' @return Invisibly: all source-aligned population variance bar geometry.
#' @details Realized variance uses population denominator n (NumPy ddof=0),
#'   not R sample variance n-1. R graphics replaces Matplotlib Axes.
#' @export
etr_plot_functional_simulation_score_variances <- function(result,
    strict_source_record=FALSE){
  .etr_sim_artist_check(result,strict_source_record)
  x<-.etr_simulation_audit_fields(result)
  truth<-x$truth;k<-x$k
  participants<-truth$participant_scores
  .etr_assert(is.matrix(participants)&&is.numeric(participants)&&
    ncol(participants)==k&&nrow(participants)>=1L&&
    all(is.finite(participants)),
    "truth participant_scores must be finite participant-by-component scores")
  .etr_assert(is.numeric(truth$participant_eigenvalues)&&
    length(truth$participant_eigenvalues)==k&&
    is.numeric(truth$trial_eigenvalues)&&
    length(truth$trial_eigenvalues)==k&&
    all(is.finite(truth$participant_eigenvalues))&&
    all(is.finite(truth$trial_eigenvalues)),
    "truth participant/trial eigenvalues must match component count")
  variance<-function(scores)
    colMeans((sweep(scores,2L,colMeans(scores),"-"))^2)
  declared<-cbind(truth$eigenvalues,
    truth$participant_eigenvalues,truth$trial_eigenvalues)
  realized<-cbind(variance(truth$curve_scores),
    variance(participants),variance(truth$trial_scores))
  .etr_assert(all(declared>=0),"declared score variances must be nonnegative")
  tags<-c("curve","participant","trial")
  geometry<-vector("list",6L);pos<-0L
  for(j in seq_len(3L))for(kind in c("declared","realized")){
    pos<-pos+1L
    geometry[[pos]]<-data.frame(component_index=seq_len(k)-1L,
      source=tags[[j]],kind=kind,
      variance=if(kind=="declared")declared[,j] else realized[,j],
      center=(seq_len(k)-1L)+
        (if(kind=="declared")j-3.5 else j-.5)*.18,
      width=.18,stringsAsFactors=FALSE)
  }
  bars<-do.call(rbind,geometry);rownames(bars)<-NULL
  ymax<-max(c(0,bars$variance))
  graphics::plot(0,0,type="n",
    xlim=range(c(bars$center-bars$width/2,bars$center+bars$width/2)),
    ylim=c(0,if(ymax>0)ymax*1.05 else 1),
    xaxt="n",xlab="",ylab="Score variance",
    main="Functional simulation score-source variance audit")
  graphics::axis(1,at=seq_len(k)-1L,
    labels=paste("component",seq_len(k)))
  fills<-grDevices::gray.colors(6L,start=.2,end=.85)
  for(j in seq_len(nrow(bars))){
    i<-match(paste(bars$source[j],bars$kind[j]),
      c("curve declared","curve realized",
        "participant declared","participant realized",
        "trial declared","trial realized"))
    graphics::rect(bars$center[j]-bars$width[j]/2,0,
      bars$center[j]+bars$width[j]/2,bars$variance[j],
      col=fills[[i]],border=NA)
  }
  graphics::legend("topright",legend=c(
    "curve declared","participant declared","trial declared",
    "curve realized","participant realized","trial realized"),
    fill=fills[c(1,3,5,2,4,6)],bty="n")
  geometry<-list(geometry=bars,declared=declared,realized=realized,
    provenance=list(backend="base_R",variance_ddof=0L,
      source_operation="plot_functional_simulation_score_variances",
      python_axes_return_equivalence=FALSE))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_sim_variance_artist(geometry)))
  invisible(geometry)
}
