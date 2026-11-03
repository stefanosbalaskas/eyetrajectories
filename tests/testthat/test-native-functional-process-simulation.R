# Frozen eyetrajectoriespy 1.2 _functional_simulation.py source law.
.etr_dense_simulation_fixture<-function(){
  list(grid=c(0,.25,.5,.75,1),
    mean=function(t)rep(.3,length(t)),
    modes=list(function(t)rep(1,length(t)),
      function(t)sqrt(2)*cos(pi*t)))
}
test_that("native dense process retains curve, participant and trial truth",{
  x<-.etr_dense_simulation_fixture()
  set.seed(500L);before<-.Random.seed
  out<-etr_simulate_functional_process(x$mean,x$modes,
    eigenvalues=c(1,.4),truth_grid=x$grid,
    n_participants=3L,trials_per_participant=2L,
    participant_eigenvalues=c(.2,.1),trial_eigenvalues=c(.1,.05),
    measurement_noise_sd=.03,random_state=73L)
  expect_identical(before,.Random.seed)
  expect_s3_class(out,"etr_functional_simulation_result")
  expect_identical(dim(out$observations$values),c(6L,5L,1L))
  expect_identical(dim(out$truth$scores),c(6L,2L))
  expect_identical(dim(out$truth$participant_scores),c(3L,2L))
  expect_identical(dim(out$truth$trial_scores),c(6L,2L))
  expect_identical(dim(out$truth$measurement_noise_covariance),c(1L,1L))
  expect_equal(out$truth$measurement_noise_covariance[1L,1L],.03^2)
  expect_identical(out$observations$curve_ids[1:2],
    c("P001|T01","P001|T02"))
  expect_equal(out$truth$scores,
    out$truth$curve_scores+out$truth$trial_scores+
      out$truth$participant_scores[rep(1:3,each=2),,drop=FALSE],
    tolerance=1e-12)
  for(i in seq_len(6L))
    expect_equal(matrix(out$observations$values[i,,],
      nrow=5L,ncol=1L),
      matrix(out$truth$latent_on_truth_grid[i,,],
        nrow=5L,ncol=1L)+
        out$truth$measurement_noise[[i]],tolerance=1e-12)
  expect_true(nrow(etr_functional_simulation_truth_frame(out))==6L)
  expect_false(out$truth$provenance$full_source_contract_certified)
  again<-etr_simulate_functional_process(x$mean,x$modes,
    eigenvalues=c(1,.4),truth_grid=x$grid,n_participants=3L,
    trials_per_participant=2L,
    participant_eigenvalues=c(.2,.1),trial_eigenvalues=c(.1,.05),
    measurement_noise_sd=.03,random_state=73L)
  expect_identical(out$observations$values,again$observations$values)
})

test_that("dense simulator rejects unsupported domains and nonorthogonal bases",{
  x<-.etr_dense_simulation_fixture()
  f<-function(...)etr_simulate_functional_process(...)
  args<-list(mean=x$mean,eigenfunctions=x$modes,
    eigenvalues=c(1,.4),truth_grid=x$grid,n_participants=3L)
  expect_error(do.call(f,c(args,list(observation_design="irregular"))),
    "only dense")
  expect_error(do.call(f,c(args,list(
    missingness=list(kind="mcar",probability=1)))),
    "missingness")
  expect_error(do.call(f,c(args,list(score_distribution="student_t"))),
    "Gaussian")
  expect_error(do.call(f,c(args,list(measurement_noise_covariance=matrix(-1,1,1)))),
    "positive semidefinite")
  bad<-args;bad$eigenfunctions<-list(x$modes[[1L]],x$modes[[1L]])
  expect_error(do.call(f,bad),"quadrature-orthonormal")
  bad<-args;bad$truth_grid<-c(0,.5,.5,1)
  expect_error(do.call(f,bad),"truth_grid")
  bad<-args;bad$eigenvalues<-c(.4,1)
  expect_error(do.call(f,bad),"nonincreasing")
})

