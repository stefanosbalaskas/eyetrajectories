# Native simulation audit geometry versus frozen published Python 1.2.
.etr_sim_plot_fixture <- function(){
  n<-3L;g<-seq(0,1,length.out=5L)
  score<-matrix(seq_len(n*2L)/10,nrow=n)
  w<-matrix(rep(g,each=n),nrow=n)
  w[2L,3L]<-.65
  missing<-list(rep(FALSE,5),c(FALSE,TRUE,FALSE,FALSE,FALSE),
    rep(FALSE,5))
  v<-array(0,dim=c(n,5L,1L))
  latent<-array(0,dim=c(n,5L,1L))
  pre<-vector("list",n)
  for(i in seq_len(n)){
    v[i,,1L]<-sin(pi*g)+i/4
    pre[[i]]<-matrix(v[i,,1L],ncol=1L)
    latent[i,,1L]<-sin(pi*g)+i/5
  }
  v[2L,2L,1L]<-NA_real_
  list(observations=list(curve_ids=c("a","b","c"),values=v),
    truth=list(metadata=data.frame(
        participant_id=c("p1","p1","p2"),trial_id=c("1","2","1")),
      truth_grid=g,
      pre_missing_observation_times=rep(list(g),n),
      observation_times=rep(list(g),n),
      missingness_mask=missing,phase_warps_on_truth_grid=w,
      eigenvalues=c(1,.35),scores=score,curve_scores=score/2,
      trial_scores=score/4,
      participant_scores=matrix(c(.3,.4,.1,.2),nrow=2L),
      participant_eigenvalues=c(.3,.1),
      trial_eigenvalues=c(.2,.05),
      latent_on_truth_grid=latent,dimension_names="value",
      time_unit="s",observed_pre_missing=pre))
}

