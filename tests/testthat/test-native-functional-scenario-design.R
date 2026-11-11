# Published source: eyetrajectoriespy==1.2.0, src/eyetrajectoriespy/simulate.py,
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R source contract is intentionally RESTRICTED; zero full certification.
.etr_scenario_design_test_fixture <- function(...) {
  args<-list(name="basic",truth_grid=c(0,.5,1),
    eigenvalues=c(2,1),n_participants=3L,
    trials_per_participant=2L,replicates=2L,seed_start=31L)
  replace<-list(...)
  for(nm in names(replace)) args[[nm]]<-replace[[nm]]
  do.call(etr_functional_simulation_scenario,args)
}

test_that("native scenario design preserves ordered source columns and explicit truth",{
  skip_if_not_installed("jsonlite")
  basic<-.etr_scenario_design_test_fixture()
  expect_s3_class(basic,"etr_functional_simulation_scenario")
  tab<-etr_functional_simulation_scenario_frame(list(basic))
  expect_identical(names(tab),c("scenario","n_participants",
    "trials_per_participant","n_curves","n_time_truth","n_components",
    "eigenvalues","observation_design","samples_per_curve_min",
    "samples_per_curve_max","irregular_time_design",
    "participant_eigenvalues","trial_eigenvalues","measurement_noise_sd",
    "measurement_noise_covariance","coordinate_system","time_unit",
    "missingness","phase_variation","score_distribution","replicates",
    "seed_start","labels"))
  expect_equal(nrow(tab),1L)
  expect_identical(tab$scenario,"basic")
  expect_equal(tab$n_curves,6L)
  expect_equal(tab$n_time_truth,3L)
  expect_equal(tab$samples_per_curve_min,3L)
  expect_equal(tab$samples_per_curve_max,3L)
  expect_equal(jsonlite::fromJSON(tab$eigenvalues),c(2,1))
  expect_identical(tab$labels,"{}")
  expect_identical(tab$participant_eigenvalues,"null")
  expect_identical(tab$trial_eigenvalues,"null")
  expect_true(is.na(tab$measurement_noise_covariance))
  expect_true(is.na(tab$missingness))
  expect_true(is.na(tab$phase_variation))
  expect_identical(tab$measurement_noise_sd,"0.0")
  expect_true(is.na(tab$measurement_noise_covariance))
  irr<-.etr_scenario_design_test_fixture(name="sparse",
    observation_design="irregular",samples_per_curve=c(2L,4L))
  frame<-etr_functional_simulation_scenario_frame(list(basic,irr))
  expect_equal(frame$samples_per_curve_min,c(3L,2L))
  expect_equal(frame$samples_per_curve_max,c(3L,4L))
  expect_equal(nrow(etr_functional_simulation_scenario_frame(list())),0L)
})

test_that("explicit scenario design rejects unsupported scientific assumptions",{
  expect_error(.etr_scenario_design_test_fixture(truth_grid=c(0,1)),
    "truth_grid")
  expect_error(.etr_scenario_design_test_fixture(eigenvalues=c(1,2)),
    "eigenvalues")
  expect_error(.etr_scenario_design_test_fixture(n_participants=0),
    "n_participants")
  expect_error(.etr_scenario_design_test_fixture(
    observation_design="irregular"),"samples_per_curve")
  expect_error(.etr_scenario_design_test_fixture(samples_per_curve=5L),
    "samples_per_curve")
  expect_error(.etr_scenario_design_test_fixture(
    dimension_names=c("x","y"),
    measurement_noise_covariance=diag(1,1)),"must match")
  covar<-matrix(c(.04,.018,.018,.09),2L,2L)
  valid<-etr_functional_simulation_scenario(
    name="two_channel",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.35),n_participants=12L,
    dimension_names=c("x","y"),measurement_noise_sd=NULL,
    measurement_noise_covariance=covar)
  expect_equal(valid$measurement_noise_covariance,covar,tolerance=0)
  expect_equal(jsonlite::fromJSON(
    etr_functional_simulation_scenario_frame(
      list(valid))$measurement_noise_covariance),
    covar,tolerance=0)
  expect_error(etr_functional_simulation_scenario(
    name="bad_covariance",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.35),n_participants=12L,
    dimension_names=c("x","y"),
    measurement_noise_covariance=matrix(c(1,2,0,1),2L)),
    "symmetric")
  expect_error(etr_functional_simulation_scenario(
    name="bad_psd",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.35),n_participants=12L,
    dimension_names=c("x","y"),
    measurement_noise_covariance=matrix(c(1,2,2,1),2L)),
    "positive semidefinite")
  expect_error(etr_functional_simulation_scenario(
    name="confounded_noise",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.35),n_participants=12L,
    dimension_names=c("x","y"),measurement_noise_sd=.2,
    measurement_noise_covariance=covar),
    "cannot both specify")
  expect_error(.etr_scenario_design_test_fixture(score_distribution="student_t",
    score_df=2),"score_df")
  expect_error(.etr_scenario_design_test_fixture(
    participant_eigenvalues=1),"participant_eigenvalues")
  expect_error(etr_functional_simulation_scenario_frame(list(list())),
    "native functional simulation scenario")
})

