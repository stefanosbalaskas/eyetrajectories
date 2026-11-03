# Source: frozen Python eyetrajectoriespy 1.2.0
# simulate.py::run_functional_recovery_scenarios and
# recovery.py::FunctionalRecoveryAssessment / functional_recovery_value_key.
# Pinned SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# First-party source numerical and semantic tests; not independent certification.

.etr_structured_runner_mean<-function(t)rep(.15+0*t,length(t))
.etr_structured_runner_modes<-function()
  list(function(t)rep(1,length(t)))
.etr_structured_runner_scenarios<-function() {
  grid<-c(0,.25,.5,.75,1)
  list(
    etr_functional_simulation_scenario(
      name="structured_dense_t",truth_grid=grid,
      eigenvalues=1.1,n_participants=8L,
      trials_per_participant=2L,
      participant_eigenvalues=.2,trial_eigenvalues=.1,
      score_distribution="student_t",score_df=5,
      measurement_noise_sd=.02,replicates=2L,seed_start=730L),
    etr_functional_simulation_scenario(
      name="structured_irregular_phase",truth_grid=grid,
      eigenvalues=1.1,n_participants=8L,
      trials_per_participant=2L,
      observation_design="irregular",samples_per_curve=6L,
      irregular_time_design="center_clustered",
      participant_eigenvalues=.2,trial_eigenvalues=.1,
      score_distribution="student_t",score_df=5,
      phase_variation=list(kind="power",sd=.25),
      missingness=list(kind="block",fraction=.16),
      measurement_noise_sd=.02,replicates=1L,seed_start=738L))
}

test_that("structured assessment recovery works on dense Student-t and irregular phase truth",{
  scenarios<-.etr_structured_runner_scenarios()
  calls<-0L
  estimator<-function(observations,scenario) {
    calls<<-calls+1L
    expect_false("truth"%in%names(observations))
    expect_true(inherits(observations,"etr_trajectory_set")||
      inherits(observations,"etr_irregular_trajectory_set"))
    list(curves=length(observations$curve_ids),
      name=scenario$name)
  }
  recovery<-function(fit,truth,scenario) {
    expect_identical(fit$curves,nrow(truth$scores))
    expect_identical(fit$name,scenario$name)
    etr_evaluate_hierarchy_truth_recovery(truth)
  }
  out<-etr_run_functional_recovery_scenarios(scenarios,
    mean=.etr_structured_runner_mean,
    eigenfunctions=.etr_structured_runner_modes(),
    estimator=estimator,recovery=recovery)
  expect_s3_class(out,"etr_functional_recovery_result")
  expect_identical(calls,3L)
  expect_identical(length(out$records),3L)
  expect_true(all(vapply(out$records,function(x)x$status=="ok",
    logical(1L))))
  expect_true(all(vapply(out$records,function(x)
    identical(x$assessment_provenance$ddof,0L),logical(1L))))
  expect_identical(names(out$metric_definitions),
    c("source_variance_absolute_error",
      "source_variance_relative_error"))
  expect_true(all(vapply(out$records,function(x)
    all(vapply(x$metric_values,function(v)
      identical(v$metric$name,"source_variance_absolute_error")||
        identical(v$metric$name,"source_variance_relative_error"),
      logical(1L))),logical(1L))))
  expect_true(all(vapply(out$records,function(record)
    length(record$metrics)==length(record$metric_values),
    logical(1L))))
  for(record in out$records) {
    keys<-vapply(record$metric_values,
      etr_functional_recovery_value_key,character(1L))
    expect_identical(names(record$metrics),keys)
    expect_identical(length(unique(keys)),length(keys))
    expect_identical(sort(unique(vapply(record$metric_values,
      function(v)v$source,character(1L)))),
      sort(c("curve","participant","trial")))
    expect_true(any(grepl(".source_curve.component_1",
      names(record$metrics),fixed=TRUE)))
  }
  expect_silent(etr_functional_recovery_result(
    out$records,out$metric_definitions))
  frame<-etr_functional_recovery_frame(out)
  expect_equal(nrow(frame),length(out$records)*
    length(out$records[[1L]]$metric_values),tolerance=0)
  expect_identical(unique(frame$metric),
    c("source_variance_absolute_error",
      "source_variance_relative_error"))
  expect_identical(unique(frame$component),1L)
  expect_true(all(frame$direction=="lower_is_better"))
  expect_true(all(frame$source%in%c("curve","participant","trial")))
  expect_true(all(is.finite(frame$value)))
  failure<-etr_functional_recovery_failure_frame(out)
  expect_identical(sum(failure$n_failed),0L)
  expect_true(all(failure$failure_proportion==0))
})

test_that("the source recovery runner retains plain numeric metric callbacks",{
  scenario<-.etr_structured_runner_scenarios()[[1L]]
  observed<-0L
  runner<-etr_run_functional_recovery_scenarios(
    list(scenario),.etr_structured_runner_mean,
    .etr_structured_runner_modes(),
    estimator=function(observations,scenario){
      observed<<-observed+1L
      length(observations$curve_ids)
    },
    recovery=function(fit,truth,scenario)
      c(sample_size=as.numeric(fit),score_rms=
        sqrt(mean(truth$scores^2))))
  expect_identical(observed,2L)
  expect_identical(length(runner$records),2L)
  expect_identical(runner$metric_definitions,list())
  expect_identical(runner$records[[1L]]$metric_values,list())
  expect_identical(runner$records[[1L]]$assessment_provenance,list())
  expect_identical(names(runner$records[[1L]]$metrics),
    c("sample_size","score_rms"))
  expect_silent(etr_functional_recovery_result(
    runner$records,runner$metric_definitions))
})

