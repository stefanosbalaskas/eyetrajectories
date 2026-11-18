# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
sensitivity <- structure(list(table = structure(list(embedding_dimension = c(2, 
3, 4, 5), requested_delay = c(1, 1, 1, 1), exponent = c(0.12, 
0.04, -0.03, 0.06), r_squared = c(0.64, 0.76, 0.71, 0.69), standard_error = c(0.06, 
0.04, 0.05, 0.05)), class = "data.frame", row.names = c(NA, -4L
)), curve_id = "synthetic_1", exponent_unit = "1/s", provenance = list(
    source = "synthetic_plot_contract")), class = "etr_kantz_parameter_sensitivity")
etr_plot_kantz_sensitivity(sensitivity,parameter="embedding_dimension",response="r_squared")
