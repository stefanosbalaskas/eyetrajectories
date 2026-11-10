# Frozen Python 1.2 functional_mixed_effects_inference.py.
# The source-class adapter below passes a fitted *native nlme* marginal
# covariance into the real frozen Python public bootstrap. This isolates
# bootstrap numerical law from different Python/R likelihood optimizers.
.etr_joint_fixed_boot_fixture<-function(){
  time<-seq(0,1,length.out=7L)
  ids<-sprintf("curve%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  x<-rep(c(-1,0,1),8L)
  y<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    y[i,,1L]<-.7+.23*time+x[i]*(.25-.15*time)+
      .18*sin(g*.6)+.13*cos(g*.31)*time+
      .06*sin(i*.7+time*4)+.035*cos(1.5*i*time)
  }
  tr<-etr_trajectory_set(time,y,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  etr_fit_joint_bspline_functional_mixed_effects(tr,design,
    "x","pid","signal",fixed_basis_size=2L,
    random_basis_size=2L,spline_degree=1L,reml=TRUE)
}

test_that("joint nested trial and serial covariance contribute to full GLS information",{
  tt<-c(0,.4,1);nt<-length(tt)
  scalar<-cbind(Intercept=1,x=rep(c(0,1),3L))
  y<-outer(seq_len(6L),seq_len(nt),function(i,t)
    .6+.15*((i+1L)%%2L)+.04*sin(i+t*.8))
  X<-cbind(rep(1,6L*nt),rep(scalar[,2L],each=nt))
  Z<-matrix(1,6L*nt,1L)
  C<-outer(seq_len(nt),seq_len(nt),
    function(i,j).4^abs(i-j))
  G<-matrix(.08,1L,1L)
  H<-matrix(.02,1L,1L)
  info<-array(NA_real_,c(3L,2L,2L))
  scores<-matrix(NA_real_,3L,2L)
  for(g in seq_len(3L)){
    ix<-((g-1L)*2L*nt)+seq_len(2L*nt)
    V<-.08*matrix(1,2L*nt,2L*nt)+
      kronecker(diag(2L),.035*C+.02*matrix(1,nt,nt))
    info[g,,]<-crossprod(X[ix,,drop=FALSE],
      solve(V,X[ix,,drop=FALSE]))
    scores[g,]<-as.numeric(crossprod(X[ix,,drop=FALSE],
      solve(V,as.numeric(t(y[(g-1L)*2L+seq_len(2L),,drop=FALSE])))))
  }
  reference_beta<-as.numeric(solve(
    apply(info,c(2L,3L),sum),colSums(scores)))
  fit<-structure(list(
    fitted_model=structure(list(),class="lme"),
    fixed_long_design=X,random_long_design=Z,
    random_effect_covariance=G,
    residual_correlation_matrix=C,
    residual_variance=.035,
    trial_random_effect="functional_intercept",
    trial_random_basis=matrix(1,nt,1L),
    trial_random_effect_covariance=H,
    observed_functions=y,
    fixed_basis=matrix(1,nt,1L),
    fixed_basis_coefficients=matrix(reference_beta,2L,1L),
    participant_ids=c("p1","p2","p3"),
    curve_participant_ids=rep(c("p1","p2","p3"),each=2L),
    n_participants=3L,n_curves=6L,time=tt,
    provenance=list()),class="etr_joint_bspline_mixed")
  extracted<-.etr_joint_bootstrap_gls_contributions(fit)
  expect_equal(unname(extracted$information),unname(info),
    tolerance=1e-11)
  expect_equal(unname(extracted$scores),unname(scores),
    tolerance=1e-11)
  expect_lt(extracted$max_reference_gls_difference,1e-11)
  fixed<-matrix(rep(0:2,length.out=300L),nrow=100L,ncol=3L)
  bootstrap<-etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,random_state=4L,
    sampled_participant_indices=fixed)
  expect_identical(bootstrap$covariance_conditioning,
    "reference_participant_and_trial_random_effect_covariances_and_residual_covariance_fixed")
  for(b in seq_len(3L)){
    ix<-fixed[b,]+1L
    expected<-solve(apply(info[ix,,,drop=FALSE],c(2L,3L),sum),
      colSums(scores[ix,,drop=FALSE]))
    expect_equal(as.numeric(bootstrap$bootstrap_fixed_basis_coefficients[b,,1L]),
      as.numeric(expected),tolerance=1e-10)
  }
  expect_identical(dim(bootstrap$bootstrap_coefficient_functions),
    c(100L,2L,3L))
})

