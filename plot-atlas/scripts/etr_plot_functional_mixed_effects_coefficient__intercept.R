# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
n <- 18L; tt <- seq(0,1,length.out=17L)
groups <- rep(sprintf("p%02d",1:6),each=3L)
z <- rep(c(-1,0,1),6L)+rep((1:6-3.5)/10,each=3L)
Y <- array(0,c(n,length(tt),1L))
for(i in seq_len(n)){
  g <- match(groups[i],unique(groups))
  Y[i,,1L] <- 1+.55*sin(pi*tt)+.7*z[i]*cos(pi*tt)+
   .15*g*sin(2*pi*tt)+.1*sin(6*pi*tt+.4*i)+
   .05*cos(3*pi*tt+i*.7)+.025*i*tt
}
x <- etr_trajectory_set(tt,Y,sprintf("c%02d",1:n),"x",
  metadata=data.frame(participant_id=groups),time_unit="s",
  coordinate_system="normalized")
design <- data.frame(curve_id=x$curve_ids,exposure=z)
mixed <- etr_fit_functional_mixed_effects_regression(x,design,
  predictors="exposure",participant_column="participant_id",
  dimension="x")
etr_plot_functional_mixed_effects_coefficient(mixed,coefficient="Intercept")
