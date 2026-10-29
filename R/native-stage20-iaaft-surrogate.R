# Stage 20: native univariate IAAFT surrogate and LLE nonlinearity test.
# Published Python v1.2.0 nonlinear_dynamics.py; independent base R FFT.
# RNG streams differ; no claim of identical Monte Carlo realizations.

.etr_iaaft_single <- function(signal,max_iterations,tolerance) {
  n<-length(signal)
  target<-sort(signal)
  amps<-Mod(stats::fft(signal))[seq_len(floor(n/2)+1L)]
  surrogate<-sample(signal,n,replace=FALSE)
  old<-Inf
  full_spectrum<-function(half) {
    if(n%%2L==0L) tail<-if(length(half)>2L)
      Conj(rev(half[2:(length(half)-1L)]))else complex()
    else tail<-Conj(rev(half[2:length(half)]))
    c(half,tail)
  }
  for(iter in seq_len(max_iterations)){
    present<-stats::fft(surrogate)[seq_along(amps)]
    phase<-exp(1i*Arg(present))
    adjusted<-Re(stats::fft(full_spectrum(amps*phase),
      inverse=TRUE))/n
    order<-order(adjusted,seq_along(adjusted),method="radix")
    ranked<-numeric(n)
    ranked[order]<-target
    new_amp<-Mod(stats::fft(ranked))[seq_along(amps)]
    err<-sqrt(sum((new_amp-amps)^2))/
      max(sqrt(sum(amps^2)),.Machine$double.eps)
    surrogate<-ranked
    if(abs(old-err)<=tolerance)
      return(list(values=surrogate,iterations=as.integer(iter),
        spectral_error=err))
    old<-err
  }
  stop("IAAFT surrogate did not converge within max_iterations",call.=FALSE)
}

