# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
surrogate <- structure(list(surrogate_statistics = c(0.21, 0.24, 0.29, 0.31, 
0.37, 0.4, 0.43, 0.45, 0.49, 0.5, 0.54, 0.56, 0.6, 0.62, 0.68, 
0.71, 0.76, 0.79, 0.82, 0.85, 0.91), observed_statistic = 0.73, 
    p_value = 0.2272727272727, statistic = "largest_lyapunov", 
    method = "iaaft", provenance = list(source = "synthetic_plot_contract", 
        independent_validation = FALSE)), class = "etr_surrogate_nonlinearity")
etr_plot_surrogate_nonlinearity(surrogate,bins=6L)
