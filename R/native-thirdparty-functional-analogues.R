# Source frozen: backends.py and sparse.py (eyetrajectoriespy 1.2.0).
# Native-R functional-data counterparts, NOT skfda.FDataGrid / FDApy
# instances, and NOT the scikit-fda or FDApy source estimators.

#' Copy native trajectory geometry to a backend-independent functional grid
#' @description Preserves time, values and dimension ordering exactly.
#'   Returns a native R grid, NOT Python scikit-fda FDataGrid.
#'   Strict source-scientific mode additionally exposes source constructor
#'   arguments and one-dimensional normalized grid points without fitting.
#' @param trajectories Native complete/common-grid trajectory set.
#' @param strict_source_record Opt-in inspectable Python 1.2 source constructor
#'   geometry in a native R record; never a Python backend object.
#' @export
etr_to_skfda_grid<-function(trajectories,strict_source_record=FALSE){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a nonmissing logical scalar")
  etr_validate(trajectories)
  out<-structure(list(values=trajectories$values,time=trajectories$time,
    curve_ids=trajectories$curve_ids,
    dimension_names=trajectories$dimension_names,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,
    backend="native_R_functional_grid",
    source_object_type="skfda.FDataGrid_NOT_RETURNED",
    independently_source_certified=FALSE),
    class="etr_native_functional_grid")
  if(!isTRUE(strict_source_record))return(out)
  # Frozen Python 1.2 backends.py::to_skfda_grid passes the original
  # curve-by-time-by-codomain array to FDataGrid without interpolation.
  # Both source constructor kwargs and the normalized single-domain
  # grid_points tuple are retained as inspectable R numerical objects.
  shape<-dim(trajectories$values)
  .etr_assert(length(shape)==3L&&shape[1L]>=1L&&shape[3L]>=1L,
    "source scikit-fda scientific grid requires observed curves and channels")
  .etr_assert(is.numeric(trajectories$values)&&
    !any(is.infinite(trajectories$values)),
    "source scientific grid requires finite or explicitly missing values, not infinity")
  .etr_assert(length(trajectories$curve_ids)==shape[1L]&&
    length(trajectories$dimension_names)==shape[3L],
    "source scientific grid curve and coordinate dimensions are inconsistent")
  canonical<-array(as.numeric(trajectories$values),dim=shape)
  out$source_constructor<-list(
    data_matrix=canonical,
    grid_points=as.numeric(trajectories$time),
    dataset_name="eyetrajectoriespy trajectories",
    coordinate_names=as.character(trajectories$dimension_names))
  out$source_normalized_grid_points<-list(as.numeric(trajectories$time))
  out$source_domain_range<-matrix(as.numeric(range(trajectories$time)),
    nrow=1L,ncol=2L)
  out$source_n_samples<-as.integer(shape[1L])
  out$source_domain_dimension<-1L
  out$source_codomain_dimension<-as.integer(shape[3L])
  out$source_curve_indices<-as.integer(seq_len(shape[1L])-1L)
  out$interpolation_performed<-FALSE
  out$backend_object<-NULL
  out$matplotlib_or_python_object_identity<-FALSE
  out$source_scientific_geometry_scope<-
    "source_constructor_data_matrix_grid_points_coordinate_names_only"
  class(out)<-c("etr_skfda_fdatagrid_scientific_record",class(out))
  out
}

