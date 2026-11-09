# Frozen source Python 1.2 sparse_partial_conformal.py;
# disjoint calibration, exact observations, grouped maximum, finite rank.
.etr_spnpc_fixture<-function(n=12L){
  times<-vector("list",n);values<-vector("list",n)
  for(i in seq_len(n)){
    tt<-c(.12,.24,.36,.48,.60,.72,.84)
    y<-(-.5)+.18*tt+.25*sin(pi*tt+.19*i)+
      .16*cos(2*pi*tt+.31*i)+.03*sin(i+tt*6)
    times[[i]]<-tt
    values[[i]]<-matrix(y,ncol=1L)
  }
  etr_irregular_trajectory_set(
    times,values,sprintf("cal_%03d",seq_len(n)),"signal",
    metadata=data.frame(batch=sprintf("cal_g%d",
      (seq_len(n)-1L)%/%3L+1L)),
    coordinate_system="degrees",time_unit="s")
}
.etr_spnpc_target<-function(){
  x<-.etr_spnp_partial_target_safe()
  x$metadata$batch<-"target_unique"
  x
}
.etr_spnp_partial_target_safe<-function(){
  tt<-c(.12,.24,.36,.48,.60,.72,.84)
  y<-(-.5)+.18*tt+.32*sin(pi*tt)+.12*cos(2*pi*tt)
  etr_irregular_trajectory_set(
    list(tt),list(matrix(y,ncol=1L)),
    "target_conformal","signal",
    metadata=data.frame(batch="target_unique"),
    coordinate_system="degrees",time_unit="s")
}

