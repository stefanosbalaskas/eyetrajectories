# Pinned Python 1.2.0 reporting.py source contract.
.etr_test_simulation_truth_result <- function(){
  n<-4L;g<-seq(0,1,length.out=5L)
  meta<-data.frame(participant_id=c("p1","p1","p2","p2"),
    trial_id=c("a","b","a","b"),stringsAsFactors=FALSE)
  warp<-matrix(rep(g,each=n),nrow=n);warp[2L,3L]<-.63
  scores<-matrix(seq_len(n*2L)/10,nrow=n)
  list(observations=list(curve_ids=paste0("curve_",seq_len(n))),
    truth=list(metadata=meta,truth_grid=g,
      pre_missing_observation_times=rep(list(g),n),
      observation_times=rep(list(g),n),
      missingness_mask=list(c(FALSE,TRUE,FALSE,FALSE,FALSE),
        rep(FALSE,5L),c(TRUE,FALSE,FALSE,FALSE,FALSE),
        rep(FALSE,5L)),
      phase_warps_on_truth_grid=warp,eigenvalues=c(1,.35),
      scores=scores,curve_scores=scores/2,trial_scores=scores/4,
      participant_scores=matrix(c(.3,.1,.6,.2),nrow=2L),
      dimension_names="value",
      participant_eigenvalues=c(.2,.05),
      trial_eigenvalues=c(.1,.02),
      measurement_noise_covariance=matrix(.0025,1L),
      observation_design="dense",score_distribution="normal",
      score_distribution_parameters=list(),random_state=821L,
      provenance=list(missingness_kind="mcar",
        phase_variation_kind="power",
        raw_dense_to_irregular_interpolation_performed=FALSE)))
}

test_that("truth frame preserves counts, ordered scores and first-seen groups",{
  x<-.etr_test_simulation_truth_result()
  z<-etr_functional_simulation_truth_frame(x)
  expect_identical(names(z),c("curve_id","participant_id","trial_id",
    "n_pre_missing_samples","n_output_schedule_samples",
    "n_observed_samples","n_missing_by_design","max_phase_displacement",
    "score_total_1","score_curve_1","score_trial_1",
    "score_participant_1","score_total_2","score_curve_2",
    "score_trial_2","score_participant_2"))
  expect_equal(z$n_observed_samples,c(4L,5L,4L,5L))
  expect_equal(z$n_missing_by_design,c(1L,0L,1L,0L))
  expect_equal(z$max_phase_displacement,c(0,.13,0,0),tolerance=1e-14)
  expect_equal(z$score_participant_1,c(.3,.3,.1,.1))
  expect_equal(z$score_participant_2,c(.6,.6,.2,.2))
  expect_identical(z,etr_functional_simulation_truth_frame(x))
  bad<-x;bad$truth$missingness_mask[[1L]]<-logical(3L)
  expect_error(etr_functional_simulation_truth_frame(bad),"missingness masks")
  bad<-x;bad$truth$phase_warps_on_truth_grid<-matrix(0,2L,5L)
  expect_error(etr_functional_simulation_truth_frame(bad),"phase warps")
  expect_error(etr_functional_simulation_truth_frame(list()),"truth and observations")
})

test_that("simulation report states scientific design without overclaiming",{
  x<-.etr_test_simulation_truth_result()
  txt<-etr_functional_simulation_reporting_text(x)
  for(term in c("4 curves","1 dimension(s)","2 declared orthonormal",
    "mcar","power","Exact latent curves"))
    expect_true(grepl(term,txt,fixed=TRUE),info=term)
  expect_true(grepl("4–5 retained samples",txt,fixed=TRUE))
  expect_true(grepl("No dense-to-irregular raw-trajectory interpolation",
    txt,fixed=TRUE))
  expect_error(etr_functional_simulation_reporting_text(x,digits=-1),
    "digits")
  expect_error(etr_functional_simulation_reporting_text(x,digits=2.2),
    "digits")
})

