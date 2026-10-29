# Stage 7 batched native Python 1.2 contract tests.
# The algorithms are pure R. Python is imported only inside explicitly
# opted-in, independent oracle fixtures.

test_that("native validation contracts preserve their scientific definitions",{
  tt <- c(0,.2,.7,1.4)
  v <- array(0,dim=c(2L,4L,3L))
  v[,,1L] <- .2; v[,,2L] <- .3; v[,,3L] <- .5
  expect_null(etr_validate_simplex(v))
  expect_null(etr_validate_simplex(v+1e-8))
  expect_error(etr_validate_simplex(array(1,c(2,4))),"shape")
  bad <- v;bad[1L,2L,1L]<-NA_real_
  expect_error(etr_validate_simplex(bad),"missing")
  bad <- v;bad[1L,2L,1L]<--.01
  expect_error(etr_validate_simplex(bad),"non-negative")
  bad <- v;bad[1L,2L,1L]<-.65
  expect_error(etr_validate_simplex(bad),"sum to one")
  expect_error(etr_validate_simplex(v,atol=-1),"atol")
  source <- etr_trajectory_set(tt,v,c("c1","c2"),
    c("a","b","c"),provenance=list(source="native"))
  expect_null(etr_validate_common_grid(source))
  broken <- source;broken$time[3L]<-broken$time[2L]
  expect_error(etr_validate_common_grid(broken),"strictly increasing")
  expect_null(etr_validate_no_long_missing_runs(source,.2))
  source$values[1L,1:2,1L] <- NA_real_
  expect_error(etr_validate_no_long_missing_runs(source,.49),
               "max_missing_fraction")
  expect_null(etr_validate_no_long_missing_runs(source,.5))
  expect_error(etr_validate_no_long_missing_runs(source,1),"\\[0, 1\\)")
})

test_that("native irregular object preserves each individual grid and missing gaze",{
  a <- etr_irregular_trajectory_set(
    list(c(0,1,2),c(.5,1.5,2.5,3.5)),
    list(matrix(c(0,1,2,4,5,6),ncol=2L),
         matrix(c(10,11,12,13,2,3,4,5),ncol=2L)),
    c("A","B"),c("x","y"),
    data.frame(group=c("treatment","control")),
    time_unit="ms",provenance=list(source="experiment"))
  expect_s3_class(a,"etr_irregular_trajectory_set")
  expect_equal(length(a$time),2L)
  expect_equal(vapply(a$time,length,integer(1L)),c(3L,4L))
  expect_equal(etr_common_overlap_interval(a),c(.5,2))
  expect_equal(etr_make_common_grid(a,4L),
               seq(.5,2,length.out=4L))
  expect_equal(etr_make_common_grid(a,5L,domain="union"),
               seq(0,3.5,length.out=5L))
  expect_equal(etr_make_common_grid(a,3L,start=-1,end=1),
               c(-1,0,1))
  expect_error(etr_make_common_grid(a,1L),"n_time")
  expect_error(etr_make_common_grid(a,5L,start=0),
               "together")
  expect_error(etr_make_common_grid(a,5L,domain="wrong"),
               "domain")
  expect_error(etr_irregular_trajectory_set(
    list(c(0,1,1)),list(matrix(0,3,1)),"dup","x"),
    "strictly increasing")
  expect_error(etr_irregular_trajectory_set(
    list(c(0,1)),list(matrix(0,2,1)),c("A","A"),"x"),
    "curve_ids|equally")
})

