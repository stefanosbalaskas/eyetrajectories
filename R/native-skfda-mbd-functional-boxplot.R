# Frozen scientific source: eyetrajectoriespy 1.2.0 backends.py
# detect_functional_outliers_skfda(method="boxplot"), whose scikit-fda
# BoxplotOutlierDetector uses ModifiedBandDepth (SimplicialDepth) and
# scipy.integrate.simpson on the observed grid. Native R implementation
# of the default boxplot scientific estimand, NOT the stochastic MSPlot,
# not a Python scikit-fda detector class or full-source certification.

.etr_skfda_simpson_weights <- function(time) {
  .etr_assert(is.numeric(time)&&is.null(dim(time))&&
    length(time)>=2L&&all(is.finite(time))&&
    all(diff(time)>0),
    "source MBD integration requires increasing finite observation times")
  n<-length(time)
  h<-diff(time)
  weight<-numeric(n)
  # SciPy's composite Simpson for nonuniform 3-point subintervals;
  # the 2-point special case is the standard trapezoidal rule.
  if(n==2L) {
    weight[]<-h[1L]/2
  } else {
    last<-if(n%%2L==1L)n else n-1L
    for(j in seq.int(1L,last-2L,by=2L)) {
      h0<-h[j];h1<-h[j+1L]
      span<-h0+h1
      weight[j]<-weight[j]+span/6*(2-h1/h0)
      weight[j+1L]<-weight[j+1L]+span^3/(6*h0*h1)
      weight[j+2L]<-weight[j+2L]+span/6*(2-h0/h1)
    }
    if(n%%2L==0L) {
      # scipy.integrate.simpson even-length correction at final
      # sample interval, i.e. the Cartwright 3-sample formula.
      h0<-h[n-2L];h1<-h[n-1L]
      alpha<-(2*h1^2+3*h0*h1)/(6*(h0+h1))
      beta<-(h1^2+3*h0*h1)/(6*h0)
      eta<-h1^3/(6*h0*(h0+h1))
      weight[n]<-weight[n]+alpha
      weight[n-1L]<-weight[n-1L]+beta
      weight[n-2L]<-weight[n-2L]-eta
    }
  }
  weight<-weight/(time[n]-time[1L])
  .etr_assert(all(is.finite(weight))&&
    abs(sum(weight)-1)<1e-9,
    "scipy-compatible average Simpson weights failed consistency audit")
  weight
}

.etr_skfda_pointwise_simplicial_depth <- function(y) {
  .etr_assert(is.matrix(y)&&is.numeric(y)&&
    nrow(y)>=3L&&ncol(y)>=2L&&all(is.finite(y)),
    "functional modified band depth needs >=3 finite complete curves")
  n<-nrow(y);nt<-ncol(y)
  choose2<-function(v)v*(v-1)/2
  denom<-choose2(n)
  depth<-matrix(0,nrow=n,ncol=nt)
  for(j in seq_len(nt)) {
    sample<-y[,j]
    # This reproduces scikit-fda SimplicialDepth: combinations of
    # two distinct training curves (univariate simplex) including
    # both endpoints and all equality/tie cases.
    l<-vapply(sample,function(x)sum(sample<x),integer(1L))
    r<-vapply(sample,function(x)sum(sample>x),integer(1L))
    depth[,j]<-(denom-choose2(l)-choose2(r))/denom
  }
  depth
}

.etr_skfda_mbd_boxplot_scientific <- function(
    trajectories,dimension,method,factor,random_state) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "source MBD boxplot dimension must identify a real trajectory channel")
  .etr_assert(identical(method,"boxplot"),
    "source-scientific implementation currently supports only functional boxplot; MSPlot uses a distinct robust MCD method")
  .etr_assert(is.numeric(factor)&&length(factor)==1L&&
    !is.na(factor)&&is.finite(factor)&&factor>0,
    "functional boxplot factor must be finite and positive")
  .etr_assert(is.null(random_state)||
    (is.numeric(random_state)&&length(random_state)==1L&&
     !is.na(random_state)&&is.finite(random_state)),
    "random_state must be one finite scalar or NULL")
  n<-length(trajectories$curve_ids)
  .etr_assert(n>=3L,
    "source scientific MBD requires at least three complete curves")
  tt<-as.numeric(trajectories$time)
  z<-matrix(trajectories$values[,,
    match(dimension,trajectories$dimension_names),drop=FALSE],
    nrow=n,ncol=length(tt))
  .etr_assert(all(is.finite(z)),
    "source MBD boxplot requires finite complete selected observations")
  pointwise<-.etr_skfda_pointwise_simplicial_depth(z)
  weights<-.etr_skfda_simpson_weights(tt)
  mbd<-as.vector(pointwise%*%weights)
  central_n<-as.integer(ceiling(.5*n))
  ord<-order(-mbd,seq_along(mbd),method="radix")
  # The frozen Python source uses np.argsort's default unstable
  # quicksort for tied MBD depths. In a tie *straddling the central
  # boundary*, central-envelope selection can depend on Python
  # sorting implementation. No false full-source claim in that domain.
  if(central_n<n && abs(mbd[ord[central_n]]-
                        mbd[ord[central_n+1L]])<=
      1e-13*max(1,abs(mbd[ord[central_n]]))) {
    stop("source scientific MBD central rank cutoff is tied; Python NumPy quicksort central-region membership requires backend-specific tie resolution",
      call.=FALSE)
  }
  central<-z[ord[seq_len(central_n)],,drop=FALSE]
  lower<-apply(central,2L,min)
  upper<-apply(central,2L,max)
  iqr<-upper-lower
  lower_fence<-lower-as.numeric(factor)*iqr
  upper_fence<-upper+as.numeric(factor)*iqr
  flag<-rowSums(sweep(z,2L,lower_fence,"<")|
    sweep(z,2L,upper_fence,">"))>0L
  labels<-ifelse(flag,-1L,1L)
  warning_text<-"Functional outlier flags are review diagnostics and are not automatic exclusion criteria."
  provenance<-trajectories$provenance
  if(is.null(provenance))provenance<-list()
  provenance$dimension<-dimension
  provenance$factor<-as.numeric(factor)
  provenance$random_state<-random_state
  provenance$scientific_warning<-warning_text
  structure(list(
    diagnostics=data.frame(
      curve_id=trajectories$curve_ids,
      backend_label=as.integer(labels),
      review_flag=as.logical(flag),
      stringsAsFactors=FALSE),
    method="skfda_boxplot",
    reference=NULL,
    backend_object=NULL,
    provenance=provenance,
    source_detector="scikit_fda_MBD_BoxplotOutlierDetector_scientific_R",
    scientific_warning=warning_text,
    integration_weights=weights,
    pointwise_simplicial_depth=pointwise,
    modified_band_depth=as.numeric(mbd),
    central_rank_order_zero_based=as.integer(ord-1L),
    central_curve_indices_zero_based=as.integer(ord[seq_len(central_n)]-1L),
    central_envelope=data.frame(time=tt,lower=lower,upper=upper),
    non_outlying_envelope=data.frame(
      time=tt,lower=lower_fence,upper=upper_fence),
    source_scientific_scope="ModifiedBandDepth_default_functional_boxplot_no_crossing_center_ties",
    source_equivalent=FALSE,
    independently_source_certified=FALSE,
    source_python_object_type="skfda.BoxplotOutlierDetector_not_returned",
    actual_msplot_implemented=FALSE),
    class=c("etr_skfda_mbd_boxplot_scientific_record",
      "etr_native_functional_outlier_result","list"))
}
