# Frozen Python 1.2 recovery.py::evaluate_fpca_recovery (multimode)
# Pinned source SHA c1cd95ad718327550f7e55393ff38582872f7a94
# Native first-party qualification; never third-party full-domain certificate.

.etr_multi_fpca_recovery_fixture<-function(retain=3L){
  tt<-c(0,.15,.4,.7,1,1.4,2)
  nt<-length(tt);nd<-2L;n<-8L;kt<-3L
  w<-etr_trapezoid_weights(tt)
  truth_components<-array(0,c(kt,nt,nd))
  truth_components[1L,1L,1L]<-1/sqrt(w[1L])
  truth_components[2L,3L,2L]<-1/sqrt(w[3L])
  truth_components[3L,5L,1L]<-1/sqrt(w[5L])
  true_scores<-cbind(seq(-2,2,length.out=n),
    sin(seq_len(n)*.8),cos(seq_len(n)*1.2))
  truth_mean<-matrix(seq_len(nt*nd)/25,nt,nd)
  latent<-array(0,c(n,nt,nd))
  for(i in seq_len(n)){
    latent_i<-truth_mean
    for(j in seq_len(kt))latent_i<-latent_i+
      true_scores[i,j]*matrix(truth_components[j,,,drop=FALSE],
        nrow=nt,ncol=nd)
    latent[i,,]<-latent_i
  }
  truth_lambda<-c(9,4,1)
  permutation<-if(retain==3L)c(3L,1L,2L)else c(3L,1L)
  signs<-if(retain==3L)c(-1,1,-1)else c(-1,1)
  fitted_components<-truth_components[permutation,,,drop=FALSE]
  for(j in seq_len(retain))fitted_components[j,,]<-
    signs[j]*fitted_components[j,,]
  fitted_scores<-sweep(true_scores[,permutation,drop=FALSE],
    2L,signs,"*")
  fit_mean<-truth_mean;fit_mean[2L,2L]<-fit_mean[2L,2L]+.05
  truth<-list(truth_grid=tt,dimension_names=c("x","y"),
    mean=truth_mean,eigenfunctions=truth_components,
    eigenvalues=truth_lambda,scores=true_scores,
    latent_on_truth_grid=latent)
  fit<-list(time=tt,provenance=list(fpca=list(scaling="none")),
    dimension_names=c("x","y"),scale=c(1,1),mean=fit_mean,
    components=fitted_components,
    explained_variance=truth_lambda[permutation],
    scores=fitted_scores,weights=w)
  list(fit=fit,truth=truth,permutation=as.integer(permutation-1L),
    signs=as.numeric(signs),retain=retain)
}

test_that("native three-component recovery matches weighted population geometry",{
  z<-.etr_multi_fpca_recovery_fixture(3L)
  assessment<-etr_evaluate_fpca_recovery(z$fit,z$truth)
  expect_s3_class(assessment,"etr_functional_recovery_assessment")
  expect_identical(assessment$provenance$matched_truth_components,
    z$permutation)
  expect_equal(assessment$provenance$alignment_signs,z$signs,tolerance=0)
  expect_identical(assessment$provenance$multivariate,TRUE)
  names<-vapply(assessment$values,function(x)x$metric$name,character(1L))
  indices<-vapply(assessment$values,function(x)
    if(is.null(x$component)) -1L else as.integer(x$component),
    integer(1L))
  expect_identical(length(names),21L)
  expect_identical(names[1:2],c("mean_ise","covariance_ise"))
  expect_identical(names[3:6],c("eigenvalue_relative_error",
    "component_absolute_similarity","score_correlation","score_rmse"))
  expect_identical(tail(names,1L),"reconstruction_ise")
  expect_equal(assessment$values[[2L]]$value,0,tolerance=1e-11)
  expect_equal(assessment$values[[1L]]$value,
    z$fit$weights[2L]*(.05^2),tolerance=1e-12)
  expect_identical(indices[c(3L,7L,11L)],c(0L,1L,2L))
  expect_equal(vapply(assessment$values[c(4L,8L,12L)],
    function(x)x$value,numeric(1L)),rep(1,3),tolerance=1e-12)
  expect_equal(vapply(assessment$values[c(6L,10L,14L)],
    function(x)x$value,numeric(1L)),rep(0,3),tolerance=1e-12)
  expect_equal(tail(assessment$values,1L)[[1L]]$value,
    assessment$values[[1L]]$value,tolerance=1e-11)
})

