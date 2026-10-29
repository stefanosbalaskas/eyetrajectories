# Stage 14 native FPCA eigenspace/bootstrap/outlier scientific tests.
# Python 1.2 reference comparisons are explicit opt-in only.

.etr14_fixture <- function(grouped=TRUE){
  n<-16L;t<-seq(0,1,length.out=27L)
  vals<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)){
    vals[i,,1L]<-sin(pi*t)*(1+i/19)+
      cos(2*pi*t)*(i%%5)/7 + t*i/12 +
      .1*sin(5*pi*t+i/3)
    vals[i,,2L]<-cos(2*pi*t+i/5)+(i/13)*sin(3*pi*t)+
      t^2*(i%%7)/6+.04*cos(7*pi*t+i/9)
  }
  md<-if(grouped)
    data.frame(participant_id=rep(sprintf("p%02d",1:8),each=2L))
  else NULL
  etr_trajectory_set(t,vals,sprintf("c%02d",1:n),c("x","y"),
    metadata=md,coordinate_system="normalized",time_unit="s")
}

test_that("Stage 14 principal angles ignore sign switches and rotations",{
  x<-.etr14_fixture()
  a<-etr_fit_mfpca(x,n_components=3L)
  same<-etr_compare_fpca_subspaces(a,a,start_component=0L,
                                   n_components=2L)
  expect_s3_class(same,"etr_fpca_subspace_comparison")
  expect_equal(same$principal_cosines,c(1,1),tolerance=1e-7)
  # Bitwise-identical weighted bases have exactly zero principal angles;
  # roundoff in SVD of the self-Gram matrix must not generate 1e-8 distances.
  expect_identical(same$normalized_projector_distance,0)
  expect_identical(same$projector_distance_frobenius,0)
  expect_equal(same$principal_angles_degrees,c(0,0),tolerance=0)
  b<-a
  b$components[1L,,]<- -b$components[1L,,]
  b$components[2L,,]<- -b$components[2L,,]
  flip<-etr_compare_fpca_subspaces(a,b,0L,2L)
  expect_equal(flip$normalized_projector_distance,0,tolerance=1e-7)
  expect_identical(flip$component_indices,0:1)
  one<-etr_compare_fpca_subspaces(a,b,1L,1L)
  expect_equal(one$principal_cosines,1,tolerance=1e-7)
  expect_error(etr_compare_fpca_subspaces(a,b,0L,4L),
    "common fitted range")
  bad<-b;bad$time[2L]<-bad$time[2L]+.002
  expect_error(etr_compare_fpca_subspaces(a,bad,0L,2L),"time grid")
})

test_that("Stage 14 principal-angle bootstrap has independent group units",{
  x<-.etr14_fixture()
  set.seed(404)
  prior<-.Random.seed
  res<-etr_bootstrap_fpca_subspace_stability(x,
    start_component=0L,n_components=2L,n_bootstrap=4L,
    resample_unit="participant",participant_column="participant_id",
    random_state=123L)
  expect_identical(prior,.Random.seed)
  expect_s3_class(res,"etr_fpca_subspace_stability")
  expect_identical(dim(res$principal_cosines),c(4L,2L))
  expect_identical(dim(res$principal_angles_degrees),c(4L,2L))
  expect_true(all(res$principal_cosines>=0 & res$principal_cosines<=1))
  expect_true(all(res$normalized_projector_distance>=0 &
                  res$normalized_projector_distance<=1+1e-9))
  expect_identical(res$resampling_unit,"participant")
  again<-etr_bootstrap_fpca_subspace_stability(x,
    start_component=0L,n_components=2L,n_bootstrap=4L,
    resample_unit="participant",participant_column="participant_id",
    random_state=123L)
  expect_identical(res$principal_cosines,again$principal_cosines)
  table<-etr_summarise_fpca_subspace_stability(res)
  expect_equal(nrow(table),1L)
  expect_equal(table$component_start,1L)
  expect_equal(table$component_end,2L)
  expect_true(all(is.finite(unlist(table[1L,4:ncol(table)],use.names=FALSE))))
  expect_error(etr_summarise_fpca_subspace_stability(res,c(.9,.1)),
    "interval")
  expect_error(etr_bootstrap_fpca_subspace_stability(x,
    n_bootstrap=1L),"n_bootstrap")
  expect_error(etr_bootstrap_fpca_subspace_stability(x,
    n_bootstrap=2L,resample_unit="participant"),"participant_column")
})

test_that("Stage 14 component-bootstrap matching tracks sign and variance",{
  x<-.etr14_fixture()
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_bootstrap_fpca_stability(x,n_bootstrap=5L,n_components=2L,
      scaling="none",random_state=17L)
  expect_s3_class(z,"etr_fpca_stability")
  expect_identical(dim(z$similarities),c(5L,2L))
  expect_identical(dim(z$assignments),c(5L,2L))
  expect_true(all(z$similarities>=0 & z$similarities<=1+1e-9))
  expect_true(all(z$assignments%in%0:1))
  expect_true(all(z$bootstrap_curve_counts==16L))
  summary<-etr_summarise_fpca_stability(z,similarity_threshold=.8)
  expect_identical(summary$component,1:2)
  expect_identical(names(summary),c("component",
    "median_abs_similarity","similarity_interval_low",
    "similarity_interval_high","fraction_at_or_above_threshold",
    "similarity_threshold","median_explained_variance_ratio"))
  expect_true(all(summary$fraction_at_or_above_threshold>=0&
                  summary$fraction_at_or_above_threshold<=1))
  repeated_fit<-etr_bootstrap_fpca_stability(x,n_bootstrap=5L,n_components=2L,
      scaling="none",random_state=17L)
  expect_identical(z$similarities,repeated_fit$similarities)
  expect_identical(before,reticulate::py_available(initialize=FALSE))
  expect_error(etr_summarise_fpca_stability(z,similarity_threshold=1.5),
    "similarity_threshold")
})

