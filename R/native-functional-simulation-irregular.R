# Frozen Python 1.2: _functional_simulation.py::simulate_functional_process_core
# and _sample_irregular_times, _validate_explicit_observation_times.
# Pinned source c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R directly evaluates functions at each observed time.
# No interpolation, latent-grid resampling or Python runtime.

.etr_functional_simulation_irregular_schedules <- function(
    observation_times,samples_per_curve,design,grid,n) {
  .etr_assert(!( !is.null(observation_times) &&
    !is.null(samples_per_curve)),
    "for irregular simulation, specify observation_times or samples_per_curve, not both")
  if(!is.null(observation_times)) {
    .etr_assert(is.list(observation_times)&&length(observation_times)==n,
      "observation_times must contain exactly one time array per curve")
    schedules<-lapply(seq_len(n),function(i) {
      time<-observation_times[[i]]
      .etr_assert(is.numeric(time)&&is.null(dim(time))&&
        length(time)>=2L&&all(is.finite(time))&&
        all(diff(time)>0),
        paste0("observation_times[",i-1L,
          "] must be finite, strictly increasing, and contain at least two samples"))
      .etr_assert(time[1L]>=grid[1L]&&
        time[length(time)]<=grid[length(grid)],
        paste0("observation_times[",i-1L,
          "] lies outside truth_grid support"))
      as.numeric(time)
    })
    return(list(schedules=schedules,kind=NULL))
  }
  .etr_assert(!is.null(samples_per_curve),
    "irregular observation_design requires observation_times or samples_per_curve")
  .etr_assert(is.character(design)&&length(design)==1L&&
    !is.na(design)&&design%in%c("uniform","center_clustered","boundary_poor"),
    "irregular_time_design must be uniform, center_clustered or boundary_poor")
  .etr_assert(is.numeric(samples_per_curve)&&
    !is.logical(samples_per_curve)&&is.null(dim(samples_per_curve))&&
    length(samples_per_curve)%in%c(1L,2L)&&
    all(is.finite(samples_per_curve))&&
    all(samples_per_curve==floor(samples_per_curve))&&
    all(samples_per_curve>=2L)&&
    all(samples_per_curve<=.Machine$integer.max),
    "samples_per_curve must be an integer >=2 or (minimum, maximum) integer pair")
  lower<-as.integer(samples_per_curve[1L])
  upper<-as.integer(samples_per_curve[length(samples_per_curve)])
  .etr_assert(upper>=lower,
    "sample-count bounds must satisfy 2 <= minimum <= maximum")
  counts<-if(lower==upper)rep.int(lower,n) else
    as.integer(sample.int(upper-lower+1L,n,replace=TRUE)+lower-1L)
  times<-lapply(counts,function(count) {
    if(count==2L)return(c(grid[1L],grid[length(grid)]))
    size<-count-2L
    unit<-switch(design,
      uniform=stats::runif(size,.01,.99),
      center_clustered=.01+.98*stats::rbeta(size,4,4),
      boundary_poor=stats::runif(size,.15,.85))
    c(grid[1L],
      grid[1L]+(grid[length(grid)]-grid[1L])*sort(unit),
      grid[length(grid)])
  })
  list(schedules=times,kind=design)
}

