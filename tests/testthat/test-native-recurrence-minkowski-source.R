# Frozen Python 1.2 recurrence.py: cKDTree Minkowski p=1/2/Inf.
# Native R calculates actual L1/L2/L-infinity geometry, not an alias.
# Published Python output source is pinned by the opt-in second test.
test_that("native recurrence metric geometry is scientifically distinct",{
  times<-0:3
  positions<-rbind(c(0,0),c(1,1),c(2,0),c(3,1))
  values<-array(0,dim=c(2L,4L,2L))
  for(k in seq_len(2L))values[k,,]<-positions
  x<-etr_trajectory_set(times,values,
    curve_ids=c("a","b"),dimension_names=c("x","y"))
  radius<-1.5
  l1<-etr_recurrence_matrix(x,curve="a",radius=radius,
    metric="cityblock")
  l2<-etr_recurrence_matrix(x,curve="a",radius=radius)
  li<-etr_recurrence_matrix(x,curve="a",radius=radius,
    metric="chebyshev")
  expect_identical(l1$metric,"cityblock")
  expect_identical(l2$metric,"euclidean")
  expect_identical(li$metric,"chebyshev")
  expect_false(l1$matrix[1L,2L])
  expect_true(l2$matrix[1L,2L])
  expect_true(li$matrix[1L,2L])
  expect_equal(l1$recurrence_rate,0,tolerance=0)
  expect_true(l2$recurrence_rate>0)
  expect_true(li$recurrence_rate>=l2$recurrence_rate)
  for(z in list(l1,l2,li)){
    expect_identical(z$matrix,t(z$matrix))
    expect_false(any(diag(z$matrix)))
    expect_identical(z$provenance$metric,z$metric)
  }
  a<-rbind(c(0,0),c(2,0))
  b<-rbind(c(1,1),c(2,2))
  cross_l1<-etr_cross_recurrence_matrix(a,b,radius=1.1,
    metric="cityblock")
  cross_l2<-etr_cross_recurrence_matrix(a,b,radius=1.1,
    metric="euclidean")
  cross_inf<-etr_cross_recurrence_matrix(a,b,radius=1.1,
    metric="chebyshev")
  expect_false(any(cross_l1$matrix))
  expect_false(any(cross_l2$matrix))
  expect_identical(sum(cross_inf$matrix),2L)
  expect_identical(cross_inf$metric,"chebyshev")
  expect_error(etr_recurrence_matrix(x,curve="a",radius=1,
    metric="manhattan"),"metric must be one of")
  expect_error(etr_cross_recurrence_matrix(a,b,radius=1,
    metric="L1"),"metric must be one of")
})

