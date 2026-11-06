# Stage 8: independent native R recurrence-network and joint-RQA functions.
# Source contracts: eyetrajectoriespy v1.2.0 recurrence.py,
# recurrence_networks.py, joint_recurrence.py and nonlinear_types.py.
# No Python/reticulate runtime calls. Dense scientific RQA retains guards;
# recurrence-network and joint-recurrence accept sparse native Matrix inputs.

.etr_recurrence_internal <- function(x,kind="auto"){
  .etr_assert(inherits(x,"etr_recurrence") &&
    is.matrix(x$matrix) && is.logical(x$matrix) &&
    !anyNA(x$matrix) && identical(x$kind,kind),
    paste0(kind,"-recurrence must be a native etr_recurrence"))
  m<-x$matrix
  if(kind=="auto"){
    n<-nrow(m)
    .etr_assert(n>=2L && n==ncol(m) && identical(m,t(m)) &&
       !any(diag(m)),"auto recurrence requires a symmetric square off-diagonal matrix")
    .etr_assert(is.numeric(x$time) && length(x$time)==n &&
       all(is.finite(x$time)) && all(diff(x$time)>0),
       "recurrence time must match state count and be strictly increasing")
    .etr_assert(is.numeric(x$theiler) && length(x$theiler)==1L &&
       x$theiler>=0 && x$theiler==as.integer(x$theiler),
       "recurrence Theiler window must be a nonnegative integer")
    .etr_assert(!any(m & abs(row(m)-col(m))<=x$theiler),
       "recurrence contains forbidden Theiler-window edges")
  }
  invisible(x)
}

.etr_recurrence_quantifiers_full <- function(rec,min_diagonal_length=2L,min_vertical_length=2L){
  out<-etr_rqa_metrics(rec,min_diagonal_length,min_vertical_length)
  m<-rec$matrix
  if(inherits(m,"sparseMatrix")) {
    # Sparse etr_rqa_metrics already computes exact source-style center mass.
    out$min_diagonal_length<-as.integer(min_diagonal_length)
    out$min_vertical_length<-as.integer(min_vertical_length)
    return(out)
  }
  if(identical(rec$kind,"auto")){
    idx<-which(m & upper.tri(m),arr.ind=TRUE)
    out$center_of_recurrence_mass <- if(nrow(idx))
      100*mean(idx[,2L]-idx[,1L])/max(nrow(m)-1,1L) else NaN
  }else out$center_of_recurrence_mass<-NaN
  out$min_diagonal_length<-as.integer(min_diagonal_length)
  out$min_vertical_length<-as.integer(min_vertical_length)
  out
}

# Python 1.2 recurrence_networks.py and joint_recurrence.py accept CSR
# recurrence source matrices. Validate a native Matrix sparse analogue without
# allocating n-by-n dense arrays, and preserve the declared Theiler contract.
# Matrix::summary can return an atomic zero-length object for a completely
# empty sparse matrix on some Matrix versions. Normalize all COO reads in one
# place so zero-edge networks and joint RQA retain the Python CSR semantics.
# Matrix::nnzero is namespace-qualified; do not rely on S3 base dispatch.
.etr_sparse_recurrence_entries <- function(matrix) {
  .etr_assert(inherits(matrix,"sparseMatrix"),
    "sparse entry enumeration requires a Matrix sparse matrix")
  if (Matrix::nnzero(matrix) == 0L)
    return(data.frame(i=integer(0L), j=integer(0L), x=numeric(0L)))
  entries <- Matrix::summary(matrix)
  .etr_assert(is.list(entries) &&
    all(c("i","j","x") %in% names(entries)),
    "sparse Matrix summary must expose i, j, x fields")
  entries
}

.etr_recurrence_sparse_source <- function(x) {
  .etr_assert(inherits(x,"etr_recurrence") &&
    identical(x$kind,"auto") && inherits(x$matrix,"sparseMatrix"),
    "auto recurrence requires a native sparse Matrix source")
  .etr_assert(requireNamespace("Matrix",quietly=TRUE),
    "Matrix package is required for sparse recurrence sources")
  n<-nrow(x$matrix)
  .etr_assert(n>=2L && n==ncol(x$matrix),
    "sparse auto recurrence requires at least two square state nodes")
  .etr_assert(is.numeric(x$time) && length(x$time)==n &&
    all(is.finite(x$time)) && all(diff(x$time)>0),
    "sparse auto recurrence time must be finite and strictly increasing")
  .etr_assert(is.character(x$time_unit)&&length(x$time_unit)==1L&&
    !is.na(x$time_unit)&&nzchar(x$time_unit),
    "sparse auto recurrence requires a time_unit")
  .etr_assert(is.numeric(x$theiler) && length(x$theiler)==1L&&
    !is.na(x$theiler) && is.finite(x$theiler) && x$theiler>=0&&
    x$theiler==as.integer(x$theiler),
    "sparse recurrence Theiler window must be a nonnegative integer")
  entries<-.etr_sparse_recurrence_entries(x$matrix)
  .etr_assert(all(!is.na(entries$x)) &&
    (is.logical(entries$x)||all(is.finite(entries$x))),
    "sparse recurrence edges must be finite and non-missing")
  adjacency<-Matrix::drop0(x$matrix!=0)
  # A symmetricMatrix can store only one triangle. Expand to a *sparse*
  # generalMatrix before enumerating graph neighbors and pairs. This also
  # makes sparse-source checks independent of S3/S4 isSymmetric dispatch,
  # which can differ across R/Matrix versions and namespace load paths.
  adjacency<-methods::as(adjacency,"generalMatrix")
  .etr_assert(inherits(adjacency,"sparseMatrix"),
    "sparse recurrence conversion must preserve sparse storage")
  nonzero<-.etr_sparse_recurrence_entries(adjacency)
  # Exact structural symmetry for logical adjacency: (i,j) is present iff
  # (j,i) is present. Sorted triplets use O(E) storage, never O(n^2).
  forward_order<-order(nonzero$i,nonzero$j)
  reverse_order<-order(nonzero$j,nonzero$i)
  .etr_assert(identical(nonzero$i[forward_order],nonzero$j[reverse_order]) &&
    identical(nonzero$j[forward_order],nonzero$i[reverse_order]),
    "sparse auto recurrence requires symmetric adjacency")
  .etr_assert(!any(nonzero$i == nonzero$j),
    "sparse recurrence must exclude the main diagonal")
  .etr_assert(!any(abs(nonzero$i-nonzero$j)<=x$theiler),
    "sparse recurrence contains forbidden Theiler-window edges")
  adjacency
}

