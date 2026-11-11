# Shared only by native functional GEE regression and bootstrap test files.
# testthat loads helper-*.R independent of the selected test filename filter.
.etr_native_gee_fixture<-function(family="poisson",grouped=FALSE){
  time<-seq(0,1,length.out=7L)
  n<-36L;nt<-length(time)
  z<-outer(seq_len(n),seq_len(nt),function(i,j){
    if(family=="poisson") (i+2*j+(i*j)%%3)%%6
    else as.integer((i+j+i*j)%%5<2)
  })
  den<-NULL
  if(grouped){
    den<-outer(seq_len(n),seq_len(nt),
      function(i,j)3L+(i+j)%%3L)
    z<-outer(seq_len(n),seq_len(nt),
      function(i,j)(i+2*j)%%4)
    z<-pmin(z,den)
  }
  x<-etr_trajectory_set(time,array(as.numeric(z),c(n,nt,1L)),
    sprintf("curve%02d",seq_len(n)),"outcome",
    metadata=data.frame(participant_id=rep(
      sprintf("P%02d",1:12),each=3)),
    coordinate_system="unknown",time_unit="s")
  design<-data.frame(curve_id=rev(x$curve_ids),
    treatment=as.numeric((rev(seq_len(n))%%4)<2))
  list(x=x,design=design,den=den)
}

# Paired R/Python inputs. No behavior from either fit is used to form a fixture.
.etr_native_gee_boundary_case<-function(key){
  family<-if(key%in%c("weighted_grouped","separated"))"binomial" else "poisson"
  f<-.etr_native_gee_fixture(family,grouped=key=="weighted_grouped")
  x<-f$x
  d<-f$design[match(x$curve_ids,f$design$curve_id),,drop=FALSE]
  predictors<-"treatment"
  exposure<-NULL
  if(key=="separated")x$values[,,1L]<-d$treatment
  if(key=="zero_counts")x$values[]<-0
  if(key=="nearly_rank_deficient") {
    d$treatment<-d$treatment*1e-8
    exposure<-exp(outer(seq_len(nrow(d)),seq_along(x$time),
      function(i,j)(i-j)/10))
  }
  if(key=="subthreshold_rank")d$treatment<-d$treatment*1e-16
  if(key=="rank_deficient")d$treatment<-0
  if(key=="numeric_curve_id"){
    x$curve_ids<-as.character(seq_len(nrow(d)))
    d$curve_id<-x$curve_ids
    predictors<-"curve_id"
  }
  list(trajectories=x,design=d,predictors=predictors,
    participant_column="participant_id",dimension="outcome",family=family,
    basis_size=4L,spline_degree=3L,binomial_denominator=f$den,
    exposure=exposure,exposure_units=if(is.null(exposure))NULL else "person-hours",
    maxiter=1L,ctol=if(key=="score_too_large")1e-14 else 1e-8,
    python_boundary_mode=TRUE)
}

.etr_python_gee_boundary_call<-function(args){
  pd<-reticulate::import("pandas",convert=FALSE)
  np<-reticulate::import("numpy",convert=FALSE)
  builtins<-reticulate::import_builtins(convert=FALSE)
  x<-args$trajectories
  frame<-function(d)pd$DataFrame(lapply(d,as.list))
  args$trajectories<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=np$array(as.numeric(x$time)),values=np$array(x$values),
    curve_ids=builtins$tuple(as.list(x$curve_ids)),
    dimension_names=builtins$tuple(as.list(x$dimension_names)),
    metadata=frame(x$metadata),coordinate_system=x$coordinate_system,
    time_unit=x$time_unit)
  args$design<-frame(args$design)
  args$predictors<-as.list(args$predictors)
  args$python_boundary_mode<-NULL
  do.call(reticulate::py_call,
    c(list(etpy_get_export("fit_generalized_function_on_scalar_regression")),args))
}
