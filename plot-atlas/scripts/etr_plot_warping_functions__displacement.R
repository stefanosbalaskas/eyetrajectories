# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
tt <- as.numeric(0:6)
vals <- array(0,c(2L,length(tt),1L))
vals[1L,,1L] <- sin(tt/3)
vals[2L,,1L] <- cos(tt/3)
x <- etr_trajectory_set(tt,vals,c("a","b"),"x",
  coordinate_system="arbitrary",time_unit="s")
registered <- etr_register_landmarks(x,
  source_landmarks=matrix(c(2,4),nrow=2L,ncol=1L),
  target_landmarks=3)
etr_plot_warping_functions(registered,displacement=TRUE)
