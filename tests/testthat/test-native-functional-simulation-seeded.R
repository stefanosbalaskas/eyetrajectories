.etr_seeded_simulation_args <- function() {
  list(mean=function(t)cbind(.3+t,sin(pi*t)),
    eigenfunctions=list(function(t)cbind(rep(1,length(t)),rep(0,length(t))),
      function(t)cbind(rep(0,length(t)),rep(1,length(t)))),
    eigenvalues=c(1,.35),truth_grid=seq(0,1,length.out=9L),
    n_participants=4L,trials_per_participant=2L,dimension_names=c("x","y"),
    coordinate_system="degrees",participant_eigenvalues=c(.22,.08),
    trial_eigenvalues=c(.17,.06),measurement_noise_sd=c(.02,.08),
    random_state=927L)
}

.etr_seeded_simulation_source_bases <- function() {
  reticulate::py_run_string("import numpy as np\n",
    local=FALSE,convert=FALSE)
  list(mean=reticulate::py_eval(
    "lambda t: np.column_stack((.3+t,np.sin(np.pi*t)))",convert=FALSE),
    eigenfunctions=reticulate::py_eval(paste0("(",
      "lambda t: np.column_stack((np.ones_like(t),np.zeros_like(t))),",
      "lambda t: np.column_stack((np.zeros_like(t),np.ones_like(t))))"),
      convert=FALSE))
}

.etr_seeded_simulation_python <- function(args,bases) {
  args[names(bases)]<-bases
  if(length(args$samples_per_curve)==2L)
    args$samples_per_curve<-do.call(reticulate::tuple,
      as.list(as.integer(args$samples_per_curve)))
  builtins<-reticulate::import_builtins(convert=FALSE)
  args$random_state<-builtins$int(format(args$random_state,
    scientific=FALSE,trim=TRUE))
  do.call(reticulate::py_call,c(list(etpy_get_export("simulate_functional_process")),args))
}

.etr_expect_seeded_simulation <- function(native,source,label) {
  expected<-function(name)et_to_r(reticulate::py_get_attr(source$truth,name))
  numeric_equal<-function(x,y,field) {
    expect_identical(dim(x),dim(y),info=paste(label,field,"shape"))
    expect_identical(as.vector(is.na(x)),as.vector(is.na(y)),
      info=paste(label,field,"missing"))
    expect_equal(as.numeric(x[!is.na(x)]),as.numeric(y[!is.na(y)]),
      tolerance=1e-12,info=paste(label,field,"values"))
  }
  for(field in c("mean","eigenfunctions","scores","curve_scores",
    "participant_scores","trial_scores","latent_on_truth_grid",
    "phase_warps_on_truth_grid","measurement_noise_covariance"))
    numeric_equal(native$truth[[field]],expected(field),field)
  for(field in c("measurement_noise","latent_at_pre_missing_times",
    "latent_at_observation_times","observed_pre_missing")){
    source_curves<-expected(field)
    expect_length(source_curves,length(native$truth[[field]]))
    for(i in seq_along(source_curves))
      numeric_equal(native$truth[[field]][[i]],source_curves[[i]],paste(field,i))
  }
  for(field in c("pre_missing_observation_times","observation_times",
    "warped_pre_missing_observation_times","warped_observation_times"))
    expect_equal(native$truth[[field]],lapply(expected(field),as.numeric),
      tolerance=1e-12,info=paste(label,field))
  expect_identical(native$truth$missingness_mask,
    lapply(expected("missingness_mask"),as.logical),info=label)
  expect_identical(native$observations$curve_ids,
    as.character(unlist(et_to_r(source$observations$curve_ids))),info=label)
  values<-et_to_r(source$observations$values)
  if(is.list(values)){
    expect_length(native$observations$values,length(values))
    for(i in seq_along(values))
      numeric_equal(native$observations$values[[i]],values[[i]],paste("observations",i))
  }else numeric_equal(native$observations$values,values,"observations")
  frame<-etr_functional_simulation_truth_frame(native)
  source_frame<-et_to_r(reticulate::py_call(
    etpy_get_export("functional_simulation_truth_frame"),source))
  expect_identical(names(frame),names(source_frame),info=label)
  for(field in names(frame))
    expect_equal(frame[[field]],source_frame[[field]],tolerance=1e-12,
      info=paste(label,"truth frame",field))
  expect_identical(native$truth$provenance$native_random_engine,"numpy_pcg64")
}

