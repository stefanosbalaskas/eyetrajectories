# Frozen eyetrajectoriespy==1.2.0:
# sparse.py::sparse_fpca_score_frame and
# sparse_multivariate.py::sparse_mfpca_score_frame.
# Tests identify where pandas assignment differs from R dataframe defaults.

.etr_sparse_frame_semantic_fixture <- function(prefix) {
  ids<-c("α1","β2","γ3")
  meta<-data.frame(group=c("control","treated","control"),
    site=c("A","B","C"),check.names=FALSE)
  ans<-list(curve_ids=ids,metadata=meta,
    scores=matrix(c(1,2,3,4,5,6),3L,2L,byrow=TRUE),
    n_components=2L)
  ans
}
test_that("sparse source score labels overwrite colliding metadata in place", {
  for(prefix in c("SFPC","SMFPC")){
    f<-if(prefix=="SFPC")etr_sparse_fpca_score_frame
      else etr_sparse_mfpca_score_frame
    z<-.etr_sparse_frame_semantic_fixture(prefix)
    if(prefix=="SMFPC")class(z)<-"etr_sparse_mfpca_source"
    z$metadata[[paste0(prefix,"1")]]<-c(-1,-2,-3)
    z$metadata$tail<-c(TRUE,FALSE,TRUE)
    frame<-f(z)
    expect_identical(names(frame),
      c("curve_id","group","site",paste0(prefix,"1"),
        "tail",paste0(prefix,"2")))
    expect_identical(frame[[paste0(prefix,"1")]],c(1,3,5))
    expect_identical(frame[[paste0(prefix,"2")]],c(2,4,6))
    expect_identical(frame$tail,c(TRUE,FALSE,TRUE))
    expect_identical(frame$curve_id,z$curve_ids)
    expect_identical(frame$group,z$metadata$group)
    expect_identical(rownames(frame),as.character(1:3))
  }
})

test_that("sparse source scores replace all duplicate labeled columns", {
  for(prefix in c("SFPC","SMFPC")){
    f<-if(prefix=="SFPC")etr_sparse_fpca_score_frame
      else etr_sparse_mfpca_score_frame
    z<-.etr_sparse_frame_semantic_fixture(prefix)
    if(prefix=="SMFPC")class(z)<-"etr_sparse_mfpca_source"
    extras<-data.frame(c(-1,-2,-3),c(-7,-8,-9),
      c(11L,12L,13L),c(14L,15L,16L),check.names=FALSE)
    names(extras)<-c(paste0(prefix,"1"),paste0(prefix,"1"),"dup","dup")
    z$metadata<-data.frame(z$metadata,extras,check.names=FALSE)
    names(z$metadata)[3:6]<-names(extras)
    out<-f(z)
    expect_identical(names(out),
      c("curve_id","group","site",paste0(prefix,"1"),
        paste0(prefix,"1"),"dup","dup",paste0(prefix,"2")))
    expect_identical(out[[4L]],c(1,3,5))
    expect_identical(out[[5L]],c(1,3,5))
    expect_identical(out[[6L]],c(11L,12L,13L))
    expect_identical(out[[7L]],c(14L,15L,16L))
    expect_identical(out[[8L]],c(2,4,6))
    expect_identical(z$metadata[[3L]],c(-1,-2,-3))
  }
})

test_that("sparse source inserted curve_id collision and retained NAN match policy", {
  z<-.etr_sparse_frame_semantic_fixture("SFPC")
  z$metadata$curve_id<-z$curve_ids
  expect_error(etr_sparse_fpca_score_frame(z),"curve_id")
  expect_error(etr_sparse_mfpca_score_frame(z),
    "native sparse MFPCA source result")
  expect_error(etr_sparse_mfpca_score_frame(structure(z,
    class="etr_sparse_mfpca_source")),"curve_id")
  z$metadata$curve_id<-NULL
  z$scores[2,1]<-NaN
  for(f in list(etr_sparse_fpca_score_frame,
    etr_sparse_mfpca_score_frame)){
    input<-z
    if(identical(f,etr_sparse_mfpca_score_frame))
      class(input)<-"etr_sparse_mfpca_source"
    frame<-f(input)
    expect_true(is.nan(frame[[4L]][2L]))
    expect_equal(frame[[4L]][c(1,3)],c(1,5))
  }
})

