# Frozen Python 1.2 scientific covariance contract:
# _functional_simulation.py::_resolve_noise_covariance().
# Native R source implementation; no Python or reticulate runtime dependency.
# Source commit c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_functional_simulation_noise_spec <- function(
    measurement_noise_sd,measurement_noise_covariance,nd) {
  if(is.null(measurement_noise_sd))measurement_noise_sd<-0
  .etr_assert(is.numeric(measurement_noise_sd)&&
    is.null(dim(measurement_noise_sd))&&
    length(measurement_noise_sd)%in%c(1L,nd)&&
    all(is.finite(measurement_noise_sd))&&
    all(measurement_noise_sd>=0),
    "measurement_noise_sd must be finite nonnegative scalar or per dimension")
  sd<-rep(as.numeric(measurement_noise_sd),length.out=nd)
  if(is.null(measurement_noise_covariance)) {
    covariance<-diag(sd^2,nrow=nd,ncol=nd)
    return(list(sd=sd,covariance=covariance,sqrt=NULL))
  }
  covariance<-measurement_noise_covariance
  .etr_assert(is.matrix(covariance)&&is.numeric(covariance)&&
    identical(dim(covariance),c(nd,nd)),
    "measurement_noise_covariance must have shape (n_dimensions,n_dimensions)")
  .etr_assert(all(is.finite(covariance)),
    "measurement_noise_covariance must contain only finite values")
  .etr_assert(max(abs(covariance-t(covariance)))<=1e-12,
    "measurement_noise_covariance must be symmetric")
  # NumPy uses eigvalsh for PSD validation and tolerates negative
  # roundoff down to -1e-12, while symmetric roots clip at zero.
  # Return the declared source covariance unchanged for provenance/truth.
  ev<-eigen(covariance,symmetric=TRUE)
  .etr_assert(all(is.finite(ev$values))&&min(ev$values)>= -1e-12,
    "measurement_noise_covariance must be positive semidefinite")
  .etr_assert(!any(sd>0),
    "measurement_noise_sd and measurement_noise_covariance cannot both specify non-zero measurement noise")
  sd<-sqrt(pmax(diag(covariance),0))
  root<-ev$vectors %*% diag(sqrt(pmax(ev$values,0)),nrow=nd) %*%
    t(ev$vectors)
  list(sd=as.numeric(sd),covariance=covariance,sqrt=root)
}

.etr_functional_simulation_correlated_noise <- function(
    n,nt,nd,root) {
  .etr_assert(is.matrix(root)&&identical(dim(root),c(nd,nd))&&
    all(is.finite(root)),
    "correlated Gaussian noise root must be finite and square")
  if(!any(root!=0))return(array(0,c(n,nt,nd)))
  # Rows index curve/time, columns index channels; symmetric root A
  # gives Cov(Z %*% A)=A'A=covariance. No NumPy PCG64 stream equivalence.
  independent<-matrix(stats::rnorm(n*nt*nd),nrow=n*nt,ncol=nd)
  array(as.numeric(independent %*% root),dim=c(n,nt,nd))
}
