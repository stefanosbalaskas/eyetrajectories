# Stage 21: independent reference-anchored multivariate IAAFT.
# Mathematical source: published eyetrajectoriespy v1.2.0
# multivariate_surrogates.py. Native base R FFT, no Python dependency.
# RNG streams are intentionally not claimed identical to NumPy.

.etr21_fft <- function(x) {
  n<-length(x)
  stats::fft(x)[seq_len(floor(n/2L)+1L)]
}
.etr21_irfft <- function(half,n){
  if(n%%2L==0L){
    mirror<-if(length(half)>2L)
      Conj(rev(half[2L:(length(half)-1L)]))else complex()
  }else{
    mirror<-if(length(half)>1L)
      Conj(rev(half[2L:length(half)]))else complex()
  }
  Re(stats::fft(c(half,mirror),inverse=TRUE))/n
}
.etr21_errors <- function(x,target_amp,target_cross,pairs){
  n<-nrow(x);d<-ncol(x)
  spectrum<-vapply(seq_len(d),function(j).etr21_fft(x[,j]),
    complex(floor(n/2L)+1L))
  spec<-numeric(d);cross<-numeric(nrow(pairs))
  for(j in seq_len(d)){
    den<-max(sqrt(sum(target_amp[,j]^2)),.Machine$double.eps)
    spec[j]<-sqrt(sum((Mod(spectrum[,j])-target_amp[,j])^2))/den
  }
  for(q in seq_len(nrow(pairs))){
    a<-pairs[q,1L];b<-pairs[q,2L]
    current<-spectrum[,a]*Conj(spectrum[,b])
    target<-target_cross[,q]
    den<-max(sqrt(sum(Mod(target[-1L])^2)),.Machine$double.eps)
    cross[q]<-sqrt(sum(Mod(current[-1L]-target[-1L])^2))/den
  }
  list(auto=spec,cross=cross)
}

