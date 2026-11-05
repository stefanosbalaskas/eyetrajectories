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


test_that("native cross-recurrence source target-rate policy selects all cross pairs",{
  a<-rbind(c(0,0),c(1,1),c(2,0),c(4,3))
  b<-rbind(c(0.5,0.5),c(2,2),c(3,0))
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      z<-etr_cross_recurrence_matrix(a,b,
        target_recurrence_rate=target,metric=metric)
      expect_s3_class(z,"etr_recurrence")
      expect_identical(dim(z$matrix),c(4L,3L))
      expect_identical(z$provenance$radius_policy,
        "target_recurrence_rate")
      expect_equal(z$target_recurrence_rate,target,tolerance=0)
      expect_true(is.finite(z$radius) && z$radius>0)
      expect_equal(z$recurrence_rate,mean(z$matrix),tolerance=0)
      expect_equal(z$eligible_pairs,12L)
      expect_true(z$recurrence_rate>=0 && z$recurrence_rate<=1)
    }
  expect_error(etr_cross_recurrence_matrix(a,b),"exactly one")
  expect_error(etr_cross_recurrence_matrix(a,b,radius=1,
    target_recurrence_rate=.3),"exactly one")
  expect_error(etr_cross_recurrence_matrix(a,b,
    target_recurrence_rate=0),"strictly between")
  expect_error(etr_cross_recurrence_matrix(a,b,
    target_recurrence_rate=1),"strictly between")
  expect_equal(etr_cross_recurrence_matrix(a,b,radius=0)$radius,0)
  tied_a<-matrix(0,nrow=3L,ncol=1L)
  tied_b<-matrix(1,nrow=2L,ncol=1L)
  tied<-etr_cross_recurrence_matrix(tied_a,tied_b,
    target_recurrence_rate=.4)
  # The source algorithm is inclusive and must report achieved 100%:
  # ties make the requested target rate unattainable.
  expect_equal(tied$radius,1,tolerance=1e-12)
  expect_equal(tied$recurrence_rate,1,tolerance=0)
  expect_true(all(tied$matrix))
  expect_error(etr_cross_recurrence_matrix(
    tied_a,tied_a,target_recurrence_rate=.4),"non-constant")
})

