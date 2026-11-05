# Stage 12: leakage-aware numeric FPCA CV, selection and fixed-target
# reporting frames. Python==1.2.0 source oracle only when explicitly enabled.

.etr_cv_uncertainty_test_fixture <- function(with_groups=FALSE) {
  n<-12L;t<-seq(0,1,length.out=9L)
  vals<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)) {
    vals[i,,1L]<-sin(2*pi*t)*(1+i/13)+i*t/10+
       cos(3*pi*t+i/9)/5
    vals[i,,2L]<-cos(2*pi*t+i/5)+i*t^2/12+
       sin(4*pi*t+i/3)/7
  }
  md<-if(with_groups)
    data.frame(participant_id=rep(sprintf("p%02d",1:6),each=2L))
    else NULL
  etr_trajectory_set(t,vals,sprintf("c%02d",seq_len(n)),c("x","y"),
    metadata=md,coordinate_system="normalized",time_unit="s")
}

test_that("CV refits training folds and retains exact holdouts", {
  x<-.etr_cv_uncertainty_test_fixture()
  before<-reticulate::py_available(initialize=FALSE)
  res<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=c(2L,1L,2L),n_splits=3L,
    shuffle=FALSE)
  expect_s3_class(res,"etr_fpca_cv")
  expect_identical(res$component_counts,c(1L,2L))
  expect_equal(nrow(res$fold_errors),6L)
  expect_identical(names(res$fold_errors),
    c("fold","n_components","mean_integrated_rmse",
      "median_integrated_rmse","n_train_curves","n_test_curves"))
  expect_equal(sort(res$assignments$curve_id),sort(x$curve_ids))
  expect_true(all(table(res$assignments$curve_id)==1L))
  expect_equal(res$assignments$fold,rep(0:2,each=4L))
  expect_true(all(res$fold_errors$n_train_curves==8L))
  expect_true(all(res$fold_errors$n_test_curves==4L))
  expect_true(all(is.finite(res$fold_errors$mean_integrated_rmse)))
  expect_true(all(res$fold_errors$mean_integrated_rmse>=0))
  expect_true(isTRUE(res$provenance$fit_inside_fold))
  expect_null(res$random_state)
  expect_identical(before,reticulate::py_available(initialize=FALSE))
  expect_error(etr_cross_validate_fpca_reconstruction(x,
    candidate_components=8L,n_splits=3L,shuffle=FALSE),
    "exceeds training-fold maximum")
  expect_error(etr_cross_validate_fpca_reconstruction(x,
    candidate_components=c(0,1),shuffle=FALSE),
    "positive integer")
  expect_error(etr_cross_validate_fpca_reconstruction(x,n_splits=1L),
    "n_splits")
})

test_that("group folds exclude whole participants and preserve RNG",{
  x<-.etr_cv_uncertainty_test_fixture(with_groups=TRUE)
  x$metadata$participant_id<-rep(sprintf("p%02d",1:6),each=2L)
  res<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,
    cv_unit="group",group_column="participant_id",shuffle=FALSE)
  a<-res$assignments
  expect_true("group"%in%names(a))
  grouped<-split(a$fold,a$group)
  expect_true(all(vapply(grouped,function(z)length(unique(z))==1L,
    logical(1L))))
  expect_true(all(res$provenance$group_leakage_prevented))
  expect_true(all(res$fold_errors$n_test_curves==4L))
  expect_equal(sum(res$fold_errors$n_test_curves),12L)
  expect_error(etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,cv_unit="group",
    group_column="absent"),"group_column")
  bad<-x;bad$metadata$participant_id[1L]<-NA
  expect_error(etr_cross_validate_fpca_reconstruction(bad,
    candidate_components=1L,n_splits=3L,cv_unit="group",
    group_column="participant_id"),"nonmissing")
  set.seed(400)
  was<-.Random.seed
  shuffle<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,shuffle=TRUE,random_state=11L)
  expect_identical(was,.Random.seed)
  repeat_cv<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,shuffle=TRUE,random_state=11L)
  expect_identical(shuffle$assignments,repeat_cv$assignments)
  expect_identical(shuffle$provenance$random_engine,"base_R_sample")
})

