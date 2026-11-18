# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
set.seed(2506L)
source_states <- sample(0:1,220L,replace=TRUE)
target_states <- c(0L,head(source_states,-1L))
flip <- runif(220L)<.1
target_states[flip] <- 1L-target_states[flip]
te <- etr_transfer_entropy_shift_test(source_states,target_states,
  n_surrogates=49L,seed=2507L)
etr_plot_transfer_surrogates(te)