# Materialize only an explicitly bounded binary recurrence matrix. Avoid
# base::as.matrix() on optional Matrix S4 classes: under package namespace-only
# loading, its S3 registration is not guaranteed across R/Matrix versions.
# This conversion is only invoked after n <= 2500 has been verified.
.etr_recurrence_sparse_dense_bounded <- function(adjacency) {
  nz<-.etr_sparse_recurrence_entries(methods::as(adjacency,"generalMatrix"))
  out<-matrix(FALSE,nrow(adjacency),ncol(adjacency))
  if(nrow(nz))out[cbind(nz$i,nz$j)]<-TRUE
  out
}

# Sparse COO line-RQA engine matching frozen Python 1.2 recurrence.py.
# Group by diagonal offset (j-i) or column (j) and find consecutive rows.
# O(E log E) time, O(E) memory; never allocate an n-by-n logical matrix.
.etr_sparse_rqa_run_lengths <- function(group, position) {
  if (!length(group)) return(integer(0L))
  ord <- order(group, position)
  g <- as.integer(group[ord]); position <- as.integer(position[ord])
  # Duplicate nonzeros are already coalesced by Matrix CSR/CSC canonicalization.
  start <- c(TRUE, diff(g) != 0L | diff(position) != 1L)
  indices <- which(start)
  as.integer(diff(c(indices, length(g) + 1L)))
}

.etr_sparse_rqa_entropy <- function(lengths) {
  if (!length(lengths)) return(NaN)
  counts <- as.numeric(table(lengths))
  probabilities <- counts / sum(counts)
  -sum(probabilities * log(probabilities))
}

.etr_sparse_auto_rqa <- function(recurrence, min_diagonal_length,
                                  min_vertical_length) {
  .etr_assert(identical(recurrence$kind,"auto"),
    "sparse line-RQA currently requires auto recurrence")
  adj <- .etr_recurrence_sparse_source(recurrence)
  dt <- diff(as.numeric(recurrence$time))
  step <- stats::median(dt)
  # Python embedding._regular_step uses np.allclose(rtol=1e-6,
  # atol=max(1e-12, abs(step)*1e-9)). Irregular sampling needs regularization.
  .etr_assert(all(abs(dt-step) <= (1e-6*abs(step) +
      max(1e-12, abs(step)*1e-9))),
    "line-based RQA requires an approximately regular time/index grid")
  nz <- .etr_sparse_recurrence_entries(adj)
  upper <- nz$i < nz$j
  n_upper <- sum(upper)
  n_all <- nrow(nz)
  diag_all <- .etr_sparse_rqa_run_lengths(
    nz$j[upper]-nz$i[upper],nz$i[upper])
  vert_all <- .etr_sparse_rqa_run_lengths(nz$j,nz$i)
  diagonal <- diag_all[diag_all>=min_diagonal_length]
  vertical <- vert_all[vert_all>=min_vertical_length]
  det <- if(n_upper) sum(diagonal)/n_upper else NaN
  lam <- if(n_all) sum(vertical)/n_all else NaN
  corm <- if(n_upper)
    100 * sum(as.double(nz$j[upper])-nz$i[upper]) /
      (max(nrow(adj)-1,1L)*n_upper) else NaN
  .etr_assert(is.numeric(recurrence$recurrence_rate) &&
    length(recurrence$recurrence_rate)==1L &&
    is.finite(recurrence$recurrence_rate),
    "sparse recurrence_rate must be a finite scalar")
  list(recurrence_rate=as.numeric(recurrence$recurrence_rate),
    determinism=det,
    mean_diagonal_length=if(length(diagonal)) mean(diagonal) else NaN,
    max_diagonal_length=if(length(diagonal)) as.integer(max(diagonal)) else 0L,
    diagonal_entropy=.etr_sparse_rqa_entropy(diagonal),
    laminarity=lam,
    trapping_time=if(length(vertical)) mean(vertical) else NaN,
    max_vertical_length=if(length(vertical)) as.integer(max(vertical)) else 0L,
    center_of_recurrence_mass=corm,
    n_recurrence_points=as.integer(n_upper),
    n_diagonal_lines=as.integer(length(diagonal)),
    n_vertical_lines=as.integer(length(vertical)),
    min_diagonal_length=as.integer(min_diagonal_length),
    min_vertical_length=as.integer(min_vertical_length),
    provenance=list(operation="rqa_metrics",kind="auto",
      sampling_contract="approximately_regular_grid",
      sampling_step_a=as.numeric(step),
      sparse_nnz=as.integer(n_all),dense_materialized=FALSE,
      python_source="recurrence.py:rqa_metrics",
      source_rqa_semantics="upper_diagonals_full_verticals"))
}

