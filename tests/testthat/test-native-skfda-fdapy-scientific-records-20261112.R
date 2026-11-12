# Frozen Python 1.2 source-constructor mapping, not Python backend class parity.
# backends.py::to_skfda_grid and sparse.py::to_fdapy_irregular
# frozen commit c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_dual_data_fixture <- function(){
  tt<-c(0,.5,1)
  vv<-array(0,c(3L,3L,2L))
  for(i in seq_len(3L)){
    vv[i,,1L]<-i+c(.01,.02,.03)
    vv[i,,2L]<-i*c(.1,.2,.3)
  }
  list(time=tt,values=vv,
    dense=etr_trajectory_set(tt,vv,c("c1","c2","c3"),
      c("x","y"),time_unit="s"))
}

test_that("FDataGrid source constructor is value preserving and retains domain structure",{
  fixture<-.etr_dual_data_fixture()
  old<-etr_to_skfda_grid(fixture$dense)
  expect_s3_class(old,"etr_native_functional_grid")
  expect_null(old$source_constructor)
  got<-etr_to_skfda_grid(fixture$dense,strict_source_record=TRUE)
  expect_s3_class(got,"etr_skfda_fdatagrid_scientific_record")
  expect_s3_class(got,"etr_native_functional_grid")
  expect_identical(got$values,old$values)
  expect_identical(got$time,old$time)
  expect_identical(names(got$source_constructor),
    c("data_matrix","grid_points","dataset_name","coordinate_names"))
  expect_identical(got$source_constructor$data_matrix,fixture$values)
  expect_identical(got$source_constructor$grid_points,fixture$time)
  expect_identical(got$source_constructor$dataset_name,
    "eyetrajectoriespy trajectories")
  expect_identical(got$source_constructor$coordinate_names,c("x","y"))
  expect_identical(got$source_normalized_grid_points,list(fixture$time))
  expect_equal(unname(got$source_domain_range),matrix(c(0,1),1L,2L))
  expect_identical(got$source_n_samples,3L)
  expect_identical(got$source_codomain_dimension,2L)
  expect_identical(got$source_domain_dimension,1L)
  expect_identical(got$source_curve_indices,c(0L,1L,2L))
  expect_false(got$interpolation_performed)
  expect_false(got$matplotlib_or_python_object_identity)
  expect_false(got$independently_source_certified)
  expect_null(got$backend_object)
  expect_error(etr_to_skfda_grid(fixture$dense,strict_source_record=NA),
    "strict_source_record")
  expect_error(etr_to_skfda_grid(fixture$dense,strict_source_record=1L),
    "strict_source_record")
})

test_that("FDataGrid source preserves declared missing values without imputation",{
  z<-.etr_dual_data_fixture()
  z$values[2L,2L,1L]<-NaN
  tr<-etr_trajectory_set(z$time,z$values,c("c1","c2","c3"),
    c("x","y"),time_unit="s",python_boundary_mode=TRUE)
  got<-etr_to_skfda_grid(tr,strict_source_record=TRUE)
  expect_true(is.nan(got$source_constructor$data_matrix[2L,2L,1L]))
  expect_identical(got$source_constructor$data_matrix,tr$values)
  expect_true(is.finite(got$source_constructor$data_matrix[3L,2L,1L]))
})

test_that("FDApy source maps per-curve irregular coordinates with zero-based keys",{
  time<-list(c(0,.4),c(.03,.48,.92),c(.1,.35,.7,1.1))
  values<-lapply(seq_along(time),function(i){
    cbind(x=sin(time[[i]]*i),y=rep(i,length(time[[i]])))
  })
  values[[1L]][1L,2L]<-NA_real_ # unrelated dimension is allowed.
  tr<-etr_irregular_trajectory_set(time,values,
    curve_ids=c("A","B","C"),dimension_names=c("x","y"),
    time_unit="s")
  strict<-etr_to_fdapy_irregular(tr,"x",strict_source_record=TRUE)
  expect_s3_class(strict,"etr_fdapy_irregular_scientific_record")
  expect_identical(strict$python_integer_keys,c(0L,1L,2L))
  expect_identical(names(strict$argvals),c("0","1","2"))
  expect_identical(names(strict$values),c("0","1","2"))
  expect_identical(strict$source_sample_counts,c(2L,3L,4L))
  expect_identical(strict$dimension_index_zero_based,0L)
  expect_identical(strict$source_input_curve_order,c("A","B","C"))
  for(i in seq_along(time)){
    expect_identical(strict$argvals[[i]]$input_dim_0,time[[i]])
    expect_identical(strict$values[[i]],as.numeric(values[[i]][,1L]))
  }
  expect_identical(strict$source_constructor_classes[["result"]],
    "FDApy.IrregularFunctionalData")
  expect_false(strict$interpolation_performed)
  expect_false(strict$source_equivalent)
  expect_false(strict$independently_source_certified)
  expect_null(strict$backend_object)
  expect_error(etr_to_fdapy_irregular(tr,"x"),
    "at least 3 samples per curve")
  # Legacy R fdapace path still handles its declared >=3-visit domain.
  time_three<-list(time[[2L]],time[[3L]],c(0,.3,.9))
  values_three<-list(values[[2L]],values[[3L]],
    cbind(x=c(.1,.2,.3),y=c(1,2,3)))
  tr_three<-etr_irregular_trajectory_set(time_three,values_three,
    c("B","C","D"),c("x","y"),time_unit="s")
  old<-etr_to_fdapy_irregular(tr_three,"x")
  expect_s3_class(old,"etr_sparse_curves")
  expect_identical(old$times,time_three)
})

