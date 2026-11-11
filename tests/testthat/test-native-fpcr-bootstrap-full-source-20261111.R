# Complete outer FPCARegressionUncertaintyResult scientific source contract.
# Frozen eyetrajectoriespy==1.2.0 regression_inference.py
# c1cd95ad718327550f7e55393ff38582872f7a94.
# R scientific lm is not the Python statsmodels object identity.

.etr_fpcr_bootstrap_full_fixture<-function(){
  n<-14L; time<-seq(0,1,length.out=15L)
  x<-array(0,c(n,15L,1L))
  for(i in seq_len(n))
    x[i,,1L]<-sin(pi*time)*(1+i/16)+
      .16*cos(2*pi*time)*(i%%4L)/3+time*i/18
  y<-.2+1.2*seq_len(n)/n+.2*sin(seq_len(n))
  list(x=etr_trajectory_set(time,x,sprintf("c%02d",1:n),
    "gaze",metadata=data.frame(
      subject=rep(sprintf("p%02d",1:7),each=2L)),
    coordinate_system="normalized",time_unit="s"),y=y)
}

test_that("paired Gaussian FPCR source mode emits 25 canonical fields and full provenance",{
  z<-.etr_fpcr_bootstrap_full_fixture()
  for(unit in c("curve","participant")){
    group<-if(unit=="participant")"subject" else NULL
    ans<-etr_bootstrap_fpca_regression_uncertainty(
      z$x,z$y,n_bootstrap=20L,n_components=1L,
      resample_unit=unit,participant_column=group,random_state=7L,
      python_boundary_mode=TRUE)
    expect_s3_class(ans,"etr_fpcr_bootstrap_uncertainty")
    expect_identical(names(ans),c("reference_fpca","reference_regression",
      "reference_slope","bootstrap_slopes","slope_lower",
      "slope_median","slope_upper","slope_se","reference_intercept",
      "bootstrap_intercepts","target_curve_ids",
      "reference_mean_predictions","bootstrap_mean_predictions",
      "prediction_lower","prediction_median","prediction_upper",
      "prediction_se","level","n_components","scaling",
      "resampling_unit","participant_column","target_source",
      "random_state","provenance"))
    expect_identical(names(ans$reference_regression),c(
      "model","component_indices","coefficients",
      "predictions","family","provenance"))
    expect_identical(ans$reference_regression$component_indices,0L)
    expect_identical(names(ans$reference_regression$coefficients),
      c("const","FPC1"))
    expect_identical(ans$reference_regression$family,"gaussian")
    expect_identical(ans$reference_regression$provenance,
      list(method="scalar_on_function_via_fpca_scores",
        n_components=1L,family="gaussian",covariates=list()))
    expect_identical(dim(ans$bootstrap_slopes),c(20L,15L,1L))
    expect_identical(dim(ans$bootstrap_mean_predictions),c(20L,14L))
    expect_true(all(is.finite(ans$bootstrap_slopes)))
    expect_true(all(ans$slope_lower<=ans$slope_median&
      ans$slope_median<=ans$slope_upper))
    expect_true(all(ans$prediction_lower<=ans$prediction_median&
      ans$prediction_median<=ans$prediction_upper))
    expect_identical(ans$target_source,"training")
    expect_identical(ans$random_state,7L)
    prov<-ans$provenance$fpca_regression_uncertainty
    expect_identical(names(prov),c(
      "method","family","n_bootstrap","n_components",
      "component_count_fixed","component_selection_uncertainty_included",
      "scaling","resample_unit","participant_column","level",
      "slope_interval","prediction_interval",
      "future_outcome_prediction_interval","target_source",
      "target_curves_fixed","fpc_label_matching_required",
      "fpc_label_invariance_reason","operator_scaled_fpcr_test",
      "random_state"))
    expect_identical(prov$fpc_label_invariance_reason,
      "slope_and_mean_prediction_reconstructed_from_each_complete_refit")
    expect_false(prov$future_outcome_prediction_interval)
    expect_false(prov$operator_scaled_fpcr_test)
    expect_null(prov$random_engine)
  }
})

