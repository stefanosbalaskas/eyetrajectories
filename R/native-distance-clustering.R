# Stage 19: exact distance multiverse and native FPCA-score K-means.
# Source reference eyetrajectoriespy 1.2.0 similarity_sensitivity.py,
# analysis.py. R/NumPy/scikit-learn RNG streams need not agree.

#' Deterministic finite k-means clustering of retained FPCA scores
#' @param fpca Native complete fitted FPCA result.
#' @param n_clusters Explicit integer clusters >= 2.
#' @param n_components Number of fitted FPCA scores retained; NULL uses all.
#' @param random_state Scoped base-R random seed.
#' @param n_init Positive number of independent starts, or source "auto" (1).
#' @export
etr_cluster_fpca_scores <- function(fpca,n_clusters,
    n_components=NULL,random_state=0L,n_init="auto"){
  .etr_fpca_fitted_check(fpca)
  k<-.etr_nonlinear_integer(n_clusters,2L,"n_clusters")
  n<-length(fpca$curve_ids)
  .etr_assert(k<=n,"n_clusters must not exceed number of trajectories")
  comp<-if(is.null(n_components))fpca$n_components else
    .etr_nonlinear_integer(n_components,1L,"n_components")
  .etr_assert(comp<=fpca$n_components,
    "n_components exceeds fitted FPCA range")
  if(identical(n_init,"auto"))nstart<-1L else
    nstart<-.etr_nonlinear_integer(n_init,1L,"n_init")
  .etr_assert(is.matrix(fpca$scores)&&is.numeric(fpca$scores)&&
    all(is.finite(fpca$scores))&&nrow(fpca$scores)==n&&
    ncol(fpca$scores)>=comp,"FPCA scores must be finite and aligned")
  scores<-fpca$scores[,seq_len(comp),drop=FALSE]
  .etr_assert(nrow(unique(scores))>=k,
    "at least n_clusters distinct FPCA score vectors are required")
  restore<-.etr_simulation_rng(random_state);on.exit(restore(),add=TRUE)
  fit<-stats::kmeans(scores,centers=k,iter.max=100L,nstart=nstart,
    algorithm="Hartigan-Wong")
  structure(list(labels=as.integer(fit$cluster-1L),
    centers=fit$centers,method="kmeans_fpca_scores",
    withinss=fit$withinss,tot_withinss=fit$tot.withinss,
    iterations=fit$iter,curve_ids=fpca$curve_ids,
    n_components=comp,model=list(algorithm="base_R_Hartigan_Wong",
      n_init=nstart,random_engine="base_R_not_scikit_learn"),
    provenance=list(operation="cluster_fpca_scores",
      n_components=comp,n_clusters=k,random_state=random_state,
      exact_sklearn_initialization_equivalence=FALSE,
      label_permutation_identifiable=FALSE)),
    class="etr_fpca_clusters")
}
.etr_cluster_distance_spec <- function(x){
  .etr_assert(is.list(x)&&length(x)>=2L,
    "specifications must contain at least two declared distance contracts")
  names<-character(length(x))
  for(i in seq_along(x)){
    s<-x[[i]]
    .etr_assert(is.list(s)&&is.character(s$name)&&length(s$name)==1L&&
      nzchar(trimws(s$name))&&is.character(s$method)&&
      length(s$method)==1L&&
      s$method%in%c("functional_l2","discrete_frechet","dtw"),
      "each specification must have distinct name and known method")
    names[i]<-s$name
    expected<-if(s$method=="dtw")
      c("name","method","step_pattern","normalize","window_radius")
      else c("name","method")
    .etr_assert(all(names(s)%in%expected),
      "distance method has unsupported specification options")
    if(s$method=="dtw"){
      .etr_assert(is.null(s$step_pattern)||
        s$step_pattern%in%c("symmetric1","symmetric2"),
        "DTW step_pattern must be symmetric1 or symmetric2")
      .etr_assert(is.null(s$normalize)||
        (is.logical(s$normalize)&&length(s$normalize)==1L&&!is.na(s$normalize)),
        "DTW normalize must be Boolean")
      if(!is.null(s$window_radius))
        .etr_nonlinear_integer(s$window_radius,0L,"window_radius")
      .etr_assert(!isTRUE(s$normalize)||
        identical(if(is.null(s$step_pattern))"symmetric1" else s$step_pattern,
          "symmetric2"),"normalized DTW requires symmetric2")
    }
  }
  .etr_assert(!anyDuplicated(names),
    "distance specification names must be distinct")
  x
}
.etr_cluster_distance_value<-function(a,b,time,weights,s){
  switch(s$method,
    functional_l2=etr_l2_distance(a,b,time,dimension_weights=weights),
    discrete_frechet=etr_discrete_frechet(a,b,dimension_weights=weights),
    dtw=etr_dynamic_time_warping(a,b,dimension_weights=weights,
      window_radius=s$window_radius,
      step_pattern=if(is.null(s$step_pattern))"symmetric1" else s$step_pattern,
      normalize=if(is.null(s$normalize))FALSE else s$normalize))
}

