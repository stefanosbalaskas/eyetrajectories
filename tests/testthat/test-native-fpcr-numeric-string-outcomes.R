# Frozen eyetrajectoriespy==1.2.0 prediction.py::_validate_outcome:
# np.asarray(outcome,dtype=float) before all FPCA and model fitting.
# Source-bounded decimal character outcome conversion; not certification.

.etr_fpcr_character_outcome_fixture<-function() {
  t<-seq(0,1,length.out=7L);n<-36L
  a<-seq(-2,2,length.out=n)
  b<-rep(c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7),3L)
  v<-array(0,c(n,7L,1L))
  for(i in seq_len(n))
    v[i,,1L]<-.2+a[i]*sin(pi*t)+b[i]*cos(2*pi*t)
  y<-as.numeric(rep(c(0,1,1,0,1,0,0,1,0,1,1,0),3L))
  texts<-as.character(y)
  texts[1L]<-" 0 "
  texts[2L]<-" +1e0 "
  texts[3L]<-"1."
  texts[4L]<-"0.0"
  texts[5L]<-".1e1"
  texts[6L]<-"-0."
  x<-etr_trajectory_set(t,v,paste0("curve",seq_len(n)),"x",
    metadata=data.frame(participant=rep(sprintf("P%02d",1:6),each=6L),
      stringsAsFactors=FALSE),
    coordinate_system="normalized",time_unit="normalized")
  list(x=x,y=y,texts=texts)
}

test_that("numeric-string outcomes give identical native Gaussian and binomial fold models",{
  z<-.etr_fpcr_character_outcome_fixture()
  for(family in c("gaussian","binomial")){
    run<-function(y)etr_cross_validate_fpca_regression(
      z$x,y,candidate_components=c(1L,2L),
      family=family,n_splits=3L,cv_unit="group",
      group_column="participant",shuffle=FALSE,
      loss=if(identical(family,"gaussian"))"mae" else "brier")
    a<-run(z$texts);b<-run(z$y)
    expect_identical(a$family,family)
    expect_identical(a$component_counts,b$component_counts)
    expect_identical(a$assignments,b$assignments)
    expect_equal(a$fold_losses,b$fold_losses,tolerance=1e-12)
    expect_equal(a$predictions,b$predictions,tolerance=1e-12)
    expect_true(is.numeric(a$predictions$observed))
    expect_true(all(a$predictions$observed%in%c(0,1)))
  }
})

test_that("numeric-string outcomes preserve Gaussian and binomial nested selection",{
  z<-.etr_fpcr_character_outcome_fixture()
  for(family in c("gaussian","binomial")){
    run<-function(y)etr_nested_cross_validate_fpca_regression(
      z$x,y,candidate_components=c(1L,2L),family=family,
      outer_splits=3L,inner_splits=2L,
      loss=if(identical(family,"gaussian"))"rmse" else "brier",
      selection_rule="minimum",cv_unit="group",
      group_column="participant",shuffle=FALSE)
    a<-run(z$texts);b<-run(z$y)
    expect_identical(a$family,family)
    expect_equal(a$outer_folds,b$outer_folds,tolerance=1e-12)
    expect_equal(a$inner_summaries,b$inner_summaries,tolerance=1e-12)
    expect_equal(a$predictions,b$predictions,tolerance=1e-12)
    expect_true(is.numeric(a$predictions$observed))
  }
})

test_that("malformed and nonfinite numeric strings fail explicitly",{
  z<-.etr_fpcr_character_outcome_fixture()
  for(bad in c("NaN","Inf","-Infinity","", " ", "abc",
               "2_000","0x10","1,000","1e309")){
    y<-z$texts;y[1L]<-bad
    expect_error(etr_cross_validate_fpca_regression(z$x,y,
      family="binomial",n_splits=3L,shuffle=FALSE),
      "one finite scalar",info=bad)
    expect_error(etr_nested_cross_validate_fpca_regression(z$x,y,
      family="binomial",outer_splits=3L,inner_splits=2L,
      shuffle=FALSE),"finite and curve aligned",info=bad)
  }
  y<-z$texts;y[1L]<-NA_character_
  expect_error(etr_cross_validate_fpca_regression(z$x,y,
    family="gaussian",n_splits=3L,shuffle=FALSE),
    "one finite scalar")
  y<-z$texts;y[1L]<-"2"
  expect_error(etr_cross_validate_fpca_regression(z$x,y,
    family="binomial",n_splits=3L,shuffle=FALSE),
    "binomial outcome must contain only 0/1 values")
  expect_error(etr_cross_validate_fpca_regression(
    z$x,factor(z$texts),family="binomial",n_splits=3L,
    shuffle=FALSE),"one finite scalar")
  expect_error(etr_cross_validate_fpca_regression(
    z$x,matrix(z$texts,ncol=1L),family="binomial",
    n_splits=3L,shuffle=FALSE),"one finite scalar")
})

test_that("frozen Python 1.2 decimal outcome FPCR CV and nested match native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 numeric-string outcome oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_os_t=np.linspace(0,1,7);_os_a=np.linspace(-2,2,36)
_os_b=np.tile([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7],3)
_os_v=np.array([.2+a*np.sin(np.pi*_os_t)+b*np.cos(2*np.pi*_os_t)
                for a,b in zip(_os_a,_os_b)])[:,:,None]
_os_n=np.tile([0,1,1,0,1,0,0,1,0,1,1,0],3).astype(float)
_os_s=[str(int(z)) for z in _os_n]
_os_s[0]=' 0 ';_os_s[1]=' +1e0 ';_os_s[2]='1.'
_os_s[3]='0.0';_os_s[4]='.1e1';_os_s[5]='-0.'
_os_x=et.TrajectorySet(time=_os_t,values=_os_v,
 curve_ids=tuple('curve'+str(i) for i in range(1,37)),
 dimension_names=('x',),metadata=pd.DataFrame({
 'participant':np.repeat([f'P{i:02d}' for i in range(1,7)],6)}),
 coordinate_system='normalized',time_unit='normalized')
_os_cv=et.cross_validate_fpca_regression(
 _os_x,_os_s,candidate_components=(1,2),family='binomial',
 loss='brier',n_splits=3,cv_unit='group',
 group_column='participant',shuffle=False)
_os_nested=et.nested_cross_validate_fpca_regression(
 _os_x,_os_s,candidate_components=(1,2),family='binomial',
 loss='brier',outer_splits=3,inner_splits=2,
 selection_rule='minimum',cv_unit='group',
 group_column='participant',shuffle=False)
")
  z<-.etr_fpcr_character_outcome_fixture()
  a<-etr_cross_validate_fpca_regression(z$x,z$texts,
    candidate_components=c(1L,2L),family="binomial",
    loss="brier",n_splits=3L,cv_unit="group",
    group_column="participant",shuffle=FALSE)
  b<-etr_nested_cross_validate_fpca_regression(z$x,z$texts,
    candidate_components=c(1L,2L),family="binomial",
    loss="brier",outer_splits=3L,inner_splits=2L,
    selection_rule="minimum",cv_unit="group",
    group_column="participant",shuffle=FALSE)
  for(pair in list(
    list(native=a,source="_os_cv",
      fields=c("fold_losses","assignments","predictions")),
    list(native=b,source="_os_nested",
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
            info=paste("string outcome source oracle",pair$source,field,column))
        else
          expect_identical(as.character(actual[[column]]),
            as.character(expected[[column]]))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
