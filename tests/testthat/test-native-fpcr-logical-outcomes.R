# Pinned eyetrajectoriespy 1.2.0 prediction.py::_validate_outcome uses
# np.asarray(outcome,dtype=float); logical / NumPy bool is finite 0/1.
# These are developer contract tests, not independent scientific approval.

.etr_fpcr_logical_fixture<-function(){
  t<-seq(0,1,length.out=7L);n<-36L
  a<-seq(-2,2,length.out=n)
  b<-rep(c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7),3L)
  values<-array(0,c(n,7L,1L))
  for(i in seq_len(n))
    values[i,,1L]<-.2+a[i]*sin(pi*t)+b[i]*cos(2*pi*t)
  y<-as.logical(rep(c(0,1,1,0,1,0,0,1,0,1,1,0),3L))
  x<-etr_trajectory_set(t,values,paste0("curve",seq_len(n)),"x",
    metadata=data.frame(participant=rep(sprintf("P%02d",1:6),
                                        each=6L),stringsAsFactors=FALSE),
    coordinate_system="normalized",time_unit="normalized")
  list(x=x,y=y)
}

test_that("logical outcomes reproduce numeric 0/1 Gaussian and binomial CV",{
  z<-.etr_fpcr_logical_fixture()
  for(family in c("gaussian","binomial")){
    run<-function(y)etr_cross_validate_fpca_regression(z$x,y,
      candidate_components=c(1L,2L),family=family,
      loss=if(identical(family,"gaussian"))"mae" else "brier",
      n_splits=3L,cv_unit="group",group_column="participant",
      shuffle=FALSE)
    a<-run(z$y);b<-run(as.numeric(z$y))
    expect_identical(a$family,family)
    expect_equal(a$fold_losses,b$fold_losses,tolerance=1e-12)
    expect_identical(a$assignments,b$assignments)
    expect_equal(a$predictions,b$predictions,tolerance=1e-12)
    expect_true(is.numeric(a$predictions$observed))
    expect_setequal(unique(a$predictions$observed),c(0,1))
    expect_true(all(is.finite(a$predictions$prediction)))
    if(identical(family,"binomial"))
      expect_true(all(a$predictions$prediction>=0&
                      a$predictions$prediction<=1))
  }
})

test_that("logical outcomes remain numeric in nested FPCR selection",{
  z<-.etr_fpcr_logical_fixture()
  for(family in c("gaussian","binomial")){
    run<-function(y)etr_nested_cross_validate_fpca_regression(z$x,y,
      candidate_components=c(1L,2L),family=family,
      loss=if(identical(family,"gaussian"))"rmse" else "brier",
      outer_splits=3L,inner_splits=2L,selection_rule="minimum",
      cv_unit="group",group_column="participant",shuffle=FALSE)
    a<-run(z$y);b<-run(as.numeric(z$y))
    expect_identical(a$family,family)
    expect_equal(a$outer_folds,b$outer_folds,tolerance=1e-12)
    expect_equal(a$inner_summaries,b$inner_summaries,tolerance=1e-12)
    expect_equal(a$predictions,b$predictions,tolerance=1e-12)
    expect_identical(nrow(a$predictions),36L)
    expect_true(is.numeric(a$predictions$observed))
  }
})

test_that("logical NA and wrong-shaped outcomes fail explicitly",{
  z<-.etr_fpcr_logical_fixture()
  bad<-z$y;bad[1L]<-NA
  expect_error(etr_cross_validate_fpca_regression(z$x,bad,
    family="binomial",n_splits=3L,shuffle=FALSE),
    "one finite scalar")
  expect_error(etr_nested_cross_validate_fpca_regression(z$x,bad,
    family="binomial",outer_splits=3L,inner_splits=2L,
    shuffle=FALSE),"finite and curve aligned")
  expect_error(etr_cross_validate_fpca_regression(z$x,
    matrix(z$y,ncol=1L),family="binomial",shuffle=FALSE),
    "one finite scalar")
  expect_error(etr_nested_cross_validate_fpca_regression(z$x,
    as.logical(c(TRUE,FALSE)),family="binomial"),
    "finite and curve aligned")
})

test_that("pinned Python 1.2 NumPy boolean FPCR source oracle matches native outcomes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 NumPy boolean FPCR outcome source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_lo_t=np.linspace(0,1,7);_lo_a=np.linspace(-2,2,36)
_lo_b=np.tile([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7],3)
_lo_v=np.array([.2+a*np.sin(np.pi*_lo_t)+b*np.cos(2*np.pi*_lo_t)
                for a,b in zip(_lo_a,_lo_b)])[:,:,None]
_lo_y=np.tile([False,True,True,False,True,False,False,True,False,
               True,True,False],3)
_lo_gr=np.repeat([f'P{i:02d}' for i in range(1,7)],6)
_lo_x=et.TrajectorySet(time=_lo_t,values=_lo_v,
 curve_ids=tuple('curve'+str(i) for i in range(1,37)),
 dimension_names=('x',),metadata=pd.DataFrame({'participant':_lo_gr}),
 coordinate_system='normalized',time_unit='normalized')
_lo_cv=et.cross_validate_fpca_regression(
 _lo_x,_lo_y,candidate_components=(1,2),family='binomial',
 loss='brier',n_splits=3,cv_unit='group',
 group_column='participant',shuffle=False)
_lo_nested=et.nested_cross_validate_fpca_regression(
 _lo_x,_lo_y,candidate_components=(1,2),family='binomial',
 loss='brier',outer_splits=3,inner_splits=2,
 selection_rule='minimum',cv_unit='group',
 group_column='participant',shuffle=False)
")
  z<-.etr_fpcr_logical_fixture()
  native_cv<-etr_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=c(1L,2L),family="binomial",
    loss="brier",n_splits=3L,cv_unit="group",
    group_column="participant",shuffle=FALSE)
  native_nested<-etr_nested_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=c(1L,2L),family="binomial",
    loss="brier",outer_splits=3L,inner_splits=2L,
    selection_rule="minimum",cv_unit="group",
    group_column="participant",shuffle=FALSE)
  for(pair in list(
    list(native=native_cv,source="_lo_cv",
      fields=c("fold_losses","assignments","predictions")),
    list(native=native_nested,source="_lo_nested",
      fields=c("outer_folds","inner_summaries","predictions")))){
    for(field in pair$fields){
      expected<-et_to_r(reticulate::py_eval(
        paste0(pair$source,".",field),convert=FALSE))
      actual<-pair$native[[field]]
      expect_identical(names(actual),names(expected))
      expect_identical(nrow(actual),nrow(expected))
      for(column in names(expected)){
        if(is.numeric(actual[[column]]))
          expect_equal(as.numeric(actual[[column]]),
            as.numeric(expected[[column]]),tolerance=1e-5,
            info=paste("Boolean FPCR oracle",pair$source,field,column))
        else expect_identical(as.character(actual[[column]]),
          as.character(expected[[column]]))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
