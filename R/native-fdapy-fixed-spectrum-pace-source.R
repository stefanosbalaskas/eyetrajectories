# Frozen eyetrajectoriespy==1.2.0 sparse.py::fit_sparse_fpca_fdapy
# and FDApy 1.0.x UFPCA internal transform("PACE") deterministic
# fixed-spectral-state score/reconstruction stage (StevenGolovkine/FDApy
# source snapshot 6626ebc6a70a6496f3058c4abb0bb97f5bdb20be).
# NOT an independent reimplementation of FDApy PS/LP covariance fitting:
# source_fit_snapshot explicitly contains frozen already-fitted eigenpairs,
# pooled mean and PRE-CENTERED original irregular observations.
# No Python/reticulate runtime is invoked from this native R function.

.etr_fdapy_spectrum_pinv <- function(x,rcond=1e-15) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&nrow(x)==ncol(x)&&
    all(is.finite(x))&&
    is.numeric(rcond)&&length(rcond)==1L&&is.finite(rcond)&&
    rcond>0,
    "FDApy pooled covariance pseudoinverse requires finite square matrix and positive rcond")
  z<-svd(x)
  # numpy.linalg.pinv uses a fixed 1e-15 relative singular-value cutoff
  # on this real-valued double-precision source path.
  keep<-z$d>max(z$d)*rcond
  if(!any(keep))return(matrix(0,nrow(x),ncol(x)))
  sweep(z$v[,keep,drop=FALSE],2L,z$d[keep],"/")%*%
    t(z$u[,keep,drop=FALSE])
}