#' Test a declared largest-Lyapunov statistic under an IAAFT surrogate null
#' @param trajectories Complete native common-grid trajectories.
#' @param curve Exact curve ID or zero-based source index.
#' @param dimension One declared response channel.
#' @param statistic Only "largest_lyapunov".
#' @param embedding_dimension Positive integer (>=2) embedding blocks.
#' @param delay,theiler_window,max_horizon,fit_start,fit_end Explicit sample units.
#' @param delay_units,theiler_window_units,max_horizon_units,fit_units "samples" only.
#' @param method Only "iaaft".
#' @param n_surrogates Positive number of independent surrogate trials.
#' @param alternative "greater", "less", or "two-sided".
#' @param max_iterations Positive maximum IAAFT steps per surrogate.
#' @param tolerance Positive final Fourier-spectrum convergence-difference threshold.
#' @param random_state Scoped native base-R seed (not NumPy-identical).
#' @export
etr_surrogate_nonlinearity_test <- function(trajectories,curve,
    dimension,statistic,embedding_dimension,delay,theiler_window,
    max_horizon,fit_start,fit_end,delay_units="samples",
    theiler_window_units="samples",max_horizon_units="samples",
    fit_units="samples",method="iaaft",n_surrogates=199L,
    alternative="greater",max_iterations=1000L,tolerance=1e-8,
    random_state=NULL) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(identical(statistic,"largest_lyapunov"),
    "only largest_lyapunov statistic is supported")
  .etr_assert(identical(method,"iaaft"),"only iaaft method is supported")
  .etr_assert(is.character(alternative)&&length(alternative)==1L&&
    alternative%in%c("greater","less","two-sided"),
    "alternative must be greater, less or two-sided")
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    dimension%in%trajectories$dimension_names,
    "dimension must be an existing source dimension")
  .etr_assert(all(c(delay_units,theiler_window_units,max_horizon_units,
    fit_units)=="samples"),"sample units only are qualified")
  m<-.etr_nonlinear_integer(embedding_dimension,2L,"embedding_dimension")
  dl<-.etr_nonlinear_integer(delay,1L,"delay")
  th<-.etr_nonlinear_integer(theiler_window,0L,"theiler_window")
  mh<-.etr_nonlinear_integer(max_horizon,1L,"max_horizon")
  start<-.etr_nonlinear_integer(fit_start,0L,"fit_start")
  end<-.etr_nonlinear_integer(fit_end,1L,"fit_end")
  .etr_assert(end>start,"fit_end must exceed fit_start")
  b<-.etr_nonlinear_integer(n_surrogates,1L,"n_surrogates")
  maxit<-.etr_nonlinear_integer(max_iterations,1L,"max_iterations")
  .etr_assert(is.numeric(tolerance)&&length(tolerance)==1L&&
    is.finite(tolerance)&&tolerance>0,
    "tolerance must be finite and strictly positive")
  ci<-.etr_nonlinear_curve(trajectories$curve_ids,curve)
  signal<-as.numeric(trajectories$values[ci,,
    match(dimension,trajectories$dimension_names)])
  .etr_assert(all(is.finite(signal))&&stats::sd(signal)>0,
    "surrogate testing requires a finite non-constant signal")
  source_one<-function(values) {
    v<-array(values,c(1L,length(values),1L))
    etr_trajectory_set(trajectories$time,v,
      trajectories$curve_ids[ci],dimension,
      coordinate_system=trajectories$coordinate_system,
      time_unit=trajectories$time_unit)
  }
  stat<-function(values) {
    e<-etr_delay_embed_trajectory(source_one(values),m,dl,
      dimensions=dimension)
    div<-etr_local_divergence_curve(e,curve=0L,
      theiler_window=th,max_horizon=mh)
    etr_estimate_largest_lyapunov_rosenstein(div,start,end)$exponent
  }
  observed<-stat(signal)
  if(!is.null(random_state)){
    restore<-.etr_simulation_rng(random_state)
    on.exit(restore(),add=TRUE)
  }
  # Without a seed, native R uses its active RNG stream; unlike Python
  # default_rng(NULL), these stochastic draws are not NumPy-equivalent.
  sur<-iter<-errors<-numeric(b)
  for(i in seq_len(b)){
    trial<-tryCatch({
      candidate<-.etr_iaaft_single(signal,maxit,tolerance)
      list(value=stat(candidate$values),niter=candidate$iterations,
        err=candidate$spectral_error)
    },error=function(e)stop(sprintf(
      "surrogate %d failed under the declared analysis contract: %s",
      i-1L,conditionMessage(e)),call.=FALSE))
    sur[i]<-trial$value;iter[i]<-trial$niter;errors[i]<-trial$err
  }
  upper<-(sum(sur>=observed)+1)/(b+1)
  lower<-(sum(sur<=observed)+1)/(b+1)
  p<-switch(alternative,greater=upper,less=lower,
    "two-sided"=min(1,2*min(upper,lower)))
  structure(list(observed_statistic=observed,
    surrogate_statistics=sur,p_value=p,alternative=alternative,
    statistic=statistic,method=method,n_surrogates=b,
    random_state=random_state,convergence_iterations=as.integer(iter),
    spectral_errors=errors,
    provenance=list(operation="surrogate_nonlinearity_test",
      source_python_equivalent_stochastic_draws=FALSE,
      source_curve_id=trajectories$curve_ids[ci],
      dimension=dimension,surrogate_method="IAAFT",
      p_value_correction=if(alternative=="two-sided")
        "two_sided_double_min_plus_one_tails" else "plus_one",
      maximum_final_spectral_error=max(errors),
      common_statistic_settings=list(embedding_dimension=m,
        delay=dl,theiler_window=th,max_horizon=mh,
        fit_start=start,fit_end=end,units="samples"),
      failed_surrogate_policy="raise",
      interpretation_boundary=paste("Evidence against a declared linear",
        "stochastic IAAFT surrogate null is not unique evidence of chaos"))),
    class="etr_surrogate_nonlinearity")
}
