# Frozen published Python 1.2 prediction.py::cross_validate_fpca_regression
.etr_fpcr_cv_fixture<-function(){
  grid<-seq(0,1,length.out=5L);n<-12L
  x<-array(0,c(n,5L,1L))
  z1<-seq(-2,2,length.out=n)
  z2<-c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7)
  for(i in seq_len(n))x[i,,1L]<-
    .2+z1[i]*sin(pi*grid)+z2[i]*cos(2*pi*grid)
  y<-1+.5*z1-.2*z2+.03*c(0,1,-1,0,1,-1,0,1,-1,0,1,-1)
  list(trajectories=etr_trajectory_set(grid,x,
    paste0("curve",seq_len(n)),"x",
    coordinate_system="normalized",time_unit="normalized"),outcome=y)
}
test_that("native Gaussian FPCR refits FPCA and OLS inside deterministic folds",{
  z<-.etr_fpcr_cv_fixture()
  ans<-etr_cross_validate_fpca_regression(z$trajectories,z$outcome,
    candidate_components=c(2L,1L,2L),n_splits=3L,shuffle=FALSE)
  expect_identical(ans$component_counts,c(1L,2L))
  expect_identical(nrow(ans$fold_losses),6L)
  expect_identical(nrow(ans$assignments),12L)
  expect_identical(nrow(ans$predictions),24L)
  expect_identical(ans$assignments$fold,rep(0:2,each=4L))
  expect_equal(ans$fold_losses$n_train_curves,rep(8L,6L))
  expect_equal(ans$fold_losses$n_test_curves,rep(4L,6L))
  expect_equal(ans$fold_losses$loss,vapply(seq_len(6L),function(j){
    row<-ans$fold_losses[j,]
    predictions<-ans$predictions[
      ans$predictions$fold==row$fold&
      ans$predictions$n_components==row$n_components,]
    sqrt(mean((predictions$observed-predictions$prediction)^2))
  },numeric(1L)),tolerance=1e-12)
  expect_true(ans$provenance$fit_fpca_inside_fold)
  expect_true(ans$provenance$fit_regression_inside_fold)
  expect_false(ans$provenance$group_leakage_prevented)
  expect_identical(ans$random_state,NULL)
  expect_equal(
    etr_select_fpca_regression_components(ans,rule="minimum"),
    ans$component_counts[which.min(
      etr_summarise_fpca_regression_cv(ans)$mean_loss)])
})
test_that("bounded FPCR CV explicitly rejects unsupported published domains",{
  z<-.etr_fpcr_cv_fixture();f<-etr_cross_validate_fpca_regression
  expect_error(f(z$trajectories,z$outcome,shuffle=TRUE,
    random_state=-1),"nonnegative R integer seed")
  expect_error(f(z$trajectories,z$outcome,cv_unit="group"),
    "group_column is required")
  expect_error(f(z$trajectories,z$outcome,family="binomial"),
    "binomial outcome must contain only 0/1 values")
  expect_error(f(z$trajectories,z$outcome,covariates=data.frame(a=letters[1:12])),
    "covariates must be numeric")
  expect_error(f(z$trajectories,z$outcome,candidate_components=99L,
    n_splits=3L),"training-fold maximum")
  expect_error(f(z$trajectories,c(z$outcome,NA_real_)),
    "one finite scalar")
  expect_error(f(z$trajectories,z$outcome,n_splits=1L),
    "n_splits must be an integer")
  expect_error(f(z$trajectories,z$outcome,loss="log_loss"),
    "gaussian loss")
})
test_that("published Python 1.2 unshuffled Gaussian FPCR folds and losses match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 leakage-aware FPCR regression CV oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
t=np.linspace(0,1,5)
z1=np.linspace(-2,2,12)
z2=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
v=np.array([.2+a*np.sin(np.pi*t)+b*np.cos(2*np.pi*t)
    for a,b in zip(z1,z2)])[:,:,None]
y=1+.5*z1-.2*z2+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
trajectories=et.TrajectorySet(time=t,values=v,
    curve_ids=tuple('curve'+str(i) for i in range(1,13)),
    dimension_names=('x',),coordinate_system='normalized',
    time_unit='normalized')
_cv_python=et.cross_validate_fpca_regression(
    trajectories,y,candidate_components=(2,1,2),n_splits=3,
    shuffle=False,family='gaussian')
")
  direct<-reticulate::py_call(
    etpy_get_export("cross_validate_fpca_regression"),
    trajectories=reticulate::py_eval("trajectories",convert=FALSE),
    outcome=reticulate::py_eval("y",convert=FALSE),
    candidate_components=reticulate::py_eval("(2,1,2)",convert=FALSE),
    n_splits=3L,shuffle=FALSE,family="gaussian")
  for(name in c("fold_losses","assignments","predictions")){
    original<-reticulate::py_eval(
      paste0("_cv_python.",name),convert=TRUE)
    replay<-et_to_r(reticulate::py_get_attr(direct,name))
    expect_equal(replay,original,tolerance=1e-8,
      ignore_attr=TRUE)
  }
  z<-.etr_fpcr_cv_fixture()
  actual<-etr_cross_validate_fpca_regression(z$trajectories,z$outcome,
    candidate_components=c(2L,1L,2L),n_splits=3L,shuffle=FALSE)
  for(field in c("fold_losses","assignments","predictions")){
    expected<-reticulate::py_to_r(reticulate::py_eval(
      paste0("_cv_python.",field),convert=FALSE))
    expect_identical(names(actual[[field]]),names(expected))
    expect_identical(nrow(actual[[field]]),nrow(expected))
    for(col in names(expected)){
      if(is.numeric(actual[[field]][[col]]))
        expect_equal(as.numeric(actual[[field]][[col]]),
          as.numeric(expected[[col]]),tolerance=1e-8,
          info=paste("Python leakage-aware CV",field,col))
      else
        expect_identical(as.character(actual[[field]][[col]]),
          as.character(expected[[col]]))
    }
  }
  expect_identical(actual$component_counts,
    as.integer(reticulate::py_to_r(
      reticulate::py_eval("_cv_python.component_counts",convert=FALSE))))
  expect_true(actual$provenance$fit_fpca_inside_fold)
})