.etr_fdapy_source_snapshot_validation <- function(
    trajectories,dimension,n_components,fit_smoothing,score_smoothing,
    tol,normalize,evaluation_grid,kwargs_mean,kwargs_covariance,
    source_fit_snapshot) {
  .etr_assert(inherits(trajectories,"etr_irregular_trajectory_set"),
    "FDApy source snapshot mode requires native irregular trajectories")
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "FDApy source snapshot dimension must name a sampled channel")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    !is.logical(n_components)&&is.finite(n_components)&&
    n_components==floor(n_components)&&n_components>=1L,
    "n_components must be an integer >=1")
  ncurves<-length(trajectories$curve_ids)
  .etr_assert(n_components<=ncurves-1L,
    "n_components cannot exceed the nonzero centered sample rank (n_curves-1)")
  .etr_assert(is.numeric(tol)&&length(tol)==1L&&
    is.finite(tol)&&tol>0,
    "tol must be finite and positive")
  .etr_assert(is.logical(normalize)&&length(normalize)==1L&&
    !is.na(normalize),
    "normalize must be boolean")
  .etr_assert(!normalize,
    "FDApy source fixed-spectrum score mode currently requires normalize=FALSE; source normalization/rescale is not implemented")
  .etr_assert((is.character(fit_smoothing)&&
    length(fit_smoothing)==1L&&!is.na(fit_smoothing)&&
    fit_smoothing%in%c("PS","LP"))||is.null(fit_smoothing),
    "fit_smoothing must be None, 'PS', or 'LP'")
  .etr_assert(is.character(score_smoothing)&&
    length(score_smoothing)==1L&&!is.na(score_smoothing)&&
    score_smoothing%in%c("PS","LP"),
    "score_smoothing must be 'PS' or 'LP'")
  .etr_assert(is.null(kwargs_mean)||is.list(kwargs_mean),
    "kwargs_mean must be mapping/list or NULL")
  .etr_assert(is.null(kwargs_covariance)||is.list(kwargs_covariance),
    "kwargs_covariance must be mapping/list or NULL")
  times<-trajectories$time
  pooled<-sort(unique(unlist(times,use.names=FALSE)))
  .etr_assert(length(pooled)>=2L&&all(is.finite(pooled))&&
    all(diff(pooled)>0),
    "FDApy source pooled observed time grid requires >=2 increasing finite times")
  if(!is.null(evaluation_grid)){
    .etr_assert(is.numeric(evaluation_grid)&&is.null(dim(evaluation_grid))&&
      length(evaluation_grid)>=2L&&all(is.finite(evaluation_grid))&&
      all(diff(evaluation_grid)>0),
      "evaluation_grid must be a finite strictly increasing one-dimensional array")
    .etr_assert(identical(as.numeric(evaluation_grid),as.numeric(pooled)),
      "FDApy irregular PACE evaluation_grid must equal sorted pooled observed times exactly")
  }
  idx<-match(dimension,trajectories$dimension_names)
  .etr_assert(all(vapply(trajectories$values,function(y)
    all(is.finite(y[,idx])),logical(1L))),
    "FDApy source selected channel must be finite and observed")
  .etr_assert(is.list(source_fit_snapshot),
    "source_fit_snapshot must be an independently supplied FDApy fitted eigensystem record; native PS/LP fitting is not implemented")
  needed<-c("mean_grid","eigenfunctions","eigenvalues",
    "noise_variance","centered_observations")
  .etr_assert(all(needed%in%names(source_fit_snapshot)),
    "source_fit_snapshot needs mean_grid eigenfunctions eigenvalues noise_variance centered_observations")
  mean<-source_fit_snapshot$mean_grid
  phi<-source_fit_snapshot$eigenfunctions
  lambda<-source_fit_snapshot$eigenvalues
  noise<-source_fit_snapshot$noise_variance
  centered<-source_fit_snapshot$centered_observations
  m<-length(pooled);k<-as.integer(n_components)
  .etr_assert(is.numeric(mean)&&length(mean)==m&&
    is.null(dim(mean))&&all(is.finite(mean)),
    "FDApy fitted mean_grid must be a finite vector on pooled source grid")
  .etr_assert(is.matrix(phi)&&is.numeric(phi)&&
    identical(dim(phi),c(k,m))&&all(is.finite(phi)),
    "FDApy eigenfunctions must be numeric n_components x pooled_time grid")
  .etr_assert(is.numeric(lambda)&&is.null(dim(lambda))&&
    length(lambda)==k&&all(is.finite(lambda))&&all(lambda>=0),
    "FDApy eigenvalues must be nonnegative finite length n_components")
  .etr_assert(is.numeric(noise)&&length(noise)==1L&&
    is.finite(noise)&&noise>=0,
    "FDApy fitted noise_variance must be nonnegative and finite")
  .etr_assert(is.list(centered)&&length(centered)==ncurves&&
    all(vapply(seq_len(ncurves),function(i)
      is.numeric(centered[[i]])&&is.null(dim(centered[[i]]))&&
      length(centered[[i]])==length(times[[i]])&&
      all(is.finite(centered[[i]])),logical(1L))),
    "centered_observations must preserve every original irregular visit and source-centered value")
  list(grid=as.numeric(pooled),mean=as.numeric(mean),
    eigenfunctions=phi,eigenvalues=as.numeric(lambda),
    noise_variance=as.numeric(noise),
    centered_observations=centered,dimension_idx=idx,
    n_components=k,n_curves=ncurves)
}

