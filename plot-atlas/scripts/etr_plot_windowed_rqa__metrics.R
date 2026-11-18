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
window <- etr_windowed_rqa(paths,curve=1L,
  window=30L,step=10L,radius=.20,theiler_window=2L)
etr_plot_windowed_rqa(window,metrics=c("recurrence_rate","determinism"))