#' Project one native functional channel onto an explicit R basis
#' @param trajectories Native complete trajectories.
#' @param dimension Explicit channel name.
#' @param basis bspline or fourier.
#' @param n_basis Number of fixed basis columns.
#' @param order Positive B-spline order.
#' @param strict_source_record TRUE computes the pinned scikit-fda
#'   numerical sampled-grid least-squares Fourier/B-spline source
#'   geometry (including Fourier normalization and odd basis expansion),
#'   returning a native R source-scientific record rather than FDataBasis.
#'   Default FALSE preserves the historical R least-squares alternative.
#' @return R least-squares basis projection (not scikit-fda FDataBasis).
#' @export
etr_to_skfda_basis<-function(trajectories,dimension,basis="bspline",
    n_basis=15L,order=4L,strict_source_record=FALSE){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict_source_record))
    return(.etr_skfda_source_basis_projection(
      trajectories,dimension,basis,n_basis,order))
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "dimension must identify an observed trajectory channel")
  .etr_assert(is.character(basis)&&length(basis)==1L&&
    !is.na(basis)&&basis%in%c("bspline","fourier"),
    "basis must be bspline or fourier")
  .etr_assert(is.numeric(n_basis)&&length(n_basis)==1L&&
    is.finite(n_basis)&&n_basis==floor(n_basis)&&n_basis>=2L,
    "n_basis must be an integer at least two")
  .etr_assert(is.numeric(order)&&length(order)==1L&&
    is.finite(order)&&order==floor(order)&&order>=1L,
    "order must be a positive integer")
  .etr_assert(basis!="bspline"||n_basis>=order,
    "bspline n_basis must be at least order")
  n_basis<-as.integer(n_basis)
  tt<-trajectories$time
  .etr_assert(length(tt)>=n_basis,
    "observed time grid must resolve every declared basis coefficient")
  if(basis=="bspline"){
    degree<-as.integer(order-1L)
    interior<-n_basis-as.integer(order)
    knots<-c(rep(tt[1L],order),
      if(interior>0L)seq(tt[1L],tail(tt,1L),
        length.out=interior+2L)[-c(1L,interior+2L)],
      rep(tail(tt,1L),order))
    B<-splines::splineDesign(knots,tt,ord=as.integer(order),
      outer.ok=TRUE)
    B[nrow(B),]<-0
    B[nrow(B),ncol(B)]<-1
  }else{
    u<-(tt-tt[1L])/(tail(tt,1L)-tt[1L])
    B<-matrix(1,length(tt),n_basis)
    if(n_basis>=2L)for(k in 2:n_basis){
      harmonic<-ceiling((k-1L)/2)
      B[,k]<-if(k%%2L==0L)
        sin(2*pi*harmonic*u) else cos(2*pi*harmonic*u)
    }
    knots<-NULL
  }
  .etr_assert(all(is.finite(B))&&qr(B)$rank==n_basis,
    "basis projection design is rank deficient on the observed grid")
  n<-length(trajectories$curve_ids)
  y<-matrix(trajectories$values[,,
    match(dimension,trajectories$dimension_names),drop=FALSE],
    nrow=n)
  coef<-t(qr.solve(B,t(y)))
  fitted<-coef%*%t(B)
  structure(list(dimension=dimension,basis_type=basis,
    n_basis=n_basis,order=if(basis=="bspline")as.integer(order)else NULL,
    time_domain=range(tt),basis_matrix=B,basis_knots=knots,
    coefficient_matrix=coef,fitted_functions=fitted,
    curve_ids=trajectories$curve_ids,
    backend="base_R_least_squares",
    source_backend="scikit_fda_not_used",
    source_equivalent=FALSE,independently_source_certified=FALSE),
    class="etr_native_basis_projection")
}

#' Flag native marginal functional-envelope outliers for review only
#' @description Non-equivalent native pointwise Tukey envelope alternative
#'   to scikit-fda boxplot/MSPlot; never removes or modifies observations.
#' @param trajectories Complete native common-grid curves.
#' @param dimension Explicit observed functional channel.
#' @param method Only boxplot; scikit-fda msplot is not implemented.
#' @param factor Positive Tukey multiplier.
#' @param random_state Recorded seed, unused by deterministic R envelope.
#' @export
etr_detect_functional_outliers_skfda<-function(
    trajectories,dimension,method="boxplot",factor=1.5,
    random_state=0L){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "dimension must identify a trajectory channel")
  .etr_assert(identical(method,"boxplot"),
    "native marginal envelope supports only boxplot; skfda MSPlot not implemented")
  .etr_assert(is.numeric(factor)&&length(factor)==1L&&
    is.finite(factor)&&factor>0,
    "factor must be finite positive")
  i<-match(dimension,trajectories$dimension_names)
  y<-matrix(trajectories$values[,,i,drop=FALSE],
    nrow=length(trajectories$curve_ids))
  q1<-apply(y,2L,stats::quantile,.25,names=FALSE,type=7)
  q3<-apply(y,2L,stats::quantile,.75,names=FALSE,type=7)
  lower<-q1-factor*(q3-q1);upper<-q3+factor*(q3-q1)
  flag<-rowSums(sweep(y,2L,lower,"<")|
    sweep(y,2L,upper,">"))>0L
  diagnostics<-data.frame(curve_id=trajectories$curve_ids,
    backend_label=ifelse(flag,-1L,1L),
    review_flag=flag,stringsAsFactors=FALSE)
  structure(list(diagnostics=diagnostics,method="native_marginal_tukey_envelope",
    reference=NULL,backend_object=NULL,
    scientific_warning="Review-only flags; not automatic exclusion",
    source_detector="scikit_fda_boxplot_not_reproduced",
    provenance=list(dimension=dimension,factor=factor,
      random_state=random_state,source_equivalent=FALSE,
      full_source_contract_certified=FALSE)),
    class="etr_native_functional_outlier_result")
}

