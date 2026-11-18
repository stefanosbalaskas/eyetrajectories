# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
comparison <- structure(list(coefficient = c("Intercept", "Intercept", "Intercept", 
"dose", "dose", "dose"), time = c(0, 0.5, 1, 0, 0.5, 1), fixed_covariance_band_width = c(0.333333333333333, 
0.5, 0.666666666666667, 0.75, 0.5, 0.5), full_refit_band_width = c(0.333333333333333, 
0.5, 0.666666666666667, 0.75, 0.5, 0.5), full_refit_to_fixed_covariance_width_ratio = c(1, 
1, 1, 1, 1, 1), confidence_level = c(0.5, 0.5, 0.5, 0.5, 0.5, 
0.5), simultaneous_scope = c("coefficient", "coefficient", "coefficient", 
"coefficient", "coefficient", "coefficient")), row.names = c(NA, 
-6L), class = "data.frame")
etr_plot_functional_mixed_effects_bootstrap_comparison(comparison,"dose")