test_that("frozen Python 1.2 cross-recurrence target rate matches native dense matrix",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 cross-recurrence target source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  a<-rbind(c(0,0),c(1,1),c(2,0),c(4,3))
  b<-rbind(c(.5,.5),c(2,2),c(3,0))
  make_source<-function(points,curve_id) {
    ctor<-etpy_get_export("TrajectorySet")
    values<-array(0,c(1L,nrow(points),2L))
    values[1L,,]<-points
    reticulate::py_call(ctor,
      time=reticulate::r_to_py(as.numeric(seq_len(nrow(points))-1L)),
      values=reticulate::r_to_py(values),
      curve_ids=as.list(curve_id),
      dimension_names=as.list(c("x","y")),
      coordinate_system="arbitrary",time_unit="s")
  }
  pa<-make_source(a,"a")
  pb<-make_source(b,"b")
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      ours<-etr_cross_recurrence_matrix(a,b,
        target_recurrence_rate=target,metric=metric)
      theirs<-reticulate::py_call(etpy_get_export("cross_recurrence_matrix"),
        source_a=pa,source_b=pb,curve_a=as.integer(0L),
        curve_b=as.integer(0L),target_recurrence_rate=target,
        metric=metric,dimensions_a=as.list(c("x","y")),
        dimensions_b=as.list(c("x","y")))
      radius<-as.numeric(et_to_r(
        reticulate::py_get_attr(theirs,"radius")))
      achieved<-as.numeric(et_to_r(
        reticulate::py_get_attr(theirs,"achieved_recurrence_rate")))
      matrix_source<-et_to_r(theirs$matrix$toarray())
      expect_equal(ours$radius,radius,tolerance=1e-9,
        info=paste("radius",metric,target))
      expect_equal(ours$recurrence_rate,achieved,tolerance=1e-12,
        info=paste("rate",metric,target))
      expect_equal(unname(ours$matrix),unname(matrix_source),
        tolerance=0,info=paste("matrix",metric,target))
    }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("native cross recurrence accepts explicit source trajectory state names",{
  points_a<-rbind(c(0,0),c(1,1),c(2,0),c(4,3))
  points_b<-rbind(c(.5,.5),c(2,2),c(3,0))
  make_traj<-function(points,id,cs="arbitrary",unit="s",names=c("x","y")){
    values<-array(0,c(1L,nrow(points),2L))
    values[1L,,]<-points
    etr_trajectory_set(as.numeric(seq_len(nrow(points))-1L),
      values,curve_ids=id,dimension_names=names,
      coordinate_system=cs,time_unit=unit,
      provenance=list(origin="independent_test_fixture"))
  }
  a<-make_traj(points_a,"left")
  b<-make_traj(points_b,"right")
  for(metric in c("cityblock","euclidean","chebyshev")){
    for(target in c(.2,.4,.65)){
      native<-etr_cross_recurrence_matrix(a,b,
        curve_a="left",curve_b="right",dimensions_a=c("x","y"),
        dimensions_b=c("x","y"),
        target_recurrence_rate=target,metric=metric)
      baseline<-etr_cross_recurrence_matrix(points_a,points_b,
        target_recurrence_rate=target,metric=metric)
      expect_equal(native$radius,baseline$radius,tolerance=0)
      expect_identical(native$matrix,baseline$matrix)
      expect_equal(native$recurrence_rate,baseline$recurrence_rate,
        tolerance=0)
      expect_identical(native$curve_ids,c("left","right"))
      expect_equal(native$time_a,a$time,tolerance=0)
      expect_equal(native$time_b,b$time,tolerance=0)
      expect_identical(native$time_unit,"s")
      expect_identical(native$state_dimension,2L)
      expect_identical(native$provenance$source_a$source_kind,"TrajectorySet")
      expect_identical(native$provenance$source_a$state_names,c("x","y"))
      expect_identical(native$provenance$time_alignment,"none")
    }
  }
  expect_error(etr_cross_recurrence_matrix(a,b,radius=1),
    "curve identifiers")
  expect_error(etr_cross_recurrence_matrix(a,b,
    curve_a="left",curve_b="right",radius=1),"dimension selections")
  expect_error(etr_cross_recurrence_matrix(a,b,curve_a="left",curve_b="right",
    dimensions_a="x",dimensions_b="y",radius=1),"same named state")
  expect_error(etr_cross_recurrence_matrix(a,
    make_traj(points_b,"right",cs="pixels"),curve_a="left",curve_b="right",
    dimensions_a="x",dimensions_b="x",radius=1),"coordinate_system")
  expect_error(etr_cross_recurrence_matrix(a,
    make_traj(points_b,"right",unit="ms"),curve_a="left",curve_b="right",
    dimensions_a="x",dimensions_b="x",radius=1),"same time_unit")
  expect_error(etr_cross_recurrence_matrix(a,b,curve_a="missing",
    curve_b="right",dimensions_a="x",dimensions_b="x",radius=1),
    "curve ID")
  expect_error(etr_cross_recurrence_matrix(a,points_b,
    curve_a="left",curve_b="right",dimensions_a="x",
    dimensions_b="x",radius=1),"both be trajectory sets")
})

