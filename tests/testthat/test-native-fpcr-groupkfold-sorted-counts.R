# Frozen eyetrajectoriespy 1.2.0 prediction.py grouped FPCR:
# sklearn GroupKFold, source-backed sorted group-size subdomain only.
.etr_fpcr_sorted_group_fixture <- function(counts=c(1L,1L,2L,2L,3L,3L)) {
  stopifnot(sum(counts)==12L, length(counts)>=3L)
  t <- seq(0,1,length.out=5L)
  a <- seq(-2,2,length.out=12L)
  b <- c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7)
  v <- array(0,c(12L,5L,1L))
  for(i in seq_len(12L))
    v[i,,1L] <- .2+a[i]*sin(pi*t)+b[i]*cos(2*pi*t)
  y <- 1+.5*a-.2*b+.03*c(0,1,-1,0,1,-1,0,1,-1,0,1,-1)
  gr <- rep(sprintf("P%02d",seq_along(counts)),counts)
  x <- etr_trajectory_set(t,v,paste0("curve",1:12),"x",
    metadata=data.frame(participant=gr,stringsAsFactors=FALSE),
    coordinate_system="normalized",time_unit="normalized")
  list(x=x,y=y,group=gr)
}

test_that("ascending sorted group counts match GroupKFold observed fold IDs",{
  z <- .etr_fpcr_sorted_group_fixture()
  actual <- etr_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=c(1L,2L),
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=TRUE,random_state=11L)
  expected <- c(1L,0L,rep(2L,4L),rep(1L,3L),rep(0L,3L))
  expect_identical(actual$assignments$fold,expected)
  expect_identical(actual$assignments$group,z$group)
  expect_identical(as.integer(table(actual$assignments$fold)),rep(4L,3L))
  expect_identical(actual$random_state,NULL)
  for(g in unique(z$group)) {
    expect_length(unique(actual$assignments$fold[
      actual$assignments$group==g]),1L)
  }
  expect_true(all(is.finite(actual$predictions$prediction)))
  nested <- etr_nested_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=c(1L,2L),
    outer_splits=3L,inner_splits=2L,selection_rule="minimum",
    cv_unit="group",group_column="participant",
    shuffle=TRUE,random_state=11L)
  expect_identical(nrow(nested$outer_folds),3L)
  expect_identical(nrow(nested$predictions),12L)
  for(g in unique(z$group)) {
    expect_length(unique(nested$predictions$outer_fold[
      nested$predictions$group==g]),1L)
  }
})

test_that("mixed-size nonmonotone group counts preserve native fallback",{
  z <- .etr_fpcr_sorted_group_fixture(c(2L,1L,2L,1L,3L,3L))
  actual <- etr_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=1L,
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=FALSE)
  expect_identical(actual$assignments$fold,
    c(rep(2L,2L),0L,rep(2L,2L),1L,rep(0L,3L),rep(1L,3L)))
  expect_true(actual$provenance$group_leakage_prevented)
})

test_that("frozen Python 1.2 grouped CV and nested CV match ascending group-size strata",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 sorted-stratum GroupKFold source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_sc_time=np.linspace(0,1,5);_sc_a=np.linspace(-2,2,12)
_sc_b=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
_sc_vals=np.array([.2+a*np.sin(np.pi*_sc_time)+b*np.cos(2*np.pi*_sc_time)
                   for a,b in zip(_sc_a,_sc_b)])[:,:,None]
_sc_y=1+.5*_sc_a-.2*_sc_b+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
_sc_groups=np.repeat([f'P{i:02d}' for i in range(1,7)],[1,1,2,2,3,3])
_sc_x=et.TrajectorySet(time=_sc_time,values=_sc_vals,
 curve_ids=tuple('curve'+str(i) for i in range(1,13)),
 dimension_names=('x',),
 metadata=pd.DataFrame({'participant':_sc_groups}),
 coordinate_system='normalized',time_unit='normalized')
_sc_cv=et.cross_validate_fpca_regression(
 _sc_x,_sc_y,candidate_components=(1,2),n_splits=3,
 cv_unit='group',group_column='participant',shuffle=True,random_state=11)
_sc_nested=et.nested_cross_validate_fpca_regression(
 _sc_x,_sc_y,candidate_components=(1,2),
 outer_splits=3,inner_splits=2,selection_rule='minimum',
 cv_unit='group',group_column='participant',shuffle=True,random_state=11)
")
  z <- .etr_fpcr_sorted_group_fixture()
  native_cv <- etr_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=c(1L,2L),n_splits=3L,
    cv_unit="group",group_column="participant",shuffle=TRUE,random_state=11L)
  native_nested <- etr_nested_cross_validate_fpca_regression(
    z$x,z$y,candidate_components=c(1L,2L),
    outer_splits=3L,inner_splits=2L,selection_rule="minimum",
    cv_unit="group",group_column="participant",shuffle=TRUE,random_state=11L)
  for(pair in list(
    list(native=native_cv, source="_sc_cv",
         fields=c("fold_losses","assignments","predictions")),
    list(native=native_nested, source="_sc_nested",
         fields=c("outer_folds","inner_summaries","predictions")))) {
    direct <- if(identical(pair$source,"_sc_cv"))
      reticulate::py_call(
        etpy_get_export("cross_validate_fpca_regression"),
        trajectories=reticulate::py_eval("_sc_x",convert=FALSE),
        outcome=reticulate::py_eval("_sc_y",convert=FALSE),
        candidate_components=reticulate::py_eval("(1,2)",convert=FALSE),
        n_splits=3L,cv_unit="group",group_column="participant",
        shuffle=TRUE,random_state=11L)
    else
      reticulate::py_call(
        etpy_get_export("nested_cross_validate_fpca_regression"),
        trajectories=reticulate::py_eval("_sc_x",convert=FALSE),
        outcome=reticulate::py_eval("_sc_y",convert=FALSE),
        candidate_components=reticulate::py_eval("(1,2)",convert=FALSE),
        outer_splits=3L,inner_splits=2L,selection_rule="minimum",
        cv_unit="group",group_column="participant",
        shuffle=TRUE,random_state=11L)
    for(field in pair$fields) {
      expected <- et_to_r(reticulate::py_eval(
        paste0(pair$source,".",field),convert=FALSE))
      replay <- et_to_r(reticulate::py_get_attr(direct,field))
      expect_equal(replay,expected,tolerance=1e-8,ignore_attr=TRUE)
      actual <- pair$native[[field]]
      expect_identical(names(actual),names(expected))
      expect_identical(nrow(actual),nrow(expected))
      for(column in names(expected)) {
        if(is.numeric(actual[[column]]))
          expect_equal(as.numeric(actual[[column]]),
            as.numeric(expected[[column]]),tolerance=1e-8,
            info=paste("sorted-stratum GroupKFold",pair$source,field,column))
        else
          expect_identical(as.character(actual[[column]]),
            as.character(expected[[column]]))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