test_that("sparse score metadata collisions match frozen pandas 1.2 source",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned 1.2 source score tables require Python")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _sp_frame_object(cls, **kwargs):
    o=object.__new__(cls)
    for key,value in kwargs.items():
        object.__setattr__(o,key,value)
    return o
_sp_frame_cases={}
for prefix, cls, function in (
    ('SFPC',et.SparseFPCAResult,et.sparse_fpca_score_frame),
    ('SMFPC',et.SparseMFPCAResult,et.sparse_mfpca_score_frame)):
    meta=pd.DataFrame({
        'group':['control','treated','control'],
        'site':['A','B','C']})
    extras=pd.DataFrame(
        [[-1.,-7.,11,14],[-2.,-8.,12,15],[-3.,-9.,13,16]],
        columns=[prefix+'1',prefix+'1','dup','dup'])
    meta=pd.concat([meta,extras],axis=1)
    model=_sp_frame_object(cls,curve_ids=('α1','β2','γ3'),
        metadata=meta,scores=np.array([[1.,2.],[3.,4.],[5.,6.]]),
        n_components=2)
    frame=function(model)
    _sp_frame_cases[prefix]={
        'columns':list(frame.columns),
        'values':[[frame.iloc[i,j] for i in range(len(frame))]
                  for j in range(frame.shape[1])],
        'types':[str(frame.iloc[:,j].dtype)
                 for j in range(frame.shape[1])]}
    invalid=_sp_frame_object(cls,curve_ids=('α1','β2','γ3'),
        metadata=meta.assign(curve_id=['a','b','c']),
        scores=model.scores,n_components=2)
    try:
        function(invalid)
    except Exception as e:
        _sp_frame_cases[prefix]['error']=type(e).__name__+': '+str(e)
    else:
        raise AssertionError('Expected pandas curve_id insert failure')
")
  for(prefix in c("SFPC","SMFPC")){
    f<-if(prefix=="SFPC")etr_sparse_fpca_score_frame
      else etr_sparse_mfpca_score_frame
    z<-.etr_sparse_frame_semantic_fixture(prefix)
    if(prefix=="SMFPC")class(z)<-"etr_sparse_mfpca_source"
    extras<-data.frame(c(-1,-2,-3),c(-7,-8,-9),
      c(11L,12L,13L),c(14L,15L,16L),check.names=FALSE)
    names(extras)<-c(paste0(prefix,"1"),paste0(prefix,"1"),"dup","dup")
    z$metadata<-data.frame(z$metadata,extras,check.names=FALSE)
    names(z$metadata)[3:6]<-names(extras)
    native<-f(z)
    python<-reticulate::py_to_r(reticulate::py_eval(
      paste0("_sp_frame_cases['",prefix,"']"),convert=FALSE))
    expect_identical(names(native),unlist(python$columns,use.names=FALSE))
    for(j in seq_len(ncol(native))){
      wanted<-unlist(python$values[[j]],use.names=FALSE)
      if(is.numeric(native[[j]]))
        expect_equal(as.numeric(native[[j]]),as.numeric(wanted),
          tolerance=0,info=paste(prefix,j))
      else expect_identical(as.character(native[[j]]),
        as.character(wanted),info=paste(prefix,j))
    }
    expect_match(python$error,"cannot insert curve_id, already exists",
      fixed=TRUE)
    z$metadata$curve_id<-z$curve_ids
    expect_error(f(z),"curve_id")
  }
})
