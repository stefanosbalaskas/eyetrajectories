# Stage 26: native multiscale RQA inference and source recovery catalog.
.etr_test_functional_rqa_fixture <- function() {
  time<-0:17
  n<-4L
  values<-array(NA_real_,c(n,length(time),1L))
  for(i in seq_len(n))values[i,,1L]<-sin(time/3+i/5)+
    .06*time+.04*i*cos(time/4)
  etr_trajectory_set(as.numeric(time),values,
    curve_ids=paste0("curve_",seq_len(n)),dimension_names="x",
    metadata=data.frame(participant=c("p1","p1","p2","p2")),
    coordinate_system="arbitrary",time_unit="s")
}

test_that("frozen public recovery metric registry has 27 exact semantic rows",{
  defs<-etr_functional_recovery_metric_catalog()
  frame<-etr_functional_recovery_metric_catalog_frame()
  expect_length(defs,27L)
  expect_equal(nrow(frame),27L)
  expect_identical(names(frame),c("metric","quantity","direction",
    "units","scope","description"))
  expect_identical(names(defs),frame$metric)
  expect_identical(defs[[1L]]$name,"mean_ise")
  expect_identical(defs[[1L]]$direction,"lower_is_better")
  expect_identical(frame$metric[27L],"source_variance_relative_error")
  expect_false(anyDuplicated(frame$metric)>0L)
  expect_true(all(frame$direction%in%c("lower_is_better","higher_is_better")))
  expect_true(all(nzchar(frame$description)))
  expect_identical(defs,etr_functional_recovery_metric_catalog())
})

test_that("recovery flat keys are source zero-based without mutation",{
  m<-etr_functional_recovery_metric_catalog()[["mean_ise"]]
  v<-list(metric=m,value=.25,component=0L,source="participant")
  expect_identical(etr_functional_recovery_value_key(v),
    "mean_ise.source_participant.component_1")
  v$component<-2L
  expect_identical(etr_functional_recovery_value_key(v),
    "mean_ise.source_participant.component_3")
  v$source<-NULL;v$component<-NULL
  expect_identical(etr_functional_recovery_value_key(v),"mean_ise")
  v$component<--1L
  expect_error(etr_functional_recovery_value_key(v),"zero-based")
})

test_that("native recovery assessment preserves metric semantics and ordering",{
  defs<-etr_functional_recovery_metric_catalog()
  z<-list(values=list(
    list(metric=defs[["mean_ise"]],value=.2,source="x",component=0L),
    list(metric=defs[["score_correlation"]],value=.8,
      source=NULL,component=NULL)))
  out<-etr_functional_recovery_assessment_frame(z)
  expect_identical(dim(out),c(2L,9L))
  expect_identical(out$metric,c("mean_ise","score_correlation"))
  expect_equal(out$value,c(.2,.8))
  expect_equal(out$component[1L],1L)
  expect_true(is.na(out$component[2L]))
  expect_identical(out$direction,c("lower_is_better","higher_is_better"))
  wrong<-z;wrong$values[[1L]]$metric$direction<-"higher_is_better"
  expect_error(etr_functional_recovery_assessment_frame(wrong),
    "must match the published")
  bad_source<-z;bad_source$values[[2L]]$source<-c("x","y")
  expect_error(etr_functional_recovery_assessment_frame(bad_source),
    "single optional text")
  expect_error(etr_functional_recovery_assessment_frame(
    list(values=list())),"at least one")
  z$provenance<-list(estimator="fpca")
  prose<-etr_functional_recovery_reporting_text(z)
  expect_match(prose,"estimator 'fpca'")
  expect_match(prose,"mean_ise, score_correlation")
  expect_match(prose,"not an estimator-tuning input")
})