test_that("native W4 cityblock and chebyshev agree with frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 Minkowski W4 workflow oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  r_t<-seq(0,1,length.out=25L)
  r_v<-array(0,c(4L,25L,1L))
  for(i in seq_len(4L))r_v[i,,1L]<-
    sin(2*pi*r_t+i/5)+i*r_t/10
  rx<-etr_trajectory_set(r_t,r_v,sprintf("c%02d",1:4),"x",
    coordinate_system="normalized",time_unit="s")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
w4m_t=np.linspace(0,1,25)
w4m_v=np.empty((4,25,1))
for i in range(1,5):
    w4m_v[i-1,:,0]=np.sin(2*np.pi*w4m_t+i/5)+i*w4m_t/10
w4m_x=et.TrajectorySet(
    time=w4m_t,values=w4m_v,
    curve_ids=tuple('c%02d'%i for i in range(1,5)),
    dimension_names=('x',),
    metadata=pd.DataFrame(index=range(4)),
    coordinate_system='normalized',time_unit='s')
")
  metric_names<-c("cityblock","chebyshev")
  metric_fields<-c("recurrence_rate","determinism",
    "mean_diagonal_length","max_diagonal_length","diagonal_entropy",
    "laminarity","trapping_time","max_vertical_length",
    "center_of_recurrence_mass","n_recurrence_points",
    "n_diagonal_lines","n_vertical_lines")
  for(metric in metric_names){
    native<-etr_run_recurrence_workflow(rx,
      list(curve=0L,dimensions="x",embedding_dimension=2L,
        delay=2L,radius=.6,metric=metric,
        theiler_window=1L,min_diagonal_length=2L,
        min_vertical_length=2L))
    python_cfg<-reticulate::py_call(
      etpy_get_export("RecurrenceWorkflowConfig",.namespace="workflows"),
      curve=0L,dimensions=reticulate::r_to_py(list("x")),
      embedding_dimension=2L,delay=2L,radius=.6,
      metric=metric,theiler_window=1L,
      min_diagonal_length=2L,min_vertical_length=2L)
    python<-reticulate::py_call(
      etpy_get_export("run_recurrence_workflow",.namespace="workflows"),
      trajectories=reticulate::py_eval("w4m_x",convert=FALSE),
      config=python_cfg)
    source_matrix<-et_to_r(python$recurrence$matrix$toarray())
    expect_equal(unname(native$recurrence$matrix),
      unname(source_matrix),tolerance=0,
      info=paste("recurrence matrix",metric))
    expect_identical(native$recurrence$metric,metric)
    for(field in metric_fields){
      actual<-as.numeric(native$metrics[[field]])
      target<-as.numeric(reticulate::py_to_r(
        reticulate::py_get_attr(python$metrics,field)))
      if(is.finite(actual)&&is.finite(target)){
        expect_equal(actual,target,tolerance=1e-10,
          info=paste(metric,field))
      }else{
        expect_true(is.na(actual)&&is.na(target),
          info=paste(metric,field,"undefined value"))
      }
    }
    expect_identical(vapply(native$steps,
      function(step)step$name,character(1L)),
      c("delay_embedding","recurrence","rqa"))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("native auto recurrence target policy has source bisection geometry",{
  t<-as.numeric(0:7)
  values<-array(0,c(2L,length(t),2L))
  values[1L,,1L]<-c(0,1,3,4,5,6,8,9)
  values[1L,,2L]<-c(0,0,1,2,1,2,3,4)
  values[2L,,1L]<-c(1,2,2,4,5,7,8,10)
  values[2L,,2L]<-c(1,0,2,3,2,4,5,3)
  x<-etr_trajectory_set(t,values,c("a","b"),c("x","y"),
    coordinate_system="arbitrary",time_unit="s")
  for(metric in c("cityblock","euclidean","chebyshev")){
    for(target in c(.2,.4,.65)){
      z<-etr_recurrence_matrix(x,curve="b",
        target_recurrence_rate=target,theiler=1L,metric=metric)
      expect_s3_class(z,"etr_recurrence")
      expect_identical(z$provenance$radius_policy,"target_recurrence_rate")
      expect_equal(z$target_recurrence_rate,target,tolerance=0)
      expect_true(is.finite(z$radius)&&z$radius>0)
      expect_true(z$recurrence_rate>=0&&z$recurrence_rate<=1)
      expect_false(any(diag(z$matrix)))
      expect_false(any(z$matrix[row(z$matrix)!=col(z$matrix)&
        abs(row(z$matrix)-col(z$matrix))<=1L]))
    }
  }
  expect_error(etr_recurrence_matrix(x,curve="a"),
    "supply exactly one")
  expect_error(etr_recurrence_matrix(x,curve="a",radius=1,
    target_recurrence_rate=.3),"supply exactly one")
  expect_error(etr_recurrence_matrix(x,curve="a",
    target_recurrence_rate=0),"strictly between")
  expect_error(etr_recurrence_matrix(x,curve="a",
    target_recurrence_rate=1),"strictly between")
  expect_equal(etr_recurrence_matrix(x,curve="a",radius=0)$radius,0)
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 target-rate recurrence source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  ctor<-etpy_get_export("TrajectorySet")
  pyx<-reticulate::py_call(ctor,time=reticulate::r_to_py(t),
    values=reticulate::r_to_py(values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  for(metric in c("cityblock","euclidean","chebyshev")){
    for(target in c(.2,.4,.65)){
      native<-etr_recurrence_matrix(x,curve="b",
        target_recurrence_rate=target,theiler=1L,metric=metric)
      py<-reticulate::py_call(etpy_get_export("recurrence_matrix"),
        source=pyx,curve=as.integer(1L),target_recurrence_rate=target,
        theiler_window=as.integer(1L),metric=metric,
        dimensions=as.list(x$dimension_names))
      source_radius<-as.numeric(et_to_r(
        reticulate::py_get_attr(py,"radius")))
      source_rate<-as.numeric(et_to_r(
        reticulate::py_get_attr(py,"achieved_recurrence_rate")))
      source_matrix<-et_to_r(py$matrix$toarray())
      expect_equal(native$radius,source_radius,tolerance=1e-9,
        info=paste("radius",metric,target))
      expect_equal(native$recurrence_rate,source_rate,tolerance=1e-12,
        info=paste("rate",metric,target))
      expect_equal(unname(native$matrix),unname(source_matrix),
        tolerance=0,info=paste("matrix",metric,target))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
