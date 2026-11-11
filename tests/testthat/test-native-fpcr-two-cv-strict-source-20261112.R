# Two source-scientific CV contracts: Python 1.2 prediction.py
# Frozen commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Explicit strict_source_record is an R source-scientific result mode;
# Python runtime dataclass identity and its backend class are not asserted.
.etr_fpcr_two_cv_fixture<-function(family="gaussian") {
  n<-36L;t<-seq(0,1,length.out=7L)
  a<-seq(-2,2,length.out=n)
  b<-rep(c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7),3L)
  cv<-rep(c(.2,-.7,.9,0,-.3,.5,1.2,-1.1,.4,-.9,.6,-.2),3L)
  z<-array(0,c(n,length(t),1L))
  for(i in seq_len(n))z[i,,1L]<-.2+a[i]*sin(pi*t)+b[i]*cos(2*pi*t)
  y<-if(family=="gaussian")
    1+.5*a-.2*b+.025*cv else
    as.numeric(rep(c(0,1,1,0,1,0,0,1,0,1,1,0),3L))
  x<-etr_trajectory_set(t,z,paste0("curve",seq_len(n)),"x",
    metadata=data.frame(participant=rep(sprintf("P%02d",1:6),each=6L)),
    coordinate_system="normalized",time_unit="normalized")
  list(x=x,y=y,cov=data.frame(w=cv),t=t,a=a,b=b,w=cv)
}
.etr_fpcr_two_cv_source_keys<-list(
  ordinary=c("method","fit_fpca_inside_fold",
    "fit_regression_inside_fold","group_leakage_prevented",
    "covariates","scientific_warning"),
  nested=c("method","nested_selection",
    "outer_performance_unseen_by_inner_selection",
    "group_leakage_prevented","covariates","scientific_warning"))
.etr_fpcr_two_cv_compare_frame<-function(actual,expected,which){
  expect_identical(names(actual),names(expected),
    info=paste(which,"field names"))
  expect_identical(nrow(actual),nrow(expected),
    info=paste(which,"row count"))
  for(k in names(expected)){
    if(is.numeric(actual[[k]]))
      expect_equal(as.numeric(actual[[k]]),
        as.numeric(expected[[k]]),tolerance=1e-5,
        info=paste(which,k))
    else expect_identical(as.character(actual[[k]]),
      as.character(expected[[k]]),info=paste(which,k))
  }
}

test_that("source-scientific ordinary and nested FPCR CV return canonical fields",{
  for(family in c("gaussian","binomial")){
    z<-.etr_fpcr_two_cv_fixture(family)
    ordinary<-etr_cross_validate_fpca_regression(
      z$x,z$y,candidate_components=c(1L,2L),
      family=family,covariates=z$cov,
      n_splits=3L,shuffle=TRUE,random_state=19L,
      random_engine="numpy",strict_source_record=TRUE)
    nested<-etr_nested_cross_validate_fpca_regression(
      z$x,z$y,candidate_components=c(1L,2L),
      family=family,covariates=z$cov,
      outer_splits=3L,inner_splits=2L,selection_rule="one_se",
      shuffle=TRUE,random_state=19L,
      random_engine="numpy",strict_source_record=TRUE)
    expect_identical(names(ordinary),c("fold_losses","assignments",
      "predictions","component_counts","family","loss",
      "cv_unit","n_splits","group_column","scaling","random_state",
      "provenance"))
    expect_identical(names(nested),c("outer_folds","inner_summaries",
      "predictions","family","loss","selection_rule","component_counts",
      "outer_splits","inner_splits","cv_unit","group_column","scaling",
      "random_state","provenance"))
    expect_identical(names(ordinary$provenance),
      .etr_fpcr_two_cv_source_keys$ordinary)
    expect_identical(names(nested$provenance),
      .etr_fpcr_two_cv_source_keys$nested)
    expect_true(ordinary$provenance$fit_fpca_inside_fold)
    expect_true(nested$provenance$nested_selection)
    expect_identical(ordinary$provenance$covariates,list("w"))
    expect_identical(nested$provenance$covariates,list("w"))
    expect_identical(nrow(ordinary$fold_losses),6L)
    expect_identical(nrow(nested$outer_folds),3L)
    expect_identical(nrow(nested$inner_summaries),6L)
    expect_identical(nrow(nested$predictions),36L)
    expect_true(all(is.finite(ordinary$predictions$prediction)))
    expect_true(all(is.finite(nested$predictions$prediction)))
    if(family=="binomial"){
      expect_true(all(ordinary$predictions$prediction>=0&
        ordinary$predictions$prediction<=1))
      expect_true(all(nested$predictions$prediction>=0&
        nested$predictions$prediction<=1))
    }
  }
})

