# Pinned eyetrajectoriespy 1.2.0 _functional_simulation.py:
# _resolve_phase_variation, _apply_power_warp,
# simulate_functional_process_core. Immutable pinned Python commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# First-party finite source qualification, not independent certification.

.etr_phase_source_args<-function(design="dense",missingness=NULL) {
  grid<-c(0,.25,.5,.75,1)
  args<-list(
    mean=function(t)cbind(.1+t^2,.2-sin(pi*t)),
    eigenfunctions=list(function(t)
      cbind(rep(1/sqrt(2),length(t)),
        rep(1/sqrt(2),length(t)))),
    eigenvalues=1.3,truth_grid=grid,
    n_participants=2L,trials_per_participant=2L,
    dimension_names=c("x","y"),
    observation_design=design,
    participant_eigenvalues=.2,trial_eigenvalues=.1,
    measurement_noise_covariance=matrix(c(.09,.02,.02,.16),2,2),
    missingness=missingness,phase_variation=list(kind="power",sd=.35),
    random_state=927L)
  if(identical(design,"irregular"))
    args$observation_times<-list(c(0,.15,.5,.8,1),
      c(0,.1,.4,.65,.9,1),c(.05,.3,.6,.95),
      c(0,.25,.45,.7,.85,1))
  args
}

.etr_phase_fixed_draws<-function(args,exponents) {
  n<-args$n_participants*args$trials_per_participant
  k<-length(args$eigenvalues)
  score<-matrix(c(-.8,.5,1.2,-.2),n,k)
  curve<-score
  participant<-matrix(0,args$n_participants,k)
  trial<-matrix(0,n,k)
  noise<-if(identical(args$observation_design,"dense"))
    array(0,c(n,length(args$truth_grid),length(args$dimension_names)))
  else lapply(args$observation_times,function(time)
    matrix(0,length(time),length(args$dimension_names)))
  list(curve_scores=curve,participant_scores=participant,
    trial_scores=trial,measurement_noise=noise,
    phase_exponents=exponents)
}

.etr_phase_analytic_mean<-function(time) cbind(
  .1+time^2,.2-sin(pi*time))

test_that("dense source power phase directly warps latent functions while preserving raw observation times",{
  a<-.etr_phase_source_args()
  a$source_draws<-.etr_phase_fixed_draws(a,c(.65,1,1.3,1.75))
  x<-do.call(etr_simulate_functional_process,a)
  expect_s3_class(x$observations,"etr_trajectory_set")
  expect_identical(x$observations$time,a$truth_grid)
  expect_identical(x$truth$provenance$phase_variation_kind,"power")
  expect_equal(x$truth$provenance$phase_exponents,
    a$source_draws$phase_exponents,tolerance=0)
  expect_equal(x$truth$phase_warps_on_truth_grid[2L,],
    a$truth_grid,tolerance=0)
  expect_gt(max(abs(x$truth$phase_warps_on_truth_grid[1L,]-
    a$truth_grid)),.01)
  for(i in seq_len(4L)) {
    warped<-a$truth_grid^a$source_draws$phase_exponents[i]
    expect_equal(as.numeric(x$truth$phase_warps_on_truth_grid[i,]),
      warped,tolerance=1e-14)
    expect_equal(x$truth$warped_pre_missing_observation_times[[i]],
      warped,tolerance=1e-14)
    expected<-.etr_phase_analytic_mean(warped)+
      x$truth$scores[i,1L]/sqrt(2)
    expect_equal(matrix(x$truth$latent_on_truth_grid[i,,,drop=FALSE],
      nrow=length(a$truth_grid),ncol=2L),expected,tolerance=1e-12)
    expect_equal(matrix(x$observations$values[i,,,drop=FALSE],
      nrow=length(a$truth_grid),ncol=2L),expected,tolerance=1e-12)
  }
  frame<-etr_functional_simulation_truth_frame(x)
  expect_true(any(frame$max_phase_displacement>.01))
  expect_identical(frame$n_missing_by_design,rep.int(0L,4L))
})

