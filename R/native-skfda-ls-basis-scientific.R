# Frozen scientific source: eyetrajectoriespy 1.2.0 backends.py::to_skfda_basis
# via scikit-fda FDataGrid.to_basis -> BasisSmoother(return_basis=TRUE).
# External mathematical witness: scikit-fda _fourier_basis.py, _bspline_basis.py
# and smoothing/_basis.py. Native R source-scientific geometry, NOT a
# skfda.FDataBasis Python object or independent whole-domain certification.

.etr_skfda_source_bspline <- function(t,n_basis,order) {
  .etr_assert(is.numeric(t)&&is.null(dim(t))&&length(t)>=2L&&
    all(is.finite(t))&&all(diff(t)>0),
    "source B-spline evaluation time must be increasing finite observations")
  .etr_assert(n_basis>=order&&order>=1L,
    "source B-spline basis count must be at least spline order")
  interior<-as.integer(n_basis-order)
  domain<-range(t)
  base_knots<-seq(domain[1L],domain[2L],length.out=interior+2L)
  all_knots<-c(rep(domain[1L],as.integer(order-1L)),
    base_knots,rep(domain[2L],as.integer(order-1L)))
  B<-splines::splineDesign(all_knots,t,ord=as.integer(order),
    outer.ok=TRUE)
  # scipy.interpolate.BSpline evaluates the rightmost endpoint in the
  # last basis element. R splineDesign's right boundary convention differs.
  B[length(t),]<-0
  B[length(t),as.integer(n_basis)]<-1
  .etr_assert(identical(dim(B),c(length(t),as.integer(n_basis)))&&
    all(is.finite(B)),
    "native scikit-fda B-spline source design has invalid dimensions")
  list(B=B,knots=base_knots,evaluation_knots=all_knots)
}

.etr_skfda_source_fourier <- function(t,n_basis) {
  period<-as.numeric(max(t)-min(t))
  .etr_assert(is.finite(period)&&period>0,
    "scikit-fda Fourier source requires positive domain period")
  n_actual<-as.integer(n_basis + (1L-as.integer(n_basis %% 2L)))
  B<-matrix(0,nrow=length(t),ncol=n_actual)
  B[,1L]<-1/sqrt(period)
  pairs<-as.integer((n_actual-1L)/2L)
  if(pairs>0L)for(k in seq_len(pairs)){
    B[,2L*k]<-sqrt(2/period)*sin(2*pi*k*t/period)
    B[,2L*k+1L]<-sqrt(2/period)*cos(2*pi*k*t/period)
  }
  list(B=B,period=period,expanded_n_basis=n_actual,
    fourier_order="constant_sin1_cos1_sin2_cos2")
}

.etr_skfda_source_basis_projection <- function(trajectories,
    dimension,basis,n_basis,order) {
  # Default native-R path is unchanged. This helper uses the frozen
  # scikit-fda *sampled least-squares* estimand, not a continuous L2
  # projection or quadrature-smoothing substitute.
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "Unknown dimension for frozen scikit-fda source projection")
  .etr_assert(is.character(basis)&&length(basis)==1L&&
    !is.na(basis)&&basis%in%c("bspline","fourier"),
    "basis must be 'bspline' or 'fourier'")
  .etr_assert(is.numeric(n_basis)&&length(n_basis)==1L&&
    !is.logical(n_basis)&&is.finite(n_basis)&&n_basis==floor(n_basis)&&
    n_basis>=2L,
    "n_basis must be a positive integer >=2")
  .etr_assert(is.numeric(order)&&length(order)==1L&&
    !is.logical(order)&&is.finite(order)&&order==floor(order)&&order>=1L,
    "order must be a positive integer")
  .etr_assert(basis!="bspline"||n_basis>=order,
    "For B-splines, n_basis must be at least order")
  t<-as.numeric(trajectories$time)
  .etr_assert(length(t)>=2L&&all(is.finite(t))&&all(diff(t)>0),
    "source basis requires an increasing finite time domain")
  requested<-as.integer(n_basis)
  design<-if(basis=="bspline")
    .etr_skfda_source_bspline(t,requested,as.integer(order))
  else .etr_skfda_source_fourier(t,requested)
  B<-design$B
  n_actual<-ncol(B)
  .etr_assert(n_actual<=length(t),
    "source-scientific least squares requires sufficient observed time samples for all backend basis columns")
  .etr_assert(all(is.finite(B))&&qr(B)$rank==n_actual,
    "source-scientific least-squares basis is rank deficient on observed time")
  ncurves<-length(trajectories$curve_ids)
  .etr_assert(ncurves>=1L,
    "source scientific basis requires at least one observed curve")
  y<-matrix(trajectories$values[,,
    match(dimension,trajectories$dimension_names),drop=FALSE],
    nrow=ncurves,ncol=length(t))
  .etr_assert(all(is.finite(y)),
    "frozen source basis requires complete finite selected observations")
  # scikit-fda BasisSmoother obtains the unweighted least-squares
  # coefficients on the ORIGINAL sample times; no quadrature weights.
  # QR is numerically stable for admissible full-rank designs and solves
  # the same no-regularization objective as the source SVD least squares.
  coefficients<-t(qr.solve(B,t(y)))
  fitted<-coefficients%*%t(B)
  .etr_assert(identical(dim(coefficients),c(ncurves,n_actual))&&
    all(is.finite(coefficients))&&
    identical(dim(fitted),dim(y))&&all(is.finite(fitted)),
    "source basis coefficients or reconstructions are invalid")
  source_provenance<-trajectories$provenance
  if(is.null(source_provenance))source_provenance<-list()
  source_provenance$basis_projection<-list(
    backend="scikit-fda",
    basis=basis,
    n_basis=requested,
    order=if(basis=="bspline")as.integer(order)else NULL)
  source_projection<-list(
    backend_object=NULL,
    dimension=dimension,
    basis_type=basis,
    n_basis=requested,
    time_domain=as.numeric(range(t)),
    provenance=source_provenance)
  structure(list(
    source_projection=source_projection,
    source_backend_basis_class=if(basis=="bspline")
      "skfda.representation.basis.BSplineBasis" else
      "skfda.representation.basis.FourierBasis",
    source_backend_object_type="skfda.representation.basis.FDataBasis_not_returned",
    dimension=dimension,
    basis_type=basis,
    n_basis=requested,
    actual_backend_n_basis=n_actual,
    order=if(basis=="bspline")as.integer(order)else NULL,
    domain_range=as.numeric(range(t)),
    basis_matrix=B,
    basis_knots=if(basis=="bspline")design$knots else NULL,
    evaluation_knots=if(basis=="bspline")design$evaluation_knots else NULL,
    coefficient_matrix=coefficients,
    fitted_functions=fitted,
    fitted_grid=t,
    dataset_name=paste("eyetrajectoriespy",dimension),
    coordinate_names=dimension,
    curve_ids=trajectories$curve_ids,
    objective="unweighted_observed_grid_least_squares",
    source_fitting_semantics="scikit_fda_BasisSmoother_no_regularization",
    solver="base_R_QR_equivalent_full_rank_LS",
    source_backend="scikit_fda_R_numeric_projection_only",
    source_equivalent=FALSE,
    independently_source_certified=FALSE,
    full_backend_object_identity=FALSE),
    class=c("etr_skfda_basis_scientific_record",
      "etr_native_basis_projection","list"))
}
