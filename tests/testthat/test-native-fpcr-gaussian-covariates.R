# Source: frozen eyetrajectoriespy 1.2.0 prediction.py
# ::_validate_covariates, cross_validate_fpca_regression and
# nested_cross_validate_fpca_regression.
# Numeric Gaussian subset only. Python oracle is explicitly opt-in.

.etr_fpcr_covariate_fixture <- function() {
  t <- seq(0,1,length.out=5L); n <- 12L
  a <- seq(-2,2,length.out=n)
  b <- c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7)
  w <- c(.2,-.7,.9,0,-.3,.5,1.2,-1.1,.4,-.9,.6,-.2)
  v <- array(0,c(n,5L,1L))
  for(i in seq_len(n))
    v[i,,1L] <- .2+a[i]*sin(pi*t)+b[i]*cos(2*pi*t)
  y <- 1+.5*a-.2*b+.8*w+
    .03*c(0,1,-1,0,1,-1,0,1,-1,0,1,-1)
  grp <- c(rep("P01",5L),rep("P02",4L),rep("P03",3L))
  trajectories <- etr_trajectory_set(t,v,
    paste0("curve",seq_len(n)),"x",
    metadata=data.frame(participant=grp,stringsAsFactors=FALSE),
    coordinate_system="normalized",time_unit="normalized")
  list(x=trajectories,y=y,cov=data.frame(w=w),group=grp)
}

test_that("Gaussian FPCR numeric covariates are fitted within held-out folds",{
  z <- .etr_fpcr_covariate_fixture()
  ans <- etr_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=c(1L,2L),covariates=z$cov,
    n_splits=3L,shuffle=FALSE)
  expect_s3_class(ans,"etr_fpcr_regression_cv")
  expect_identical(ans$provenance$covariates,list("w"))
  expect_identical(nrow(ans$predictions),24L)
  expect_true(all(is.finite(ans$predictions$prediction)))
  without <- etr_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=c(1L,2L),n_splits=3L,shuffle=FALSE)
  expect_gt(max(abs(ans$predictions$prediction-
    without$predictions$prediction)),1e-7)
  for(i in seq_len(nrow(ans$fold_losses))) {
    entry <- ans$fold_losses[i,]
    rows <- ans$predictions[
      ans$predictions$fold==entry$fold &
      ans$predictions$n_components==entry$n_components,]
    expect_equal(entry$loss,
      sqrt(mean((rows$observed-rows$prediction)^2)),tolerance=1e-12)
  }
  # Held-out outcomes must not affect the estimates used to predict
  # their own fold; they may only affect the reported test losses.
  held <- which(ans$assignments$fold==0L)
  idx <- match(ans$assignments$curve_id[held],z$x$curve_ids)
  modified <- z$y;modified[idx] <- modified[idx]+50
  moved <- etr_cross_validate_fpca_regression(z$x,modified,
    candidate_components=c(1L,2L),covariates=z$cov,
    n_splits=3L,shuffle=FALSE)
  left <- ans$predictions$fold==0L
  expect_equal(ans$predictions$prediction[left],
    moved$predictions$prediction[left],tolerance=1e-12)
})

test_that("nested Gaussian FPCR covariates stay aligned across both fold layers",{
  z <- .etr_fpcr_covariate_fixture()
  for(rule in c("minimum","one_se")) {
    run <- function(y) etr_nested_cross_validate_fpca_regression(
      z$x,y,candidate_components=1L,
      covariates=z$cov,outer_splits=3L,inner_splits=2L,
      selection_rule=rule,cv_unit="group",
      group_column="participant",shuffle=FALSE)
    ans <- run(z$y)
    expect_s3_class(ans,"etr_nested_fpcr_cv")
    expect_identical(ans$provenance$covariates,list("w"))
    expect_identical(nrow(ans$outer_folds),3L)
    expect_identical(nrow(ans$predictions),12L)
    for(f in 0:2){
      rows <- ans$predictions[ans$predictions$outer_fold==f,]
      expect_equal(ans$outer_folds$loss[f+1L],
        sqrt(mean((rows$observed-rows$prediction)^2)),
        tolerance=1e-12)
      expect_identical(length(unique(rows$group)),1L)
    }
    held <- ans$predictions$outer_fold==0L
    idx <- match(ans$predictions$curve_id[held],z$x$curve_ids)
    altered <- z$y;altered[idx] <- altered[idx]+100
    after <- run(altered)
    expect_equal(ans$predictions$prediction[held],
      after$predictions$prediction[held],tolerance=1e-12)
    expect_identical(ans$outer_folds$selected_n_components[1L],
      after$outer_folds$selected_n_components[1L])
  }
})

