# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
n <- 24L; ids <- sprintf('spn_%03d',seq_len(n))
times <- values <- vector('list',n)
for (i in seq_len(n)) {
  j <- seq(0,1,length.out=8L)
  ti <- .03+.94*j+.004*((i-1L)%%4L)*sin(pi*j)
  x <- -.5+.18*ti+.35*sin(.31*i)*sin(pi*ti)+
    .22*cos(.43*i)*cos(2*pi*ti)+.035*cos(3*pi*ti+.7*i)
  times[[i]] <- ti; values[[i]] <- matrix(x,ncol=1L)
}
irregular <- etr_irregular_trajectory_set(
  times,values,ids,'signal',
  metadata=data.frame(batch=rep(1:6,each=4L)),
  coordinate_system="degrees",time_unit="s")
fit <- etr_fit_sparse_fpca_native(irregular,'signal',n_components=1L,
  evaluation_grid=seq(.08,.92,length.out=9L),
  mean_bandwidth=.50,covariance_bandwidth=.85,
  noise_variance_method="fixed",measurement_error_variance=.07,
  analysis_support_action="restrict",psd_action="project",
  score_ridge=.002,score_condition_limit=1e12,
  mean_min_local_points=3L,covariance_min_local_pairs=6L)
etr_plot_sparse_fpca_component(fit,component=0L,sd_multiplier=2)
