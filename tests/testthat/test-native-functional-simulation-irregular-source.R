# Frozen Python 1.2 _functional_simulation.py irregular observation law.
# Pinned Python SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer source comparisons only, not independent full-domain certification.

.etr_irregular_process_fixture<-function(
    schedules=NULL,missingness=NULL,counts=NULL,design="uniform"){
  list(mean=function(t)cbind(.1+t,.2-t),
    eigenfunctions=list(function(t)
      cbind(rep(1/sqrt(2),length(t)),
        rep(1/sqrt(2),length(t)))),
    eigenvalues=1.3,truth_grid=c(0,.25,.5,.75,1),
    n_participants=2L,trials_per_participant=2L,
    dimension_names=c("x","y"),
    observation_design="irregular",
    observation_times=schedules,samples_per_curve=counts,
    irregular_time_design=design,
    participant_eigenvalues=.2,trial_eigenvalues=.1,
    measurement_noise_covariance=matrix(c(.09,.02,.02,.16),2L,2L),
    missingness=missingness,random_state=927L)
}
.etr_irregular_source_schedules<-function(){
  list(c(0,.15,.5,.8,1),
       c(0,.1,.4,.65,.9,1),
       c(.05,.3,.6,.95),
       c(0,.25,.45,.7,.85,1))
}

test_that("native irregular functional simulator directly evaluates per-curve samples",{
  schedules<-.etr_irregular_source_schedules()
  a<-.etr_irregular_process_fixture(schedules)
  set.seed(503L);before<-.Random.seed
  x<-do.call(etr_simulate_functional_process,a)
  expect_identical(before,.Random.seed)
  expect_s3_class(x,"etr_functional_simulation_result")
  expect_s3_class(x$observations,"etr_irregular_trajectory_set")
  expect_identical(x$observations$time,schedules)
  expect_identical(x$truth$pre_missing_observation_times,schedules)
  expect_identical(x$truth$observation_times,schedules)
  expect_identical(x$truth$observation_design,"irregular")
  expect_false(x$truth$provenance$raw_dense_to_irregular_interpolation_performed)
  expect_identical(x$observations$curve_ids,
    c("P001|T01","P001|T02","P002|T01","P002|T02"))
  expect_equal(x$truth$measurement_noise_covariance,
    a$measurement_noise_covariance,tolerance=0)
  expect_true(etr_functional_simulation_truth_frame(x)$
    n_pre_missing_samples[1L]==length(schedules[[1L]]))
  for(i in seq_along(schedules)){
    time<-schedules[[i]]
    expect_identical(nrow(x$observations$values[[i]]),length(time))
    expect_identical(ncol(x$observations$values[[i]]),2L)
    phi<-1/sqrt(2)
    expected<-cbind(.1+time,.2-time)+
      x$truth$scores[i,1L]*phi
    expect_equal(x$truth$latent_at_pre_missing_times[[i]],
      expected,tolerance=1e-12)
    expect_equal(x$observations$values[[i]],
      expected+x$truth$measurement_noise[[i]],tolerance=1e-12)
    expect_false(any(x$truth$missingness_mask[[i]]))
  }
  repeat_x<-do.call(etr_simulate_functional_process,a)
  expect_identical(x$observations$values,repeat_x$observations$values)
})

test_that("irregular generated uniform, clustered and boundary-poor schedules are bounded",{
  for(design in c("uniform","center_clustered","boundary_poor")){
    a<-.etr_irregular_process_fixture(counts=c(4L,7L),design=design)
    x<-do.call(etr_simulate_functional_process,a)
    expect_s3_class(x$observations,"etr_irregular_trajectory_set")
    expect_identical(x$truth$provenance$irregular_time_design,design)
    expect_true(all(lengths(x$observations$time)>=4L))
    expect_true(all(lengths(x$observations$time)<=7L))
    for(tt in x$observations$time){
      expect_true(all(is.finite(tt))&&all(diff(tt)>0))
      expect_identical(tt[1L],0)
      expect_identical(tail(tt,1L),1)
      if(design=="boundary_poor")
        expect_true(all(tt[-c(1L,length(tt))]>=.15&
          tt[-c(1L,length(tt))]<=.85))
    }
    b<-.etr_irregular_process_fixture(counts=5L,design=design)
    y<-do.call(etr_simulate_functional_process,b)
    expect_identical(lengths(y$observations$time),rep.int(5L,4L))
  }
})

