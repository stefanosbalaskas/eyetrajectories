# Frozen eyetrajectoriespy==1.2.0 prediction.py binomial FPCR subset.
# Logit GLM uses stats::glm.fit, not statsmodels IRLS. Paired direct
# source oracle is opt-in; this is not full-domain certification.

.etr_binomial_fpcr_fixture<-function(){
  n<-36L;t<-seq(0,1,length.out=7L)
  a<-seq(-2,2,length.out=n)
  b<-rep(c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7),3L)
  w<-rep(c(.2,-.7,.9,0,-.3,.5,1.2,-1.1,.4,-.9,.6,-.2),3L)
  y<-rep(c(0,1,1,0,1,0,0,1,0,1,1,0),3L)
  values<-array(0,c(n,7L,1L))
  for(i in seq_len(n))
    values[i,,1L]<-.2+a[i]*sin(pi*t)+b[i]*cos(2*pi*t)
  groups<-rep(sprintf("P%02d",1:6),each=6L)
  x<-etr_trajectory_set(t,values,paste0("curve",seq_len(n)),"x",
    metadata=data.frame(participant=groups,stringsAsFactors=FALSE),
    coordinate_system="normalized",time_unit="normalized")
  list(x=x,y=y,cov=data.frame(w=w),groups=groups)
}

test_that("fold-local binomial FPCR produces probabilities and source losses",{
  z<-.etr_binomial_fpcr_fixture()
  for(loss in c("log_loss","brier")) {
    a<-etr_cross_validate_fpca_regression(z$x,z$y,
      candidate_components=c(1L,2L),family="binomial",loss=loss,
      covariates=z$cov,n_splits=3L,
      cv_unit="group",group_column="participant",shuffle=FALSE)
    expect_s3_class(a,"etr_fpcr_regression_cv")
    expect_identical(a$family,"binomial")
    expect_identical(a$loss,loss)
    expect_identical(nrow(a$predictions),72L)
    expect_identical(nrow(a$fold_losses),6L)
    expect_true(all(is.finite(a$predictions$prediction)))
    expect_true(all(a$predictions$prediction>0&
                    a$predictions$prediction<1))
    expect_identical(a$provenance$covariates,list("w"))
    for(i in seq_len(nrow(a$fold_losses))) {
      fold<-a$fold_losses[i,]
      rows<-a$predictions[
        a$predictions$fold==fold$fold&
        a$predictions$n_components==fold$n_components,]
      p<-pmax(.Machine$double.eps,pmin(1-.Machine$double.eps,
                                      rows$prediction))
      expected<-if(identical(loss,"brier"))
        mean((rows$observed-p)^2) else
        -mean(rows$observed*log(p)+(1-rows$observed)*log1p(-p))
      expect_equal(fold$loss,expected,tolerance=1e-12)
    }
    # Held-out labels cannot influence their own fold probability fit.
    held<-a$assignments$curve_id[a$assignments$fold==0L]
    ids<-match(held,z$x$curve_ids)
    changed<-z$y;changed[ids]<-1-changed[ids]
    moved<-etr_cross_validate_fpca_regression(z$x,changed,
      candidate_components=c(1L,2L),family="binomial",loss=loss,
      covariates=z$cov,n_splits=3L,
      cv_unit="group",group_column="participant",shuffle=FALSE)
    self<-a$predictions$fold==0L
    expect_equal(a$predictions$prediction[self],
      moved$predictions$prediction[self],tolerance=1e-10)
  }
})

test_that("nested binomial FPCR keeps selection out of outer test labels",{
  z<-.etr_binomial_fpcr_fixture()
  for(rule in c("minimum","one_se")) {
    run<-function(y)etr_nested_cross_validate_fpca_regression(z$x,y,
      candidate_components=c(1L,2L),family="binomial",loss="brier",
      covariates=z$cov,outer_splits=3L,inner_splits=2L,
      selection_rule=rule,cv_unit="group",
      group_column="participant",shuffle=FALSE)
    a<-run(z$y)
    expect_s3_class(a,"etr_nested_fpcr_cv")
    expect_identical(a$family,"binomial")
    expect_identical(a$loss,"brier")
    expect_identical(nrow(a$outer_folds),3L)
    expect_identical(nrow(a$inner_summaries),6L)
    expect_identical(nrow(a$predictions),36L)
    expect_true(all(a$outer_folds$selected_n_components%in%c(1L,2L)))
    expect_true(all(a$predictions$prediction>=0&
                    a$predictions$prediction<=1))
    for(i in 0:2) {
      rows<-a$predictions[a$predictions$outer_fold==i,]
      expect_equal(a$outer_folds$loss[i+1L],
        mean((rows$observed-rows$prediction)^2),tolerance=1e-12)
      expect_length(unique(rows$group),2L)
    }
    held<-a$predictions$curve_id[a$predictions$outer_fold==0L]
    idx<-match(held,z$x$curve_ids)
    changed<-z$y;changed[idx]<-1-changed[idx]
    moved<-run(changed)
    self<-a$predictions$outer_fold==0L
    expect_equal(a$predictions$prediction[self],
      moved$predictions$prediction[self],tolerance=1e-10)
    expect_identical(a$outer_folds$selected_n_components[1L],
      moved$outer_folds$selected_n_components[1L])
  }
})

