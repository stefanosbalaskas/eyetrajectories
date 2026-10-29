# Independent R simulation scenario design integration, source-pinned to
# eyetrajectoriespy 1.2.0 c1cd95ad718327550f7e55393ff38582872f7a94
# src/eyetrajectoriespy/simulate.py. This is a RESTRICTED semantic port.
# A native R scenario is not the Python dataclass and scientific simulation
# is NOT performed by these auditable design functions.

.etr_scenario_integer <- function(x,name,minimum=-.Machine$integer.max) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.na(x)&&is.finite(x)&&
    x==floor(x)&&x>=minimum&&abs(x)<=.Machine$integer.max,
    paste0(name," must be a finite integer in the supported range"))
  as.integer(x)
}

.etr_scenario_variances <- function(x,n,name) {
  if(is.null(x))return(NULL)
  .etr_assert(is.numeric(x)&&length(x)==n&&!anyNA(x)&&
    all(is.finite(x))&&all(x>=0),
    paste0(name," must contain one finite nonnegative value per component"))
  as.numeric(x)
}

#' Declare one source-aligned native functional simulation design
#' @param name Nonempty scenario identifier.
#' @param truth_grid At least three strictly increasing finite time values.
#' @param eigenvalues Positive nonincreasing component variances.
#' @param n_participants Positive number of independent participants.
#' @param trials_per_participant Positive number of curves per participant.
#' @param dimension_names Unique response channel names.
#' @param coordinate_system,time_unit,observation_design,irregular_time_design Declared data domains.
#' @param samples_per_curve For irregular designs: a count or minimum/maximum.
#' @param participant_eigenvalues,trial_eigenvalues Nonnegative variance components.
#' @param measurement_noise_sd Nonnegative scalar or vector SD.
#' @param measurement_noise_covariance Covariance matrix; currently unsupported.
#' @param missingness,phase_variation Declared JSON-compatible mechanisms.
#' @param score_distribution,score_df Declared score distribution.
#' @param orthonormal_tolerance Strictly positive numerical tolerance.
#' @param replicates,seed_start Explicit replication and seed design.
#' @param labels Additional named JSON-compatible provenance.
#' @return Native immutable-by-convention S3 scenario record, not a simulator.
#' @export
etr_functional_simulation_scenario <- function(name,truth_grid,eigenvalues,
    n_participants,trials_per_participant=1L,dimension_names="value",
    coordinate_system="unknown",time_unit="normalized",
    observation_design="dense",samples_per_curve=NULL,
    irregular_time_design="uniform",participant_eigenvalues=NULL,
    trial_eigenvalues=NULL,measurement_noise_sd=0,
    measurement_noise_covariance=NULL,missingness=NULL,phase_variation=NULL,
    score_distribution="normal",score_df=5,orthonormal_tolerance=1e-6,
    replicates=1L,seed_start=42L,labels=list()) {
  .etr_assert(is.character(name)&&length(name)==1L&&!is.na(name)&&
    nzchar(trimws(name)),"scenario name must be nonempty")
  .etr_assert(is.numeric(truth_grid)&&length(truth_grid)>=3L&&
    all(is.finite(truth_grid))&&all(diff(truth_grid)>0),
    "truth_grid must be finite and strictly increasing")
  .etr_assert(is.numeric(eigenvalues)&&length(eigenvalues)>=1L&&
    all(is.finite(eigenvalues))&&all(eigenvalues>0)&&
    all(diff(eigenvalues)<=0),
    "eigenvalues must be positive and supplied in descending order")
  np<-.etr_scenario_integer(n_participants,"n_participants",1L)
  nt<-.etr_scenario_integer(trials_per_participant,"trials_per_participant",1L)
  nr<-.etr_scenario_integer(replicates,"replicates",1L)
  seed<-.etr_scenario_integer(seed_start,"seed_start")
  .etr_assert(as.double(np)*nt<=.Machine$integer.max,
    "n_curves exceeds native integer limit")
  .etr_assert(is.character(dimension_names)&&length(dimension_names)>0L&&
    !anyNA(dimension_names)&&all(nzchar(dimension_names))&&
    !anyDuplicated(dimension_names),
    "dimension_names must contain unique nonempty strings")
  .etr_assert(is.character(coordinate_system)&&length(coordinate_system)==1L&&
    !is.na(coordinate_system)&&nzchar(coordinate_system)&&
    is.character(time_unit)&&length(time_unit)==1L&&
    !is.na(time_unit)&&nzchar(time_unit),
    "coordinate_system and time_unit must be nonempty strings")
  .etr_assert(identical(observation_design,"dense")||
    identical(observation_design,"irregular"),
    "observation_design must be dense or irregular")
  .etr_assert(is.character(irregular_time_design)&&
    length(irregular_time_design)==1L&&!is.na(irregular_time_design)&&
    nzchar(irregular_time_design),"irregular_time_design must be nonempty")
  samples<-NULL
  if(!is.null(samples_per_curve)){
    .etr_assert(is.numeric(samples_per_curve)&&
      length(samples_per_curve)%in%c(1L,2L),
      "samples_per_curve must be an integer or a min/max pair")
    samples<-vapply(samples_per_curve,function(x)
      .etr_scenario_integer(x,"samples_per_curve",2L),integer(1L))
    .etr_assert(length(samples)==1L||samples[2L]>=samples[1L],
      "samples_per_curve must satisfy minimum <= maximum")
  }
  .etr_assert((observation_design=="dense"&&is.null(samples))||
    (observation_design=="irregular"&&!is.null(samples)),
    "samples_per_curve required only for irregular observation_design")
  pv<-.etr_scenario_variances(participant_eigenvalues,length(eigenvalues),
    "participant_eigenvalues")
  tv<-.etr_scenario_variances(trial_eigenvalues,length(eigenvalues),
    "trial_eigenvalues")
  .etr_assert(is.null(measurement_noise_covariance),
    "measurement_noise_covariance not yet supported by native scenario subset")
  .etr_assert(is.null(measurement_noise_sd)||
    (is.numeric(measurement_noise_sd)&&
     length(measurement_noise_sd)%in%c(1L,length(dimension_names))&&
     all(is.finite(measurement_noise_sd))&&
     all(measurement_noise_sd>=0)),
    "measurement_noise_sd must be finite nonnegative scalar or per dimension")
  .etr_assert(score_distribution %in% c("normal","student_t")&&
    length(score_distribution)==1L&&!is.na(score_distribution),
    "score_distribution must be normal or student_t")
  .etr_assert(is.numeric(score_df)&&length(score_df)==1L&&
    is.finite(score_df)&&
    (score_distribution!="student_t"||score_df>2),
    "score_df must exceed 2 for student_t")
  .etr_assert(is.numeric(orthonormal_tolerance)&&
    length(orthonormal_tolerance)==1L&&
    is.finite(orthonormal_tolerance)&&orthonormal_tolerance>0,
    "orthonormal_tolerance must be strictly positive")
  for(nm in c("missingness","phase_variation","labels")){
    v<-get(nm)
    if(!is.null(v)) .etr_workflow_named_fields(v,nm)
  }
  structure(list(name=trimws(name),truth_grid=as.numeric(truth_grid),
    eigenvalues=as.numeric(eigenvalues),
    n_participants=np,trials_per_participant=nt,
    dimension_names=as.character(dimension_names),
    coordinate_system=coordinate_system,time_unit=time_unit,
    observation_design=observation_design,samples_per_curve=samples,
    irregular_time_design=irregular_time_design,
    participant_eigenvalues=pv,trial_eigenvalues=tv,
    measurement_noise_sd=measurement_noise_sd,
    measurement_noise_covariance=NULL,
    missingness=missingness,phase_variation=phase_variation,
    score_distribution=score_distribution,score_df=as.numeric(score_df),
    orthonormal_tolerance=as.numeric(orthonormal_tolerance),
    replicates=nr,seed_start=seed,labels=labels),
    class="etr_functional_simulation_scenario")
}