.etr_fdapy_fixed_spectrum_pace <- function(
    trajectories,dimension,n_components,fit_smoothing,score_smoothing,
    tol,normalize,evaluation_grid,kwargs_mean,kwargs_covariance,
    source_fit_snapshot) {
  parsed<-.etr_fdapy_source_snapshot_validation(
    trajectories,dimension,n_components,fit_smoothing,score_smoothing,
    tol,normalize,evaluation_grid,kwargs_mean,kwargs_covariance,
    source_fit_snapshot)
  grid<-parsed$grid
  n<-parsed$n_curves;m<-length(grid);k<-parsed$n_components
  centered_grid<-matrix(NA_real_,nrow=n,ncol=m)
  for(i in seq_len(n)) {
    # Actual FDApy 1.0.x UFPCA._transform_pace_irregular calls
    # data.smooth(method="interpolation"), internally using NumPy
    # np.interp on the POOLED irregular observation grid.
    # On both ends np.interp takes the nearest observed endpoint.
    centered_grid[i,]<-stats::approx(
      x=as.numeric(trajectories$time[[i]]),
      y=as.numeric(parsed$centered_observations[[i]]),
      xout=grid,method="linear",rule=2,ties="ordered")$y
  }
  .etr_assert(all(is.finite(centered_grid)),
    "source frozen FDApy PACE interpolation produced invalid values")
  lambda<-parsed$eigenvalues
  phi<-parsed$eigenfunctions
  # FDApy UFPCA after fitting overwrites its covariance with a spectral
  # Mercer reconstruction rather than the initially smoothed raw surface.
  covariance<-t(phi)%*%(lambda*phi)
  effective_noise<-max(as.numeric(tol),parsed$noise_variance)
  sigma<-covariance+diag(effective_noise,m)
  pinv<-.etr_fdapy_spectrum_pinv(sigma,rcond=1e-15)
  scores<-sweep(centered_grid%*%pinv%*%t(phi),2L,lambda,"*")
  reconstructed<-scores%*%phi+
    matrix(rep(parsed$mean,each=n),nrow=n)
  .etr_assert(identical(dim(scores),c(n,k))&&all(is.finite(scores))&&
    identical(dim(reconstructed),c(n,m))&&all(is.finite(reconstructed)),
    "native frozen FDApy fixed-spectrum source result has invalid scores or reconstructed values")
  metadata<-trajectories$metadata
  if(is.null(metadata))metadata<-data.frame(
    row.names=seq_len(n))
  provenance<-trajectories$provenance
  if(is.null(provenance))provenance<-list()
  fit_note<-list(
    backend="FDApy",
    backend_version=if(is.character(source_fit_snapshot$backend_version)&&
      length(source_fit_snapshot$backend_version)==1L)
        source_fit_snapshot$backend_version else NULL,
    dimension=dimension,
    fit_method="covariance",
    fit_smoothing=fit_smoothing,
    score_method="PACE",
    score_smoothing=score_smoothing,
    tolerance=as.numeric(tol),
    normalize=FALSE,
    evaluation_grid=if(is.null(evaluation_grid))NULL else as.numeric(grid),
    kwargs_mean=if(is.null(kwargs_mean))list() else kwargs_mean,
    kwargs_covariance=if(is.null(kwargs_covariance))list() else kwargs_covariance,
    sample_counts=as.integer(lengths(trajectories$time)),
    interpolation_performed=TRUE,
    interpolation_internal_to_FDApy_1_0_x_PACE=TRUE,
    spectral_state_supplied_instead_of_fitted=TRUE)
  provenance$sparse_fpca<-fit_note
  structure(list(
    scores=scores,
    eigenvalues=lambda,
    dimension=dimension,
    curve_ids=trajectories$curve_ids,
    metadata=metadata,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,
    n_components=k,
    fit_method="covariance",
    fit_smoothing=fit_smoothing,
    score_method="PACE",
    score_smoothing=score_smoothing,
    tolerance=as.numeric(tol),
    normalize=FALSE,
    provenance=provenance,
    backend_object=NULL,
    backend_data=NULL,
    reconstructed_backend=NULL,
    source_reconstructed=list(
      grid=grid,
      values=reconstructed,
      source_python_class="FDApy.representation.DenseFunctionalData_not_returned"),
    source_centered_grid=centered_grid,
    source_eigenfunctions=phi,
    source_covariance_spectral=covariance,
    source_noise_floor=effective_noise,
    source_pseudoinverse=pinv,
    source_scientific_scope="known_FDApy_fit_UFPCA_spectrum_PACE_scores_and_inverse_transform",
    fitted_UFPCA_model_natively=FALSE,
    interpolation_performed=TRUE,
    source_backend="FDApy_UFPCA_scientific_PACE_conditional_source",
    source_equivalent=FALSE,
    independently_source_certified=FALSE),
    class=c("etr_fdapy_fixed_spectrum_pace_scientific_record",
      "etr_native_fdapy_pace_record","list"))
}
