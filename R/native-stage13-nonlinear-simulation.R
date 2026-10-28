# Stage 13 — independent numerical embedding, return-map stability and
# simulation implementations (no Python bridge).
# Published source: embedding.py, return_maps.py, simulate.py (v1.2.0).

.etr13_rng <- function(seed) {
  .etr_assert(is.numeric(seed)&&length(seed)==1L&&is.finite(seed)&&
    seed==as.integer(seed)&&seed>=0L,
    "random_state must be a nonnegative R seed")
  old<-exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  if(old)prior<-get(".Random.seed",envir=.GlobalEnv)
  set.seed(as.integer(seed))
  function(){
    if(old)assign(".Random.seed",prior,envir=.GlobalEnv)
    else if(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
      rm(".Random.seed",envir=.GlobalEnv)
  }
}
.etr13_regularity <- function(t) {
  delta<-diff(t);step<-stats::median(delta)
  .etr_assert(all(abs(delta-step)<=1e-6*abs(step)+
    max(1e-12,abs(step)*1e-9)),
    "embedding diagnostics require an approximately regular temporal grid")
  step
}
.etr13_histogram_mi <- function(x,y,edges) {
  k<-length(edges)-1L
  xi<-findInterval(x,edges,rightmost.closed=TRUE,all.inside=TRUE)
  yi<-findInterval(y,edges,rightmost.closed=TRUE,all.inside=TRUE)
  z<-matrix(0,k,k)
  for(i in seq_along(xi))z[xi[i],yi[i]]<-z[xi[i],yi[i]]+1
  p<-z/length(x);px<-rowSums(p);py<-colSums(p)
  inds<-which(p>0,arr.ind=TRUE)
  sum(vapply(seq_len(nrow(inds)),function(i){
    a<-inds[i,1L];b<-inds[i,2L]
    p[a,b]*log(p[a,b]/(px[a]*py[b]))
  },numeric(1L)))
}

#' Autocorrelation and histogram average mutual information delay diagnostics
#' @param trajectories Complete native trajectory set with regular time grid.
#' @param curve One-based source-curve index or exact ID.
#' @param dimension Named scalar functional channel.
#' @param max_lag Positive sample-index lag maximum.
#' @param max_lag_units Only "samples" supported (fail closed).
#' @param bins Fixed-count source-range AMI histogram bins.
#' @export
etr_embedding_delay_diagnostics <- function(trajectories,curve,dimension,
    max_lag,max_lag_units="samples",bins=16L){
  etr_validate(trajectories,require_complete=TRUE)
  step<-.etr13_regularity(trajectories$time)
  .etr_assert(identical(max_lag_units,"samples"),
    "time-unit lags not yet qualified; use explicit sample lags")
  .etr_assert(is.numeric(max_lag)&&length(max_lag)==1L&&
    is.finite(max_lag)&&max_lag==as.integer(max_lag)&&max_lag>=1L,
    "max_lag must be a positive integer in samples")
  .etr_assert(is.numeric(bins)&&length(bins)==1L&&is.finite(bins)&&
    bins==as.integer(bins)&&bins>=2L,"bins must be integer >= 2")
  .etr_assert(dimension%in%trajectories$dimension_names,
    "Unknown functional dimension")
  if(is.character(curve))curve<-match(curve,trajectories$curve_ids)
  .etr_assert(is.numeric(curve)&&length(curve)==1L&&!is.na(curve)&&
    curve==as.integer(curve)&&curve>=1L&&
    curve<=length(trajectories$curve_ids),"curve index or ID is out of range")
  y<-as.vector(trajectories$values[curve,,match(dimension,
    trajectories$dimension_names)])
  n<-length(y);max_lag<-as.integer(max_lag);bins<-as.integer(bins)
  .etr_assert(max_lag<n-1L,
    "max_lag must leave at least two paired observations")
  .etr_assert(stats::sd(y)>0,
    "embedding delay diagnostics require a non-constant signal")
  centered<-y-mean(y)
  denom<-sum(centered^2)
  edges<-seq(min(y),max(y),length.out=bins+1L)
  .etr_assert(length(unique(edges))==bins+1L,
    "AMI histogram requires non-degenerate fixed bin edges")
  tab<-do.call(rbind,lapply(seq_len(max_lag),function(lag) {
    data.frame(lag_samples=as.integer(lag),
      lag_time=trajectories$time[lag+1L]-trajectories$time[1L],
      autocorrelation=sum(centered[seq_len(n-lag)]*
        centered[(lag+1L):n])/denom,
      average_mutual_information=.etr13_histogram_mi(
        y[seq_len(n-lag)],y[(lag+1L):n],edges))
  }))
  minima<-rep(FALSE,nrow(tab));m<-tab$average_mutual_information
  if(length(m)>2L)for(i in 2:(length(m)-1L))
    if(m[i]<m[i-1L]&&m[i]<=m[i+1L]){minima[i]<-TRUE;break}
  tab$first_ami_local_minimum<-minima
  structure(list(table=tab,curve_id=trajectories$curve_ids[curve],
    dimension=dimension,bins=bins,max_lag_samples=max_lag,
    time_unit=trajectories$time_unit,
    provenance=list(operation="embedding_delay_diagnostics",
      criterion="Fraser-Swinney average mutual information diagnostic",
      automatic_delay_selection=FALSE,
      histogram_edges_fixed_across_lags=TRUE,
      sampling_contract="approximately_regular_grid",
      sampling_step=step)),class="etr_embedding_delay_diagnostics")
}

#' Eigenvalue criterion for an explicitly fitted empirical return map
#' @param fit Native or declared return-map fit with square Jacobian.
#' @param tolerance Nonnegative spectral-radius classification margin.
#' @export
etr_return_map_stability <- function(fit,tolerance=1e-6){
  .etr_assert(is.list(fit)&&is.matrix(fit$jacobian)&&
    is.numeric(fit$jacobian)&&nrow(fit$jacobian)==ncol(fit$jacobian)&&
    nrow(fit$jacobian)>0L&&all(is.finite(fit$jacobian)),
    "return-map Jacobian must be a finite square matrix")
  .etr_assert(is.numeric(tolerance)&&length(tolerance)==1L&&
    is.finite(tolerance)&&tolerance>=0,
    "tolerance must be nonnegative and finite")
  eig<-eigen(fit$jacobian,only.values=TRUE)$values
  radius<-max(Mod(eig))
  classification<-if(radius<1-tolerance)"contracting"
    else if(radius>1+tolerance)"expanding" else "near-neutral"
  structure(list(eigenvalues=eig,spectral_radius=as.numeric(radius),
    classification=classification,tolerance=tolerance,
    provenance=list(operation="return_map_stability",
      fit_provenance=if(is.null(fit$provenance))list() else fit$provenance,
      criterion="spectral radius of empirical local return-map Jacobian",
      experimental=TRUE,
      interpretation_boundary=paste(
        "describes local empirical cycle-to-cycle contraction/expansion;",
        "does not establish deterministic orbital stability"))),
    class="etr_return_map_stability")
}

#' Native repeatable simulated gaze trajectories with participants and trials
#' @param n_participants Number of participant units (>=2).
#' @param trials_per_participant Trial repeats per participant (>=1).
#' @param n_time Time samples (>=5).
#' @param duration Time horizon (>0 seconds).
#' @param random_state Isolated base R random seed (not NumPy-identical).
#' @export
etr_simulate_planar_trajectories <- function(n_participants=20L,
    trials_per_participant=6L,n_time=121L,duration=2,random_state=42L){
  vals<-c(n_participants,trials_per_participant,n_time)
  .etr_assert(all(is.finite(vals))&&all(vals==as.integer(vals))&&
    n_participants>=2L&&trials_per_participant>=1L&&n_time>=5L&&
    is.numeric(duration)&&length(duration)==1L&&
    is.finite(duration)&&duration>0,
    "use >=2 participants, >=1 trial, >=5 time samples and positive duration")
  restore<-.etr13_rng(random_state);on.exit(restore(),add=TRUE)
  n_participants<-as.integer(n_participants)
  trials_per_participant<-as.integer(trials_per_participant)
  n_time<-as.integer(n_time)
  t<-seq(0,duration,length.out=n_time);u<-t/duration
  n<-n_participants*trials_per_participant
  .etr_assert(n<=100000L,"simulator limited to 100000 independent curves")
  out<-array(0,c(n,n_time,2L))
  ids<-character(n);parts<-character(n);trials<-integer(n)
  conditions<-character(n);amplitudes<-numeric(n)
  i<-0L
  for(p in seq_len(n_participants)){
    shift<-stats::rnorm(2L,0,.025)
    phase_shift<-stats::rnorm(1L,0,.035)
    amp<-stats::rnorm(1L,1,.07)
    for(j in seq_len(trials_per_participant)){
      i<-i+1L;prompt<-as.numeric(j%%2L==0L)
      phase<-pmin(1,pmax(0,u+phase_shift+stats::rnorm(1L,0,.018)))
      evidence<-1/(1+exp(-(phase-(.38-.04*prompt))/.055))
      decision<-1/(1+exp(-(phase-.73)/.07))
      xx<-.5+(.26+.05*prompt)*amp*evidence-.17*decision+
        shift[1L]+.012*sin(2*pi*phase)+stats::rnorm(n_time,0,.008)
      yy<-.5-.17*amp*evidence+.27*decision+
        shift[2L]+.010*cos(2*pi*phase)+stats::rnorm(n_time,0,.008)
      out[i,,1L]<-pmin(1,pmax(0,xx))
      out[i,,2L]<-pmin(1,pmax(0,yy))
      ids[i]<-sprintf("P%03d|T%02d",p,j)
      parts[i]<-sprintf("P%03d",p)
      trials[i]<-j;conditions[i]<-if(prompt==1)"evidence_prompt" else "control"
      amplitudes[i]<-amp
    }
  }
  etr_trajectory_set(t,out,ids,c("x","y"),
    metadata=data.frame(participant_id=parts,trial_id=trials,
      condition=conditions,latent_participant_amplitude=amplitudes),
    coordinate_system="normalized",time_unit="s",
    provenance=list(source="simulate_planar_trajectories",
      random_state=as.integer(random_state),synthetic=TRUE,
      random_engine="base_R_not_NumPy"))
}

#' Simulate finite, smoothly time-varying AOI simplex trajectories
#' @param n_curves Number of observation curves (>=2).
#' @param n_aoi Number of simplex channels (>=2).
#' @inheritParams etr_simulate_planar_trajectories
#' @export
etr_simulate_aoi_probability_trajectories <- function(n_curves=80L,
    n_time=101L,n_aoi=4L,duration=2,random_state=17L){
  vals<-c(n_curves,n_time,n_aoi)
  .etr_assert(all(is.finite(vals))&&all(vals==as.integer(vals))&&
    n_curves>=2L&&n_time>=5L&&n_aoi>=2L&&
    is.numeric(duration)&&length(duration)==1L&&
    is.finite(duration)&&duration>0,
    "use >=2 curves, >=5 time points, >=2 AOIs and positive duration")
  restore<-.etr13_rng(random_state);on.exit(restore(),add=TRUE)
  n_curves<-as.integer(n_curves);n_time<-as.integer(n_time);n_aoi<-as.integer(n_aoi)
  .etr_assert(as.double(n_curves)*n_time*n_aoi<=3e7,
    "simulated AOI array exceeds 30 million cells")
  t<-seq(0,duration,length.out=n_time);u<-t/duration
  centers<-seq(.12,.88,length.out=n_aoi)
  out<-array(0,c(n_curves,n_time,n_aoi))
  for(i in seq_len(n_curves)){
    shift<-stats::rnorm(1L,0,.035)
    bias<-stats::rnorm(n_aoi,0,.25)
    logits<-matrix(0,n_time,n_aoi)
    for(j in seq_len(n_aoi))
      logits[,j]<- -((u-centers[j]-shift)^2)/.025+bias[j]+
        stats::rnorm(n_time,0,.08)
    for(k in seq_len(n_time)){
      z<-exp(logits[k,]-max(logits[k,]))
      out[i,k,]<-z/sum(z)
    }
  }
  etr_trajectory_set(t,out,
    sprintf("curve_%03d",seq_len(n_curves)),
    paste0("AOI_",seq_len(n_aoi)),
    metadata=data.frame(curve_index=0:(n_curves-1L)),
    coordinate_system="probability_simplex",time_unit="s",
    provenance=list(source="simulate_aoi_probability_trajectories",
      random_state=as.integer(random_state),synthetic=TRUE,
      random_engine="base_R_not_NumPy"))
}


#' Kennel-style false nearest-neighbor fractions across embedding dimensions
#' @inheritParams etr_embedding_delay_diagnostics
#' @param delay Positive integer lag in samples.
#' @param delay_units,theiler_window_units Only "samples" supported.
#' @param max_dimension Maximum candidate dimension.
#' @param theiler_window Temporally excluded neighboring states.
#' @param rtol,atol Declared positive FNN thresholds.
#' @export
etr_embedding_dimension_diagnostics <- function(trajectories,curve,dimension,
    delay,delay_units="samples",max_dimension=10L,theiler_window=0L,
    theiler_window_units="samples",rtol=10,atol=2){
  etr_validate(trajectories,require_complete=TRUE)
  step<-.etr13_regularity(trajectories$time)
  .etr_assert(identical(delay_units,"samples") &&
    identical(theiler_window_units,"samples"),
    "embedding FNN time-unit parameters not yet qualified; use sample units")
  .etr_assert(is.numeric(delay)&&length(delay)==1L&&is.finite(delay)&&
    delay==as.integer(delay)&&delay>=1L,
    "delay must be a positive sample count")
  .etr_assert(is.numeric(theiler_window)&&length(theiler_window)==1L&&
    is.finite(theiler_window)&&theiler_window==as.integer(theiler_window)&&
    theiler_window>=0L,
    "theiler_window must be a nonnegative sample count")
  .etr_assert(is.numeric(max_dimension)&&length(max_dimension)==1L&&
    is.finite(max_dimension)&&max_dimension==as.integer(max_dimension)&&
    max_dimension>=1L,
    "max_dimension must be a positive integer")
  .etr_assert(is.numeric(rtol)&&length(rtol)==1L&&is.finite(rtol)&&rtol>0&&
    is.numeric(atol)&&length(atol)==1L&&is.finite(atol)&&atol>0,
    "rtol and atol must be positive finite")
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    dimension%in%trajectories$dimension_names,
    "Unknown dimension")
  if(is.character(curve))curve<-match(curve,trajectories$curve_ids)
  .etr_assert(is.numeric(curve)&&length(curve)==1L&&!is.na(curve)&&
    curve==as.integer(curve)&&curve>=1L&&
    curve<=length(trajectories$curve_ids),"curve index/ID out of range")
  y<-as.vector(trajectories$values[curve,,match(dimension,
    trajectories$dimension_names)])
  n<-length(y);delay<-as.integer(delay)
  tw<-as.integer(theiler_window)
  .etr_assert(n<=2500L,
    "native exact FNN nearest-neighbor search limited to 2500 samples")
  scale<-sqrt(mean((y-mean(y))^2))
  .etr_assert(scale>0,"FNN diagnostics require a non-constant signal")
  rows<-list()
  for(m in seq_len(as.integer(max_dimension))){
    start<-m*delay
    if(start>=n-1L)break
    endpoints<-(start+1L):n
    st<-sapply(0:(m-1L),function(lag)y[endpoints-lag*delay])
    if(is.null(dim(st)))st<-matrix(st,ncol=1L)
    added<-y[endpoints-m*delay]
    nr<-nrow(st)
    .etr_assert(nr>=2L,"FNN requires at least two reconstructed states")
    failed<-logical(nr)
    for(i in seq_len(nr)){
      dists<-sqrt(rowSums((st-matrix(st[i,],nr,m,byrow=TRUE))^2))
      candidates<-which(seq_len(nr)!=i &
        abs(seq_len(nr)-i)>tw & is.finite(dists) & dists>0)
      .etr_assert(length(candidates)>0L,
        "no positive-distance temporally separated nearest neighbor")
      idx<-candidates[which.min(dists[candidates])]
      extra<-abs(added[i]-added[idx])
      newdist<-sqrt(dists[idx]^2+extra^2)
      failed[i]<-extra/dists[idx]>rtol||newdist/scale>atol
    }
    rows[[length(rows)+1L]]<-data.frame(
      embedding_dimension=as.integer(m),
      false_neighbor_fraction=mean(failed),
      n_reference_states=as.integer(nr),rtol=rtol,atol=atol)
  }
  .etr_assert(length(rows)>0L,
    "no embedding dimensions supported by available series length")
  structure(list(table=do.call(rbind,rows),
    curve_id=trajectories$curve_ids[curve],dimension=dimension,
    delay_samples=delay,theiler_window_samples=tw,rtol=rtol,atol=atol,
    provenance=list(operation="embedding_dimension_diagnostics",
      criterion="Kennel-Brown-Abarbanel false nearest neighbors",
      automatic_dimension_selection=FALSE,missing_policy="error",
      sampling_contract="approximately_regular_grid",sampling_step=step)),
    class="etr_embedding_dimension_diagnostics")
}

