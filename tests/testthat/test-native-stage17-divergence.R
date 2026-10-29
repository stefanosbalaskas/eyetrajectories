# Stage 17 source-oriented exact embedding and local divergence tests.
.etr17_fixture <- function(){
  t<-seq(0,4.5,length.out=91L);n<-8L
  a<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)){
    a[i,,1L]<-sin(2.7*t+i*.19)+.22*cos(4.1*t+i*.04)+
      t*i/95+.02*sin(6.1*t+i*.5)
    a[i,,2L]<-cos(1.6*t+i*.12)+.2*sin(3.6*t+i*.31)+
      t*i/75+.02*cos(5.5*t+i*.23)
  }
  etr_trajectory_set(t,a,sprintf("c%02d",seq_len(n)),
    c("x","y"),metadata=data.frame(
      participant_id=rep(sprintf("p%02d",1:4),each=2L)),
    time_unit="s",coordinate_system="normalized")
}

test_that("Stage 17 multichannel delay embedding preserves exact source order",{
  x<-.etr17_fixture()
  e<-etr_delay_embed_trajectory(x,embedding_dimension=3L,
    delay=2L,dimensions=c("y","x"))
  expect_s3_class(e,"etr_delay_embedding_set")
  expect_identical(dim(e$values),c(8L,87L,6L))
  expect_identical(e$state_names,c(
    "y[t-0*delay]","x[t-0*delay]",
    "y[t-1*delay]","x[t-1*delay]",
    "y[t-2*delay]","x[t-2*delay]"))
  expect_equal(e$values[1L,1L,1L],x$values[1L,5L,2L])
  expect_equal(e$values[1L,1L,3L],x$values[1L,3L,2L])
  expect_equal(e$values[1L,1L,5L],x$values[1L,1L,2L])
  expect_equal(e$time,x$time[5:91])
  expect_equal(e$delay_time,.10,tolerance=1e-13)
  expect_error(etr_delay_embed_trajectory(x,3L,2L,dimensions=NULL),
    "dimensions must be explicit")
  expect_error(etr_delay_embed_trajectory(x,2L,2L,
    delay_units="ms",dimensions="x"),"not yet qualified")
})

test_that("Stage 17 Rosenstein local divergence tracks all eligible forward pairs",{
  x<-.etr17_fixture()
  e<-etr_delay_embed_trajectory(x,2L,2L,dimensions=c("x","y"))
  z<-etr_local_divergence_curve(e,curve="c01",
    theiler_window=3L,max_horizon=8L)
  expect_s3_class(z,"etr_local_divergence")
  expect_identical(z$horizons,0:8)
  expect_equal(z$time_lags,(0:8)*.05,tolerance=1e-13)
  expect_equal(length(z$nearest_neighbor_indices),89L)
  expect_identical(length(z$pair_counts),9L)
  expect_true(all(z$nearest_neighbor_indices>=0&
    z$nearest_neighbor_indices<89L))
  expect_true(all(z$pair_counts>=0))
  expect_true(all(z$zero_distance_counts>=0))
  expect_true(any(is.finite(z$mean_log_divergence)))
  zz<-etr_local_divergence_curve(e,curve=0L,
    theiler_window=3L,max_horizon=8L)
  expect_equal(z$mean_log_divergence,zz$mean_log_divergence)
  expect_error(etr_local_divergence_curve(e,"c01",3L,89L),
    "max_horizon")
  expect_error(etr_local_divergence_curve(e,"missing",3L,4L),
    "curve_id")
})

