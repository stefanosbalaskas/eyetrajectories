# Frozen eyetrajectoriespy==1.2.0, source commit
# c1cd95ad718327550f7e55393ff38582872f7a94
# functional_rqa.py::windowed_rqa_sensitivity and
# functional_rqa.py::windowed_rqa_functional_mean_band.
# Python is opt-in test oracle only; native R implementations are Python-free.

.etr_rqa_two_fixture <- function(physical=FALSE,multichannel=FALSE){
  time<-if(physical)seq(0,by=.01,length.out=18L) else as.numeric(0:17)
  n<-6L;nd<-if(multichannel)2L else 1L
  values<-array(0,c(n,length(time),nd))
  time_index<-as.numeric(0:17)
  for(i in seq_len(n)){
    values[i,,1L]<-sin(time_index/3+i/5)+.08*time_index+
      .22*cos(time_index/4+i/3)+i*time_index/80
    if(multichannel)values[i,,2L]<-cos(time_index/6+i/7)
  }
  etr_trajectory_set(
    time=time,values=values,curve_ids=paste0("curve_",seq_len(n)),
    dimension_names=if(multichannel)c("x","y") else "x",
    metadata=data.frame(participant=c("p1","p1","p1","p2","p2","p3"),
      stringsAsFactors=FALSE),
    coordinate_system="arbitrary",time_unit="s",
    provenance=list(origin="RQA source-parity case"))
}
.etr_rqa_two_py_trajectory <- function(x){
  pd<-reticulate::import("pandas",convert=FALSE)
  meta<-pd$DataFrame(reticulate::r_to_py(
    list(participant=as.list(x$metadata$participant))))
  reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    metadata=meta,coordinate_system="arbitrary",time_unit="s",
    provenance=reticulate::dict(origin="RQA source-parity case"))
}
.etr_rqa_two_frame_compare<-function(a,b,label){
  expect_s3_class(a,"data.frame")
  expect_s3_class(b,"data.frame")
  expect_identical(names(a),names(b),info=paste(label,"column order"))
  expect_identical(nrow(a),nrow(b),info=paste(label,"row count"))
  for(field in names(a)){
    x<-a[[field]];y<-b[[field]]
    expect_identical(is.na(x),is.na(y),
      info=paste(label,field,"missing values"))
    finite<-!is.na(x)
    if(is.numeric(x)&&is.numeric(y)){
      expect_equal(as.numeric(x[finite]),as.numeric(y[finite]),
        tolerance=1e-9,info=paste(label,field,"numerics"))
    }else expect_identical(as.character(x[finite]),
      as.character(y[finite]),info=paste(label,field,"strings"))
  }
}
.etr_rqa_two_provenance_compare<-function(native,python,label){
  if(is.list(native)&&is.list(python)){
    nx<-names(native);ny<-names(python)
    if(!length(native)&&!length(python))return(invisible(NULL))
    if(is.null(nx)&&length(ny)==0L)ny<-NULL
    expect_identical(nx,ny,info=paste(label,"provenance names"))
    expect_identical(length(native),length(python),
      info=paste(label,"provenance length"))
    for(i in seq_along(native)){
      key<-if(!is.null(nx))nx[[i]] else as.character(i)
      .etr_rqa_two_provenance_compare(native[[i]],python[[i]],
        paste(label,key))
    }
  }else if(is.null(native))expect_null(python,info=label)
  else if(is.numeric(native)&&is.numeric(python)){
    expect_identical(is.na(native),is.na(python),info=label)
    expect_equal(as.numeric(native[!is.na(native)]),
      as.numeric(python[!is.na(python)]),tolerance=1e-11,info=label)
  }else if(is.logical(native)&&is.logical(python))
    expect_identical(as.logical(native),as.logical(python),info=label)
  else expect_identical(as.character(native),as.character(python),info=label)
}

test_that("single RQA source specification produces the pandas 0x0 pairwise table",{
  x<-.etr_rqa_two_fixture()
  native<-etr_windowed_rqa_sensitivity(x,metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L)),radius=.75)
  expect_identical(dim(native$design_table),c(1L,21L))
  expect_identical(nrow(native$summary_table),6L)
  expect_identical(dim(native$pairwise_table),c(0L,0L))
  expect_identical(native$provenance$specification_ids,"spec_1")
  expect_true(native$provenance$no_automatic_specification_selection)
  # A source-invalid duplicated resolved sample specification must fail,
  # regardless of its spelling in physical-time or sample units.
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",
    window_step_pairs=list(c(5L,2L),c(5,2)),radius=.75),
    "duplicate resolved")
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",
    window_step_pairs=list(c(TRUE,2L)),radius=.75),"numeric")
})

test_that("curve-level RQA band preserves source caller participant provenance",{
  x<-.etr_rqa_two_fixture()
  z<-etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,
    unit="curve",participant_column="participant",radius=.75,
    n_multiplier=100L,random_state=123L)
  expect_identical(z$provenance$participant_column,"participant")
  expect_identical(z$unit,"curve")
  expect_identical(z$band$unit,"curve")
  expect_equal(length(z$band$unit_ids),6L)
  expect_false(z$provenance$window_rows_resampled_as_independent)
  expect_true(z$provenance$whole_function_resampling_contract)
})