.etr_functional_simulation_irregular <- function(
    mean,eigenfunctions,eigenvalues,truth_grid,n_participants,
    trials_per_participant,dimension_names,coordinate_system,time_unit,
    observation_times,samples_per_curve,irregular_time_design,
    participant_eigenvalues,trial_eigenvalues,measurement_noise_sd,
    measurement_noise_covariance,missingness,phase_variation,
    score_distribution,score_df,orthonormal_tolerance,random_state,
    source_draws) {
  np<-.etr_scenario_integer(n_participants,"n_participants",1L)
  trials<-.etr_scenario_integer(trials_per_participant,
    "trials_per_participant",1L)
  .etr_assert(as.double(np)*trials<=.Machine$integer.max,
    "too many source curves")
  .etr_assert(is.numeric(truth_grid)&&is.null(dim(truth_grid))&&
    length(truth_grid)>=3L&&all(is.finite(truth_grid))&&
    all(diff(truth_grid)>0),
    "truth_grid must contain three strictly increasing finite times")
  .etr_assert(is.character(dimension_names)&&
    length(dimension_names)>=1L&&!anyNA(dimension_names)&&
    all(nzchar(dimension_names))&&!anyDuplicated(dimension_names),
    "dimension_names must be unique nonempty strings")
  .etr_assert(is.null(phase_variation),
    "irregular native source subset requires no phase variation")
  .etr_assert(identical(score_distribution,"normal"),
    "only Gaussian score_distribution is currently implemented")
  .etr_assert(is.numeric(eigenvalues)&&length(eigenvalues)>=1L&&
    all(is.finite(eigenvalues))&&all(eigenvalues>0)&&
    all(diff(eigenvalues)<=0),
    "eigenvalues must be positive finite and nonincreasing")
  k<-length(eigenvalues)
  nd<-length(dimension_names)
  nt<-length(truth_grid)
  n<-np*trials
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
      eigenfunctions[[j]],truth_grid,nd,
      paste0("eigenfunctions[",j-1L,"]"))
  weights<-etr_trapezoid_weights(truth_grid)
  gram<-matrix(0,k,k)
  for(i in seq_len(k))for(j in seq_len(k))
    gram[i,j]<-sum(modes[i,,]*modes[j,,]*
      matrix(weights,nrow=nt,ncol=nd))
  .etr_assert(max(abs(gram-diag(k)))<=orthonormal_tolerance,
    "eigenfunctions must be quadrature-orthonormal; no silent normalization")
  pv<-.etr_scenario_variances(participant_eigenvalues,k,
    "participant_eigenvalues")
  tv<-.etr_scenario_variances(trial_eigenvalues,k,
    "trial_eigenvalues")
  if(is.null(pv))pv<-rep(0,k)
  if(is.null(tv))tv<-rep(0,k)
  noise_spec<-.etr_functional_simulation_noise_spec(
    measurement_noise_sd,measurement_noise_covariance,nd)
  noise_sd<-noise_spec$sd
  noise_covariance<-noise_spec$covariance
  missing_spec<-.etr_functional_simulation_missingness_spec(missingness)
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
  }else{
    required<-c("curve_scores","participant_scores",
      "trial_scores","measurement_noise")
    fields<-names(source_draws)
    .etr_assert(is.list(source_draws)&&!is.null(fields)&&
      !anyDuplicated(fields)&&
      (identical(sort(fields),sort(required))||
       (!is.null(missingness)&&identical(sort(fields),
         sort(c(required,"missingness_mask"))))),
      "source_draws must contain four source components and optionally missingness_mask")
    curve_scores<-source_draws$curve_scores
    participant_scores<-source_draws$participant_scores
    trial_scores<-source_draws$trial_scores
    for(field in c("curve_scores","participant_scores","trial_scores")){
      value<-source_draws[[field]]
      shape<-if(field=="participant_scores")c(np,k)else c(n,k)
      .etr_assert(is.matrix(value)&&is.numeric(value)&&
        identical(dim(value),shape)&&all(is.finite(value)),
        paste("source_draws",field,"must have finite source matrix geometry"))
    }
  }
  scores<-curve_scores+trial_scores+
    participant_scores[pidx,,drop=FALSE]
  # Schedules are generated AFTER score draws, exactly as the frozen
  # source call order, but base-R random numbers are not NumPy PCG64.
  sampling<-.etr_functional_simulation_irregular_schedules(
    observation_times,samples_per_curve,irregular_time_design,
    truth_grid,n)
  schedules<-sampling$schedules
  if(!is.null(source_draws)){
    if("missingness_mask"%in%names(source_draws))
      .etr_assert(is.list(source_draws$missingness_mask)&&
        length(source_draws$missingness_mask)==n,
        "source_draws missingness_mask must contain one vector per irregular curve")
    .etr_assert(is.list(source_draws$measurement_noise)&&
      length(source_draws$measurement_noise)==n,
      "source_draws measurement_noise must contain one matrix per irregular curve")
    for(i in seq_len(n))
      .etr_assert(is.matrix(source_draws$measurement_noise[[i]])&&
        is.numeric(source_draws$measurement_noise[[i]])&&
        identical(dim(source_draws$measurement_noise[[i]]),
          c(length(schedules[[i]]),nd))&&
        all(is.finite(source_draws$measurement_noise[[i]])),
        "source_draws measurement_noise must match each irregular schedule")
  }

  evaluate_curve<-function(time,curve) {
    value<-.etr_functional_simulation_evaluate(mean,time,nd,"mean")
    for(j in seq_len(k))
      value<-value+scores[curve,j]*
        .etr_functional_simulation_evaluate(
          eigenfunctions[[j]],time,nd,
          paste0("eigenfunctions[",j-1L,"]"))
    value
  }
  latent_grid<-array(0,c(n,nt,nd))
  for(i in seq_len(n))
    latent_grid[i,,]<-evaluate_curve(truth_grid,i)
  warped_grid<-matrix(rep(truth_grid,each=n),nrow=n,ncol=nt)
  pre_missing_times<-schedules
  masks<-vector("list",n)
  noise<-vector("list",n)
  pre_latent<-vector("list",n)
  pre_observed<-vector("list",n)
  output_times<-vector("list",n)
  output_latent<-vector("list",n)
  output_values<-vector("list",n)
  for(i in seq_len(n)) {
    time<-schedules[[i]]
    pre_latent[[i]]<-evaluate_curve(time,i)
    nt_curve<-length(time)
    if(is.null(source_draws)) {
      if(all(abs(noise_covariance)<=1e-8)){
        noise[[i]]<-matrix(0,nt_curve,nd)
      }else if(is.null(measurement_noise_covariance)){
        raw<-matrix(stats::rnorm(nt_curve*nd),nt_curve,nd)
        noise[[i]]<-sweep(raw,2L,noise_sd,"*")
      }else{
        raw<-matrix(stats::rnorm(nt_curve*nd),nt_curve,nd)
        noise[[i]]<-raw%*%noise_spec$sqrt
      }
    }else noise[[i]]<-source_draws$measurement_noise[[i]]
    pre_observed[[i]]<-pre_latent[[i]]+noise[[i]]
    if(!is.null(source_draws)&&
       "missingness_mask"%in%names(source_draws)){
      mask<-source_draws$missingness_mask[[i]]
      .etr_assert(is.logical(mask)&&is.null(dim(mask))&&
        length(mask)==nt_curve&&!anyNA(mask),
        "source_draws missingness_mask must match each irregular schedule")
    }else mask<-.etr_functional_simulation_missingness_draw(
      nt_curve,missing_spec)
    masks[[i]]<-mask
    keep<-!mask
    .etr_assert(sum(keep)>=2L,
      paste0("missingness left fewer than two irregular observations for curve ",
        i-1L,"; the simulator does not silently resample"))
    output_times[[i]]<-time[keep]
    output_latent[[i]]<-pre_latent[[i]][keep,,drop=FALSE]
    output_values[[i]]<-pre_observed[[i]][keep,,drop=FALSE]
  }

  provenance<-list(
    source="simulate_functional_process_core",
    synthetic=TRUE,private_0_11_simulation_core=TRUE,
    random_state=seed,observation_design="irregular",
    irregular_time_design=sampling$kind,
    raw_dense_to_irregular_interpolation_performed=FALSE,
    measurement_noise_sd=noise_sd,
    measurement_noise_covariance=lapply(seq_len(nd),
      function(i)as.numeric(noise_covariance[i,])),
    participant_eigenvalues=pv,trial_eigenvalues=tv,
    phase_variation_kind="none",phase_exponents=rep(1,n),
    missingness_kind=missing_spec$kind,
    missingness_specification=missingness,
    score_distribution="normal",n_components=k,
    truth_grid=as.numeric(truth_grid),
    native_random_engine=if(is.null(source_draws))
      "base_R_not_NumPy_PCG64" else "externally_retained_source_draws",
    full_source_contract_certified=FALSE)
  observations<-etr_irregular_trajectory_set(
    output_times,output_values,ids,dimension_names,
    metadata=metadata,coordinate_system=coordinate_system,
    time_unit=time_unit,provenance=provenance)
  truth<-list(
    truth_grid=as.numeric(truth_grid),mean=m,
    eigenfunctions=modes,eigenvalues=as.numeric(eigenvalues),
    scores=scores,curve_scores=curve_scores,
    participant_scores=participant_scores,trial_scores=trial_scores,
    participant_eigenvalues=pv,trial_eigenvalues=tv,
    latent_on_truth_grid=latent_grid,
    phase_warps_on_truth_grid=warped_grid,
    pre_missing_observation_times=pre_missing_times,
    warped_pre_missing_observation_times=pre_missing_times,
    observation_times=output_times,
    warped_observation_times=output_times,
    latent_at_pre_missing_times=pre_latent,
    latent_at_observation_times=output_latent,
    measurement_noise=noise,
    measurement_noise_covariance=noise_covariance,
    observed_pre_missing=pre_observed,missingness_mask=masks,
    metadata=metadata,dimension_names=dimension_names,
    coordinate_system=coordinate_system,time_unit=time_unit,
    observation_design="irregular",score_distribution="normal",
    score_distribution_parameters=list(kind="normal"),
    random_state=seed,provenance=provenance)
  structure(list(observations=observations,truth=truth),
    class="etr_functional_simulation_result")
}
