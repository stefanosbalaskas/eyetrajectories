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
