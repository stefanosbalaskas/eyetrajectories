# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
tt <- seq(0,1,length.out=21L)
make_set <- function(ids,shift=0) {
 n<-length(ids);val<-array(0,c(n,length(tt),1L))
 for(i in seq_len(n)) val[i,,1L]<-sin(2*pi*tt)+
  .17*cos(.6*i)*cos(2*pi*tt)+.11*sin(.45*i)*sin(4*pi*tt)+
  .02*cos(tt*6*pi+.3*i)+shift*sin(6*pi*tt)
 etr_trajectory_set(tt,val,ids,"x")
}
train<-make_set(paste0("train_",1:10))
cal<-make_set(paste0("cal_",1:19))
target<-make_set(paste0("target_",1:5),shift=.09)
fit<-etr_fit_fpca(train,n_components=1L)
screen<-etr_split_conformal_fpca_anomalies(fit,cal,target,alpha=.2)
etr_plot_conformal_fpca_anomaly(screen)