test_that("structured assessment catches duplicate labels and conflicting definitions",{
  metric<-.etr_recovery_source_metric("source_variance_absolute_error")
  make_value<-function(value,source="curve")
    list(metric=metric,value=value,component=0L,source=source)
  ass<-structure(list(values=list(make_value(.15)),
    provenance=list(study="unit")),class="etr_functional_recovery_assessment")
  p<-.etr_recovery_runner_assessment(ass)
  expect_identical(p$metrics,c(
    "source_variance_absolute_error.source_curve.component_1"=.15))
  bad<-ass
  bad$values<-c(bad$values,bad$values)
  expect_error(.etr_recovery_runner_assessment(bad),
    "duplicate metric labels")
  bad<-ass;bad$values[[1L]]$value<-NaN
  expect_error(.etr_recovery_runner_assessment(bad),"finite")
  bad<-ass;bad$values[[1L]]$source<-"  "
  expect_error(.etr_recovery_runner_assessment(bad),"nonempty")
  bad<-ass;bad$values[[1L]]$component<--1L
  expect_error(.etr_recovery_runner_assessment(bad),"nonnegative")
  bad<-ass;bad$values[[1L]]$metric$direction<-"unknown"
  expect_error(.etr_recovery_runner_assessment(bad),
    "six valid source fields")
  bad<-ass;bad$provenance<-list(invalid=NaN)
  expect_error(.etr_recovery_runner_assessment(bad),"provenance")
  scenario<-.etr_structured_runner_scenarios()[[1L]]
  i<-0L
  flip<-function(fit,truth,scenario){
    i<<-i+1L
    definition<-metric
    if(i>1L)definition$units<-"different units"
    structure(list(values=list(list(metric=definition,
      value=.2,component=0L,source="curve")),
      provenance=list()),class="etr_functional_recovery_assessment")
  }
  expect_error(etr_run_functional_recovery_scenarios(
    list(scenario),.etr_structured_runner_mean,
    .etr_structured_runner_modes(),
    estimator=function(observations,scenario) NULL,
    recovery=flip,failure_action="record"),
    "recovery metric definitions are inconsistent")
})

test_that("structured recovery preserves explicit estimator failures without synthetic replacement",{
  scenarios<-.etr_structured_runner_scenarios()
  should_fail<-function(observations,scenario){
    if(scenario$name=="structured_irregular_phase")
      stop("predeclared fit exception")
    1
  }
  out<-etr_run_functional_recovery_scenarios(
    scenarios,.etr_structured_runner_mean,
    .etr_structured_runner_modes(),
    estimator=should_fail,
    recovery=function(fit,truth,scenario)
      etr_evaluate_hierarchy_truth_recovery(truth),
    failure_action="record")
  expect_identical(vapply(out$records,function(r)r$status,
    character(1L)),c("ok","ok","fit_failed"))
  expect_identical(out$records[[3L]]$metrics,numeric())
  expect_identical(out$records[[3L]]$metric_values,list())
  expect_match(out$records[[3L]]$error_message,
    "predeclared fit exception")
  frame<-etr_functional_recovery_failure_frame(out)
  expect_identical(frame$n_failed[frame$scenario==
    "structured_irregular_phase"],1L)
  expect_identical(frame$n_failed[frame$scenario==
    "structured_dense_t"],0L)
  expect_silent(etr_functional_recovery_result(
    out$records,out$metric_definitions))
})

test_that("frozen Python 1.2 structured recovery key/definition semantics agree with native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 functional recovery source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.recovery import (
    FunctionalRecoveryMetric, FunctionalRecoveryValue,
    FunctionalRecoveryAssessment, functional_recovery_value_key)
_etr_recovery_metric=FunctionalRecoveryMetric(
    name='test_rmse',quantity='latent signal',direction='lower_is_better',
    units='score units',scope='curve',description='Source semantic test')
_etr_recovery_values=(
    FunctionalRecoveryValue(_etr_recovery_metric,.12,component=0,source='curve'),
    FunctionalRecoveryValue(_etr_recovery_metric,.28,component=1,source='trial'),
)
_etr_recovery_assessment=FunctionalRecoveryAssessment(
    values=_etr_recovery_values,provenance={'study':'source'})
_etr_recovery_mapping=dict(_etr_recovery_assessment.as_mapping())
_etr_recovery_keys=tuple(functional_recovery_value_key(value)
                         for value in _etr_recovery_values)
")
  metric<-list(name="test_rmse",quantity="latent signal",
    direction="lower_is_better",units="score units",scope="curve",
    description="Source semantic test")
  ours<-structure(list(values=list(
    list(metric=metric,value=.12,component=0L,source="curve"),
    list(metric=metric,value=.28,component=1L,source="trial")),
    provenance=list(study="source")),
    class="etr_functional_recovery_assessment")
  out<-.etr_recovery_runner_assessment(ours)
  py_keys<-et_to_r(reticulate::py_eval("_etr_recovery_keys",
    convert=FALSE))
  py_map<-et_to_r(reticulate::py_eval("_etr_recovery_mapping",
    convert=FALSE))
  expect_identical(names(out$metrics),as.character(py_keys))
  expect_equal(unname(out$metrics),
    as.numeric(unlist(py_map[as.character(py_keys)])),tolerance=0)
  expect_identical(out$metric_values[[1L]]$component,0L)
  expect_identical(out$metric_values[[2L]]$source,"trial")
  expect_identical(out$definitions[["test_rmse"]]$direction,
    "lower_is_better")
  # Actual source runner also accepts FunctionalRecoveryAssessment;
  # the R implementation uses an explicitly audited native record
  # rather than asserting Python dataclass identity.
  expect_true(is.list(et_to_r(reticulate::py_eval(
    "_etr_recovery_assessment.provenance",convert=FALSE))))
})
