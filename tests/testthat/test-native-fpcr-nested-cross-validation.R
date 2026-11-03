# Opt-in oracle: frozen eyetrajectoriespy==1.2.0 prediction.py.
.etr_nested_cv_fixture <- function(){
  t<-seq(0,1,length.out=5L);z<-seq(-2,2,length.out=12L)
  q<-c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7)
  a<-array(0,c(12L,5L,1L))
  for(i in seq_len(12L))a[i,,1L]<-.2+z[i]*sin(pi*t)+q[i]*cos(2*pi*t)
  y<-1+.5*z-.2*q+.03*c(0,1,-1,0,1,-1,0,1,-1,0,1,-1)
  list(x=etr_trajectory_set(t,a,paste0("curve",1:12),"x",
    coordinate_system="normalized",time_unit="normalized"),y=y)
}
test_that("nested FPCR selection and outer predictions remain leakage-free",{
  z<-.etr_nested_cv_fixture()
  for(rule in c("minimum","one_se")){
    v<-etr_nested_cross_validate_fpca_regression(z$x,z$y,
      candidate_components=c(2L,1L,2L),outer_splits=3L,
      inner_splits=2L,selection_rule=rule,shuffle=FALSE)
    expect_equal(nrow(v$outer_folds),3L)
    expect_equal(nrow(v$inner_summaries),6L)
    expect_equal(nrow(v$predictions),12L)
    expect_identical(v$component_counts,c(1L,2L))
    expect_identical(v$random_state,NULL)
    expect_true(v$provenance$nested_selection)
    expect_true(v$provenance$outer_performance_unseen_by_inner_selection)
    expect_equal(v$outer_folds$n_train_curves,rep(8L,3L))
    expect_equal(v$outer_folds$n_test_curves,rep(4L,3L))
    expect_true(all(v$outer_folds$selected_n_components%in%c(1L,2L)))
    for(f in 0:2){
      r<-v$predictions[v$predictions$outer_fold==f,,drop=FALSE]
      expect_equal(v$outer_folds$loss[[f+1L]],
        sqrt(mean((r$observed-r$prediction)^2)),tolerance=1e-12)
    }
  }
})
test_that("outer held-out outcomes cannot affect their own nested prediction",{
  z<-.etr_nested_cv_fixture()
  original<-etr_nested_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=c(1L,2L),outer_splits=3L,
    inner_splits=2L,selection_rule="one_se")
  changed<-z$y;changed[1:4]<-changed[1:4]+100
  moved<-etr_nested_cross_validate_fpca_regression(z$x,changed,
    candidate_components=c(1L,2L),outer_splits=3L,
    inner_splits=2L,selection_rule="one_se")
  first<-original$predictions$outer_fold==0L
  expect_equal(original$predictions$prediction[first],
    moved$predictions$prediction[first],tolerance=1e-12)
  expect_identical(original$outer_folds$selected_n_components[[1L]],
    moved$outer_folds$selected_n_components[[1L]])
  expect_false(isTRUE(all.equal(
    original$outer_folds$loss[[1L]],moved$outer_folds$loss[[1L]])))
})
test_that("nested FPCR refuses unsupported Python source domains",{
  z<-.etr_nested_cv_fixture()
  f<-etr_nested_cross_validate_fpca_regression
  expect_error(f(z$x,z$y,shuffle=TRUE,random_state=-1L),
    "nonnegative inner/outer R shuffle seeds")
  expect_error(f(z$x,z$y,cv_unit="group"),"group_column is required")
  expect_error(f(z$x,z$y,family="binomial"),"family")
  expect_error(f(z$x,z$y,covariates=data.frame(z=letters[1:12])),"covariates")
  expect_error(f(z$x,z$y,selection_rule="bad"),"selection_rule")
  expect_error(f(z$x,z$y,outer_splits=1L),"outer_splits")
  expect_error(f(z$x,z$y,outer_splits=3L,inner_splits=9L),"inner_splits")
})
test_that("pinned Python 1.2 nested FPCR source results agree on fixed folds",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 nested Gaussian FPCR oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
t=np.linspace(0,1,5);z=np.linspace(-2,2,12)
q=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
a=np.array([.2+x*np.sin(np.pi*t)+v*np.cos(2*np.pi*t)
 for x,v in zip(z,q)])[:,:,None]
y=1+.5*z-.2*q+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
x=et.TrajectorySet(time=t,values=a,
 curve_ids=tuple('curve'+str(i) for i in range(1,13)),
 dimension_names=('x',),coordinate_system='normalized',
 time_unit='normalized')
_py_nested={}
for rule in ('minimum','one_se'):
 _py_nested[rule]=et.nested_cross_validate_fpca_regression(
  x,y,candidate_components=(2,1,2),outer_splits=3,
  inner_splits=2,selection_rule=rule,shuffle=False,
  family='gaussian')
")
  z<-.etr_nested_cv_fixture()
  for(rule in c("minimum","one_se")){
    direct<-reticulate::py_call(
      etpy_get_export("nested_cross_validate_fpca_regression"),
      trajectories=reticulate::py_eval("x",convert=FALSE),
      outcome=reticulate::py_eval("y",convert=FALSE),
      candidate_components=reticulate::py_eval("(2,1,2)",convert=FALSE),
      outer_splits=3L,inner_splits=2L,selection_rule=rule,
      shuffle=FALSE,family="gaussian")
    for(name in c("outer_folds","inner_summaries","predictions")){
      original<-reticulate::py_eval(
        paste0("_py_nested['",rule,"'].",name),convert=TRUE)
      replay<-et_to_r(reticulate::py_get_attr(direct,name))
      expect_equal(replay,original,tolerance=1e-8,ignore_attr=TRUE)
    }
    native<-etr_nested_cross_validate_fpca_regression(z$x,z$y,
      candidate_components=c(2L,1L,2L),outer_splits=3L,
      inner_splits=2L,selection_rule=rule,shuffle=FALSE)
    for(field in c("outer_folds","inner_summaries","predictions")){
      expected<-reticulate::py_to_r(reticulate::py_eval(
        paste0("_py_nested['",rule,"'].",field),convert=FALSE))
      actual<-native[[field]]
      expect_identical(names(actual),names(expected))
      expect_identical(nrow(actual),nrow(expected))
      for(column in names(expected)){
        if(is.numeric(actual[[column]]))
          expect_equal(as.numeric(actual[[column]]),
            as.numeric(expected[[column]]),tolerance=1e-8,
            info=paste("Python nested FPCR",rule,field,column))
        else expect_identical(as.character(actual[[column]]),
          as.character(expected[[column]]))
      }
    }
  }
})


