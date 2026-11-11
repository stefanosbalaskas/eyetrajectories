# Frozen source: eyetrajectoriespy.sparse_multivariate_score_uncertainty
# conditional full-covariance PACE posterior; no independent certification.

test_that("native joint sparse PACE conditional uncertainty is PSD and source-shaped",{
  tr<-.etr_spnm_fixture()
  fit<-do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),.etr_spnm_args()))
  result<-etr_sparse_mfpca_score_uncertainty_native(fit,tr)
  expect_s3_class(result,"etr_sparse_mfpca_score_uncertainty_native")
  expect_identical(result$method,
    "conditional_gaussian_given_fitted_joint_population")
  expect_identical(dim(result$covariance),c(24L,2L,2L))
  expect_identical(dim(result$standard_errors),c(24L,2L))
  expect_true(all(is.finite(result$covariance)))
  expect_true(all(is.finite(result$standard_errors)))
  expect_true(all(result$standard_errors>=0))
  for(i in seq_along(result$curve_ids)){
    C<-result$covariance[i,,]
    expect_equal(C,t(C),tolerance=1e-11)
    expect_gte(min(eigen(C,symmetric=TRUE,only.values=TRUE)$values),
      -1e-9)
    expect_equal(diag(C),result$standard_errors[i,]^2,
      tolerance=1e-10,ignore_attr=TRUE)
    expect_equal(result$correlations[i,,],stats::cov2cor(C),tolerance=1e-10)
  }
  expect_true(all(result$diagnostics$status_code=="ok"))
  expect_true(all(result$diagnostics$fit_score_status=="ok"))
  expect_true(all(result$diagnostics$solve_status=="solved"))
  expect_false(result$provenance$rank_k_covariance_used_for_uncertainty)
  expect_false(result$provenance$population_estimation_uncertainty_included)
  expect_false(result$independent_full_source_certified)
  frame<-etr_sparse_mfpca_score_uncertainty_frame_native(result)
  expect_identical(nrow(frame),48L)
  expect_identical(names(frame),c("curve_id","component","score",
    "conditional_variance","conditional_se","status_code",
    "fit_score_status","condition_number","method"))
  expect_equal(frame$score[seq(1L,48L,2L)],fit$scores[,1L])
  expect_equal(frame$conditional_se[seq(2L,48L,2L)],
    result$standard_errors[,2L])
})

test_that("joint sparse uncertainty rejects mismatched fit geometry and curve order",{
  tr<-.etr_spnm_fixture()
  fit<-do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),.etr_spnm_args()))
  bad<-tr;bad$curve_ids<-rev(bad$curve_ids)
  expect_error(etr_sparse_mfpca_score_uncertainty_native(fit,bad),
    "curve order")
  bad<-tr;bad$coordinate_system<-"pixels"
  expect_error(etr_sparse_mfpca_score_uncertainty_native(fit,bad),
    "measurement units")
  expect_error(etr_sparse_mfpca_score_uncertainty_native(fit,tr,
    condition_limit=1),"condition_limit")
  expect_error(etr_sparse_mfpca_score_uncertainty_native(fit,tr,
    failure_action="ignore"),"failure_action")
  badfit<-fit
  badfit$covariance_cyx[1L,2L]<-
    badfit$covariance_cyx[1L,2L]+.2
  expect_error(etr_sparse_mfpca_score_uncertainty_native(badfit,tr),
    "Cyx=Cxy")
  badfit<-fit
  badfit$provenance$sparse_mfpca$
    rank_k_covariance_used_for_scoring<-TRUE
  expect_error(etr_sparse_mfpca_score_uncertainty_native(badfit,tr),
    "full native-time")
})

test_that("frozen Python joint PACE conditional posterior arrays and frame match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("live frozen Python joint sparse score uncertainty oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  tr<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  native_fit<-do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),args))
  native<-etr_sparse_mfpca_score_uncertainty_native(native_fit,tr)
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_spnm_post
import importlib
_etr_spnm_posterior=importlib.import_module('eyetrajectoriespy.sparse_multivariate_score_uncertainty')
def _etr_spnm_post_input(times,values,ids):
  return _etr_spnm_post.IrregularTrajectorySet(
    time=tuple(np.asarray(t,dtype=float) for t in times),
    values=tuple(np.asarray(v,dtype=float) for v in values),
    curve_ids=tuple(str(x) for x in ids),
    dimension_names=('x','y'),
    coordinate_system='degrees',time_unit='s')
")
  trpy<-reticulate::py_call(
    reticulate::py_eval("_etr_spnm_post_input",convert=FALSE),
    times=reticulate::r_to_py(tr$time),
    values=reticulate::r_to_py(tr$values),
    ids=reticulate::r_to_py(tr$curve_ids))
  pyargs<-args
  pyargs$dimensions<-reticulate::tuple("x","y")
  pyargs$measurement_error_variance<-reticulate::tuple(.08,.10)
  pyargs$evaluation_grid<-reticulate::r_to_py(args$evaluation_grid)
  pyfit<-do.call(reticulate::py_call,
    c(list(etpy_get_export("fit_sparse_mfpca"),trajectories=trpy),
      pyargs))
  module<-reticulate::py_eval("_etr_spnm_posterior",convert=FALSE)
  pyresult<-reticulate::py_call(reticulate::py_get_attr(
    module,"sparse_mfpca_score_uncertainty"),
    fit=pyfit,trajectories=trpy)
  for(field in c("covariance","standard_errors","correlations")){
    expect_equal(unname(native[[field]]),
      unname(et_to_r(reticulate::py_get_attr(pyresult,field))),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("frozen joint PACE posterior",field))
  }
  py_diagnostics<-et_to_r(reticulate::py_get_attr(pyresult,"diagnostics"))
  for(field in c("status_code","fit_score_status",
      "solve_status","observation_order")){
    expect_identical(as.character(native$diagnostics[[field]]),
      as.character(py_diagnostics[[field]]),
      info=paste("source posterior diagnostic",field))
  }
  pyframe<-reticulate::py_call(reticulate::py_get_attr(
    module,"sparse_mfpca_score_uncertainty_frame"),
    result=pyresult)
  rframe<-etr_sparse_mfpca_score_uncertainty_frame_native(native)
  pframe<-et_to_r(pyframe)
  for(field in names(rframe)){
    if(is.numeric(rframe[[field]]))
      expect_equal(rframe[[field]],pframe[[field]],
        tolerance=3e-6,ignore_attr=TRUE,
        info=paste("source joint uncertainty frame",field))
    else expect_identical(as.character(rframe[[field]]),
      as.character(pframe[[field]]))
  }
})
