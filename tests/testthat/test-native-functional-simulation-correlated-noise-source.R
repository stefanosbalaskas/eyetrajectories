# Frozen Python 1.2 _functional_simulation.py::
# _resolve_noise_covariance and simulate_functional_process_core.
# Source SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# Direct Python replay isolates RNG differences by retaining source draws.
# Author-side source evidence only; independent certification remains unsigned.

.etr_simulation_noise_source_args<-function(){
  list(mean=function(t)cbind(.1+t,.2-t),
    eigenfunctions=list(function(t)cbind(rep(1/sqrt(2),length(t)),
      rep(1/sqrt(2),length(t)))),
    eigenvalues=1.2,truth_grid=c(0,.25,.5,.75,1),
    n_participants=5L,trials_per_participant=2L,
    dimension_names=c("x","y"),
    participant_eigenvalues=.15,trial_eigenvalues=.08,
    measurement_noise_covariance=matrix(c(.25,.1,.1,.16),2L,2L),
    random_state=2026L)
}

test_that("native multichannel correlated simulator preserves source covariance truth",{
  a<-.etr_simulation_noise_source_args()
  result<-do.call(etr_simulate_functional_process,a)
  expect_s3_class(result,"etr_functional_simulation_result")
  expect_identical(dim(result$observations$values),c(10L,5L,2L))
  expect_equal(result$truth$measurement_noise_covariance,
    a$measurement_noise_covariance,tolerance=0)
  expect_equal(result$observations$provenance$
    measurement_noise_covariance[[1L]],c(.25,.1),tolerance=0)
  expect_equal(result$observations$provenance$
    measurement_noise_covariance[[2L]],c(.1,.16),tolerance=0)
  expect_equal(result$observations$provenance$measurement_noise_sd,
    c(.5,.4),tolerance=1e-14)
  for(i in seq_len(10L)){
    obs<-matrix(result$observations$values[i,,,drop=FALSE],
      nrow=5L,ncol=2L)
    latent<-matrix(result$truth$latent_on_truth_grid[i,,,drop=FALSE],
      nrow=5L,ncol=2L)
    expect_equal(obs,latent+result$truth$measurement_noise[[i]],
      tolerance=1e-12)
  }
  repeat_result<-do.call(etr_simulate_functional_process,a)
  expect_identical(result$observations$values,
    repeat_result$observations$values)
  expect_identical(result$truth$measurement_noise_covariance,
    repeat_result$truth$measurement_noise_covariance)
  expect_false(result$truth$provenance$full_source_contract_certified)
})

test_that("native PSD covariance supports singular and zero noise, rejects invalid matrices",{
  a<-.etr_simulation_noise_source_args()
  a$measurement_noise_covariance<-matrix(c(.25,.25,.25,.25),2L,2L)
  singular<-do.call(etr_simulate_functional_process,a)
  expect_equal(singular$truth$measurement_noise_covariance,
    a$measurement_noise_covariance,tolerance=0)
  expect_equal(vapply(singular$truth$measurement_noise,function(m)
    max(abs(m[,1L]-m[,2L])),numeric(1L)),
    rep(0,10L),tolerance=1e-12)
  a$measurement_noise_covariance<-matrix(0,2L,2L)
  zero<-do.call(etr_simulate_functional_process,a)
  expect_true(all(vapply(zero$truth$measurement_noise,function(m)
    all(m==0),logical(1L))))
  expect_equal(zero$observations$values,zero$truth$latent_on_truth_grid,
    tolerance=0)
  a$measurement_noise_covariance<-matrix(c(.25,.1,.1,.16),2L,2L)
  a$measurement_noise_sd<-.05
  expect_error(do.call(etr_simulate_functional_process,a),
    "cannot both specify non-zero")
  a$measurement_noise_sd<-0
  bad<-a;bad$measurement_noise_covariance<-matrix(c(.2,.1,.3,.2),2L,2L)
  expect_error(do.call(etr_simulate_functional_process,bad),"symmetric")
  bad<-a;bad$measurement_noise_covariance<-diag(c(1,-.01))
  expect_error(do.call(etr_simulate_functional_process,bad),
    "positive semidefinite")
  bad<-a;bad$measurement_noise_covariance<-matrix(1,1L,1L)
  expect_error(do.call(etr_simulate_functional_process,bad),"shape")
  bad<-a;bad$measurement_noise_covariance<-matrix(c(1,NaN,NaN,1),2L,2L)
  expect_error(do.call(etr_simulate_functional_process,bad),"finite")
})

