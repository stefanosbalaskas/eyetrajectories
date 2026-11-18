# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
tt <- seq(0,1,length.out=301L)
state <- array(0,c(1L,length(tt),2L))
state[1,,1L] <- sin(12*pi*tt)
state[1,,2L] <- cos(12*pi*tt)+.05*tt+.02*sin(4*pi*tt)
trajectory <- etr_trajectory_set(tt,state,"cycle_1",c("x","y"),
  coordinate_system="arbitrary",time_unit="s")
crossings <- etr_poincare_crossings(trajectory,curve=1L,
  section_dimension="x",section_value=0,direction="positive",
  state_dimensions="y")
etr_plot_poincare_return_map(crossings)