test_that("simulation scenario expansion keeps factor order and explicit seed policy",{
  basic<-.etr_scenario_design_test_fixture()
  shared<-etr_expand_functional_simulation_scenarios(basic,
    list(n_participants=c(3L,5L)),seed_policy="shared")
  disjoint<-etr_expand_functional_simulation_scenarios(basic,
    list(n_participants=c(3L,5L)),seed_policy="disjoint")
  expect_identical(vapply(shared,function(x)x$name,character(1L)),
    c("basic__n_participants=3","basic__n_participants=5"))
  expect_identical(vapply(shared,function(x)x$seed_start,integer(1L)),
    c(31L,31L))
  expect_identical(vapply(disjoint,function(x)x$seed_start,integer(1L)),
    c(31L,33L))
  expect_identical(vapply(disjoint,function(x)x$n_participants,integer(1L)),
    c(3L,5L))
  expect_error(etr_expand_functional_simulation_scenarios(basic,
    list(seed_start=c(1L,2L))),"unsupported")
  expect_error(etr_expand_functional_simulation_scenarios(basic,list()),
    "nonempty")
  expect_error(etr_expand_functional_simulation_scenarios(basic,
    list(n_participants=numeric())),"at least one level")
})

test_that("new simulation scenario contracts remain unapproved without independent review",{
  z<-etr_native_parity_catalog()
  names<-c("functional_simulation_scenario_frame",
    "expand_functional_simulation_scenarios")
  for(name in names){
    row<-z[z$is_python_function & z$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",name))
    expect_true(row$native_implementation_started)
    ledger<-utils::read.csv(system.file("extdata",
      "native_source_contract_gaps_stage22.csv",package="eyetrajectories"),
      stringsAsFactors=FALSE)
    status<-ledger[ledger$python_name==name,,drop=FALSE]
    expect_identical(as.logical(row$source_contract_gap_unresolved),
      as.logical(status$unresolved_source_gap))
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_gte(sum(z$is_python_function & z$named_native_candidate),380L)
  expect_gte(sum(z$native_implementation_started),380L)
  expect_lte(sum(z$source_contract_gap_unresolved),203L)
})

test_that("published Python 1.2 scenario design and seed expansion source witnesses",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 frozen functional scenario dataclass oracle is opt-in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  py_case<-reticulate::py_call(etpy_get_export("FunctionalSimulationScenario"),
    name="basic",truth_grid=reticulate::r_to_py(list(0,.5,1)),
    eigenvalues=reticulate::r_to_py(list(2,1)),
    n_participants=as.integer(3L),
    trials_per_participant=as.integer(2L),
    replicates=as.integer(2L),seed_start=as.integer(31L))
  py_frame<-reticulate::py_to_r(reticulate::py_call(
    etpy_get_export("functional_simulation_scenario_frame"),
    scenarios=reticulate::r_to_py(list(py_case))))
  r_frame<-etr_functional_simulation_scenario_frame(
    list(.etr_scenario_design_test_fixture()))
  expect_identical(names(py_frame),names(r_frame))
  for(k in c("scenario","n_participants","trials_per_participant",
    "n_curves","n_time_truth","n_components","observation_design",
    "samples_per_curve_min","samples_per_curve_max",
    "score_distribution","replicates","seed_start"))
    expect_equal(unname(py_frame[[k]]),unname(r_frame[[k]]),info=k)
  expect_equal(jsonlite::fromJSON(py_frame$eigenvalues[[1L]]),
    jsonlite::fromJSON(r_frame$eigenvalues[[1L]]),tolerance=0)
  py_scenarios<-reticulate::py_call(
    etpy_get_export("expand_functional_simulation_scenarios"),
    base=py_case,
    factors=reticulate::dict(n_participants=reticulate::r_to_py(
      list(as.integer(3L),as.integer(5L)))),
    seed_policy="disjoint")
  r_scenarios<-etr_expand_functional_simulation_scenarios(
    .etr_scenario_design_test_fixture(),
    list(n_participants=c(3L,5L)),seed_policy="disjoint")
  expect_identical(length(py_scenarios),length(r_scenarios))
  for(i in seq_along(r_scenarios)){
    src<-py_scenarios[[i-1L]]
    expect_identical(as.character(reticulate::py_to_r(src$name)),
      r_scenarios[[i]]$name)
    expect_equal(reticulate::py_to_r(src$seed_start),
      r_scenarios[[i]]$seed_start)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


# Batch 19: frozen source factors include full dataclass domains, not only
# native scalar-only subsets.  An expanded design is validated independently.
test_that("source simulation factor matrix handles composite scientific designs",{
  base<-etr_functional_simulation_scenario("irregular",seq(0,1,length.out=9L),
    c(2,1),3L,observation_design="irregular",samples_per_curve=c(3L,5L),
    replicates=2L,seed_start=31L,measurement_noise_sd=0)
  factors<-list(samples_per_curve=list(c(3L,5L),c(5L,7L)),
    irregular_time_design=c("uniform","center_clustered"),
    score_distribution=c("normal","student_t"))
  scenarios<-etr_expand_functional_simulation_scenarios(base,factors,
    seed_policy="disjoint")
  expect_length(scenarios,8L)
  expect_identical(vapply(scenarios,function(x)x$seed_start,integer(1L)),
    seq.int(31L,by=2L,length.out=8L))
  expect_identical(scenarios[[1L]]$name,
    "irregular__samples_per_curve=3-5__irregular_time_design=uniform__score_distribution=normal")
  expect_identical(scenarios[[2L]]$name,
    "irregular__samples_per_curve=3-5__irregular_time_design=uniform__score_distribution=student_t")
  expect_identical(scenarios[[3L]]$name,
    "irregular__samples_per_curve=3-5__irregular_time_design=center_clustered__score_distribution=normal")
  expect_identical(scenarios[[5L]]$samples_per_curve,c(5L,7L))
  expect_identical(scenarios[[4L]]$score_distribution,"student_t")
  expect_identical(vapply(etr_expand_functional_simulation_scenarios(
      base,factors,seed_policy="shared"),function(x)x$seed_start,
      integer(1L)),rep(31L,8L))
  # Distinct covariance structures, hierarchical variances, missingness and
  # multi-dimensional noise SDs must survive factor expansion without loss.
  covariance<-matrix(c(.09,.01,.01,.04),2L,2L)
  multivariate<-etr_functional_simulation_scenario("multi",
    seq(0,1,length.out=9L),c(2,1),5L,
    dimension_names=c("x","y"),measurement_noise_sd=0)
  mixed<-etr_expand_functional_simulation_scenarios(multivariate,list(
    measurement_noise_covariance=list(covariance,NULL),
    participant_eigenvalues=list(c(.3,.1),NULL),
    missingness=list(list(kind="dropout",p=.1),NULL)),"disjoint")
  expect_length(mixed,8L)
  expect_equal(mixed[[1L]]$measurement_noise_covariance,covariance)
  expect_null(mixed[[5L]]$measurement_noise_covariance)
  expect_null(mixed[[3L]]$participant_eigenvalues)
  expect_null(mixed[[2L]]$missingness)
  expect_match(mixed[[1L]]$name,"measurement_noise_covariance=array4")
  expect_match(mixed[[1L]]$name,"missingness=dropout")
  expect_match(mixed[[2L]]$name,"missingness=None")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list(seed_start=c(1L,2L))),"unsupported")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list(name=c("bad","worse"))),"unsupported")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list(samples_per_curve=list(c(1L,4L)))),"samples_per_curve")
})

