# Batches 70–74: output schemas, nested identifiers and source-ordered frames.
# Independent deterministic fixtures; do not depend on other test file scopes.
.etr_batch74_fixture <- function() {
  set.seed(39001L)
  ng<-24L;m<-3L;nc<-ng*m;time<-seq(0,1,length.out=8L)
  ids<-sprintf("ns%03d",seq_len(nc))
  pid<-rep(sprintf("P%02d",seq_len(ng)),each=m)
  trial<-rep(sprintf("T%02d",seq_len(m)),ng)
  slope<-rep(c(-1,0,1),ng)
  y<-array(NA_real_,c(nc,length(time),1L));q<-time
  for(g in seq_len(ng)) {
    u<-rnorm(4L);pb<-c(.35*u[1L],.22*u[2L]+.07*u[1L],
      .17*u[3L]+.04*u[1L],.15*u[4L]-.03*u[2L])
    for(j in seq_len(m)) {
      i<-(g-1L)*m+j;v<-rnorm(2L)
      tr<-c(.13*v[1L],.12*v[2L]+.02*v[1L])
      eps<-rnorm(length(time),sd=.10)
      y[i,,1L]<-.4+.1*q+slope[i]*(.3-.12*q)+
        pb[1L]*(1-q)+pb[2L]*q+
        slope[i]*(pb[3L]*(1-q)+pb[4L]*q)+
        tr[1L]*(1-q)+tr[2L]*q+eps
    }
  }
  trajectories<-etr_trajectory_set(time,y,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid,trial=trial),
    coordinate_system="degrees",time_unit="seconds")
  design<-data.frame(curve_id=rev(ids),predictor=rev(slope))
  list(trajectories=trajectories,design=design)
}

test_that("source trial frame validates input and exact row schema",{
  expect_error(etr_nested_source_trial_effect_frame(list()),"native nested trial")
  d<-.etr_batch74_fixture()
  # Do not need an optimizer to verify exact table/row ordering.
  mock<-structure(list(n_curves=2L,time=c(.1,.3,.7),
    curve_ids=c("c1","c2"),curve_participant_ids=c("p1","p2"),
    curve_trial_ids=c("t1","t2"),trial_ids=c("p1::t1","p2::t2"),
    trial_random_effect_functions=matrix(1:6,2,3,byrow=TRUE)),
    class=c("etr_joint_bspline_mixed_nested_trial","etr_joint_bspline_mixed"))
  frame<-etr_nested_source_trial_effect_frame(mock)
  expect_identical(names(frame),c("curve_index","curve_id","participant_id",
    "source_trial_id","trial_id","time","effect","value"))
  expect_identical(frame$curve_index,c(0L,0L,0L,1L,1L,1L))
  expect_equal(frame$value,as.numeric(1:6))
  expect_identical(frame$trial_id,c(rep("p1::t1",3),rep("p2::t2",3)))
  bad<-mock;bad$trial_random_effect_functions[1L,1L]<-NA_real_
  expect_error(etr_nested_source_trial_effect_frame(bad),"finite")
  bad_time<-mock;bad_time$time<-c(.1,.3,.3)
  expect_error(etr_nested_source_trial_effect_frame(bad_time),"time")
})

test_that("native nested fitted output aliases agree with source formula",{
  skip_if_not_installed("nlme")
  d<-.etr_batch74_fixture()
  f1<-etr_fit_joint_bspline_functional_nested_trial(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    fixed_basis_size=2L,random_basis_size=2L,trial_random_basis_size=2L,
    spline_degree=1L,maxiter=500L)
  f2<-etr_fit_joint_bspline_functional_nested_slope(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    "predictor",fixed_basis_size=2L,random_basis_size=2L,
    trial_random_basis_size=2L,spline_degree=1L,maxiter=500L)
  for(f in list(f1,f2)) {
    expect_equal(unname(f$coefficient_functions),
      unname(f$fixed_coefficient_functions))
    expect_equal(unname(f$coefficient_standard_errors),
      unname(f$fixed_standard_errors))
    expect_equal(unname(f$random_effect_coefficients),
      unname(f$participant_random_effect_coefficients))
    expect_equal(unname(f$random_effect_functions),
      unname(f$random_intercept_functions))
    expect_identical(f$trial_random_effect,"functional_intercept")
    expect_identical(f$trial_random_basis_size,2L)
    expect_identical(f$trial_ids,
      paste0(f$curve_participant_ids,"::",f$source_trial_ids))
    expect_identical(f$curve_trial_ids,f$source_trial_ids)
    expect_equal(f$residual_correlation_eigenvalues,rep(1,8))
    expect_true(f$residual_correlation_grid_regular)
    expect_equal(unname(f$whitened_residual_functions),
      unname(f$residual_functions)/sqrt(f$residual_variance),
      tolerance=1e-8)
    expect_equal(unname(f$fitted_functions+f$residual_functions),
      unname(f$observed_functions),tolerance=1e-10)
    expect_equal(f$log_likelihood,
      as.numeric(stats::logLik(f$fitted_model)),tolerance=1e-10)
    fr<-etr_nested_source_trial_effect_frame(f)
    expect_equal(nrow(fr),f$n_curves*length(f$time))
    expect_equal(fr$value,as.numeric(t(f$trial_random_effect_functions)))
    expect_equal(fr$time[seq_along(f$time)],f$time)
    expect_true(all(fr$effect=="trial_functional_intercept"))
    expect_true(is.finite(f$residual_correlation_condition_number))
  }
  expect_null(f1$random_slope_coefficients)
  expect_null(f1$random_slope_functions)
  expect_equal(unname(f2$random_slope_functions),
    unname(f2$participant_random_slope_effect_functions))
  expect_equal(unname(f2$random_slope_covariance),
    unname(f2$random_effect_covariance[3:4,3:4,drop=FALSE]))
})