test_that("Stage 17 Kantz local divergence retains declared fixed radius and counts",{
  x<-.etr17_fixture()
  e<-etr_delay_embed_trajectory(x,2L,2L,dimensions=c("x","y"))
  k<-etr_kantz_divergence_curve(e,"c01",radius=3,
    theiler_window=3L,max_horizon=8L,min_neighbors=2L)
  expect_s3_class(k,"etr_kantz_divergence")
  expect_identical(length(k$horizons),9L)
  expect_true(k$reference_counts[1L]>0)
  expect_true(all(k$pair_counts>=k$reference_counts))
  expect_true(all(k$zero_mean_neighborhood_counts>=0))
  expect_true(any(is.finite(k$mean_log_divergence)))
  expect_identical(k$radius,3)
  expect_error(etr_kantz_divergence_curve(e,"c01",radius=0,
    theiler_window=3L,max_horizon=8L),"radius")
  expect_error(etr_kantz_divergence_curve(e,"c01",radius=1e-12,
    theiler_window=3L,max_horizon=8L),"minimum neighbors")
})

test_that("Stage 17 Lyapunov fits use exact declared sample-index interval",{
  x<-.etr17_fixture()
  e<-etr_delay_embed_trajectory(x,2L,2L,dimensions=c("x","y"))
  r<-etr_local_divergence_curve(e,"c01",3L,8L)
  k<-etr_kantz_divergence_curve(e,"c01",3,3L,8L)
  a<-etr_estimate_largest_lyapunov_rosenstein(r,fit_start=1L,fit_end=6L)
  b<-etr_estimate_largest_lyapunov_kantz(k,fit_start=1L,fit_end=6L)
  expect_s3_class(a,"etr_largest_lyapunov")
  expect_s3_class(b,"etr_largest_lyapunov")
  expect_equal(a$fit_start,.05,tolerance=1e-13)
  expect_equal(a$fit_end,.3,tolerance=1e-13)
  expect_identical(a$n_fit_points,6L)
  expect_equal(a$exponent,
    unname(stats::coef(stats::lm(r$mean_log_divergence[2:7]~
      r$time_lags[2:7]))[2L]),tolerance=1e-10)
  expect_true(is.finite(b$exponent))
  expect_identical(a$exponent_unit,"1/s")
  expect_identical(b$exponent_unit,"1/s")
  expect_error(etr_estimate_largest_lyapunov_rosenstein(r,0L,1L),
    "fewer than three")
  expect_error(etr_estimate_largest_lyapunov_kantz(k,1L,9L),
    "remain within")
  expect_error(etr_estimate_largest_lyapunov_kantz(r,1L,6L),
    "etr_kantz_divergence")
})

test_that("Stage 17 whole-participant RQA mean bootstrap is deterministic and fail-closed",{
  x<-.etr17_fixture()
  set.seed(172);before<-.Random.seed
  z<-etr_bootstrap_rqa_metric_means(x,dimensions=c("x","y"),
    metrics="recurrence_rate",radius=.6,theiler_window=1L,
    unit="participant",participant_column="participant_id",
    n_bootstrap=100L,random_state=7L)
  expect_identical(before,.Random.seed)
  expect_s3_class(z,"etr_rqa_metric_bootstrap")
  expect_equal(nrow(z$observed_table),8L)
  expect_identical(names(z$observed_table),
    c("curve_id","resolved_radius","achieved_recurrence_rate",
      "theiler_window_samples","recurrence_rate"))
  expect_equal(nrow(z$unit_table),4L)
  expect_equal(nrow(z$bootstrap_table),100L)
  expect_equal(nrow(z$summary_table),1L)
  expect_equal(z$summary_table$mean,
    mean(z$unit_table$recurrence_rate),tolerance=1e-14)
  expect_true(all(z$observed_table$recurrence_rate>=0&
    z$observed_table$recurrence_rate<=1))
  expect_true(all(z$summary_table$lower<=z$summary_table$upper))
  expect_identical(z$unit,"participant")
  z2<-etr_bootstrap_rqa_metric_means(x,dimensions=c("x","y"),
    metrics="recurrence_rate",radius=.6,theiler_window=1L,
    unit="participant",participant_column="participant_id",
    n_bootstrap=100L,random_state=7L)
  expect_identical(z$bootstrap_table,z2$bootstrap_table)
  expect_error(etr_bootstrap_rqa_metric_means(x,dimensions="x",
    metrics="recurrence_rate",target_recurrence_rate=.1,
    n_bootstrap=100L),"fixed radius")
  expect_error(etr_bootstrap_rqa_metric_means(x,dimensions="x",
    metrics="recurrence_rate",radius=.2,n_bootstrap=99L),
    "n_bootstrap")
  expect_error(etr_bootstrap_rqa_metric_means(x,dimensions="x",
    metrics="invalid",radius=.2,n_bootstrap=100L),
    "supported RQA metrics")
})

