# Frozen Python 1.2 generalized_function_on_scalar.py participant-case bootstrap.
# Oracle pin c1cd95ad718327550f7e55393ff38582872f7a94.
# R-only fitted model object and Python dataclass identities are deliberately
# not equated. All bootstrap coefficients are refit, not retained projections.

.etr_gee_bootstrap_strict_case<-function(family="poisson",grouped=FALSE,
    exposed=FALSE) {
  f<-.etr_native_gee_fixture(family,grouped)
  d<-f$design[match(f$x$curve_ids,f$design$curve_id),,drop=FALSE]
  args<-list(trajectories=f$x,design=d,predictors="treatment",
    participant_column="participant_id",dimension="outcome",family=family,
    basis_size=4L,spline_degree=3L,
    binomial_denominator=f$den,
    exposure=if(exposed)rep(2.5,36L) else NULL,
    exposure_units=if(exposed)"person-hours" else NULL,
    python_boundary_mode=TRUE)
  fit<-do.call(etr_fit_generalized_function_on_scalar_regression,
    c(args,list(strict_source_record=TRUE)))
  list(fit=fit,args=args)
}

.etr_gee_bootstrap_source_provenance_fields<-c(
  "method","n_bootstrap","random_state","resampling_unit",
  "whole_participant_curve_bundles_resampled",
  "duplicate_source_participants_receive_distinct_group_ids",
  "family_refit","link_refit","working_correlation_refit",
  "basis_refit","basis_selected_automatically",
  "failed_replicate_policy","failed_replicates_redrawn",
  "exposure_observed_and_fixed",
  "exposure_resampled_with_response_bundle",
  "exposure_measurement_uncertainty",
  "binomial_denominator_observed_and_fixed",
  "binomial_denominator_resampled_with_response_bundle",
  "binomial_denominator_measurement_uncertainty")

test_that("strict bootstrap preserves source 8-field result and 19-field provenance",{
  for(spec in list(
    list(family="poisson",grouped=FALSE,exposed=FALSE),
    list(family="poisson",grouped=FALSE,exposed=TRUE),
    list(family="binomial",grouped=TRUE,exposed=FALSE),
    list(family="binomial",grouped=FALSE,exposed=FALSE))){
    fixture<-do.call(.etr_gee_bootstrap_strict_case,spec)
    z<-etr_bootstrap_generalized_function_on_scalar_coefficients(
      fixture$fit,n_bootstrap=100L,random_state=20261109L,
      strict_source_record=TRUE)
    expect_s3_class(z,"etr_generalized_function_on_scalar_bootstrap")
    expect_identical(names(z),c("reference",
      "bootstrap_coefficient_functions","sampled_participant_indices",
      "sampled_source_participant_ids",
      "sampled_bootstrap_participant_ids","random_state",
      "failure_policy","provenance"))
    expect_identical(names(z$provenance),
      c("generalized_function_on_scalar_regression",
        "generalized_function_on_scalar_bootstrap"))
    source<-z$provenance$generalized_function_on_scalar_bootstrap
    expect_identical(names(source),.etr_gee_bootstrap_source_provenance_fields)
    expect_identical(length(source),19L)
    expect_identical(source$n_bootstrap,100L)
    expect_identical(source$random_state,20261109L)
    expect_identical(source$family_refit,spec$family)
    expect_identical(source$exposure_observed_and_fixed,spec$exposed)
    expect_identical(source$binomial_denominator_observed_and_fixed,
      spec$grouped)
    expect_true(source$duplicate_source_participants_receive_distinct_group_ids)
    expect_false(source$failed_replicates_redrawn)
    expect_identical(dim(z$bootstrap_coefficient_functions),c(100L,2L,7L))
    expect_identical(dim(z$sampled_participant_indices),c(100L,12L))
    expect_true(all(is.finite(z$bootstrap_coefficient_functions)))
    expect_identical(length(z$sampled_source_participant_ids),100L)
    expect_true(all(lengths(z$sampled_source_participant_ids)==12L))
    expect_true(all(vapply(z$sampled_bootstrap_participant_ids,
      function(ids)length(unique(ids))==12L,logical(1L))))
  }
})