test_that("direct Python 1.2 cross recurrence confirms source-object time and state contract",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python TrajectorySet cross recurrence input parity opt-in")
  expect_identical(et_python_version(),"1.2.0")
  make_source<-function(points,id){
    values<-array(0,c(1L,nrow(points),2L))
    values[1L,,]<-points
    native<-etr_trajectory_set(as.numeric(seq_len(nrow(points))-1L),
      values,curve_ids=id,dimension_names=c("x","y"),
      coordinate_system="arbitrary",time_unit="s")
    python<-reticulate::py_call(etpy_get_export("TrajectorySet"),
      time=reticulate::r_to_py(native$time),
      values=reticulate::r_to_py(native$values),
      curve_ids=as.list(native$curve_ids),
      dimension_names=as.list(native$dimension_names),
      coordinate_system="arbitrary",time_unit="s")
    list(native=native,python=python)
  }
  a<-make_source(rbind(c(0,0),c(1,1),c(2,0),c(4,3)),"a")
  b<-make_source(rbind(c(.5,.5),c(2,2),c(3,0)),"b")
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      ours<-etr_cross_recurrence_matrix(a$native,b$native,
        curve_a="a",curve_b="b",dimensions_a=c("x","y"),
        dimensions_b=c("x","y"),target_recurrence_rate=target,
        metric=metric)
      theirs<-reticulate::py_call(etpy_get_export("cross_recurrence_matrix"),
        source_a=a$python,source_b=b$python,
        curve_a="a",curve_b="b",dimensions_a=as.list(c("x","y")),
        dimensions_b=as.list(c("x","y")),
        target_recurrence_rate=target,metric=metric)
      expect_equal(ours$radius,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"radius"))),
        tolerance=1e-9)
      expect_equal(ours$recurrence_rate,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,
          "achieved_recurrence_rate"))),tolerance=1e-12)
      expect_equal(unname(ours$matrix),
        unname(et_to_r(theirs$matrix$toarray())),tolerance=0)
      expect_equal(ours$time_a,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"time_a"))),
        tolerance=0)
      expect_equal(ours$time_b,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"time_b"))),
        tolerance=0)
      expect_identical(ours$curve_ids,c("a","b"))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("native source delay-embedding cross recurrence preserves state semantics",{
  t<-as.numeric(0:9)
  make_trajectory<-function(offset,id){
    values<-array(0,c(1L,length(t),2L))
    values[1L,,1L]<-c(0,1,3,4,5,8,9,10,12,13)+offset
    values[1L,,2L]<-c(0,1,1,3,3,4,6,7,8,10)+offset
    etr_trajectory_set(t,values,curve_ids=id,
      dimension_names=c("x","y"),
      coordinate_system="arbitrary",time_unit="s")
  }
  a<-etr_delay_embed_trajectory(make_trajectory(0,"A"),
    embedding_dimension=2L,delay=1L,dimensions=c("x","y"))
  b<-etr_delay_embed_trajectory(make_trajectory(.5,"B"),
    embedding_dimension=2L,delay=1L,dimensions=c("x","y"))
  expect_s3_class(a,"etr_delay_embedding_set")
  expect_s3_class(b,"etr_delay_embedding_set")
  raw_a<-matrix(a$values[1L,,,drop=FALSE],nrow=length(a$time))
  raw_b<-matrix(b$values[1L,,,drop=FALSE],nrow=length(b$time))
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      z<-etr_cross_recurrence_matrix(a,b,
        curve_a="A",curve_b="B",target_recurrence_rate=target,
        metric=metric)
      baseline<-etr_cross_recurrence_matrix(raw_a,raw_b,
        target_recurrence_rate=target,metric=metric)
      expect_equal(z$radius,baseline$radius,tolerance=0)
      expect_identical(z$matrix,baseline$matrix)
      expect_equal(z$recurrence_rate,baseline$recurrence_rate,tolerance=0)
      expect_identical(z$curve_ids,c("A","B"))
      expect_identical(z$provenance$source_a$source_kind,
        "DelayEmbeddingResult")
      expect_identical(z$provenance$source_b$state_names,
        b$state_names)
      expect_equal(z$time_a,a$time,tolerance=0)
      expect_equal(z$time_b,b$time,tolerance=0)
    }
  expect_error(etr_cross_recurrence_matrix(a,b,
    curve_a="A",curve_b="B",radius=.8,dimensions_a=a$state_names),
    "dimensions_a cannot be supplied")
  wrong_dim<-b;wrong_dim$embedding_dimension<-3L
  expect_error(etr_cross_recurrence_matrix(a,wrong_dim,
    curve_a="A",curve_b="B",radius=.8),"same embedding_dimension")
  wrong_lag<-b;wrong_lag$delay_samples<-2L
  expect_error(etr_cross_recurrence_matrix(a,wrong_lag,
    curve_a="A",curve_b="B",radius=.8),"same delay_samples")
  wrong_physical<-b;wrong_physical$delay_time<-1.5
  expect_error(etr_cross_recurrence_matrix(a,wrong_physical,
    curve_a="A",curve_b="B",radius=.8),"same physical delay")
})

