# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
nonlinearity <- list(surrogate_statistics = c(0.08, 0.11, 0.14, 0.16, 0.19, 0.22, 
0.26, 0.31, 0.37, 0.41, 0.46), observed_statistic = 0.33, statistic = "largest_lyapunov", 
    p_value = 0.25, provenance = list(source = "synthetic_plot_contract"))
etr_plot_multivariate_surrogate_nonlinearity(nonlinearity,bins=6L)