test_that("Stage 14 leave-group-out FPCA influence preserves entire participants",{
  x<-.etr14_fixture()
  z<-etr_leave_one_group_out_fpca_influence(x,
    group_column="participant_id",n_components=2L)
  expect_s3_class(z,"etr_fpca_influence")
  expect_equal(nrow(z$summary),8L)
  expect_equal(nrow(z$components),16L)
  expect_true(all(z$summary$omitted_n_curves==2L))
  expect_true(all(z$summary$remaining_n_curves==14L))
  expect_true(all(z$summary$influence_score>=-1e-9))
  expect_true(all(z$components$absolute_similarity<=1+1e-9))
  expect_equal(sort(unique(z$components$reference_component)),1:2)
  expect_identical(z$group_column,"participant_id")
  by_curve<-etr_leave_one_group_out_fpca_influence(x,
    n_components=1L)
  expect_equal(nrow(by_curve$summary),16L)
  expect_true(all(by_curve$summary$omitted_n_curves==1L))
  bad<-x;bad$metadata$participant_id[1L]<-NA_character_
  expect_error(etr_leave_one_group_out_fpca_influence(bad,
     group_column="participant_id",n_components=2L),"missing")
})

test_that("Stage 14 empirical FPCA outlier screening is explicit and non-exclusionary",{
  x<-.etr14_fixture()
  fit<-etr_fit_mfpca(x,n_components=2L)
  expect_error(etr_diagnose_fpca_outliers(fit,x),
    "robust MinCovDet")
  z<-etr_diagnose_fpca_outliers(fit,x,n_components=2L,
    score_covariance="empirical",score_alpha=.99)
  expect_s3_class(z,"etr_fpca_outliers")
  d<-z$diagnostics
  expect_identical(names(d),c("curve_id","reconstruction_rmse",
    "reconstruction_robust_z","score_mahalanobis_sq",
    "score_cutoff","reconstruction_flag","score_flag","review_flag"))
  expect_identical(d$curve_id,x$curve_ids)
  expect_true(all(d$score_mahalanobis_sq>=-1e-9))
  expect_equal(unique(d$score_cutoff),stats::qchisq(.99,df=2L))
  expect_identical(d$review_flag,d$reconstruction_flag|d$score_flag)
  expect_identical(x$curve_ids,fit$curve_ids) # no automatic removal
  expect_error(etr_diagnose_fpca_outliers(fit,x,
    score_covariance="empirical",score_alpha=1),"score_alpha")
  bad<-x;bad$curve_ids<-rev(x$curve_ids)
  expect_error(etr_diagnose_fpca_outliers(fit,bad,
    score_covariance="empirical"),"IDs/order")
})

test_that("Stage 14 strict inventory is distinct from scientific certification",{
  was<-reticulate::py_available(initialize=FALSE)
  a<-etr_native_parity_catalog()
  expect_equal(nrow(a),508L)
  expect_equal(sum(a$is_python_function),380L)
  expect_equal(sum(a$named_native_candidate),219L)
  expect_equal(sum(a$is_python_function & !a$named_native_candidate),161L)
  expect_equal(sum(a$native_implementation_started),194L)
  expect_equal(sum(a$native_implementation_stage==14L,na.rm=TRUE),7L)
  expect_equal(sum(!is.na(a$native_representation_stage)),7L)
  expect_equal(sum(!a$is_python_function &
    is.na(a$native_representation_stage)),121L)
  expect_true(all(!a$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 14 pinned Python 1.2 eigenspace and empirical outlier oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 14 pinned Python 1.2 numerical oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr14_fixture()
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  pyfit<-reticulate::py_call(etpy_get_export("fit_mfpca"),
    trajectories=pyx,n_components=as.integer(2L))
  fit<-etr_fit_mfpca(x,n_components=2L)
  pycomp<-reticulate::py_call(etpy_get_export("compare_fpca_subspaces"),
    reference=pyfit,candidate=pyfit,start_component=as.integer(0L),
    n_components=as.integer(2L))
  native<-etr_compare_fpca_subspaces(fit,fit,0L,2L)
  expect_equal(native$principal_cosines,as.numeric(
    et_to_r(pycomp$principal_cosines)),tolerance=1e-8)
  expect_equal(native$normalized_projector_distance,
    as.numeric(et_to_r(pycomp$normalized_projector_distance)),
    tolerance=1e-8)
  pyout<-reticulate::py_call(etpy_get_export("diagnose_fpca_outliers"),
    result=pyfit,trajectories=pyx,
    n_components=as.integer(2L),score_covariance="empirical")
  nativeout<-etr_diagnose_fpca_outliers(fit,x,n_components=2L,
    score_covariance="empirical")
  pd<-et_to_r(pyout$diagnostics)
  rd<-nativeout$diagnostics
  expect_identical(names(rd),names(pd))
  for(field in c("reconstruction_rmse","reconstruction_robust_z",
                 "score_mahalanobis_sq","score_cutoff"))
    expect_equal(as.numeric(rd[[field]]),as.numeric(pd[[field]]),
      tolerance=1e-7,info=field)
  expect_identical(rd$review_flag,as.logical(pd$review_flag))
})