test_that("irregular power phase and block dropout retain original and warped schedules separately",{
  a<-.etr_phase_source_args("irregular",
    list(kind="block",fraction=.2))
  a$source_draws<-.etr_phase_fixed_draws(a,c(.75,.9,1.25,1.8))
  masks<-lapply(a$observation_times,function(time) {
    out<-rep(FALSE,length(time));out[2L]<-TRUE;out
  })
  a$source_draws$missingness_mask<-masks
  x<-do.call(etr_simulate_functional_process,a)
  expect_s3_class(x$observations,"etr_irregular_trajectory_set")
  expect_identical(x$truth$provenance$phase_variation_kind,"power")
  expect_equal(x$truth$provenance$phase_exponents,
    a$source_draws$phase_exponents,tolerance=0)
  for(i in seq_len(4L)) {
    raw<-a$observation_times[[i]]
    warped<-raw^a$source_draws$phase_exponents[i]
    keep<-!masks[[i]]
    expect_identical(x$truth$pre_missing_observation_times[[i]],raw)
    expect_equal(x$truth$warped_pre_missing_observation_times[[i]],
      warped,tolerance=1e-14)
    expect_identical(x$observations$time[[i]],raw[keep])
    expect_equal(x$truth$warped_observation_times[[i]],
      warped[keep],tolerance=1e-14)
    expected<-.etr_phase_analytic_mean(warped)+
      x$truth$scores[i,1L]/sqrt(2)
    expect_equal(x$truth$latent_at_pre_missing_times[[i]],
      expected,tolerance=1e-12)
    expect_equal(x$observations$values[[i]],
      expected[keep,,drop=FALSE],tolerance=1e-12)
    expect_equal(x$truth$latent_at_observation_times[[i]],
      expected[keep,,drop=FALSE],tolerance=1e-12)
  }
  frame<-etr_functional_simulation_truth_frame(x)
  expect_true(any(frame$max_phase_displacement>0))
  expect_identical(as.integer(frame$n_observed_samples),
    as.integer(lengths(x$observations$time)))
})

test_that("source power phase validates signed SD and finite retained exponents",{
  a<-.etr_phase_source_args()
  for(bad in list(-.1,NA_real_,NaN,Inf,"invalid")) {
    a$phase_variation<-list(kind="power",sd=bad)
    expect_error(do.call(etr_simulate_functional_process,a),
      "finite and non-negative")
  }
  a$phase_variation<-list(kind="linear",sd=.1)
  expect_error(do.call(etr_simulate_functional_process,a),
    "only kind='power'")
  a$phase_variation<-list(kind="power",sd=.1)
  a$source_draws<-.etr_phase_fixed_draws(a,c(.5,1,1.5,2))
  a$source_draws$phase_exponents[3L]<-0
  expect_error(do.call(etr_simulate_functional_process,a),
    "positive finite exponent")
  a$source_draws$phase_exponents<-rep(1,3L)
  expect_error(do.call(etr_simulate_functional_process,a),
    "positive finite exponent")
  a$source_draws$phase_exponents<-c(.7,1,1.4,2)
  one<-do.call(etr_simulate_functional_process,a)
  expect_true(all(is.finite(one$truth$latent_on_truth_grid)))
  again<-do.call(etr_simulate_functional_process,a)
  expect_identical(one$observations$values,again$observations$values)
  a$source_draws<-NULL
  own<-do.call(etr_simulate_functional_process,a)
  expect_true(all(is.finite(own$truth$provenance$phase_exponents)))
  expect_identical(length(own$truth$provenance$phase_exponents),4L)
})

