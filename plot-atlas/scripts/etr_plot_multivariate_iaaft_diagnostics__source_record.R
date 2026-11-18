# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
diagnostics <- list(n_surrogates = 5L, reference_dimension = "x", convergence_iterations = c(4L, 
7L, 5L, 8L, 6L), spectral_errors = structure(c(0.09, 0.12, 0.08, 
0.06, 0.1, 0.11, 0.17, 0.11, 0.08, 0.14), dim = c(5L, 2L)), cross_spectral_errors = structure(c(0.03, 
0.04, 0.05, 0.04, 0.07), dim = c(5L, 1L)), provenance = list(
    source = "synthetic_plot_contract"))
etr_plot_multivariate_iaaft_diagnostics(diagnostics)