#' Declared trajectory-distance contract agreement and local neighbor turnover
#' @param trajectories Complete source curves on common time grid.
#' @param specifications At least two named method specifications; explicit DTW options.
#' @param dimensions Optional distinct source dimensions, NULL uses all.
#' @param dimension_weights Positive-support, nonnegative selected-channel weights.
#' @param neighbor_k Explicit nearest neighbors per source curve.
#' @export
etr_trajectory_distance_sensitivity<-function(trajectories,specifications,
    dimensions=NULL,dimension_weights=NULL,neighbor_k=3L){
  etr_validate(trajectories,require_complete=TRUE)
  n<-length(trajectories$curve_ids)
  .etr_assert(n>=3L,"trajectory distance sensitivity requires >=3 curves")
  k<-.etr_nonlinear_integer(neighbor_k,1L,"neighbor_k")
  .etr_assert(k<n,"neighbor_k must be < number of curves")
  d<-if(is.null(dimensions))trajectories$dimension_names else dimensions
  .etr_assert(is.character(d)&&length(d)>0L&&!anyNA(d)&&
    !anyDuplicated(d)&&all(d%in%trajectories$dimension_names),
    "dimensions must be nonempty distinct existing names")
  w<-if(is.null(dimension_weights))rep(1,length(d)) else dimension_weights
  .etr_assert(is.numeric(w)&&length(w)==length(d)&&all(is.finite(w))&&
    all(w>=0)&&any(w>0),
    "dimension_weights must be finite nonnegative and have positive support")
  specs<-.etr_cluster_distance_spec(specifications)
  ns<-length(specs);arrays<-array(0,c(ns,n,n))
  cols<-match(d,trajectories$dimension_names)
  pts<-lapply(seq_len(n),function(i)matrix(
    trajectories$values[i,,cols,drop=FALSE],
    nrow=length(trajectories$time),ncol=length(cols)))
  idx<-do.call(rbind,lapply(seq_len(n-1L),function(i)
    cbind(i,seq.int(i+1L,n))))
  np<-nrow(idx);ranked<-matrix(0,ns,np)
  names<-vapply(specs,function(x)x$name,character(1L))
  pairRows<-vector("list",ns*np);p<-0L
  for(s in seq_len(ns)){
    m<-matrix(0,n,n)
    for(i in seq_len(np)){
      a<-idx[i,1L];b<-idx[i,2L]
      val<-.etr_cluster_distance_value(pts[[a]],pts[[b]],
        trajectories$time,w,specs[[s]])
      .etr_assert(length(val)==1L&&is.finite(val)&&val>=0,
        "distance contract returned nonfinite/negative value")
      m[a,b]<-m[b,a]<-val
    }
    arrays[s,,]<-m
    v<-m[idx]
    ranked[s,]<-rank(v,ties.method="average")
    for(i in seq_len(np)){
      p<-p+1L
      pairRows[[p]]<-data.frame(specification=names[s],
        method=specs[[s]]$method,
        curve_id_a=trajectories$curve_ids[idx[i,1L]],
        curve_id_b=trajectories$curve_ids[idx[i,2L]],
        distance=v[i],distance_rank=ranked[s,i])
    }
  }
  orders<-array(0L,c(ns,n,k));ties<-matrix(FALSE,ns,n)
  for(s in seq_len(ns))for(i in seq_len(n)){
    candidates<-setdiff(seq_len(n),i)
    distances<-arrays[s,i,candidates]
    permutation<-order(distances,candidates,method="radix")
    orderIDs<-candidates[permutation]
    orders[s,i,]<-as.integer(orderIDs[seq_len(k)]-1L)
    sorted<-distances[permutation]
    if(k<length(sorted))ties[s,i]<-abs(sorted[k]-sorted[k+1L])<=
      1e-12*max(abs(sorted[k]),abs(sorted[k+1L]))
  }
  compare<-list();neighbor<-list()
  for(a in seq_len(ns-1L))for(b in seq.int(a+1L,ns)){
    ia<-ranked[a,];ib<-ranked[b,]
    ja<-logical(n);nm<-logical(n);exact<-logical(n)
    for(i in seq_len(n)){
      left<-orders[a,i,];right<-orders[b,i,]
      intersection<-length(intersect(left,right))
      union<-length(union(left,right))
      ja[i]<-FALSE
      nm[i]<-identical(as.integer(left[1L]),as.integer(right[1L]))
      exact[i]<-setequal(left,right)
      neighbor[[length(neighbor)+1L]]<-data.frame(
        specification_a=names[a],specification_b=names[b],
        curve_id=trajectories$curve_ids[i],neighbor_k=k,
        overlap_count=intersection,jaccard=intersection/union,
        exact_neighbor_set_match=exact[i],
        nearest_neighbor_match=nm[i],
        cutoff_tie_a=ties[a,i],cutoff_tie_b=ties[b,i])
    }
    ranksDiff<-abs(ia-ib)
    jaccard<-vapply(neighbor[(length(neighbor)-n+1L):
      length(neighbor)],function(row)row$jaccard,numeric(1L))
    av<-arrays[a,,][idx];bv<-arrays[b,,][idx]
    corr<-function(a,b)if(stats::sd(a)==0||stats::sd(b)==0)
      NaN else stats::cor(a,b)
    compare[[length(compare)+1L]]<-data.frame(
      specification_a=names[a],specification_b=names[b],
      n_curve_pairs=np,
      spearman_rank_correlation=corr(ia,ib),
      pearson_raw_distance_correlation=corr(av,bv),
      mean_absolute_rank_difference=mean(ranksDiff),
      median_absolute_rank_difference=stats::median(ranksDiff),
      maximum_absolute_rank_difference=max(ranksDiff),
      mean_top_k_neighbor_jaccard=mean(jaccard),
      exact_top_k_neighbor_set_agreement_fraction=mean(exact),
      nearest_neighbor_identity_agreement_fraction=mean(nm),
      any_neighbor_cutoff_tie=any(ties[c(a,b),,drop=FALSE]))
  }
  specTable<-do.call(rbind,lapply(specs,function(s)data.frame(
    name=s$name,method=s$method,
    step_pattern=if(is.null(s$step_pattern))NA_character_ else s$step_pattern,
    normalize=if(is.null(s$normalize))NA else s$normalize,
    window_radius=if(is.null(s$window_radius))NA_integer_ else
      as.integer(s$window_radius))))
  structure(list(specification_names=names,
    distance_matrices=arrays,specification_table=specTable,
    pairwise_distance_table=do.call(rbind,pairRows),
    comparison_table=do.call(rbind,compare),
    neighbor_overlap_table=do.call(rbind,neighbor),
    neighbor_orders=orders,neighbor_cutoff_ties=ties,
    curve_ids=trajectories$curve_ids,dimensions=d,
    dimension_weights=as.numeric(w),neighbor_k=k,
    provenance=list(operation="trajectory_distance_sensitivity",
      n_curves=n,n_curve_pairs=np,specifications=specs,
      rank_tie_method="average",
      neighbor_tie_break="original_curve_order",
      distance_matrix_standardization=FALSE,
      distance_matrix_rescaling=FALSE,
      consensus_distance_constructed=FALSE,
      preferred_metric_selected=FALSE,
      pairwise_distances_treated_as_independent=FALSE,
      correlation_p_values_computed=FALSE)),
    class="etr_trajectory_distance_sensitivity")
}
