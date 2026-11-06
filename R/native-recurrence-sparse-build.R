# Exact fixed-radius one-dimensional sparse recurrence construction.
# Python 1.2 uses scipy.spatial.cKDTree query_pairs/query_ball_tree with
# inclusive-radius neighbors. This native R subset uses ordered state values;
# time-index order and Theiler exclusions are applied AFTER distance testing.
# No NumPy, scipy, Python bridge, or dense distance matrix is used.
.etr_source_sparse_fixed_radius_1d <- function(x,y=NULL,radius,
    theiler=0L,auto=is.null(y),max_pairs=3000000L) {
  .etr_assert(requireNamespace("Matrix",quietly=TRUE),
    "Matrix is required for sparse_output=TRUE")
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)>=2L&&
    all(is.finite(x)),"x must be a finite numeric state vector")
  .etr_assert(is.numeric(radius)&&length(radius)==1L&&
    is.finite(radius)&&radius>=0,"radius must be finite and non-negative")
  .etr_assert(is.logical(auto)&&length(auto)==1L&&!is.na(auto),
    "auto must be TRUE or FALSE")
  if (auto) {
    .etr_assert(is.null(y),"auto sparse source cannot specify y")
    y<-x
  } else {
    .etr_assert(is.numeric(y)&&is.null(dim(y))&&length(y)>=2L&&
      all(is.finite(y)),"y must be a finite numeric state vector")
  }
  .etr_assert(is.numeric(theiler)&&length(theiler)==1L&&
    is.finite(theiler)&&theiler>=0&&theiler==as.integer(theiler),
    "theiler must be a non-negative integer")
  .etr_assert(is.numeric(max_pairs)&&length(max_pairs)==1L&&
    is.finite(max_pairs)&&max_pairs>0&&max_pairs==as.integer(max_pairs),
    "max_pairs must be a positive integer")
  # For auto pairs, sort the joint state vector once and inspect each pair
  # in exactly one direction; for cross pairs, independently sort y.
  order_x<-if (auto) order(x) else seq_along(x)
  order_y<-if (auto) order_x else order(y)
  sorted_y<-y[order_y]
  i_chunks<-list();j_chunks<-list();n_pairs<-0L
  for (rank in seq_along(order_x)) {
    original_i<-order_x[rank]
    value<-x[original_i]
    # left.open=TRUE counts values strictly below the inclusive lower bound.
    lower<-findInterval(value-radius,sorted_y,left.open=TRUE)+1L
    upper<-findInterval(value+radius,sorted_y)
    if (lower>upper) next
    candidate_rank<-seq.int(lower,upper)
    if (auto) candidate_rank<-candidate_rank[candidate_rank>rank]
    if (!length(candidate_rank)) next
    column_indices<-as.integer(order_y[candidate_rank])
    if (auto) column_indices<-column_indices[
      abs(column_indices-original_i)>theiler]
    if (!length(column_indices)) next
    .etr_assert(n_pairs+length(column_indices)<=max_pairs,
      "sparse source exceeds max_pairs; reduce radius or subset upstream")
    n_pairs<-n_pairs+length(column_indices)
    k<-length(i_chunks)+1L
    i_chunks[[k]]<-rep.int(as.integer(original_i),length(column_indices))
    j_chunks[[k]]<-column_indices
  }
  i<-if(length(i_chunks)) as.integer(unlist(i_chunks,use.names=FALSE)) else integer()
  j<-if(length(j_chunks)) as.integer(unlist(j_chunks,use.names=FALSE)) else integer()
  if(auto&&n_pairs) {
    first_i<-i;first_j<-j
    i<-c(first_i,first_j)
    j<-c(first_j,first_i)
  }
  matrix<-Matrix::sparseMatrix(i=i,j=j,x=rep.int(TRUE,length(i)),
    dims=c(as.integer(length(x)),as.integer(length(y))),
    giveCsparse=TRUE)
  list(matrix=matrix,pair_count=as.integer(n_pairs),
    directed_nonzeros=length(i),dense_materialized=FALSE)
}
