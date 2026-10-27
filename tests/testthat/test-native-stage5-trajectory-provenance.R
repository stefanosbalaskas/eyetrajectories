# Stage 5: provenance, metadata, portable-native-R trajectory state.
# R-only tests never initialize Python. Optional reference checks use 1.2.

test_that("native trajectory provenance is validated and backwards compatible",{
  tt <- c(0,.25,1,2)
  a <- array(seq_len(2L*length(tt)*3L),c(2L,length(tt),3L))
  md <- data.frame(subject=c("p1","p2"),
                   condition=factor(c("A","B")))
  provenance <- list(source="recording",device=list(
    make="Gazepoint",calibrated=TRUE),preprocessing=c("none"),
    missingness=list(explicit=TRUE,reviewed=NULL))
  x <- etr_trajectory_set(tt,a,c("g1","g2"),c("x","y","pupil"),
    md,coordinate_system="pixels",time_unit="ms",
    provenance=provenance)
  expect_identical(etr_trajectory_provenance(x),provenance)
  expect_identical(x$metadata,md)
  expect_identical(x$provenance$device$make,"Gazepoint")
  expect_true(etr_validate(x))
  expect_equal(etr_subset(x,"g2")$provenance,provenance)
  expect_equal(etr_subset(x,"g2")$metadata,
               md[2L,,drop=FALSE])
  empty <- etr_trajectory_set(tt,a)
  expect_identical(etr_trajectory_provenance(empty),list())

  expect_error(etr_trajectory_set(tt,a,provenance="bad"),
               "provenance")
  expect_error(etr_trajectory_set(tt,a,provenance=list(A=1,A=2)),
               "provenance")
  expect_error(etr_trajectory_set(tt,a,provenance=list(thing=function()1)),
               "provenance")
  expect_error(etr_trajectory_set(tt,a,provenance=NULL),
               "provenance")
  expect_error(etr_trajectory_set(tt,a,provenance=list(bad=NA_real_)),
               "provenance")
})

test_that("native with_values replaces top-level provenance keys only",{
  tt <- c(0,.25,1,2)
  a <- array(1:16,c(2L,4L,2L))
  initial <- list(source="raw",nested=list(a=1,b=2))
  x <- etr_trajectory_set(tt,a,c("A","B"),c("x","y"),
    coordinate_system="pixels",time_unit="ms",
    provenance=initial)
  replacement <- a+2
  y <- etr_with_values(x,replacement,
    time=tt*1000,
    time_unit="s",
    coordinate_system="normalized",
    provenance_update=list(nested=list(a=4),
                           marker=NULL,normalization="explicit"))
  expect_identical(y$time,tt*1000)
  expect_identical(y$values,replacement)
  expect_identical(y$coordinate_system,"normalized")
  expect_identical(y$time_unit,"s")
  expect_identical(y$curve_ids,x$curve_ids)
  expect_identical(y$dimension_names,x$dimension_names)
  expect_identical(y$metadata,x$metadata)
  expect_identical(y$provenance$source,"raw")
  expect_identical(y$provenance$nested,list(a=4))
  expect_true("marker" %in% names(y$provenance))
  expect_null(y$provenance$marker)
  expect_identical(y$provenance$normalization,"explicit")
  expect_identical(x$values,a)
  expect_identical(x$provenance,initial)
  expect_error(etr_with_values(x,provenance_update=list(a=function()1)),
               "provenance_update")
  expect_error(etr_with_values(x,time=c(2,1,3,4)),
               "strictly increasing")
  expect_error(etr_with_values(x,values=array(1,c(1,4,2))),
               "values dimensions")
})

test_that("Stage 3 transforms now append exactly sourced Python provenance",{
  tt <- c(2,3,4,5)
  a <- array(0,c(2L,length(tt),3L))
  a[1L,,1L] <- c(0,10,20,30)
  a[2L,,1L] <- c(5,15,25,35)
  a[1L,,2L] <- c(1,2,3,4)
  a[2L,,2L] <- c(6,7,8,9)
  original <- list(source="raw",review=list(done=TRUE))
  x <- etr_trajectory_set(tt,a,c("g1","g2"),c("x","y","pupil"),
    coordinate_system="pixels",time_unit="ms",
    provenance=original)
  scaled <- etr_normalize_coordinates(x,width=100,height=200)
  expect_identical(scaled$provenance$coordinate_normalization,
                   list(width=100,height=200))
  expect_identical(scaled$provenance$source,"raw")
  centered <- etr_center_on_landmark(
    scaled,c(0.1,0.2),c(0.3,0.4))
  expect_identical(centered$provenance$landmark_centering,
                   list(per_curve=TRUE))
  norm <- etr_normalize_time_interval(centered,start=-1,end=1)
  expect_identical(norm$provenance$time_normalization,list(
    original_start=2,original_end=5,original_unit="ms",
    new_start=-1,new_end=1))
  expect_identical(norm$provenance$coordinate_normalization,
                   list(width=100,height=200))
  expect_identical(norm$provenance$landmark_centering,
                   list(per_curve=TRUE))
  expect_identical(norm$provenance$review,list(done=TRUE))
  expect_identical(x$provenance,original)
  expect_identical(norm$values[,,3L],x$values[,,3L])
})

