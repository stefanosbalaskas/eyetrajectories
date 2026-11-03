# Source Python 1.2 _functional_simulation.py::_missingness_mask and
# simulate_functional_process_core at c1cd95ad718327550f7e55393ff38582872f7a94
# Dense MCAR / contiguous-block missingness only. These are first-party
# mathematical and frozen-source tests, not independent certifications.

.etr_dense_dropout_fixture<-function(missingness=NULL) {
  grid<-c(0,.25,.5,.75,1)
  list(mean=function(t)cbind(.1+t,.2-t),
    eigenfunctions=list(function(t)cbind(
      rep(1/sqrt(2),length(t)),rep(1/sqrt(2),length(t)))),
    eigenvalues=1.2,truth_grid=grid,
    n_participants=5L,trials_per_participant=2L,
    dimension_names=c("x","y"),
    participant_eigenvalues=.15,trial_eigenvalues=.08,
    measurement_noise_covariance=matrix(c(.25,.1,.1,.16),2L,2L),
    missingness=missingness,random_state=2026L)
}

test_that("block dropout preserves pre-missing signal and masks both channels",{
  a<-.etr_dense_dropout_fixture(list(kind="block",fraction=.4))
  x<-do.call(etr_simulate_functional_process,a)
  expect_identical(dim(x$observations$values),c(10L,5L,2L))
  expect_identical(x$observations$provenance$missingness_kind,"block")
  expect_identical(x$truth$provenance$missingness_kind,"block")
  expect_equal(x$truth$provenance$missingness_specification,
    a$missingness,tolerance=0)
  for(i in 1:10){
    m<-x$truth$missingness_mask[[i]]
    expect_true(is.logical(m)&&length(m)==5L&&!anyNA(m))
    expect_identical(sum(m),2L)
    expect_identical(diff(which(m)),1L)
    expect_identical(is.na(x$observations$values[i,,1L]),m)
    expect_identical(is.na(x$observations$values[i,,2L]),m)
    baseline<-x$truth$observed_pre_missing[[i]]
    expected<-x$truth$latent_at_observation_times[[i]]+
      x$truth$measurement_noise[[i]]
    expect_equal(baseline,expected,tolerance=1e-12)
    expect_false(anyNA(baseline))
    for(d in 1:2)
      expect_equal(x$observations$values[i,!m,d],
        baseline[!m,d],tolerance=0)
  }
  again<-do.call(etr_simulate_functional_process,a)
  expect_identical(x$observations$values,again$observations$values)
  a$missingness<-list(kind="block",fraction=.01)
  minimum<-do.call(etr_simulate_functional_process,a)
  expect_true(all(vapply(minimum$truth$missingness_mask,sum,integer(1L))==1L))
  a$missingness<-list(kind="block",fraction=0)
  none<-do.call(etr_simulate_functional_process,a)
  expect_false(anyNA(none$observations$values))
})

test_that("MCAR dropout follows declared Bernoulli probability without imputation",{
  a<-.etr_dense_dropout_fixture(list(kind="mcar",probability=.35))
  a$n_participants<-200L
  x<-do.call(etr_simulate_functional_process,a)
  masks<-do.call(rbind,x$truth$missingness_mask)
  expect_identical(dim(masks),c(400L,5L))
  expect_true(all(is.logical(masks)))
  expect_lt(abs(mean(masks)-.35),.06)
  expect_identical(is.na(x$observations$values[,,1L]),masks)
  expect_identical(is.na(x$observations$values[,,2L]),masks)
  expect_equal(x$truth$observed_pre_missing[[1L]],
    x$truth$latent_at_pre_missing_times[[1L]]+
      x$truth$measurement_noise[[1L]],tolerance=1e-12)
  expect_identical(x$truth$provenance$missingness_kind,"mcar")
  expect_true(etr_validate(x$observations))
  expect_error(etr_validate(x$observations,require_complete=TRUE),
    "complete observations required")
})