test_that("frozen Python DelayEmbeddingResult cross-source numerical and schema oracle",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 embedded source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  make_source<-function(offset,id){
    t<-as.numeric(0:9)
    values<-array(0,c(1L,length(t),2L))
    values[1L,,1L]<-c(0,1,3,4,5,8,9,10,12,13)+offset
    values[1L,,2L]<-c(0,1,1,3,3,4,6,7,8,10)+offset
    native<-etr_trajectory_set(t,values,id,c("x","y"),
      coordinate_system="arbitrary",time_unit="s")
    python<-reticulate::py_call(etpy_get_export("TrajectorySet"),
      time=reticulate::r_to_py(t),values=reticulate::r_to_py(values),
      curve_ids=as.list(id),dimension_names=as.list(c("x","y")),
      coordinate_system="arbitrary",time_unit="s")
    rn<-etr_delay_embed_trajectory(native,
      embedding_dimension=2L,delay=1L,dimensions=c("x","y"))
    py<-reticulate::py_call(etpy_get_export("delay_embed_trajectory"),
      trajectories=python,embedding_dimension=as.integer(2L),
      delay=as.integer(1L),dimensions=as.list(c("x","y")))
    list(native=rn,python=py)
  }
  a<-make_source(0,"A")
  b<-make_source(.5,"B")
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      ours<-etr_cross_recurrence_matrix(a$native,b$native,
        curve_a="A",curve_b="B",target_recurrence_rate=target,
        metric=metric)
      theirs<-reticulate::py_call(
        etpy_get_export("cross_recurrence_matrix"),
        source_a=a$python,source_b=b$python,curve_a="A",curve_b="B",
        metric=metric,target_recurrence_rate=target)
      expect_equal(ours$radius,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"radius"))),
        tolerance=1e-9)
      expect_equal(ours$recurrence_rate,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,
          "achieved_recurrence_rate"))),tolerance=1e-12)
      expect_equal(unname(ours$matrix),
        unname(et_to_r(theirs$matrix$toarray())),tolerance=0)
      expect_equal(ours$time_a,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"time_a"))),
        tolerance=0)
      expect_equal(ours$time_b,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"time_b"))),
        tolerance=0)
      expect_identical(ours$provenance$source_a$source_kind,
        "DelayEmbeddingResult")
    }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("auto recurrence supports explicit ordered source channels and physical Theiler time",{
  t<-as.numeric(0:8)
  v<-array(0,c(2L,length(t),3L))
  for(k in seq_len(2L)){
    v[k,,1L]<-c(0,1,3,4,6,7,8,10,12)+k/5
    v[k,,2L]<-c(0,2,1,3,2,5,4,7,6)+k/3
    v[k,,3L]<-c(1,3,2,2,4,5,8,7,9)+k/4
  }
  x<-etr_trajectory_set(t,v,c("left","right"),c("x","y","z"),
    coordinate_system="arbitrary",time_unit="s")
  order<-c("z","x")
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      z<-etr_recurrence_matrix(x,curve="right",
        target_recurrence_rate=target,theiler=1,
        theiler_window_units="s",dimensions=order,metric=metric)
      selected<-etr_trajectory_set(t,
        v[,,match(order,x$dimension_names),drop=FALSE],
        x$curve_ids,order,coordinate_system="arbitrary",time_unit="s")
      reference<-etr_recurrence_matrix(selected,curve="right",
        target_recurrence_rate=target,theiler=1,metric=metric)
      expect_equal(z$radius,reference$radius,tolerance=0)
      expect_identical(z$matrix,reference$matrix)
      expect_equal(z$recurrence_rate,reference$recurrence_rate,tolerance=0)
      expect_identical(z$state_dimension,2L)
      expect_identical(z$provenance$source_info$state_names,order)
      expect_identical(z$theiler,1L)
    }
  expect_error(etr_recurrence_matrix(x,curve=1L,radius=1,
    dimensions=c("x","x")),"distinct")
  expect_error(etr_recurrence_matrix(x,curve=1L,radius=1,
    dimensions="missing"),"known")
  missing<-x;missing$values[1L,1L,2L]<-NA_real_
  expect_s3_class(etr_recurrence_matrix(missing,curve="left",
    radius=1,dimensions="x"),"etr_recurrence")
  expect_error(etr_recurrence_matrix(missing,curve="left",radius=1),
    "complete observations")
})

