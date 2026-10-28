# Stage 18 restricted native functional mixed-effects moments and diagnostics.

.etr18_fixture<-function(){
  n<-18L;t<-seq(0,1,length.out=17L)
  groups<-rep(sprintf("p%02d",1:6),each=3L)
  z<-rep(c(-1,0,1),6L)+rep((1:6-3.5)/10,each=3L)
  Y<-array(0,c(n,length(t),1L))
  for(i in seq_len(n)){
    g<-match(groups[i],unique(groups))
    Y[i,,1L]<-1+.55*sin(pi*t)+.7*z[i]*cos(pi*t)+
      .15*g*sin(2*pi*t)+.1*sin(6*pi*t+.4*i)+
      .05*cos(3*pi*t+i*.7)+.025*i*t
  }
  x<-etr_trajectory_set(t,Y,sprintf("c%02d",1:n),"x",
    metadata=data.frame(participant_id=groups),
    time_unit="s",coordinate_system="normalized")
  list(x=x,design=data.frame(curve_id=x$curve_ids,exposure=z))
}

test_that("Stage 18 restricted mixed-moment regression has explicit provenance and PSD covariance",{
  fixture<-.etr18_fixture()
  z<-etr_fit_functional_mixed_effects_regression(fixture$x,
    fixture$design,predictors="exposure",
    participant_column="participant_id",dimension="x")
  expect_s3_class(z,"etr_functional_mixed_moments")
  expect_identical(z$estimator,"two_level_functional_method_of_moments")
  expect_false(z$provenance$source_python_equivalent)
  expect_false(z$provenance$likelihood_optimized)
  expect_equal(dim(z$coefficient_functions),c(2L,17L))
  expect_equal(dim(z$coefficient_standard_errors),c(2L,17L))
  expect_equal(dim(z$residual_functions),c(18L,17L))
  expect_equal(dim(z$random_intercept_covariance),c(17L,17L))
  expect_true(all(eigen(z$random_intercept_covariance,
    symmetric=TRUE,only.values=TRUE)$values>=-1e-9))
  expect_true(all(is.finite(z$residual_functions)))
  expect_true(z$residual_variance>0)
  expect_true(all(z$curves_per_participant==3L))
  expect_equal(z$fitted_functions+z$residual_functions,
    z$observed_functions,tolerance=1e-12)
  expect_equal(z$coefficient_functions,
    qr.solve(z$scalar_design_matrix,z$observed_functions),
    tolerance=1e-11)
  expect_error(etr_fit_functional_mixed_effects_regression(fixture$x,
    transform(fixture$design,exposure=1),predictors="exposure",
    participant_column="participant_id",dimension="x"),"rank deficient")
  bad<-fixture$x;bad$metadata$participant_id[1L]<-NA_character_
  expect_error(etr_fit_functional_mixed_effects_regression(bad,
    fixture$design,"exposure","participant_id","x"),"complete")
})

test_that("Stage 18 whitening is within-trial and uses finite positive definite covariance",{
  a<-.etr18_fixture()
  fit<-etr_fit_functional_mixed_effects_regression(a$x,a$design,
    "exposure","participant_id","x")
  w<-etr_functional_mixed_effects_whitened_residuals(fit)
  expect_identical(dim(w),c(18L,17L))
  expect_true(all(is.finite(w)))
  V<-fit$residual_variance*fit$residual_correlation_matrix
  L<-t(chol(V))
  expect_equal(as.vector(L%*%w[1L,]),as.vector(fit$residual_functions[1L,]),
    tolerance=1e-8)
  expect_equal(w[1L,],
    as.vector(forwardsolve(L,fit$residual_functions[1L,])),
    tolerance=1e-8)
  invalid<-fit;invalid$residual_correlation_matrix[1L,1L]<- -1
  expect_error(etr_functional_mixed_effects_whitened_residuals(invalid),
    "not positive definite")
})

test_that("Stage 18 raw and whitened residual lag diagnostics preserve physical lag",{
  a<-.etr18_fixture()
  fit<-etr_fit_functional_mixed_effects_regression(a$x,a$design,
    "exposure","participant_id","x")
  r<-etr_functional_mixed_effects_residual_diagnostics(fit,
    max_lag=3L,residual_scale="raw")
  expect_s3_class(r,"etr_functional_mixed_residual_diagnostics")
  expect_equal(nrow(r$trial_diagnostics),18L*4L)
  expect_equal(nrow(r$participant_diagnostics),6L*4L)
  expect_equal(nrow(r$overall_diagnostics),4L)
  expect_true(all(r$trial_diagnostics$n_pairs%in%14:17))
  expect_equal(r$trial_diagnostics$autocorrelation[
    r$trial_diagnostics$lag_index==0L],rep(1,18),tolerance=1e-10)
  expect_equal(r$trial_diagnostics$semivariance[
    r$trial_diagnostics$lag_index==0L],rep(0,18),tolerance=0)
  expect_equal(r$overall_diagnostics$lag_time_mean,
    (0:3)/16,tolerance=1e-12)
  expect_true(all(is.finite(r$participant_diagnostics$autocovariance)))
  expect_equal(r$overall_diagnostics$n_pairs[1L],18L*17L)
  wr<-etr_functional_mixed_effects_residual_diagnostics(fit,
    max_lag=3L,residual_scale="whitened")
  expect_identical(wr$residual_scale,"whitened")
  expect_equal(nrow(wr$trial_diagnostics),nrow(r$trial_diagnostics))
  expect_error(etr_functional_mixed_effects_residual_diagnostics(fit,
    max_lag=17L),"max_lag")
  expect_error(etr_functional_mixed_effects_residual_diagnostics(fit,
    max_lag=3L,residual_scale="random"),"residual_scale")
})