test_that("FPCR covariates reject source-reserved or nonfinite input domains",{
  z <- .etr_fpcr_covariate_fixture()
  f <- function(cv, ...) {
    if(cv) etr_cross_validate_fpca_regression(z$x,z$y,
      candidate_components=1L,n_splits=3L,covariates=...)
    else etr_nested_cross_validate_fpca_regression(z$x,z$y,
      candidate_components=1L,outer_splits=3L,inner_splits=2L,
      covariates=...)
  }
  bads <- list(
    data.frame(w=1:11),
    data.frame(const=1:12),
    data.frame(FPC1=1:12),
    data.frame(FPC02=1:12),
    data.frame(w=letters[1:12]),
    data.frame(w=factor(rep(c("1","2"),6L))),
    data.frame(w=c(1:11,NA_real_)),
    data.frame(w=c(1:11,Inf)))
  dup <- data.frame(a=1:12,b=12:1)
  names(dup) <- c("a","a")
  bads <- c(bads,list(dup))
  for(bad in bads)
    for(cv in c(TRUE,FALSE))
      expect_error(f(cv,bad),regexp="covariate")
  # Perfectly duplicated columns must fail inside the Gaussian OLS fold.
  duplicated <- data.frame(w=z$cov$w,w_copy=z$cov$w)
  expect_error(f(TRUE,duplicated),regexp="full-rank")
  expect_error(f(FALSE,duplicated),regexp="rank deficient|full-rank")
  for(cv in c(TRUE,FALSE)) {
    valid <- data.frame(flag=rep(c(TRUE,FALSE),6L))
    expect_silent(f(cv,valid))
  }
})

test_that("curve-level nested covariates preserve nontrivial inner FPC selection",{
  z <- .etr_fpcr_covariate_fixture()
  for(rule in c("minimum","one_se")) {
    run <- function(y) etr_nested_cross_validate_fpca_regression(
      z$x,y,candidate_components=c(1L,2L),covariates=z$cov,
      outer_splits=3L,inner_splits=2L,selection_rule=rule,
      cv_unit="curve",shuffle=FALSE)
    original <- run(z$y)
    expect_s3_class(original,"etr_nested_fpcr_cv")
    expect_identical(original$component_counts,c(1L,2L))
    expect_identical(nrow(original$inner_summaries),6L)
    expect_true(all(original$outer_folds$selected_n_components %in% c(1L,2L)))
    first <- original$predictions$outer_fold==0L
    id <- match(original$predictions$curve_id[first],z$x$curve_ids)
    perturbed <- z$y;perturbed[id] <- perturbed[id]+50
    moved <- run(perturbed)
    expect_equal(original$predictions$prediction[first],
      moved$predictions$prediction[first],tolerance=1e-12)
    expect_identical(original$outer_folds$selected_n_components[1L],
      moved$outer_folds$selected_n_components[1L])
  }
})

test_that("pinned Python 1.2 finite-covariate Gaussian FPCR agrees on fixed folds",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 numeric Gaussian FPCR covariate oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd
import eyetrajectoriespy as et
_t=np.linspace(0,1,5);_a=np.linspace(-2,2,12)
_b=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
_w=np.array([.2,-.7,.9,0,-.3,.5,1.2,-1.1,.4,-.9,.6,-.2])
_v=np.array([.2+i*np.sin(np.pi*_t)+j*np.cos(2*np.pi*_t)
             for i,j in zip(_a,_b)])[:,:,None]
_y=1+.5*_a-.2*_b+.8*_w+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
_group=['P01']*5+['P02']*4+['P03']*3
_x=et.TrajectorySet(time=_t,values=_v,
 curve_ids=tuple('curve'+str(i) for i in range(1,13)),
 dimension_names=('x',),
 metadata=pd.DataFrame({'participant':_group}),
 coordinate_system='normalized',time_unit='normalized')
_cov=pd.DataFrame({'w':_w})
_src_cv=et.cross_validate_fpca_regression(
 _x,_y,candidate_components=(1,2),covariates=_cov,
 n_splits=3,cv_unit='group',group_column='participant',shuffle=False)
_src_nested=et.nested_cross_validate_fpca_regression(
 _x,_y,candidate_components=(1,),covariates=_cov,
 outer_splits=3,inner_splits=2,cv_unit='group',
 group_column='participant',selection_rule='minimum',shuffle=False)
")
  z <- .etr_fpcr_covariate_fixture()
  cv <- etr_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=c(1L,2L),covariates=z$cov,
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=FALSE)
  nested <- etr_nested_cross_validate_fpca_regression(z$x,z$y,
    candidate_components=1L,covariates=z$cov,
    outer_splits=3L,inner_splits=2L,
    cv_unit="group",group_column="participant",
    selection_rule="minimum",shuffle=FALSE)
  for(pair in list(list(native=cv,source="_src_cv",
    fields=c("fold_losses","assignments","predictions")),
    list(native=nested,source="_src_nested",
      fields=c("outer_folds","inner_summaries","predictions")))){
    for(field in pair$fields) {
      expected <- reticulate::py_to_r(reticulate::py_eval(
        paste0(pair$source,".",field),convert=FALSE))
      actual <- pair$native[[field]]
      expect_identical(names(actual),names(expected))
      expect_identical(nrow(actual),nrow(expected))
      for(column in names(expected)) {
        if(is.numeric(actual[[column]]))
          expect_equal(as.numeric(actual[[column]]),
            as.numeric(expected[[column]]),tolerance=1e-8,
            info=paste(pair$source,field,column))
        else
          expect_identical(as.character(actual[[column]]),
            as.character(expected[[column]]))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
