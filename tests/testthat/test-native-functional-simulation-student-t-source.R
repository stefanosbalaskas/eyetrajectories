# Frozen Python eyetrajectoriespy==1.2.0 at immutable
# c1cd95ad718327550f7e55393ff38582872f7a94:
# _functional_simulation.py::_sample_curve_scores and public
# simulate_functional_process. This is author-side source evidence;
# independent full-domain certification remains unsigned.

.etr_student_t_source_args<-function(
    design="dense",combine=FALSE){
  a<-list(
    mean=function(t)cbind(.1+t^2,.2-sin(pi*t)),
    eigenfunctions=list(function(t)
      cbind(rep(1/sqrt(2),length(t)),
        rep(1/sqrt(2),length(t)))),
    eigenvalues=1.3,truth_grid=c(0,.25,.5,.75,1),
    n_participants=2L,trials_per_participant=2L,
    dimension_names=c("x","y"),
    observation_design=design,
    participant_eigenvalues=.2,trial_eigenvalues=.1,
    measurement_noise_covariance=matrix(c(.09,.02,.02,.16),2,2),
    score_distribution="student_t",score_df=6.0,
    random_state=927L)
  if(identical(design,"irregular"))
    a$observation_times<-list(c(0,.15,.5,.8,1),
      c(0,.1,.4,.65,.9,1),c(.05,.3,.6,.95),
      c(0,.25,.45,.7,.85,1))
  if(isTRUE(combine)){
    a$missingness<-list(kind="block",fraction=.2)
    a$phase_variation<-list(kind="power",sd=.3)
  }
  a
}

test_that("Student-t curve-score moments match frozen source variance correction",{
  eigenvalues<-c(1.3,.65)
  df<-7
  spec<-.etr_functional_simulation_score_spec("student_t",df)
  expect_equal(spec,list(kind="student_t",df=7),tolerance=0)
  n<-60000L
  scale<-sqrt(eigenvalues*(df-2)/df)
  set.seed(238L)
  reference<-matrix(stats::rt(n*2L,df=df),nrow=n,ncol=2L)*
    matrix(rep(scale,each=n),nrow=n,ncol=2L)
  set.seed(238L)
  observed<-.etr_functional_simulation_sample_curve_scores(
    n,eigenvalues,spec)
  expect_identical(observed,reference)
  expect_equal(as.numeric(colMeans(observed)),c(0,0),tolerance=.04)
  expect_equal(as.numeric(apply(observed,2L,stats::var)),
    eigenvalues,tolerance=.06)
  # Regression guard for the previously qualified Gaussian sampling
  # stream: the exact source helper must consume identical normal draws.
  set.seed(238L)
  gaussian_reference<-matrix(stats::rnorm(8L),4L,2L)*
    matrix(rep(sqrt(eigenvalues),each=4L),4L,2L)
  set.seed(238L)
  expect_identical(
    .etr_functional_simulation_sample_curve_scores(
      4L,eigenvalues,
      .etr_functional_simulation_score_spec("normal",NA_real_)),
    gaussian_reference)
})

test_that("dense and irregular Student-t simulation retains curve/hierarchy source separation",{
  for(design in c("dense","irregular")){
    a<-.etr_student_t_source_args(design)
    set.seed(889L);before<-.Random.seed
    x<-do.call(etr_simulate_functional_process,a)
    expect_identical(before,.Random.seed)
    expect_identical(x$truth$score_distribution,"student_t")
    expect_identical(x$truth$provenance$score_distribution,"student_t")
    expect_equal(x$truth$score_distribution_parameters,
      list(kind="student_t",df=6.0),tolerance=0)
    expect_identical(dim(x$truth$curve_scores),c(4L,1L))
    expect_identical(dim(x$truth$participant_scores),c(2L,1L))
    expect_identical(dim(x$truth$trial_scores),c(4L,1L))
    expect_equal(x$truth$scores,
      x$truth$curve_scores+x$truth$trial_scores+
      x$truth$participant_scores[rep(1:2,each=2),,drop=FALSE],
      tolerance=1e-12)
    expect_true(all(is.finite(x$truth$curve_scores)))
    expect_match(etr_functional_simulation_reporting_text(x),
      "student_t",fixed=TRUE)
    again<-do.call(etr_simulate_functional_process,a)
    expect_identical(x$truth$curve_scores,again$truth$curve_scores)
    expect_identical(x$observations$values,again$observations$values)
    expect_false(x$truth$provenance$full_source_contract_certified)
    if(design=="irregular")
      expect_s3_class(x$observations,"etr_irregular_trajectory_set")
    else expect_s3_class(x$observations,"etr_trajectory_set")
  }
})

