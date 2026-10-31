# Shared only by native functional GEE regression and bootstrap test files.
# testthat loads helper-*.R independent of the selected test filename filter.
.etr_native_gee_fixture<-function(family="poisson",grouped=FALSE){
  time<-seq(0,1,length.out=7L)
  n<-36L;nt<-length(time)
  z<-outer(seq_len(n),seq_len(nt),function(i,j){
    if(family=="poisson") (i+2*j+(i*j)%%3)%%6
    else as.integer((i+j+i*j)%%5<2)
  })
  den<-NULL
  if(grouped){
    den<-outer(seq_len(n),seq_len(nt),
      function(i,j)3L+(i+j)%%3L)
    z<-outer(seq_len(n),seq_len(nt),
      function(i,j)(i+2*j)%%4)
    z<-pmin(z,den)
  }
  x<-etr_trajectory_set(time,array(as.numeric(z),c(n,nt,1L)),
    sprintf("curve%02d",seq_len(n)),"outcome",
    metadata=data.frame(participant_id=rep(
      sprintf("P%02d",1:12),each=3)),
    coordinate_system="unknown",time_unit="s")
  design<-data.frame(curve_id=rev(x$curve_ids),
    treatment=as.numeric((rev(seq_len(n))%%4)<2))
  list(x=x,design=design,den=den)
}
