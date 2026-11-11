.etr_multivariate_lle_fixture<-function(){
  t<-seq(0,1,length.out=96L);j<-seq_len(96L)-1L
  a<-array(0,c(1L,96L,3L))
  a[1L,,1L]<-sin(2*pi*5*j/96)+.19*cos(2*pi*13*j/96)
  a[1L,,2L]<-cos(2*pi*5*j/96+.3)+.13*sin(2*pi*11*j/96)
  a[1L,,3L]<-(-0.5)*sin(2*pi*4*j/96+.4)+.28*cos(2*pi*9*j/96)
  etr_trajectory_set(t,a,"example",c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}

.etr_multivariate_lle_call<-function(x,alternative,phase_replay=NULL){
  etr_multivariate_surrogate_nonlinearity_test(x,curve="example",
    dimensions=c("x","y","z"),reference_dimension="y",
    statistic="largest_lyapunov",embedding_dimension=2L,delay=2L,
    theiler_window=3L,max_horizon=7L,fit_start=1L,fit_end=4L,
    n_surrogates=3L,max_iterations=100L,tolerance=.7,
    alternative=alternative,random_state=17L,phase_replay=phase_replay)
}

.etr_miaaft_python_trace<-function(x){
  # Observe the unmodified frozen source calculation at the rank boundary.
  # Both runtimes get the same numeric input, including sinusoid roundoff.
  reticulate::py_run_string("
def _etr_miaaft_periodic_source_trace(time, values):
    import sys
    import numpy as np
    import eyetrajectoriespy as et
    from eyetrajectoriespy import multivariate_surrogates as ms
    trajectory = et.TrajectorySet(
        time=np.asarray(time, dtype=float), values=np.asarray(values, dtype=float),
        curve_ids=('example',), dimension_names=('x','y','z'),
        coordinate_system='pixels', time_unit='s')
    snapshots = []
    rank = ms._rank_match_columns
    def capture(adjusted, target):
        state = sys._getframe(1).f_locals
        ranked = rank(adjusted, target)
        snapshots.append(dict(
            previous=state['surrogate'].copy(),
            spectrum=state['target_spectrum'].copy(),
            target_phase=state['target_phases'].copy(),
            current=state['current_spectrum'].copy(),
            reference_phase=state['reference_phase'].copy(),
            offsets=state['phase_offsets'].copy(),
            desired=state['desired_phases'].copy(),
            adjusted_spectrum=state['adjusted_spectrum'].copy(),
            transformed=adjusted.copy(),
            order=np.argsort(adjusted, axis=0, kind='mergesort'),
            ranked=ranked.copy()))
        return ranked
    try:
        ms._rank_match_columns = capture
        result = et.multivariate_surrogate_nonlinearity_test(
            trajectory, curve='example', dimensions=('x','y','z'),
            reference_dimension='y', statistic='largest_lyapunov',
            embedding_dimension=2, delay=2, theiler_window=3, max_horizon=7,
            fit_start=1, fit_end=4, n_surrogates=3, max_iterations=100,
            tolerance=.7, alternative='two-sided', random_state=17)
    finally:
        ms._rank_match_columns = rank
    surrogates = result.surrogate_result
    return dict(iterations=surrogates.convergence_iterations,
        surrogates=surrogates.surrogates, spectral_errors=surrogates.spectral_errors,
        cross_spectral_errors=surrogates.cross_spectral_errors,
        observed=result.observed_statistic, stats=result.surrogate_statistics,
        p=result.p_value, snapshots=snapshots, numpy_version=np.__version__)
")
  fn<-reticulate::py_eval("_etr_miaaft_periodic_source_trace",convert=FALSE)
  et_to_r(fn(x$time,x$values))
}

.etr_miaaft_phase_replay_from_trace<-function(source){
  first<-source$snapshots[[1L]]
  n<-nrow(first$previous)
  target<-first$target_phase
  target[!.etr_multivariate_unresolved_phases(first$spectrum,n)]<-NA_real_
  groups<-split(source$snapshots,rep(seq_along(source$iterations),
    source$iterations))
  reference<-lapply(groups,function(iterations){
    do.call(rbind,lapply(iterations,function(step){
      phase<-step$reference_phase
      unresolved<-.etr_multivariate_unresolved_phases(
        step$current[,2L,drop=FALSE],n)
      phase[!unresolved[,1L]]<-NA_real_
      phase
    }))
  })
  list(target=target,reference=unname(reference))
}

.etr_miaaft_native_trace<-function(x,source,replay=NULL){
  n<-length(x$time)
  values<-matrix(x$values,nrow=n)
  rng<-.etr_numpy_pcg64(17L)
  spectrum<-.etr_multivariate_fft_half(values)
  target_phase<-.etr_multivariate_apply_phase_replay(Arg(spectrum),
    replay$target,.etr_multivariate_unresolved_phases(spectrum,n),"target")
  source_start<-cumsum(c(0L,source$iterations))
  comparisons<-list()
  fields<-c("previous","spectrum","current","offsets","desired",
    "adjusted_spectrum","transformed","ranked")
  for(surrogate in seq_along(source$iterations)){
    iteration<-0L
    initial_order<-vapply(seq_len(ncol(values)),
      function(j)rng$permutation(n)-1L,integer(n))
    observe<-function(step){
      iteration<<-iteration+1L
      if(iteration>source$iterations[[surrogate]])return(invisible(NULL))
      expected<-source$snapshots[[source_start[[surrogate]]+iteration]]
      metrics<-vapply(fields,function(field)
        max(Mod(step[[field]]-expected[[field]])),numeric(1L))
      order<-vapply(seq_len(ncol(values)),function(j)
        order(step$transformed[,j],method="radix")-1L,integer(n))
      names(metrics)<-paste0("max_abs_",fields)
      comparisons[[length(comparisons)+1L]]<<-data.frame(
        surrogate=surrogate,iteration=iteration,
        as.list(metrics),different_rank_positions=sum(order!=expected$order))
      invisible(NULL)
    }
    .etr_multivariate_iaaft_once(values,2L,100L,.7,initial_order,
      spectrum,target_phase,replay$reference[[surrogate]],observe)
  }
  do.call(rbind,comparisons)
}
