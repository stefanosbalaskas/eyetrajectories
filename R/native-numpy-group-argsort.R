# Indirect integer sorting used by sklearn GroupKFold. The x86 network
# follows x86-simd-sort at 6a7a01d and the scalar sort follows NumPy 2.3.5
# quicksort.cpp and npysort_heapsort.h. See inst/licenses/NUMPY-GROUP-ARGSORT.txt.

.etr_numpy_group_argsort_simd <- function(counts) {
  n <- length(counts)
  if (!is.unsorted(counts)) return(seq_len(n))
  if (!anyDuplicated(counts)) return(order(counts,method="radix"))
  .etr_assert(n <= 256L,
    "NumPy SIMD ordering for more than 256 mixed-order tied groups requires explicit fold_assignments")

  levels <- ceiling(log2(n))
  size <- as.integer(2^levels)
  keys <- c(counts,rep(Inf,size-n))
  position <- seq_len(size)-1L
  indices <- seq_len(size)
  # Each ascending pair of sorted blocks merges by comparing reflected
  # positions first, then by successively halving the comparison distance.
  # The lane's original index is kept on equality, as in the SIMD masks.
  compare <- function(indices,mask,distance) {
    peer <- indices[1L+bitwXor(position,mask)]
    high <- bitwAnd(position,distance)!=0L
    replace <- (high & keys[indices]<keys[peer]) |
      (!high & keys[indices]>keys[peer])
    indices[replace] <- peer[replace]
    indices
  }
  for (level in seq_len(levels)) {
    half <- as.integer(2^(level-1L))
    indices <- compare(indices,2L*half-1L,half)
    while (half>1L) {
      half <- half%/%2L
      indices <- compare(indices,half,half)
    }
  }
  indices[seq_len(n)]
}

.etr_numpy_group_argsort_scalar <- function(counts) {
  heap <- function(indices) {
    size <- length(indices)
    sift <- function(i,last,value) {
      child <- 2*i
      while (child<=last) {
        if (child<last && counts[indices[child]]<counts[indices[child+1L]])
          child <- child+1L
        if (counts[value]>=counts[indices[child]]) break
        indices[i] <<- indices[child]
        i <- child
        child <- 2*i
      }
      indices[i] <<- value
    }
    for (i in rev(seq_len(size%/%2L))) sift(i,size,indices[i])
    for (last in rev(seq_len(size)[-1L])) {
      value <- indices[last]
      indices[last] <- indices[1L]
      sift(1L,last-1L,value)
    }
    indices
  }
  sort_indices <- function(indices,depth,from_smaller=FALSE) {
    if (depth<0L && !from_smaller) return(heap(indices))
    n <- length(indices)
    # At most sixteen entries use stable insertion sort in the oracle.
    if (n<=16L) return(indices[order(counts[indices],method="radix")])

    swap <- function(i,j) indices[c(i,j)] <<- indices[c(j,i)]
    middle <- 1L+(n-1L)%/%2L
    if (counts[indices[middle]]<counts[indices[1L]]) swap(middle,1L)
    if (counts[indices[n]]<counts[indices[middle]]) swap(n,middle)
    if (counts[indices[middle]]<counts[indices[1L]]) swap(middle,1L)
    pivot <- counts[indices[middle]]
    right <- n-1L
    left <- 1L
    swap(middle,right)
    repeat {
      left <- left+1L
      while (counts[indices[left]]<pivot) left <- left+1L
      right <- right-1L
      while (pivot<counts[indices[right]]) right <- right-1L
      if (left>=right) break
      swap(left,right)
    }
    swap(left,n-1L)
    before <- indices[seq_len(left-1L)]
    after <- indices[seq.int(left+1L,n)]
    before_smaller <- length(before)<length(after)
    # NumPy enters the smaller partition directly and tests the heap
    # cutoff only after popping a saved larger partition from its stack.
    c(sort_indices(before,depth-1L,before_smaller),indices[left],
      sort_indices(after,depth-1L,!before_smaller))
  }
  n <- length(counts)
  if (!anyDuplicated(counts)) return(order(counts,method="radix"))
  sort_indices(seq_len(n),2L*floor(log2(n)))
}