test_that("Stage 18 diagnostic and exact residual-pair frames preserve index semantics",{
  a<-.etr18_fixture()
  fit<-etr_fit_functional_mixed_effects_regression(a$x,a$design,
    "exposure","participant_id","x")
  d<-etr_functional_mixed_effects_residual_diagnostics(fit,3L)
  trial<-etr_functional_mixed_effects_residual_diagnostic_frame(d,
    "trial",curve_id="c01")
  expect_equal(nrow(trial),4L)
  expect_true(all(trial$curve_id=="c01"))
  part<-etr_functional_mixed_effects_residual_diagnostic_frame(d,
    "participant",participant_id="p01")
  expect_equal(nrow(part),4L)
  overall<-etr_functional_mixed_effects_residual_diagnostic_frame(d,"overall")
  expect_equal(nrow(overall),4L)
  pairs<-etr_functional_mixed_effects_residual_pair_frame(d,
    lag_index=2L,curve_id="c01")
  expect_equal(nrow(pairs),15L)
  expect_equal(pairs$time_end-pairs$time_start,
    rep(2/16,15),tolerance=1e-12)
  expect_identical(pairs$start_index,0:14)
  expect_identical(pairs$end_index,2:16)
  expect_equal(sum(pairs$centered_product)/15,
    trial$autocovariance[3L],tolerance=1e-12)
  expect_equal(mean(pairs$semivariance_contribution),
    trial$semivariance[3L],tolerance=1e-12)
  expect_error(etr_functional_mixed_effects_residual_pair_frame(d,4L),
    "exceeds max_lag")
  expect_error(etr_functional_mixed_effects_residual_diagnostic_frame(d,
    "overall",curve_id="c01"),"only")
})

test_that("Stage 18 coefficient and variance frames retain native inferential boundaries",{
  a<-.etr18_fixture()
  fit<-etr_fit_functional_mixed_effects_regression(a$x,a$design,
    "exposure","participant_id","x")
  cf<-etr_functional_mixed_effects_coefficient_frame(fit)
  expect_identical(names(cf),c("coefficient","time","dimension",
    "estimate","standard_error","lower_95_wald","upper_95_wald"))
  expect_equal(nrow(cf),2L*17L)
  expect_true(all(cf$lower_95_wald<=cf$upper_95_wald))
  # Numeric coefficient equality is independent of matrix dimname metadata.
  # Check the coefficient identity explicitly in the source-shaped table.
  expect_identical(cf$coefficient[1L],"Intercept")
  expect_equal(unname(cf$estimate[1L]),
    unname(fit$coefficient_functions[1L,1L]))
  v<-etr_functional_mixed_effects_variance_decomposition(fit,
    model_label="restricted-model")
  expect_identical(sort(unique(v$component)),
    sort(c("participant_intercept_variance","residual_variance")))
  expect_equal(nrow(v),2L*17L)
  expect_equal(v$value[v$component=="participant_intercept_variance"],
    diag(fit$random_intercept_covariance),tolerance=1e-10)
  expect_true(all(v$value>=0))
  expect_error(etr_functional_mixed_effects_coefficient_frame(fit,band=1),
    "not yet qualified")
  expect_error(etr_functional_mixed_effects_variance_decomposition(fit,
    model_label=""),"model_label")
})

test_that("Stage 18 frozen source map does not imply full likelihood equivalence",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),175L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),205L)
  expect_equal(sum(z$native_implementation_started),150L)
  expect_equal(sum(z$native_implementation_stage==18L,na.rm=TRUE),7L)
  expect_equal(sum(!z$is_python_function &
    is.na(z$native_representation_stage)),121L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 18 Python 1.2 reference source numerical formulas opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 18 NumPy residual diagnostics formula oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  a<-.etr18_fixture()
  fit<-etr_fit_functional_mixed_effects_regression(a$x,a$design,
    "exposure","participant_id","x")
  R<-fit$residual_functions[1L,]
  # Numerically verify the published Python 1.2 formulas on the exact
  # same R residual vector, without comparing distinct mixed estimators.
  np<-reticulate::import("numpy",convert=TRUE)
  y<-np$array(as.numeric(R),dtype="float64")
  centered<-np$subtract(y,np$mean(y))
  variance<-np$mean(centered*centered)
  lag<-2L;n<-length(R)
  rawcov<-np$mean(centered[seq_len(n-lag)]*
    centered[(lag+1L):n])
  rawsemivar<-.5*np$mean((y[(lag+1L):n]-y[seq_len(n-lag)])^2)
  d<-etr_functional_mixed_effects_residual_diagnostics(fit,3L)
  trial<-etr_functional_mixed_effects_residual_diagnostic_frame(
    d,"trial",curve_id="c01")
  expect_equal(trial$autocovariance[lag+1L],rawcov,tolerance=1e-12)
  expect_equal(trial$autocorrelation[lag+1L],rawcov/variance,
    tolerance=1e-12)
  expect_equal(trial$semivariance[lag+1L],rawsemivar,tolerance=1e-12)
  # This is a NumPy-formula oracle, NOT an equivalence check with
  # Python's spline MixedLM fitting result.
})
