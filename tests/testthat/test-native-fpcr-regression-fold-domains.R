# Frozen Python 1.2 prediction.py::cross_validate_fpca_regression
# Source c1cd95ad718327550f7e55393ff38582872f7a94.
# Native group and shuffled curve predictive CV; R does not emulate NumPy RNG.
# Full Python typed-domain parity and independent certification remain open.

.etr_fpcr_group_fixture<-function(){
  time<-seq(0,1,length.out=5L)
  n<-12L
  z1<-seq(-2,2,length.out=n)
  z2<-c(1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7)
  values<-array(0,c(n,5L,1L))
  for(i in seq_len(n))
    values[i,,1L]<-.2+z1[i]*sin(pi*time)+z2[i]*cos(2*pi*time)
  y<-1+.5*z1-.2*z2+.03*c(0,1,-1,0,1,-1,0,1,-1,0,1,-1)
  groups<-c(rep("P01",5L),rep("P02",4L),rep("P03",3L))
  trajectories<-etr_trajectory_set(time,values,
    paste0("curve",seq_len(n)),"x",
    metadata=data.frame(participant=groups,stringsAsFactors=FALSE),
    coordinate_system="normalized",time_unit="normalized")
  list(trajectories=trajectories,outcome=y,groups=groups)
}

test_that("held-out group FPCR keeps participants out of their training folds",{
  z<-.etr_fpcr_group_fixture()
  ans<-etr_cross_validate_fpca_regression(z$trajectories,z$outcome,
    candidate_components=c(1L,2L),n_splits=3L,cv_unit="group",
    group_column="participant",shuffle=TRUE,random_state=100L)
  expect_s3_class(ans,"etr_fpcr_regression_cv")
  expect_identical(ans$cv_unit,"group")
  expect_identical(ans$group_column,"participant")
  expect_identical(ans$random_state,NULL)
  expect_true(ans$provenance$group_leakage_prevented)
  expect_false(ans$provenance$shuffle)
  expect_identical(names(ans$assignments),c("curve_id","fold","group"))
  expect_identical(nrow(ans$assignments),12L)
  expect_identical(nrow(ans$predictions),24L)
  expect_identical(nrow(ans$fold_losses),6L)
  # Source GroupKFold gives 5/4/3 unique size participant blocks.
  expect_identical(as.integer(table(ans$assignments$fold)),
    c(5L,4L,3L))
  expect_identical(length(unique(ans$assignments$group)),3L)
  for(g in unique(ans$assignments$group))
    expect_identical(length(unique(ans$assignments$fold[
      ans$assignments$group==g])),1L)
  for(k in c(1L,2L)){
    rows<-ans$predictions[ans$predictions$n_components==k,]
    expect_identical(sort(rows$curve_id),
      sort(z$trajectories$curve_ids))
    expect_true(all(is.finite(rows$prediction)))
    for(f in 0:2){
      current<-rows[rows$fold==f,]
      expected<-sqrt(mean((current$observed-current$prediction)^2))
      loss<-ans$fold_losses$loss[
        ans$fold_losses$fold==f&
        ans$fold_losses$n_components==k]
      expect_equal(loss,expected,tolerance=1e-12)
    }
  }
  another<-etr_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=c(1L,2L),
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=FALSE,random_state=42L)
  expect_identical(ans$assignments,another$assignments)
  expect_identical(ans$predictions,another$predictions)
})

test_that("R-seeded shuffled curve FPCR is deterministic without changing global RNG",{
  z<-.etr_fpcr_group_fixture()
  set.seed(126L);before<-.Random.seed
  run<-function(seed)etr_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=c(1L,2L),
    n_splits=3L,cv_unit="curve",shuffle=TRUE,random_state=seed)
  a<-run(202L)
  expect_identical(.Random.seed,before)
  b<-run(202L)
  expect_identical(.Random.seed,before)
  expect_identical(a$assignments,b$assignments)
  expect_identical(a$predictions,b$predictions)
  expect_identical(a$fold_losses,b$fold_losses)
  expect_identical(a$random_state,202L)
  expect_identical(a$provenance$random_engine,
    "base_R_sample_not_NumPy")
  expect_true(a$provenance$shuffle)
  expect_false(a$provenance$group_leakage_prevented)
  expect_identical(sort(a$assignments$curve_id),
    sort(z$trajectories$curve_ids))
  expect_identical(as.integer(table(a$assignments$fold)),
    rep.int(4L,3L))
  no_shuffle<-etr_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=1L,
    n_splits=3L,shuffle=FALSE)
  expect_identical(no_shuffle$assignments$fold,rep(0:2,each=4L))
  expect_identical(no_shuffle$random_state,NULL)
})

