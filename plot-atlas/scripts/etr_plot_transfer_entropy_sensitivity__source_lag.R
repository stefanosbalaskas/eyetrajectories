# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
set.seed(4404L)
source <- sample(0:1,180L,replace=TRUE)
target <- c(0L,head(source,-1L))
noise <- runif(180L)<.16
target[noise] <- 1L-target[noise]
condition <- sample(0:1,180L,replace=TRUE)
shifts <- as.integer(c(3,7,11,17,23,29,37,43,59,67,71))
sensitivity <- etr_transfer_entropy_parameter_sensitivity(source,target,
  target_histories=1L,source_histories=1L,source_lags=1:4)
etr_plot_transfer_entropy_sensitivity(sensitivity,parameter="source_lag")
