# Frozen eyetrajectoriespy==1.2.0 _sparse_multivariate_async.py,
# async_joint_pace_scores, commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R must diagnose each curve and retain later valid fits.

.etr_async_score_failure_fixture<-function(){
  g<-c(0,1,2)
  covariance<-.2*diag(length(g))
  zero<-matrix(0,length(g),length(g))
  list(ids=c("outside","inside"),
    views=list(tx=list(c(-.1,.5),c(.3,1.2)),
      xv=list(c(1,2),c(2,3)),
      ty=list(c(.5),c(.7)),
      yv=list(3,1)),
    grid=g,mu=matrix(0,length(g),2L),
    blocks=list(cxx=covariance,cxy=zero,cyx=zero,cyy=covariance),
    eigen=list(eigenvalues=.8,
      eigenfunctions=array(1,c(1L,length(g),2L))),
    noise=diag(c(1,1)))
}

.etr_async_score_failure_run<-function(failure="retain_nan",min_obs=2L){
  f<-.etr_async_score_failure_fixture()
  .etr_spna_pace(f$ids,f$views,f$grid,f$mu,
    f$blocks,f$eigen,f$noise,
    tolerance=0,ridge=.1,limit=1e12,
    min_obs=min_obs,failure=failure)
}

test_that("async source catches per-curve support failure and keeps valid later score",{
  fitted<-.etr_async_score_failure_run("retain_nan")
  diag<-fitted$diagnostics
  expect_identical(dim(fitted$scores),c(2L,1L))
  expect_true(is.nan(fitted$scores[1,1]))
  expect_true(is.finite(fitted$scores[2,1]))
  expect_identical(as.character(diag$status_code),
    c("native_time_outside_fitted_support","ok"))
  expect_identical(as.character(diag$solve_status),
    c("not_attempted","solved"))
  expect_identical(as.integer(diag$measurement_error_cross_links),
    c(0L,0L))
  expect_true(is.nan(diag$condition_number[[1L]]))
  expect_true(is.nan(diag$minimum_eigenvalue[[1L]]))
  expect_true(is.nan(diag$maximum_eigenvalue[[1L]]))
  expect_true(is.finite(diag$condition_number[[2L]]))
  expect_true(is.finite(diag$minimum_eigenvalue[[2L]]))
  expect_true(is.finite(diag$maximum_eigenvalue[[2L]]))
  expect_identical(as.character(diag$curve_id),c("outside","inside"))
})

test_that("async source failure_action=error reports the first curve and full audit",{
  error<-tryCatch(.etr_async_score_failure_run("error"),
    error=identity)
  expect_s3_class(error,"etr_sparse_native_error")
  expect_identical(error$code,"native_time_outside_fitted_support")
  expect_identical(as.character(error$details$curve_id),"outside")
  expect_length(error$details$all_curve_diagnostics,2L)
  all_rows<-error$details$all_curve_diagnostics
  expect_identical(as.character(all_rows[[1L]]$status_code),
    "native_time_outside_fitted_support")
  expect_identical(as.character(all_rows[[2L]]$status_code),"ok")
  expect_identical(as.integer(all_rows[[1L]]$measurement_error_cross_links),
    0L)
})

test_that("async source min-observation failures retain NaN and skip latent evaluation",{
  result<-.etr_async_score_failure_run("retain_nan",min_obs=4L)
  expect_identical(as.character(result$diagnostics$status_code),
    rep("curve_too_sparse_for_async_joint_score_system",2L))
  expect_true(all(is.nan(result$scores)))
  expect_identical(as.integer(result$diagnostics$measurement_error_cross_links),
    c(0L,0L))
  expect_true(all(is.nan(result$diagnostics$minimum_eigenvalue)))
})

test_that("async PACE source curve recovery matches frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 async PACE per-curve oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_multivariate import PlanarCovarianceBlocks
from eyetrajectoriespy._sparse_multivariate_async import async_joint_pace_scores
from eyetrajectoriespy._sparse_native import SparseNativeError
_grid=np.array([0.,1.,2.])
_v=.2*np.eye(3)
_zeros=np.zeros((3,3))
_block=PlanarCovarianceBlocks(cxx=_v,cxy=_zeros,cyx=_zeros,cyy=_v)
_kw=dict(curve_ids=('outside','inside'),
 x_times=(np.array([-.1,.5]),np.array([.3,1.2])),
 x_values=(np.array([1.,2.]),np.array([2.,3.])),
 y_times=(np.array([.5]),np.array([.7])),
 y_values=(np.array([3.]),np.array([1.])),
 evaluation_grid=_grid,fitted_mean=np.zeros((2,3)),
 covariance_blocks=_block,
 eigenvalues=np.array([.8]),eigenfunctions=np.ones((1,2,3)),
 measurement_error_covariance=np.eye(2),
 n_components=1,same_time_tolerance=0.,score_ridge=.1,
 condition_limit=1e12,min_score_observations=2)
_pyfit=async_joint_pace_scores(**_kw,failure_action='retain_nan')
def _pyfail():
 try:
  async_joint_pace_scores(**_kw,failure_action='error')
 except SparseNativeError as e:
  return dict(code=e.code,details=e.details)
 raise AssertionError('missing source first-curve failure')
")
  native<-.etr_async_score_failure_run("retain_nan")
  pyfit<-reticulate::py_eval("_pyfit",convert=FALSE)
  expect_equal(native$scores,
    et_to_r(reticulate::py_get_attr(pyfit,"scores")),
    tolerance=1e-12,ignore_attr=TRUE)
  theirs<-et_to_r(reticulate::py_get_attr(pyfit,"diagnostics"))
  for(field in c("curve_id","n_x_observations","n_y_observations",
    "n_scalar_observations","n_simultaneous_pairs",
    "measurement_error_cross_links","status_code","solve_status",
    "condition_number","minimum_eigenvalue","maximum_eigenvalue",
    "score_ridge","condition_limit","observation_order")){
    expect_equal(native$diagnostics[[field]],theirs[[field]],
      tolerance=1e-10,ignore_attr=TRUE,
      info=paste("frozen async diagnostic",field))
  }
  pyfailure<-reticulate::py_to_r(reticulate::py_call(
    reticulate::py_get_attr(reticulate::py,"_pyfail")))
  ours<-tryCatch(.etr_async_score_failure_run("error"),
    error=identity)
  expect_identical(ours$code,pyfailure$code)
  expect_identical(as.character(ours$details$curve_id),
    as.character(pyfailure$details$curve_id))
  expect_equal(length(ours$details$all_curve_diagnostics),
    length(pyfailure$details$all_curve_diagnostics))
  for(i in seq_along(ours$details$all_curve_diagnostics))
    for(field in c("status_code","solve_status",
      "measurement_error_cross_links")){
      expect_equal(ours$details$all_curve_diagnostics[[i]][[field]],
        pyfailure$details$all_curve_diagnostics[[i]][[field]],
        ignore_attr=TRUE,info=paste(i,field))
    }
})