test_that("group FPCR rejects missing group IDs and insufficient distinct groups",{
  z<-.etr_fpcr_group_fixture()
  f<-etr_cross_validate_fpca_regression
  expect_error(f(z$trajectories,z$outcome,n_splits=3L,
    cv_unit="group",group_column="absent"),"group_column")
  bad<-z$trajectories
  bad$metadata$participant[2L]<-NA_character_
  expect_error(f(bad,z$outcome,n_splits=3L,
    cv_unit="group",group_column="participant"),"nonmissing")
  expect_error(f(z$trajectories,z$outcome,n_splits=4L,
    cv_unit="group",group_column="participant"),"unique groups")
  expect_error(f(z$trajectories,z$outcome,shuffle=TRUE,
    random_state=-1L),"nonnegative R integer seed")
  expect_error(f(z$trajectories,z$outcome,shuffle=NA),
    "shuffle must be")
  # Grouped folds use declared group identities regardless of shuffle.
  ref<-f(z$trajectories,z$outcome,candidate_components=1L,
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=FALSE)
  sh<-f(z$trajectories,z$outcome,candidate_components=1L,
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=TRUE)
  expect_identical(ref$assignments,sh$assignments)
})

test_that("real Python 1.2 GroupKFold predictive FPCR agrees for distinct group sizes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 grouped predictive FPCR source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd
import eyetrajectoriespy as et
_t=np.linspace(0,1,5);_z1=np.linspace(-2,2,12)
_z2=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
_values=np.array([.2+a*np.sin(np.pi*_t)+b*np.cos(2*np.pi*_t)
                   for a,b in zip(_z1,_z2)])[:,:,None]
_y=1+.5*_z1-.2*_z2+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
_grp=['P01']*5+['P02']*4+['P03']*3
_x=et.TrajectorySet(time=_t,values=_values,
   curve_ids=tuple('curve'+str(i) for i in range(1,13)),
   dimension_names=('x',),
   metadata=pd.DataFrame({'participant':_grp}),
   coordinate_system='normalized',time_unit='normalized')
_cv_group=et.cross_validate_fpca_regression(
   _x,_y,candidate_components=(1,2),n_splits=3,
   family='gaussian',cv_unit='group',group_column='participant',
   shuffle=True,random_state=100)
")
  py<-reticulate::py_call(
    etpy_get_export("cross_validate_fpca_regression"),
    trajectories=reticulate::py_eval("_x",convert=FALSE),
    outcome=reticulate::py_eval("_y",convert=FALSE),
    candidate_components=reticulate::py_eval("(1,2)",convert=FALSE),
    n_splits=3L,family="gaussian",cv_unit="group",
    group_column="participant",shuffle=TRUE,random_state=100L)
  for(field in c("fold_losses","assignments","predictions")){
    left<-et_to_r(reticulate::py_get_attr(py,field))
    right<-et_to_r(reticulate::py_eval(
      paste0("_cv_group.",field),convert=FALSE))
    expect_equal(left,right,tolerance=1e-9,ignore_attr=TRUE)
  }
  z<-.etr_fpcr_group_fixture()
  native<-etr_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=c(1L,2L),
    n_splits=3L,cv_unit="group",group_column="participant",
    shuffle=TRUE,random_state=100L)
  for(field in c("fold_losses","assignments","predictions")){
    source<-et_to_r(reticulate::py_eval(
      paste0("_cv_group.",field),convert=FALSE))
    expect_identical(names(native[[field]]),names(source))
    expect_identical(nrow(native[[field]]),nrow(source))
    for(column in names(source)){
      actual<-native[[field]][[column]]
      expected<-source[[column]]
      if(is.numeric(actual))
        expect_equal(as.numeric(actual),as.numeric(expected),
          tolerance=1e-8,
          info=paste("source grouped FPCR",field,column))
      else expect_identical(as.character(actual),as.character(expected))
    }
  }
  expect_true(native$provenance$group_leakage_prevented)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("nested FPCR selects components within groups without outer-group leakage",{
  z<-.etr_fpcr_group_fixture()
  for(rule in c("minimum","one_se")){
    x<-etr_nested_cross_validate_fpca_regression(
      z$trajectories,z$outcome,candidate_components=c(1L,2L),
      outer_splits=3L,inner_splits=2L,
      selection_rule=rule,cv_unit="group",
      group_column="participant",shuffle=TRUE,random_state=121L)
    expect_s3_class(x,"etr_nested_fpcr_cv")
    expect_true(x$provenance$outer_performance_unseen_by_inner_selection)
    expect_true(x$provenance$group_leakage_prevented)
    expect_identical(x$cv_unit,"group")
    expect_identical(x$group_column,"participant")
    expect_identical(x$random_state,NULL)
    expect_identical(nrow(x$outer_folds),3L)
    expect_identical(nrow(x$inner_summaries),6L)
    expect_identical(nrow(x$predictions),12L)
    expect_identical(names(x$predictions),
      c("curve_id","outer_fold","observed","prediction",
        "selected_n_components","group"))
    expect_identical(sort(x$predictions$curve_id),
      sort(z$trajectories$curve_ids))
    for(g in unique(x$predictions$group))
      expect_identical(length(unique(x$predictions$outer_fold[
        x$predictions$group==g])),1L)
    for(fold in 0:2){
      rows<-x$predictions[x$predictions$outer_fold==fold,]
      expect_equal(x$outer_folds$loss[fold+1L],
        sqrt(mean((rows$observed-rows$prediction)^2)),tolerance=1e-12)
    }
    again<-etr_nested_cross_validate_fpca_regression(
      z$trajectories,z$outcome,candidate_components=c(1L,2L),
      outer_splits=3L,inner_splits=2L,
      selection_rule=rule,cv_unit="group",
      group_column="participant",shuffle=FALSE)
    expect_identical(x$predictions,again$predictions)
    # Perturb all outcomes from the first outer held-out group:
    # its predictions/selected k cannot change, only its observed loss.
    first<-which(x$predictions$outer_fold==0L)
    held_ids<-match(x$predictions$curve_id[first],
      z$trajectories$curve_ids)
    changed<-z$outcome;changed[held_ids]<-changed[held_ids]+100
    shifted<-etr_nested_cross_validate_fpca_regression(
      z$trajectories,changed,candidate_components=c(1L,2L),
      outer_splits=3L,inner_splits=2L,
      selection_rule=rule,cv_unit="group",
      group_column="participant",shuffle=TRUE,random_state=121L)
    expect_equal(x$predictions$prediction[first],
      shifted$predictions$prediction[first],tolerance=1e-12)
    expect_identical(x$outer_folds$selected_n_components[1L],
      shifted$outer_folds$selected_n_components[1L])
    expect_false(isTRUE(all.equal(x$outer_folds$loss[1L],
      shifted$outer_folds$loss[1L])))
  }
})