test_that("seeded simulation keeps native defaults and isolates PCG64",{
  args<-.etr_seeded_simulation_args()
  set.seed(872L)
  before<-.Random.seed
  legacy<-do.call(etr_simulate_functional_process,args)
  native<-do.call(etr_simulate_functional_process,c(args,list(random_engine="base_R")))
  expect_identical(legacy,native)
  numpy<-do.call(etr_simulate_functional_process,c(args,list(random_engine="numpy")))
  expect_identical(.Random.seed,before)
  expect_identical(numpy,do.call(etr_simulate_functional_process,
    c(args,list(random_engine="numpy"))))
  expect_identical(numpy$observations$provenance$native_random_engine,"numpy_pcg64")
  expect_false(identical(numpy$truth$curve_scores,native$truth$curve_scores))
  expect_error(do.call(etr_simulate_functional_process,
    c(args,list(random_engine="numpy",source_draws=list()))),"source_draws")
  args$random_state<-2^53
  expect_error(do.call(etr_simulate_functional_process,
    c(args,list(random_engine="numpy"))),"exactly represented integer")
})

test_that("NumPy seeded processes reproduce frozen schedules, noise and realized truth",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 seeded simulation oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  base<-.etr_seeded_simulation_args()
  cases<-list(dense_gaussian=list(random_state=0L,
      phase_variation=list(kind="power",sd=.2),
      missingness=list(kind="mcar",probability=.27)),
    dense_student_covariance=list(score_distribution="student_t",score_df=5.5,
      measurement_noise_sd=0,measurement_noise_covariance=matrix(c(.04,.012,.012,.09),2),
      missingness=list(kind="block",fraction=.23)),
    dense_skips_tiny_noise=list(random_state=2^32+9,
      measurement_noise_sd=c(1e-5,5e-5),participant_eigenvalues=c(0,0),
      trial_eigenvalues=c(0,0),phase_variation=list(kind="power",sd=0),
      missingness=list(kind="mcar",probability=.19)),
    irregular_explicit=list(observation_design="irregular",
      observation_times=replicate(8L,c(1e-10,.1,.32,.6,1-1e-6),simplify=FALSE)))
  for(design in c("uniform","boundary_poor","center_clustered"))
    cases[[design]]<-list(observation_design="irregular",
      samples_per_curve=c(4L,8L),irregular_time_design=design,
      score_distribution="student_t",score_df=2.25,random_state=2^53-1,
      phase_variation=list(kind="power",sd=.13),
      missingness=list(kind="block",fraction=.21))
  bases<-.etr_seeded_simulation_source_bases()
  for(label in names(cases)){
    args<-base
    args[names(cases[[label]])]<-cases[[label]]
    native<-do.call(etr_simulate_functional_process,c(args,list(random_engine="numpy")))
    source<-.etr_seeded_simulation_python(args,bases)
    .etr_expect_seeded_simulation(native,source,label)
  }
})

test_that("NumPy engine propagates through scenarios and recovery callbacks",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 seeded scenario oracle opt-in")
  args<-.etr_seeded_simulation_args()
  design<-args[setdiff(names(args),c("mean","eigenfunctions","random_state"))]
  design<-c(list(name="seeded_recovery",replicates=2L,seed_start=123L),design)
  scenario<-do.call(etr_functional_simulation_scenario,design)
  source_scenario<-do.call(reticulate::py_call,c(list(
    etpy_get_export("FunctionalSimulationScenario")),design))
  bases<-.etr_seeded_simulation_source_bases()
  native<-etr_simulate_functional_scenario(scenario,args$mean,args$eigenfunctions,
    replicate=1L,random_engine="numpy")
  source<-do.call(reticulate::py_call,c(list(etpy_get_export("simulate_functional_scenario"),
    scenario=source_scenario,replicate=1L),bases))
  .etr_expect_seeded_simulation(native,source,"scenario replicate 1")
  expect_equal(native$truth$provenance$scenario_seed,124)
  recovery<-etr_run_functional_recovery_scenarios(list(scenario),
    args$mean,args$eigenfunctions,estimator=function(observations,scenario)
      observations$values[1L,1L,1L],
    recovery=function(fit,truth,scenario)c(error=fit-truth$latent_on_truth_grid[1L,1L,1L]),
    random_engine="numpy")
  source_recovery<-do.call(reticulate::py_call,c(list(
    etpy_get_export("run_functional_recovery_scenarios"),
    scenarios=reticulate::tuple(source_scenario),
    estimator=reticulate::py_eval("lambda obs, s: obs.values[0, 0, 0]",convert=FALSE),
    recovery=reticulate::py_eval(paste0("lambda fit, truth, s: ",
      "{'error': float(fit - truth.latent_on_truth_grid[0, 0, 0])}"),convert=FALSE)),bases))
  source_records<-source_recovery$records
  for(i in seq_along(recovery$records)){
    record<-reticulate::py_get_item(source_records,i-1L)
    expect_equal(recovery$records[[i]]$seed,et_to_r(record$seed))
    expect_equal(unname(recovery$records[[i]]$metrics),
      as.numeric(et_to_r(record$metrics)[["error"]]),tolerance=1e-12)
  }
  expect_identical(recovery$provenance$native_random_engine,"numpy_pcg64")
})
