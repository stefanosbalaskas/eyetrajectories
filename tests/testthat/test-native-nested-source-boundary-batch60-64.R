# Batch 60–64: source-frozen covariance diagnostics and explicit trial metadata.
# All covariance diagnostics are non-mutating; prior fit/likelihood unchanged.

test_that('frozen Python 1.2 covariance boundary and singular tolerances agree', {
  G <- diag(c(2,1e-15))
  got <- .etr_nested_source_covariance_diagnostics(G)
  expect_equal(got$eigenvalues,c(1e-15,2),tolerance=1e-12)
  expect_true(got$boundary)
  expect_true(got$singular)
  expect_gt(got$condition_number,1e12)
  stable <- .etr_nested_source_covariance_diagnostics(diag(c(.3,2)))
  expect_false(stable$boundary)
  expect_false(stable$singular)
  expect_equal(stable$condition_number,2/.3,tolerance=1e-12)
  expect_error(.etr_nested_source_covariance_diagnostics(
    matrix(c(1,2,0,1),2,2)), 'symmetric')
  expect_error(.etr_nested_source_covariance_diagnostics(
    diag(c(1,-.1))), 'semidefinite')
  expect_error(.etr_nested_source_covariance_diagnostics(
    matrix(c(NA_real_,0,0,1),2,2)), 'non-finite')
})

test_that('trial-level boundary uses participant and residual reference scale', {
  d <- .etr_nested_source_joint_diagnostics(diag(c(.4,1)),
    diag(c(.01,.02)),.2)
  expect_false(d$participant$boundary)
  expect_true(d$trial$boundary)
  expect_false(d$trial$singular)
  d2 <- .etr_nested_source_joint_diagnostics(diag(c(.4,1)),
    diag(c(.4,.6)),.2)
  expect_false(d2$trial$boundary)
})

.etr_batch60_data <- function() {
  set.seed(39001L)
  ng<-24L; m<-3L; nc<-ng*m; time<-seq(0,1,length.out=8L)
  ids<-sprintf('ns%03d',seq_len(nc))
  pid<-rep(sprintf('P%02d',seq_len(ng)),each=m)
  trial<-rep(sprintf('T%02d',seq_len(m)),ng)
  slope<-rep(c(-1,0,1),ng)
  y<-array(NA_real_,c(nc,length(time),1L));q<-time
  for(g in seq_len(ng)) {
    u<-rnorm(4L); pb<-c(.35*u[1L],.22*u[2L]+.07*u[1L],
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
    dimension_names='signal',metadata=data.frame(pid=pid,trial=trial),
    coordinate_system='degrees',time_unit='seconds')
  design<-data.frame(curve_id=rev(ids),predictor=rev(slope))
  list(trajectories=trajectories,design=design)
}

test_that('trial duplicate and missing identifier errors are explicit', {
  d<-.etr_batch60_data()
  duplicate<-d$trajectories
  duplicate$metadata$trial[2L]<-duplicate$metadata$trial[1L]
  expect_error(.etr_nested_trial_structure(duplicate,'pid','trial'),
    'duplicated participant/trial pairs')
  missing<-d$trajectories
  missing$metadata$trial[2L]<-NA_character_
  expect_error(.etr_nested_trial_structure(missing,'pid','trial'),
    'trial_column contains missing values')
})

test_that('both native nested estimators return source-aligned diagnostics', {
  skip_if_not_installed('nlme')
  d<-.etr_batch60_data()
  f1<-etr_fit_joint_bspline_functional_nested_trial(
    d$trajectories,d$design,'predictor','pid','trial','signal',
    fixed_basis_size=2L,random_basis_size=2L,trial_random_basis_size=2L,
    spline_degree=1L,maxiter=500L)
  f2<-etr_fit_joint_bspline_functional_nested_slope(
    d$trajectories,d$design,'predictor','pid','trial','signal',
    'predictor',fixed_basis_size=2L,random_basis_size=2L,
    trial_random_basis_size=2L,spline_degree=1L,maxiter=500L)
  for(f in list(f1,f2)) {
    reference<-.etr_nested_source_joint_diagnostics(
      f$random_effect_covariance,f$trial_random_effect_covariance,
      f$residual_variance)
    expect_equal(f$random_effect_covariance_eigenvalues,
      reference$participant$eigenvalues,tolerance=1e-10)
    expect_equal(f$trial_random_effect_covariance_eigenvalues,
      reference$trial$eigenvalues,tolerance=1e-10)
    expect_equal(f$random_effect_covariance_condition_number,
      reference$participant$condition_number,tolerance=1e-8)
    expect_equal(f$trial_random_effect_covariance_condition_number,
      reference$trial$condition_number,tolerance=1e-8)
    expect_identical(f$random_effect_boundary_fit,reference$participant$boundary)
    expect_identical(f$random_effect_singular,reference$participant$singular)
    expect_identical(f$trial_random_effect_boundary_fit,reference$trial$boundary)
    expect_identical(f$trial_random_effect_singular,reference$trial$singular)
    expect_equal(unname(f$fitted_functions+f$residual_functions),
      unname(f$observed_functions),tolerance=1e-10)
    expect_true(is.finite(as.numeric(stats::logLik(f$fitted_model))))
  }
})