test_that("R-seeded shuffled nested FPCR respects outer/inner random-state isolation",{
  z<-.etr_fpcr_group_fixture()
  set.seed(38L);before<-.Random.seed
  run<-function(seed)etr_nested_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=1L,
    outer_splits=3L,inner_splits=2L,
    cv_unit="curve",shuffle=TRUE,random_state=seed)
  a<-run(99L)
  expect_identical(.Random.seed,before)
  b<-run(99L)
  expect_identical(.Random.seed,before)
  expect_identical(a$outer_folds,b$outer_folds)
  expect_identical(a$inner_summaries,b$inner_summaries)
  expect_identical(a$predictions,b$predictions)
  expect_identical(a$random_state,99L)
  expect_identical(a$provenance$random_engine,
    "base_R_sample_not_NumPy")
  expect_false(a$provenance$group_leakage_prevented)
})

test_that("real Python 1.2 grouped nested FPCR matches source on three unequal participant blocks",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 grouped nested FPCR source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_tn=np.linspace(0,1,5);_za=np.linspace(-2,2,12)
_zb=np.array([1,-1,2,-2,1.5,-1.5,1.2,-1.2,2.2,-2.2,.7,-.7])
_vn=np.array([.2+a*np.sin(np.pi*_tn)+b*np.cos(2*np.pi*_tn)
     for a,b in zip(_za,_zb)])[:,:,None]
_yn=1+.5*_za-.2*_zb+.03*np.array([0,1,-1,0,1,-1,0,1,-1,0,1,-1])
_xn=et.TrajectorySet(time=_tn,values=_vn,
  curve_ids=tuple('curve'+str(i) for i in range(1,13)),
  dimension_names=('x',),
  metadata=pd.DataFrame({'participant':['P01']*5+['P02']*4+['P03']*3}),
  coordinate_system='normalized',time_unit='normalized')
_src_nested_group=et.nested_cross_validate_fpca_regression(
 _xn,_yn,candidate_components=(1,2),outer_splits=3,
 inner_splits=2,cv_unit='group',group_column='participant',
 selection_rule='minimum',shuffle=True,random_state=121)
")
  direct<-reticulate::py_call(
    etpy_get_export("nested_cross_validate_fpca_regression"),
    trajectories=reticulate::py_eval("_xn",convert=FALSE),
    outcome=reticulate::py_eval("_yn",convert=FALSE),
    candidate_components=reticulate::py_eval("(1,2)",convert=FALSE),
    outer_splits=3L,inner_splits=2L,cv_unit="group",
    group_column="participant",selection_rule="minimum",
    shuffle=TRUE,random_state=121L)
  z<-.etr_fpcr_group_fixture()
  native<-etr_nested_cross_validate_fpca_regression(
    z$trajectories,z$outcome,candidate_components=c(1L,2L),
    outer_splits=3L,inner_splits=2L,cv_unit="group",
    group_column="participant",selection_rule="minimum",
    shuffle=TRUE,random_state=121L)
  for(field in c("outer_folds","inner_summaries","predictions")){
    original<-et_to_r(reticulate::py_eval(
      paste0("_src_nested_group.",field),convert=FALSE))
    replay<-et_to_r(reticulate::py_get_attr(direct,field))
    expect_equal(replay,original,tolerance=1e-8,ignore_attr=TRUE)
    expect_identical(names(native[[field]]),names(original))
    expect_identical(nrow(native[[field]]),nrow(original))
    for(column in names(original)){
      actual<-native[[field]][[column]]
      expected<-original[[column]]
      if(is.numeric(actual))
        expect_equal(as.numeric(actual),as.numeric(expected),
          tolerance=1e-8,
          info=paste("grouped nested source",field,column))
      else expect_identical(as.character(actual),as.character(expected))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