test_that("FDApy source raises on selected missing data and wrong channels",{
  tt<-list(c(0,.5),c(.1,.6))
  vv<-list(matrix(c(1,2),ncol=1L),matrix(c(3,NA_real_),ncol=1L))
  z<-etr_irregular_trajectory_set(tt,vv,c("A","B"),"x")
  expect_error(etr_to_fdapy_irregular(z,"x",
    strict_source_record=TRUE),"finite and observed")
  expect_error(etr_to_fdapy_irregular(z,"not_found",
    strict_source_record=TRUE),"dimension")
  expect_error(etr_to_fdapy_irregular(z,"x",
    strict_source_record=1L),"strict_source_record")
})

test_that("frozen Python 1.2 public converters supply the exact scientific constructor arrays",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 public converter oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  # These minimal dependency stubs capture how the actual frozen Python
  # public functions call optional backend constructors. They do NOT test
  # actual scikit-fda/FDApy classes, numerical projection or estimators.
  reticulate::py_run_string("
import sys,types,numpy as np,pandas as pd
import eyetrajectoriespy as et
class _CaptureGrid:
    def __init__(self,**kwargs): self.kwargs=kwargs
fake_skfda=types.ModuleType('skfda')
fake_skfda.FDataGrid=_CaptureGrid
sys.modules['skfda']=fake_skfda
_gv=np.arange(18.,dtype=float).reshape(3,3,2)
_gt=np.array([0.,.5,1.])
_gtr=et.TrajectorySet(time=_gt,values=_gv,
    curve_ids=('c1','c2','c3'),dimension_names=('x','y'))
_gpy=et.to_skfda_grid(_gtr)
assert isinstance(_gpy,_CaptureGrid)
class _DenseArgvals(dict):pass
class _IrregularArgvals(dict):pass
class _IrregularValues(dict):pass
class _IrregularFunctionalData:
    def __init__(self,argvals,values):
        self.argvals=argvals;self.values=values
fake_fdapy=types.ModuleType('FDApy')
fake_rep=types.ModuleType('FDApy.representation')
fake_fdapy.IrregularFunctionalData=_IrregularFunctionalData
fake_rep.DenseArgvals=_DenseArgvals
fake_rep.IrregularArgvals=_IrregularArgvals
fake_rep.IrregularValues=_IrregularValues
sys.modules['FDApy']=fake_fdapy
sys.modules['FDApy.representation']=fake_rep
_it=(np.array([0.,.4]),np.array([.03,.48,.92]))
_iv=(np.array([[.1,10.],[.2,20.]]),
     np.array([[.3,30.],[.4,40.],[.5,50.]]))
_itr=et.IrregularTrajectorySet(time=_it,values=_iv,
    curve_ids=('A','B'),dimension_names=('x','y'))
_ipy=et.to_fdapy_irregular(_itr,dimension='x')
assert isinstance(_ipy,_IrregularFunctionalData)
_grid_kw=_gpy.kwargs
_irregular_argvals=_ipy.argvals
_irregular_values=_ipy.values
")
  data<-reticulate::py_eval("_grid_kw",convert=TRUE)
  expect_identical(names(data),
    c("data_matrix","grid_points","dataset_name","coordinate_names"))
  expect_equal(as.numeric(data$grid_points),c(0,.5,1),tolerance=0)
  dm<-as.array(data$data_matrix)
  expect_identical(dim(dm),c(3L,3L,2L))
  expect_equal(as.numeric(dm[1L,1L,]),c(0,1),tolerance=0)
  expect_equal(as.numeric(dm[2L,1L,]),c(6,7),tolerance=0)
  expect_equal(as.numeric(dm[3L,3L,]),c(16,17),tolerance=0)
  expect_identical(data$dataset_name,"eyetrajectoriespy trajectories")
  expect_identical(as.character(unlist(data$coordinate_names)),c("x","y"))
  keys<-reticulate::py_eval("list(_irregular_argvals.keys())",convert=TRUE)
  expect_equal(as.integer(unlist(keys)),c(0L,1L))
  x0<-reticulate::py_eval("_irregular_argvals[0]['input_dim_0']",convert=TRUE)
  y1<-reticulate::py_eval("_irregular_values[1]",convert=TRUE)
  expect_equal(as.numeric(x0),c(0,.4),tolerance=0)
  expect_equal(as.numeric(y1),c(.3,.4,.5),tolerance=0)
})