.etr_scenario_json <- function(x,mapping=FALSE,scalar=FALSE) {
  if(is.null(x))return(NA_character_)
  if(mapping&&is.list(x)&&!length(x))return("{}")
  if(!requireNamespace("jsonlite",quietly=TRUE))
    stop("jsonlite required for simulation scenario source JSON",call.=FALSE)
  as.character(jsonlite::toJSON(x,auto_unbox=scalar,
    null="null",digits=NA,pretty=FALSE))
}

#' Audit functional simulation scenario designs in a native R data frame
#' @param scenarios Ordered list of native scenario declarations.
#' @return Source-aligned 23-column scenario design table. Python pandas
#'   class, float formatting and Python dataclass identity remain uncertified.
#' @export
etr_functional_simulation_scenario_frame <- function(scenarios) {
  .etr_assert(is.list(scenarios),"scenarios must be a list")
  if(!length(scenarios))return(data.frame())
  .etr_assert(all(vapply(scenarios,function(x)
    inherits(x,"etr_functional_simulation_scenario"),logical(1L))),
    "every scenario must be a native functional simulation scenario")
  rows<-lapply(scenarios,function(s){
    counts<-s$samples_per_curve
    if(is.null(counts))counts<-as.integer(length(s$truth_grid))
    data.frame(scenario=s$name,
      n_participants=s$n_participants,
      trials_per_participant=s$trials_per_participant,
      n_curves=as.integer(s$n_participants*s$trials_per_participant),
      n_time_truth=as.integer(length(s$truth_grid)),
      n_components=as.integer(length(s$eigenvalues)),
      eigenvalues=.etr_scenario_json(s$eigenvalues),
      observation_design=s$observation_design,
      samples_per_curve_min=counts[[1L]],
      samples_per_curve_max=counts[[length(counts)]],
      irregular_time_design=s$irregular_time_design,
      participant_eigenvalues=.etr_scenario_json(s$participant_eigenvalues),
      trial_eigenvalues=.etr_scenario_json(s$trial_eigenvalues),
      measurement_noise_sd=.etr_scenario_json(s$measurement_noise_sd,
        scalar=length(s$measurement_noise_sd)==1L),
      measurement_noise_covariance=NA_character_,
      coordinate_system=s$coordinate_system,
      time_unit=s$time_unit,
      missingness=.etr_scenario_json(s$missingness,mapping=TRUE),
      phase_variation=.etr_scenario_json(s$phase_variation,mapping=TRUE),
      score_distribution=s$score_distribution,
      replicates=s$replicates,
      seed_start=s$seed_start,
      labels=.etr_scenario_json(s$labels,mapping=TRUE),
      stringsAsFactors=FALSE,check.names=FALSE)
  })
  ans<-do.call(rbind,rows);rownames(ans)<-NULL;ans
}

