#' Frozen Python 1.2 recurrence network scientific record compatibility
#'
#' Source: eyetrajectoriespy==1.2.0 recurrence_networks.py,
#' c1cd95ad718327550f7e55393ff38582872f7a94.
#'
#' Reuses exactly the established native sparse graph algorithm, after
#' validating the postfit RecurrenceResult scientific fields. Does not
#' re-estimate recurrence radii or reconstruct source trajectories.
#' The output adjacency is an R Matrix analogue of Python scipy CSR, not
#' a Python sparse object, and the original source record is retained.
#' @keywords internal
.etr_recurrence_network_python_source <- function(source) {
  .etr_assert(requireNamespace("Matrix",quietly=TRUE),
    "Matrix is required for Python source recurrence network compatibility")
  required <- c("matrix","kind","time_a","time_b",
    "theiler_window_samples","time_unit","metric","radius",
    "target_recurrence_rate","achieved_recurrence_rate",
    "state_dimension","provenance")
  .etr_assert(is.list(source) && all(required %in% names(source)),
    "recurrence must supply the complete Python RecurrenceResult source record")
  .etr_assert(identical(source$kind,"auto"),
    "recurrence networks require an auto-recurrence result")
  m <- source$matrix
  sparse <- inherits(m,"sparseMatrix")
  .etr_assert((is.matrix(m) || sparse) &&
    (is.numeric(m) || is.logical(m) || sparse) &&
    length(dim(m))==2L &&
    nrow(m)>=2L && nrow(m)==ncol(m),
    "recurrence network adjacency must be square with at least two nodes")
  n <- nrow(m)
  if(sparse) {
    stored <- if("x" %in% methods::slotNames(m))
      methods::slot(m,"x") else TRUE
    .etr_assert((is.numeric(stored) || is.logical(stored)) &&
      !anyNA(stored),"recurrence source matrix cannot contain missing entries")
  } else {
    .etr_assert(!anyNA(m) && all(is.finite(as.numeric(m))),
      "recurrence source matrix must be finite and non-missing")
  }
  t_a <- source$time_a
  t_b <- source$time_b
  .etr_assert(is.numeric(t_a) && is.null(dim(t_a)) &&
    is.numeric(t_b) && is.null(dim(t_b)) &&
    length(t_a)==n && length(t_b)==n &&
    !anyNA(t_a) && !anyNA(t_b) &&
    identical(as.numeric(t_a),as.numeric(t_b)),
    "auto-recurrence network requires identical time grids on both axes")
  th <- source$theiler_window_samples
  .etr_assert(is.numeric(th) && length(th)==1L &&
    is.finite(th) && th>=0 && th==floor(th) &&
    th<=.Machine$integer.max,
    "theiler_window_samples must be non-negative")
  .etr_assert(is.numeric(source$radius) &&
    length(source$radius)==1L && is.finite(source$radius) &&
    is.numeric(source$achieved_recurrence_rate) &&
    length(source$achieved_recurrence_rate)==1L &&
    is.finite(source$achieved_recurrence_rate),
    "recurrence radius and achieved recurrence rate must be finite")
  target <- source$target_recurrence_rate
  .etr_assert(is.null(target) || (is.numeric(target) &&
    length(target)==1L && is.finite(target)),
    "target_recurrence_rate must be finite or NULL")
  .etr_assert(is.numeric(source$state_dimension) &&
    length(source$state_dimension)==1L &&
    is.finite(source$state_dimension) &&
    source$state_dimension>=1L &&
    source$state_dimension==floor(source$state_dimension),
    "state_dimension must be positive integer")
  .etr_assert((is.null(source$time_unit) ||
      (is.character(source$time_unit) &&
        length(source$time_unit)==1L && !is.na(source$time_unit))) &&
    is.character(source$metric) &&
    length(source$metric)==1L && !is.na(source$metric) &&
    nzchar(source$metric) && is.list(source$provenance),
    "source recurrence requires time unit, metric and provenance")
  # Python calls recurrence.matrix.astype(bool).tocsr() before all graph
  # checks; R Matrix provides the same unweighted binary adjacency.
  adjacency <- if(sparse) Matrix::drop0(m != 0) else
    Matrix::Matrix(m != 0,sparse=TRUE)
  adjacency <- methods::as(adjacency,"generalMatrix")
  entries <- .etr_sparse_recurrence_entries(adjacency)
  .etr_assert(!any(entries$i==entries$j),
    "recurrence network source must exclude the main diagonal")
  .etr_assert(!any(abs(entries$i-entries$j)<=th),
    "recurrence network source contains edges inside its declared Theiler exclusion")
  # Structural symmetry is checked by the reused native sparse validator.
  # The synthetic monotonically increasing index grid is internal to that
  # validator; source time_a/time_b are retained byte-for-byte in the
  # returned source record and may be nonuniform or repeated (as Python
  # recurrence_networks itself checks only exact axis equality).
  proxy <- structure(list(
    matrix=adjacency,kind="auto",time=as.numeric(seq_len(n)),
    time_unit=if(is.null(source$time_unit))"source_unknown" else
      if(nzchar(source$time_unit))source$time_unit else "source_empty",
    theiler=as.integer(th),
    metric=source$metric,radius=as.numeric(source$radius),
    recurrence_rate=as.numeric(source$achieved_recurrence_rate),
    target_recurrence_rate=target,
    state_dimension=as.integer(source$state_dimension),
    provenance=source$provenance),class="etr_recurrence")
  native <- etr_recurrence_network(proxy,adjacency_storage="sparse",
    python_boundary_mode=FALSE)
  provenance <- list(
    operation="recurrence_network",
    network_type="undirected_unweighted_simple_graph",
    node_definition="recurrence_state_time_index",
    edge_definition="retained_off_diagonal_recurrence_pair",
    source_recurrence_provenance=source$provenance,
    source_metric=source$metric,
    source_radius=as.numeric(source$radius),
    source_target_recurrence_rate=target,
    source_achieved_recurrence_rate=
      as.numeric(source$achieved_recurrence_rate),
    source_theiler_window_samples=as.integer(th),
    source_state_dimension=as.integer(source$state_dimension),
    source_time_unit=source$time_unit,
    graph_density_denominator="all_unordered_node_pairs",
    source_recurrence_rate_denominator=
      source$provenance$recurrence_rate_denominator,
    local_clustering_degree_lt_2=0,
    transitivity_undefined_when_no_connected_triples=TRUE,
    triangle_count=native$provenance$triangle_count,
    dense_adjacency_materialized=FALSE,
    automatic_threshold_selection=FALSE,
    automatic_community_detection=FALSE,
    automatic_dimension_interpretation=FALSE,
    interpretation_boundary=paste(
      "network topology describes the geometry induced by the",
      "declared recurrence relation; it remains conditional on the",
      "state representation, metric, threshold policy, Theiler",
      "window, and sampling design"))
  # Canonical ordered source fields only; no legacy R aliases.
  fields <- c("adjacency","degree","normalized_degree",
    "local_clustering","component_labels","component_sizes",
    "edge_count","graph_density","transitivity",
    "mean_local_clustering","n_connected_components",
    "largest_component_fraction","isolated_node_fraction")
  result <- native[fields]
  result$source_recurrence <- source
  result$provenance <- provenance
  structure(result,class="etr_recurrence_network")
}