test_that("dense and irregular power phase source truth and observed values replay frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 power-phase source direct oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  reticulate::py_run_string("
import numpy as np
def _etr_phase_mean(t):
    return np.column_stack((.1 + t*t, .2 - np.sin(np.pi*t)))
def _etr_phase_mode(t):
    return np.column_stack((np.full_like(t,1/np.sqrt(2),dtype=float),
                            np.full_like(t,1/np.sqrt(2),dtype=float)))
")
  for(design in c("dense","irregular")) {
    spec<-list(kind="block",fraction=.2)
    a<-.etr_phase_source_args(design,spec)
    kwargs<-list(
      mean=reticulate::py_eval("_etr_phase_mean",convert=FALSE),
      eigenfunctions=reticulate::py_eval("(_etr_phase_mode,)",
        convert=FALSE),
      eigenvalues=reticulate::py_eval("(1.3,)",convert=FALSE),
      truth_grid=np$asarray(reticulate::r_to_py(a$truth_grid),
        dtype="float64"),
      n_participants=as.integer(a$n_participants),
      trials_per_participant=as.integer(a$trials_per_participant),
      dimension_names=reticulate::r_to_py(as.list(a$dimension_names)),
      observation_design=design,
      participant_eigenvalues=reticulate::py_eval("(.2,)",
        convert=FALSE),
      trial_eigenvalues=reticulate::py_eval("(.1,)",
        convert=FALSE),
      measurement_noise_sd=0.0,
      measurement_noise_covariance=np$asarray(
        reticulate::r_to_py(a$measurement_noise_covariance),
        dtype="float64"),
      missingness=reticulate::r_to_py(spec),
      phase_variation=reticulate::r_to_py(a$phase_variation),
      random_state=as.integer(a$random_state))
    if(identical(design,"irregular"))
      kwargs$observation_times<-reticulate::r_to_py(a$observation_times)
    python<-do.call(reticulate::py_call,
      c(list(etpy_get_export("simulate_functional_process")),kwargs))
    pt<-python$truth
    py_masks<-lapply(et_to_r(pt$missingness_mask),as.logical)
    exponent<-as.numeric(unlist(et_to_r(
      pt$provenance$get("phase_exponents"))))
    a$source_draws<-list(
      curve_scores=et_to_r(pt$curve_scores),
      participant_scores=et_to_r(pt$participant_scores),
      trial_scores=et_to_r(pt$trial_scores),
      measurement_noise=if(identical(design,"dense"))
        et_to_r(np$stack(pt$measurement_noise))
      else et_to_r(pt$measurement_noise),
      missingness_mask=py_masks,
      phase_exponents=exponent)
    native<-do.call(etr_simulate_functional_process,a)
    expect_equal(native$truth$provenance$phase_exponents,exponent,
      tolerance=0)
    expect_equal(unname(native$truth$phase_warps_on_truth_grid),
      unname(et_to_r(pt$phase_warps_on_truth_grid)),tolerance=1e-12)
    expect_equal(unname(native$truth$latent_on_truth_grid),
      unname(et_to_r(pt$latent_on_truth_grid)),tolerance=1e-12)
    expect_identical(native$truth$missingness_mask,py_masks)
    py_pre<-et_to_r(pt$observed_pre_missing)
    py_warped_pre<-et_to_r(pt$warped_pre_missing_observation_times)
    py_warped_final<-et_to_r(pt$warped_observation_times)
    for(i in seq_len(4L)) {
      expect_equal(native$truth$observed_pre_missing[[i]],
        py_pre[[i]],tolerance=1e-12)
      expect_equal(native$truth$warped_pre_missing_observation_times[[i]],
        as.numeric(py_warped_pre[[i]]),tolerance=1e-12)
      expect_equal(native$truth$warped_observation_times[[i]],
        as.numeric(py_warped_final[[i]]),tolerance=1e-12)
    }
    if(identical(design,"dense")){
      expected<-et_to_r(python$observations$values)
      expected[is.nan(expected)]<-NA_real_
      expect_equal(unname(native$observations$values),
        unname(expected),tolerance=1e-12)
      expect_identical(native$observations$time,a$truth_grid)
    }else{
      py_time<-et_to_r(python$observations$time)
      py_values<-et_to_r(python$observations$values)
      for(i in seq_len(4L)) {
        expect_equal(native$observations$time[[i]],
          as.numeric(py_time[[i]]),tolerance=0)
        expect_equal(native$observations$values[[i]],
          py_values[[i]],tolerance=1e-12)
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
