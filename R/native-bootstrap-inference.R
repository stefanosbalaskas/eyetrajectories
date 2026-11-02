# Stage 15: native R functional mean and FPCA uncertainty estimation.
# Published Python 1.2 source: inference.py, score_uncertainty.py,
# spectrum_inference.py, component_inference.py. No Python bridge.
# Bootstrap bands describe observed-grid resampling approximations, not
# exact finite-sample or continuous-domain coverage.

.etr_bootstrap_integer <- function(x,low,label) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x==as.integer(x)&&x>=low,paste(label,"must be integer >=",low))
  as.integer(x)
}
.etr_bootstrap_probability <- function(x,label) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x>0&&x<1,paste(label,"must lie in (0,1)"))
  as.numeric(x)
}
.etr_bootstrap_upper_tail <- function(x,p) {
  v<-sort(as.numeric(x))
  .etr_assert(length(v)>0L&&all(is.finite(v)),
    "bootstrap calibration must be finite")
  # NumPy quantile(method='higher'): zero-based index ceil((n-1) p).
  v[1L+as.integer(ceiling((length(v)-1L)*p))]
}
.etr_bootstrap_options <- function(x,unit,participant_column) {
  .etr_assert(is.character(unit)&&length(unit)==1L&&
    unit%in%c("curve","participant"),
    "resample_unit must be curve or participant")
  .etr_assert(is.null(participant_column)||unit=="participant",
    "participant_column must be NULL with resample_unit='curve'")
  .etr_fpca_stability_scope(x,unit,participant_column)
}
.etr_bootstrap_target <- function(training,targets) {
  if(is.null(targets))return(training)
  etr_validate(targets,require_complete=TRUE)
  .etr_assert(identical(training$time,targets$time),
    "target time grid must match training")
  .etr_assert(identical(training$dimension_names,targets$dimension_names),
    "target dimension names/order must match training")
  .etr_assert(identical(training$coordinate_system,targets$coordinate_system)&&
    identical(training$time_unit,targets$time_unit),
    "target coordinate system and time unit must match training")
  targets
}
.etr_bootstrap_calibrate <- function(samples,reference,level,scope,metric) {
  .etr_assert(is.matrix(samples)&&is.numeric(samples) &&
    is.numeric(reference)&&is.null(dim(reference))&&
    ncol(samples)==length(reference)&&nrow(samples)>=2L&&
    all(is.finite(samples))&&all(is.finite(reference)),
    paste(metric,"requires finite bootstrap matrix and reference vector"))
  k<-length(reference)
  se<-apply(samples,2L,stats::sd)
  scale<-max(1,max(abs(reference)))
  positive<-se>.Machine$double.eps*scale
  delta<-sweep(samples,2L,reference,"-")
  tolerance<-100*.Machine$double.eps*scale
  .etr_assert(!any(!positive & apply(abs(delta),2L,max)>tolerance),
    paste(metric,"has zero bootstrap SE with nonzero reference discrepancy"))
  stat<-matrix(0,nrow(samples),k)
  for(j in which(positive))stat[,j]<-abs(delta[,j]/se[j])
  critical<-if(scope=="component")
    vapply(seq_len(k),function(j).etr_bootstrap_upper_tail(stat[,j],level),numeric(1L))
    else rep(.etr_bootstrap_upper_tail(apply(stat,1L,max),level),k)
  list(se=as.numeric(se),critical=as.numeric(critical),
    lower=reference-critical*se,upper=reference+critical*se,
    max_statistics=stat)
}
.etr_bootstrap_matrix <- function(a,k,nt,nd) {
  array(a,c(k,nt,nd))
}

