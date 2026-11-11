# Source: frozen eyetrajectoriespy 1.2.0 simulate.py and
# _functional_simulation.py. Dense common-grid source subdomain.
# Optional native PCG64 follows frozen Python's seeded draw order.
# Finite-variance Student-t curve scores and source missingness preserve
# source masks and complete pre-missing truth.
# NumPy-style cross-channel noise uses an SVD factor of the covariance.

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
#' interpolate or silently replace observations. Power-phase warps are
#' evaluated directly on the generating mean and modes.
#' @param mean Callable evaluating the source mean on a numeric time grid.
#' @param eigenfunctions List of callable source eigenfunctions.
#' @param eigenvalues Strictly positive descending component variances.
#' @param truth_grid Finite, strictly increasing time grid of >=3 points.
#' @param n_participants,trials_per_participant Declared hierarchy counts.
#' @param dimension_names Unique response dimension names.
#' @param coordinate_system,time_unit Source metadata.
#' @param observation_design "dense" (complete common grid) or "irregular"
#'   (curve-specific schedules; no interpolation).
#' @param observation_times Optional explicit list of curve-specific finite
#'   increasing time arrays within truth_grid support; for irregular only.
#' @param samples_per_curve Optional integer count or two-element integer
#'   range for native-generated irregular sampling; mutually exclusive
#'   with observation_times. NULL for dense.
#' @param irregular_time_design "uniform", "center_clustered" or
#'   "boundary_poor" source sampling design for generated irregular grids.
#' @param participant_eigenvalues,trial_eigenvalues Nonnegative source
#'   variance components, default zero.
#' @param measurement_noise_sd Scalar or per-channel Gaussian noise SD.
#' @param measurement_noise_covariance NULL for independent Gaussian noise;
#'   alternatively a finite symmetric positive-semidefinite channel-by-channel
#'   covariance matrix. Cannot be combined with positive noise SD.
#' @param missingness NULL or named list(kind="mcar",probability=p)
#'   or list(kind="block",fraction=f), with finite p/f in [0,1).
#'   Missing samples affect all channels simultaneously, remaining NA.
#' @param phase_variation NULL or list(kind="power",sd=s), with finite
#'   nonnegative log-exponent SD; changes latent evaluation timestamps.
#' @param score_distribution "normal" or "student_t" for curve
#'   functional scores; participant and trial score effects remain Gaussian.
#' @param score_df Student-t degrees of freedom, finite and greater
#'   than two when score_distribution is "student_t". Curve scores are
#'   variance-adjusted so each component retains its declared eigenvalue.
#' @param orthonormal_tolerance Absolute quadrature Gram tolerance.
#' @param random_state Integer seed for the selected random engine.
#' @param source_draws Optional externally retained zero-based source-law
#'   numerical draw arrays (curve_scores, participant_scores,
#'   trial_scores, measurement_noise) for exact fixed-draw comparison.
#'   With declared missingness, optional field missingness_mask
#'   permits frozen Python realized logical-mask replay.
#'   With power phase variation, optional phase_exponents holds one
#'   positive finite source exponent per curve. Irregular
#'   observations use a per-curve list of numeric noise matrices,
#'   each with rows equal to the pre-missing curve schedule.
#' @param random_engine Use "base_R" for legacy native simulation or
#'   "numpy" for native PCG64 source replay. Fixed source draws use base_R.
#' @return Native R observations and fully auditable source-shaped truth;
#'   Python frozen dataclass representation is not claimed.
#' @param python_boundary_mode If TRUE, use the seeded native NumPy PCG64
#'   scientific source stream and return the exact 19-field frozen Python
#'   simulation provenance in observations and truth. The native result
#'   remains an R scientific record, not a Python dataclass.
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
    source_draws=NULL,random_engine="base_R",
    python_boundary_mode=FALSE){
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  random_engine<-match.arg(random_engine,c("base_R","numpy"))
  if(isTRUE(python_boundary_mode)){
    .etr_assert(identical(random_engine,"numpy"),
      "Python source mode requires random_engine='numpy'")
    .etr_assert(is.null(source_draws),
      "Python source mode rejects native-only source_draws replay")
  }
  .etr_assert(identical(random_engine,"base_R")||is.null(source_draws),
    "source_draws must use random_engine='base_R'")
  if(identical(observation_design,"irregular")){
    out<-.etr_functional_simulation_irregular(
      mean=mean,eigenfunctions=eigenfunctions,eigenvalues=eigenvalues,
      truth_grid=truth_grid,n_participants=n_participants,
      trials_per_participant=trials_per_participant,
      dimension_names=dimension_names,coordinate_system=coordinate_system,
      time_unit=time_unit,observation_times=observation_times,
      samples_per_curve=samples_per_curve,
      irregular_time_design=irregular_time_design,
      participant_eigenvalues=participant_eigenvalues,
      trial_eigenvalues=trial_eigenvalues,
      measurement_noise_sd=measurement_noise_sd,
      measurement_noise_covariance=measurement_noise_covariance,
      missingness=missingness,phase_variation=phase_variation,
      score_distribution=score_distribution,score_df=score_df,
      orthonormal_tolerance=orthonormal_tolerance,
      random_state=random_state,source_draws=source_draws,
      random_engine=random_engine)
    if(isTRUE(python_boundary_mode))
      out<-.etr_functional_simulation_python_boundary(out,
        observation_times=observation_times,
        irregular_time_design=irregular_time_design)
    return(out)
  }
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
  phase_spec<-.etr_functional_simulation_phase_spec(phase_variation)
  missing_spec<-.etr_functional_simulation_missingness_spec(missingness)
  score_spec<-.etr_functional_simulation_score_spec(
    score_distribution,score_df)
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
  noise_spec<-.etr_functional_simulation_noise_spec(
    measurement_noise_sd,measurement_noise_covariance,nd)
  noise_sd<-noise_spec$sd
  noise_covariance<-noise_spec$covariance
  seed<-.etr_functional_simulation_seed(random_state,random_engine)
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
  rng<-NULL
  if(identical(random_engine,"numpy")){
    rng<-.etr_numpy_pcg64(seed)
  }else{
    restore<-.etr_simulation_rng(seed)
    on.exit(restore(),add=TRUE)
  }
  if(is.null(source_draws)){
    curve_scores<-.etr_functional_simulation_sample_curve_scores(
      n,eigenvalues,score_spec,rng)
    participant_scores<-.etr_functional_simulation_normal_scores(np,pv,rng)
    trial_scores<-.etr_functional_simulation_normal_scores(n,tv,rng)
    if(is.null(rng)&&is.null(phase_variation)){
      # Preserve the pre-existing no-phase native RNG sequence exactly.
      if(is.null(measurement_noise_covariance)){
        noise<-array(stats::rnorm(n*nt*nd),c(n,nt,nd))
        for(d in seq_len(nd))noise[,,d]<-noise[,,d]*noise_sd[d]
      }else{
        noise<-.etr_functional_simulation_correlated_noise(
          n,nt,nd,noise_spec$sqrt)
      }
    }else noise<-NULL
  }else{
    required_draws<-c("curve_scores","participant_scores",
      "trial_scores","measurement_noise")
    declared_draws<-names(source_draws)
    optional_draws<-c(if(!is.null(missingness))"missingness_mask",
      if(!is.null(phase_variation))"phase_exponents")
    .etr_assert(is.list(source_draws)&&
      !is.null(declared_draws)&&!anyDuplicated(declared_draws)&&
      all(required_draws%in%declared_draws)&&
      all(declared_draws%in%c(required_draws,optional_draws)),
      "source_draws must declare four source components and only declared optional masks or phase exponents")
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
  curve_participants<-participant_scores[pidx,,drop=FALSE]
  scores<-if(is.null(rng))curve_scores+trial_scores+curve_participants else
    curve_scores+curve_participants+trial_scores
  # Python draws phase exponents after scores and before observation noise.
  phase_exponents<-.etr_functional_simulation_phase_draw(
    phase_spec,n,source_draws,rng)
  warp<-matrix(rep(truth_grid,each=n),nrow=n,ncol=nt)
  evaluate_at_warp<-!is.null(phase_variation)||!is.null(rng)
  if(evaluate_at_warp)
    for(i in seq_len(n))
      warp[i,]<-.etr_functional_simulation_power_warp(
        truth_grid,truth_grid,phase_exponents[i])
  masks<-NULL
  if(!is.null(rng)){
    noise_draw<-.etr_functional_simulation_numpy_noise(noise_covariance,rng)
    noise<-array(0,c(n,nt,nd))
    masks<-vector("list",n)
    for(i in seq_len(n)){
      noise[i,,]<-noise_draw(nt)
      masks[[i]]<-.etr_functional_simulation_missingness_draw(nt,missing_spec,rng)
    }
  }else if(is.null(noise)){
    if(is.null(measurement_noise_covariance)){
      noise<-array(stats::rnorm(n*nt*nd),c(n,nt,nd))
      for(d in seq_len(nd))noise[,,d]<-noise[,,d]*noise_sd[d]
    }else noise<-.etr_functional_simulation_correlated_noise(
      n,nt,nd,noise_spec$sqrt)
  }
  latent<-array(0,c(n,nt,nd))
  if(!evaluate_at_warp){
    for(i in seq_len(n))for(d in seq_len(nd))for(t in seq_len(nt))
      latent[i,t,d]<-m[t,d]+sum(scores[i,]*modes[,t,d])
  }else{
    for(i in seq_len(n)){
      wt<-as.numeric(warp[i,])
      current<-.etr_functional_simulation_evaluate(mean,wt,nd,"mean")
      for(j in seq_len(k))
        current<-current+scores[i,j]*
          .etr_functional_simulation_evaluate(
            eigenfunctions[[j]],wt,nd,
            paste0("eigenfunctions[",j-1L,"]"))
      latent[i,,]<-current
    }
  }
  pre_missing_values<-latent+noise
  values<-pre_missing_values
  schedules<-replicate(n,as.numeric(truth_grid),simplify=FALSE)
  if(is.null(masks)){
    masks<-if(!is.null(source_draws)&&"missingness_mask"%in%names(source_draws))
      .etr_functional_simulation_missingness_replay(source_draws$missingness_mask,n,nt) else
      lapply(seq_len(n),function(i)
        .etr_functional_simulation_missingness_draw(nt,missing_spec))
  }
  for(i in seq_len(n))
    if(any(masks[[i]]))values[i,masks[[i]],]<-NA_real_
  as_curves<-function(data)lapply(seq_len(n),function(i)
    matrix(data[i,,,drop=FALSE],nrow=nt,ncol=nd))
  provenance<-list(
    source="simulate_functional_process_core",
    synthetic=TRUE,random_state=seed,
    observation_design="dense",
    raw_dense_to_irregular_interpolation_performed=FALSE,
    measurement_noise_sd=noise_sd,
    measurement_noise_covariance=lapply(seq_len(nd),function(i)
      as.numeric(noise_covariance[i,])),
    participant_eigenvalues=pv,trial_eigenvalues=tv,
    phase_variation_kind=phase_spec$kind,
    missingness_kind=missing_spec$kind,
    score_distribution=score_spec$kind,n_components=k,
    native_random_engine=if(is.null(source_draws))
      .etr_functional_simulation_engine_label(random_engine) else "externally_retained_source_draws",
    full_source_contract_certified=FALSE)
  if(!is.null(missingness))
    provenance["missingness_specification"]<-list(missingness)
  if(!is.null(phase_variation))
    provenance["phase_exponents"]<-list(as.numeric(phase_exponents))
  if(!is.null(rng)){
    provenance$private_0_11_simulation_core<-TRUE
    provenance["irregular_time_design"]<-list(NULL)
    provenance$phase_exponents<-as.numeric(phase_exponents)
    provenance["missingness_specification"]<-list(missingness)
    provenance$score_distribution_parameters<-score_spec
    provenance$truth_grid<-as.numeric(truth_grid)
  }
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
    warped_pre_missing_observation_times=lapply(seq_len(n),
      function(i)as.numeric(warp[i,])),
    observation_times=schedules,
    warped_observation_times=lapply(seq_len(n),
      function(i)as.numeric(warp[i,])),
    latent_at_pre_missing_times=as_curves(latent),
    latent_at_observation_times=as_curves(latent),
    measurement_noise=as_curves(noise),
    measurement_noise_covariance=noise_covariance,
    observed_pre_missing=as_curves(pre_missing_values),
    missingness_mask=masks,metadata=metadata,
    dimension_names=dimension_names,
    coordinate_system=coordinate_system,time_unit=time_unit,
    observation_design="dense",score_distribution=score_spec$kind,
    score_distribution_parameters=score_spec,
    random_state=seed,provenance=provenance)
  result<-structure(list(observations=observations,truth=truth),
    class="etr_functional_simulation_result")
  if(isTRUE(python_boundary_mode))
    result<-.etr_functional_simulation_python_boundary(result,
      irregular_time_design=irregular_time_design)
  result
}
