# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
sim <- etr_simulate_functional_process(
  mean=function(t)0*t,
  eigenfunctions=list(function(t)sqrt(2)*sin(pi*t)),
  eigenvalues=1,truth_grid=seq(0,1,length.out=41L),
  n_participants=3L,trials_per_participant=2L,
  dimension_names="value",coordinate_system="unknown",time_unit="s",
  participant_eigenvalues=.2,trial_eigenvalues=.1,
  measurement_noise_sd=.04,random_state=821L)
etr_plot_functional_simulation_curve(sim,curve=2L,dimension="value")