#' Compute undirected recurrence-network topology in R
#' @param recurrence Native auto etr_recurrence with symmetric off-diagonal matrix.
#' @param adjacency_storage Either `dense` (default, backward compatible) or
#'   `sparse` (an optional Matrix-package logical sparse column matrix).
#'   Sparse output preserves network topology and source-style adjacency
#'   without requiring a Python scipy CSR object. The input recurrence
#'   remains an explicitly defined native R representation.
#' @return etr_recurrence_network list with topology and source provenance.
#'   Native adjacency remains a dense logical matrix (up to 2500 states),
#'   by default. Sparse output supports 10000 dense-source states or
#'   100000 already-sparse source states without a dense conversion.
#'   Triangle counting uses forward-neighbor intersections and
#'   component enumeration uses queue-head breadth-first search.
#' @export
etr_recurrence_network <- function(recurrence,
    adjacency_storage=c("dense","sparse")){
  sparse_source<-inherits(recurrence$matrix,"sparseMatrix")
  if(sparse_source) adj<-.etr_recurrence_sparse_source(recurrence)
  else .etr_recurrence_internal(recurrence,"auto")
  adjacency_storage<-match.arg(adjacency_storage)
  if(identical(adjacency_storage,"sparse"))
    .etr_assert(requireNamespace("Matrix",quietly=TRUE),
      "Matrix package is required for sparse recurrence adjacency")
  if(!sparse_source)adj<-recurrence$matrix
  n<-nrow(adj)
  # Dense sources still have the original 2500-node guard; legacy dense
  # sources requested in sparse-output mode retain their 10000-node guard.
  # Already-sparse sources can contain many more states without an n^2 copy.
  max_nodes<-if(identical(adjacency_storage,"dense"))2500L else
    if(sparse_source)100000L else 10000L
  .etr_assert(n<=max_nodes,
    paste0("native ",adjacency_storage,
      " recurrence-network analysis limited to ",max_nodes," nodes"))
  if(sparse_source) {
    nz<-.etr_sparse_recurrence_entries(adj)
    neighbors<-replicate(n,integer(0),simplify=FALSE)
    if(nrow(nz)) {
      split_neighbors<-split(as.integer(nz$j),as.integer(nz$i))
      neighbors[as.integer(names(split_neighbors))]<-
        lapply(split_neighbors,sort.int)
    }
    degrees<-as.integer(vapply(neighbors,length,integer(1L)))
  }else {
    degrees<-as.integer(rowSums(adj))
    neighbors<-lapply(seq_len(n),function(i)which(adj[i,]))
  }
  triples<-as.double(degrees)*(as.double(degrees)-1)/2
  # Count triangles through forward-neighbor intersections in O(n+E)
  # storage rather than forming dense adjacency submatrices.
  forward<-lapply(seq_len(n),function(i)neighbors[[i]][neighbors[[i]]>i])
  triangles_by_node<-numeric(n)
  n_triangles<-0
  for(i in seq_len(n)){
    ahead<-forward[[i]]
    if(length(ahead)<2L)next
    for(j in ahead){
      common<-intersect(ahead,forward[[j]])
      if(!length(common))next
      k<-length(common)
      triangles_by_node[i]<-triangles_by_node[i]+k
      triangles_by_node[j]<-triangles_by_node[j]+k
      triangles_by_node[common]<-triangles_by_node[common]+1
      n_triangles<-n_triangles+k
    }
  }
  clustering<-ifelse(triples>0,triangles_by_node/pmax(triples,1),0)
  labels<-rep(-1L,n);component<-0L
  # Queue-head BFS avoids repeatedly copying and shrinking a frontier,
  # preserving SciPy's ascending-root component enumeration.
  queue<-integer(n)
  for(i in seq_len(n))if(labels[i]<0L){
    head<-1L;tail<-1L;queue[tail]<-i
    labels[i]<-component
    while(head<=tail){
      cur<-queue[head];head<-head+1L
      nearby<-neighbors[[cur]]
      nearby<-nearby[labels[nearby]<0L]
      if(length(nearby)){
        labels[nearby]<-component
        ix<-tail+seq_along(nearby)
        queue[ix]<-nearby
        tail<-tail+length(nearby)
      }
    }
    component<-component+1L
  }
  sizes<-as.integer(tabulate(labels+1L,nbins=component))
  edge_count<-as.double(sum(degrees))/2
  e<-if(edge_count<=.Machine$integer.max)as.integer(edge_count)
    else edge_count
  density<-e/(as.double(n)*(n-1)/2)
  transitivity<-if(sum(triples)>0)
    as.numeric(3*n_triangles/sum(triples)) else NaN
  # The core graph summaries above use the same adjacency regardless of
  # storage. Convert only the returned adjacency, not the estimator.
  # Matrix::Matrix preserves logical semantics and drops absent edges.
  result_adjacency<-if(identical(adjacency_storage,"sparse")) {
    if(sparse_source)adj else Matrix::Matrix(adj,sparse=TRUE)
  }else {
    if(sparse_source).etr_recurrence_sparse_dense_bounded(adj) else adj
  }
  structure(list(
    adjacency=result_adjacency,degree=degrees,
    normalized_degree=as.numeric(degrees)/(n-1),
    local_clustering=as.numeric(clustering),
    component_labels=as.integer(labels),component_sizes=sizes,
    edge_count=e,graph_density=density,
    transitivity=transitivity,
    mean_local_clustering=mean(clustering),
    n_connected_components=as.integer(component),
    largest_component_fraction=max(sizes)/n,
    isolated_node_fraction=mean(degrees==0L),
    # Legacy R-only aliases: retain the initial native graph API without
    # replacing the published Python 1.2 canonical fields. These aliases,
    # and the compatibility node table, are explicit representation gaps.
    n_nodes=as.integer(n),n_edges=as.numeric(e),
    density=as.numeric(density),degrees=as.numeric(degrees),
    triangles=as.numeric(n_triangles),
    component=as.integer(labels)+1L,
    n_components=as.integer(component),
    theiler=as.integer(recurrence$theiler),
    method="undirected_binary_recurrence_network",
    source_recurrence=recurrence,
    provenance=list(operation="recurrence_network",
      network_type="undirected_unweighted_simple_graph",
      node_definition="recurrence_state_time_index",
      edge_definition="retained_off_diagonal_recurrence_pair",
      source_recurrence_provenance=recurrence$provenance,
      source_metric=if(is.null(recurrence$metric))"euclidean" else recurrence$metric,
      source_radius=recurrence$radius,
      source_target_recurrence_rate=recurrence$target_recurrence_rate,
      source_achieved_recurrence_rate=recurrence$recurrence_rate,
      source_theiler_window_samples=as.integer(recurrence$theiler),
      source_state_dimension=recurrence$state_dimension,
      source_time_unit=recurrence$time_unit,
      graph_density_denominator="all_unordered_node_pairs",
      source_recurrence_rate_denominator=recurrence$provenance$recurrence_rate_denominator,
      local_clustering_degree_lt_2=0,
      transitivity_undefined_when_no_connected_triples=TRUE,
      triangle_count=if(n_triangles <= .Machine$integer.max)
        as.integer(n_triangles) else as.numeric(n_triangles),
      dense_adjacency_materialized=identical(adjacency_storage,"dense"),
      native_source_matrix_storage=if(sparse_source)"sparse" else "dense",
      sparse_input_preserved_without_dense_copy=isTRUE(sparse_source)&&
        identical(adjacency_storage,"sparse"),
      native_adjacency_storage=adjacency_storage,
      scipy_csr_identity_claimed=FALSE,
      triangle_count_method="forward_neighbor_intersections",
      connected_components_method="queue_head_breadth_first_search",
      automatic_community_detection=FALSE,
      automatic_dimension_interpretation=FALSE,
      interpretation_boundary=paste(
        "Network topology describes the geometry induced by the",
        "declared recurrence relation; it remains conditional on the",
        "state representation, metric, threshold policy, Theiler",
        "window, and sampling design"),
      source_recurrence_rate=recurrence$recurrence_rate,
      legacy_R_alias_fields_present=TRUE,
      legacy_R_node_clustering_undefined_under_degree_two=TRUE,
      automatic_threshold_selection=FALSE)
  ),class="etr_recurrence_network")
}