test_that("native versioned snapshot restores values units metadata and provenance",{
  tt <- c(.2,.4,1.1,3)
  a <- array(seq_len(2L*4L*2L)*.5,c(2L,4L,2L))
  a[1L,2L,1L] <- NA_real_
  md <- data.frame(subject=c("a","b"),
                   condition=factor(c("treatment","control")))
  original <- list(source="example",missing_policy="preserve")
  x <- etr_trajectory_set(tt,a,c("A","B"),c("x","y"),
    metadata=md,coordinate_system="pixels",
    time_unit="ms",provenance=original)
  frozen <- etr_trajectory_snapshot(x)
  expect_s3_class(frozen,"etr_trajectory_snapshot")
  expect_identical(frozen$schema_version,1L)
  expect_identical(frozen$shape,c(2L,4L,2L))
  expect_identical(etr_restore_trajectory_snapshot(frozen),x)
  file <- tempfile(fileext=".rds")
  on.exit(unlink(file),add=TRUE)
  saveRDS(frozen,file,version=3)
  thawed <- etr_restore_trajectory_snapshot(readRDS(file))
  expect_identical(thawed,x)
  expect_identical(thawed$metadata$condition,md$condition)
  expect_true(is.na(thawed$values[1L,2L,1L]))
  expect_identical(thawed$provenance,original)

  wrong_version <- frozen
  wrong_version$schema_version <- 2L
  expect_error(etr_restore_trajectory_snapshot(wrong_version),"schema_version")
  wrong_shape <- frozen
  wrong_shape$shape <- c(3L,4L,2L)
  expect_error(etr_restore_trajectory_snapshot(wrong_shape),"shape")
  wrong_metadata <- frozen
  wrong_metadata$metadata <- data.frame(subject="a")
  expect_error(etr_restore_trajectory_snapshot(wrong_metadata),
               "metadata")
  wrong_provenance <- frozen
  wrong_provenance$provenance <- list(error=Inf)
  expect_error(etr_restore_trajectory_snapshot(wrong_provenance),
               "provenance")
})

test_that("Python TrajectorySet with_values/subset and Stage 3 provenance match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Independent Python 1.2 trajectory provenance oracle is opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")
  tt <- c(0,.4,1.2,2)
  values <- array(0,dim=c(2L,length(tt),3L))
  values[1L,,1L] <- c(0,100,200,300)
  values[2L,,1L] <- c(10,110,210,310)
  values[1L,,2L] <- c(20,40,60,80)
  values[2L,,2L] <- c(2,4,6,8)
  values[1L,,3L] <- c(2,3,4,5)
  values[2L,,3L] <- c(6,7,8,9)
  metadata <- data.frame(subject=c("p1","p2"),trial=c(1,2))
  provenance <- list(source="lab",decision=list(method="preserve"))
  x <- etr_trajectory_set(tt,values,c("A","B"),c("x","y","pupil"),
    metadata=metadata,coordinate_system="pixels",time_unit="ms",
    provenance=provenance)
  ctor <- etpy_get_export("TrajectorySet")
  pandas <- reticulate::import("pandas",convert=FALSE)
  py_md <- pandas$DataFrame(reticulate::r_to_py(metadata))
  py <- reticulate::py_call(ctor,
    time=tt,values=reticulate::r_to_py(values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    metadata=py_md,
    coordinate_system="pixels",time_unit="ms",
    provenance=reticulate::r_to_py(provenance))
  compare <- function(native,python,tag) {
    expect_identical(native$curve_ids,
      as.character(unlist(et_to_r(python$curve_ids))),info=tag)
    expect_identical(native$dimension_names,
      as.character(unlist(et_to_r(python$dimension_names))),info=tag)
    expect_equal(native$time,as.numeric(et_to_r(python$time)),
                 tolerance=1e-12,info=tag)
    expect_equal(as.vector(native$values),
                 as.vector(et_to_r(python$values)),
                 tolerance=1e-12,info=tag)
    expect_identical(native$coordinate_system,
                     as.character(et_to_r(python$coordinate_system)),
                     info=tag)
    expect_identical(native$time_unit,
                     as.character(et_to_r(python$time_unit)),
                     info=tag)
    expect_equal(native$provenance,et_to_r(python$provenance),
                 info=paste(tag,"provenance"))
  }
  compare(x,py,"source")
  updated <- list(decision=list(method="rescale"),new_key="new")
  native_new <- etr_with_values(x,values+1,
    provenance_update=updated,time_unit="s")
  py_new <- reticulate::py_call(
    reticulate::py_get_attr(py,"with_values"),
    values=reticulate::r_to_py(values+1),
    provenance_update=reticulate::r_to_py(updated),time_unit="s")
  compare(native_new,py_new,"with_values")
  expect_identical(native_new$provenance$decision,
                   list(method="rescale"))

  # Python uses zero-based subset indices; R uses one-based indices.
  subset_r <- etr_subset(x,"B")
  subset_py <- reticulate::py_call(
    reticulate::py_get_attr(py,"subset"),indices=list(1L))
  compare(subset_r,subset_py,"subset by curve")

  stage3 <- list(
    list(r=etr_normalize_coordinates(x,1000,500),
         py=etpy_normalize_coordinates(py,width=1000,height=500)),
    list(r=etr_center_on_landmark(x,10,20),
         py=etpy_center_on_landmark(py,landmark_x=10,landmark_y=20)),
    list(r=etr_normalize_time_interval(x,start=-1,end=3),
         py=etpy_normalize_time(py,start=-1,end=3))
  )
  for(i in seq_along(stage3))
    compare(stage3[[i]]$r,stage3[[i]]$py,
            paste("Stage3 provenance",i))
})