test_that("joint fixed-covariance mixed bootstrap solves true full-time GLS",{
  skip_if_not_installed("nlme")
  fit<-.etr_joint_fixed_boot_fixture()
  original_seed<-local({
    set.seed(7727L)
    .Random.seed
  })
  set.seed(7727L)
  selected<-matrix(rep(c(0L,1L,2L,3L,4L,5L,6L,7L),
    times=100L),nrow=100L,byrow=TRUE)
  selected[2L,]<-rep(0L,8L)
  # Identical source group draws: deterministic, no R RNG consumption.
  before<-.Random.seed
  a<-etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,random_state=8L,
    sampled_participant_indices=selected)
  expect_identical(before,.Random.seed)
  expect_s3_class(a,"etr_joint_mixed_fixed_covariance_bootstrap")
  expect_identical(a$bootstrap_type,"conditional_covariance")
  expect_identical(a$covariance_conditioning,
    "reference_participant_and_residual_covariance_fixed")
  expect_identical(dim(a$bootstrap_fixed_basis_coefficients),
    c(100L,2L,2L))
  expect_identical(dim(a$bootstrap_coefficient_functions),
    c(100L,2L,7L))
  expect_identical(a$sampled_participant_indices,selected)
  expect_equal(a$bootstrap_coefficient_functions[1L,,],
    fit$fixed_coefficient_functions,tolerance=2e-4,
    ignore_attr=TRUE)
  expect_equal(a$bootstrap_standard_errors,
    apply(a$bootstrap_coefficient_functions,c(2L,3L),stats::sd),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_true(is.finite(a$provenance$
    functional_mixed_effects_bootstrap$reference_gls_max_abs_difference))
  expect_false(a$independent_full_source_certified)
  bands<-etr_functional_mixed_effects_simultaneous_bands(
    a,confidence_level=.9,simultaneous_scope="family")
  expect_equal((bands$upper+bands$lower)/2,
    fit$fixed_coefficient_functions,tolerance=1e-12,
    ignore_attr=TRUE)
  expect_true(all(bands$upper>=bands$lower))
  bad<-selected;bad[3L,2L]<-8L
  expect_error(etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,
    sampled_participant_indices=bad),"zero-based")
  expect_identical(original_seed,before)
})