test_that("three native simulation figures retain all exact source geometry",{
  x<-.etr_sim_plot_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  one<-etr_plot_functional_simulation_curve(
    x,curve="b",dimension="value",show_pre_missing=TRUE)
  expect_identical(one$curve_id,"b")
  expect_identical(one$dimension,"value")
  expect_equal(one$latent$value,
    as.numeric(x$truth$latent_on_truth_grid[2L,,1L]))
  expect_equal(one$observed$time,c(0,.5,.75,1))
  expect_equal(nrow(one$removed),1L)
  expect_equal(one$removed$time,.25)
  expect_false(one$provenance$python_axes_return_equivalence)
  phase<-etr_plot_functional_simulation_phase_warps(
    x,max_curves=2L,alpha=.5)
  expect_identical(phase$n_plotted,2L)
  expect_identical(phase$warps,
    x$truth$phase_warps_on_truth_grid[1:2,,drop=FALSE])
  expect_identical(phase$identity,x$truth$truth_grid)
  expect_error(etr_plot_functional_simulation_phase_warps(x,max_curves=0),
    "max_curves")
  expect_error(etr_plot_functional_simulation_phase_warps(x,alpha=0),
    "alpha")
  score<-etr_plot_functional_simulation_score_variances(x)
  expect_identical(dim(score$declared),c(2L,3L))
  expect_identical(dim(score$realized),c(2L,3L))
  expect_equal(nrow(score$geometry),12L)
  expect_identical(score$provenance$variance_ddof,0L)
  expect_equal(score$realized[,1L],
    colMeans((sweep(x$truth$curve_scores,2L,
      colMeans(x$truth$curve_scores),"-"))^2))
  expect_equal(score$geometry$center[1:2],c(-.45,.55))
  expect_equal(score$geometry$center[3:4],c(.09,1.09))
  expect_error(etr_plot_functional_simulation_curve(x,curve=0L),
    "curve")
  expect_error(etr_plot_functional_simulation_curve(x,dimension="missing"),
    "dimension")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("three plot mappings remain uncertified with explicit backend gaps",{
  a<-etr_native_parity_catalog()
  for(name in c("plot_functional_simulation_curve",
    "plot_functional_simulation_phase_warps",
    "plot_functional_simulation_score_variances")){
    row<-a[a$is_python_function&a$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",name))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(a$is_python_function&a$named_native_candidate),285L)
  expect_equal(sum(a$native_implementation_started),260L)
  expect_equal(sum(a$source_contract_gap_unresolved),107L)
})

test_that("Python 1.2 phase plot line points and population variance bars agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 Matplotlib simulation plots oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
def _et_mean(t):
    return np.zeros_like(np.asarray(t,dtype=float))
def _et_phi(t):
    return np.sqrt(2.0)*np.sin(np.pi*np.asarray(t,dtype=float))
_et_sim=et.simulate_functional_process(
    mean=_et_mean,eigenfunctions=(_et_phi,),eigenvalues=(1.0,),
    truth_grid=np.linspace(0,1,41),n_participants=3,
    trials_per_participant=2,participant_eigenvalues=(0.2,),
    trial_eigenvalues=(0.1,),measurement_noise_sd=0.04,
    random_state=821)
_et_phase=et.plot_functional_simulation_phase_warps(_et_sim,max_curves=4)
_et_phase_lines=[(np.asarray(z.get_xdata()),np.asarray(z.get_ydata()))
                for z in _et_phase.lines]
_et_var=et.plot_functional_simulation_score_variances(_et_sim)
_et_bars=[(r.get_x()+r.get_width()/2,r.get_height())
          for r in _et_var.patches]
plt.close(_et_phase.figure)
plt.close(_et_var.figure)
",convert=FALSE)
  py<-reticulate::py
  sim<-reticulate::py_get_attr(py,"_et_sim")
  truth<-sim$truth
  obs<-sim$observations
  tolist<-function(x)reticulate::py_to_r(x)
  native<-list(observations=list(curve_ids=as.character(
    unlist(tolist(obs$curve_ids)))),
    truth=list(metadata=tolist(truth$metadata),
      truth_grid=as.numeric(tolist(truth$truth_grid)),
      pre_missing_observation_times=tolist(truth$pre_missing_observation_times),
      observation_times=tolist(truth$observation_times),
      missingness_mask=tolist(truth$missingness_mask),
      phase_warps_on_truth_grid=tolist(truth$phase_warps_on_truth_grid),
      eigenvalues=as.numeric(tolist(truth$eigenvalues)),
      scores=tolist(truth$scores),curve_scores=tolist(truth$curve_scores),
      trial_scores=tolist(truth$trial_scores),
      participant_scores=tolist(truth$participant_scores),
      participant_eigenvalues=as.numeric(tolist(
        truth$participant_eigenvalues)),
      trial_eigenvalues=as.numeric(tolist(truth$trial_eigenvalues)),
      time_unit=as.character(tolist(truth$time_unit))))
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  phase<-etr_plot_functional_simulation_phase_warps(native,max_curves=4L)
  python_lines<-tolist(reticulate::py_get_attr(py,"_et_phase_lines"))
  expect_length(python_lines,5L)
  expect_equal(as.numeric(python_lines[[1L]][[1L]]),
    phase$time,tolerance=1e-12)
  expect_equal(as.numeric(python_lines[[1L]][[2L]]),
    phase$identity,tolerance=1e-12)
  for(i in seq_len(4L)){
    expect_equal(as.numeric(python_lines[[i+1L]][[1L]]),
      phase$time,tolerance=1e-12)
    expect_equal(as.numeric(python_lines[[i+1L]][[2L]]),
      as.numeric(phase$warps[i,]),tolerance=1e-12)
  }
  var<-etr_plot_functional_simulation_score_variances(native)
  pybars<-tolist(reticulate::py_get_attr(py,"_et_bars"))
  expect_equal(length(pybars),nrow(var$geometry))
  for(i in seq_along(pybars)){
    expect_equal(as.numeric(pybars[[i]][[1L]]),
      var$geometry$center[i],tolerance=1e-12)
    expect_equal(as.numeric(pybars[[i]][[2L]]),
      var$geometry$variance[i],tolerance=1e-12)
  }
})