#' Gaussian multiplier simultaneous functional mean band on observed grid
#' @param trajectories Complete native trajectories.
#' @param confidence_level Requested nominal simultaneous fraction.
#' @param n_multiplier Number of Gaussian multiplier draws, at least 100.
#' @param unit Curve or independent participant units.
#' @param participant_column Required participant metadata when used.
#' @param random_state Isolated base-R RNG seed; not NumPy-identical.
#' @export
etr_multiplier_functional_mean_band <- function(trajectories,
    confidence_level=.95,n_multiplier=2000L,unit="curve",
    participant_column=NULL,random_state=0L) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(trajectories$coordinate_system!="probability_simplex",
    "simplex responses require an explicit log-ratio transform")
  level<-.etr_bootstrap_probability(confidence_level,"confidence_level")
  b<-.etr_bootstrap_integer(n_multiplier,100L,"n_multiplier")
  .etr_bootstrap_options(trajectories,unit,participant_column)
  vals<-trajectories$values; n<-dim(vals)[1L];nt<-dim(vals)[2L];nd<-dim(vals)[3L]
  if(unit=="curve"){
    ids<-trajectories$curve_ids
    unit_vals<-vals
    counts<-rep(1L,n)
  }else{
    g<-as.character(trajectories$metadata[[participant_column]])
    ids<-unique(g);counts<-vapply(ids,function(p)sum(g==p),integer(1L))
    unit_vals<-array(0,c(length(ids),nt,nd))
    for(i in seq_along(ids)){
      subset<-which(g==ids[i])
      for(t in seq_len(nt))for(d in seq_len(nd))
        unit_vals[i,t,d]<-mean(vals[subset,t,d])
    }
  }
  nu<-length(ids)
  .etr_assert(nu>=2L,"at least two independent units required")
  mu<-apply(unit_vals,c(2L,3L),mean)
  mu<-matrix(mu,nt,nd)
  residual<-sweep(unit_vals,c(2L,3L),mu,"-")
  sd_grid<-matrix(apply(unit_vals,c(2L,3L),stats::sd),nt,nd)
  se<-sd_grid/sqrt(nu)
  active<-sd_grid>.Machine$double.eps
  restore<-.etr_simulation_rng(random_state);on.exit(restore(),add=TRUE)
  stats<-numeric(b)
  if(any(active))for(i in seq_len(b)){
    w<-stats::rnorm(nu)
    process<-matrix(0,nt,nd)
    for(t in seq_len(nt))for(d in seq_len(nd))
      process[t,d]<-sum(w*residual[,t,d])/sqrt(nu)
    standardized<-matrix(0,nt,nd)
    standardized[active]<-process[active]/sd_grid[active]
    stats[i]<-max(abs(standardized))
  }
  crit<-if(any(active)).etr_bootstrap_upper_tail(stats,level) else 0
  lower<-mu-crit*se;upper<-mu+crit*se
  structure(list(mean=mu,lower=lower,upper=upper,
    pointwise_se=se,critical_value=as.numeric(crit),
    max_statistics=stats,confidence_level=level,unit=unit,
    unit_ids=ids,curves_per_unit=as.integer(counts),
    participant_column=if(unit=="participant")participant_column else NULL,
    time=trajectories$time,dimension_names=trajectories$dimension_names,
    coordinate_system=trajectories$coordinate_system,time_unit=trajectories$time_unit,
    provenance=c(if(is.null(trajectories$provenance))list()
      else trajectories$provenance,list(functional_mean_band=list(
      method="gaussian_multiplier_studentized_maximum",
      n_multiplier=b,confidence_level=level,random_state=random_state,
      n_units=nu,unit=unit,participant_column=if(unit=="participant")
        participant_column else NULL,
      estimand=if(unit=="participant")
        "equal_weight_mean_of_participant_mean_trajectories"
        else "equal_weight_curve_mean",
      curves_per_unit=as.integer(counts),
      zero_variance_grid_points=sum(!active),
      simultaneous_domain="observed_time_by_dimension_grid",
      continuous_between_grid_points=FALSE,
      random_engine="base_R_not_NumPy")))),
    class="etr_functional_mean_band")
}