test_that("native joint GLS bootstrap and simultaneous bands match frozen Python public source",{
  skip_if_not_installed("nlme")
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python joint GLS coefficient bootstrap oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fit<-.etr_joint_fixed_boot_fixture()
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_joint_source
def _etr_joint_source_adapter(time, observed, scalar,
                              fixed_basis, fixed_coef, random_design,
                              random_cov, residual_var, residual_corr,
                              participant_ids, curve_groups, curve_ids,
                              coefficient_names):
    obj=object.__new__(_etr_joint_source.FunctionalMixedEffectsResult)
    values={
      'time':np.asarray(time,dtype=float),
      'observed_functions':np.asarray(observed,dtype=float),
      'scalar_design_matrix':np.asarray(scalar,dtype=float),
      'fixed_basis':np.asarray(fixed_basis,dtype=float),
      'fixed_basis_coefficients':np.asarray(fixed_coef,dtype=float),
      'coefficient_functions':np.asarray(fixed_coef,dtype=float) @
            np.asarray(fixed_basis,dtype=float).T,
      'random_effect_design_matrix':np.asarray(random_design,dtype=float),
      'random_effect_covariance':np.asarray(random_cov,dtype=float),
      'random_effect_dimension':int(np.asarray(random_cov).shape[0]),
      'residual_variance':float(residual_var),
      'residual_correlation':'iid',
      'residual_correlation_matrix':np.asarray(residual_corr,dtype=float),
      'participant_ids':tuple(str(x) for x in participant_ids),
      'curve_participant_ids':tuple(str(x) for x in curve_groups),
      'source_curve_ids':tuple(str(x) for x in curve_ids),
      'coefficient_names':tuple(str(x) for x in coefficient_names),
      'fixed_basis_size':int(np.asarray(fixed_basis).shape[1]),
      'random_slope_predictor':None,
      'trial_random_effect':None,
      'residual_correlation_parameter':None,
      'residual_correlation_parameter_name':None,
      'boundary_fit':False,'converged':True,'provenance':{}
    }
    for key,value in values.items():
        object.__setattr__(obj,key,value)
    return obj
")
  fn<-reticulate::py_eval("_etr_joint_source_adapter",convert=FALSE)
  pyref<-reticulate::py_call(fn,
    reticulate::r_to_py(fit$time),
    reticulate::r_to_py(fit$observed_functions),
    reticulate::r_to_py(fit$scalar_design),
    reticulate::r_to_py(fit$fixed_basis),
    reticulate::r_to_py(fit$fixed_basis_coefficients),
    reticulate::r_to_py(fit$random_long_design),
    reticulate::r_to_py(fit$random_effect_covariance),
    as.numeric(fit$residual_variance),
    reticulate::r_to_py(fit$residual_correlation_matrix),
    reticulate::r_to_py(fit$participant_ids),
    reticulate::r_to_py(fit$curve_participant_ids),
    reticulate::r_to_py(fit$source_curve_ids),
    reticulate::r_to_py(fit$predictor_names))
  pyboot<-reticulate::py_call(
    etpy_get_export("bootstrap_functional_mixed_effects_coefficients"),
    result=pyref,n_bootstrap=100L,random_state=23L)
  sampled<-et_to_r(reticulate::py_get_attr(pyboot,
    "sampled_participant_indices"))
  expect_identical(dim(sampled),c(100L,8L))
  native<-etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,random_state=23L)
  expect_equal(native$sampled_participant_indices,sampled,tolerance=0)
  for(field in c("bootstrap_fixed_basis_coefficients",
      "bootstrap_coefficient_functions","bootstrap_mean",
      "bootstrap_standard_errors","sampled_participant_indices")){
    a<-native[[field]]
    b<-et_to_r(reticulate::py_get_attr(pyboot,field))
    expect_equal(unname(a),unname(b),tolerance=1e-7,
      ignore_attr=TRUE,info=paste("pinned mixed GLS",field))
  }
  expect_identical(native$covariance_conditioning,
    et_to_r(reticulate::py_get_attr(pyboot,"covariance_conditioning")))
  for(scope in c("coefficient","family")){
    bands<-etr_functional_mixed_effects_simultaneous_bands(
      native,confidence_level=.9,simultaneous_scope=scope)
    source<-reticulate::py_call(
      etpy_get_export("functional_mixed_effects_simultaneous_bands"),
      bootstrap=pyboot,confidence_level=.9,
      simultaneous_scope=scope)
    for(field in c("lower","upper","critical_values",
        "max_statistics","pointwise_standard_errors")){
      expect_equal(unname(bands[[field]]),
        unname(et_to_r(reticulate::py_get_attr(source,field))),
        tolerance=1e-7,ignore_attr=TRUE,
        info=paste("pinned joint GLS simultaneous bands",scope,field))
    }
  }
})

test_that("native iid likelihood refits use the same seeded participant bundles",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned NumPy participant indices are opt-in")
  if(!identical(Sys.getenv("ET_RUN_SCIENTIFIC_SLOW"),"true"))
    skip("20 full native likelihood refits are opt-in")
  fit<-.etr_joint_fixed_boot_fixture()
  rng<-reticulate::import("numpy",convert=TRUE)$random$default_rng(23L)
  units<-length(fit$participant_ids)
  expected<-rng$integers(0L,units,size=reticulate::tuple(20L,units))
  actual<-etr_bootstrap_functional_mixed_effects_full_refit(
    fit,n_bootstrap=20L,random_state=23L)
  expect_equal(actual$sampled_participant_indices,expected,tolerance=0)
  expect_true(all(actual$convergence_flags))
})
