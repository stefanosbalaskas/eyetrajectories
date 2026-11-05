# Python 1.2.0 frozen multivariate_surrogates.py
# Source SHA c1cd95ad718327550f7e55393ff38582872f7a94
# Native Fourier/rank constraint port, no NumPy RNG equivalence asserted.

.etr_multivariate_positive_integer<-function(x,label){
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.na(x)&&is.finite(x)&&
    x==floor(x)&&x>=1L&&x<=.Machine$integer.max,
    paste(label,"must be a positive integer"))
  as.integer(x)
}
.etr_multivariate_fft_half<-function(x){
  h<-floor(nrow(x)/2L)+1L
  sapply(seq_len(ncol(x)),function(j)
    stats::fft(x[,j])[seq_len(h)])
}
.etr_multivariate_fft_inverse<-function(half,n){
  h<-nrow(half)
  out<-matrix(0,n,ncol(half))
  for(j in seq_len(ncol(half))){
    reversed<-if(n%%2L==0L){
      if(h>2L)Conj(rev(half[2:(h-1L),j])) else complex()
    } else Conj(rev(half[2:h,j]))
    out[,j]<-Re(stats::fft(c(half[,j],reversed),inverse=TRUE))/n
  }
  out
}
.etr_multivariate_spectrum_errors<-function(surrogate,target_spectrum,pairs){
  now<-.etr_multivariate_fft_half(surrogate)
  expected<-Mod(target_spectrum)
  norm<-function(z)sqrt(sum(Mod(z)^2))
  error<-vapply(seq_len(ncol(now)),function(j)
    norm(Mod(now[,j])-expected[,j])/
      max(norm(expected[,j]),.Machine$double.eps),numeric(1L))
  cross<-vapply(pairs,function(p){
    a<-now[-1L,p[[1L]]]*Conj(now[-1L,p[[2L]]])
    b<-target_spectrum[-1L,p[[1L]]]*Conj(
      target_spectrum[-1L,p[[2L]]])
    norm(a-b)/max(norm(b),.Machine$double.eps)
  },numeric(1L))
  list(spectral=error,cross=cross)
}
.etr_multivariate_iaaft_once<-function(values,reference_index,
    max_iterations,tolerance){
  n<-nrow(values);d<-ncol(values)
  target<-apply(values,2L,sort)
  spectrum<-.etr_multivariate_fft_half(values)
  amplitude<-Mod(spectrum)
  offsets<-sweep(Arg(spectrum),1L,Arg(spectrum[,reference_index]),"-")
  pairs<-combn(seq_len(d),2L,simplify=FALSE)
  surrogate<-sapply(seq_len(d),function(j)
    sample(values[,j],n,replace=FALSE))
  previous<-Inf
  for(i in seq_len(max_iterations)){
    current<-.etr_multivariate_fft_half(surrogate)
    refphase<-Arg(current[,reference_index])
    adjusted<-amplitude*exp(1i*sweep(offsets,1L,refphase,"+"))
    adjusted[1L,]<-spectrum[1L,]
    if(n%%2L==0L)adjusted[nrow(adjusted),]<-
      spectrum[nrow(adjusted),]
    transformed<-.etr_multivariate_fft_inverse(adjusted,n)
    ranked<-matrix(0,n,d)
    for(j in seq_len(d)){
      order<-order(transformed[,j],seq_len(n),method="radix")
      ranked[order,j]<-target[,j]
    }
    errors<-.etr_multivariate_spectrum_errors(ranked,spectrum,pairs)
    combined<-max(c(errors$spectral,errors$cross))
    fixed<-identical(unname(ranked),unname(surrogate))
    surrogate<-ranked
    if(fixed||abs(previous-combined)<=tolerance)
      return(list(values=surrogate,iterations=as.integer(i),
        spectral_errors=errors$spectral,
        cross_spectral_errors=errors$cross))
    previous<-combined
  }
  stop("multivariate IAAFT did not converge within max_iterations",
    call.=FALSE)
}

