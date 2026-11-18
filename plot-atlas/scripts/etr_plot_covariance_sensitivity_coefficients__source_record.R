# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
sensitivity <- list(specifications = list(list(name = "reference"), list(name = "alternative")), 
    reference_label = "reference", fits = list(reference = list(
        time_unit = "s")), coefficient_frame = structure(list(
        coefficient = c("dose", "dose", "dose", "dose", "dose", 
        "dose", "dose", "dose", "dose", "dose", "dose", "dose", 
        "dose", "dose", "dose", "dose", "dose", "dose"), model = c("reference", 
        "reference", "reference", "reference", "reference", "reference", 
        "reference", "reference", "reference", "alternative", 
        "alternative", "alternative", "alternative", "alternative", 
        "alternative", "alternative", "alternative", "alternative"
        ), time = c(0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 
        0.875, 1, 0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 
        1), difference_from_reference = c(0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0.1, 0.170710678118655, 0.2, 0.170710678118655, 
        0.1, 0.0292893218813453, 0, 0.0292893218813452, 0.1)), class = "data.frame", row.names = c(NA, 
    -18L)), band_width_frame = structure(list(coefficient = c("dose", 
    "dose", "dose", "dose", "dose", "dose", "dose", "dose", "dose", 
    "dose", "dose", "dose", "dose", "dose", "dose", "dose", "dose", 
    "dose"), model = c("reference", "reference", "reference", 
    "reference", "reference", "reference", "reference", "reference", 
    "reference", "alternative", "alternative", "alternative", 
    "alternative", "alternative", "alternative", "alternative", 
    "alternative", "alternative"), time = c(0, 0.125, 0.25, 0.375, 
    0.5, 0.625, 0.75, 0.875, 1, 0, 0.125, 0.25, 0.375, 0.5, 0.625, 
    0.75, 0.875, 1), band_width_ratio_to_reference = c(1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1.3, 1.27071067811865, 1.2, 1.12928932188135, 
    1.1, 1.12928932188135, 1.2, 1.27071067811865, 1.3)), class = "data.frame", row.names = c(NA, 
    -18L)))
etr_plot_covariance_sensitivity_coefficients(sensitivity,"dose")
