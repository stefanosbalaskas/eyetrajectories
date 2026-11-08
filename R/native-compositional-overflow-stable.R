# Scientific native-R extension: overflow-stable inverse ALR and functional
# compositional FPCA reconstruction. Deliberately distinct from the frozen
# Python 1.2 source's direct exp(z)/sum(exp(z)) contract.

#' Overflow-stable inverse additive log-ratio transformation
#'
#' Reconstructs simplex probabilities from three-dimensional ALR coordinates
#' with a row-wise log-sum-exp normalization. This native numerical method
#' avoids the overflow/NaN produced by direct exponentiation of extreme
#' finite log-ratio scores. The reference component has logit zero. This
#' function is a scientific stable alternative, NOT exact Python 1.2
#' exceptional-value parity.
#'
#' @param transformed Numeric array (curves x times x K-1).
#' @param reference_dimension Python-style zero-based reference index;
#'   negative indices count from the end.
#' @param n_dimensions Total simplex dimensions (K), at least two.
#' @param infinite_policy Whether infinities are rejected (default) or
#'   resolved as an explicit limiting softmax. NaNs are always rejected.
#' @return Numeric array (curves x times x K), with simplex row sums one.
#' @export
etr_inverse_alr_stable <- function(transformed, reference_dimension=-1L,
    n_dimensions=dim(transformed)[3L]+1L,
    infinite_policy=c("error","limit")) {
  infinite_policy <- match.arg(infinite_policy)
  if(!is.array(transformed) || length(dim(transformed))!=3L ||
      !is.numeric(transformed))
    stop("transformed must be a three-dimensional numeric array",call.=FALSE)
  dims <- dim(transformed)
  if(!is.numeric(n_dimensions) || length(n_dimensions)!=1L ||
      is.na(n_dimensions) || !is.finite(n_dimensions) ||
      n_dimensions!=floor(n_dimensions) || n_dimensions<2L ||
      n_dimensions>.Machine$integer.max ||
      dims[3L] != n_dimensions-1L)
    stop("transformed data have incompatible dimensions",call.=FALSE)
  if(!is.numeric(reference_dimension) ||
      length(reference_dimension)!=1L ||
      is.na(reference_dimension) || !is.finite(reference_dimension) ||
      reference_dimension!=floor(reference_dimension))
    stop("reference_dimension must be a finite integer",call.=FALSE)
  if(anyNA(transformed) || any(is.nan(transformed)))
    stop("transformed must not contain NA or NaN",call.=FALSE)
  if(infinite_policy=="error" && any(!is.finite(transformed)))
    stop("nonfinite ALR coordinates require infinite_policy='limit'",call.=FALSE)

  k <- as.integer(n_dimensions)
  ref <- as.integer((reference_dimension %% k)+1L)
  nc <- dims[1L]
  nt <- dims[2L]
  result <- array(0,c(nc,nt,k))
  if(nc==0L || nt==0L)return(result)
  indices <- setdiff(seq_len(k),ref)
  logits <- matrix(0,nrow=as.double(nc)*nt,ncol=k)
  for(j in seq_along(indices)) {
    logits[,indices[j]] <- as.vector(transformed[,,j,drop=FALSE])
  }
  maxima <- apply(logits,1L,max)
  result_rows <- matrix(0,nrow=nrow(logits),ncol=k)
  infinite_rows <- is.infinite(maxima) & maxima>0
  if(any(!infinite_rows)) {
    ix <- which(!infinite_rows)
    finite_shift <- sweep(logits[ix,,drop=FALSE],1L,maxima[ix],"-")
    weights <- exp(finite_shift)
    result_rows[ix,] <- weights/rowSums(weights)
  }
  if(any(infinite_rows)) {
    # Limit as all +Inf coordinates diverge together at equal rates.
    ix <- which(infinite_rows)
    positive_inf <- is.infinite(logits[ix,,drop=FALSE]) &
      logits[ix,,drop=FALSE]>0
    result_rows[ix,] <- positive_inf/rowSums(positive_inf)
  }
  for(j in seq_len(k))
    result[,,j] <- matrix(result_rows[,j],nrow=nc,ncol=nt)
  result
}

#' Overflow-stable compositional FPCA reconstruction
#'
#' Reconstructs finite ALR scores and performs a numerically stable
#' inverse transformation to simplex trajectories. The original
#' `etr_reconstruct_compositional_fpca()` remains unchanged.
#'
#' @param result A fitted native `etr_compositional_fpca` object.
#' @param scores Optional scores replacing fitted scores.
#' @param n_components Optional number of fitted components to use.
#' @return Numeric array with a probability simplex at every curve/time.
#' @export
etr_reconstruct_compositional_fpca_stable <- function(result,scores=NULL,
    n_components=NULL) {
  if(!inherits(result,"etr_compositional_fpca") ||
      !inherits(result$fpca,"etr_fpca") ||
      length(result$original_dimension_names)<3L)
    stop("result must be a native compositional FPCA fit",call.=FALSE)
  z <- .etr_fpca_reconstruct_scores(result$fpca,scores,n_components)
  etr_inverse_alr_stable(z,
    reference_dimension=result$reference_dimension,
    n_dimensions=length(result$original_dimension_names))
}
