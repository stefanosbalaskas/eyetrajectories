# Python 1.2.0 frozen multivariate_surrogates.py
# multivariate_surrogate_nonlinearity_test
# Source SHA c1cd95ad718327550f7e55393ff38582872f7a94
# Restricted native domain: sample units and R MIAAFT draw stream.
#' Multivariate Lyapunov nonlinearity test with MIAAFT null surrogates
#' @param trajectories Native complete regular common-grid trajectories.
#' @param curve Curve ID or zero-based curve index.
#' @param dimensions At least two distinct named dimensions.
#' @param reference_dimension Explicit selected reference dimension.
#' @param statistic Currently largest_lyapunov only.
#' @param embedding_dimension Delay embedding dimension.
#' @param delay,theiler_window,max_horizon,fit_start,fit_end Sample units.
#' @param delay_units,theiler_window_units,max_horizon_units,fit_units Must be samples.
#' @param n_surrogates Number of generated multivariate surrogates.
#' @param alternative greater, less or two-sided.
#' @param max_iterations,tolerance MIAAFT convergence controls.
#' @param random_state Scoped R seed, not NumPy-equivalent.
#' @export
etr_multivariate_surrogate_nonlinearity_test<-function(
    trajectories,curve,dimensions,reference_dimension,
    statistic,embedding_dimension,delay,theiler_window,
    max_horizon,fit_start,fit_end,
    delay_units="samples",theiler_window_units="samples",
    max_horizon_units="samples",fit_units="samples",
    n_surrogates=199L,alternative="greater",
    max_iterations=1000L,tolerance=1e-8,random_state=NULL){
  .etr_assert(identical(statistic,"largest_lyapunov"),
    "statistic must be largest_lyapunov")
  .etr_assert(is.character(alternative)&&length(alternative)==1L&&
    !is.na(alternative)&&alternative%in%c("greater","less","two-sided"),
    "alternative must be greater, less or two-sided")
  .etr_assert(all(c(delay_units,theiler_window_units,
    max_horizon_units,fit_units)=="samples"),
    "native multivariate test supports sample units only")
  m<-.etr_nonlinear_integer(embedding_dimension,2L,"embedding_dimension")
  dl<-.etr_nonlinear_integer(delay,1L,"delay")
  tw<-.etr_nonlinear_integer(theiler_window,0L,"theiler_window")
  mh<-.etr_nonlinear_integer(max_horizon,1L,"max_horizon")
  a<-.etr_nonlinear_integer(fit_start,0L,"fit_start")
  b<-.etr_nonlinear_integer(fit_end,1L,"fit_end")
  .etr_assert(b>a,"fit_end must exceed fit_start")
  etr_validate(trajectories,require_complete=TRUE)
  ci<-.etr_nonlinear_curve(trajectories$curve_ids,curve)
  .etr_assert(is.character(dimensions)&&length(dimensions)>=2L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%trajectories$dimension_names),
    "dimensions must be distinct declared source channels")
  nd<-length(dimensions);nt<-length(trajectories$time)
  selected<-match(dimensions,trajectories$dimension_names)
  source_values<-matrix(0,nt,nd)
  for(j in seq_len(nd))
    source_values[,j]<-trajectories$values[ci,,selected[[j]]]
  one<-function(values){
    etr_trajectory_set(trajectories$time,array(values,c(1L,nt,nd)),
      trajectories$curve_ids[[ci]],dimensions,
      coordinate_system=trajectories$coordinate_system,
      time_unit=trajectories$time_unit)
  }
  stat<-function(values){
    emb<-etr_delay_embed_trajectory(one(values),
      embedding_dimension=m,delay=dl,dimensions=dimensions)
    div<-etr_local_divergence_curve(emb,curve=0L,
      theiler_window=tw,max_horizon=mh)
    as.numeric(etr_estimate_largest_lyapunov_rosenstein(
      div,fit_start=a,fit_end=b)$exponent)
  }
  observed<-stat(source_values)
  .etr_assert(length(observed)==1L&&is.finite(observed),
    "observed multivariate LLE must be finite")
  surrogates<-etr_generate_multivariate_iaaft_surrogates(
    trajectories,curve,dimensions,reference_dimension,
    n_surrogates=n_surrogates,max_iterations=max_iterations,
    tolerance=tolerance,random_state=random_state)
  stats<-vapply(seq_len(surrogates$n_surrogates),function(i){
    values<-matrix(surrogates$surrogates[i,,],
      nrow=nt,ncol=nd)
    value<-tryCatch(stat(values),error=function(e)stop(sprintf(
      "multivariate surrogate statistic %d failed: %s",i-1L,
      conditionMessage(e)),call.=FALSE))
    .etr_assert(length(value)==1L&&is.finite(value),
      "multivariate surrogate statistic must be finite")
    value
  },numeric(1L))
  upper<-(sum(stats>=observed)+1)/(length(stats)+1)
  lower<-(sum(stats<=observed)+1)/(length(stats)+1)
  pv<-switch(alternative,greater=upper,less=lower,
    "two-sided"=min(1,2*min(upper,lower)))
  structure(list(
    observed_statistic=observed,surrogate_statistics=stats,
    p_value=pv,alternative=alternative,statistic=statistic,
    surrogate_result=surrogates,
    provenance=list(
      operation="multivariate_surrogate_nonlinearity_test",
      source_provenance=trajectories$provenance,
      curve_id=surrogates$curve_id,
      dimensions=dimensions,reference_dimension=reference_dimension,
      surrogate_method="multivariate_IAAFT",
      common_statistic_settings=list(embedding_dimension=m,
        delay=dl,delay_units="samples",
        theiler_window=tw,theiler_window_units="samples",
        max_horizon=mh,max_horizon_units="samples",
        fit_start=a,fit_end=b,fit_units="samples"),
      p_value_correction=if(alternative=="two-sided")
        "two_sided_double_min_plus_one_tails" else "plus_one",
      failed_surrogate_policy="raise",
      source_python_equivalent_stochastic_draws=FALSE,
      interpretation_boundary=paste(
        "Rejection is evidence against the declared multivariate",
        "linear-stochastic surrogate null; it does not establish",
        "deterministic chaos or a unique nonlinear mechanism."))),
    class="etr_multivariate_surrogate_nonlinearity")
}
