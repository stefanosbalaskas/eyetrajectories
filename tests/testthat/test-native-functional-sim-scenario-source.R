# Frozen source eyetrajectoriespy==1.2.0:
# simulate.py::simulate_functional_process / simulate_functional_scenario
# _functional_simulation.py::FunctionalSimulationTruth / Result.
# Pinned SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# Source-scientific R record analogue, not Python dataclass identity.

.etr_simulation_full_source_args<-function(){
  grid<-seq(0,1,length.out=9L)
  list(mean=function(t)cbind(.3+t,sin(pi*t)),
    eigenfunctions=list(
      function(t)cbind(rep(1,length(t)),rep(0,length(t))),
      function(t)cbind(rep(0,length(t)),rep(1,length(t)))),
    eigenvalues=c(1,.35),truth_grid=grid,
    n_participants=4L,trials_per_participant=2L,
    dimension_names=c("x","y"),coordinate_system="degrees",
    participant_eigenvalues=c(.22,.08),trial_eigenvalues=c(.17,.06),
    measurement_noise_sd=c(.02,.08),random_state=927L)
}

.etr_simulation_full_source_provenance<-c(
  "source","synthetic","private_0_11_simulation_core","random_state",
  "observation_design","irregular_time_design","measurement_noise_sd",
  "measurement_noise_covariance","participant_eigenvalues",
  "trial_eigenvalues","phase_variation_kind","phase_exponents",
  "missingness_kind","missingness_specification","n_components",
  "score_distribution","score_distribution_parameters","truth_grid",
  "raw_dense_to_irregular_interpolation_performed")

.etr_simulation_full_source_truth_fields<-c(
  "truth_grid","mean","eigenfunctions","eigenvalues","scores",
  "curve_scores","participant_scores","trial_scores",
  "participant_eigenvalues","trial_eigenvalues",
  "latent_on_truth_grid","phase_warps_on_truth_grid",
  "pre_missing_observation_times",
  "warped_pre_missing_observation_times",
  "observation_times","warped_observation_times",
  "latent_at_pre_missing_times","latent_at_observation_times",
  "measurement_noise","measurement_noise_covariance",
  "observed_pre_missing","missingness_mask","metadata",
  "dimension_names","coordinate_system","time_unit",
  "observation_design","score_distribution",
  "score_distribution_parameters","random_state","provenance")

test_that("process source mode retains all 31 truth fields and exact provenance",{
  args<-.etr_simulation_full_source_args()
  cases<-list(
    dense=list(),
    dense_phase_mcar=list(phase_variation=list(kind="power",sd=.13),
      missingness=list(kind="mcar",probability=.17)),
    dense_student_cov=list(score_distribution="student_t",score_df=5.5,
      measurement_noise_sd=0,
      measurement_noise_covariance=matrix(c(.04,.012,.012,.09),2)),
    irregular_explicit=list(observation_design="irregular",
      observation_times=replicate(8L,
        c(1e-10,.1,.32,.6,1-1e-6),simplify=FALSE)),
    irregular_generated=list(observation_design="irregular",
      samples_per_curve=c(4L,7L),
      irregular_time_design="boundary_poor",
      missingness=list(kind="block",fraction=.17))
  )
  for(case_name in names(cases)){
    current<-args;current[names(cases[[case_name]])]<-cases[[case_name]]
    fit<-do.call(etr_simulate_functional_process,c(current,
      list(random_engine="numpy",python_boundary_mode=TRUE)))
    expect_s3_class(fit,"etr_functional_simulation_result")
    expect_identical(names(fit),c("observations","truth"))
    expect_identical(names(fit$truth),.etr_simulation_full_source_truth_fields)
    expect_identical(names(fit$truth$provenance),
      .etr_simulation_full_source_provenance)
    expect_identical(fit$observations$provenance,fit$truth$provenance)
    expect_identical(fit$truth$provenance$source,
      "simulate_functional_process_core")
    expect_true(fit$truth$provenance$synthetic)
    expect_true(fit$truth$provenance$private_0_11_simulation_core)
    expect_false(fit$truth$provenance$
      raw_dense_to_irregular_interpolation_performed)
    expect_identical(length(fit$truth$provenance$phase_exponents),8L)
    expect_identical(length(fit$truth$pre_missing_observation_times),8L)
    expect_identical(length(fit$truth$missingness_mask),8L)
    expect_identical(fit$truth$provenance$score_distribution_parameters,
      fit$truth$score_distribution_parameters)
    if(case_name=="irregular_explicit")
      expect_null(fit$truth$provenance$irregular_time_design)
    if(case_name=="irregular_generated")
      expect_identical(fit$truth$provenance$irregular_time_design,
        "boundary_poor")
    if(startsWith(case_name,"dense"))
      expect_null(fit$truth$provenance$irregular_time_design)
    again<-do.call(etr_simulate_functional_process,c(current,
      list(random_engine="numpy",python_boundary_mode=TRUE)))
    expect_identical(fit,again)
  }
})