test_that("Python 1.2 shuffled FPCR KFold is reproducible with explicit source folds",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 shuffled KFold source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_t=np.linspace(0,1,5)
_a=np.linspace(-2,2,12)
_b=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
_v=np.array([.2+u*np.sin(np.pi*_t)+w*np.cos(2*np.pi*_t)
 for u,w in zip(_a,_b)])[:,:,None]
_y=1+.5*_a-.2*_b+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
_x=et.TrajectorySet(time=_t,values=_v,
 curve_ids=tuple('curve'+str(i) for i in range(1,13)),
 dimension_names=('x',),coordinate_system='normalized',
 time_unit='normalized')
_et_cv=et.cross_validate_fpca_regression(_x,_y,
 candidate_components=(1,2),n_splits=3,shuffle=True,random_state=19)
_fold=np.full(12,-1,dtype=np.int64)
for r in _et_cv.assignments.itertuples(index=False):
 _fold[int(r.curve_id[5:])-1]=int(r.fold)
assert sorted(set(_fold))==[0,1,2]
")
  z<-.etr_fpcr_cv_fixture()
  folds<-as.integer(reticulate::py_to_r(reticulate::py_eval(
    "_fold",convert=FALSE)))
  result<-etr_cross_validate_fpca_regression(z$trajectories,z$outcome,
    candidate_components=c(1L,2L),n_splits=3L,shuffle=TRUE,
    random_state=19L,fold_assignments=folds)
  expect_identical(result$provenance$fold_source,
    "explicit_zero_based_source_replay")
  expect_identical(result$provenance$random_engine,"none_fixed_folds")
  for(field in c("fold_losses","assignments","predictions")){
    expected<-reticulate::py_to_r(reticulate::py_get_attr(
      reticulate::py_eval("_et_cv",convert=FALSE),field))
    actual<-result[[field]]
    expect_identical(names(actual),names(expected))
    for(col in names(expected)){
      if(is.numeric(actual[[col]]))
        expect_equal(as.numeric(actual[[col]]),
          as.numeric(expected[[col]]),tolerance=1e-7,
          info=paste("shuffled FPCR source",field,col))
      else expect_identical(as.character(actual[[col]]),
        as.character(expected[[col]]))
    }
  }
})

test_that("explicit FPCR source folds reject malformed and group-leaking assignments",{
  z<-.etr_fpcr_cv_fixture()
  f<-function(folds,...)etr_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=1L,n_splits=3L,
    fold_assignments=folds,...)
  for(bad in list(0:10,rep(0L,12),c(rep(0,11),3),
    c(rep(0,11),1.5),rep(NA_real_,12),rep("0",12),
    matrix(rep(0L,12),3L,4L),rep(FALSE,12)))
    expect_error(f(bad),"fold_assignments")
  x<-z$trajectories
  x$metadata$person<-c("a","a","b","c","c","d","d","d",
    "e","e","f","f")
  folds<-c(0L,0L,1L,2L,2L,1L,1L,1L,0L,0L,2L,2L)
  grouped<-etr_cross_validate_fpca_regression(x,z$outcome,
    candidate_components=1L,n_splits=3L,cv_unit="group",
    group_column="person",fold_assignments=folds)
  expect_identical(grouped$assignments$fold,
    as.integer(folds[match(grouped$assignments$curve_id,x$curve_ids)]))
  wrong<-folds;wrong[2L]<-1L
  expect_error(etr_cross_validate_fpca_regression(x,z$outcome,
    candidate_components=1L,n_splits=3L,cv_unit="group",
    group_column="person",fold_assignments=wrong),"split a group")
  expect_equal(nrow(grouped$predictions),12L)
})
