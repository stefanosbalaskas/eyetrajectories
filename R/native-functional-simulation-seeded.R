# Frozen eyetrajectoriespy 1.2.0 consumes NumPy's PCG64 in C array order.
# The shape > 1 gamma sampler follows NumPy 2.3.5 distributions.c.
# Redistribution notices are in inst/licenses/NUMPY-ZIGGURAT.txt.

.etr_functional_simulation_seed <- function(random_state,random_engine) {
  if(identical(random_engine,"base_R"))
    return(.etr_scenario_integer(random_state,"random_state",0L))
  .etr_assert(is.numeric(random_state)&&is.null(dim(random_state))&&
    length(random_state)==1L&&is.finite(random_state)&&random_state>=0&&
    random_state<2^53&&random_state==floor(random_state),
    "NumPy simulation random_state must be an exactly represented integer in [0, 2^53)")
  random_state
}

.etr_functional_simulation_engine_label <- function(random_engine) {
  if(identical(random_engine,"numpy"))"numpy_pcg64" else "base_R_not_NumPy_PCG64"
}

.etr_functional_simulation_numpy_gamma <- function(rng,shape) {
  # Both the supported Student-t df/2 and the fixed Beta(4,4) shapes
  # exceed one, so this path needs only normal and uniform PCG64 draws.
  b<-shape-1/3
  c<-1/sqrt(9*b)
  repeat {
    x<-rng$normal(1L)
    v<-1+c*x
    if(v<=0)next
    v<-v*v*v
    u<-rng$uniform(1L)
    if(u<1-0.0331*(x*x)*(x*x)||log(u)<0.5*x*x+b*(1-v+log(v)))
      return(b*v)
  }
}

.etr_functional_simulation_normal_scores <- function(n,variances,rng) {
  k<-length(variances)
  draws<-if(is.null(rng))matrix(stats::rnorm(n*k),n,k) else
    matrix(rng$normal(as.double(n)*k),n,k,byrow=TRUE)
  draws*matrix(rep(sqrt(variances),each=n),n,k)
}

.etr_functional_simulation_numpy_noise <- function(covariance,rng) {
  nd<-ncol(covariance)
  # The source's allclose check skips the draw entirely for small noise.
  if(all(abs(covariance)<=1e-8))return(function(n)matrix(0,n,nd))
  # Generator.multivariate_normal defaults to an SVD factor. Its signed
  # basis can depend on LAPACK, so fixed-seed values assume a matching SVD.
  decomposition<-svd(covariance,nv=0)
  factor<-sweep(decomposition$u,2L,sqrt(decomposition$d),"*")
  function(n)matrix(rng$normal(as.double(n)*nd),n,nd,byrow=TRUE)%*%t(factor)
}
