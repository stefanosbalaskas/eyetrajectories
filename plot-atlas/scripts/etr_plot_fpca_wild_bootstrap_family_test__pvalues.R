# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
n <- 24L;tt <- seq(0,1,length.out=13L)
val <- array(0,c(n,length(tt),1L))
for(i in seq_len(n)) val[i,,1L] <- .25*sin(2*pi*tt)+
 .13*cos(i*.8)*cos(pi*tt)+.09*sin(i*.57)*sin(3*pi*tt)+
 .07*cos(i*.21)*tt^2
x <- etr_trajectory_set(tt,val,sprintf("curve%02d",1:n),"x",
  time_unit="s",coordinate_system="unknown")
y <- vapply(seq_len(n),function(i)
 .6*cos(i*.8)-.35*sin(i*.57)+.04*cos(i*.37),numeric(1L))
draws <- outer(seq_len(20L),seq_len(n),function(i,j)
 .9*sin(i*j*.49)+.4*cos(i+j*.23))
p <- etr_wild_bootstrap_fpca_projection(x,y,n_bootstrap=20L,
 residual_components=2L,inference_components=3L,
 multiplier_draws=draws)
family <- etr_fpca_wild_bootstrap_projection_family_test(
 p,null_values=0,significance_level=.05)
etr_plot_fpca_wild_bootstrap_family_test(family,max_targets=8L,show_targetwise=TRUE)