test_that("frozen Python 1.2 auto recurrence matches channel-order and physical-time semantics",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 channel selection oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  t<-as.numeric(0:8)
  v<-array(0,c(2L,length(t),3L))
  for(k in seq_len(2L)){
    v[k,,1L]<-c(0,1,3,4,6,7,8,10,12)+k/5
    v[k,,2L]<-c(0,2,1,3,2,5,4,7,6)+k/3
    v[k,,3L]<-c(1,3,2,2,4,5,8,7,9)+k/4
  }
  x<-etr_trajectory_set(t,v,c("left","right"),c("x","y","z"),
    coordinate_system="arbitrary",time_unit="s")
  py<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(t),values=reticulate::r_to_py(v),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      ours<-etr_recurrence_matrix(x,curve="right",
        target_recurrence_rate=target,theiler=1L,
        theiler_window_units="s",dimensions=c("z","x"),metric=metric)
      theirs<-reticulate::py_call(etpy_get_export("recurrence_matrix"),
        source=py,curve="right",target_recurrence_rate=target,
        metric=metric,theiler_window=as.integer(1L),
        theiler_window_units="s",dimensions=as.list(c("z","x")))
      expect_equal(ours$radius,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"radius"))),
        tolerance=1e-9)
      expect_equal(ours$recurrence_rate,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,
          "achieved_recurrence_rate"))),tolerance=1e-12)
      expect_equal(unname(ours$matrix),
        unname(et_to_r(theirs$matrix$toarray())),tolerance=0)
      expect_identical(ours$provenance$source_info$state_names,c("z","x"))
    }
})

test_that("native embedded auto recurrence matches frozen delay-state source",{
  t<-as.numeric(0:9)
  v<-array(0,c(2L,length(t),2L))
  for(k in seq_len(2L)){
    v[k,,1L]<-c(0,1,3,4,5,8,9,10,12,13)+k/3
    v[k,,2L]<-c(0,1,1,3,3,4,6,7,8,10)+k/5
  }
  x<-etr_trajectory_set(t,v,c("A","B"),c("x","y"),
    coordinate_system="arbitrary",time_unit="s")
  embedded<-etr_delay_embed_trajectory(x,embedding_dimension=2L,
    delay=1L,dimensions=c("x","y"))
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      z<-etr_recurrence_matrix(embedded,curve="B",
        target_recurrence_rate=target,theiler=1L,metric=metric)
      proxy<-etr_trajectory_set(embedded$time,embedded$values,
        embedded$curve_ids,embedded$state_names,
        coordinate_system=embedded$coordinate_system,
        time_unit=embedded$time_unit)
      baseline<-etr_recurrence_matrix(proxy,curve="B",
        target_recurrence_rate=target,theiler=1L,metric=metric)
      expect_equal(z$radius,baseline$radius,tolerance=0)
      expect_identical(z$matrix,baseline$matrix)
      expect_equal(z$recurrence_rate,baseline$recurrence_rate,tolerance=0)
      expect_identical(z$provenance$source_info$source_kind,
        "DelayEmbeddingResult")
      expect_identical(z$provenance$source_info$state_names,
        embedded$state_names)
    }
  expect_error(etr_recurrence_matrix(embedded,curve="A",
    radius=1,dimensions=embedded$state_names),
    "dimensions cannot be supplied")
})