test_that("strict CV modes reject R-only fold replay and unsupported source RNG",{
  z<-.etr_fpcr_two_cv_fixture("gaussian")
  cv<-function(...)etr_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=1L,n_splits=3L,...)
  nc<-function(...)etr_nested_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=1L,outer_splits=3L,inner_splits=2L,...)
  expect_error(cv(strict_source_record=NA),"strict_source_record")
  expect_error(nc(strict_source_record=1L),"strict_source_record")
  expect_error(cv(shuffle=TRUE,random_state=19L,
    strict_source_record=TRUE),"random_engine")
  expect_error(nc(shuffle=TRUE,random_state=19L,
    strict_source_record=TRUE),"random_engine")
  expect_error(cv(fold_assignments=rep(0L,36L),
    strict_source_record=TRUE),"fold_assignments")
  expect_error(nc(outer_fold_assignments=rep(0L,36L),
    strict_source_record=TRUE),"fold assignments")
  expect_error(cv(coerce_numeric_text_covariates=TRUE,
    strict_source_record=TRUE),"text covariate")
  expect_error(nc(coerce_numeric_text_covariates=TRUE,
    strict_source_record=TRUE),"text covariate")
  expect_error(cv(cv_unit="group",group_column="participant",
    strict_source_record=TRUE),"NumPy tie-order")
  expect_error(nc(cv_unit="group",group_column="participant",
    strict_source_record=TRUE),"NumPy tie-order")
  legacy<-cv(shuffle=FALSE)
  expect_true("random_engine"%in%names(legacy$provenance))
  expect_true("fold_source"%in%names(legacy$provenance))
  strict<-cv(shuffle=FALSE,strict_source_record=TRUE)
  expect_false("fold_source"%in%names(strict$provenance))
  expect_equal(legacy$fold_losses,strict$fold_losses,tolerance=0)
  expect_equal(legacy$predictions,strict$predictions,tolerance=0)
})

test_that("real frozen Python 1.2 ordinary and nested FPCR fits agree on source scientific outputs",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires Python 1.2 sklearn and statsmodels direct CV oracles")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_src_t=np.linspace(0.,1.,7)
_src_a=np.linspace(-2.,2.,36)
_src_b=np.tile([1.,-1.,2.,-2.,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7],3)
_src_w=np.tile([.2,-.7,.9,0.,-.3,.5,1.2,-1.1,.4,-.9,.6,-.2],3)
_src_y_gaussian=1.+.5*_src_a-.2*_src_b+.025*_src_w
_src_y_binomial=np.tile([0.,1.,1.,0.,1.,0.,0.,1.,0.,1.,1.,0.],3)
_src_values=np.array([.2+a*np.sin(np.pi*_src_t)+b*np.cos(2*np.pi*_src_t)
                    for a,b in zip(_src_a,_src_b)])[:,:,None]
_src_x=et.TrajectorySet(time=_src_t,values=_src_values,
 curve_ids=tuple('curve'+str(i) for i in range(1,37)),
 dimension_names=('x',),
 metadata=pd.DataFrame({'participant':np.repeat(
     [f'P{i:02d}' for i in range(1,7)],6)}),
 coordinate_system='normalized',time_unit='normalized')
_src_cov=pd.DataFrame({'w':_src_w})
")
  for(family in c("gaussian","binomial")){
    z<-.etr_fpcr_two_cv_fixture(family)
    py_y<-reticulate::py_eval(
      if(family=="gaussian")"_src_y_gaussian" else "_src_y_binomial",
      convert=FALSE)
    args<-list(trajectories=reticulate::py_eval("_src_x",convert=FALSE),
      outcome=py_y,
      candidate_components=reticulate::py_eval("(1,2)",convert=FALSE),
      family=family,covariates=reticulate::py_eval("_src_cov",convert=FALSE),
      shuffle=TRUE,random_state=19L)
    py_cv<-do.call(reticulate::py_call,c(list(
      etpy_get_export("cross_validate_fpca_regression")),
      args,list(n_splits=3L)))
    py_nc<-do.call(reticulate::py_call,c(list(
      etpy_get_export("nested_cross_validate_fpca_regression")),
      args,list(outer_splits=3L,inner_splits=2L,
        selection_rule="one_se")))
    native_cv<-etr_cross_validate_fpca_regression(
      z$x,z$y,candidate_components=c(1L,2L),
      family=family,covariates=z$cov,n_splits=3L,
      shuffle=TRUE,random_state=19L,random_engine="numpy",
      strict_source_record=TRUE)
    native_nc<-etr_nested_cross_validate_fpca_regression(
      z$x,z$y,candidate_components=c(1L,2L),
      family=family,covariates=z$cov,
      outer_splits=3L,inner_splits=2L,selection_rule="one_se",
      shuffle=TRUE,random_state=19L,random_engine="numpy",
      strict_source_record=TRUE)
    for(pair in list(list(native=native_cv,py=py_cv,
        fields=c("fold_losses","assignments","predictions")),
      list(native=native_nc,py=py_nc,
        fields=c("outer_folds","inner_summaries","predictions")))){
      for(field in pair$fields){
        expected<-et_to_r(reticulate::py_get_attr(pair$py,field))
        .etr_fpcr_two_cv_compare_frame(pair$native[[field]],
          expected,paste(family,field))
      }
      expected_provenance<-et_to_r(pair$py$provenance)
      expect_identical(names(pair$native$provenance),
        names(expected_provenance))
      for(key in names(expected_provenance))
        expect_equal(pair$native$provenance[[key]],
          expected_provenance[[key]],ignore_attr=TRUE,
          info=paste(family,"provenance",key))
    }
    expect_equal(native_cv$component_counts,
      et_to_r(py_cv$component_counts),ignore_attr=TRUE)
    expect_equal(native_nc$component_counts,
      et_to_r(py_nc$component_counts),ignore_attr=TRUE)
  }
})