test_that("selection distinguishes predictive minimum and one-SE",{
  z<-list(fold_errors=data.frame(
    n_components=rep(1:3,each=3L),
    mean_integrated_rmse=c(.5,.6,.4,.31,.33,.35,.32,.34,.36)))
  tbl<-etr_summarise_fpca_cross_validation(z)
  expect_identical(names(tbl),c("n_components","mean_rmse",
    "sd_rmse","n_folds","se_rmse"))
  expect_equal(tbl$n_folds,c(3L,3L,3L))
  expect_equal(tbl$mean_rmse,c(.5,.33,.34))
  expect_equal(etr_select_fpca_components_cv(z,"minimum"),2L)
  expect_equal(etr_select_fpca_components_cv(z,"one_se"),2L)
  expect_error(etr_select_fpca_components_cv(z,"automatic"),"rule")
  r<-list(fold_losses=data.frame(n_components=rep(1:3,each=3L),
    loss=c(1.1,1.2,1.0,.75,.74,.76,.755,.755,.755)))
  tab<-etr_summarise_fpca_regression_cv(r)
  expect_identical(names(tab),c("n_components","mean_loss",
    "sd_loss","n_folds","se_loss"))
  expect_equal(etr_select_fpca_regression_components(r,"minimum"),2L)
  expect_equal(etr_select_fpca_regression_components(r,"one_se"),2L)
  expect_error(etr_summarise_fpca_regression_cv(list()),"declared fields")
})

test_that("fixed-target score, spectrum and conformal frames",{
  x<-.etr_cv_uncertainty_test_fixture()
  fit<-etr_fit_fpca(x,n_components=2L)
  ids<-c("target1","target2")
  scores<-list(target_curve_ids=ids,n_components=2L,
    reference_scores=matrix(1:4,2,2),
    median=matrix(1:4+.1,2,2),score_se=matrix(.1,2,2),
    lower=matrix(1:4-.2,2,2),upper=matrix(1:4+.2,2,2),
    similarities=matrix(c(.9,.8,.7,.95,.85,.75),nrow=3L))
  tab<-etr_fpca_score_uncertainty_frame(scores)
  expect_equal(nrow(tab),4L)
  expect_identical(names(tab),c("curve_id","component",
    "reference_score","bootstrap_median","bootstrap_se",
    "lower","upper","median_matched_abs_similarity"))
  expect_equal(tab$component,c(1L,2L,1L,2L))
  expect_equal(tab$median_matched_abs_similarity,
    c(.8,.85,.8,.85))
  bad<-scores;bad$lower<-matrix(1,2,3)
  expect_error(etr_fpca_score_uncertainty_frame(bad),"declared dimensions")
  spectrum<-list(reference=fit,n_components=2L,
    similarities=matrix(c(.9,.8,.7,.8,.9,.85),3,2),
    eigenvalue_se=c(.1,.1),eigenvalue_lower=c(.5,.1),
    eigenvalue_upper=c(2,1),
    explained_variance_ratio_se=c(.01,.02),
    explained_variance_ratio_lower=c(.3,.1),
    explained_variance_ratio_upper=c(.6,.3),
    cumulative_variance_ratio_se=c(.02,.03),
    cumulative_variance_ratio_lower=c(.3,.5),
    cumulative_variance_ratio_upper=c(.6,.85))
  sp<-etr_fpca_spectrum_uncertainty_frame(spectrum)
  expect_equal(nrow(sp),2L)
  expect_true(all(sp$eigenvalue==fit$explained_variance))
  expect_equal(sp$cumulative_variance_ratio,
    cumsum(fit$explained_variance_ratio))
  anomaly<-list(target_curve_ids=ids,target_scores=c(2,5),
    p_values=c(.5,.04),alpha=.05,review_flags=c(FALSE,TRUE),
    minimum_attainable_p=.01)
  ab<-etr_conformal_fpca_anomaly_frame(anomaly)
  expect_identical(names(ab),c("curve_id","nonconformity_score",
    "conformal_p_value","alpha","review_flag","minimum_attainable_p"))
  expect_identical(ab$review_flag,c(FALSE,TRUE))
  anomaly$p_values[2L]<-1.5
  expect_error(etr_conformal_fpca_anomaly_frame(anomaly),"p-values")
  dist<-list(comparison_table=data.frame(k=1:2),
    neighbor_overlap_table=data.frame(curve_id=ids))
  expect_equal(etr_trajectory_distance_comparison_frame(dist),
    dist$comparison_table)
  expect_equal(etr_trajectory_distance_neighbor_frame(dist),
    dist$neighbor_overlap_table)
})