test_that("source process and scenario fail closed on R-only replay boundaries",{
  args<-.etr_simulation_full_source_args()
  expect_error(do.call(etr_simulate_functional_process,c(args,
    list(python_boundary_mode=TRUE))),"requires random_engine")
  expect_error(do.call(etr_simulate_functional_process,c(args,
    list(python_boundary_mode=1))),"python_boundary_mode")
  expect_error(do.call(etr_simulate_functional_process,c(args,
    list(random_engine="numpy",python_boundary_mode=TRUE,
      source_draws=list()))),"source_draws")
  legacy<-do.call(etr_simulate_functional_process,args)
  expect_identical(legacy$truth$provenance$native_random_engine,
    "base_R_not_NumPy_PCG64")
  design<-args[setdiff(names(args),c("mean","eigenfunctions","random_state"))]
  scenario<-do.call(etr_functional_simulation_scenario,
    c(list(name="full_source",replicates=2L,seed_start=121L),design))
  expect_error(etr_simulate_functional_scenario(scenario,
    args$mean,args$eigenfunctions,python_boundary_mode=TRUE),
    "requires random_engine")
  expect_error(etr_simulate_functional_scenario(scenario,
    args$mean,args$eigenfunctions,python_boundary_mode=TRUE,
    random_engine="numpy",source_draws=list()),"does not expose")
  expect_error(etr_simulate_functional_scenario(scenario,
    args$mean,args$eigenfunctions,python_boundary_mode=TRUE,
    random_engine="numpy",observation_times=list()),"does not expose")
  source<-etr_simulate_functional_scenario(scenario,
    args$mean,args$eigenfunctions,replicate=1L,
    random_engine="numpy",python_boundary_mode=TRUE)
  expect_identical(names(source$truth$provenance),
    c(.etr_simulation_full_source_provenance,
      "scenario_name","scenario_replicate","scenario_seed",
      "scenario_labels"))
  expect_identical(source$truth$provenance$scenario_name,
    "full_source")
  expect_identical(source$truth$provenance$scenario_replicate,1L)
  expect_identical(source$truth$provenance$scenario_seed,122L)
  expect_null(source$observations$provenance$scenario_name)
  expect_identical(names(source$observations$provenance),
    .etr_simulation_full_source_provenance)
})