test_that("Stage 17 strict public source census remains separate from certification",{
  was<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_gte(sum(z$named_native_candidate),236L)
  expect_lte(sum(z$is_python_function & !z$named_native_candidate),144L)
  expect_gte(sum(z$native_implementation_started),211L)
  expect_equal(sum(z$native_implementation_stage==17L,na.rm=TRUE),6L)
  expect_equal(sum(!z$is_python_function &
    is.na(z$native_representation_stage)),121L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 17 independent Python 1.2 numerical divergence oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 17 pinned Python 1.2 divergence numerical oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr17_fixture()
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  pye<-reticulate::py_call(etpy_get_export("delay_embed_trajectory"),
    trajectories=pyx,embedding_dimension=as.integer(2L),
    delay=as.integer(2L),dimensions=as.list(c("x","y")))
  e<-etr_delay_embed_trajectory(x,2L,2L,dimensions=c("x","y"))
  expect_equal(unname(e$values),unname(et_to_r(pye$values)),
    tolerance=1e-12)
  expect_equal(e$time,as.numeric(et_to_r(pye$time)),tolerance=1e-12)
  pyr<-reticulate::py_call(etpy_get_export("local_divergence_curve"),
    embedding=pye,curve="c01",theiler_window=as.integer(3L),
    max_horizon=as.integer(8L))
  r<-etr_local_divergence_curve(e,"c01",3L,8L)
  expect_equal(r$mean_log_divergence,
    as.numeric(et_to_r(pyr$mean_log_divergence)),tolerance=1e-9)
  expect_equal(r$pair_counts,as.integer(et_to_r(pyr$pair_counts)))
  expect_equal(r$zero_distance_counts,
    as.integer(et_to_r(pyr$zero_distance_counts)))
  pyk<-reticulate::py_call(etpy_get_export("kantz_divergence_curve"),
    embedding=pye,curve="c01",radius=3,
    theiler_window=as.integer(3L),max_horizon=as.integer(8L),
    min_neighbors=as.integer(2L))
  k<-etr_kantz_divergence_curve(e,"c01",radius=3,3L,8L,min_neighbors=2L)
  expect_equal(k$mean_log_divergence,
    as.numeric(et_to_r(pyk$mean_log_divergence)),tolerance=1e-9)
  expect_equal(k$reference_counts,
    as.integer(et_to_r(pyk$reference_counts)))
  expect_equal(k$pair_counts,as.integer(et_to_r(pyk$pair_counts)))
  pya<-reticulate::py_call(etpy_get_export(
    "estimate_largest_lyapunov_rosenstein"),
    divergence=pyr,fit_start=as.integer(1L),fit_end=as.integer(6L))
  a<-etr_estimate_largest_lyapunov_rosenstein(r,1L,6L)
  expect_equal(a$exponent,as.numeric(et_to_r(pya$exponent)),
    tolerance=1e-8)
  expect_equal(a$standard_error,
    as.numeric(et_to_r(pya$standard_error)),tolerance=1e-8)
  pyb<-reticulate::py_call(etpy_get_export(
    "estimate_largest_lyapunov_kantz"),
    divergence=pyk,fit_start=as.integer(1L),fit_end=as.integer(6L))
  b<-etr_estimate_largest_lyapunov_kantz(k,1L,6L)
  expect_equal(b$exponent,as.numeric(et_to_r(pyb$exponent)),tolerance=1e-8)
  expect_equal(b$standard_error,
    as.numeric(et_to_r(pyb$standard_error)),tolerance=1e-8)
})