test_that("Python 1.2 composite simulation-factor product matches native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 simulation design factor source is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  py_base<-reticulate::py_call(etpy_get_export("FunctionalSimulationScenario"),
    name="irregular",truth_grid=reticulate::r_to_py(as.list(seq(0,1,length.out=9L))),
    eigenvalues=reticulate::r_to_py(list(2.0,1.0)),
    n_participants=as.integer(3L),observation_design="irregular",
    samples_per_curve=reticulate::tuple(3L,5L),replicates=as.integer(2L),
    seed_start=as.integer(31L),measurement_noise_sd=0)
  py_levels<-reticulate::dict(
    samples_per_curve=reticulate::r_to_py(list(
      reticulate::tuple(3L,5L),reticulate::tuple(5L,7L))),
    irregular_time_design=reticulate::r_to_py(list("uniform","center_clustered")),
    score_distribution=reticulate::r_to_py(list("normal","student_t")))
  source<-reticulate::py_call(
    etpy_get_export("expand_functional_simulation_scenarios"),
    base=py_base,factors=py_levels,seed_policy="disjoint")
  native_base<-etr_functional_simulation_scenario("irregular",
    seq(0,1,length.out=9L),c(2,1),3L,
    observation_design="irregular",samples_per_curve=c(3L,5L),
    replicates=2L,seed_start=31L,measurement_noise_sd=0)
  native<-etr_expand_functional_simulation_scenarios(native_base,
    list(samples_per_curve=list(c(3L,5L),c(5L,7L)),
      irregular_time_design=c("uniform","center_clustered"),
      score_distribution=c("normal","student_t")),seed_policy="disjoint")
  expect_identical(length(native),length(source))
  for(i in seq_along(native)){
    src<-source[[i-1L]]
    expect_identical(native[[i]]$name,
      as.character(reticulate::py_to_r(src$name)),info=paste("name",i))
    expect_identical(native[[i]]$seed_start,
      as.integer(reticulate::py_to_r(src$seed_start)),info=paste("seed",i))
    expect_equal(native[[i]]$samples_per_curve,
      as.integer(et_to_r(src$samples_per_curve)),info=paste("samples",i))
    expect_identical(native[[i]]$irregular_time_design,
      as.character(reticulate::py_to_r(src$irregular_time_design)))
    expect_identical(native[[i]]$score_distribution,
      as.character(reticulate::py_to_r(src$score_distribution)))
  }
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