test_that("irregular source dropout removes samples but preserves complete truth",{
  schedules<-.etr_irregular_source_schedules()
  a<-.etr_irregular_process_fixture(schedules,
    missingness=list(kind="block",fraction=.4))
  x<-do.call(etr_simulate_functional_process,a)
  expect_s3_class(x$observations,"etr_irregular_trajectory_set")
  expect_identical(x$truth$provenance$missingness_kind,"block")
  for(i in seq_along(schedules)){
    mask<-x$truth$missingness_mask[[i]]
    n<-length(schedules[[i]])
    block<-max(1L,as.integer(floor(.4*n)))
    expect_identical(sum(mask),block)
    expect_identical(x$observations$time[[i]],schedules[[i]][!mask])
    expect_equal(x$truth$latent_at_observation_times[[i]],
      x$truth$latent_at_pre_missing_times[[i]][!mask,,drop=FALSE],
      tolerance=0)
    expect_equal(x$observations$values[[i]],
      x$truth$observed_pre_missing[[i]][!mask,,drop=FALSE],
      tolerance=0)
    expect_identical(length(x$truth$measurement_noise[[i]]),
      length(schedules[[i]])*2L)
  }
  frame<-etr_functional_simulation_truth_frame(x)
  expect_identical(as.integer(frame$n_observed_samples),
    as.integer(lengths(x$observations$time)))

  # Native source-draw replay with irregular MCAR is explicit: masks
  # are applied to each curve's original schedule, not to truth_grid.
  fixed_masks<-lapply(schedules,function(time){
    mask<-rep(FALSE,length(time));mask[2L]<-TRUE;mask
  })
  mc_args<-a
  mc_args$missingness<-list(kind="mcar",probability=.3)
  mc_args$source_draws<-list(curve_scores=x$truth$curve_scores,
    participant_scores=x$truth$participant_scores,
    trial_scores=x$truth$trial_scores,
    measurement_noise=x$truth$measurement_noise,
    missingness_mask=fixed_masks)
  replay<-do.call(etr_simulate_functional_process,mc_args)
  expect_identical(replay$truth$missingness_mask,fixed_masks)
  for(i in seq_along(schedules)){
    expect_identical(replay$observations$time[[i]],
      schedules[[i]][-2L])
    expect_equal(replay$observations$values[[i]],
      x$truth$observed_pre_missing[[i]][-2L,,drop=FALSE],
      tolerance=1e-12)
  }
  bad<-mc_args
  bad$source_draws$missingness_mask<-fixed_masks[-1L]
  expect_error(do.call(etr_simulate_functional_process,bad),
    "source_draws missingness_mask")
})

test_that("irregular source schedules and missingness fail closed when malformed",{
  a<-.etr_irregular_process_fixture(.etr_irregular_source_schedules())
  bad<-a
  bad$observation_times[[1L]]<-c(0,.6,.6,1)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "strictly increasing")
  bad<-a;bad$observation_times[[2L]]<-c(-.01,1)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "outside truth_grid support")
  bad<-a;bad$observation_times<-bad$observation_times[-1L]
  expect_error(do.call(etr_simulate_functional_process,bad),
    "exactly one time array per curve")
  bad<-a;bad$samples_per_curve<-3L
  expect_error(do.call(etr_simulate_functional_process,bad),
    "not both")
  bad<-a;bad$observation_times<-NULL
  expect_error(do.call(etr_simulate_functional_process,bad),
    "requires observation_times or samples_per_curve")
  bad<-a;bad$observation_times<-NULL
  bad$samples_per_curve<-c(6L,3L)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "minimum <= maximum")
  bad<-a;bad$observation_times<-NULL
  bad$samples_per_curve<-3.5
  expect_error(do.call(etr_simulate_functional_process,bad),
    "integer")
  bad<-a;bad$observation_times<-NULL
  bad$samples_per_curve<-5L
  bad$irregular_time_design<-"unknown"
  expect_error(do.call(etr_simulate_functional_process,bad),
    "irregular_time_design")
  bad<-a;bad$missingness<-list(kind="block",fraction=.99)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "fewer than two irregular observations")
  bad<-a;bad$phase_variation<-list(kind="power",sd=.1)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "no phase variation")
})