#' Cross-spectrum-aware multivariate IAAFT surrogates in native R
#' @param trajectories Complete native regular common-grid trajectories.
#' @param curve Curve ID or zero-based source curve index.
#' @param dimensions At least two distinct named channels in desired order.
#' @param reference_dimension Required explicit reference channel.
#' @param n_surrogates Positive number of independent replicates.
#' @param max_iterations Positive convergence budget.
#' @param tolerance Positive spectral stopping-difference tolerance.
#' @param random_state Optional R seed with caller RNG restored.
#' @return Source-shaped surrogate array and per-dimension/spectral diagnostics.
#' @export
etr_generate_multivariate_iaaft_surrogates<-function(
    trajectories,curve,dimensions,reference_dimension,
    n_surrogates=199L,max_iterations=1000L,tolerance=1e-8,
    random_state=NULL){
  etr_validate(trajectories,require_complete=TRUE)
  steps<-diff(trajectories$time)
  .etr_assert(all(is.finite(steps))&&max(abs(steps-steps[[1L]]))<=
    1e-8*max(1,abs(steps[[1L]])),
    "multivariate surrogates require a regular common grid")
  .etr_assert(is.character(dimensions)&&length(dimensions)>=2L&&
    !anyNA(dimensions)&&all(nzchar(dimensions))&&
    !anyDuplicated(dimensions)&&
    all(dimensions%in%trajectories$dimension_names),
    "dimensions must be at least two distinct existing channels")
  .etr_assert(is.character(reference_dimension)&&
    length(reference_dimension)==1L&&!is.na(reference_dimension)&&
    reference_dimension%in%dimensions,
    "reference_dimension must be a selected dimension")
  b<-.etr_multivariate_positive_integer(n_surrogates,"n_surrogates")
  it<-.etr_multivariate_positive_integer(max_iterations,"max_iterations")
  .etr_assert(is.numeric(tolerance)&&length(tolerance)==1L&&
    !is.na(tolerance)&&is.finite(tolerance)&&tolerance>0,
    "tolerance must be finite and positive")
  ci<-.etr_nonlinear_curve(trajectories$curve_ids,curve)
  channels<-match(dimensions,trajectories$dimension_names)
  nt<-length(trajectories$time);d<-length(channels)
  values<-matrix(0,nt,d)
  for(j in seq_len(d))values[,j]<-trajectories$values[ci,,channels[[j]]]
  .etr_assert(all(is.finite(values))&&
    all(vapply(seq_len(d),function(j)stats::sd(values[,j])>0,
      logical(1L))),
    "multivariate IAAFT requires finite nonconstant selected channels")
  if(!is.null(random_state)){
    restore<-.etr_simulation_rng(random_state)
    on.exit(restore(),add=TRUE)
  }
  surrogates<-array(NA_real_,c(b,nt,d))
  iterations<-integer(b);errors<-matrix(NA_real_,b,d)
  pairs<-combn(seq_len(d),2L,simplify=FALSE)
  cross<-matrix(NA_real_,b,length(pairs))
  for(i in seq_len(b)){
    trial<-tryCatch(.etr_multivariate_iaaft_once(values,
      match(reference_dimension,dimensions),it,tolerance),
      error=function(e)stop(sprintf(
        "multivariate surrogate %d failed: %s",i-1L,
        conditionMessage(e)),call.=FALSE))
    surrogates[i,,]<-trial$values
    iterations[[i]]<-trial$iterations
    errors[i,]<-trial$spectral_errors
    cross[i,]<-trial$cross_spectral_errors
  }
  pair_names<-lapply(pairs,function(p)dimensions[p])
  structure(list(
    surrogates=surrogates,source_values=values,
    curve_id=trajectories$curve_ids[[ci]],
    dimension_names=dimensions,reference_dimension=reference_dimension,
    dimension_pairs=pair_names,convergence_iterations=iterations,
    spectral_errors=errors,cross_spectral_errors=cross,
    n_surrogates=b,max_iterations=it,tolerance=tolerance,
    random_state=random_state,
    provenance=list(
      operation="generate_multivariate_iaaft_surrogates",
      source_provenance=trajectories$provenance,
      curve_id=trajectories$curve_ids[[ci]],
      dimensions=as.list(dimensions),
      reference_dimension=reference_dimension,
      method="reference_anchored_multivariate_IAAFT",
      fourier_constraint=paste0(
        "original_per_dimension_amplitudes_plus_original_",
        "inter_dimension_phase_differences"),
      marginal_constraint="exact_per_dimension_empirical_rank_distribution",
      cross_spectral_preservation=
        "approximate_after_final_rank_remapping_with_error_retained",
      reference_dimension_selected_automatically=FALSE,
      sampling_grid="regular_common_grid",
      sampling_step=steps[[1L]],
      time_unit=trajectories$time_unit,
      dimension_scaling=FALSE,
      smoothing=FALSE,interpolation=FALSE,
      random_engine="base_R_sample_not_NumPy_PCG64",
      source_python_equivalent_stochastic_draws=FALSE,
      failed_surrogate_policy="raise",
      interpretation_boundary=paste(
        "Surrogates target a multivariate linear-stochastic null",
        "with retained marginal distributions and approximate",
        "auto/cross-spectral structure; they do not preserve nonlinear",
        "cross-dependence by construction"))),
    class="etr_multivariate_iaaft")
}