#' Generate native reference-anchored multivariate IAAFT surrogates
#' @param trajectories Native complete common-grid trajectories.
#' @param curve Exact curve ID or zero-based source index.
#' @param dimensions Explicit >=2 existing dimension names, no duplicates.
#' @param reference_dimension One of the declared dimensions.
#' @param n_surrogates At least one independent surrogate.
#' @param max_iterations Positive maximum number of joint Fourier/remap steps.
#' @param tolerance Positive finite change in relative spectral error stopping criterion.
#' @param random_state Optional nonnegative native R seed.
#' @export
etr_generate_multivariate_iaaft_surrogates <- function(trajectories,curve,
    dimensions,reference_dimension,n_surrogates=199L,
    max_iterations=1000L,tolerance=1e-8,random_state=NULL){
  etr_validate(trajectories,require_complete=TRUE)
  .etr13_regularity(trajectories$time)
  .etr_assert(is.character(dimensions)&&length(dimensions)>=2L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%trajectories$dimension_names),
    "multivariate IAAFT dimensions must be at least two distinct known channels")
  .etr_assert(is.character(reference_dimension)&&
    length(reference_dimension)==1L&&
    reference_dimension%in%dimensions,
    "reference_dimension must be among declared dimensions")
  count<-.etr17_integer(n_surrogates,1L,"n_surrogates")
  limit<-.etr17_integer(max_iterations,1L,"max_iterations")
  .etr_assert(is.numeric(tolerance)&&length(tolerance)==1L&&
    is.finite(tolerance)&&tolerance>0,
    "tolerance must be strictly positive and finite")
  ci<-.etr17_curve(trajectories$curve_ids,curve)
  cols<-match(dimensions,trajectories$dimension_names)
  n<-length(trajectories$time);d<-length(dimensions)
  values<-matrix(trajectories$values[ci,,cols,drop=FALSE],n,d)
  .etr_assert(all(is.finite(values))&&all(apply(values,2L,stats::sd)>0),
    "multivariate IAAFT requires finite nonconstant channels")
  ref<-match(reference_dimension,dimensions)
  if(!is.null(random_state)){
    restore<-.etr13_rng(random_state);on.exit(restore(),add=TRUE)
  }
  half<-floor(n/2L)+1L
  source_fft<-vapply(seq_len(d),function(j).etr21_fft(values[,j]),complex(half))
  amp<-Mod(source_fft)
  offsets<-sweep(Arg(source_fft),1L,Arg(source_fft[,ref]),"-")
  pairs<-t(utils::combn(d,2L))
  nPairs<-nrow(pairs)
  target_cross<-matrix(0+0i,half,nPairs)
  for(p in seq_len(nPairs)){
    target_cross[,p]<-source_fft[,pairs[p,1L]]*
      Conj(source_fft[,pairs[p,2L]])
  }
  target_sorted<-apply(values,2L,sort)
  valuesOut<-array(0,c(count,n,d))
  iterOut<-integer(count);specOut<-matrix(0,count,d)
  crossOut<-matrix(0,count,nPairs)
  for(b in seq_len(count)){
    candidate<-vapply(seq_len(d),function(j)
      sample(values[,j],n,replace=FALSE),numeric(n))
    old<-Inf;converged<-FALSE
    for(iter in seq_len(limit)){
      current<-vapply(seq_len(d),function(j).etr21_fft(candidate[,j]),
        complex(half))
      desired<-amp*exp(1i*sweep(offsets,1L,Arg(current[,ref]),"+"))
      # Preserve genuinely real-valued DC and Nyquist bins, as Python does.
      desired[1L,]<-source_fft[1L,]
      if(n%%2L==0L) desired[half,]<-source_fft[half,]
      adjusted<-vapply(seq_len(d),function(j)
        .etr21_irfft(desired[,j],n),numeric(n))
      ranked<-matrix(0,n,d)
      for(j in seq_len(d)){
        order<-order(adjusted[,j],seq_len(n),method="radix")
        ranked[order,j]<-target_sorted[,j]
      }
      errors<-.etr21_errors(ranked,amp,target_cross,pairs)
      joint<-max(errors$auto,errors$cross)
      stable<-identical(unname(ranked),unname(candidate))
      candidate<-ranked
      if(stable||abs(old-joint)<=tolerance){
        converged<-TRUE
        iterOut[b]<-as.integer(iter)
        specOut[b,]<-errors$auto
        crossOut[b,]<-errors$cross
        break
      }
      old<-joint
    }
    .etr_assert(converged,
      sprintf("multivariate surrogate %d failed under declared IAAFT convergence contract",b-1L))
    valuesOut[b,,]<-candidate
  }
  pairNames<-lapply(seq_len(nPairs),function(j)
    dimensions[pairs[j,]])
  structure(list(surrogates=valuesOut,source_values=values,
    curve_id=trajectories$curve_ids[ci],
    dimension_names=dimensions,reference_dimension=reference_dimension,
    dimension_pairs=pairNames,convergence_iterations=iterOut,
    spectral_errors=specOut,cross_spectral_errors=crossOut,
    n_surrogates=count,max_iterations=limit,tolerance=tolerance,
    random_state=random_state,
    provenance=list(operation="generate_multivariate_iaaft_surrogates",
      source_python_equivalent_stochastic_draws=FALSE,
      source_provenance=trajectories$provenance,
      dimensions=dimensions,reference_dimension=reference_dimension,
      fourier_constraint="original_auto_amplitudes_and_interchannel_phase_differences",
      marginal_constraint="exact_empirical_rank_per_channel",
      cross_spectral_preservation="approximate_post_rank_remap",
      reference_dimension_selected_automatically=FALSE,
      sampling_grid="regular_common_grid",
      sampling_step=.etr13_regularity(trajectories$time),
      failed_surrogate_policy="error",
      interpretation_boundary="surrogate matches a declared multivariate linear stochastic null; nonlinear coupling is not preserved")),
    class="etr_multivariate_iaaft")
}
#' Auditable iteration and spectral error frame for native multivariate IAAFT
#' @param result Native multivariate IAAFT result.
#' @export
etr_multivariate_iaaft_diagnostics_frame <- function(result){
  .etr_assert(inherits(result,"etr_multivariate_iaaft")&&
    length(dim(result$surrogates))==3L&&
    nrow(result$spectral_errors)==result$n_surrogates&&
    nrow(result$cross_spectral_errors)==result$n_surrogates,
    "result must be a complete native multivariate IAAFT result")
  data.frame(
    surrogate=as.integer(seq_len(result$n_surrogates)-1L),
    iterations=as.integer(result$convergence_iterations),
    max_spectral_error=apply(result$spectral_errors,1L,max),
    max_cross_spectral_error=apply(result$cross_spectral_errors,1L,max),
    mean_spectral_error=rowMeans(result$spectral_errors),
    mean_cross_spectral_error=rowMeans(result$cross_spectral_errors))
}