test_that("Student-t source requires df greater than two and rejects invalid distribution",{
  a<-.etr_student_t_source_args()
  for(bad in list(2,1.9,-.4,NaN,Inf,NA_real_,"invalid",c(4,5))){
    args<-a;args$score_df<-bad
    expect_error(do.call(etr_simulate_functional_process,args),
      "score_df must be finite and greater than 2")
  }
  args<-a;args$score_distribution<-"skew_normal"
  expect_error(do.call(etr_simulate_functional_process,args),
    "score_distribution must be")
  args<-a;args$score_df<-"5.5"
  out<-do.call(etr_simulate_functional_process,args)
  expect_equal(out$truth$score_distribution_parameters$df,5.5,tolerance=0)
  # The frozen normal source does not validate score_df.
  args<-a;args$score_distribution<-"normal"
  args$score_df<-NA_real_
  out<-do.call(etr_simulate_functional_process,args)
  expect_identical(out$truth$score_distribution_parameters,
    list(kind="normal"))
})

test_that("frozen Python 1.2 Student-t curve-score and observed truth replay dense and irregular",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 Student-t simulation source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  reticulate::py_run_string("
import numpy as np
def _etr_t_mean(t):
    return np.column_stack((.1 + t*t,.2-np.sin(np.pi*t)))
def _etr_t_mode(t):
    return np.column_stack((np.full_like(t,1/np.sqrt(2),dtype=float),
                            np.full_like(t,1/np.sqrt(2),dtype=float)))
")
  for(design in c("dense","irregular")){
    combined<-identical(design,"irregular")
    a<-.etr_student_t_source_args(design,combine=combined)
    kwargs<-list(
      mean=reticulate::py_eval("_etr_t_mean",convert=FALSE),
      eigenfunctions=reticulate::py_eval("(_etr_t_mode,)",
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
      score_distribution="student_t",score_df=6.0,
      random_state=as.integer(a$random_state))
    if(design=="irregular")
      kwargs$observation_times<-reticulate::r_to_py(a$observation_times)
    if(combined){
      kwargs$missingness<-reticulate::r_to_py(a$missingness)
      kwargs$phase_variation<-reticulate::r_to_py(a$phase_variation)
    }
    python<-do.call(reticulate::py_call,
      c(list(etpy_get_export("simulate_functional_process")),kwargs))
    pt<-python$truth
    draws<-list(
      curve_scores=et_to_r(pt$curve_scores),
      participant_scores=et_to_r(pt$participant_scores),
      trial_scores=et_to_r(pt$trial_scores),
      measurement_noise=if(design=="dense")
        et_to_r(np$stack(pt$measurement_noise))
      else et_to_r(pt$measurement_noise))
    if(combined){
      draws$missingness_mask<-lapply(
        et_to_r(pt$missingness_mask),as.logical)
      draws$phase_exponents<-as.numeric(
        unlist(et_to_r(pt$provenance$get("phase_exponents"))))
    }
    a$source_draws<-draws
    native<-do.call(etr_simulate_functional_process,a)
    expect_equal(unname(native$truth$curve_scores),
      unname(et_to_r(pt$curve_scores)),tolerance=1e-12)
    expect_equal(unname(native$truth$scores),
      unname(et_to_r(pt$scores)),tolerance=1e-12)
    expect_equal(unname(native$truth$latent_on_truth_grid),
      unname(et_to_r(pt$latent_on_truth_grid)),tolerance=1e-12)
    expect_identical(native$truth$score_distribution,"student_t")
    source_params<-et_to_r(pt$score_distribution_parameters)
    expect_identical(as.character(source_params$kind),"student_t")
    expect_equal(native$truth$score_distribution_parameters$df,
      as.numeric(source_params$df),tolerance=0)
    py_pre<-et_to_r(pt$observed_pre_missing)
    expect_identical(length(py_pre),4L)
    for(i in seq_len(4L))
      expect_equal(unname(native$truth$observed_pre_missing[[i]]),
        unname(py_pre[[i]]),tolerance=1e-12)
    if(design=="dense"){
      expected<-et_to_r(python$observations$values)
      expected[is.nan(expected)]<-NA_real_
      expect_equal(unname(native$observations$values),
        unname(expected),tolerance=1e-12)
    }else{
      py_times<-et_to_r(python$observations$time)
      py_values<-et_to_r(python$observations$values)
      py_warps<-et_to_r(pt$warped_observation_times)
      expect_identical(native$truth$missingness_mask,
        draws$missingness_mask)
      expect_equal(native$truth$provenance$phase_exponents,
        draws$phase_exponents,tolerance=0)
      for(i in seq_len(4L)){
        expect_equal(native$observations$time[[i]],
          as.numeric(py_times[[i]]),tolerance=0)
        expect_equal(unname(native$observations$values[[i]]),
          unname(py_values[[i]]),tolerance=1e-12)
        expect_equal(native$truth$warped_observation_times[[i]],
          as.numeric(py_warps[[i]]),tolerance=1e-12)
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