#' Explicit irregular-long-dataframe projection to a supplied fixed grid
#' @param data Source samples in long-format R data.frame.
#' @param curve_columns Curve-identifying columns.
#' @param time_column Numeric sample time column.
#' @param value_columns Functional channels.
#' @param grid Declared complete finite increasing target time grid.
#' @param metadata_columns Optional curve-constant fields.
#' @param method Explicit native resampling interpolation method.
#' @param max_gap Optional maximum bridgeable source sampling gap.
#' @param coordinate_system,time_unit Declared original measurement semantics.
#' @export
etr_from_irregular_long_dataframe <- function(data,curve_columns,time_column,
    value_columns=c("x","y"),grid,metadata_columns=NULL,method="linear",
    max_gap=NULL,coordinate_system="unknown",time_unit="unknown"){
  ir<-etr_from_irregular_long_native(data,curve_columns,time_column,
    value_columns,metadata_columns,coordinate_system,time_unit)
  etr_resample_irregular_to_grid(ir,grid,method=method,max_gap=max_gap)
}


#' Explicit interpolated crossings of a declared Poincare section
#' @param trajectories Complete common-grid native functional trajectories.
#' @param curve One-based curve index or exact source curve ID.
#' @param section_dimension Scalar crossing channel.
#' @param section_value Declared finite scalar section threshold.
#' @param direction Positive, negative, or both crossing orientations.
#' @param state_dimensions Nonempty explicit non-section state channels.
#' @export
etr_poincare_crossings <- function(trajectories,curve,section_dimension,
    section_value,direction,state_dimensions=NULL) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.character(section_dimension)&&
    length(section_dimension)==1L&&section_dimension%in%
    trajectories$dimension_names,"Unknown section_dimension")
  .etr_assert(is.numeric(section_value)&&length(section_value)==1L&&
    is.finite(section_value),"section_value must be finite")
  .etr_assert(is.character(direction)&&length(direction)==1L&&
    direction%in%c("positive","negative","both"),
    "direction must be 'positive', 'negative', or 'both'")
  .etr_assert(is.character(state_dimensions)&&length(state_dimensions)>0L&&
    !anyNA(state_dimensions)&&!anyDuplicated(state_dimensions)&&
    all(state_dimensions%in%trajectories$dimension_names)&&
    !(section_dimension%in%state_dimensions),
    "state_dimensions must explicitly select distinct non-section channels")
  if(is.character(curve))curve<-match(curve,trajectories$curve_ids)
  .etr_assert(is.numeric(curve)&&length(curve)==1L&&!is.na(curve)&&
    curve==as.integer(curve)&&curve>=1L&&
    curve<=length(trajectories$curve_ids),"curve index or ID is out of range")
  v<-matrix(trajectories$values[curve,,,drop=FALSE],
    nrow=length(trajectories$time),
    ncol=length(trajectories$dimension_names))
  idx<-match(state_dimensions,trajectories$dimension_names)
  q<-v[,match(section_dimension,trajectories$dimension_names)]-section_value
  left<-integer();fractions<-numeric()
  for(i in seq_len(length(q)-1L)){
    a<-q[i];b<-q[i+1L]
    positive<-a<0 && b>=0
    negative<-a>0 && b<=0
    if(!((direction=="positive"&&positive)||
         (direction=="negative"&&negative)||
         (direction=="both"&&(positive||negative))))next
    denom<-b-a
    if(denom==0)next
    frac<- -a/denom
    if(frac>=0&&frac<=1){left<-c(left,i);fractions<-c(fractions,frac)}
  }
  .etr_assert(length(left)>0L,
    "no crossings satisfy declared section and direction")
  states<-matrix(0,length(left),length(idx))
  times<-numeric(length(left))
  for(i in seq_along(left)){
    j<-left[i];w<-fractions[i]
    states[i,]<-v[j,idx]+w*(v[j+1L,idx]-v[j,idx])
    times[i]<-trajectories$time[j]+
      w*(trajectories$time[j+1L]-trajectories$time[j])
  }
  provenance<-list(operation="poincare_crossings",
    source_provenance=trajectories$provenance,
    interpolation="linear_between_observed_samples",
    section_dimension=section_dimension,section_value=section_value,
    direction=direction,state_dimensions=as.list(state_dimensions),
    experimental=TRUE)
  structure(list(states=states,times=times,
    left_indices=as.integer(left-1L),fractions=fractions,
    curve_id=trajectories$curve_ids[curve],
    section_dimension=section_dimension,section_value=section_value,
    direction=direction,state_dimensions=state_dimensions,
    provenance=provenance),class="etr_poincare_crossings")
}