test_that("frozen Python 1.2 embedded recurrence direct numerical oracle",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 embedded recurrence oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  t<-as.numeric(0:9)
  v<-array(0,c(2L,length(t),2L))
  for(k in seq_len(2L)){
    v[k,,1L]<-c(0,1,3,4,5,8,9,10,12,13)+k/3
    v[k,,2L]<-c(0,1,1,3,3,4,6,7,8,10)+k/5
  }
  x<-etr_trajectory_set(t,v,c("A","B"),c("x","y"),
    coordinate_system="arbitrary",time_unit="s")
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(t),values=reticulate::r_to_py(v),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  native_embedded<-etr_delay_embed_trajectory(x,
    embedding_dimension=2L,delay=1L,dimensions=c("x","y"))
  py_embedded<-reticulate::py_call(etpy_get_export("delay_embed_trajectory"),
    trajectories=pyx,embedding_dimension=as.integer(2L),
    delay=as.integer(1L),dimensions=as.list(c("x","y")))
  for(metric in c("cityblock","euclidean","chebyshev"))
    for(target in c(.2,.4,.65)){
      ours<-etr_recurrence_matrix(native_embedded,curve="B",
        target_recurrence_rate=target,theiler=1L,metric=metric)
      theirs<-reticulate::py_call(etpy_get_export("recurrence_matrix"),
        source=py_embedded,curve="B",target_recurrence_rate=target,
        theiler_window=as.integer(1L),metric=metric)
      expect_equal(ours$radius,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,"radius"))),
        tolerance=1e-9)
      expect_equal(ours$recurrence_rate,
        as.numeric(et_to_r(reticulate::py_get_attr(theirs,
          "achieved_recurrence_rate"))),tolerance=1e-12)
      expect_equal(unname(ours$matrix),
        unname(et_to_r(theirs$matrix$toarray())),tolerance=0)
      expect_identical(ours$provenance$source_info$source_kind,
        "DelayEmbeddingResult")
    }
})