#' Node-level recurrence network data frame
#' @param result Native etr_recurrence_network.
#' @export
etr_recurrence_network_node_frame <- function(result){
  .etr_assert(inherits(result,"etr_recurrence_network"),
    "result must be native recurrence network")
  n<-length(result$degree)
  data.frame(
    node_index=seq_len(n)-1L,
    time=result$source_recurrence$time,
    degree=as.integer(result$degree),
    normalized_degree=result$normalized_degree,
    local_clustering=result$local_clustering,
    component=as.integer(result$component_labels),
    component_size=result$component_sizes[result$component_labels+1L])
}

#' Global recurrence-network summary data frame
#' @inheritParams etr_recurrence_network_node_frame
#' @export
etr_recurrence_network_summary_frame <- function(result){
  .etr_assert(inherits(result,"etr_recurrence_network"),
    "result must be native recurrence network")
  data.frame(n_nodes=as.integer(length(result$degree)),
    edge_count=result$edge_count,graph_density=result$graph_density,
    source_achieved_recurrence_rate=result$source_recurrence$recurrence_rate,
    mean_degree=mean(result$degree),
    mean_local_clustering=result$mean_local_clustering,
    transitivity=result$transitivity,
    n_connected_components=result$n_connected_components,
    largest_component_fraction=result$largest_component_fraction,
    isolated_node_fraction=result$isolated_node_fraction)
}

#' Synchronized logical intersection of auto recurrence matrices
#' @param recurrences List of at least two native auto etr_recurrence objects.
#' @param labels Optional unique subsystem labels.
#' @return Native etr_joint_recurrence result, without silent time alignment.
#' @export
etr_joint_recurrence_matrix <- function(recurrences,labels=NULL){
  .etr_assert(is.list(recurrences) && length(recurrences)>=2L,
    "joint recurrence requires at least two recurrence components")
  source_sparse<-vapply(recurrences,function(x)
    inherits(x$matrix,"sparseMatrix"),logical(1L))
  for(i in seq_along(recurrences)) {
    if(source_sparse[i]) .etr_recurrence_sparse_source(recurrences[[i]])
    else .etr_recurrence_internal(recurrences[[i]],"auto")
  }
  first<-recurrences[[1L]]
  .etr_assert(is.character(first$time_unit) &&
     length(first$time_unit)==1L && nzchar(first$time_unit),
     "joint recurrence components require explicit time_unit")
  n<-nrow(first$matrix)
  for(x in recurrences[-1L]){
    .etr_assert(identical(dim(x$matrix),dim(first$matrix)),
      "joint recurrence requires identical matrix shapes")
    .etr_assert(identical(x$time,first$time),
      "joint recurrence requires the exact same time grid")
    .etr_assert(identical(as.integer(x$theiler),as.integer(first$theiler)),
      "joint recurrence requires the same Theiler window")
    .etr_assert(identical(x$time_unit,first$time_unit),
      "joint recurrence requires the same time_unit")
  }
  if(is.null(labels))labels<-paste0("component_",seq_along(recurrences))
  .etr_assert(is.character(labels) && length(labels)==length(recurrences) &&
    all(nzchar(labels)) && !anyNA(labels) && !anyDuplicated(labels),
    "labels must be distinct nonempty strings, one per component")
  # Closed-form count avoids generating n-by-n row/col masks for sparse
  # sources, as in frozen Python _eligible_auto_pairs.
  remaining<-as.double(n)-as.double(first$theiler)-1
  eligible<-if(remaining>0)remaining*(remaining+1)/2 else 0
  .etr_assert(eligible>0L,
    "Theiler window leaves no eligible joint recurrence pairs")
  if(any(source_sparse)) {
    .etr_assert(requireNamespace("Matrix",quietly=TRUE),
      "Matrix package is required for sparse joint recurrence")
    sources<-lapply(seq_along(recurrences),function(i){
      a<-recurrences[[i]]$matrix
      if(source_sparse[i]) .etr_recurrence_sparse_source(recurrences[[i]])
      else Matrix::Matrix(a,sparse=TRUE)
    })
    m<-Reduce(function(a,b)Matrix::drop0(a & b),sources)
    nz<-.etr_sparse_recurrence_entries(m)
    pts<-as.double(sum(nz$i<nz$j))
  }else {
    m<-Reduce("&",lapply(recurrences,function(x)x$matrix))
    pts<-sum(m[upper.tri(m)])
  }
  structure(list(
    matrix=m,time=first$time,
    component_recurrences=recurrences,component_labels=labels,
    joint_recurrence_rate=pts/eligible,
    n_joint_recurrent_pairs=if(pts<=.Machine$integer.max)
      as.integer(pts) else as.double(pts),
    eligible_pair_count=if(eligible<=.Machine$integer.max)
      as.integer(eligible) else as.double(eligible),
    theiler_window_samples=as.integer(first$theiler),
    time_unit=first$time_unit,
    provenance=list(operation="joint_recurrence_matrix",
      definition="elementwise_logical_and_of_synchronized_auto_recurrence_matrices",
      component_labels=labels,component_count=length(recurrences),
      matrix_storage=if(any(source_sparse))"sparse" else "dense",
      sparse_source_components=sum(source_sparse),
      time_alignment="exact_grid_match_required",
      resampling=FALSE,lag_shift=FALSE,
      threshold_harmonization=FALSE,
      recurrence_rate_denominator="eligible_off_diagonal_pairs_outside_shared_theiler_window")
  ),class="etr_joint_recurrence")
}

