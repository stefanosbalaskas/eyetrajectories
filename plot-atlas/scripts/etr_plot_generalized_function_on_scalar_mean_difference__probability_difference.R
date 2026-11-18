# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
fit <- list(time=c(0,.5,1),time_unit="seconds",
  family="binomial",link="logit",predictor_names="treatment",
  coefficient_names=c("Intercept","treatment"),
  basis=cbind(c(1,1,1),c(0,.5,1)),
  basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),
  coefficient_functions=rbind(c(.2,.25,.3),c(.5,.625,.75)),
  coefficient_standard_errors=rbind(c(.12,.12,.12),c(.14,.16,.17)),
  parameter_covariance=diag(c(.04,.01,.09,.04)),
  scalar_design_matrix=rbind(c(1,0),c(1,1)),exposure=NULL,
  provenance=list(source="synthetic_plot_contract"))
draws <- array(NA_real_,c(4L,2L,3L))
draws[1L,,] <- rbind(c(.10,.20,.25),c(.35,.55,.65))
draws[2L,,] <- rbind(c(.22,.26,.32),c(.48,.58,.68))
draws[3L,,] <- rbind(c(.27,.29,.38),c(.51,.59,.73))
draws[4L,,] <- rbind(c(.32,.36,.42),c(.65,.80,.85))
bootstrap <- list(reference=fit,bootstrap_coefficient_functions=draws,
  provenance=list(source="synthetic_plot_contract"))
pred <- etr_bootstrap_generalized_function_on_scalar_predictions(
  bootstrap,data.frame(profile_id=c("A","B"),treatment=c(0,1)))
difference <- etr_generalized_function_on_scalar_mean_difference_band(
  pred,profile_a="B",profile_b="A",confidence_level=.5)
etr_plot_generalized_function_on_scalar_mean_difference(difference)
