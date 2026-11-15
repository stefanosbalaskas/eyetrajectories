# Python 1.2.0 frozen multivariate_surrogates.py
# Source SHA c1cd95ad718327550f7e55393ff38582872f7a94
# Native Fourier/rank constraint port with NumPy-compatible seeded initialization.

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
.etr_multivariate_spectrum_errors<-function(
    surrogate,target_spectrum,pairs,denominator_audit=FALSE){
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
  out<-list(spectral=error,cross=cross)
  if(!isTRUE(denominator_audit))return(out)
  # Diagnostic only: preserve the frozen Python 1.2 error law above.
  # Near-zero cross-spectral target norms make a ratio numerically
  # ill-conditioned even when surrogate rank/phase replay agrees.
  # The 64*eps guard is an explicitly R-side numerical warning, not a
  # replacement for Python's max(norm(target), eps) denominator and not
  # a surrogate convergence or inference decision.
  out$denominator_audit<-do.call(rbind,lapply(seq_along(pairs),function(i){
    p<-pairs[[i]]
    a<-now[-1L,p[[1L]]]*Conj(now[-1L,p[[2L]]])
    b<-target_spectrum[-1L,p[[1L]]]*Conj(
      target_spectrum[-1L,p[[2L]]])
    target_norm<-norm(b)
    error_norm<-norm(a-b)
    scale<-norm(target_spectrum[-1L,p[[1L]]])*
      norm(target_spectrum[-1L,p[[2L]]])
    threshold<-64*.Machine$double.eps*max(1,scale)
    data.frame(left=as.integer(p[[1L]]-1L),
      right=as.integer(p[[2L]]-1L),
      target_cross_spectral_norm=as.numeric(target_norm),
      cross_spectral_difference_norm=as.numeric(error_norm),
      source_denominator=as.numeric(max(target_norm,.Machine$double.eps)),
      independent_channel_norm_product=as.numeric(scale),
      roundoff_warning_threshold=as.numeric(threshold),
      near_zero_cross_spectral_target=target_norm<=threshold,
      relative_error=as.numeric(cross[[i]]))
  }))
  out
}
.etr_multivariate_unresolved_phases<-function(spectrum,n){
  amplitude<-Mod(spectrum)
  .etr_assert(all(is.finite(amplitude)),
    "multivariate IAAFT requires finite Fourier amplitudes")
  # Roundoff envelope scaled by channel amplitude and FFT depth.
  limit<-8*ceiling(log2(n))*.Machine$double.eps*apply(amplitude,2L,max)
  unresolved<-sweep(amplitude,2L,limit,"<=")
  unresolved[1L,]<-FALSE
  if(n%%2L==0L)unresolved[nrow(unresolved),]<-FALSE
  unresolved
}
.etr_multivariate_validate_phase_replay<-function(replay,b,h,d,max_iterations){
  if(is.null(replay))return(invisible(NULL))
  fields<-names(replay)
  .etr_assert(is.list(replay)&&is.null(dim(replay))&&length(replay)>0L&&
    !is.null(fields)&&!anyNA(fields)&&!anyDuplicated(fields)&&
    all(fields%in%c("target","reference")),
    "phase_replay must be a named list with target and/or reference")
  valid_phases<-function(x){
    is.matrix(x)&&is.numeric(x)&&!any(is.nan(x))&&
      all(is.na(x)|(is.finite(x)&abs(x)<=pi))
  }
  if(!is.null(replay$target)){
    .etr_assert(valid_phases(replay$target)&&
      identical(dim(replay$target),c(h,d)),
      "phase_replay target must be an (n_frequency, n_dimensions) matrix of radians or NA")
  }
  if(!is.null(replay$reference)){
    .etr_assert(is.list(replay$reference)&&is.null(dim(replay$reference))&&
      length(replay$reference)==b,
      "phase_replay reference must be a list with one entry per surrogate")
    for(x in replay$reference){
      .etr_assert(is.null(x)||(valid_phases(x)&&ncol(x)==h&&
        nrow(x)>0L&&nrow(x)<=max_iterations),
        "phase_replay reference entries must be NULL or (n_iterations, n_frequency) matrices of radians or NA within max_iterations")
    }
  }
  invisible(NULL)
}
.etr_multivariate_apply_phase_replay<-function(phase,replay,unresolved,label){
  if(is.null(replay))return(phase)
  supplied<-!is.na(replay)
  .etr_assert(!any(supplied&!unresolved),paste(label,
    "can only replace unresolved phases outside DC and Nyquist"))
  phase[supplied]<-replay[supplied]
  phase
}
.etr_multivariate_rank_match_columns<-function(transformed,sorted_target){
  n<-nrow(transformed)
  ranked<-matrix(0,n,ncol(transformed))
  for(j in seq_len(ncol(transformed))){
    order<-order(transformed[,j],seq_len(n),method="radix")
    ranked[order,j]<-sorted_target[,j]
  }
  ranked
}
.etr_multivariate_iaaft_once<-function(values,reference_index,
    max_iterations,tolerance,initial_order=NULL,
    spectrum=.etr_multivariate_fft_half(values),target_phase=Arg(spectrum),
    reference_phases=NULL,observer=NULL){
  n<-nrow(values);d<-ncol(values)
  target<-apply(values,2L,sort)
  amplitude<-Mod(spectrum)
  offsets<-sweep(target_phase,1L,target_phase[,reference_index],"-")
  pairs<-combn(seq_len(d),2L,simplify=FALSE)
  # Caller-supplied and integer-seeded orders share the same FFT path.
  surrogate<-if(is.null(initial_order)) {
    sapply(seq_len(d),function(j)sample(values[,j],n,replace=FALSE))
  } else {
    sapply(seq_len(d),function(j)
      values[as.integer(initial_order[,j])+1L,j])
  }
  surrogate<-matrix(surrogate,nrow=n,ncol=d)
  previous<-Inf
  phases_replayed<-0
  for(i in seq_len(max_iterations)){
    current<-.etr_multivariate_fft_half(surrogate)
    refphase<-Arg(current[,reference_index])
    if(!is.null(reference_phases)&&i<=nrow(reference_phases)){
      replay<-reference_phases[i,]
      if(any(!is.na(replay))){
        unresolved<-.etr_multivariate_unresolved_phases(
          current[,reference_index,drop=FALSE],n)
        refphase<-.etr_multivariate_apply_phase_replay(refphase,replay,
          unresolved[,1L],sprintf("phase_replay reference iteration %d",i))
        phases_replayed<-phases_replayed+sum(!is.na(replay))
      }
    }
    desired<-sweep(offsets,1L,refphase,"+")
    adjusted<-amplitude*exp(1i*desired)
    adjusted[1L,]<-spectrum[1L,]
    if(n%%2L==0L)adjusted[nrow(adjusted),]<-
      spectrum[nrow(adjusted),]
    transformed<-.etr_multivariate_fft_inverse(adjusted,n)
    .etr_assert(all(is.finite(transformed)),
      "multivariate IAAFT requires a finite inverse Fourier transform")
    ranked<-.etr_multivariate_rank_match_columns(transformed,target)
    if(!is.null(observer)){
      observer(list(previous=surrogate,spectrum=spectrum,current=current,
        offsets=offsets,desired=desired,adjusted_spectrum=adjusted,
        transformed=transformed,ranked=ranked))
    }
    errors<-.etr_multivariate_spectrum_errors(ranked,spectrum,pairs)
    combined<-max(c(errors$spectral,errors$cross))
    .etr_assert(is.finite(combined),
      "multivariate IAAFT requires finite spectral errors")
    fixed<-identical(unname(ranked),unname(surrogate))
    surrogate<-ranked
    if(fixed||abs(previous-combined)<=tolerance){
      if(!is.null(reference_phases)&&i<nrow(reference_phases)){
        unused<-reference_phases[seq.int(i+1L,nrow(reference_phases)),,
          drop=FALSE]
        .etr_assert(all(is.na(unused)),
          "phase_replay reference has supplied phases after convergence")
      }
      return(list(values=surrogate,iterations=as.integer(i),
        spectral_errors=errors$spectral,
        cross_spectral_errors=errors$cross,
        reference_phases_replayed=phases_replayed))
    }
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
#' @param random_state Integer seed for NumPy-compatible PCG64 permutations
#'   or NULL for unseeded native R draws.
#' @param initial_permutations Optional zero-based integer-valued array of
#'   shape (n_surrogates, n_time, n_selected_dimensions), where every
#'   surrogate-by-dimension column is a permutation of 0:(n_time-1).
#'   Uses the supplied initialization directly. The declared channel
#'   order must agree with \code{dimensions}.
#' @param phase_replay Optional named list with a target phase matrix
#'   and/or one reference phase matrix per surrogate. Radians can replace
#'   roundoff-scale Fourier phases and NA retains the native phase.
#' @param python_boundary_mode When TRUE, require the frozen Python 1.2
#'   public generator interface (no fixed permutation or Fourier phase
#'   replay), retaining its original 14 scientific fields and source
#'   provenance without native-only audit flags. FALSE retains the
#'   extended native R research interface.
#' @return Source-shaped surrogate array and per-dimension/spectral diagnostics.
#' @export
etr_generate_multivariate_iaaft_surrogates<-function(
    trajectories,curve,dimensions,reference_dimension,
    n_surrogates=199L,max_iterations=1000L,tolerance=1e-8,
    random_state=NULL,initial_permutations=NULL,phase_replay=NULL,
    python_boundary_mode=FALSE){
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be TRUE or FALSE")
  if(isTRUE(python_boundary_mode)){
    .etr_assert(is.null(initial_permutations)&&is.null(phase_replay),
      "Python source mode rejects native-only initial_permutations and phase_replay")
  }
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
  spectrum<-.etr_multivariate_fft_half(values)
  reference_index<-match(reference_dimension,dimensions)
  unresolved<-.etr_multivariate_unresolved_phases(spectrum,nt)
  .etr_multivariate_validate_phase_replay(phase_replay,b,nrow(spectrum),d,it)
  target_phase<-.etr_multivariate_apply_phase_replay(
    Arg(spectrum),phase_replay$target,unresolved,"phase_replay target")
  target_replayed<-sum(!is.na(phase_replay$target))
  reference_replayed<-numeric(b)
  other_channels<-seq_len(d)!=reference_index
  ambiguous_reference_bins<-which(unresolved[,reference_index]&
    rowSums(!unresolved[,other_channels,drop=FALSE])>0L)-1L
  if(!is.null(initial_permutations)){
    .etr_assert(is.array(initial_permutations)&&
      length(dim(initial_permutations))==3L&&
      is.numeric(initial_permutations)&&
      identical(as.integer(dim(initial_permutations)),c(b,nt,d))&&
      all(is.finite(initial_permutations))&&
      all(initial_permutations==floor(initial_permutations))&&
      all(initial_permutations>=0)&&all(initial_permutations<nt),
      "initial_permutations must be a finite zero-based integer array of shape (n_surrogates,n_time,n_dimensions)")
    # Enforce the permutation contract rather than silently accepting
    # duplicate or omitted source observations within a channel.
    valid<-all(vapply(seq_len(b),function(i)
      all(vapply(seq_len(d),function(j)
        identical(sort(as.integer(initial_permutations[i,,j])),
          seq.int(0L,nt-1L)),logical(1L))),logical(1L)))
    .etr_assert(valid,
      "initial_permutations must be complete permutations in every surrogate and channel")
  }
  rng<-if(!is.null(random_state)&&is.null(initial_permutations))
    .etr_numpy_pcg64(random_state) else NULL
  surrogates<-array(NA_real_,c(b,nt,d))
  iterations<-integer(b);errors<-matrix(NA_real_,b,d)
  pairs<-combn(seq_len(d),2L,simplify=FALSE)
  cross<-matrix(NA_real_,b,length(pairs))
  for(i in seq_len(b)){
    initial_order<-if(!is.null(initial_permutations)){
      matrix(initial_permutations[i,,,drop=FALSE],nrow=nt,ncol=d)
    }else if(!is.null(rng)){
      vapply(seq_len(d),function(j)rng$permutation(nt)-1L,integer(nt))
    }else NULL
    trial<-tryCatch(.etr_multivariate_iaaft_once(values,
      reference_index,it,tolerance,initial_order=initial_order,
      spectrum=spectrum,target_phase=target_phase,
      reference_phases=phase_replay$reference[[i]]),
      error=function(e)stop(sprintf(
        "multivariate surrogate %d failed: %s",i-1L,
        conditionMessage(e)),call.=FALSE))
    surrogates[i,,]<-trial$values
    iterations[[i]]<-trial$iterations
    errors[i,]<-trial$spectral_errors
    cross[i,]<-trial$cross_spectral_errors
    reference_replayed[[i]]<-trial$reference_phases_replayed
  }
  pair_names<-lapply(pairs,function(p)dimensions[p])
  result<-structure(list(
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
      random_engine=if(is.null(initial_permutations))
        (if(is.null(rng))"base_R_unseeded"else"numpy_pcg64") else
        "externally_supplied_zero_based_initial_permutations",
      initialization_source=if(is.null(initial_permutations))
        (if(is.null(rng))"native_R_per_channel_permutation"else"numpy_pcg64_permutation") else
        "fixed_numpy_compatible_permutation_replay",
      fixed_initialization_replay=!is.null(initial_permutations),
      seeded_initialization_matches_numpy=!is.null(rng),
      ambiguous_target_reference_bins_zero_based=ambiguous_reference_bins,
      target_phases_replayed=target_replayed,
      reference_phases_replayed=reference_replayed,
      source_python_equivalent_stochastic_draws=FALSE,
      failed_surrogate_policy="raise",
      interpretation_boundary=paste(
        "Surrogates target a multivariate linear-stochastic null",
        "with retained marginal distributions and approximate",
        "auto/cross-spectral structure; they do not preserve nonlinear",
        "cross-dependence by construction"))),
    class="etr_multivariate_iaaft")
  if(isTRUE(python_boundary_mode)){
    # The unseeded Python API draws OS entropy while native R uses its
    # ambient RNG. The estimand is unchanged but these realizations are
    # not identical. Source mode never claims identical unseeded paths.
    p<-result$provenance
    # Frozen Python emits a tuple of dimension names; reticulate maps this
    # to a character vector, not a list of length-one R strings.
    p$dimensions<-as.character(dimensions)
    p$interpretation_boundary<-paste(
      "surrogates target a multivariate linear-stochastic null",
      "with retained marginal distributions and approximate",
      "auto/cross-spectral structure; they do not preserve nonlinear",
      "cross-dependence by construction")
    native_audit<-c("random_engine","initialization_source",
      "fixed_initialization_replay",
      "seeded_initialization_matches_numpy",
      "ambiguous_target_reference_bins_zero_based",
      "target_phases_replayed","reference_phases_replayed",
      "source_python_equivalent_stochastic_draws")
    result$provenance<-p[setdiff(names(p),native_audit)]
  }
  result
}
