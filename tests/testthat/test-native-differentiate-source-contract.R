# Frozen Python 1.2 kinematics.py::differentiate_trajectories
# Direct first/second derivative numerical source-contract witnesses.
# Pinned Python source: c1cd95ad718327550f7e55393ff38582872f7a94
# Developer fixture evidence only; not independent scientific certification.

.etr_derivative_source_fixture<-function() {
  t<-c(0,.11,.4,.8,1.4,2)
  v<-array(0,c(2L,length(t),3L))
  for(i in 1:2) {
    v[i,,1L]<-i*1.5+t^2+0.1*t
    v[i,,2L]<--i+t^3
    v[i,,3L]<-3*i+0.4*t
  }
  etr_trajectory_set(t,v,curve_ids=c("a","b"),
    dimension_names=c("x","y","pupil"),
    metadata=data.frame(participant=c("p1","p2")),
    coordinate_system="pixels",time_unit="s",
    provenance=list(source="synthetic_derivative",
      provenance_version=1L))
}

test_that("native source differentiation reproduces first/second R gradients",{
  x<-.etr_derivative_source_fixture()
  first<-etr_differentiate_trajectories(x)
  second<-etr_differentiate_trajectories(x,order=2L)
  expect_equal(first$values,etr_velocity(x)$values,tolerance=1e-12)
  expect_equal(second$values,etr_acceleration(x)$values,tolerance=1e-12)
  expect_identical(first$dimension_names,
    c("x_velocity","y_velocity","pupil_velocity"))
  expect_identical(second$dimension_names,
    c("x_acceleration","y_acceleration","pupil_acceleration"))
  for(i in seq_len(2L)) {
    expect_equal(first$values[i,,1L],2*x$time+0.1,tolerance=1e-10)
    expect_equal(second$values[i,,1L],
      rep(2,length(x$time)),tolerance=1e-9)
    expect_equal(first$values[i,,3L],
      rep(.4,length(x$time)),tolerance=1e-10)
    expect_equal(second$values[i,,3L],
      rep(0,length(x$time)),tolerance=1e-9)
  }
})

test_that("source differentiation retains trajectory metadata and derivative audit",{
  x<-.etr_derivative_source_fixture()
  for(k in c(1L,2L)) {
    z<-etr_differentiate_trajectories(x,k)
    expect_identical(z$time,x$time)
    expect_identical(z$curve_ids,x$curve_ids)
    expect_identical(z$metadata,x$metadata)
    expect_identical(z$coordinate_system,x$coordinate_system)
    expect_identical(z$time_unit,x$time_unit)
    expect_identical(z$provenance$source,"synthetic_derivative")
    expect_identical(z$provenance$provenance_version,1L)
    expect_identical(z$provenance$derivative$order,k)
    expect_identical(z$provenance$derivative$method,"numpy_gradient")
    expect_identical(z$provenance$derivative$smoothing,FALSE)
  }
  expect_null(x$provenance$derivative)
  expect_identical(etr_differentiate_trajectories(x,TRUE)$values,
    etr_differentiate_trajectories(x,1L)$values)
  expect_equal(etr_differentiate_trajectories(x,2.0)$values,
    etr_differentiate_trajectories(x,2L)$values,tolerance=0)
})

test_that("source differentiation rejects unsupported derivative orders and grids",{
  x<-.etr_derivative_source_fixture()
  for(k in list(0L,3L,FALSE,1.5,"2",NA_real_,Inf))
    expect_error(etr_differentiate_trajectories(x,k),"order must be 1 or 2")
  short<-etr_trajectory_set(c(0,1),array(0,c(1L,2L,1L)))
  expect_error(etr_differentiate_trajectories(short),
    "at least three time samples")
  missing<-x;missing$values[1L,2L,1L]<-NA_real_
  expect_error(etr_differentiate_trajectories(missing),
    "complete observations required")
  mapped<-etr_native_parity_catalog()
  row<-mapped[mapped$python_name=="differentiate_trajectories" &
    mapped$namespace=="root",,drop=FALSE]
  expect_identical(nrow(row),1L)
  expect_identical(row$native_r_candidate,"etr_differentiate_trajectories")
  expect_false(row$one_to_one_native_contract_complete)
})

test_that("frozen Python 1.2 first and second derivative numerical oracles agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python differentiate_trajectories direct source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_derivative_source_fixture()
  py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="pixels",time_unit="s",
    provenance=reticulate::r_to_py(
      list(source="synthetic_derivative",provenance_version=1L)))
  for(k in c(1L,2L)) {
    native<-etr_differentiate_trajectories(x,order=k)
    py<-reticulate::py_call(etpy_get_export("differentiate_trajectories"),
      trajectories=py_x,order=k)
    expect_equal(unname(native$values),unname(et_to_r(py$values)),
      tolerance=1e-10)
    expect_identical(native$dimension_names,
      as.character(unlist(et_to_r(py$dimension_names))))
    expect_identical(native$coordinate_system,
      as.character(et_to_r(py$coordinate_system)))
    expect_identical(native$provenance$derivative$order,
      as.integer(et_to_r(py$provenance$get("derivative")$get("order"))))
    expect_identical(native$provenance$derivative$method,
      as.character(et_to_r(py$provenance$get("derivative")$get("method"))))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