test_that("correlated native Gaussian noise reproduces declared cross-channel covariance",{
  a<-.etr_simulation_noise_source_args()
  a$n_participants<-240L
  a$trials_per_participant<-1L
  result<-do.call(etr_simulate_functional_process,a)
  raw<-result$observations$values-result$truth$latent_on_truth_grid
  observed<-stats::cov(cbind(as.vector(raw[,,1L]),
    as.vector(raw[,,2L])))
  expect_equal(observed,a$measurement_noise_covariance,tolerance=.09)
  expect_gt(observed[1L,2L],.05)
  expect_true(all(is.finite(raw)))
})

test_that("direct frozen Python 1.2 correlated noise draws replay native full scientific truth",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 correlated noise source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  reticulate::py_run_string("
import numpy as np
def _etr_sim_cov_mean(t):
    return np.column_stack((.1+t, .2-t))
def _etr_sim_cov_phi(t):
    return np.column_stack((
        np.full_like(t,1/np.sqrt(2),dtype=float),
        np.full_like(t,1/np.sqrt(2),dtype=float)))
")
  a<-.etr_simulation_noise_source_args()
  python<-reticulate::py_call(
    etpy_get_export("simulate_functional_process"),
    mean=reticulate::py_eval("_etr_sim_cov_mean",convert=FALSE),
    eigenfunctions=reticulate::py_eval("(_etr_sim_cov_phi,)",
      convert=FALSE),
    eigenvalues=reticulate::py_eval("(1.2,)",convert=FALSE),
    truth_grid=np$asarray(reticulate::r_to_py(a$truth_grid),
      dtype="float64"),
    n_participants=as.integer(a$n_participants),
    trials_per_participant=as.integer(a$trials_per_participant),
    dimension_names=reticulate::r_to_py(as.list(a$dimension_names)),
    participant_eigenvalues=reticulate::py_eval("(.15,)",
      convert=FALSE),
    trial_eigenvalues=reticulate::py_eval("(.08,)",
      convert=FALSE),
    measurement_noise_sd=0.0,
    measurement_noise_covariance=np$asarray(
      reticulate::r_to_py(a$measurement_noise_covariance),
      dtype="float64"),
    random_state=as.integer(a$random_state))
  truth<-python$truth
  source_draws<-list(
    curve_scores=et_to_r(truth$curve_scores),
    participant_scores=et_to_r(truth$participant_scores),
    trial_scores=et_to_r(truth$trial_scores),
    measurement_noise=et_to_r(np$stack(truth$measurement_noise)))
  a$source_draws<-source_draws
  native<-do.call(etr_simulate_functional_process,a)
  expect_equal(unname(native$truth$measurement_noise_covariance),
    unname(et_to_r(truth$measurement_noise_covariance)),
    tolerance=1e-14)
  expect_equal(unname(native$truth$scores),
    unname(et_to_r(truth$scores)),tolerance=1e-12)
  expect_equal(unname(native$truth$latent_on_truth_grid),
    unname(et_to_r(truth$latent_on_truth_grid)),tolerance=1e-12)
  expect_equal(unname(native$observations$values),
    unname(et_to_r(python$observations$values)),tolerance=1e-12)
  expect_equal(native$observations$provenance$measurement_noise_sd,
    c(.5,.4),tolerance=1e-14)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
