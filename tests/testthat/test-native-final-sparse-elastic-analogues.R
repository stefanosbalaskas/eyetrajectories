# Native scientific ALTERNATIVES to frozen Python elastic.py and sparse
# workflows. Source backend/schema differences are intentionally open.

.etr_final_sparse_fixture<-function(){
  make<-function(start,n,groups=FALSE){
    time<-lapply(seq_len(n),function(i)
      seq(0,1,length.out=11L)+.001*(i%%4L))
    values<-lapply(seq_len(n),function(i)
      cbind(x=sin(2*pi*time[[i]])+
        .05*cos(i*.75)*cos(pi*time[[i]])+.02*i,
        y=cos(2*pi*time[[i]])+
        .06*sin(i*.33)*sin(pi*time[[i]])+.01*i))
    etr_irregular_trajectory_set(time,values,
      paste0("sample",seq.int(start,length.out=n)),
      c("x","y"),
      metadata=data.frame(participant_id=
        paste0("P",rep(seq_len(ceiling(n/3L)),each=3L)[seq_len(n)])),
      time_unit="s")
  }
  list(proper=make(1L,18L),cal=make(101L,12L),
    target=make(201L,3L))
}

test_that("native square-root velocity FPCA uses identity warp and rejects source DP",{
  tt<-seq(0,1,length.out=21L)
  n<-12L;v<-array(0,c(n,21L,2L))
  for(i in seq_len(n)){
    v[i,,1L]<-tt+.05*sin(i*.62)*sin(2*pi*tt)
    v[i,,2L]<-tt^2+.06*cos(i*.46)*cos(2*pi*tt)
  }
  tr<-etr_trajectory_set(tt,v,paste0("c",1:n),
    c("x","y"),time_unit="s")
  out<-etr_fit_elastic_fpca(tr,n_components=2L)
  expect_s3_class(out,"etr_unregistered_srvf_fpca")
  expect_identical(dim(out$sqrt_velocity),c(12L,21L,2L))
  expect_identical(dim(out$scores),c(12L,2L))
  expect_true(all(vapply(seq_len(n),function(i)
    isTRUE(all.equal(out$warping_functions[i,],tt)),logical(1L))))
  expect_false(out$phase_amplitude_separated)
  expect_false(out$provenance$source_python_equivalent)
  expect_error(etr_fit_elastic_fpca(tr,n_components=2L,
    method="DP"),"fdasrsf")
  expect_error(etr_fit_elastic_fpca(tr,n_components=2L,
    rotation=TRUE),"fdasrsf")
})

test_that("native sparse multilevel workflow interpolates only when declared",{
  f<-.etr_final_sparse_fixture()
  config<-list(backend="explicit_linear_interpolation_dense_multilevel",
    dimension="x",participant_column="participant_id",
    evaluation_grid=seq(.1,.9,length.out=9L),
    n_between=2L,n_within=2L)
  z<-etr_run_sparse_multilevel_workflow(f$proper,config)
  expect_s3_class(z,"etr_native_sparse_multilevel_workflow")
  expect_s3_class(z$fit,"etr_multilevel_fpca")
  expect_true(z$provenance$interpolation_explicit)
  expect_false(z$provenance$source_python_equivalent)
  expect_equal(nrow(z$tables$variance),2L)
  expect_error(etr_run_sparse_multilevel_workflow(
    f$proper,modifyList(config,list(backend="source_sparse_PACE"))),
    "explicitly choose")
  expect_error(etr_run_sparse_multilevel_workflow(
    f$proper,modifyList(config,list(evaluation_grid=seq(-.1,1.1,
      length.out=9L)))),"extrapolation refused")
})