#' Component-contract table of a joint recurrence
#' @param result Native etr_joint_recurrence result.
#' @export
etr_joint_recurrence_component_frame <- function(result) {
  .etr_assert(inherits(result,"etr_joint_recurrence"),
    "result must be a native joint recurrence")
  r<-result$component_recurrences
  data.frame(label=result$component_labels,
    source_curve_ids=I(lapply(r,function(x)x$curve_ids)),
    metric=vapply(r,function(x)if(is.null(x$metric))"euclidean" else x$metric,character(1L)),
    radius=vapply(r,function(x)as.numeric(x$radius),numeric(1L)),
    target_recurrence_rate=vapply(r,function(x)
      if(is.null(x$target_recurrence_rate))NA_real_
      else as.numeric(x$target_recurrence_rate),numeric(1L)),
    achieved_recurrence_rate=vapply(r,function(x)x$recurrence_rate,numeric(1L)),
    state_dimension=as.integer(vapply(r,function(x)x$state_dimension,numeric(1L))),
    theiler_window_samples=as.integer(vapply(r,function(x)x$theiler,integer(1L))),
    time_unit=vapply(r,function(x)x$time_unit,character(1L)))
}

#' Line-based quantification on the synchronized joint recurrence
#' @inheritParams etr_joint_recurrence_component_frame
#' @param min_diagonal_length,min_vertical_length Minimum run lengths.
#' @export
etr_joint_rqa_metrics <- function(result,min_diagonal_length=2L,
                                  min_vertical_length=2L){
  .etr_assert(inherits(result,"etr_joint_recurrence"),
    "result must be a native joint recurrence")
  # Sparse sources run a native coordinate-based line-RQA estimator without
  # dense allocation; source Python CSR uses the same line definitions.
  rec<-structure(list(matrix=result$matrix,kind="auto",
    recurrence_rate=result$joint_recurrence_rate,
    theiler=result$theiler_window_samples,
    time=result$time,time_unit=result$time_unit),class="etr_recurrence")
  out<-.etr_recurrence_quantifiers_full(rec,min_diagonal_length,min_vertical_length)
  out$provenance<-c(list(operation="joint_rqa_metrics",
    joint_recurrence_provenance=result$provenance),
    if(inherits(result$matrix,"sparseMatrix"))
      list(native_sparse_rqa=TRUE,dense_materialized=FALSE) else list())
  out
}

#' Cross recurrence quantification with a complete native RQA result
#' @param recurrence A native cross recurrence result.
#' @param min_diagonal_length,min_vertical_length Positive integer thresholds.
#' @export
etr_cross_rqa_metrics <- function(recurrence,min_diagonal_length=2L,
                                  min_vertical_length=2L){
  .etr_recurrence_internal(recurrence,"cross")
  out<-.etr_recurrence_quantifiers_full(recurrence,min_diagonal_length,min_vertical_length)
  out$provenance<-list(operation="rqa_metrics",kind="cross")
  out
}