test_that("Python 1.2 retained source draws replay full truth in R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 functional process full-truth oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
time=np.array([0.,.25,.5,.75,1.])
a=et.simulate_functional_process(
  mean=lambda t: np.full(t.shape,.3),
  eigenfunctions=(lambda t: np.ones_like(t),),
  eigenvalues=(1.,),truth_grid=time,
  n_participants=3,trials_per_participant=2,
  participant_eigenvalues=(.2,),trial_eigenvalues=(.1,),
  measurement_noise_sd=.03,random_state=73)
_py_process={
 'curve':a.truth.curve_scores,
 'participant':a.truth.participant_scores,
 'trial':a.truth.trial_scores,
 'noise':np.stack(a.truth.measurement_noise),
 'observed':a.observations.values,
 'latent':a.truth.latent_on_truth_grid,
 'scores':a.truth.scores
}
")
  # Direct public source call: same seed and Python callable bases.
  # Native R still uses retained Python source draws to avoid RNG claims.
  direct<-reticulate::py_call(
    etpy_get_export("simulate_functional_process"),
    mean=reticulate::py_eval(
      "lambda t: np.full(t.shape,.3)",convert=FALSE),
    eigenfunctions=reticulate::py_eval(
      "(lambda t: np.ones_like(t),)",convert=FALSE),
    eigenvalues=reticulate::py_eval("(1.,)",convert=FALSE),
    truth_grid=reticulate::py_eval("time",convert=FALSE),
    n_participants=3L,trials_per_participant=2L,
    participant_eigenvalues=reticulate::py_eval(
      "(.2,)",convert=FALSE),
    trial_eigenvalues=reticulate::py_eval("(.1,)",convert=FALSE),
    measurement_noise_sd=.03,random_state=73L)
  for(field in c("scores","latent_on_truth_grid")){
    replay<-et_to_r(reticulate::py_get_attr(
      reticulate::py_get_attr(direct,"truth"),field))
    original<-reticulate::py_eval(
      paste0("a.truth.",field),convert=TRUE)
    expect_equal(replay,original,tolerance=1e-12,
      ignore_attr=TRUE,info=paste("direct source simulation",field))
  }
  expect_equal(et_to_r(reticulate::py_get_attr(
    reticulate::py_get_attr(direct,"observations"),"values")),
    reticulate::py_eval("a.observations.values",convert=TRUE),
    tolerance=1e-12,ignore_attr=TRUE)
  py<-reticulate::py_to_r(reticulate::py_eval(
    "_py_process",convert=FALSE))
  a<-etr_simulate_functional_process(
    mean=function(t)rep(.3,length(t)),
    eigenfunctions=list(function(t)rep(1,length(t))),
    eigenvalues=1,truth_grid=c(0,.25,.5,.75,1),
    n_participants=3L,trials_per_participant=2L,
    participant_eigenvalues=.2,trial_eigenvalues=.1,
    measurement_noise_sd=.03,random_state=73L,
    source_draws=list(curve_scores=py$curve,
      participant_scores=py$participant,
      trial_scores=py$trial,measurement_noise=py$noise))
  expect_equal(unname(a$truth$scores),unname(py$scores),tolerance=1e-12)
  expect_equal(unname(a$truth$latent_on_truth_grid),
    unname(py$latent),tolerance=1e-12)
  expect_equal(unname(a$observations$values),
    unname(py$observed),tolerance=1e-12)
})


test_that("multichannel dense simulation keeps source quadrature and noise covariance",{
  grid<-c(0,.25,.5,.75,1)
  phi<-function(t)cbind(rep(1/sqrt(2),length(t)),
    rep(1/sqrt(2),length(t)))
  out<-etr_simulate_functional_process(
    mean=function(t)cbind(.1+t,.2-t),
    eigenfunctions=list(phi),eigenvalues=.8,
    truth_grid=grid,n_participants=2L,trials_per_participant=2L,
    dimension_names=c("x","y"),
    measurement_noise_sd=c(.05,.2),random_state=5L)
  expect_identical(dim(out$observations$values),c(4L,5L,2L))
  expect_identical(dim(out$truth$eigenfunctions),c(1L,5L,2L))
  expect_identical(dim(out$truth$measurement_noise_covariance),
    c(2L,2L))
  expect_equal(out$truth$measurement_noise_covariance,
    diag(c(.05^2,.2^2)),tolerance=1e-12)
  expect_true(is.list(out$observations$provenance$
    measurement_noise_covariance))
  expect_equal(
    out$observations$provenance$measurement_noise_covariance[[2L]],
    c(0,.2^2),tolerance=1e-12)
  expect_true(etr_validate(out$observations,require_complete=TRUE))
  expect_identical(nrow(etr_functional_simulation_truth_frame(out)),4L)
})