#' Bootstrap sign-aligned fixed-target FPCA score uncertainty
#' @param targets Fixed external target trajectories, or NULL training curves.
#' @param n_bootstrap Number of bootstrap refits, at least 20.
#' @param n_components Retained functional components.
#' @param scaling Native channel scaling.
#' @param resample_unit Curve or participant-level bootstrap.
#' @param participant_column Required when resampling participants.
#' @param level Descriptive two-sided percentile level.
#' @inheritParams etr_multiplier_functional_mean_band
#' @export
etr_bootstrap_fpca_score_uncertainty <- function(trajectories,targets=NULL,
    n_bootstrap=500L,n_components=3L,scaling="none",
    resample_unit="curve",participant_column=NULL,level=.95,
    random_state=0L) {
  etr_validate(trajectories,require_complete=TRUE)
  tgt<-.etr_bootstrap_target(trajectories,targets)
  b<-.etr_bootstrap_integer(n_bootstrap,20L,"n_bootstrap")
  k<-.etr_bootstrap_integer(n_components,1L,"n_components")
  .etr_bootstrap_probability(level,"level")
  .etr_bootstrap_options(trajectories,resample_unit,participant_column)
  ref<-.etr_fpca_stability_fit(trajectories,k,scaling)
  reference_scores<-etr_transform_fpca(ref,tgt)[,seq_len(k),drop=FALSE]
  n<-length(tgt$curve_ids)
  samples<-array(0,c(b,n,k))
  assignments<-matrix(0L,b,k)
  similarities<-matrix(0,b,k)
  restore<-.etr_simulation_rng(random_state);on.exit(restore(),add=TRUE)
  for(i in seq_len(b)){
    s<-.etr_fpca_stability_boot(trajectories,resample_unit,participant_column)
    .etr_assert(length(s$curve_ids)>k,
      "bootstrap sample has insufficient non-zero FPCA rank")
    cand<-.etr_fpca_stability_fit(s,k,scaling)
    match<-etr_match_fpca_components(ref,cand,k)
    cand_scores<-etr_transform_fpca(cand,tgt)
    aligned<-sweep(cand_scores[,match$assignments+1L,drop=FALSE],
      2L,ifelse(match$signed_similarity>=0,1,-1),"*")
    .etr_assert(all(is.finite(aligned)),"bootstrap target scores not finite")
    samples[i,,]<-matrix(aligned,n,k)
    assignments[i,]<-match$assignments
    similarities[i,]<-abs(match$signed_similarity)
  }
  alpha<-(1-level)/2
  q<-function(p){
    out<-matrix(0,n,k)
    for(j in seq_len(k))for(i in seq_len(n))
      out[i,j]<-as.numeric(stats::quantile(samples[,i,j],p,names=FALSE,type=7))
    out
  }
  se<-matrix(0,n,k)
  for(j in seq_len(k))for(i in seq_len(n))
    se[i,j]<-stats::sd(samples[,i,j])
  structure(list(reference=ref,target_curve_ids=tgt$curve_ids,
    n_components=k,reference_scores=reference_scores,
    bootstrap_scores=samples,lower=q(alpha),median=q(.5),
    upper=q(1-alpha),score_se=se,assignments=assignments,
    similarities=similarities,level=level,resampling_unit=resample_unit,
    participant_column=if(resample_unit=="participant")participant_column else NULL,
    target_source=if(is.null(targets))"training" else "external",
    random_state=as.integer(random_state),
    provenance=list(fpca_score_uncertainty=list(
      method="matched_sign_aligned_basis_resampling",
      interval="pointwise_percentile_descriptive",
      n_bootstrap=b,n_components=k,target_curves_fixed=TRUE,
      includes_target_measurement_error=FALSE,
      random_engine="base_R_not_NumPy"))),
    class="etr_fpca_score_uncertainty")
}

#' Matched-bootstrap studentized FPCA eigenvalue/ratio uncertainty
#' @param confidence_level Nominal observed-spectrum calibration fraction.
#' @param simultaneous_scope Component or same-metric family calibration.
#' @inheritParams etr_bootstrap_fpca_score_uncertainty
#' @export
etr_bootstrap_fpca_spectrum_uncertainty <- function(trajectories,
    n_bootstrap=500L,n_components=3L,scaling="none",
    resample_unit="curve",participant_column=NULL,
    confidence_level=.95,simultaneous_scope="component",random_state=0L){
  etr_validate(trajectories,require_complete=TRUE)
  b<-.etr_bootstrap_integer(n_bootstrap,20L,"n_bootstrap")
  k<-.etr_bootstrap_integer(n_components,1L,"n_components")
  level<-.etr_bootstrap_probability(confidence_level,"confidence_level")
  .etr_assert(is.character(simultaneous_scope)&&length(simultaneous_scope)==1L&&
    simultaneous_scope%in%c("component","family"),
    "simultaneous_scope must be component or family")
  .etr_bootstrap_options(trajectories,resample_unit,participant_column)
  ref<-.etr_fpca_stability_fit(trajectories,k,scaling)
  eig<-ratio<-cum<-matrix(0,b,k)
  assign<-matrix(0L,b,k);sims<-matrix(0,b,k)
  restore<-.etr_simulation_rng(random_state);on.exit(restore(),add=TRUE)
  for(i in seq_len(b)){
    sample<-.etr_fpca_stability_boot(trajectories,resample_unit,participant_column)
    .etr_assert(length(sample$curve_ids)>k,"bootstrap FPCA nonzero rank insufficient")
    candidate<-.etr_fpca_stability_fit(sample,k,scaling)
    matched<-etr_match_fpca_components(ref,candidate,k)
    ix<-matched$assignments+1L
    assign[i,]<-matched$assignments;sims[i,]<-abs(matched$signed_similarity)
    eig[i,]<-candidate$explained_variance[ix]
    ratio[i,]<-candidate$explained_variance_ratio[ix]
    # Cumulative variance is descending eigenvalue rank, NOT shape-aligned.
    cum[i,]<-cumsum(candidate$explained_variance_ratio[seq_len(k)])
  }
  e<-.etr_bootstrap_calibrate(eig,ref$explained_variance[seq_len(k)],
    level,simultaneous_scope,"eigenvalue")
  r<-.etr_bootstrap_calibrate(ratio,ref$explained_variance_ratio[seq_len(k)],
    level,simultaneous_scope,"explained variance ratio")
  c<-.etr_bootstrap_calibrate(cum,cumsum(ref$explained_variance_ratio[seq_len(k)]),
    level,simultaneous_scope,"cumulative ratio")
  structure(list(reference=ref,n_components=k,
    bootstrap_eigenvalues=eig,bootstrap_explained_variance_ratio=ratio,
    bootstrap_cumulative_variance_ratio=cum,
    eigenvalue_se=e$se,eigenvalue_critical_values=e$critical,
    eigenvalue_lower=e$lower,eigenvalue_upper=e$upper,
    eigenvalue_max_statistics=e$max_statistics,
    explained_variance_ratio_se=r$se,
    explained_variance_ratio_critical_values=r$critical,
    explained_variance_ratio_lower=r$lower,explained_variance_ratio_upper=r$upper,
    explained_variance_ratio_max_statistics=r$max_statistics,
    cumulative_variance_ratio_se=c$se,
    cumulative_variance_ratio_critical_values=c$critical,
    cumulative_variance_ratio_lower=c$lower,
    cumulative_variance_ratio_upper=c$upper,
    cumulative_variance_ratio_max_statistics=c$max_statistics,
    assignments=assign,similarities=sims,
    confidence_level=level,simultaneous_scope=simultaneous_scope,
    resampling_unit=resample_unit,random_state=as.integer(random_state),
    provenance=list(fpca_spectrum_uncertainty=list(
      method="matched_bootstrap_studentized_spectrum",
      individual_spectrum_order="matched_reference_component_identity",
      cumulative_spectrum_order="descending_eigenvalue_rank",
      support_clipping=FALSE,random_engine="base_R_not_NumPy",
      coverage_claim="bootstrap_studentized_approximation"))),
    class="etr_fpca_spectrum_uncertainty")
}