test_that("nested FPCR rejects malformed split and component domains explicitly",{
  z<-.etr_nested_cv_fixture()
  run<-function(...) etr_nested_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=1L,...)
  for(bad in list(NA_real_,NaN,Inf,-Inf,2.5,"3",numeric(),NULL))
    expect_error(run(outer_splits=bad,shuffle=TRUE,random_state=7L),
      "outer_splits invalid")
  for(bad in list(NA_real_,NaN,Inf,-Inf,1.5,"2",numeric(),NULL))
    expect_error(run(inner_splits=bad,shuffle=TRUE,random_state=7L),
      "inner_splits invalid")
  for(bad in list(c(1,NA_real_),c(1,NaN),c(1,Inf),
                  1.5,-1,0,.Machine$integer.max+1))
    expect_error(etr_nested_cross_validate_fpca_regression(
      z$x,z$y,candidate_components=bad,outer_splits=3L,
      inner_splits=2L),
      "candidate_components must be positive integers")
  expect_error(run(outer_splits=3L,inner_splits=2L,
    shuffle=TRUE,random_state=.Machine$integer.max),
    "nonnegative inner/outer R shuffle seeds")
  expect_error(run(outer_splits=3L,inner_splits=2L,
    shuffle=TRUE,random_state=NA_real_),
    "nonnegative inner/outer R shuffle seeds")
  ok<-run(outer_splits=3L,inner_splits=2L,
    shuffle=TRUE,random_state=7L)
  expect_s3_class(ok,"etr_nested_fpcr_cv")
  expect_equal(nrow(ok$outer_folds),3L)
})