test_that("functional regression uncertainty tables respect ordering",{
  x<-.etr_cv_uncertainty_test_fixture();fit<-etr_fit_fpca(x,n_components=1L)
  n<-length(fit$time);d<-length(fit$dimension_names)
  a<-matrix(seq_len(n*d),n,d)/100
  u<-list(reference_fpca=fit,reference_slope=a,
    slope_median=a+.1,slope_se=a*.1,
    slope_lower=a-.2,slope_upper=a+.2,
    target_curve_ids=c("t1","t2"),
    reference_mean_predictions=c(.3,.4),
    prediction_median=c(.31,.41),prediction_se=c(.03,.04),
    prediction_lower=c(.2,.3),prediction_upper=c(.5,.6))
  su<-etr_fpca_regression_slope_uncertainty_frame(u)
  expect_equal(nrow(su),n*d)
  expect_equal(su$time,rep(fit$time,each=d))
  expect_equal(su$dimension,rep(fit$dimension_names,n))
  expect_equal(su$reference_slope[1:2],a[1,])
  pred<-etr_fpca_regression_prediction_uncertainty_frame(u)
  expect_equal(pred$curve_id,c("t1","t2"))
  band<-list(regression_uncertainty=u,pointwise_se=a*.1,
    critical_values=c(2,2.5),lower=a-.1,upper=a+.1)
  sb<-etr_fpca_regression_slope_band_frame(band)
  expect_equal(sb$critical_value,rep(c(2,2.5),n))
  expect_equal(nrow(sb),n*d)
  future<-list(regression_uncertainty=u,median=c(.32,.42),
    predictive_se=c(.1,.2),lower=c(.05,.08),upper=c(.7,.9))
  pf<-etr_fpca_regression_future_prediction_frame(future)
  expect_identical(names(pf),c("curve_id","reference_mean_prediction",
    "mean_response_lower","mean_response_upper",
    "future_prediction_median","future_prediction_se",
    "future_prediction_lower","future_prediction_upper"))
  expect_equal(pf$future_prediction_lower,c(.05,.08))
  bad<-band;bad$lower<-matrix(0,n,1L)
  expect_error(etr_fpca_regression_slope_band_frame(bad),
    "declared dimensions")
})