test_that("windowed-RQA sensitivity reports exact source reuse and centers",{
  x<-.etr_test_functional_rqa_fixture()
  a<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L),c(7L,3L)),radius=1)
  expect_s3_class(a,"etr_windowed_rqa_sensitivity")
  expect_equal(length(a$analyses),2L)
  expect_identical(a$design_table$specification_id,c("spec_1","spec_2"))
  expect_equal(a$design_table$window_samples,c(5L,7L))
  expect_equal(a$design_table$step_samples,c(2L,3L))
  expect_equal(a$design_table$overlap_samples,c(3L,4L))
  expect_equal(a$design_table$window_span_time,c(4,6))
  expect_true(all(a$design_table$n_analyzed_source_samples>=14L))
  expect_true(all(a$design_table$fraction_analyzed_samples_reused>0))
  expect_equal(nrow(a$summary_table),8L)
  expect_equal(nrow(a$pairwise_table),4L)
  expect_identical(a$pairwise_table$curve_id,x$curve_ids)
  expect_equal(a$pairwise_table$n_common_centers,rep(2L,4L))
  common<-intersect(a$analyses[[1L]]$trajectories$time,
    a$analyses[[2L]]$trajectories$time)
  expect_equal(common,c(6,12))
  for(i in seq_len(4L)){
    left<-a$analyses[[1L]]$trajectories
    right<-a$analyses[[2L]]$trajectories
    v<-left$values[i,match(common,left$time),1L]
    w<-right$values[i,match(common,right$time),1L]
    expect_equal(a$pairwise_table$rmse[i],
      sqrt(mean((v-w)^2)),tolerance=1e-12)
  }
  expect_true(a$provenance$no_automatic_specification_selection)
  expect_false(a$provenance$interpolation_used_for_sensitivity_comparison)
  expect_equal(a$provenance$requested_window_step_pairs,
    list(c(5,2),c(7,3)))
  expect_equal(a$provenance$resolved_window_step_samples,
    list(c(5L,2L),c(7L,3L)))
  expect_identical(a$provenance$source_provenance,x$provenance)
  expect_match(a$provenance$profile_grid_spacing_interpretation,
    "not an estimate of independent-information resolution")
  expect_match(a$provenance$window_dependence_interpretation,
    "serial dependence can remain")
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L),c(5L,2L)),radius=1),
    "duplicate resolved")
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2.5)),radius=1),
    "integer sample counts")
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L)),radius=1,
    target_recurrence_rate=.1),"exactly one")
})

test_that("simultaneous RQA mean band uses whole independent units",{
  x<-.etr_test_functional_rqa_fixture()
  band<-etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,
    unit="participant",participant_column="participant",
    radius=1,n_multiplier=100L,random_state=123L)
  expect_s3_class(band,"etr_windowed_rqa_mean_band")
  expect_identical(band$unit,"participant")
  expect_identical(band$band$unit,"participant")
  expect_equal(length(band$band$unit_ids),2L)
  expect_equal(band$band$curves_per_unit,c(2L,2L))
  expect_true(all(band$band$lower<=band$band$mean))
  expect_true(all(band$band$upper>=band$band$mean))
  expect_identical(band$band$time,
    band$functional_rqa$trajectories$time)
  expect_false(band$provenance$window_rows_resampled_as_independent)
  expect_true(band$provenance$whole_function_resampling_contract)
  expect_identical(band$provenance$functional_rqa_provenance,
    band$functional_rqa$provenance)
  expect_identical(band$provenance$functional_mean_band_provenance,
    band$band$provenance)
  same<-etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,
    unit="participant",participant_column="participant",
    radius=1,n_multiplier=100L,random_state=123L)
  expect_equal(band$band$max_statistics,same$band$max_statistics,
    tolerance=0)
  expect_error(etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,
    unit="unsupported",radius=1,n_multiplier=100L),
    "unit must")
})