#' Recurrence-rate cumulative profile over prespecified positive radii
#' @param source Complete native etr_trajectory_set.
#' @param curve Curve identifier or one-based index.
#' @param radii Strictly increasing positive finite vector.
#' @param metric "euclidean", "cityblock" or "chebyshev".
#' @param theiler_window Nonnegative integer excluded sample lag.
#' @param theiler_window_units Currently "samples".
#' @param dimensions Named channel subset, NULL selects all.
#' @export
etr_recurrence_radius_profile <- function(source,curve=1L,radii,
    metric="euclidean",theiler_window=0L,theiler_window_units="samples",
    dimensions=NULL){
  if(inherits(source,"etr_delay_embedding_set")){
    .etr_assert(is.null(dimensions),
      "dimensions cannot be supplied for an already embedded state space")
    .etr_assert(is.array(source$values)&&length(dim(source$values))==3L&&
      is.numeric(source$values)&&is.character(source$state_names)&&
      length(source$state_names)==dim(source$values)[3L],
      "embedded radius profile requires numeric 3D named states")
    # Source _state_from_source checks only the selected embedded curve;
    # never reject an otherwise valid profile for unrelated missing states.
    selected<-if(is.character(curve))match(curve,source$curve_ids) else curve
    .etr_assert(is.numeric(selected)&&length(selected)==1L&&
      is.finite(selected)&&selected==as.integer(selected)&&
      selected %in% seq_along(source$curve_ids),
      "curve must identify an existing embedded trajectory")
    .etr_assert(all(is.finite(source$values[selected,,,drop=FALSE])),
      "embedded radius profile requires complete finite selected states")
    proxy<-etr_trajectory_set(source$time,
      source$values[selected,,,drop=FALSE],source$curve_ids[selected],
      source$state_names,coordinate_system=source$coordinate_system,
      time_unit=source$time_unit)
    answer<-etr_recurrence_radius_profile(proxy,1L,radii,metric,
      theiler_window,theiler_window_units)
    answer$provenance$source_kind<-"DelayEmbeddingResult"
    answer$provenance$state_names<-source$state_names
    answer$provenance$embedding_dimension<-source$embedding_dimension
    answer$provenance$delay_samples<-source$delay_samples
    answer$provenance$delay_time<-source$delay_time
    answer$provenance$source_provenance<-source$provenance
    return(answer)
  }
  etr_validate(source,require_complete=is.null(dimensions))
  .etr_assert(is.numeric(radii) && length(radii)>=2L &&
    all(is.finite(radii)) && all(radii>0) && all(diff(radii)>0),
    "radii must be strictly increasing positive finite values")
  .etr_assert(metric %in% c("euclidean","cityblock","chebyshev"),
    "metric must be euclidean, cityblock or chebyshev")
  if(is.character(curve))curve<-match(curve,source$curve_ids)
  .etr_assert(length(curve)==1L && !is.na(curve) &&
    curve %in% seq_along(source$curve_ids),
    "curve must identify an existing trajectory")
  tt<-.etr_source_time_unit_samples(source$time,theiler_window,
    theiler_window_units,source$time_unit,"theiler_window",
    allow_zero=TRUE)
  if(is.null(dimensions))dimensions<-source$dimension_names
  .etr_assert(is.character(dimensions) && length(dimensions)>0L &&
    all(dimensions %in% source$dimension_names) && !anyDuplicated(dimensions),
    "dimensions must be distinct named channels")
  idx<-match(dimensions,source$dimension_names)
  n<-length(source$time)
  .etr_assert(n<=2500L,"native dense recurrence radius profile limited to 2500 states")
  # Exact eligible-pair closed form: sum_{lag=theiler+1}^{n-1}(n-lag).
  # Avoid allocating three extra n-by-n matrices merely to count pairs.
  eligible<-as.double(n-tt)*as.double(n-tt-1L)/2
  .etr_assert(eligible>0L,"Theiler window leaves no eligible pairs")
  values<-matrix(source$values[curve,,idx,drop=FALSE],nrow=n,ncol=length(idx))
  .etr_assert(all(is.finite(values)),
    "recurrence radius profile requires complete finite selected states")
  # Preallocate pairwise distance storage instead of repeatedly
  # copying growing vectors inside the O(n^2) state-pair loop.
  distances<-numeric(eligible)
  excluded<-numeric(n*(n-1)/2-eligible)
  keep_i<-0L;drop_i<-0L
  for(i in seq_len(n-1L))for(j in (i+1L):n) {
    delta<-abs(values[i,]-values[j,])
    d<-switch(metric,euclidean=sqrt(sum(delta^2)),
              cityblock=sum(delta),chebyshev=max(delta))
    if(j-i<=tt){
      drop_i<-drop_i+1L
      excluded[drop_i]<-d
    } else {
      keep_i<-keep_i+1L
      distances[keep_i]<-d
    }
  }
  .etr_assert(keep_i==eligible &&
    drop_i==length(excluded),"recurrence profile eligibility count mismatch")
  counts<-vapply(radii,function(z)sum(distances<=z),numeric(1L))
  ex<-vapply(radii,function(z)sum(excluded<=z),numeric(1L))
  shell<-diff(c(0,counts))
  table<-data.frame(previous_radius=c(NA_real_,head(radii,-1L)),
    radius=radii,shell_pair_count=as.integer(shell),
    shell_pair_fraction=shell/eligible,
    cumulative_recurrent_pairs=as.integer(counts),
    recurrence_rate=counts/eligible,
    excluded_theiler_pairs_within_radius=as.integer(ex))
  structure(list(table=table,curve_id=source$curve_ids[curve],
    metric=metric,theiler_window_samples=tt,
    state_dimension=as.integer(ncol(values)),
    eligible_pair_count=as.integer(eligible),
    provenance=list(operation="recurrence_radius_profile",
      source_kind="TrajectorySet",state_names=dimensions,
      coordinate_system=source$coordinate_system,
      source_provenance=source$provenance,
      metric=metric,theiler_window_samples=tt,
      radius_grid_sorted_or_deduplicated=FALSE,
      threshold_operator="<=",recurrence_rate_scale="0_to_1",
      maximum_radius_coverage_fraction=as.numeric(tail(counts,1L)/eligible),
      full_distance_distribution_captured=isTRUE(all.equal(
        as.numeric(tail(counts,1L)/eligible),1,tolerance=1e-8)),
      distance_matrix_materialized=FALSE,
      declared_theiler_window=theiler_window,
      declared_theiler_window_units=theiler_window_units,
      radius_grid_declared_by_user=TRUE,
      automatic_radius_selection=FALSE)),
    class="etr_recurrence_radius_profile")
}

# Reproduce frozen eyetrajectoriespy 1.2.0 recurrence.py
# _auto_radius_for_target: 48 inclusive-radius bisections over eligible
# Theiler-excluded unordered state pairs. This is pure native R; no bridge.
.etr_windowed_rqa_source_target_radius<-function(x,target,metric,theiler,
    curve=1L){
  .etr_assert(is.numeric(target)&&length(target)==1L&&
    is.finite(target)&&target>0&&target<1,
    "target_recurrence_rate must be strictly between 0 and 1")
  states<-.etr_curve(x,curve)
  .etr_assert(is.matrix(states)&&nrow(states)>=2L&&
    nrow(states)<=2500L,"native recurrence requires 2 to 2500 states")
  n<-nrow(states)
  .etr_assert(theiler<n-1L,
    "Theiler window leaves no eligible recurrence pairs")
  spread<-apply(states,2L,function(z)max(z)-min(z))
  high<-switch(metric,euclidean=sqrt(sum(spread^2)),
    cityblock=sum(abs(spread)),chebyshev=max(abs(spread)))
  .etr_assert(is.finite(high)&&high>0,
    "recurrence analysis requires non-constant state vectors")
  distances<-.etr_distance_matrix(states,states,metric=metric)
  eligible<-upper.tri(distances) &
    (abs(row(distances)-col(distances))>theiler)
  d<-as.numeric(distances[eligible])
  .etr_assert(length(d)>0L,
    "Theiler window leaves no eligible recurrence pairs")
  low<-0
  for(iter in seq_len(48L)){
    mid<-(low+high)/2
    rr<-sum(d<=mid)/length(d)
    if(rr<target)low<-mid else high<-mid
  }
  high
}

