# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
s <- etr_simulate_hierarchical(n_subjects=20L,trials_per_subject=3L,
  n_time=41L,seed=2501L)
band <- etr_bootstrap_mean_band(s$trajectories,s$participant,
  B=99L,alpha=.10,seed=2502L)
etr_plot_functional_band(band,dimension=1L,interval="simultaneous")
