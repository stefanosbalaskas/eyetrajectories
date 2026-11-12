# Frozen public eyetrajectoriespy 1.2.0 elastic.py::fit_elastic_fpca
# source: c1cd95ad718327550f7e55393ff38582872f7a94.
# Python scientific engine: fdasrsf>=2.7, fdacurve.karcher_mean,
# srvf_align, shape_pca.
#
# This opt-in native-R mathematical implementation calls ONLY the
# maintained independent fdasrvf R package (>=2.5.1) implementing true
# SRVF Karcher mean with elastic dynamic-programming reparameterization
# and Karcher tangent-space shape PCA; it does NOT run Python or
# substitute an identity warp. R and Python algorithms have different
# Karcher seed policies (R medoid, Python first sample), aligned curve
# reconstruction and backend identity. Those are explicit open source
# subcontracts, not silently certified as Python fdasrsf parity.

.etr_native_fdasrvf_elastic_source <- function(
    trajectories,n_components,rotation,scale_curves,lam,method) {
  etr_validate(trajectories,require_complete=TRUE)
  shape<-dim(trajectories$values)
  .etr_assert(length(shape)==3L&&shape[3L]>=2L&&
    shape[2L]>=5L&&shape[1L]>=3L,
    "native elastic Karcher source requires >=3 curves, >=5 times and >=2 channels")
  .etr_assert(is.numeric(trajectories$values)&&
    all(is.finite(trajectories$values)),
    "native elastic Karcher source requires complete finite trajectories")
  .etr_assert(is.logical(rotation)&&length(rotation)==1L&&!is.na(rotation),
    "rotation must be one TRUE/FALSE logical value")
  .etr_assert(is.logical(scale_curves)&&length(scale_curves)==1L&&
    !is.na(scale_curves),
    "scale_curves must be one TRUE/FALSE logical value")
  .etr_assert(is.numeric(lam)&&length(lam)==1L&&!is.na(lam)&&
    is.finite(lam)&&lam>=0,
    "native elastic Karcher lambda must be finite and nonnegative")
  .etr_assert(is.character(method)&&length(method)==1L&&
    !is.na(method)&&identical(method,"DP"),
    "native fdasrvf source registration supports method='DP' only; RBFGS is a Python-only algorithm")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==floor(n_components)&&
    n_components>=1L&&n_components<=shape[1L]-1L,
    "native elastic Karcher n_components must be integer in [1,n_curves-1]")
  .etr_assert(requireNamespace("fdasrvf",quietly=TRUE),
    "native elastic Karcher DP requires CRAN R package 'fdasrvf' >= 2.5.1 (no Python)")
  .etr_assert(utils::packageVersion("fdasrvf")>=package_version("2.5.1"),
    "native elastic Karcher DP requires fdasrvf >= 2.5.1")
  n<-as.integer(shape[1L]); nt<-as.integer(shape[2L])
  nd<-as.integer(shape[3L]);k<-as.integer(n_components)
  # fdasrsf and fdasrvf both accept dimension x time x curves.
  beta<-aperm(trajectories$values,c(3L,2L,1L))
  dim(beta)<-c(nd,nt,n)
  # TRUE nonidentity reparameterization via native R fdasrvf Karcher
  # SRVF DP. The R backend computes its own alignment during Karcher
  # fitting; the Python source invokes karcher_mean then srvf_align.
  km<-fdasrvf::multivariate_karcher_mean(
    beta,mode="O",alignment=TRUE,
    rotation=rotation,scale=scale_curves,
    lambda=as.numeric(lam),maxit=20L,
    ms="mean",exact_medoid=FALSE,
    ncores=1L,verbose=FALSE)
  .etr_assert(inherits(km,"fdacurve")&&
    is.array(km$betan)&&identical(dim(km$betan),c(nd,nt,n))&&
    all(is.finite(km$betan)),
    "native fdasrvf Karcher solver did not return finite aligned curves")
  .etr_assert(is.matrix(km$gamma)&&
    identical(dim(km$gamma),c(nt,n))&&
    all(is.finite(km$gamma)),
    "native fdasrvf Karcher solver did not produce time x curves warps")
  .etr_assert(is.matrix(km$betamean)&&
    identical(dim(km$betamean),c(nd,nt))&&
    all(is.finite(km$betamean)),
    "native fdasrvf Karcher mean has invalid channel-by-time geometry")
  .etr_assert(is.array(km$v)&&
    identical(dim(km$v),c(nd,nt,n))&&all(is.finite(km$v)),
    "native fdasrvf Karcher shooting vectors have invalid shape")
  # R fdasrvf 2.5.x multivariate_pca may drop dimensions when no=1;
  # ask for two components and select the first in that one-component
  # boundary case, retaining the same leading tangent eigenspace.
  fit_k<-max(2L,k)
  ci<-seq(-2,2.5,by=.5)
  pca<-fdasrvf::multivariate_pca(km,
    no=fit_k,ci=ci,mode="O",showplot=FALSE)
  .etr_assert(inherits(pca,"curve_pca")&&
    is.matrix(pca$coef)&&
    identical(dim(pca$coef),c(fit_k,n))&&
    is.array(pca$pd)&&is.list(pca$pd)&&
    identical(dim(pca$pd),c(fit_k,length(ci)))&&
    length(pca$latent)>=k,
    "native fdasrvf tangent-space PCA coefficients or geodesic directions invalid")
  # Python obj.coef is component x curves, public wrapper transposes
  # it into curves x component, exactly the same scientific orientation.
  scores<-t(pca$coef[seq_len(k),,drop=FALSE])
  .etr_assert(identical(dim(scores),c(n,k))&&all(is.finite(scores)),
    "native elastic shape PCA produced invalid score matrix")
  principal<-array(NA_real_,c(nd,nt,k,length(ci)))
  for(j in seq_len(k))for(i in seq_along(ci)){
    curve<-pca$pd[j,i][[1L]]
    .etr_assert(is.matrix(curve)&&
      identical(dim(curve),c(nd,nt))&&all(is.finite(curve)),
      "native fdasrvf geodesic principal direction has invalid source geometry")
    principal[,,j,i]<-curve
  }
  # Use the raw returned R native elastic warping functions, not an
  # invented identity mapping or supplied landmark registration.
  gam<-t(km$gamma)
  .etr_assert(identical(dim(gam),c(n,nt))&&
    all(is.finite(gam))&&
    all(gam>=-1e-5 & gam<=1+1e-5),
    "native fdasrvf elastic gamma values outside normalized source unit domain")
  .etr_assert(all(vapply(seq_len(n),function(i)
    all(diff(gam[i,])>=-1e-5),logical(1L))),
    "native fdasrvf elastic warping must be nondecreasing")
  aligned_values<-aperm(km$betan,c(3L,2L,1L))
  dim(aligned_values)<-c(n,nt,nd)
  provenance_note<-list(
    backend="fdasrvf_native_R",
    frozen_python_source_backend="fdasrsf",
    rotation=rotation,scale_curves=scale_curves,
    lam=as.numeric(lam),method=method,
    native_karcher_initialization="SRVF_medoid",
    frozen_python_karcher_initialization="first_curve",
    independent_source_numeric_certification=FALSE,
    exact_python_backend_parity=FALSE)
  aligned<-etr_with_values(
    trajectories,aligned_values,
    provenance_update=list(elastic_registration=provenance_note))
  structure(list(
    aligned=aligned,
    warping_functions=gam,
    scores=scores,
    principal_directions=principal,
    mean_curve=km$betamean,
    backend="native_fdasrvf",
    provenance=list(
      phase_amplitude_separated=TRUE,
      timing_warning=paste(
        "Warping changes traversal timing. Retain and analyze",
        "warping functions when latency is meaningful."),
      registration=provenance_note,
      source_equivalent=FALSE,
      independently_source_certified=FALSE),
    backend_object=NULL,
    native_backend_object=km,
    native_pca_object=pca,
    source_backend="Python_fdasrsf_not_loaded",
    source_python_backend_object_identity=FALSE,
    source_full_numeric_parity_certified=FALSE,
    source_karcher_optimization="native_fdasrvf_Karcher_medoid_DP",
    source_phase_warp_method="true_native_R_elastic_DP_not_identity",
    source_phase_warp_domain=c(0,1),
    source_pca_geodesic_sigma=ci,
    source_pca_eigenvalues=as.numeric(pca$latent[seq_len(k)]),
    source_shooting_vectors=km$v,
    source_aligned_srvfs=km$qn,
    source_original_srvfs=km$q,
    source_karcher_energy=km$E,
    source_karcher_cost=km$qun,
    source_scientific_scope=paste(
      "genuine_R_native_SRVF_elastic_Karcher_DP",
      "amplitude_phase_separation_tangent_covariance_shape_PCA",
      "Python_seed_curve_reconstruction_and_backend_identity_NOT_equal"),
    source_equivalent=FALSE,
    independently_source_certified=FALSE),
    class=c("etr_native_elastic_karcher_pca_scientific_record",
      "etr_native_elastic_fpca_record","list"))
}