test_that("strict bootstrap validation rejects unsupported reference and flags",{
  f<-.etr_native_gee_fixture()
  d<-f$design[match(f$x$curve_ids,f$design$curve_id),,drop=FALSE]
  legacy<-etr_fit_generalized_function_on_scalar_regression(
    f$x,d,"treatment",participant_column="participant_id",
    dimension="outcome",family="poisson",basis_size=4L,
    python_boundary_mode=TRUE)
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    legacy,n_bootstrap=100L,strict_source_record=TRUE),
    "requires a strict native source GEE reference")
  strict<-.etr_gee_bootstrap_strict_case()$fit
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    strict,n_bootstrap=100L,strict_source_record=1L),
    "strict_source_record")
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    strict,n_bootstrap=99L,strict_source_record=TRUE),
    "n_bootstrap")
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    strict,n_bootstrap=100L,failed_replicate_policy="drop",
    strict_source_record=TRUE),"failed_replicate_policy")
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    strict,n_bootstrap=100L,random_state=-1L,
    strict_source_record=TRUE),"random_state")
  # The legacy provenance carries its explicit R-only draw engine and
  # certification status. The strict source mode never fabricates those keys.
  old<-etr_bootstrap_generalized_function_on_scalar_coefficients(
    legacy,n_bootstrap=100L,random_state=20261109L)
  expect_true("native_random_engine"%in%
    names(old$provenance$generalized_function_on_scalar_bootstrap))
  expect_false(old$provenance$
    generalized_function_on_scalar_bootstrap$full_source_contract_certified)
})

test_that("frozen Python 1.2 participant bootstraps compare direct 100-refit arrays and complete source provenance",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 Statsmodels GEE participant oracle")
  expect_identical(et_python_version(),"1.2.0")
  for(spec in list(
    list(family="poisson",grouped=FALSE,exposed=FALSE),
    list(family="poisson",grouped=FALSE,exposed=TRUE),
    list(family="binomial",grouped=TRUE,exposed=FALSE),
    list(family="binomial",grouped=FALSE,exposed=FALSE))){
    fixture<-do.call(.etr_gee_bootstrap_strict_case,spec)
    native<-etr_bootstrap_generalized_function_on_scalar_coefficients(
      fixture$fit,n_bootstrap=100L,random_state=20261109L,
      strict_source_record=TRUE)
    pyfit<-.etr_python_gee_boundary_call(fixture$args)
    oracle<-reticulate::py_call(
      etpy_get_export("bootstrap_generalized_function_on_scalar_coefficients"),
      result=pyfit,n_bootstrap=100L,random_state=20261109L)
    expect_equal(native$sampled_participant_indices,
      et_to_r(oracle$sampled_participant_indices),tolerance=0,
      ignore_attr=TRUE,info=paste(spec$family,spec$grouped,
        spec$exposed,"participant index stream"))
    expect_equal(native$bootstrap_coefficient_functions,
      et_to_r(oracle$bootstrap_coefficient_functions),tolerance=1e-4,
      ignore_attr=TRUE,info=paste(spec$family,spec$grouped,
        spec$exposed,"full-refit coefficient array"))
    for(field in c("sampled_source_participant_ids",
        "sampled_bootstrap_participant_ids")){
      a<-native[[field]]
      b<-et_to_r(reticulate::py_get_attr(oracle,field))
      expect_equal(length(a),length(b))
      expect_identical(as.character(unlist(a)),
        as.character(unlist(b)),info=paste(spec$family,field))
    }
    a<-native$provenance$generalized_function_on_scalar_bootstrap
    b<-et_to_r(oracle$provenance)$generalized_function_on_scalar_bootstrap
    expect_identical(names(a),names(b))
    for(key in names(a))
      expect_equal(a[[key]],b[[key]],ignore_attr=TRUE,
        info=paste(spec$family,spec$grouped,spec$exposed,key))
    expect_identical(native$failure_policy,
      et_to_r(oracle$failure_policy))
    expect_identical(native$random_state,20261109L)
  }
})
