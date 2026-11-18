# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
s <- etr_simulate_sparse_known_truth(n_subjects=35L,seed=2505L)
support <- etr_sparse_design_diagnostics(s$curves,bins=10L)
etr_plot_sparse_support(support)
