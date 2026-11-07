# Frozen eyetrajectoriespy 1.2.0 functional_rqa.py source validator:
# _validated_window_step_pairs accepts Sequence[(float|int, float|int)].
# Bounded native equivalent uses nested R lists of scalar numbers.
# This is first-party source evidence, not independent 508-contract review.

.etr_rqa_nested_pairs_fixture<-function(){
  time<-as.numeric(0:17)
  values<-array(0,c(3L,length(time),1L))
  for(i in seq_len(3L))
    values[i,,1L]<-sin(time/3+i/5)+.05*time+
      .03*i*cos(time/4)
  etr_trajectory_set(time,values,
    curve_ids=paste0("curve_",seq_len(3L)),
    dimension_names="x",
    coordinate_system="arbitrary",time_unit="s")
}

test_that("native sensitivity accepts real Python tuple-like pair sequences",{
  x<-.etr_rqa_nested_pairs_fixture()
  a<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(list(5L,2L),list(7L,3L)),radius=1)
  b<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L),c(7L,3L)),radius=1)
  expect_s3_class(a,"etr_windowed_rqa_sensitivity")
  expect_identical(a$design_table,b$design_table)
  expect_identical(a$summary_table,b$summary_table)
  expect_identical(a$pairwise_table,b$pairwise_table)
  expect_equal(a$provenance$requested_window_step_pairs,
    list(c(5,2),c(7,3)),tolerance=0)
  expect_identical(a$provenance$resolved_window_step_samples,
    list(c(5L,2L),c(7L,3L)))
  expect_identical(nrow(a$summary_table),6L)
  expect_identical(nrow(a$pairwise_table),3L)
})

test_that("nested Python-style pair validation checks each scalar before coercion",{
  x<-.etr_rqa_nested_pairs_fixture()
  run<-function(pairs)etr_windowed_rqa_sensitivity(
    x,metrics="recurrence_rate",window_step_pairs=pairs,radius=1)
  bad<-list(
    list(TRUE,2L),list(5L,FALSE),list("5",2L),
    list(5L,"2"),list(5L),list(5L,2L,3L),
    list(5L,NA_real_),list(Inf,2L),list(5L,NaN),
    list(5L,c(2L,3L)),list(5L,2+0i))
  for(case in bad)
    expect_error(run(list(case)),
      "positive finite numeric values",
      info=paste("invalid pair:",paste(unlist(case),collapse=",")))
  expect_error(run(list(list(5L,0L))),"positive finite")
  expect_error(run(list(list(5L,-1L))),"positive finite")
  expect_error(run(list(list(5L,2.5))),
    "integer sample counts")
  expect_error(run(list(list(5L,2L),c(5L,2L))),
    "duplicate resolved")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("nested physical-time pair sequences retain fractional source precision",{
  time<-as.numeric(seq(0,by=.01,length.out=18L))
  values<-array(0,c(2L,length(time),1L))
  for(i in 1:2)values[i,,1L]<-sin((0:17)/3+i/5)
  x<-etr_trajectory_set(time,values,
    curve_ids=c("a","b"),dimension_names="x",
    coordinate_system="arbitrary",time_unit="s")
  a<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(list(.05,.02),list(.07,.03)),
    window_units="s",step_units="s",radius=1)
  b<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(c(.05,.02),c(.07,.03)),
    window_units="s",step_units="s",radius=1)
  expect_equal(a$design_table,b$design_table,tolerance=0)
  expect_equal(a$summary_table,b$summary_table,tolerance=0)
  expect_equal(a$pairwise_table,b$pairwise_table,tolerance=0)
  expect_equal(a$design_table$requested_window,c(.05,.07),tolerance=0)
  expect_equal(a$design_table$requested_step,c(.02,.03),tolerance=0)
})

test_that("real frozen Python 1.2 sensitivity tables match nested R source mode",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 nested RQA sequence oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_rqa_nested_pairs_fixture()
  py_x<-reticulate::py_call(
    etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  py<-reticulate::py_call(etpy_get_export("windowed_rqa_sensitivity"),
    trajectories=py_x,metrics=as.list("recurrence_rate"),
    window_step_pairs=reticulate::r_to_py(list(
      list(5L,2L),list(7L,3L))),radius=1,
    dimensions=as.list("x"))
  native<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(list(5L,2L),list(7L,3L)),
    radius=1,dimensions="x")
  compare_table<-function(r,source,fields){
    p<-as.data.frame(et_to_r(source))
    expect_identical(names(r),names(p))
    expect_identical(nrow(r),nrow(p))
    for(field in fields)
      expect_equal(as.numeric(r[[field]]),as.numeric(p[[field]]),
        tolerance=1e-9,info=paste("Python 1.2 RQA",field))
  }
  compare_table(native$design_table,py$design_table,
    c("requested_window","requested_step","window_samples",
      "step_samples","n_windows","overlap_samples",
      "overlap_fraction","n_analyzed_source_samples",
      "fraction_analyzed_samples_reused",
      "mean_window_memberships_per_analyzed_sample",
      "max_window_memberships"))
  compare_table(native$summary_table,py$summary_table,
    c("n_windows","n_finite_windows","mean",
      "standard_deviation","minimum","maximum"))
  compare_table(native$pairwise_table,py$pairwise_table,
    c("n_common_centers","rmse","mean_absolute_difference",
      "max_absolute_difference"))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