#' Native equivalent data container for FDApy irregular functional observations
#' @description No interpolation, but returns etr_sparse_curves, NOT a
#'   Python FDApy.IrregularFunctionalData instance.
#' @param trajectories Native irregular trajectory collection.
#' @param dimension Named irregular functional channel.
#' @param strict_source_record Opt-in Python 1.2 FDApy constructor-shaped
#'   zero-based irregular coordinates and values, not a Python backend object.
#' @export
etr_to_fdapy_irregular<-function(trajectories,dimension,
    strict_source_record=FALSE){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a nonmissing logical scalar")
  .etr_assert(inherits(trajectories,"etr_irregular_trajectory_set"),
    "trajectories must be a native irregular trajectory collection")
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "dimension must identify one observed irregular functional channel")
  d<-match(dimension,trajectories$dimension_names)
  .etr_assert(all(vapply(trajectories$values,function(v)
    all(is.finite(v[,d])),logical(1L))),
    "selected irregular dimension must be finite and observed")
  if(isTRUE(strict_source_record)){
    # Frozen Python 1.2 sparse.py constructs IrregularArgvals as a dict
    # of zero-based integer keys -> DenseArgvals(input_dim_0=time.copy())
    # and IrregularValues with the same keys -> values[:,dimension].
    # R named lists encode integer keys as character names, while their
    # original Python integer identity is recorded explicitly.
    n<-length(trajectories$curve_ids)
    keys<-as.integer(seq_len(n)-1L)
    keynames<-as.character(keys)
    times<-lapply(trajectories$time,as.numeric)
    vals<-lapply(trajectories$values,
      function(v)as.numeric(v[,d]))
    argvals<-setNames(lapply(times,function(t)
      list(input_dim_0=t)),keynames)
    data_values<-setNames(vals,keynames)
    .etr_assert(identical(names(argvals),names(data_values))&&
      all(vapply(seq_len(n),function(i)
        identical(length(argvals[[i]]$input_dim_0),
          length(data_values[[i]])),logical(1L))),
      "source FDApy irregular argvals/values keys and lengths must agree")
    return(structure(list(
      argvals=argvals,values=data_values,
      python_integer_keys=keys,
      input_dimension_name="input_dim_0",
      dimension=dimension,
      dimension_index_zero_based=as.integer(d-1L),
      curve_ids=trajectories$curve_ids,
      source_sample_counts=as.integer(lengths(times)),
      source_input_curve_order=as.character(trajectories$curve_ids),
      source_constructor_classes=c(
        argvals="FDApy.representation.IrregularArgvals",
        argval_element="FDApy.representation.DenseArgvals",
        values="FDApy.representation.IrregularValues",
        result="FDApy.IrregularFunctionalData"),
      backend_object=NULL,interpolation_performed=FALSE,
      source_python_object_type="FDApy.IrregularFunctionalData_not_returned",
      source_equivalent=FALSE,independently_source_certified=FALSE),
      class=c("etr_fdapy_irregular_scientific_record","list")))
  }
  # Historical R adapter feeds fdapace and retains its >=3 visits
  # requirement. The source scientific record above supports >=2.
  .etr_assert(all(lengths(trajectories$time)>=3L),
    "native fdapace container requires at least 3 samples per curve")
  out<-etr_sparse_curves(trajectories$time,
    lapply(trajectories$values,function(v)as.numeric(v[,d])),
    curve_ids=trajectories$curve_ids,time_unit=trajectories$time_unit)
  out$source_python_object_type<-"FDApy.IrregularFunctionalData_not_returned"
  out$dimension<-dimension
  out$source_equivalent<-FALSE
  out
}

#' Fit explicitly native fdapace PACE alternative to FDApy sparse FPCA
#' @description Not FDApy UFPCA covariance operator; requires an explicit
#'   R backend declaration, no hidden use of Python/reticulate.
#' @param trajectories Native irregular functional curves.
#' @param dimension Explicit observed channel.
#' @param n_components Maximum retained sparse components.
#' @param backend Must be exactly fdapace.
#' @param fve Explicit explained-variance threshold.
#' @param options Native fdapace options; locked core score method.
#' @export
etr_fit_sparse_fpca_fdapy<-function(trajectories,dimension,
    n_components=3L,backend=NULL,fve=.95,options=list()){
  .etr_assert(identical(backend,"fdapace"),
    "source FDApy backend unavailable natively; explicitly choose fdapace")
  out<-etr_to_fdapy_irregular(trajectories,dimension)
  fit<-etr_fit_sparse_pace(out,max_components=n_components,
    fve=fve,options=options)
  fit$source_python_equivalent<-FALSE
  fit$source_backend<-"FDApy_UFPCA_not_used"
  fit$provenance<-list(
    alternate_native_backend="fdapace_FPCA_sparse_CE",
    source_backend="FDApy_UFPCA_PACE",
    smoothing_and_covariance_source_equivalent=FALSE,
    independent_source_contract_certified=FALSE)
  fit
}