test_that("real frozen Python 1.2 irregular source schedules and truth replay in R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned frozen Python 1.2 irregular simulator oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  reticulate::py_run_string("
import numpy as np
def _etr_irr_mean(t):
    return np.column_stack((.1+t,.2-t))
def _etr_irr_phi(t):
    return np.column_stack((
        np.full_like(t,1/np.sqrt(2),dtype=float),
        np.full_like(t,1/np.sqrt(2),dtype=float)))
")
  for(spec in list(NULL,list(kind="block",fraction=.4))){
    a<-.etr_irregular_process_fixture(
      .etr_irregular_source_schedules(),missingness=spec)
    args<-list(
      mean=reticulate::py_eval("_etr_irr_mean",convert=FALSE),
      eigenfunctions=reticulate::py_eval("(_etr_irr_phi,)",
        convert=FALSE),
      eigenvalues=reticulate::py_eval("(1.3,)",convert=FALSE),
      truth_grid=np$asarray(reticulate::r_to_py(a$truth_grid),
        dtype="float64"),
      n_participants=as.integer(a$n_participants),
      trials_per_participant=as.integer(a$trials_per_participant),
      dimension_names=reticulate::r_to_py(as.list(a$dimension_names)),
      observation_design="irregular",
      observation_times=reticulate::r_to_py(a$observation_times),
      participant_eigenvalues=reticulate::py_eval("(.2,)",
        convert=FALSE),
      trial_eigenvalues=reticulate::py_eval("(.1,)",
        convert=FALSE),
      measurement_noise_sd=0.0,
      measurement_noise_covariance=np$asarray(
        reticulate::r_to_py(a$measurement_noise_covariance),
        dtype="float64"),
      random_state=as.integer(a$random_state))
    if(!is.null(spec))args$missingness<-reticulate::r_to_py(spec)
    python<-do.call(reticulate::py_call,
      c(list(etpy_get_export("simulate_functional_process")),args))
    pt<-python$truth
    py_noise<-et_to_r(pt$measurement_noise)
    py_masks<-lapply(et_to_r(pt$missingness_mask),as.logical)
    a$source_draws<-list(
      curve_scores=et_to_r(pt$curve_scores),
      participant_scores=et_to_r(pt$participant_scores),
      trial_scores=et_to_r(pt$trial_scores),
      measurement_noise=py_noise)
    if(!is.null(spec))a$source_draws$missingness_mask<-py_masks
    native<-do.call(etr_simulate_functional_process,a)
    py_times<-et_to_r(python$observations$time)
    py_values<-et_to_r(python$observations$values)
    py_pre<-et_to_r(pt$observed_pre_missing)
    py_pre_times<-et_to_r(pt$pre_missing_observation_times)
    py_latent<-et_to_r(pt$latent_at_pre_missing_times)
    expect_true(is.list(py_times)&&is.list(py_values)&&
      is.list(py_pre)&&is.list(py_noise))
    expect_identical(length(py_times),length(native$observations$time))
    expect_identical(native$truth$missingness_mask,py_masks)
    for(i in seq_along(py_times)){
      expect_equal(native$observations$time[[i]],py_times[[i]],
        tolerance=0)
      expect_equal(unname(native$observations$values[[i]]),
        unname(py_values[[i]]),tolerance=1e-12)
      expect_equal(native$truth$pre_missing_observation_times[[i]],
        py_pre_times[[i]],tolerance=0)
      expect_equal(unname(native$truth$observed_pre_missing[[i]]),
        unname(py_pre[[i]]),tolerance=1e-12)
      expect_equal(unname(native$truth$latent_at_pre_missing_times[[i]]),
        unname(py_latent[[i]]),tolerance=1e-12)
    }
    expect_equal(unname(native$truth$scores),
      unname(et_to_r(pt$scores)),tolerance=1e-12)
    expect_equal(unname(native$truth$latent_on_truth_grid),
      unname(et_to_r(pt$latent_on_truth_grid)),tolerance=1e-12)
    expect_false(native$truth$provenance$
      raw_dense_to_irregular_interpolation_performed)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