test_that("full Python 1.2 RQA sensitivity source frames and provenance match R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 direct source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  specs<-list(
    list(id="single",physical=FALSE,multi=FALSE,
      metrics="recurrence_rate",
      pairs=list(c(5L,2L)),radius=.75,target=NULL),
    list(id="sample",physical=FALSE,multi=FALSE,
      metrics=c("recurrence_rate","max_diagonal_length"),
      pairs=list(c(5L,2L),c(7L,3L)),radius=.75,target=NULL),
    list(id="physical",physical=TRUE,multi=TRUE,
      metrics="recurrence_rate",
      pairs=list(c(.05,.02),c(.07,.03)),radius=.75,target=NULL),
    list(id="density",physical=FALSE,multi=FALSE,
      metrics="max_diagonal_length",
      pairs=list(c(5L,2L),c(7L,3L)),radius=NULL,target=.35))
  for(spec in specs){
    x<-.etr_rqa_two_fixture(spec$physical,spec$multi)
    pyx<-.etr_rqa_two_py_trajectory(x)
    kwargs<-list(
      trajectories=pyx,metrics=as.list(spec$metrics),
      window_step_pairs=reticulate::r_to_py(lapply(spec$pairs,
        function(z)as.list(z))),
      dimensions=as.list("x"))
    rargs<-list(trajectories=x,metrics=spec$metrics,
      window_step_pairs=spec$pairs,dimensions="x")
    if(spec$physical){
      kwargs$window_units<-"s";kwargs$step_units<-"s"
      rargs$window_units<-"s";rargs$step_units<-"s"
    }
    if(is.null(spec$radius)){
      kwargs$target_recurrence_rate<-spec$target
      rargs$target_recurrence_rate<-spec$target
    }else{
      kwargs$radius<-spec$radius;rargs$radius<-spec$radius
    }
    ours<-do.call(etr_windowed_rqa_sensitivity,rargs)
    py<-do.call(reticulate::py_call,
      c(list(etpy_get_export("windowed_rqa_sensitivity")),kwargs))
    for(which in c("design_table","summary_table","pairwise_table")){
      expected<-as.data.frame(et_to_r(
        reticulate::py_get_attr(py,which)),stringsAsFactors=FALSE)
      .etr_rqa_two_frame_compare(ours[[which]],expected,
        paste(spec$id,which))
    }
    expected_prov<-et_to_r(reticulate::py_get_attr(py,"provenance"))
    .etr_rqa_two_provenance_compare(ours$provenance,expected_prov,
      paste(spec$id,"provenance"))
    expected_analyses<-reticulate::py_get_attr(py,"analyses")
    expect_identical(length(ours$analyses),
      length(et_to_r(expected_analyses)))
    for(i in seq_along(ours$analyses)){
      source_analysis<-reticulate::py_get_item(expected_analyses,
        as.integer(i-1L))
      expect_equal(unname(ours$analyses[[i]]$trajectories$values),
        unname(et_to_r(source_analysis$trajectories$values)),
        tolerance=1e-10,info=paste(spec$id,"derived RQA",i))
      expect_equal(ours$analyses[[i]]$trajectories$time,
        as.numeric(et_to_r(source_analysis$trajectories$time)),
        tolerance=1e-12,info=paste(spec$id,"time",i))
    }
  }
})

test_that("frozen Python 1.2 RQA mean bands match complete independent-unit inference",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 full RQA mean-band source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_rqa_two_fixture()
  pyx<-.etr_rqa_two_py_trajectory(x)
  for(unit in c("curve","participant")){
    for(column in if(unit=="curve")list(NULL,"participant") else
      list("participant")){
      label<-paste(unit,if(is.null(column))"none" else column)
      kwargs<-list(trajectories=pyx,
        metrics=as.list("recurrence_rate"),
        window=as.integer(5L),step=as.integer(2L),
        unit=unit,radius=.75,n_multiplier=as.integer(100L),
        random_state=as.integer(123L),dimensions=as.list("x"))
      if(!is.null(column))kwargs$participant_column<-column
      source<-do.call(reticulate::py_call,
        c(list(etpy_get_export("windowed_rqa_functional_mean_band")),
          kwargs))
      ours<-etr_windowed_rqa_functional_mean_band(x,
        metrics="recurrence_rate",window=5L,step=2L,unit=unit,
        participant_column=column,radius=.75,
        n_multiplier=100L,random_state=123L,dimensions="x")
      for(field in c("mean","pointwise_se","max_statistics",
        "critical_value","lower","upper","time")){
        a<-ours$band[[field]]
        b<-et_to_r(reticulate::py_get_attr(source$band,field))
        expect_equal(unname(as.numeric(a)),unname(as.numeric(b)),
          tolerance=1e-10,info=paste(label,field))
      }
      expect_identical(ours$band$unit_ids,
        as.character(et_to_r(source$band$unit_ids)),
        info=paste(label,"inference units"))
      expect_equal(ours$band$curves_per_unit,
        as.integer(et_to_r(source$band$curves_per_unit)),
        tolerance=0,info=paste(label,"curve/participant blocks"))
      expect_equal(unname(ours$functional_rqa$trajectories$values),
        unname(et_to_r(source$functional_rqa$trajectories$values)),
        tolerance=1e-10,info=paste(label,"derived outcome"))
      expected_prov<-et_to_r(source$provenance)
      .etr_rqa_two_provenance_compare(ours$provenance,expected_prov,
        paste(label,"wrapper provenance"))
    }
  }
})
