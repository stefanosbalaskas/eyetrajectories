# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
n <- 14L; tt <- seq(0,1,length.out=15L)
val <- array(0,c(n,length(tt),1L))
for(i in seq_len(n)) val[i,,1L] <-
  sin(pi*tt)*(1+i/16)+.16*cos(2*pi*tt)*(i%%4)/3+tt*i/18
x <- etr_trajectory_set(tt,val,sprintf("c%02d",1:n),"gaze",
  coordinate_system="normalized",time_unit="s")
y <- .2+1.2*seq_len(n)/n+.2*sin(seq_len(n))
u <- etr_bootstrap_fpca_regression_uncertainty(
  x,y,n_bootstrap=20L,n_components=1L,random_state=123L)
b <- etr_fpca_regression_slope_simultaneous_band(u,
  confidence_level=.90,simultaneous_scope="global")
etr_plot_fpca_regression_slope_band(b,dimension="gaze")
