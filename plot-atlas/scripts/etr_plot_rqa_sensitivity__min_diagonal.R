# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
time <- seq(0,1,length.out=81L)
values <- array(0,c(12L,length(time),2L))
for(i in seq_len(12L)){
  phase <- (i-1)/35
  values[i,,1] <- .5+.28*sin(2*pi*(time+phase))+i/250
  values[i,,2] <- .5+.24*cos(2*pi*(time+phase))
}
paths <- etr_trajectory_set(time,values,curve_ids=paste0("synthetic_",1:12),
  dimension_names=c("x","y"),coordinate_system="normalized",time_unit="s")
rqa <- etr_rqa_parameter_sensitivity(
  paths,curve="synthetic_1",dimensions=c("x","y"),
  embedding_dimensions=2L,delays=1L,
  theiler_windows=2L,radii=.35,
  min_diagonal_lengths=c(2L,3L,4L),min_vertical_lengths=2L)
etr_plot_rqa_sensitivity(rqa,parameter="min_diagonal_length",metric="determinism")