test_that("realized truth/source report are explicit unresolved contracts",{
  catalog<-etr_native_parity_catalog()
  for(name in c("functional_simulation_truth_frame",
                "functional_simulation_reporting_text")){
    row<-catalog[catalog$is_python_function&
      catalog$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_true(row$named_native_candidate)
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(catalog$is_python_function&
    catalog$named_native_candidate),322L)
  expect_equal(sum(catalog$native_implementation_started),297L)
  expect_equal(sum(catalog$source_contract_gap_unresolved),144L)
})

test_that("direct Python 1.2 realized truth audit and reporting text agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 realized truth/reporting oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _gp_mean(t):
    return np.zeros_like(np.asarray(t,dtype=float))
def _gp_eig(t):
    return np.sqrt(2.0)*np.sin(np.pi*np.asarray(t,dtype=float))
_gp_sim=et.simulate_functional_process(
    mean=_gp_mean,eigenfunctions=(_gp_eig,),eigenvalues=(1.0,),
    truth_grid=np.linspace(0.0,1.0,41),n_participants=3,
    trials_per_participant=2,participant_eigenvalues=(0.2,),
    trial_eigenvalues=(0.1,),measurement_noise_sd=0.04,
    missingness={'kind':'mcar','probability':0.15},
    random_state=821)
_gp_frame=et.functional_simulation_truth_frame(_gp_sim)
_gp_text=et.functional_simulation_reporting_text(_gp_sim)
",local=FALSE,convert=FALSE)
  py<-reticulate::py
  src<-reticulate::py_get_attr(py,"_gp_sim")
  truth<-src$truth
  obs<-src$observations
  ids<-as.character(unlist(reticulate::py_to_r(obs$curve_ids)))
  n<-length(ids)
  # Convert the whole Python sequence first. Once reticulate exposes
  # an R list, [[ is one-based, NOT Python's zero-based indexing.
  as_source_list<-function(sequence){
    converted<-reticulate::py_to_r(sequence)
    expect_true(is.list(converted))
    expect_length(converted,n)
    unname(converted)
  }
  native<-list(observations=list(curve_ids=ids),
    truth=list(metadata=reticulate::py_to_r(truth$metadata),
      truth_grid=as.numeric(reticulate::py_to_r(truth$truth_grid)),
      pre_missing_observation_times=as_source_list(
        truth$pre_missing_observation_times),
      observation_times=as_source_list(truth$observation_times),
      missingness_mask=as_source_list(truth$missingness_mask),
      phase_warps_on_truth_grid=reticulate::py_to_r(
        truth$phase_warps_on_truth_grid),
      eigenvalues=as.numeric(reticulate::py_to_r(truth$eigenvalues)),
      scores=reticulate::py_to_r(truth$scores),
      curve_scores=reticulate::py_to_r(truth$curve_scores),
      trial_scores=reticulate::py_to_r(truth$trial_scores),
      participant_scores=reticulate::py_to_r(truth$participant_scores),
      dimension_names=as.character(unlist(
        reticulate::py_to_r(truth$dimension_names))),
      participant_eigenvalues=as.numeric(reticulate::py_to_r(
        truth$participant_eigenvalues)),
      trial_eigenvalues=as.numeric(reticulate::py_to_r(
        truth$trial_eigenvalues)),
      measurement_noise_covariance=reticulate::py_to_r(
        truth$measurement_noise_covariance),
      observation_design=as.character(reticulate::py_to_r(
        truth$observation_design)),
      score_distribution=as.character(reticulate::py_to_r(
        truth$score_distribution)),
      score_distribution_parameters=reticulate::py_to_r(
        truth$score_distribution_parameters),
      random_state=as.integer(reticulate::py_to_r(truth$random_state)),
      provenance=reticulate::py_to_r(truth$provenance)))
  py_frame<-reticulate::py_to_r(
    reticulate::py_get_attr(py,"_gp_frame"))
  native_frame<-etr_functional_simulation_truth_frame(native)
  expect_identical(names(native_frame),names(py_frame))
  expect_equal(nrow(native_frame),nrow(py_frame))
  for(col in names(py_frame)){
    if(is.numeric(py_frame[[col]]))
      expect_equal(as.numeric(native_frame[[col]]),
        as.numeric(py_frame[[col]]),tolerance=1e-10,info=col)
    else expect_equal(as.character(native_frame[[col]]),
      as.character(py_frame[[col]]),info=col)
  }
  expected<-reticulate::py_to_r(reticulate::py_get_attr(py,"_gp_text"))
  expect_identical(etr_functional_simulation_reporting_text(native),
    as.character(expected))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
