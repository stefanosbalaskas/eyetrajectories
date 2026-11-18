# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
grid <- seq(0,1,length.out=11L)
w <- etr_trapezoid_weights(grid)
scale <- sqrt(2*sum((grid-.5)^2*w))
modes <- list(
 function(t)matrix(1/sqrt(2),length(t),2L),
 function(t)cbind((t-.5)/scale,(.5-t)/scale))
sim <- etr_simulate_functional_process(
 mean=function(t)matrix(0,length(t),2L),
 eigenfunctions=modes,eigenvalues=c(2,.6),
 truth_grid=grid,n_participants=18L,
 dimension_names=c("x","y"),observation_design="irregular",
 observation_times=rep(list(grid),18L),
 measurement_noise_sd=sqrt(.05),random_state=42L)
joint <- etr_fit_sparse_mfpca_native(sim$observations,
 n_components=2L,evaluation_grid=grid,
 mean_bandwidth=.45,covariance_bandwidth=.65,
 measurement_error_variance=rep(.05,2L),psd_action="project")
etr_plot_sparse_mfpca_component(joint,component=0L)
