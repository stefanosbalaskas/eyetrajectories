# Frozen Python 1.2 public fit_sparse_mfpca:
# direct directional sparse cross-covariance and joint PACE vs native R.
# Existing marginal fdapace source differences remain separately declared.

.etr_spnm_fixture<-function(){
  n<-24L;times<-vector("list",n);values<-vector("list",n)
  for(i in seq_len(n)){
    t<-.03+.94*seq(0,1,length.out=8L)+
      .004*((i-1L)%%4L)*sin(pi*seq(0,1,length.out=8L))
    a<-sin(i*.31);b<-cos(i*.43);c<-sin(i*.83)
    x<-.5+.18*t+.38*a*sin(pi*t)+
      .24*b*cos(2*pi*t)+.08*c*sin(3*pi*t)
    y<-.12+.26*t+.28*b*sin(2*pi*t)+
      .19*a*cos(pi*t)+.11*c*cos(3*pi*t)+
      .06*sin(.27*i+4*pi*t)
    times[[i]]<-t
    values[[i]]<-cbind(x,y)
  }
  etr_irregular_trajectory_set(times,values,
    sprintf("spnm_%03d",seq_len(n)),
    c("x","y"),metadata=data.frame(
      block=rep(seq_len(6L),each=4L)),
    coordinate_system="degrees",time_unit="s")
}
.etr_spnm_args<-function(){
  list(dimensions=c("x","y"),n_components=2L,
    evaluation_grid=seq(.08,.92,length.out=9L),
    mean_bandwidth=.5,covariance_bandwidth=.85,
    measurement_error="diagonal",
    measurement_error_variance=c(.08,.10),
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    min_score_time_points=2L,score_failure_action="error",
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
}

