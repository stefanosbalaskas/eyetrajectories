# Native W4 recurrence and direct Python 1.2 source geometry checks.
.etr_w4_fixture <- function() {
  time<-seq(0,1,length.out=25L)
  values<-array(0,c(4L,25L,1L))
  for(i in seq_len(4L))values[i,,1L]<-sin(2*pi*time+i/5)+i*time/10
  etr_trajectory_set(time,values,sprintf("c%02d",1:4),"x",
    coordinate_system="normalized",time_unit="s")
}
.etr_w4_config <- function()list(curve=0L,dimensions="x",
  embedding_dimension=2L,delay=2L,radius=.6,
  metric="euclidean",theiler_window=1L,
  min_diagonal_length=2L,min_vertical_length=2L)

test_that("recurrence workflow preserves declared sample geometry",{
  x<-.etr_w4_fixture()
  z<-etr_run_recurrence_workflow(x,.etr_w4_config())
  expect_s3_class(z,"etr_recurrence_workflow")
  expect_s3_class(z$embedding,"etr_delay_embedding_set")
  expect_s3_class(z$recurrence,"etr_recurrence")
  expect_identical(dim(z$embedding$values),c(4L,23L,2L))
  expect_identical(z$embedding$delay_samples,2L)
  expect_identical(z$recurrence$theiler,1L)
  expect_equal(z$recurrence$radius,.6)
  expect_identical(nrow(z$tables$rqa_metrics),1L)
  expect_false(z$provenance$preprocessing_executed)
  expect_false(z$provenance$source_schema_equivalent)
  cfg<-.etr_w4_config();cfg$curve<-"c01"
  by_id<-etr_run_recurrence_workflow(x,cfg)
  expect_identical(z$recurrence$matrix,by_id$recurrence$matrix)
})

test_that("recurrence W4 refuses unsupported source modes",{
  x<-.etr_w4_fixture(); cfg<-.etr_w4_config()
  wrong<-cfg;wrong$metric<-"cityblock"
  expect_error(etr_run_recurrence_workflow(x,wrong),"Euclidean")
  wrong<-cfg;wrong$delay_units<-"time"
  expect_error(etr_run_recurrence_workflow(x,wrong),"time-unit")
  wrong<-cfg;wrong$radius<-0
  expect_error(etr_run_recurrence_workflow(x,wrong),"radius")
  wrong<-cfg;wrong$curve<-4L
  expect_error(etr_run_recurrence_workflow(x,wrong),"zero-based")
  wrong<-cfg;wrong$preprocessing<-list("smooth")
  expect_error(etr_run_recurrence_workflow(x,wrong),"empty preprocessing")
})

test_that("Python 1.2 W4 source preserves embedded and recurrence geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 W4 numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  native<-etr_run_recurrence_workflow(.etr_w4_fixture(),.etr_w4_config())
  reticulate::py_run_string("
import numpy as np, pandas as pd
import eyetrajectoriespy as et
from eyetrajectoriespy.workflows._recurrence import (
 RecurrenceWorkflowConfig,run_recurrence_workflow)
t=np.linspace(0,1,25); v=np.empty((4,25,1))
for i in range(1,5):v[i-1,:,0]=np.sin(2*np.pi*t+i/5)+i*t/10
x=et.TrajectorySet(time=t,values=v,
 curve_ids=tuple('c%02d'%i for i in range(1,5)),
 dimension_names=('x',),metadata=pd.DataFrame(index=range(4)),
 coordinate_system='normalized',time_unit='s')
cfg=RecurrenceWorkflowConfig(curve=0,dimensions=('x',),
 embedding_dimension=2,delay=2,radius=.6,metric='euclidean',
 theiler_window=1,min_diagonal_length=2,min_vertical_length=2)
a=run_recurrence_workflow(x,config=cfg)
_w4_source={'state':a.embedding.values,'matrix':a.recurrence.matrix}
")
  source<-reticulate::py_to_r(reticulate::py_eval("_w4_source",convert=FALSE))
  expect_equal(unname(native$embedding$values),
    unname(source$state),tolerance=1e-12)
  expect_equal(unname(native$recurrence$matrix),
    unname(source$matrix),tolerance=0)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