test_that("dense dropout validates probability fractions and source mask replay",{
  a<-.etr_dense_dropout_fixture(list(kind="mcar",probability=.3))
  for(bad in list(1,-.1,NaN,Inf,"not a number"))
    expect_error(do.call(etr_simulate_functional_process,
      modifyList(a,list(missingness=list(kind="mcar",probability=bad)))),
      "missingness")
  expect_error(do.call(etr_simulate_functional_process,
    modifyList(a,list(missingness=list(kind="block",fraction=1)))),
    "missingness")
  expect_error(do.call(etr_simulate_functional_process,
    modifyList(a,list(missingness=list(kind="mar",probability=.2)))),
    "supports")
  truth<-do.call(etr_simulate_functional_process,
    modifyList(a,list(missingness=NULL)))
  scores<-truth$truth
  mask<-replicate(10L,c(FALSE,TRUE,FALSE,TRUE,FALSE),simplify=FALSE)
  a$source_draws<-list(curve_scores=scores$curve_scores,
    participant_scores=scores$participant_scores,
    trial_scores=scores$trial_scores,
    measurement_noise=array(unlist(scores$measurement_noise),
      dim=c(10L,5L,2L)),
    missingness_mask=mask)
  # Truth noise is stored as per-curve time/channel matrices. Reconstruct
  # n x time x channel explicitly; unlist(list(...)) is not equivalent.
  for(i in seq_len(10L))
    a$source_draws$measurement_noise[i,,]<-scores$measurement_noise[[i]]
  replay<-do.call(etr_simulate_functional_process,a)
  expect_identical(replay$truth$missingness_mask,mask)
  expect_equal(replay$truth$observed_pre_missing,
    truth$truth$observed_pre_missing,tolerance=1e-12)
  expect_true(all(is.na(replay$observations$values[,c(2L,4L),])))
  expect_false(anyNA(replay$observations$values[,c(1L,3L,5L),]))
  bad<-a
  bad$source_draws$missingness_mask[[2L]]<-c(TRUE,NA,FALSE,TRUE,FALSE)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "source_draws missingness_mask")
  bad<-a
  bad$source_draws$missingness_mask<-replicate(9L,rep(FALSE,5L),
    simplify=FALSE)
  expect_error(do.call(etr_simulate_functional_process,bad),
    "source_draws missingness_mask")
})

test_that("frozen Python 1.2 MCAR and block draws replay native complete source truth",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 dense dropout direct-source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  reticulate::py_run_string("
import numpy as np
def _etr_dropout_mean(t):
    return np.column_stack((.1+t,.2-t))
def _etr_dropout_mode(t):
    return np.column_stack((np.full_like(t,1/np.sqrt(2),dtype=float),
                            np.full_like(t,1/np.sqrt(2),dtype=float)))
")
  for(spec in list(list(kind="mcar",probability=.35),
                   list(kind="block",fraction=.4))) {
    args<-.etr_dense_dropout_fixture(spec)
    python<-reticulate::py_call(
      etpy_get_export("simulate_functional_process"),
      mean=reticulate::py_eval("_etr_dropout_mean",convert=FALSE),
      eigenfunctions=reticulate::py_eval("(_etr_dropout_mode,)",
        convert=FALSE),
      eigenvalues=reticulate::py_eval("(1.2,)",convert=FALSE),
      truth_grid=np$asarray(reticulate::r_to_py(args$truth_grid),
        dtype="float64"),
      n_participants=as.integer(args$n_participants),
      trials_per_participant=as.integer(args$trials_per_participant),
      dimension_names=reticulate::r_to_py(as.list(args$dimension_names)),
      participant_eigenvalues=reticulate::py_eval("(.15,)",
        convert=FALSE),
      trial_eigenvalues=reticulate::py_eval("(.08,)",
        convert=FALSE),
      measurement_noise_sd=0.0,
      measurement_noise_covariance=np$asarray(
        reticulate::r_to_py(args$measurement_noise_covariance),
        dtype="float64"),
      missingness=reticulate::r_to_py(spec),
      random_state=as.integer(args$random_state))
    pt<-python$truth
    source_masks<-lapply(et_to_r(pt$missingness_mask),as.logical)
    args$source_draws<-list(
      curve_scores=et_to_r(pt$curve_scores),
      participant_scores=et_to_r(pt$participant_scores),
      trial_scores=et_to_r(pt$trial_scores),
      measurement_noise=et_to_r(np$stack(pt$measurement_noise)),
      missingness_mask=source_masks)
    native<-do.call(etr_simulate_functional_process,args)
    expected<-et_to_r(python$observations$values)
    expected[is.nan(expected)]<-NA_real_
    expect_equal(unname(native$observations$values),unname(expected),
      tolerance=1e-12)
    expect_identical(native$truth$missingness_mask,source_masks)
    expect_equal(unname(native$truth$scores),
      unname(et_to_r(pt$scores)),tolerance=1e-12)
    expect_equal(unname(native$truth$latent_on_truth_grid),
      unname(et_to_r(pt$latent_on_truth_grid)),tolerance=1e-12)
    expect_equal(unname(native$truth$measurement_noise_covariance),
      unname(et_to_r(pt$measurement_noise_covariance)),tolerance=1e-14)
    expect_equal(unname(native$truth$observed_pre_missing[[1L]]),
      unname(et_to_r(pt$observed_pre_missing[[1L]])),tolerance=1e-12)
    expect_identical(native$observations$provenance$missingness_kind,
      spec$kind)
    expect_identical(as.character(et_to_r(
      python$observations$provenance$get("missingness_kind"))),
      spec$kind)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
