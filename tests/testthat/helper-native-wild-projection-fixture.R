# Loaded by testthat independently of per-file test filter.
.etr_wild_projection_fixture<-function(){
  n<-24L;time<-seq(0,1,length.out=13L)
  vals<-array(0,c(n,length(time),1L))
  for(i in seq_len(n)){
    vals[i,,1L]<-.25*sin(2*pi*time)+
      .13*cos(i*.8)*cos(pi*time)+
      .09*sin(i*.57)*sin(3*pi*time)+
      .07*cos(i*.21)*time^2
  }
  x<-etr_trajectory_set(time,vals,
    sprintf("curve%02d",seq_len(n)),"x",
    time_unit="s",coordinate_system="unknown")
  y<-vapply(seq_len(n),function(i)
    .6*cos(i*.8)-.35*sin(i*.57)+.04*cos(i*.37),numeric(1L))
  draws<-outer(seq_len(20L),seq_len(n),function(i,j)
    .9*sin(i*j*.49)+.4*cos(i+j*.23))
  list(x=x,y=y,draws=draws)
}