test_that("native irregular linear interpolation never extrapolates and masks long gaps",{
  a <- etr_irregular_trajectory_set(
    list(c(0,1,4),c(1,2,3)),
    list(matrix(c(0,1,4,2,NA,6),ncol=2L),
         matrix(c(10,20,30,5,6,7),ncol=2L)),
    c("A","B"),c("x","y"),time_unit="s",
    provenance=list(source="lab"))
  grid <- seq(0,4,by=.5)
  out <- etr_resample_irregular_to_grid(a,grid)
  expect_s3_class(out,"etr_trajectory_set")
  expect_identical(out$curve_ids,c("A","B"))
  expect_identical(out$provenance$source,"lab")
  expect_identical(out$provenance$irregular_to_grid$method,"linear")
  expect_null(out$provenance$irregular_to_grid$max_gap)
  expect_equal(out$values[1L,,1L],grid)
  expect_true(all(is.na(out$values[2L,c(1L,2L,8L,9L),1L])))
  expect_equal(out$values[2L,3L,1L],10)
  expect_equal(out$values[2L,7L,1L],30)
  limited <- etr_resample_irregular_to_grid(a,grid,max_gap=2)
  expect_true(all(is.na(limited$values[1L,4:8,1L])))
  expect_equal(limited$values[1L,3L,1L],1)
  expect_equal(limited$values[1L,9L,1L],4)
  expect_error(etr_resample_irregular_to_grid(a,grid,method="pchip"),
               "not yet qualified")
  expect_error(etr_resample_irregular_to_grid(a,grid,max_gap=0),
               "positive")
  both <- etr_resample_irregular_to_common_grid(a,n_time=4L,
                                                domain="overlap")
  expect_equal(both$time,seq(1,3,length.out=4L))
  expect_equal(both$provenance$irregular_to_grid$n_time,4L)
})

test_that("native irregular long-form source preserves stable groups and metadata",{
  df <- data.frame(
    participant=c("B","A","B","A","B","A"),
    t=c(1,0,3,1,2,3),
    x=c(1,2,3,4,5,6),
    y=c(2,3,4,5,6,7),
    arm=c("control","active","control","active","control","active"))
  x <- etr_from_irregular_long_native(
    df,curve_columns="participant",time_column="t",
    value_columns=c("x","y"),metadata_columns="arm",
    coordinate_system="pixels",time_unit="ms")
  expect_identical(x$curve_ids,c("B","A"))
  expect_equal(x$time[[1L]],c(1,2,3))
  expect_equal(x$time[[2L]],c(0,1,3))
  expect_identical(x$metadata$arm,c("control","active"))
  expect_identical(x$provenance$source,"irregular_long_dataframe_native")
  expect_identical(x$provenance$value_columns,c("x","y"))
  summary <- etr_irregular_sampling_summary(x)
  expect_identical(names(summary),c("curve_id","n_samples","time_start",
    "time_end","median_interval","max_interval","missing_fraction"))
  expect_equal(summary$n_samples,c(3L,3L))
  expect_equal(summary$median_interval,c(1,1.5))
  expect_equal(summary$missing_fraction,c(0,0))
  bad<-df;bad$t[3L]<-1
  expect_error(etr_from_irregular_long_native(
    bad,"participant","t",metadata_columns="arm"),
    "Duplicate")
  bad<-df;bad$arm[3L]<-"changed"
  expect_error(etr_from_irregular_long_native(
    bad,"participant","t",metadata_columns="arm"),
    "varies")
})

test_that("native phase landmark frame preserves signed timing deviations",{
  x <- etr_trajectory_set(c(0,1,2),array(0,c(2L,3L,1L)),
    c("A","B"),"x")
  registration <- list(original=x,
    observed_landmarks=matrix(c(.1,.4,1.1,1.4),nrow=2L,byrow=TRUE),
    reference_landmarks=c(0,1))
  df<-etr_phase_landmark_frame(registration)
  expect_identical(names(df),c("curve_id","landmark","observed_time",
    "reference_time","timing_deviation"))
  expect_identical(df$curve_id,c("A","A","B","B"))
  expect_equal(df$observed_time,c(.1,.4,1.1,1.4))
  expect_equal(df$timing_deviation,c(.1,-.6,1.1,.4))
  expect_error(etr_phase_landmark_frame(list()),"registration")
})

