# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
sensitivity <- structure(list(table = structure(list(embedding_dimension = c(2, 
3, 4, 5), requested_delay = c(1, 1, 1, 1), exponent = c(0.08, 
0.15, 0.11, -0.02), r_squared = c(0.61, 0.73, 0.84, 0.68), standard_error = c(0.06, 
0.04, 0.05, 0.05)), class = "data.frame", row.names = c(NA, -4L
)), curve_id = "synthetic_1", exponent_unit = "1/s", provenance = list(
    source = "synthetic_plot_contract")), class = "etr_lyapunov_parameter_sensitivity")
etr_plot_lyapunov_sensitivity(sensitivity,parameter="embedding_dimension")