test_that("source FPCR mode is separate from native fixed-draw replay",{
  z<-.etr_fpcr_bootstrap_full_fixture()
  expect_error(etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,python_boundary_mode=TRUE,
    bootstrap_indices=replicate(20L,0:13,simplify=FALSE)),
    "caller-supplied bootstrap indices")
  expect_error(etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,python_boundary_mode=1),
    "python_boundary_mode")
  native<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,random_state=7L)
  expect_identical(length(native$sampled_source_curve_indices),20L)
  expect_false(native$provenance$fpca_regression_uncertainty$
    source_schema_equivalent)
})

test_that("frozen typed Python source matches both resampling units and external targets",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 FPCR bootstrap source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_bootstrap_full_fixture()
  pset<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=z$x$time,values=z$x$values,
    curve_ids=do.call(reticulate::tuple,as.list(z$x$curve_ids)),
    dimension_names=reticulate::tuple("gaze"),
    metadata=z$x$metadata,coordinate_system=z$x$coordinate_system,
    time_unit=z$x$time_unit)
  selected<-c(2L,7L,13L)
  targets<-etr_trajectory_set(z$x$time,
    z$x$values[selected,,,drop=FALSE]+.025,
    c("e02","e07","e13"),z$x$dimension_names,
    metadata=z$x$metadata[selected,,drop=FALSE],
    coordinate_system=z$x$coordinate_system,
    time_unit=z$x$time_unit)
  py_targets<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=targets$time,values=targets$values,
    curve_ids=reticulate::tuple("e02","e07","e13"),
    dimension_names=reticulate::tuple("gaze"),
    metadata=targets$metadata,
    coordinate_system=targets$coordinate_system,time_unit=targets$time_unit)
  cases<-list(list(unit="curve",seed=7L,external=FALSE),
    list(unit="participant",seed=7L,external=FALSE),
    list(unit="curve",seed=23L,external=FALSE),
    list(unit="participant",seed=23L,external=FALSE),
    list(unit="participant",seed=7L,external=TRUE))
  for(case in cases){
    grp<-if(case$unit=="participant")"subject" else NULL
    args<-list(n_bootstrap=20L,n_components=1L,
      resample_unit=case$unit,participant_column=grp,
      level=.9,random_state=case$seed)
    actual<-do.call(etr_bootstrap_fpca_regression_uncertainty,
      c(list(trajectories=z$x,outcome=z$y,
             targets=if(case$external)targets else NULL),
        args,list(python_boundary_mode=TRUE)))
    py<-do.call(reticulate::py_call,
      c(list(etpy_get_export("bootstrap_fpca_regression_uncertainty"),
        pset,z$y,targets=if(case$external)py_targets else NULL),args))
    for(field in c("reference_slope","bootstrap_slopes","slope_lower",
        "slope_median","slope_upper","slope_se","reference_intercept",
        "bootstrap_intercepts","reference_mean_predictions",
        "bootstrap_mean_predictions","prediction_lower",
        "prediction_median","prediction_upper","prediction_se")){
      expect_equal(actual[[field]],
        et_to_r(reticulate::py_get_attr(py,field)),tolerance=1e-6,
        ignore_attr=TRUE,
        info=paste("FPCR paired source",case$unit,case$seed,
          case$external,field))
    }
    expect_identical(actual$target_curve_ids,
      unname(as.character(et_to_r(reticulate::py_get_attr(
        py,"target_curve_ids")))))
    source_fit<-reticulate::py_get_attr(py,"reference_regression")
    expect_equal(actual$reference_regression$component_indices,
      as.integer(et_to_r(reticulate::py_get_attr(
        source_fit,"component_indices"))),tolerance=0)
    expect_equal(as.numeric(actual$reference_regression$coefficients),
      as.numeric(et_to_r(reticulate::py_get_attr(
        source_fit,"coefficients"))),tolerance=1e-6)
    expect_equal(actual$reference_regression$predictions,
      et_to_r(reticulate::py_get_attr(source_fit,"predictions")),
      tolerance=1e-6,ignore_attr=TRUE)
    source_prov<-et_to_r(reticulate::py_get_attr(py,"provenance"))
    expect_identical(names(actual$provenance),
      names(source_prov))
    rprov<-actual$provenance$fpca_regression_uncertainty
    pprov<-source_prov$fpca_regression_uncertainty
    expect_identical(names(rprov),names(pprov))
    for(field in names(rprov))
      expect_equal(rprov[[field]],pprov[[field]],ignore_attr=TRUE,
        info=paste("FPCR provenance",case$unit,field))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