test_that("Python 1.2 independent irregular and validation oracles agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 irregular/validation reference is opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")
  py_irr <- etpy_get_export("from_irregular_long_dataframe_native")
  py_interval <- etpy_get_export("common_overlap_interval")
  py_grid <- etpy_get_export("make_common_grid")
  py_resample <- etpy_get_export("resample_irregular_to_grid")
  py_sum <- etpy_get_export("irregular_sampling_summary")
  py_simplex <- etpy_get_export("validate_simplex")
  pandas <- reticulate::import("pandas",convert=FALSE)
  scenarios <- list(
    list(times=list(c(0,.3,1,2.5),c(.1,.4,1.2,2.2)),
         missing=FALSE),
    list(times=list(c(0,.5,2,3),c(.25,.9,1.8,2.8)),
         missing=TRUE),
    list(times=list(c(1,2,4,7),c(1.5,3,4.5,6)),
         missing=FALSE))
  for(i in seq_along(scenarios)){
    cc <- scenarios[[i]]
    df <- do.call(rbind,lapply(seq_along(cc$times),function(k){
      t<-cc$times[[k]]
      data.frame(curve=paste0("C",k),t=t,
        x=2*t+k,y=3*t-k,
        group=if(k==1L)"A" else "B")
    }))
    if(cc$missing)df$y[3L]<-NA_real_
    native<-etr_from_irregular_long_native(
      df,"curve","t",c("x","y"),metadata_columns="group",
      coordinate_system="pixels",time_unit="s")
    python<-reticulate::py_call(py_irr,
      data=pandas$DataFrame(reticulate::r_to_py(df)),
      curve_columns=as.list("curve"),time_column="t",
      value_columns=as.list(c("x","y")),
      metadata_columns=as.list("group"),
      coordinate_system="pixels",time_unit="s")
    expect_equal(native$curve_ids,
      as.character(unlist(et_to_r(python$curve_ids))),
      info=paste("ids",i))
    expected_times<-et_to_r(python$time)
    for(k in seq_along(native$time))
      expect_equal(native$time[[k]],as.numeric(expected_times[[k]]),
                   tolerance=1e-11,info=paste("time",i,k))
    expect_equal(etr_common_overlap_interval(native),
      as.numeric(unlist(et_to_r(reticulate::py_call(py_interval,
                                                  trajectories=python)))),
      tolerance=1e-10)
    for(domain in c("overlap","union")){
      nt<-6L
      actual_grid<-etr_make_common_grid(native,nt,domain)
      py_common<-reticulate::py_call(py_grid,
        trajectories=python,n_time=nt,domain=domain)
      expect_equal(actual_grid,as.numeric(et_to_r(py_common)),
                   tolerance=1e-11,info=paste("grid",i,domain))
      nres<-etr_resample_irregular_to_grid(native,actual_grid,
                                           method="linear",max_gap=1.5)
      pres<-reticulate::py_call(py_resample,trajectories=python,
        grid=reticulate::r_to_py(actual_grid),
        method="linear",max_gap=1.5)
      expected<-et_to_r(pres$values)
      expect_identical(dim(nres$values),dim(expected))
      expect_identical(is.na(nres$values),is.na(expected))
      mask<-!is.na(expected)
      if(any(mask))expect_equal(as.numeric(nres$values[mask]),
        as.numeric(expected[mask]),tolerance=1e-10,
        info=paste("resample",i,domain))
    }
    py_table<-et_to_r(reticulate::py_call(py_sum,trajectories=python))
    actual<-etr_irregular_sampling_summary(native)
    for(key in c("n_samples","time_start","time_end","median_interval",
                 "max_interval","missing_fraction"))
      expect_equal(as.numeric(actual[[key]]),
        as.numeric(py_table[[key]]),tolerance=1e-12,
        info=paste("sampling",i,key))
  }
  simplex<-array(.25,c(2L,3L,4L))
  expect_null(etr_validate_simplex(simplex))
  expect_null(et_to_r(reticulate::py_call(py_simplex,
    values=reticulate::r_to_py(simplex))))
})