#' Native sliding-window RQA with fixed or target-rate radius
#' @param trajectories Complete native common-grid trajectories.
#' @param curve Curve ID or one-based index.
#' @param window,step Positive window/step lengths, in samples or physical time.
#' @param radius Optional positive finite radius; specify exactly one of
#'   radius or target_recurrence_rate.
#' @param target_recurrence_rate Optional target probability in (0, 1).
#'   Uses the frozen Python 1.2 inclusive-radius 48-step bisection on
#'   Theiler-eligible state pairs. Distance ties can cause overshoot.
#' @param metric One of "cityblock", "euclidean" or "chebyshev".
#' @param theiler_window Nonnegative integer Theiler lag.
#' @param dimensions Optional selected channels.
#' @param min_diagonal_length,min_vertical_length Run-length thresholds.
#' @export
etr_windowed_rqa <- function(trajectories,curve=1L,window,step,
    window_units="samples",step_units="samples",radius=NULL,
    target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L){
  etr_validate(trajectories,require_complete=FALSE)
  .etr_assert(is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%c("cityblock","euclidean","chebyshev"),
    "metric must be one of cityblock, euclidean, chebyshev")
  .etr_assert(xor(is.null(radius),is.null(target_recurrence_rate)),
    "supply exactly one of radius or target_recurrence_rate")
  if(!is.null(radius))
    .etr_assert(is.numeric(radius)&&length(radius)==1L&&
      is.finite(radius)&&radius>0,
      "radius must be a positive finite value")
  else
    .etr_assert(is.numeric(target_recurrence_rate)&&
      length(target_recurrence_rate)==1L&&
      is.finite(target_recurrence_rate)&&
      target_recurrence_rate>0&&target_recurrence_rate<1,
      "target_recurrence_rate must be strictly between 0 and 1")
  window<-.etr_source_time_unit_samples(trajectories$time,window,
    window_units,trajectories$time_unit,"window")
  step<-.etr_source_time_unit_samples(trajectories$time,step,
    step_units,trajectories$time_unit,"step")
  theiler_window<-.etr_source_time_unit_samples(trajectories$time,
    theiler_window,theiler_window_units,trajectories$time_unit,
    "theiler_window",allow_zero=TRUE)
  .etr_assert(is.numeric(window) && length(window)==1L &&
    is.finite(window) && window>=3L && window==as.integer(window),
    "window must be an integer at least three")
  .etr_assert(is.numeric(step) && length(step)==1L &&
    is.finite(step) && step>=1L && step==as.integer(step) &&
    step<=window,"step must be an integer between one and window")
  if(is.character(curve))curve<-match(curve,trajectories$curve_ids)
  .etr_assert(length(curve)==1L && !is.na(curve) &&
    curve %in% seq_along(trajectories$curve_ids),
    "curve must identify an existing trajectory")
  if(is.null(dimensions))dimensions<-trajectories$dimension_names
  .etr_assert(is.character(dimensions) && length(dimensions)>=1L &&
    all(dimensions %in% trajectories$dimension_names) &&
    !anyDuplicated(dimensions),"dimensions must select distinct named channels")
  cols<-match(dimensions,trajectories$dimension_names)
  # Frozen Python's recurrence_matrix checks only the state channels of
  # the requested curve. Missing gaze on another curve or an unused channel
  # must not invalidate this otherwise complete selected state space.
  .etr_assert(all(is.finite(trajectories$values[curve,,cols,drop=FALSE])),
    "windowed recurrence requires complete finite selected curve states")
  n<-length(trajectories$time)
  .etr_assert(window<=n,"window is longer than available trajectory")
  starts<-seq.int(1L,n-as.integer(window)+1L,by=as.integer(step))
  rows<-lapply(starts,function(i){
    hi<-i+as.integer(window)-1L
    x<-etr_trajectory_set(
      trajectories$time[i:hi],
      array(trajectories$values[curve,i:hi,cols,drop=FALSE],
        dim=c(1L,as.integer(window),length(cols))),
      trajectories$curve_ids[curve],dimensions,
      trajectories$metadata[curve,,drop=FALSE],
      trajectories$coordinate_system,trajectories$time_unit,
      trajectories$provenance)
    chosen_radius<-if(is.null(radius))
      .etr_windowed_rqa_source_target_radius(x,target_recurrence_rate,
        metric,theiler_window) else radius
    rec<-etr_recurrence_matrix(x,curve=1L,radius=chosen_radius,
                               theiler=theiler_window,metric=metric)
    if(!is.null(target_recurrence_rate)) {
      rec$target_recurrence_rate<-target_recurrence_rate
      rec$provenance$radius_policy<-"target_recurrence_rate"
      rec$provenance$target_recurrence_rate<-target_recurrence_rate
      rec$provenance$target_rate_tie_policy<-
        "inclusive-radius bisection; achieved recurrence rate is retained because distance ties can prevent an exact target"
    }
    a<-.etr_recurrence_quantifiers_full(rec,min_diagonal_length,min_vertical_length)
    data.frame(start_index=as.integer(i-1L),stop_index=as.integer(hi),
      start_time=x$time[1L],end_time=x$time[length(x$time)],
      center_time=(x$time[1L]+tail(x$time,1L))/2,
      radius=rec$radius,
      recurrence_rate=a$recurrence_rate,
      determinism=a$determinism,
      mean_diagonal_length=a$mean_diagonal_length,
      max_diagonal_length=as.integer(a$max_diagonal_length),
      diagonal_entropy=a$diagonal_entropy,
      laminarity=a$laminarity,trapping_time=a$trapping_time,
      max_vertical_length=as.integer(a$max_vertical_length),
      center_of_recurrence_mass=a$center_of_recurrence_mass)
  })
  table<-do.call(rbind,rows);rownames(table)<-NULL
  drop<-n-max(starts+as.integer(window)-1L)
  structure(list(table=table,
    window_samples=as.integer(window),step_samples=as.integer(step),
    dropped_tail_samples=as.integer(drop),
    time_unit=trajectories$time_unit,
    provenance=list(operation="windowed_rqa",
      source_provenance=trajectories$provenance,
      curve_id=trajectories$curve_ids[curve],
      window_samples=as.integer(window),
      step_samples=as.integer(step),
      dropped_tail_samples=as.integer(drop),
      radius_policy=if(is.null(radius))
        "target_recurrence_rate" else "fixed",
      target_recurrence_rate=target_recurrence_rate,metric=metric,
      theiler_window_samples=theiler_window,
      declared_time_window_units=window_units,
      declared_time_step_units=step_units,
      declared_theiler_window_units=theiler_window_units,
      tail_policy="full_windows_only_with_explicit_tail_count")),
    class="etr_windowed_rqa")
}