test_that("catalog and numerical additions do not self-certify source contracts",{
  z<-etr_native_parity_catalog()
  new<-c("windowed_rqa_sensitivity",
    "windowed_rqa_functional_mean_band",
    "functional_recovery_metric_catalog",
    "functional_recovery_metric_catalog_frame",
    "functional_recovery_reporting_text",
    "functional_recovery_assessment_frame")
  for(name in new){
    row<-z[z$python_name==name&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",name))
    expect_identical(row$native_implementation_stage,26L)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_gte(sum(z$named_native_candidate&z$is_python_function),236L)
  expect_gte(sum(z$native_implementation_started),211L)
  expect_lte(sum(z$is_python_function&!z$named_native_candidate),144L)
  expect_gte(sum(z$source_contract_gap_unresolved),57L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})

test_that("direct published Python 1.2 recovery registry oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 recovery metadata oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  py<-reticulate::py_call(etpy_get_export(
    "functional_recovery_metric_catalog_frame"))
  source<-as.data.frame(et_to_r(py),stringsAsFactors=FALSE)
  ours<-etr_functional_recovery_metric_catalog_frame()
  expect_identical(names(ours),names(source))
  expect_equal(nrow(source),27L)
  for(k in names(ours))
    expect_identical(enc2utf8(as.character(ours[[k]])),
      enc2utf8(as.character(source[[k]])))
  types<-reticulate::import("types")
  metric<-types$SimpleNamespace(name="mean_ise")
  value<-types$SimpleNamespace(metric=metric,component=as.integer(0L),
    source="participant")
  # This key helper exists in Python recovery.py but is not a
  # published root callable in the frozen 380-name catalog.
  recovery<-reticulate::import("eyetrajectoriespy.recovery")
  py_key<-reticulate::py_call(
    recovery$functional_recovery_value_key,value=value)
  local<-etr_functional_recovery_value_key(
    list(metric=list(name="mean_ise"),component=0L,source="participant"))
  expect_identical(as.character(et_to_r(py_key)),local)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("pairwise RQA correlation uses frozen NumPy population-SD threshold",{
  # The frozen Python source uses np.std(ddof=0) > machine epsilon.
  # R's stats::sd(ddof=1) would erroneously permit this near-flat
  # two-point pair; use the same source condition in our calculation.
  x<-c(0,4e-16)
  y<-c(0,6e-16)
  eps<-.Machine$double.eps
  expected_gate<-.etr_rqa_source_population_sd(x)>eps &&
    .etr_rqa_source_population_sd(y)>eps
  sample_gate<-stats::sd(x)>eps && stats::sd(y)>eps
  expect_equal(.etr_rqa_source_population_sd(x),
    sqrt(mean((x-mean(x))^2)),tolerance=0)
  expect_false(expected_gate)
  expect_true(sample_gate)
  # Full pipeline correlation is exercised in the sensitivity source
  # fixture above. Here the executable numeric gate is explicit.
})


test_that("native target-density sliding RQA uses source 48-step inclusive radius",{
  x<-.etr_test_functional_rqa_fixture()
  result<-etr_windowed_rqa(x,curve=1L,window=5L,step=2L,
    target_recurrence_rate=.35)
  expect_s3_class(result,"etr_windowed_rqa")
  expect_equal(nrow(result$table),7L)
  expect_true(all(result$table$radius>0))
  expect_true(all(result$table$recurrence_rate>=0&
    result$table$recurrence_rate<=1))
  expect_identical(result$provenance$radius_policy,
    "target_recurrence_rate")
  expect_equal(result$provenance$target_recurrence_rate,.35)
  expect_error(etr_windowed_rqa(x,window=5L,step=2L,
    radius=1,target_recurrence_rate=.35),"exactly one")
  expect_error(etr_windowed_rqa(x,window=5L,step=2L),
    "exactly one")
  expect_error(etr_windowed_rqa(x,window=5L,step=2L,
    target_recurrence_rate=1),"strictly between")
  expect_error(etr_windowed_rqa(x,window=5L,step=2L,
    radius=0),"positive finite")
  expect_error(etr_windowed_rqa_trajectory_set(x,
    metrics="recurrence_rate",window=5L,step=2L,
    target_recurrence_rate=.35),"cannot be a functional outcome")
  y<-etr_windowed_rqa_trajectory_set(x,
    metrics="max_diagonal_length",window=5L,step=2L,
    target_recurrence_rate=.35)
  expect_identical(dim(y$trajectories$values),c(4L,7L,1L))
  expect_true(all(is.finite(y$trajectories$values)))
  z<-etr_windowed_rqa_sensitivity(x,
    metrics="max_diagonal_length",window_step_pairs=list(
      c(5L,2L),c(7L,3L)),target_recurrence_rate=.35)
  expect_identical(nrow(z$design_table),2L)
  expect_true(all(z$design_table$n_windows>=4L))
})

test_that("direct frozen Python 1.2 target-rate RQA radius and achieved density agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python target-rate RQA oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_test_functional_rqa_fixture()
  ctor<-etpy_get_export("TrajectorySet")
  pyx<-reticulate::py_call(ctor,
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  for(metric in c("euclidean","cityblock","chebyshev")){
    for(target in c(.2,.35,.65)){
      native<-etr_windowed_rqa(x,curve=1L,window=5L,step=2L,
        metric=metric,target_recurrence_rate=target)
      source<-reticulate::py_call(
        etpy_get_export("windowed_rqa"),
        trajectories=pyx,curve=as.integer(0L),window=as.integer(5L),
        step=as.integer(2L),target_recurrence_rate=target,
        metric=metric,dimensions=as.list(x$dimension_names))
      table<-as.data.frame(et_to_r(
        reticulate::py_get_attr(source,"table")))
      expect_equal(native$table$radius,as.numeric(table$radius),
        tolerance=1e-9,info=paste("radius",metric,target))
      expect_equal(native$table$recurrence_rate,
        as.numeric(table$recurrence_rate),tolerance=1e-12,
        info=paste("density",metric,target))
    }
  }
  # The same source radius policy must propagate through the full
  # functional sensitivity workflow, not only the base sliding-window API.
  native_sensitivity<-etr_windowed_rqa_sensitivity(x,
    metrics="max_diagonal_length",window_step_pairs=list(
      c(5L,2L),c(7L,3L)),target_recurrence_rate=.35)
  python_sensitivity<-reticulate::py_call(
    etpy_get_export("windowed_rqa_sensitivity"),
    trajectories=pyx,metrics=as.list("max_diagonal_length"),
    window_step_pairs=reticulate::r_to_py(list(
      as.list(c(5L,2L)),as.list(c(7L,3L)))),
    target_recurrence_rate=.35,dimensions=as.list(x$dimension_names))
  design<-as.data.frame(et_to_r(
    reticulate::py_get_attr(python_sensitivity,"design_table")))
  expect_equal(native_sensitivity$design_table$window_samples,
    as.integer(design$window_samples))
  expect_equal(native_sensitivity$design_table$step_samples,
    as.integer(design$step_samples))
  expect_equal(native_sensitivity$design_table$overlap_fraction,
    as.numeric(design$overlap_fraction),tolerance=1e-12)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