#' Matched-bootstrap simultaneous FPCA component shape bands
#' @param relative_gap_threshold Optional adjacent relative eigengap screen.
#' @param on_near_tie Error, warn or record the declared near tie.
#' @inheritParams etr_bootstrap_fpca_spectrum_uncertainty
#' @export
etr_bootstrap_fpca_component_bands <- function(trajectories,
    n_bootstrap=500L,n_components=3L,scaling="none",
    resample_unit="curve",participant_column=NULL,
    confidence_level=.95,simultaneous_scope="component",
    relative_gap_threshold=NULL,on_near_tie="error",random_state=0L){
  etr_validate(trajectories,require_complete=TRUE)
  b<-.etr_bootstrap_integer(n_bootstrap,20L,"n_bootstrap")
  k<-.etr_bootstrap_integer(n_components,1L,"n_components")
  level<-.etr_bootstrap_probability(confidence_level,"confidence_level")
  .etr_assert(is.character(simultaneous_scope)&&length(simultaneous_scope)==1L&&
    simultaneous_scope%in%c("component","family"),
    "simultaneous_scope must be component or family")
  .etr_assert(is.character(on_near_tie)&&length(on_near_tie)==1L&&
    on_near_tie%in%c("error","warn","ignore"),
    "on_near_tie must be error, warn or ignore")
  .etr_bootstrap_options(trajectories,resample_unit,participant_column)
  gaps<-rep(NA_real_,k);ties<-integer()
  if(!is.null(relative_gap_threshold)){
    .etr_assert(is.numeric(relative_gap_threshold)&&length(relative_gap_threshold)==1L&&
      is.finite(relative_gap_threshold)&&relative_gap_threshold>=0&&
      relative_gap_threshold<1,"relative_gap_threshold must lie in [0,1)")
    rank<-min(length(trajectories$curve_ids)-1L,
              length(trajectories$time)*length(trajectories$dimension_names))
    .etr_assert(k+1L<=rank,
      "eigengap screening requires one extra nonzero FPCA component")
    screen<-.etr_fpca_stability_fit(trajectories,k+1L,scaling)
    eigenvalues<-screen$explained_variance
    for(j in seq_len(k)){
      g<- (eigenvalues[j]-eigenvalues[j+1L])/
          max(eigenvalues[j],.Machine$double.eps)
      if(j>1L)g<-min(g,(eigenvalues[j-1L]-eigenvalues[j])/
        max(eigenvalues[j-1L],.Machine$double.eps))
      gaps[j]<-g
    }
    ties<-which(gaps<=relative_gap_threshold)
    if(length(ties)>0L){
      msg<-paste("FPC shape weakly identified under declared relative eigengap:",
        paste(ties,collapse=","))
      if(on_near_tie=="error")stop(msg,call.=FALSE)
      if(on_near_tie=="warn")warning(msg,call.=FALSE)
    }
  }
  ref<-.etr_fpca_stability_fit(trajectories,k,scaling)
  nt<-length(ref$time);nd<-length(ref$dimension_names)
  samples<-array(0,c(b,k,nt,nd))
  sims<-matrix(0,b,k)
  restore<-.etr_simulation_rng(random_state);on.exit(restore(),add=TRUE)
  for(i in seq_len(b)){
    sample<-.etr_fpca_stability_boot(trajectories,resample_unit,participant_column)
    .etr_assert(length(sample$curve_ids)>k,
      "bootstrap sample has insufficient FPCA rank")
    candidate<-.etr_fpca_stability_fit(sample,k,scaling)
    matching<-etr_match_fpca_components(ref,candidate,k)
    sims[i,]<-abs(matching$signed_similarity)
    for(j in seq_len(k))
      samples[i,j,,]<-matrix(candidate$components[
        matching$assignments[j]+1L,,,drop=FALSE],nt,nd)*
        ifelse(matching$signed_similarity[j]>=0,1,-1)
  }
  se<-array(0,c(k,nt,nd))
  maxstats<-matrix(0,b,k)
  for(j in seq_len(k))for(t in seq_len(nt))for(d in seq_len(nd)){
    v<-samples[,j,t,d]
    sigma<-stats::sd(v);se[j,t,d]<-sigma
    delta<-v-ref$components[j,t,d]
    positive<-sigma>.Machine$double.eps
    tolerance<-100*.Machine$double.eps*max(1,max(abs(ref$components)))
    .etr_assert(positive||max(abs(delta))<=tolerance,
      "bootstrap FPC uncertainty degenerate with nonzero reference discrepancy")
    if(positive)maxstats[,j]<-pmax(maxstats[,j],abs(delta/sigma))
  }
  critical<-if(simultaneous_scope=="component")
    vapply(seq_len(k),function(j).etr_bootstrap_upper_tail(maxstats[,j],level),numeric(1L))
    else rep(.etr_bootstrap_upper_tail(apply(maxstats,1L,max),level),k)
  lower<-upper<-array(0,c(k,nt,nd))
  for(j in seq_len(k)){
    lower[j,,]<-ref$components[j,,]-critical[j]*se[j,,]
    upper[j,,]<-ref$components[j,,]+critical[j]*se[j,,]
  }
  structure(list(reference=ref,lower=lower,upper=upper,
    pointwise_se=se,critical_values=critical,
    max_statistics=maxstats,similarities=sims,
    confidence_level=level,simultaneous_scope=simultaneous_scope,
    resampling_unit=resample_unit,
    participant_column=if(resample_unit=="participant")participant_column else NULL,
    relative_gap_threshold=relative_gap_threshold,
    minimum_relative_gaps=gaps,near_tie_components=as.integer(ties),
    random_state=as.integer(random_state),
    provenance=list(fpca_component_band=list(
      method="matched_sign_aligned_bootstrap_studentized_maximum",
      n_bootstrap=b,n_components=k,scaling=scaling,
      simultaneous_domain="observed_time_by_dimension_grid",
      continuous_between_grid_points=FALSE,random_engine="base_R_not_NumPy",
      component_identity_screened=!is.null(relative_gap_threshold),
      coverage_claim="bootstrap_calibrated_observed_grid_approximation"))),
    class="etr_fpca_component_band")
}

#' Long-form simultaneous native FPC shape band table
#' @param result Native FPCA component-band result.
#' @export
etr_fpca_component_band_frame <- function(result) {
  .etr_assert(inherits(result,"etr_fpca_component_band"),
    "result must be native FPC component band")
  ref<-result$reference;.etr_fpca_fitted_check(ref)
  k<-ref$n_components;nt<-length(ref$time);nd<-length(ref$dimension_names)
  rows<-vector("list",k*nt*nd);p<-0L
  for(j in seq_len(k))for(d in seq_len(nd))for(t in seq_len(nt)){
    p<-p+1L
    rows[[p]]<-data.frame(component=as.integer(j),
      time=ref$time[t],dimension=ref$dimension_names[d],
      reference=ref$components[j,t,d],
      pointwise_se=result$pointwise_se[j,t,d],
      lower=result$lower[j,t,d],upper=result$upper[j,t,d])
  }
  do.call(rbind,rows)
}