#' Turn fixed-radius windowed RQA into native functional trajectories
#' @param trajectories Complete common-grid native R trajectories.
#' @param metrics Unique selected RQA summary names.
#' @param undefined_policy "raise" or "keep" for undefined values.
#' @inheritParams etr_windowed_rqa
#' @export
etr_windowed_rqa_trajectory_set <- function(trajectories,metrics,window,step,
    window_units="samples",step_units="samples",radius=NULL,
    target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L,
    undefined_policy="raise"){
  .etr_assert(is.character(metrics) && length(metrics)>0L &&
    !anyNA(metrics) && !anyDuplicated(metrics),
    "metrics must contain unique RQA statistic names")
  allowed<-c("recurrence_rate","determinism","mean_diagonal_length",
    "max_diagonal_length","diagonal_entropy","laminarity",
    "trapping_time","max_vertical_length","center_of_recurrence_mass")
  .etr_assert(all(metrics %in% allowed),"Unknown functional RQA metrics")
  # Resolve conflicting radius policies before validating a metric that is
  # undefined under target-density control. This matches the underlying
  # windowed RQA parameter contract and makes user errors unambiguous.
  .etr_assert(xor(is.null(radius),is.null(target_recurrence_rate)),
    "supply exactly one of radius or target_recurrence_rate")
  .etr_assert(is.null(target_recurrence_rate) ||
    !("recurrence_rate" %in% metrics),
    "recurrence_rate cannot be a functional outcome when target_recurrence_rate controls density")
  .etr_assert(undefined_policy %in% c("raise","keep"),
    "undefined_policy must be 'raise' or 'keep'")
  etr_validate(trajectories,require_complete=FALSE)
  per<-lapply(seq_along(trajectories$curve_ids),function(i)
    etr_windowed_rqa(trajectories,i,window,step,window_units,
      step_units,radius,target_recurrence_rate,metric,
      theiler_window,theiler_window_units,dimensions,
      min_diagonal_length,min_vertical_length))
  centers<-per[[1L]]$table$center_time
  .etr_assert(length(centers)>=2L,
    "functional windowed RQA requires at least two complete windows")
  n<-length(per);w<-length(centers)
  vals<-array(NA_real_,dim=c(n,w,length(metrics)))
  for(i in seq_len(n))
    vals[i,,]<-as.matrix(per[[i]]$table[,metrics,drop=FALSE])
  bad<-!is.finite(vals)
  if(undefined_policy=="raise")
    .etr_assert(!any(bad),
      "selected windowed RQA metric is undefined; use undefined_policy='keep'")
  # Python uses NaN for undefined; native R stores NA for missing
  # values and explicitly tracks undefined entries as provenance.
  vals[bad]<-NA_real_
  window<-per[[1L]]$window_samples
  step<-per[[1L]]$step_samples
  overlap<-max(as.integer(window)-as.integer(step),0L)
  metric_units<-c(recurrence_rate="proportion",
    determinism="proportion",
    mean_diagonal_length="state_steps",
    max_diagonal_length="state_steps",
    diagonal_entropy="nats",
    laminarity="proportion",trapping_time="state_steps",
    max_vertical_length="state_steps",
    center_of_recurrence_mass="percent_of_sequence_length")
  provenance<-list(operation="windowed_rqa_trajectory_set",
    source_provenance=trajectories$provenance,
    source_coordinate_system=trajectories$coordinate_system,
    source_dimension_names=dimensions,
    metrics=metrics,metric_units=as.list(metric_units[metrics]),
    window_samples=as.integer(window),step_samples=as.integer(step),
    overlap_samples=overlap,
    overlap_fraction=overlap/window,
    overlapping_windows=overlap>0L,
    window_rows_are_independent=FALSE,
    window_center_definition="midpoint_of_first_and_last_observed_sample",
    source_time_support=c(trajectories$time[1L],
      tail(trajectories$time,1L)),
    functional_time_support=c(centers[1L],tail(centers,1L)),
    leading_edge_span=centers[1L]-trajectories$time[1L],
    trailing_edge_span=tail(trajectories$time,1L)-tail(centers,1L),
    edge_policy="full_window_centers_only",
    dropped_tail_samples=per[[1L]]$dropped_tail_samples,
    tail_policy="full_windows_only_with_explicit_tail_count",
    radius_policy=if(is.null(radius))"target_recurrence_rate" else "fixed",
    fixed_radius=radius,
    target_recurrence_rate=target_recurrence_rate,
    recurrence_rate_controlled_by_design=!is.null(target_recurrence_rate),
    distance_metric=metric,theiler_window=theiler_window,
    theiler_window_units=theiler_window_units,
    min_diagonal_length=as.integer(min_diagonal_length),
    min_vertical_length=as.integer(min_vertical_length),
    undefined_policy=undefined_policy,
    undefined_value_count=sum(bad),
    downstream_note=paste(
      "Windowed metrics are functional summaries, not independent",
      "window-level observations; preserve the curve/participant",
      "sampling unit in downstream inference."))
  out<-etr_trajectory_set(centers,vals,trajectories$curve_ids,metrics,
    trajectories$metadata,"rqa_metrics",trajectories$time_unit,
    provenance=provenance)
  structure(list(
    trajectories=out,window_results=per,metrics=metrics,
    window_samples=as.integer(window),step_samples=as.integer(step),
    overlap_samples=as.integer(overlap),
    overlap_fraction=overlap/window,
    dropped_tail_samples=per[[1L]]$dropped_tail_samples,
    time_unit=trajectories$time_unit,
    undefined_policy=undefined_policy,
    provenance=list(operation="windowed_rqa_trajectory_set",
      functional_trajectory_provenance=provenance)
  ),class="etr_windowed_rqa_functional")
}