test_that("rectangular two-of-three component recovery retains unmatched truth covariance",{
  z<-.etr_multi_fpca_recovery_fixture(2L)
  assessment<-etr_evaluate_fpca_recovery(z$fit,z$truth)
  expect_identical(assessment$provenance$matched_truth_components,
    z$permutation)
  expect_equal(assessment$provenance$alignment_signs,z$signs,tolerance=0)
  expect_identical(length(assessment$values),15L)
  expect_true(assessment$values[[2L]]$value>0)
  expect_equal(assessment$values[[2L]]$value,4^2,tolerance=1e-10)
  expect_equal(vapply(assessment$values[c(4L,8L)],
    function(x)x$value,numeric(1L)),rep(1,2),tolerance=1e-11)
  cosines<-assessment$values[c(11L,13L)]
  expect_true(all(vapply(cosines,function(z)
    z$metric$name=="subspace_principal_cosine"&&
    abs(z$value-1)<1e-10,logical(1L))))
  expect_equal(assessment$values[[15L]]$value,
    mean(vapply(seq_len(nrow(z$fit$scores)),function(i)
      sum(sweep((matrix(z$truth$latent_on_truth_grid[i,,,drop=FALSE],
        nrow=length(z$truth$truth_grid),ncol=2L) -
        (z$fit$mean+
          z$fit$scores[i,1L]*matrix(z$fit$components[1L,,,drop=FALSE],
            nrow=length(z$truth$truth_grid),ncol=2L)+
          z$fit$scores[i,2L]*matrix(z$fit$components[2L,,,drop=FALSE],
            nrow=length(z$truth$truth_grid),ncol=2L)))^2,
        1L,z$fit$weights,"*")),numeric(1L))),
    tolerance=1e-11)
})

test_that("multimode recovery rejects too few source components or invalid norms",{
  z<-.etr_multi_fpca_recovery_fixture(3L)
  incorrect<-z$truth;incorrect$eigenfunctions<-
    incorrect$eigenfunctions[1:2,,,drop=FALSE]
  expect_error(etr_evaluate_fpca_recovery(z$fit,incorrect),
    "truth contains fewer components")
  invalid<-z$fit;invalid$scale<-c(1,2)
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),
    "unit dimension scales")
  invalid<-z$fit;invalid$provenance$fpca$scaling<-"dimension_sd"
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),
    "scaling='none'")
  invalid<-z$fit;invalid$components[1L,,]<-0
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),
    "invalid norm")
  bad<-z$fit;bad$time[2L]<-bad$time[2L]+.01
  expect_error(etr_evaluate_fpca_recovery(bad,z$truth),
    "exact source grid")
})

test_that("multi-FPCA recovery metrics and assignments agree with frozen Python source",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 multicomponent recovery direct oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  sim<-reticulate::import(
    "eyetrajectoriespy._functional_simulation",convert=FALSE)
  reticulate::py_run_string("
def _etr_multirecovery_obj(cls, **fields):
    obj=object.__new__(cls)
    for name,value in fields.items():
        object.__setattr__(obj,name,value)
    return obj
def _etr_multirecovery_metrics(assessment):
    return {
        'names': [v.metric.name for v in assessment.values],
        'values': [float(v.value) for v in assessment.values],
        'components': [-1 if v.component is None else int(v.component)
                       for v in assessment.values],
        'matched': list(assessment.provenance['matched_truth_components']),
        'signs': list(assessment.provenance['alignment_signs'])
    }
")
  make<-reticulate::py_eval("_etr_multirecovery_obj",convert=FALSE)
  gather<-reticulate::py_eval("_etr_multirecovery_metrics",convert=FALSE)
  nparray<-function(x)np$asarray(reticulate::r_to_py(x),dtype="float64")
  for(k in c(2L,3L)){
    z<-.etr_multi_fpca_recovery_fixture(k)
    f<-z$fit;t<-z$truth
    pyfit<-reticulate::py_call(make,cls=etpy_get_export("FPCAResult"),
      time=nparray(f$time),
      dimension_names=reticulate::r_to_py(as.list(f$dimension_names)),
      provenance=reticulate::r_to_py(f$provenance),
      scale=nparray(f$scale),mean=nparray(f$mean),
      components=nparray(f$components),
      explained_variance=nparray(f$explained_variance),
      scores=nparray(f$scores),weights=nparray(f$weights))
    pytruth<-reticulate::py_call(make,
      cls=sim$FunctionalSimulationTruth,
      truth_grid=nparray(t$truth_grid),
      dimension_names=reticulate::r_to_py(as.list(t$dimension_names)),
      mean=nparray(t$mean),
      eigenfunctions=nparray(t$eigenfunctions),
      eigenvalues=nparray(t$eigenvalues),
      scores=nparray(t$scores),
      latent_on_truth_grid=nparray(t$latent_on_truth_grid))
    py<-reticulate::py_call(etpy_get_export("evaluate_fpca_recovery"),
      result=pyfit,truth=pytruth)
    direct<-et_to_r(reticulate::py_call(gather,py))
    native<-etr_evaluate_fpca_recovery(f,t)
    names_native<-vapply(native$values,
      function(x)x$metric$name,character(1L))
    vals_native<-vapply(native$values,
      function(x)x$value,numeric(1L))
    comp_native<-vapply(native$values,function(x)
      if(is.null(x$component))-1L else as.integer(x$component),
      integer(1L))
    expect_identical(names_native,as.character(direct$names))
    expect_identical(comp_native,as.integer(direct$components))
    expect_identical(native$provenance$matched_truth_components,
      as.integer(direct$matched))
    expect_equal(native$provenance$alignment_signs,
      as.numeric(direct$signs),tolerance=0)
    angular<-which(names_native=="subspace_principal_angle_degrees")
    expect_equal(vals_native[-angular],as.numeric(direct$values)[-angular],
      tolerance=1e-10)
    # acos near unit cosine has a condition number diverging at 1;
    # a tight absolute bound in degrees is appropriate.
    expect_lte(max(abs(vals_native[angular]-
      as.numeric(direct$values)[angular])),2e-5)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
