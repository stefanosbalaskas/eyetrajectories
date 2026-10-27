# Stage 8: independent native R recurrence-network and joint-RQA functions.
# Source contracts: eyetrajectoriespy v1.2.0 recurrence.py,
# recurrence_networks.py, joint_recurrence.py and nonlinear_types.py.
# No Python/reticulate runtime calls. Dense research-size guard applies.

.etr8_rec <- function(x,kind="auto"){
  .etr_assert(inherits(x,"etr_recurrence") &&
    is.matrix(x$matrix) && is.logical(x$matrix) &&
    !anyNA(x$matrix) && identical(x$kind,kind),
    paste(kind,"recurrence must be a native etr_recurrence"))
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

.etr8_rqa_full <- function(rec,min_diagonal_length=2L,min_vertical_length=2L){
  out<-etr_rqa_metrics(rec,min_diagonal_length,min_vertical_length)
  m<-rec$matrix
  if(identical(rec$kind,"auto")){
    idx<-which(m & upper.tri(m),arr.ind=TRUE)
    out$center_of_recurrence_mass <- if(nrow(idx))
      100*mean(idx[,2L]-idx[,1L])/max(nrow(m)-1,1L) else NaN
  }else out$center_of_recurrence_mass<-NaN
  out$min_diagonal_length<-as.integer(min_diagonal_length)
  out$min_vertical_length<-as.integer(min_vertical_length)
  out
}

#' Compute undirected recurrence-network topology in R
#' @param recurrence Native auto etr_recurrence with symmetric off-diagonal matrix.
#' @return etr_recurrence_network list with topology and source provenance.
#' @export
etr_recurrence_network <- function(recurrence){
  .etr8_rec(recurrence,"auto")
  adj<-recurrence$matrix;n<-nrow(adj)
  .etr_assert(n<=750L,
    "native dense recurrence-network analysis limited to 750 nodes")
  degrees<-as.integer(rowSums(adj))
  triples<-degrees*(degrees-1)/2
  triangles_by_node<-numeric(n)
  for(i in seq_len(n)) {
    nbr<-which(adj[i,])
    if(length(nbr)>=2L)triangles_by_node[i]<-
      sum(adj[nbr,nbr,drop=FALSE])/2
  }
  n_triangles<-sum(triangles_by_node)/3
  clustering<-ifelse(triples>0,triangles_by_node/pmax(triples,1),0)
  labels<-rep(-1L,n); component<-0L
  for(i in seq_len(n))if(labels[i]<0L){
    frontier<-i;labels[i]<-component
    while(length(frontier)){
      cur<-frontier[1L];frontier<-frontier[-1L]
      nearby<-which(adj[cur,] & labels<0L)
      if(length(nearby)) {
        labels[nearby]<-component
        frontier<-c(frontier,nearby)
      }
    }
    component<-component+1L
  }
  sizes<-as.integer(tabulate(labels+1L,nbins=component))
  e<-as.integer(sum(degrees)/2L)
  density<-e/(n*(n-1)/2)
  transitivity<-if(sum(triples)>0)
    as.numeric(3*n_triangles/sum(triples)) else NaN
  structure(list(
    adjacency=adj,degree=degrees,
    normalized_degree=as.numeric(degrees)/(n-1),
    local_clustering=as.numeric(clustering),
    component_labels=as.integer(labels),component_sizes=sizes,
    edge_count=e,graph_density=density,
    transitivity=transitivity,
    mean_local_clustering=mean(clustering),
    n_connected_components=as.integer(component),
    largest_component_fraction=max(sizes)/n,
    isolated_node_fraction=mean(degrees==0L),
    source_recurrence=recurrence,
    provenance=list(operation="recurrence_network",
      network_type="undirected_unweighted_simple_graph",
      source_radius=recurrence$radius,
      source_theiler_window_samples=as.integer(recurrence$theiler),
      triangle_count=as.integer(n_triangles),
      source_recurrence_rate=recurrence$recurrence_rate,
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
  for(x in recurrences).etr8_rec(x,"auto")
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
  eligible<-sum(upper.tri(first$matrix) &
    abs(row(first$matrix)-col(first$matrix))>first$theiler)
  .etr_assert(eligible>0L,
    "Theiler window leaves no eligible joint recurrence pairs")
  m<-Reduce("&",lapply(recurrences,function(x)x$matrix))
  pts<-sum(m[upper.tri(m)])
  structure(list(
    matrix=m,time=first$time,
    component_recurrences=recurrences,component_labels=labels,
    joint_recurrence_rate=pts/eligible,
    n_joint_recurrent_pairs=as.integer(pts),
    eligible_pair_count=as.integer(eligible),
    theiler_window_samples=as.integer(first$theiler),
    time_unit=first$time_unit,
    provenance=list(operation="joint_recurrence_matrix",
      definition="elementwise_logical_and_of_synchronized_auto_recurrence_matrices",
      component_labels=labels,component_count=length(recurrences),
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
  rec<-structure(list(matrix=result$matrix,kind="auto",
    recurrence_rate=result$joint_recurrence_rate,
    theiler=result$theiler_window_samples,
    time=result$time,time_unit=result$time_unit),class="etr_recurrence")
  out<-.etr8_rqa_full(rec,min_diagonal_length,min_vertical_length)
  out$provenance<-list(operation="joint_rqa_metrics",
    joint_recurrence_provenance=result$provenance)
  out
}

#' Cross recurrence quantification with a complete native RQA result
#' @param recurrence A native cross recurrence result.
#' @param min_diagonal_length,min_vertical_length Positive integer thresholds.
#' @export
etr_cross_rqa_metrics <- function(recurrence,min_diagonal_length=2L,
                                  min_vertical_length=2L){
  .etr8_rec(recurrence,"cross")
  out<-.etr8_rqa_full(recurrence,min_diagonal_length,min_vertical_length)
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
  etr_validate(source,require_complete=TRUE)
  .etr_assert(is.numeric(radii) && length(radii)>=2L &&
    all(is.finite(radii)) && all(radii>0) && all(diff(radii)>0),
    "radii must be strictly increasing positive finite values")
  .etr_assert(identical(theiler_window_units,"samples"),
    "time-based Theiler windows not yet supported by native R profile")
  .etr_assert(metric %in% c("euclidean","cityblock","chebyshev"),
    "metric must be euclidean, cityblock or chebyshev")
  if(is.character(curve))curve<-match(curve,source$curve_ids)
  .etr_assert(length(curve)==1L && !is.na(curve) &&
    curve %in% seq_along(source$curve_ids),
    "curve must identify an existing trajectory")
  .etr_assert(is.numeric(theiler_window) &&
    length(theiler_window)==1L &&
    is.finite(theiler_window) &&
    theiler_window>=0 && theiler_window==as.integer(theiler_window),
    "theiler_window must be a nonnegative integer")
  if(is.null(dimensions))dimensions<-source$dimension_names
  .etr_assert(is.character(dimensions) && length(dimensions)>0L &&
    all(dimensions %in% source$dimension_names) && !anyDuplicated(dimensions),
    "dimensions must be distinct named channels")
  idx<-match(dimensions,source$dimension_names)
  n<-length(source$time)
  .etr_assert(n<=2500L,"native dense recurrence radius profile limited to 2500 states")
  tt<-as.integer(theiler_window)
  # Exact eligible-pair closed form: sum_{lag=theiler+1}^{n-1}(n-lag).
  # Avoid allocating three extra n-by-n matrices merely to count pairs.
  eligible<-as.double(n-tt)*as.double(n-tt-1L)/2
  .etr_assert(eligible>0L,"Theiler window leaves no eligible pairs")
  values<-matrix(source$values[curve,,idx,drop=FALSE],nrow=n,ncol=length(idx))
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
      distance_matrix_materialized=FALSE,
      radius_grid_declared_by_user=TRUE,
      automatic_radius_selection=FALSE)),
    class="etr_recurrence_radius_profile")
}

#' Native fixed-radius sliding-window RQA
#' @param trajectories Complete native common-grid trajectories.
#' @param curve Curve ID or one-based index.
#' @param window,step Window/step lengths in integer samples.
#' @param radius Finite nonnegative Euclidean radius (mandatory in R).
#' @param metric Currently "euclidean"; Python alternative metrics pending.
#' @param theiler_window Nonnegative integer Theiler lag.
#' @param dimensions Optional selected channels.
#' @param min_diagonal_length,min_vertical_length Run-length thresholds.
#' @export
etr_windowed_rqa <- function(trajectories,curve=1L,window,step,
    window_units="samples",step_units="samples",radius,
    target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(identical(metric,"euclidean") &&
    identical(window_units,"samples") && identical(step_units,"samples") &&
    identical(theiler_window_units,"samples") &&
    is.null(target_recurrence_rate),
    "native windowed RQA supports fixed-radius Euclidean sample-index contracts only")
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
    rec<-etr_recurrence_matrix(x,curve=1L,radius=radius,
                               theiler=theiler_window)
    a<-.etr8_rqa_full(rec,min_diagonal_length,min_vertical_length)
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
      curve_id=trajectories$curve_ids[curve],
      radius_policy="fixed",tail_policy="full_windows_only_with_explicit_tail_count")),
    class="etr_windowed_rqa")
}

#' Turn fixed-radius windowed RQA into native functional trajectories
#' @param trajectories Complete common-grid native R trajectories.
#' @param metrics Unique selected RQA summary names.
#' @param undefined_policy "raise" or "keep" for undefined values.
#' @inheritParams etr_windowed_rqa
#' @export
etr_windowed_rqa_trajectory_set <- function(trajectories,metrics,window,step,
    window_units="samples",step_units="samples",radius,
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
  .etr_assert(undefined_policy %in% c("raise","keep"),
    "undefined_policy must be 'raise' or 'keep'")
  etr_validate(trajectories,require_complete=TRUE)
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
  overlap<-max(as.integer(window)-as.integer(step),0L)
  provenance<-list(operation="windowed_rqa_trajectory_set",
    metrics=metrics,overlap_samples=overlap,
    overlap_fraction=overlap/window,
    overlapping_windows=overlap>0L,
    window_rows_are_independent=FALSE,
    undefined_policy=undefined_policy,
    undefined_value_count=sum(bad))
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