test_that("frozen Python 1.2 process and scenario match full realized truth",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 complete functional simulation source oracle")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_src_mean=lambda t:np.column_stack((.3+t,np.sin(np.pi*t)))
_src_mode1=lambda t:np.column_stack((np.ones_like(t),np.zeros_like(t)))
_src_mode2=lambda t:np.column_stack((np.zeros_like(t),np.ones_like(t)))
_src_modes=(_src_mode1,_src_mode2)
")
  mean_py<-reticulate::py_eval("_src_mean",convert=FALSE)
  modes_py<-reticulate::tuple(
    reticulate::py_eval("_src_mode1",convert=FALSE),
    reticulate::py_eval("_src_mode2",convert=FALSE))
  args<-.etr_simulation_full_source_args()
  variants<-list(dense=list(),
    mcar_phase=list(phase_variation=list(kind="power",sd=.13),
      missingness=list(kind="mcar",probability=.17)),
    student_noise=list(score_distribution="student_t",score_df=5.5,
      measurement_noise_sd=0,
      measurement_noise_covariance=matrix(c(.04,.012,.012,.09),2)),
    irregular_explicit=list(observation_design="irregular",
      observation_times=replicate(8L,
        c(1e-10,.1,.32,.6,1-1e-6),simplify=FALSE)),
    irregular_generated=list(observation_design="irregular",
      samples_per_curve=c(4L,7L),irregular_time_design="boundary_poor"))
  compare_results<-function(native,py,info){
    for(field in c("mean","eigenfunctions","scores","curve_scores",
      "participant_scores","trial_scores","latent_on_truth_grid",
      "phase_warps_on_truth_grid","measurement_noise_covariance")){
      expected<-et_to_r(reticulate::py_get_attr(py$truth,field))
      expect_equal(native$truth[[field]],expected,
        tolerance=1e-11,ignore_attr=TRUE,
        info=paste(info,field))
    }
    for(field in c("measurement_noise",
      "latent_at_pre_missing_times","latent_at_observation_times",
      "observed_pre_missing","pre_missing_observation_times",
      "warped_pre_missing_observation_times","observation_times",
      "warped_observation_times","missingness_mask")){
      expected<-et_to_r(reticulate::py_get_attr(py$truth,field))
      expect_length(native$truth[[field]],length(expected))
      for(j in seq_along(expected)){
        a<-native$truth[[field]][[j]];b<-expected[[j]]
        if(is.numeric(a)&&is.numeric(b))
          expect_equal(a,b,tolerance=1e-11,ignore_attr=TRUE,
            info=paste(info,field,j)) else
          expect_identical(a,b,info=paste(info,field,j))
      }
    }
    source_prov<-et_to_r(reticulate::py_get_attr(py$truth,"provenance"))
    native_prov<-native$truth$provenance
    expect_identical(names(native_prov),names(source_prov))
    for(field in names(native_prov)){
      a<-native_prov[[field]];b<-source_prov[[field]]
      if(is.list(a)&&is.list(b))
        expect_equal(unlist(a),unlist(b),tolerance=1e-11,
          ignore_attr=TRUE,info=paste(info,"provenance",field))
      else expect_equal(a,b,tolerance=1e-11,
        ignore_attr=TRUE,info=paste(info,"provenance",field))
    }
    expected_values<-et_to_r(reticulate::py_get_attr(
      py$observations,"values"))
    if(is.list(expected_values)){
      for(j in seq_along(expected_values))
        expect_equal(native$observations$values[[j]],
          expected_values[[j]],tolerance=1e-11,ignore_attr=TRUE)
    }else
      expect_equal(native$observations$values,expected_values,
        tolerance=1e-11,ignore_attr=TRUE)
  }
  for(label in names(variants)){
    a<-args;a[names(variants[[label]])]<-variants[[label]]
    native<-do.call(etr_simulate_functional_process,
      c(a,list(random_engine="numpy",python_boundary_mode=TRUE)))
    b<-a;b$mean<-mean_py;b$eigenfunctions<-modes_py
    if(identical(length(b$samples_per_curve),2L))
      b$samples_per_curve<-do.call(reticulate::tuple,
        as.list(as.integer(b$samples_per_curve)))
    py<-do.call(reticulate::py_call,
      c(list(etpy_get_export("simulate_functional_process")),b))
    compare_results(native,py,label)
  }
  design<-args[setdiff(names(args),c("mean","eigenfunctions","random_state"))]
  declared<-c(list(name="source_scenario",replicates=2L,
    seed_start=121L,labels=list(study="phase_validation")),design)
  scenario<-do.call(etr_functional_simulation_scenario,declared)
  py_scenario<-do.call(reticulate::py_call,
    c(list(etpy_get_export("FunctionalSimulationScenario")),declared))
  native<-etr_simulate_functional_scenario(
    scenario,args$mean,args$eigenfunctions,replicate=1L,
    random_engine="numpy",python_boundary_mode=TRUE)
  py<-reticulate::py_call(
    etpy_get_export("simulate_functional_scenario"),
    scenario=py_scenario,mean=mean_py,
    eigenfunctions=modes_py,replicate=1L)
  compare_results(native,py,"scenario")
  expect_identical(native$truth$provenance$scenario_replicate,1L)
  expect_identical(native$truth$provenance$scenario_seed,122L)
  expect_identical(native$truth$provenance$scenario_labels,
    list(study="phase_validation"))
})