#' Local affine return map of consecutive declared section crossings
#' @param crossings Native Poincare crossing result (at least 3 crossings).
#' @param reference Explicit mean/median reference or numeric state vector.
#' @param neighborhood_radius Radius neighborhood, mutually exclusive with n_neighbors.
#' @param n_neighbors Count of nearest transition origins to the reference.
#' @export
etr_fit_local_return_map <- function(crossings,reference,
    neighborhood_radius=NULL,n_neighbors=NULL) {
  .etr_assert(inherits(crossings,"etr_poincare_crossings") &&
    is.matrix(crossings$states)&&is.numeric(crossings$states) &&
    nrow(crossings$states)>=3L&&ncol(crossings$states)>=1L &&
    all(is.finite(crossings$states)),
    "at least three finite Poincare crossings required")
  .etr_assert(xor(is.null(neighborhood_radius),is.null(n_neighbors)),
    "supply exactly one of neighborhood_radius or n_neighbors")
  values<-crossings$states
  n<-nrow(values)-1L;nd<-ncol(values)
  x<-values[seq_len(n),,drop=FALSE]
  y<-values[seq.int(2L,n+1L),,drop=FALSE]
  if(is.character(reference)&&length(reference)==1L) {
    .etr_assert(reference%in%c("mean","median"),
      "reference string must be 'mean' or 'median'")
    state<-if(reference=="mean")colMeans(x)else
      apply(x,2L,stats::median)
    refpolicy<-reference
  }else{
    .etr_assert(is.numeric(reference)&&is.null(dim(reference))&&
      length(reference)==nd&&all(is.finite(reference)),
      "reference state must be a finite vector matching state dimensions")
    state<-as.numeric(reference);refpolicy<-"supplied_state"
  }
  diff<-sweep(x,2L,state,"-")
  distances<-sqrt(rowSums(diff^2))
  if(!is.null(neighborhood_radius)){
    .etr_assert(is.numeric(neighborhood_radius)&&
      length(neighborhood_radius)==1L&&is.finite(neighborhood_radius)&&
      neighborhood_radius>0,
      "neighborhood_radius must be positive finite")
    selected<-which(distances<=neighborhood_radius)
    policy<-"radius";value<-neighborhood_radius
  }else{
    .etr_assert(is.numeric(n_neighbors)&&length(n_neighbors)==1L&&
      is.finite(n_neighbors)&&n_neighbors==as.integer(n_neighbors)&&
      n_neighbors>=1L&&n_neighbors<=n,
      "n_neighbors must be a positive integer within transition count")
    selected<-order(distances,seq_along(distances))[seq_len(n_neighbors)]
    policy<-"n_neighbors";value<-as.integer(n_neighbors)
  }
  .etr_assert(length(selected)>=nd+1L,
    paste("local affine return map requires at least",nd+1L,
      "selected transitions"))
  design<-cbind(1,sweep(x[selected,,drop=FALSE],2L,state,"-"))
  .etr_assert(qr(design)$rank==ncol(design),
    "selected return-map neighborhood is rank deficient")
  condition<-kappa(design,exact=TRUE)
  .etr_assert(is.finite(condition),
    "selected return-map design has nonfinite condition number")
  response<-sweep(y[selected,,drop=FALSE],2L,state,"-")
  coef<-qr.solve(design,response)
  if(is.null(dim(coef)))coef<-matrix(coef,ncol=nd)
  fit<-design%*%coef;resid<-response-fit
  jacobian<-t(coef[-1L,,drop=FALSE])
  r2<-vapply(seq_len(nd),function(j){
    target<-response[,j];denom<-sum((target-mean(target))^2)
    if(denom<=0)NaN else 1-sum(resid[,j]^2)/denom
  },numeric(1L))
  provenance<-list(operation="fit_local_return_map",
    crossing_provenance=crossings$provenance,
    reference_policy=refpolicy,neighborhood_policy=policy,
    neighborhood_value=value,n_selected_transitions=length(selected),
    design_condition_number=condition,fit="local_affine_least_squares",
    experimental=TRUE,
    interpretation_boundary=paste(
      "empirical local return-map Jacobian; not a variational-equation",
      "monodromy matrix or classical Floquet multiplier calculation"))
  structure(list(reference_state=as.numeric(state),
    selected_transition_indices=as.integer(selected-1L),
    jacobian=jacobian,intercept=as.numeric(coef[1L,]),
    residuals=resid,r_squared=r2,design_condition_number=condition,
    neighborhood_policy=policy,neighborhood_value=value,
    n_transitions=length(selected),provenance=provenance),
    class="etr_local_return_map")
}
