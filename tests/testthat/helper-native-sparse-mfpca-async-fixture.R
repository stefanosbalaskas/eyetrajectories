# Frozen 1.2 direct asynchronous source fixture:
# 24 curves, genuine x-only/y-only plus simultaneous coordinates.
.etr_spna_fixture<-function(){
  n<-24L;times<-vector("list",n);values<-vector("list",n)
  j<-0:11
  for(i in seq_len(n)){
    g<-(i-1L)%/%4L+1L
    t<-.03+.94*j/11
    a<-sin(.53*g);b<-cos(.41*i);c<-sin(.69*i)
    x<-.23+.16*t+.49*a*sin(pi*t)+.24*b*cos(3*pi*t)+
      .19*c*sin(2*pi*t)+.02*sin(.7*i+8*t)
    y<-.14+.21*t+.36*b*sin(2*pi*t)+.31*a*cos(pi*t)+
      .21*c*cos(3*pi*t)+.03*cos(.37*i+6*t)
    keep_x<-(j%%2L==0L)|(j%%5L==0L)
    keep_y<-(j%%2L==1L)|(j%%5L==0L)
    x[!keep_x]<-NaN;y[!keep_y]<-NaN
    times[[i]]<-t;values[[i]]<-cbind(x,y)
  }
  etr_irregular_trajectory_set(times,values,
    sprintf("async_%03d",seq_len(n)),c("x","y"),
    metadata=data.frame(batch=rep(seq_len(6L),each=4L)),
    coordinate_system="degrees",time_unit="s")
}
.etr_spna_options<-function(){
  list(dimensions=c("x","y"),n_components=2L,
    evaluation_grid=seq(.10,.86,length.out=9L),
    mean_bandwidth=.7,covariance_bandwidth=.85,
    measurement_error="fixed_matrix",
    measurement_error_covariance=matrix(c(.09,.015,.015,.08),2L),
    analysis_support_action="restrict",
    same_time_tolerance=0,
    psd_action="project",score_ridge=.003,
    score_condition_limit=1e12,
    min_score_observations=2L,
    mean_min_local_points=3L,
    covariance_min_local_pairs=6L)
}
