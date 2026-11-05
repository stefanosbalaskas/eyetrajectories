# Shared deterministic complete functional participant-bundle fixture.
.etr_mixed_sensitivity_fixture<-function(){
  n<-18L;tt<-seq(0,1,length.out=9L)
  yy<-array(0,c(n,9L,1L))
  for(i in seq_len(n))yy[i,,1L]<-.4+.12*sin(2*pi*tt)+
    .04*floor((i-1L)/3L)+.06*((i%%3)==1L)*cos(pi*tt)+
    .025*sin(i*.7)*tt
  tr<-etr_trajectory_set(tt,yy,paste0("id",seq_len(n)),
    "y",metadata=data.frame(participant_id=
      paste0("p",rep(seq_len(6L),each=3L))),
    coordinate_system="unknown",time_unit="s")
  design<-data.frame(curve_id=rev(tr$curve_ids),
    x=as.numeric((rev(seq_len(n))%%3)==1L))
  list(tr=tr,design=design)
}
