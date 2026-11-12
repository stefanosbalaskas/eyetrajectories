# Historical default: native unregistered square-root velocity FPCA,
# preserving original traversal timing and identity warps.
# New explicit strict_source_record=TRUE method="DP": actual native R
# fdasrvf Karcher dynamic-programming elastic registration and
# geodesic tangent-space shape PCA (independently implemented from
# Python fdasrsf, not exact frozen Python optimizer or backend identity).

#' Fit square-root-velocity FPCA without elastic time registration
#' @param trajectories Complete native planar trajectories.
#' @param n_components Predeclared integer number of velocity components.
#' @param rotation,scale_curves Historical identity-only mode requires
#'   both FALSE. In strict elastic source mode TRUE may request genuine
#'   native R optimal rotation or scale-invariant SRVF registration;
#'   source Python scale-augmented PCA covariance remains uncertified.
#' @param lam Must be zero; no regularized reparameterization fitted.
#' @param method Historical default is `identity_only`. For opt-in
#'   genuine native R elastic registration, explicitly use `method="DP"`
#'   with `strict_source_record=TRUE`. RBFGS source mode is unimplemented.
#' @param strict_source_record FALSE preserves historical unregistered SRVF
#'   alternative unchanged; TRUE uses actual R fdasrvf >=2.5.1 native
#'   Karcher SRVF dynamic-programming elastic alignment and geodesic PCA.
#' @return Native unregistered SRVF FPCA by default. With source mode,
#'   native R elastic Karcher/DP and tangent shape PCA scientific record,
#'   NOT a Python fdasrsf ElasticFPCAResult or Python backend object.
#' @export
etr_fit_elastic_fpca<-function(trajectories,n_components=3L,
    rotation=FALSE,scale_curves=FALSE,lam=0,method="identity_only",
    strict_source_record=FALSE){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be one TRUE/FALSE logical value")
  if(isTRUE(strict_source_record))
    return(.etr_native_fdasrvf_elastic_source(
      trajectories,n_components,rotation,scale_curves,lam,method))
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(length(trajectories$dimension_names)>=2L,
    "square-root velocity FPCA requires at least two planar channels")
  .etr_assert(identical(rotation,FALSE)&&identical(scale_curves,FALSE)&&
    identical(lam,0)&&identical(method,"identity_only"),
    "native R does not implement fdasrsf rotation scaling Karcher elastic DP alignment; use method='identity_only'")
  .etr_assert(is.numeric(n_components)&&
    length(n_components)==1L&&is.finite(n_components)&&
    n_components==floor(n_components)&&n_components>=1L,
    "n_components must be a positive explicit integer")
  n<-length(trajectories$curve_ids);nt<-length(trajectories$time)
  .etr_assert(n_components<=min(n-1L,nt*2L),
    "n_components exceeds centered SRVF rank bound")
  time<-trajectories$time
  raw<-trajectories$values[,,seq_len(2L),drop=FALSE]
  .etr_assert(all(is.finite(raw)),
    "planar trajectories must contain finite complete coordinates")
  velocity<-array(0,c(n,nt,2L))
  for(i in seq_len(n)){
    for(j in 1:2){
      z<-raw[i,,j]
      velocity[i,1L,j]<-(z[2L]-z[1L])/(time[2L]-time[1L])
      velocity[i,nt,j]<-(z[nt]-z[nt-1L])/(time[nt]-time[nt-1L])
      if(nt>2L){
        velocity[i,2:(nt-1L),j]<-(
          z[3:nt]-z[1:(nt-2L)])/
          (time[3:nt]-time[1:(nt-2L)])
      }
    }
  }
  speed<-sqrt(velocity[,,1L]^2+velocity[,,2L]^2)
  denom<-sqrt(speed)
  q<-velocity
  for(j in 1:2){
    q[,,j]<-ifelse(denom>sqrt(.Machine$double.eps),
      velocity[,,j]/pmax(denom,sqrt(.Machine$double.eps)),0)
  }
  names<-trajectories$dimension_names[1:2]
  srvf<-etr_trajectory_set(time,q,
    trajectories$curve_ids,names,
    coordinate_system="unknown",time_unit=trajectories$time_unit)
  fpca<-etr_fit_fpca(srvf,n_components=as.integer(n_components),
    scaling="none")
  warp<-matrix(rep(time,each=n),nrow=n,ncol=nt)
  structure(list(
    aligned=trajectories,warping_functions=warp,
    scores=fpca$scores,principal_directions=fpca$components,
    mean_curve=apply(raw,c(2L,3L),mean),
    sqrt_velocity=q,fpca=fpca,
    backend="native_R_SRVF_unregistered",
    source_backend="fdasrsf_Karcher_DP_not_run",
    phase_amplitude_separated=FALSE,
    timing_warning="Identity warping preserves measured gaze traversal times; elastic phase alignment not performed",
    provenance=list(rotation=FALSE,scale_curves=FALSE,lam=0,
      method="identity_only",
      source_python_equivalent=FALSE,
      source_shape_pca_not_reproduced=TRUE,
      full_source_contract_certified=FALSE)),
    class="etr_unregistered_srvf_fpca")
}