test_that("508-source census remains fail-closed",{
  before<-reticulate::py_available(initialize=FALSE)
  a<-etr_native_parity_catalog()
  expect_equal(nrow(a),508L)
  expect_equal(sum(a$is_python_function),380L)
  expect_gte(sum(a$named_native_candidate),236L)
  expect_lte(sum(a$is_python_function & !a$named_native_candidate),144L)
  expect_gte(sum(a$native_implementation_started),211L)
  expect_equal(sum(a$native_implementation_stage==12L,na.rm=TRUE),14L)
  expect_true(all(!a$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("pinned Python 1.2 source CV oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("independent Python 1.2 numerical CV oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_cv_uncertainty_test_fixture()
  pset<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  py<-reticulate::py_call(
    etpy_get_export("cross_validate_fpca_reconstruction"),
    trajectories=pset,candidate_components=as.list(c(1L,2L)),
    n_splits=as.integer(3L),scaling="none",cv_unit="curve",shuffle=FALSE)
  native<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=c(1L,2L),n_splits=3L,shuffle=FALSE)
  ptab<-et_to_r(py$fold_errors)
  expect_identical(names(native$fold_errors),names(ptab))
  for(f in c("mean_integrated_rmse","median_integrated_rmse"))
    expect_equal(as.numeric(native$fold_errors[[f]]),
      as.numeric(ptab[[f]]),tolerance=1e-7,info=f)
  passign<-et_to_r(py$assignments)
  expect_identical(as.character(native$assignments$curve_id),
    as.character(passign$curve_id))
  expect_equal(native$assignments$fold,as.integer(passign$fold))
  py_summary<-et_to_r(reticulate::py_call(
    etpy_get_export("summarise_fpca_cross_validation"),result=py))
  ours<-etr_summarise_fpca_cross_validation(native)
  for(f in c("mean_rmse","sd_rmse","se_rmse"))
    expect_equal(ours[[f]],as.numeric(py_summary[[f]]),
      tolerance=1e-7,info=f)
  pselect<-reticulate::py_call(etpy_get_export(
    "select_fpca_components_cv"),result=py,rule="one_se")
  expect_equal(etr_select_fpca_components_cv(native,"one_se"),
    as.integer(et_to_r(pselect)))
})


test_that("FPCA reconstruction accepts exact source KFold folds",{
  t<-seq(0,1,length.out=5L);n<-12L
  v<-array(0,c(n,5L,1L))
  for(i in seq_len(n))v[i,,1L]<-
    sin(pi*t)*(i/12)+cos(2*pi*t)*(i%%3)/7
  x<-etr_trajectory_set(t,v,paste0("c",seq_len(n)),"signal",
    coordinate_system="normalized",time_unit="normalized")
  folds<-c(2L,0L,1L,1L,0L,2L,0L,1L,2L,1L,2L,0L)
  a<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,fold_assignments=folds)
  expect_identical(a$assignments$fold,
    folds[match(a$assignments$curve_id,x$curve_ids)])
  expect_identical(a$provenance$fold_source,
    "explicit_zero_based_source_replay")
  expect_equal(nrow(a$fold_errors),3L)
  expect_error(etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,
    fold_assignments=c(rep(0L,11L),2L)),"fold_assignments")
})


test_that("Python 1.2 shuffled reconstruction KFold numerics replay fixed source folds",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 reconstruction KFold oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  t<-seq(0,1,length.out=5L)
  v<-array(0,c(12L,5L,1L))
  for(i in 1:12)v[i,,1L]<-sin(pi*t)*(i/12)+
    cos(2*pi*t)*(i%%3)/7
  x<-etr_trajectory_set(t,v,paste0("c",1:12),"signal",
    coordinate_system="normalized",time_unit="normalized")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_rtime=np.linspace(0,1,5)
_rvalues=np.array([np.sin(np.pi*_rtime)*(i/12)+
 np.cos(2*np.pi*_rtime)*(i%3)/7 for i in range(1,13)])[:,:,None]
_rx=et.TrajectorySet(time=_rtime,values=_rvalues,
 curve_ids=tuple('c'+str(i) for i in range(1,13)),
 dimension_names=('signal',),coordinate_system='normalized',
 time_unit='normalized')
_rcv=et.cross_validate_fpca_reconstruction(_rx,
 candidate_components=(1,),n_splits=3,shuffle=True,random_state=19)
_rf=np.full(12,-1,dtype=int)
for r in _rcv.assignments.itertuples(index=False):
 _rf[int(r.curve_id[1:])-1]=int(r.fold)
")
  fold<-as.integer(reticulate::py_to_r(reticulate::py_eval(
    "_rf",convert=FALSE)))
  actual<-etr_cross_validate_fpca_reconstruction(x,
    candidate_components=1L,n_splits=3L,shuffle=TRUE,
    random_state=19L,fold_assignments=fold)
  for(field in c("fold_errors","assignments")){
    expected<-reticulate::py_to_r(reticulate::py_get_attr(
      reticulate::py_eval("_rcv",convert=FALSE),field))
    expect_identical(names(actual[[field]]),names(expected))
    for(col in names(expected)){
      if(is.numeric(actual[[field]][[col]]))
        expect_equal(as.numeric(actual[[field]][[col]]),
          as.numeric(expected[[col]]),tolerance=1e-7,
          info=paste("shuffled reconstruction source",field,col))
      else expect_identical(as.character(actual[[field]][[col]]),
        as.character(expected[[col]]))
    }
  }
})