#' Expand an explicitly declared simulation design without fitting or RNG
#' @param base Native scenario declaration.
#' @param factors Named lists or vectors of scalar factor levels.
#' @param seed_policy shared seeds or disjoint replication blocks.
#' @return Ordered native scenario records. Restricted scalar-factor subset.
#' @export
etr_expand_functional_simulation_scenarios <- function(base,factors,
    seed_policy=c("shared","disjoint")) {
  .etr_assert(inherits(base,"etr_functional_simulation_scenario"),
    "base must be a native functional simulation scenario")
  seed_policy<-match.arg(seed_policy)
  .etr_assert(is.list(factors)&&length(factors)>0L&&
    !is.null(names(factors))&&!anyNA(names(factors))&&
    all(nzchar(names(factors)))&&!anyDuplicated(names(factors)),
    "factors must be a named nonempty list")
  allowed<-c("n_participants","trials_per_participant","replicates",
    "observation_design","score_distribution","score_df",
    "measurement_noise_sd","orthonormal_tolerance")
  .etr_assert(all(names(factors)%in%allowed),
    "unknown or currently unsupported scenario factor")
  levels<-lapply(factors,function(x){
    .etr_assert((is.atomic(x)&&!is.object(x))||is.list(x),
      "factor must be an explicit level sequence")
    .etr_assert(length(x)>0L,"factor must contain at least one level")
    if(!is.list(x))x<-as.list(x)
    .etr_assert(all(vapply(x,function(v)
      (is.numeric(v)||is.character(v))&&length(v)==1L&&!is.na(v),
      logical(1L))),"factor levels must be scalar finite numeric or strings")
    x
  })
  grid<-do.call(expand.grid,c(rev(lapply(levels,seq_along)),
    list(KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)))
  grid<-grid[,ncol(grid):1L,drop=FALSE]
  results<-vector("list",nrow(grid))
  for(i in seq_len(nrow(grid))){
    src<-unclass(base)
    suffix<-character(length(levels))
    for(j in seq_along(levels)){
      value<-levels[[j]][[grid[i,j]]]
      nm<-names(levels)[[j]]
      src[[nm]]<-value
      suffix[[j]]<-paste0(nm,"=",gsub("[^A-Za-z0-9_.+-]+","-",
        as.character(value)))
    }
    src$name<-paste0(base$name,"__",paste(suffix,collapse="__"))
    src$seed_start<-if(seed_policy=="shared")base$seed_start else
      as.double(base$seed_start)+(i-1L)*base$replicates
    results[[i]]<-do.call(etr_functional_simulation_scenario,src)
  }
  results
}