test_that("binomial source domain rejects invalid labels and fold classes",{
  z<-.etr_binomial_fpcr_fixture()
  cv<-function(y,...)
    etr_cross_validate_fpca_regression(z$x,y,candidate_components=1L,
      family="binomial",n_splits=3L,shuffle=FALSE,...)
  nested<-function(y,...)
    etr_nested_cross_validate_fpca_regression(z$x,y,
      candidate_components=1L,family="binomial",
      outer_splits=3L,inner_splits=2L,shuffle=FALSE,...)
  for(bad in list(rep(.5,36L),rep(2,36L),
                  c(rep(0,35L),NA_real_))) {
    expect_error(cv(bad),"binomial outcome|finite scalar")
    expect_error(nested(bad),"binomial outcome|finite and curve")
  }
  expect_error(cv(rep(0,36L)),"each binomial training fold")
  expect_error(nested(rep(0,36L)),"each binomial training fold")
  expect_error(cv(z$y,loss="rmse"),"binomial loss")
  expect_error(nested(z$y,loss="mae"),"binomial loss")
  expect_error(cv(z$y,family="invalid"),"formal argument|family")
  # A single monotonic threshold in FPC1 is separated or nearly separated.
  # The native GLM must fail explicitly instead of silently returning
  # misleading boundary probabilities.
  separated<-as.numeric(seq_len(36L)>18L)
  expect_error(cv(separated),"binomial FPCA regression")
})

test_that("pinned Python 1.2 binomial CV and nested predictive tables agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 binomial FPCR source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_bp_t=np.linspace(0,1,7);_bp_a=np.linspace(-2,2,36)
_bp_b=np.tile([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7],3)
_bp_w=np.tile([.2,-.7,.9,0,-.3,.5,1.2,-1.1,.4,-.9,.6,-.2],3)
_bp_y=np.tile([0,1,1,0,1,0,0,1,0,1,1,0],3).astype(float)
_bp_v=np.array([.2+a*np.sin(np.pi*_bp_t)+b*np.cos(2*np.pi*_bp_t)
                for a,b in zip(_bp_a,_bp_b)])[:,:,None]
_bp_x=et.TrajectorySet(time=_bp_t,values=_bp_v,
 curve_ids=tuple('curve'+str(i) for i in range(1,37)),
 dimension_names=('x',),
 metadata=pd.DataFrame({'participant':np.repeat(
 [f'P{i:02d}' for i in range(1,7)],6)}),
 coordinate_system='normalized',time_unit='normalized')
_bp_cov=pd.DataFrame({'w':_bp_w})
_bp_cv=et.cross_validate_fpca_regression(
 _bp_x,_bp_y,candidate_components=(1,2),family='binomial',
 loss='log_loss',covariates=_bp_cov,n_splits=3,
 cv_unit='group',group_column='participant',shuffle=False)
_bp_nested=et.nested_cross_validate_fpca_regression(
 _bp_x,_bp_y,candidate_components=(1,2),family='binomial',
 loss='brier',covariates=_bp_cov,outer_splits=3,
 inner_splits=2,selection_rule='minimum',
 cv_unit='group',group_column='participant',shuffle=False)
")
  z<-.etr_binomial_fpcr_fixture()
  native_cv<-etr_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=c(1L,2L),family="binomial",loss="log_loss",
    covariates=z$cov,n_splits=3L,cv_unit="group",
    group_column="participant",shuffle=FALSE)
  native_nested<-etr_nested_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=c(1L,2L),family="binomial",loss="brier",
    covariates=z$cov,outer_splits=3L,inner_splits=2L,
    selection_rule="minimum",cv_unit="group",
    group_column="participant",shuffle=FALSE)
  for(pair in list(
    list(native=native_cv,source="_bp_cv",
      fields=c("fold_losses","assignments","predictions")),
    list(native=native_nested,source="_bp_nested",
      fields=c("outer_folds","inner_summaries","predictions")))) {
    for(field in pair$fields) {
      expected<-et_to_r(reticulate::py_eval(
        paste0(pair$source,".",field),convert=FALSE))
      actual<-pair$native[[field]]
      expect_identical(names(actual),names(expected))
      expect_identical(nrow(actual),nrow(expected))
      for(column in names(expected)) {
        if(is.numeric(actual[[column]]))
          expect_equal(as.numeric(actual[[column]]),
            as.numeric(expected[[column]]),tolerance=1e-5,
            info=paste("binomial source oracle",pair$source,field,column))
        else
          expect_identical(as.character(actual[[column]]),
            as.character(expected[[column]]))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