test_that("native sparse split conformal baseline is disjoint and target-blind",{
  f<-.etr_final_sparse_fixture()
  cfg<-list(backend="native_mean_curve_split_conformal",
    dimension="x",alpha=.2,
    evaluation_grid=seq(.01,1,length.out=21L))
  # Proper-training curves start at >=0 and finish at >=1, so the grid
  # stays inside all proper-curve support while covering calibration/target
  # observed times to t=1.003.
  cfg$evaluation_grid<-seq(.004,1.003,length.out=31L)
  # Source curves shifted to start near zero; support intersection is
  # [.003,1.000], while target samples reach 1.003. Use aligned time lists
  # with an explicit pooled interval to avoid extrapolating the training mean.
  for(x in c("proper","cal","target")){
    f[[x]]$time<-lapply(f[[x]]$time,function(t)
      seq(0,1,length.out=11L))
    f[[x]]$values<-lapply(seq_along(f[[x]]$values),function(i){
      v<-f[[x]]$values[[i]]
      t<-seq(0,1,length.out=11L)
      cbind(x=sin(2*pi*t)+.02*i,y=cos(2*pi*t)+.01*i)
    })
  }
  cfg$evaluation_grid<-seq(0,1,length.out=21L)
  z<-etr_run_sparse_prediction_workflow(f$proper,f$cal,
    f$target,cfg)
  expect_s3_class(z,"etr_native_sparse_prediction_workflow")
  expect_identical(nrow(z$tables$predictions),33L)
  expect_equal(z$predictions$upper-z$predictions$lower,
    rep(2*z$cutoff,33L))
  expect_false(any(z$predictions$observed_value_used_for_prediction))
  expect_false(z$provenance$source_python_equivalent)
  altered<-f$target
  altered$values<-lapply(altered$values,function(v)1000*v)
  z2<-etr_run_sparse_prediction_workflow(f$proper,f$cal,altered,cfg)
  expect_equal(z$predictions$prediction,z2$predictions$prediction)
  expect_error(etr_run_sparse_prediction_workflow(
    f$proper,f$cal,f$target,modifyList(cfg,list(alpha=.01))),
    "insufficient independent calibration")
  bad<-f$target
  bad$curve_ids[1L]<-f$proper$curve_ids[1L]
  expect_error(etr_run_sparse_prediction_workflow(
    f$proper,f$cal,bad,cfg),"disjoint")
})

test_that("paired and asynchronous native MFPCA require declared R backend",{
  f<-.etr_final_sparse_fixture()
  expect_error(etr_fit_sparse_mfpca(f$proper),
    "explicitly select fdapace_joint_score_pca")
  expect_error(etr_run_sparse_mfpca_workflow(f$proper,list(
    dimensions=c("x","y"),backend="source_custom",
    n_components=2L)),"explicitly select")
  ch<-list(x=etr_to_fdapy_irregular(f$proper,"x"),
    y=etr_to_fdapy_irregular(f$proper,"y"))
  bad<-ch
  bad$y$curve_ids<-rev(bad$y$curve_ids)
  expect_error(etr_fit_sparse_mfpca(bad,
    backend="fdapace_joint_score_pca"),"identical source curve IDs")
  expect_error(etr_run_sparse_mfpca_async_workflow(f$proper,list(
    dimensions=c("x","y"),backend="fdapace_joint_score_pca",
    n_components=2L)),
    "separately timed")
})

test_that("optional real fdapace joint score fits paired and async dimensions",{
  if(!identical(Sys.getenv("ET_RUN_FDAPACE_TESTS"),"true")||
     !requireNamespace("fdapace",quietly=TRUE))
    skip("optional fdapace sparse joint-score backend numerical smoke opt-in")
  f<-.etr_final_sparse_fixture()
  cfg<-list(dimensions=c("x","y"),
    backend="fdapace_joint_score_pca",
    n_components=2L,max_marginal_components=3L,fve=.95)
  z<-etr_run_sparse_mfpca_workflow(f$proper,cfg)
  expect_s3_class(z,"etr_native_sparse_mfpca_workflow")
  expect_identical(dim(z$fit$joint_scores),c(18L,2L))
  expect_false(z$fit$source_python_equivalent)
  ch<-list(x=etr_to_fdapy_irregular(f$proper,"x"),
    y=etr_to_fdapy_irregular(f$proper,"y"))
  async<-etr_run_sparse_mfpca_async_workflow(ch,cfg)
  expect_s3_class(async,"etr_native_sparse_mfpca_async_workflow")
  expect_true(async$provenance$input_layout=="asynchronous_sparse_channels")
  expect_identical(dim(async$fit$joint_scores),c(18L,2L))
})

# Actual frozen-Python 1.2 source-symbol inspection on published exports.
# For alternate R estimands/backends this is NOT numerical source parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: fit_elastic_fpca, fit_sparse_mfpca, run_sparse_mfpca_async_workflow, run_sparse_mfpca_workflow, run_sparse_multilevel_workflow, run_sparse_prediction_workflow",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("fit_elastic_fpca"),"fit_elastic_fpca")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("fit_sparse_mfpca"),"fit_sparse_mfpca")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("run_sparse_mfpca_async_workflow",.namespace="workflows"),"run_sparse_mfpca_async_workflow")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("run_sparse_mfpca_workflow",.namespace="workflows"),"run_sparse_mfpca_workflow")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("run_sparse_multilevel_workflow",.namespace="workflows"),"run_sparse_multilevel_workflow")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("run_sparse_prediction_workflow",.namespace="workflows"),"run_sparse_prediction_workflow")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