test_that("radius profiles accept source-selected channels and embedded states",{
  t<-as.numeric(0:9)
  v<-array(0,c(2L,10L,3L))
  for(k in 1:2){
    v[k,,1]<-c(0,1,3,4,5,8,9,10,12,13)+k/3
    v[k,,2]<-c(0,1,1,3,3,4,6,7,8,10)+k/5
    v[k,,3]<-c(1,2,4,7,3,5,8,6,9,10)+k/7
  }
  x<-etr_trajectory_set(t,v,c("A","B"),c("x","y","z"),
    coordinate_system="arbitrary",time_unit="s")
  radii<-c(.25,1,2,4,8,20)
  for(m in c("euclidean","cityblock","chebyshev")){
    a<-etr_recurrence_radius_profile(x,"B",radii,metric=m,
      theiler_window=1L,dimensions=c("z","x"))
    y<-etr_trajectory_set(t,v[,,c(3,1),drop=FALSE],
      c("A","B"),c("z","x"),time_unit="s")
    q<-etr_recurrence_radius_profile(y,"B",radii,metric=m,
      theiler_window=1L)
    expect_equal(a$table,q$table,tolerance=0)
    expect_identical(a$provenance$state_names,c("z","x"))
  }
  missing<-x;missing$values[2,1,2]<-NA_real_
  expect_s3_class(etr_recurrence_radius_profile(missing,"B",
    radii,dimensions=c("z","x")),"etr_recurrence_radius_profile")
  expect_error(etr_recurrence_radius_profile(missing,"B",radii),
    "complete observations")
  missing<-x;missing$values[2,1,1]<-NA_real_
  expect_error(etr_recurrence_radius_profile(missing,"B",radii,
    dimensions="x"),"complete finite selected states")
  embedding<-etr_delay_embed_trajectory(x,embedding_dimension=2L,
    delay=1L,dimensions=c("x","y"))
  e<-etr_recurrence_radius_profile(embedding,"B",radii,
    theiler_window=1L)
  proxy<-etr_trajectory_set(embedding$time,embedding$values,
    embedding$curve_ids,embedding$state_names,
    time_unit=embedding$time_unit)
  expect_equal(e$table,etr_recurrence_radius_profile(proxy,"B",
    radii,theiler_window=1L)$table,tolerance=0)
  expect_identical(e$provenance$source_kind,"DelayEmbeddingResult")
  expect_error(etr_recurrence_radius_profile(embedding,"B",
    radii,dimensions=embedding$state_names),"dimensions cannot be supplied")
})


test_that("frozen Python 1.2 recurrence radius-profile state CDF agrees",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python radius-profile source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  t<-as.numeric(0:9)
  v<-array(0,c(2L,10L,3L))
  for(k in 1:2){
    v[k,,1]<-c(0,1,3,4,5,8,9,10,12,13)+k/3
    v[k,,2]<-c(0,1,1,3,3,4,6,7,8,10)+k/5
    v[k,,3]<-c(1,2,4,7,3,5,8,6,9,10)+k/7
  }
  x<-etr_trajectory_set(t,v,c("A","B"),c("x","y","z"),
    coordinate_system="arbitrary",time_unit="s")
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(t),values=reticulate::r_to_py(v),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  radii<-c(.25,1,2,4,8,20)
  for(m in c("euclidean","cityblock","chebyshev")){
    ours<-etr_recurrence_radius_profile(x,"B",radii,
      metric=m,theiler_window=1L,dimensions=c("z","x"))
    theirs<-reticulate::py_call(etpy_get_export("recurrence_radius_profile"),
      source=pyx,curve="B",radii=as.list(radii),metric=m,
      theiler_window=as.integer(1L),dimensions=as.list(c("z","x")))
    other<-as.data.frame(et_to_r(reticulate::py_get_attr(theirs,"table")))
    for(col in names(ours$table))
      expect_equal(as.numeric(ours$table[[col]]),
        as.numeric(other[[col]]),tolerance=1e-12,info=paste(m,col))
  }
  native_embedding<-etr_delay_embed_trajectory(x,
    embedding_dimension=2L,delay=1L,dimensions=c("x","y"))
  py_embedding<-reticulate::py_call(etpy_get_export("delay_embed_trajectory"),
    trajectories=pyx,embedding_dimension=as.integer(2L),
    delay=as.integer(1L),dimensions=as.list(c("x","y")))
  ours<-etr_recurrence_radius_profile(native_embedding,"B",radii,
    theiler_window=1L)
  theirs<-reticulate::py_call(etpy_get_export("recurrence_radius_profile"),
    source=py_embedding,curve="B",radii=as.list(radii),
    theiler_window=as.integer(1L))
  other<-as.data.frame(et_to_r(reticulate::py_get_attr(theirs,"table")))
  for(col in names(ours$table))
    expect_equal(as.numeric(ours$table[[col]]),
      as.numeric(other[[col]]),tolerance=1e-12,info=col)
})
