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

test_that("Stage 26 frozen public recovery metric registry has 27 exact semantic rows",{
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

test_that("Stage 26 recovery flat keys are source zero-based without mutation",{
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

test_that("Stage 26 native recovery assessment preserves metric semantics and ordering",{
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

test_that("Stage 26 windowed-RQA sensitivity reports exact source reuse and centers",{
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
    target_recurrence_rate=.1),"fixed-radius")
})

test_that("Stage 26 simultaneous RQA mean band uses whole independent units",{
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

test_that("Stage 26 catalog and numerical additions do not self-certify source contracts",{
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
  expect_equal(sum(z$named_native_candidate&z$is_python_function),232L)
  expect_equal(sum(z$native_implementation_started),207L)
  expect_equal(sum(z$is_python_function&!z$named_native_candidate),148L)
  expect_equal(sum(z$source_contract_gap_unresolved),53L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})

test_that("Stage 26 direct published Python 1.2 recovery registry oracle is opt-in",{
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
