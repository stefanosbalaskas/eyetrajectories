# Source: frozen eyetrajectoriespy 1.2.0 simulate.py and
# _functional_simulation.py. Dense complete-grid source subdomain only.
# RNG is native R; Python numerical replay uses explicit retained draws.
# No student-t, irregular, phase, missingness or correlated-noise parity.

.etr_functional_simulation_evaluate<-function(fun,time,nd,name){
  .etr_assert(is.function(fun),paste(name,"must be callable"))
  value<-fun(time)
  if(nd==1L&&is.numeric(value)&&is.null(dim(value))&&
    length(value)==length(time))
    value<-matrix(value,ncol=1L)
  .etr_assert(is.matrix(value)&&is.numeric(value)&&
    identical(dim(value),c(length(time),nd))&&
    all(is.finite(value)),
    paste(name,"must return a finite n_time-by-n_dimensions matrix"))
  unname(value)
}

#' Generate dense complete-grid functional trajectories with realized truth
#'
#' @description Native R implementation of a restricted published Python 1.2
#' simulation law. Distinct curve, participant, trial and measurement noise
#' components remain separately available in the truth record. Does not
#' interpolate, warp or silently replace observations.
#' @param mean Callable evaluating the source mean on a numeric time grid.
#' @param eigenfunctions List of callable source eigenfunctions.
#' @param eigenvalues Strictly positive descending component variances.
#' @param truth_grid Finite, strictly increasing time grid of >=3 points.
#' @param n_participants,trials_per_participant Declared hierarchy counts.
#' @param dimension_names Unique response dimension names.
#' @param coordinate_system,time_unit Source metadata.
#' @param observation_design Only "dense" currently supported.
#' @param observation_times,samples_per_curve Must be NULL for dense data.
#' @param irregular_time_design Reserved source option; not used for dense data.
#' @param participant_eigenvalues,trial_eigenvalues Nonnegative source
#'   variance components, default zero.
#' @param measurement_noise_sd Scalar or per-channel Gaussian noise SD.
#' @param measurement_noise_covariance Must be NULL in native subset.
#' @param missingness,phase_variation Must be NULL in native subset.
#' @param score_distribution Only normal currently supported.
#' @param score_df Reserved source option for unsupported Student-t scores.
#' @param orthonormal_tolerance Absolute quadrature Gram tolerance.
#' @param random_state R seed, not NumPy PCG64 seed-equivalent.
#' @param source_draws Optional externally retained zero-based source-law
#'   numerical draw arrays (curve_scores, participant_scores,
#'   trial_scores, measurement_noise) for exact fixed-draw comparison.
#' @return Native R observations and fully auditable source-shaped truth;
#'   Python frozen dataclass representation is not claimed.
#' @export
etr_simulate_functional_process<-function(
    mean,eigenfunctions,eigenvalues,truth_grid,n_participants,
    trials_per_participant=1L,dimension_names="value",
    coordinate_system="unknown",time_unit="normalized",
    observation_design="dense",observation_times=NULL,
    samples_per_curve=NULL,irregular_time_design="uniform",
    participant_eigenvalues=NULL,trial_eigenvalues=NULL,
    measurement_noise_sd=0,measurement_noise_covariance=NULL,
    missingness=NULL,phase_variation=NULL,
    score_distribution="normal",score_df=5,
    orthonormal_tolerance=1e-6,random_state=42L,
    source_draws=NULL){
  np<-.etr_scenario_integer(n_participants,"n_participants",1L)
  trials<-.etr_scenario_integer(trials_per_participant,
    "trials_per_participant",1L)
  .etr_assert(as.double(np)*trials<=.Machine$integer.max,
    "too many source curves")
  .etr_assert(is.numeric(truth_grid)&&is.null(dim(truth_grid))&&
    length(truth_grid)>=3L&&all(is.finite(truth_grid))&&
    all(diff(truth_grid)>0),
    "truth_grid must contain three strictly increasing finite times")
  .etr_assert(is.character(dimension_names)&&length(dimension_names)>0L&&
    !anyNA(dimension_names)&&all(nzchar(dimension_names))&&
    !anyDuplicated(dimension_names),
    "dimension_names must be unique nonempty strings")
  .etr_assert(identical(observation_design,"dense")&&
    is.null(observation_times)&&is.null(samples_per_curve),
    "only dense truth_grid observation schedules are supported")
  .etr_assert(is.null(missingness)&&is.null(phase_variation),
    "native dense source subset requires no missingness or phase variation")
  .etr_assert(is.null(measurement_noise_covariance),
    "correlated measurement noise covariance is not implemented")
  .etr_assert(identical(score_distribution,"normal"),
    "only Gaussian score_distribution is currently implemented")
  .etr_assert(is.numeric(eigenvalues)&&length(eigenvalues)>=1L&&
    all(is.finite(eigenvalues))&&all(eigenvalues>0)&&
    all(diff(eigenvalues)<=0),
    "eigenvalues must be positive finite and nonincreasing")
  k<-length(eigenvalues);nd<-length(dimension_names)
  nt<-length(truth_grid);n<-np*trials
  .etr_assert(is.list(eigenfunctions)&&length(eigenfunctions)==k,
    "eigenfunctions and eigenvalues must contain the same components")
  .etr_assert(is.numeric(orthonormal_tolerance)&&
    length(orthonormal_tolerance)==1L&&
    is.finite(orthonormal_tolerance)&&orthonormal_tolerance>0,
    "orthonormal_tolerance must be positive finite")
  m<-.etr_functional_simulation_evaluate(mean,truth_grid,nd,"mean")
  modes<-array(0,c(k,nt,nd))
  for(j in seq_len(k))
    modes[j,,]<-.etr_functional_simulation_evaluate(
      eigenfunctions[[j]],truth_grid,nd,paste0("eigenfunctions[",j-1L,"]"))
  w<-etr_trapezoid_weights(truth_grid)
  gram<-matrix(0,k,k)
  for(i in seq_len(k))for(j in seq_len(k))
    gram[i,j]<-sum(modes[i,,]*modes[j,,]*
      matrix(w,nrow=nt,ncol=nd))
  .etr_assert(max(abs(gram-diag(k)))<=orthonormal_tolerance,
    "eigenfunctions must be quadrature-orthonormal; no silent normalization")
  pv<-.etr_scenario_variances(participant_eigenvalues,k,
    "participant_eigenvalues")
  tv<-.etr_scenario_variances(trial_eigenvalues,k,"trial_eigenvalues")
  if(is.null(pv))pv<-rep(0,k)
  if(is.null(tv))tv<-rep(0,k)
  if(is.null(measurement_noise_sd))measurement_noise_sd<-0
  .etr_assert(is.numeric(measurement_noise_sd)&&
    length(measurement_noise_sd)%in%c(1L,nd)&&
    all(is.finite(measurement_noise_sd))&&
    all(measurement_noise_sd>=0),
    "measurement_noise_sd must be finite nonnegative scalar or per dimension")
  noise_sd<-rep(as.numeric(measurement_noise_sd),length.out=nd)
  seed<-.etr_scenario_integer(random_state,"random_state",0L)
  pidx<-rep(seq_len(np),each=trials)
  ids<-character(n)
  participant_ids<-character(n)
  trial_ids<-integer(n)
  for(i in seq_len(n)){
    participant_ids[i]<-sprintf("P%03d",pidx[i])
    trial_ids[i]<-as.integer((i-1L)%%trials+1L)
    ids[i]<-sprintf("%s|T%02d",participant_ids[i],trial_ids[i])
  }
  metadata<-data.frame(participant_id=participant_ids,
    trial_id=trial_ids,stringsAsFactors=FALSE)
  restore<-.etr_simulation_rng(seed)
  on.exit(restore(),add=TRUE)
  if(is.null(source_draws)){
    curve_scores<-matrix(stats::rnorm(n*k),n,k)*
      matrix(rep(sqrt(eigenvalues),each=n),n,k)
    participant_scores<-matrix(stats::rnorm(np*k),np,k)*
      matrix(rep(sqrt(pv),each=np),np,k)
    trial_scores<-matrix(stats::rnorm(n*k),n,k)*
      matrix(rep(sqrt(tv),each=n),n,k)
    noise<-array(stats::rnorm(n*nt*nd),c(n,nt,nd))
    for(d in seq_len(nd))noise[,,d]<-noise[,,d]*noise_sd[d]
  }else{
    .etr_assert(is.list(source_draws)&&
      identical(sort(names(source_draws)),sort(c("curve_scores",
        "participant_scores","trial_scores","measurement_noise"))),
      "source_draws must declare exactly four realized source components")
    curve_scores<-source_draws$curve_scores
    participant_scores<-source_draws$participant_scores
    trial_scores<-source_draws$trial_scores
    noise<-source_draws$measurement_noise
    for(field in c("curve_scores","participant_scores","trial_scores")){
      value<-source_draws[[field]]
      shape<-if(field=="participant_scores")c(np,k)else c(n,k)
      .etr_assert(is.matrix(value)&&is.numeric(value)&&
        identical(dim(value),shape)&&all(is.finite(value)),
        paste("source_draws",field,"has incorrect numeric matrix shape"))
    }
    .etr_assert(is.array(noise)&&is.numeric(noise)&&
      identical(dim(noise),c(n,nt,nd))&&all(is.finite(noise)),
      "source_draws measurement_noise must be finite n-by-time-by-channel")
  }
  scores<-curve_scores+trial_scores+
    participant_scores[pidx,,drop=FALSE]
  latent<-array(0,c(n,nt,nd))
  for(i in seq_len(n))for(d in seq_len(nd))for(t in seq_len(nt))
    latent[i,t,d]<-m[t,d]+sum(scores[i,]*modes[,t,d])
  values<-latent+noise
  warp<-matrix(rep(truth_grid,each=n),nrow=n,ncol=nt)
  schedules<-replicate(n,as.numeric(truth_grid),simplify=FALSE)
  masks<-replicate(n,rep(FALSE,nt),simplify=FALSE)
  as_curves<-function(data)lapply(seq_len(n),function(i)
    matrix(data[i,,,drop=FALSE],nrow=nt,ncol=nd))
  provenance<-list(
    source="simulate_functional_process_core",
    synthetic=TRUE,random_state=seed,
    observation_design="dense",
    raw_dense_to_irregular_interpolation_performed=FALSE,
    measurement_noise_sd=noise_sd,
    measurement_noise_covariance=lapply(seq_len(nd),function(i)
      as.numeric(diag(noise_sd^2,nrow=nd,ncol=nd)[i,])),
    participant_eigenvalues=pv,trial_eigenvalues=tv,
    phase_variation_kind="none",missingness_kind="none",
    score_distribution="normal",n_components=k,
    native_random_engine=if(is.null(source_draws))
      "base_R_not_NumPy_PCG64" else "externally_retained_source_draws",
    full_source_contract_certified=FALSE)
  observations<-etr_trajectory_set(truth_grid,values,ids,
    dimension_names,metadata=metadata,
    coordinate_system=coordinate_system,time_unit=time_unit,
    provenance=provenance)
  truth<-list(truth_grid=truth_grid,mean=m,
    eigenfunctions=modes,eigenvalues=as.numeric(eigenvalues),
    scores=scores,curve_scores=curve_scores,
    participant_scores=participant_scores,trial_scores=trial_scores,
    participant_eigenvalues=pv,trial_eigenvalues=tv,
    latent_on_truth_grid=latent,
    phase_warps_on_truth_grid=warp,
    pre_missing_observation_times=schedules,
    warped_pre_missing_observation_times=schedules,
    observation_times=schedules,warped_observation_times=schedules,
    latent_at_pre_missing_times=as_curves(latent),
    latent_at_observation_times=as_curves(latent),
    measurement_noise=as_curves(noise),
    measurement_noise_covariance=diag(noise_sd^2,nrow=nd,ncol=nd),
    observed_pre_missing=as_curves(values),
    missingness_mask=masks,metadata=metadata,
    dimension_names=dimension_names,
    coordinate_system=coordinate_system,time_unit=time_unit,
    observation_design="dense",score_distribution="normal",
    score_distribution_parameters=list(kind="normal"),
    random_state=seed,provenance=provenance)
  structure(list(observations=observations,truth=truth),
    class="etr_functional_simulation_result")
}
