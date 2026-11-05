# Pinned Python 1.2.0 functional_rqa.py::_validated_window_step_pairs
# Scientific contract: windowed_rqa_sensitivity, no automatic selection.

.etr_rqa_pair_source_fixture <- function() {
  time<-as.numeric(0:17)
  values<-array(0,c(4L,length(time),1L))
  for(i in seq_len(4L))
    values[i,,1L]<-sin(time/3+i/5)+.06*time+.04*i*cos(time/4)
  etr_trajectory_set(time,values,paste0("curve_",1:4),"x",
    coordinate_system="arbitrary",time_unit="s")
}

test_that("numeric scalar list pairs agree with the existing RQA solution", {
  x<-.etr_rqa_pair_source_fixture()
  vector_pairs<-list(c(5L,2L),c(7L,3L))
  sequence_pairs<-list(list(5L,2.0),list(7.0,3L))
  a<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=vector_pairs,radius=1)
  b<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=sequence_pairs,radius=1)
  expect_equal(b$design_table,a$design_table,tolerance=0)
  expect_equal(b$summary_table,a$summary_table,tolerance=0)
  expect_equal(b$pairwise_table,a$pairwise_table,tolerance=0)
  expect_equal(b$provenance$requested_window_step_pairs,
    list(c(5,2),c(7,3)),tolerance=0)
  expect_equal(b$design_table$n_windows,c(7L,4L))
  expect_true(all(b$design_table$n_analyzed_source_samples>0L))
})

test_that("Python pair-sequence scalar validation is fail closed", {
  x<-.etr_rqa_pair_source_fixture()
  evaluate<-function(pairs)etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",window_step_pairs=pairs,radius=1)
  expect_error(evaluate(list(list(5L,TRUE))),"positive finite numeric")
  expect_error(evaluate(list(list(5L,"2"))),"positive finite numeric")
  expect_error(evaluate(list(list(5L,2L,1L))),"positive finite numeric")
  expect_error(evaluate(list(list(5L,Inf))),"positive finite numeric")
  expect_error(evaluate(list(list(5L,2.5))),"integer sample counts")
  expect_error(evaluate(list(list(5L,2L),c(5L,2L))),
    "duplicate resolved")
  expect_error(evaluate(list()),"nonempty list")
})

test_that("physical-time mixed pairs retain numerical source geometry", {
  x<-.etr_rqa_pair_source_fixture()
  x$time<-seq(0,by=.01,length.out=18L)
  mixed<-list(list(.05,.02),list(.07,.03))
  flat<-list(c(.05,.02),c(.07,.03))
  a<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=mixed,window_units="s",step_units="s",
    radius=1,dimensions="x")
  b<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=flat,window_units="s",step_units="s",
    radius=1,dimensions="x")
  expect_equal(a$design_table,b$design_table,tolerance=0)
  expect_equal(a$summary_table,b$summary_table,tolerance=0)
  expect_equal(a$pairwise_table,b$pairwise_table,tolerance=0)
  expect_equal(a$design_table$window_samples,c(5L,7L))
  expect_equal(a$design_table$step_samples,c(2L,3L))
})

test_that("frozen Python 1.2 RQA sequence-pair tables agree", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 RQA source comparison is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_rqa_pair_source_fixture()
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  pairs<-list(list(5L,2.0),list(7.0,3L))
  our<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=pairs,radius=1,dimensions="x")
  py<-reticulate::py_call(
    etpy_get_export("windowed_rqa_sensitivity"),
    trajectories=pyx,metrics=as.list("recurrence_rate"),
    window_step_pairs=reticulate::r_to_py(pairs),radius=1,
    dimensions=as.list("x"))
  for(name in c("design_table","summary_table","pairwise_table")){
    a<-our[[name]]
    b<-as.data.frame(et_to_r(reticulate::py_get_attr(py,name)))
    expect_identical(names(a),names(b),info=name)
    expect_identical(nrow(a),nrow(b),info=name)
    for(col in names(a)){
      if(is.numeric(a[[col]])){
        lhs<-as.numeric(a[[col]])
        rhs<-as.numeric(b[[col]])
        expect_identical(is.na(lhs),is.na(rhs),
          info=paste(name,col,"missingness"))
        valid<-is.finite(lhs)&is.finite(rhs)
        if(any(valid))expect_equal(lhs[valid],rhs[valid],
          tolerance=1e-9,info=paste(name,col))
      } else expect_equal(as.character(a[[col]]),
        as.character(b[[col]]),info=paste(name,col))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
