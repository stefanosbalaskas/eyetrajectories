# Frozen source: eyetrajectoriespy 1.2.0 generalized_function_on_scalar.py
# Native R GLM score solver with participant-cluster sandwich covariance.
.etr_native_gee_fixture<-function(family="poisson",grouped=FALSE){
  time<-seq(0,1,length.out=7L)
  n<-36L;nt<-length(time)
  z<-outer(seq_len(n),seq_len(nt),function(i,j){
    if(family=="poisson") (i+2*j+(i*j)%%3)%%6
    else as.integer((i+j+i*j)%%5<2)
  })
  den<-NULL
  if(grouped){
    den<-outer(seq_len(n),seq_len(nt),
      function(i,j)3L+(i+j)%%3L)
    z<-outer(seq_len(n),seq_len(nt),
      function(i,j)(i+2*j)%%4)
    z<-pmin(z,den)
  }
  x<-etr_trajectory_set(time,array(as.numeric(z),c(n,nt,1L)),
    sprintf("curve%02d",seq_len(n)),"outcome",
    metadata=data.frame(participant_id=rep(
      sprintf("P%02d",1:12),each=3)),
    coordinate_system="unknown",time_unit="s")
  design<-data.frame(curve_id=rev(x$curve_ids),
    treatment=as.numeric((rev(seq_len(n))%%4)<2))
  list(x=x,design=design,den=den)
}

test_that("native Poisson GEE fits real expanded spline and participant sandwich",{
  f<-.etr_native_gee_fixture()
  model<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,predictors="treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L)
  expect_s3_class(model,"etr_generalized_function_on_scalar")
  expect_identical(dim(model$coefficient_functions),c(2L,7L))
  expect_identical(dim(model$parameter_covariance),c(8L,8L))
  expect_identical(dim(model$mean_functions),c(36L,7L))
  expect_identical(model$expanded_design_rank,8L)
  expect_equal(rowSums(model$basis),rep(1,7),tolerance=1e-12)
  expect_true(all(is.finite(model$coefficient_functions)))
  expect_true(all(model$coefficient_standard_errors>=0))
  expect_equal(model$parameter_covariance,t(model$parameter_covariance),
    tolerance=1e-12)
  expect_equal(model$mean_functions,
    exp(model$scalar_design_matrix%*%model$coefficient_functions),
    tolerance=1e-8)
  expect_false(model$provenance$full_source_contract_certified)
  w<-etr_run_generalized_functional_workflow(
    f$x,f$design,list(predictors="treatment",
      participant_column="participant_id",
      dimension="outcome",family="poisson",
      basis_size=4L,spline_degree=3L))
  expect_s3_class(w,"etr_generalized_functional_workflow")
  expect_equal(w$fit$coefficient_functions,model$coefficient_functions)
  expect_equal(nrow(w$tables$coefficients),14L)
  expect_false(w$provenance$independently_certified_full_contract)
  expect_true(w$provenance$automatic_model_selection_performed==FALSE)
})

test_that("native grouped binomial and Poisson exposure are explicit",{
  f<-.etr_native_gee_fixture("binomial",grouped=TRUE)
  z<-etr_fit_generalized_function_on_scalar_regression(f$x,f$design,
    "treatment",participant_column="participant_id",
    dimension="outcome",family="binomial",
    binomial_denominator=f$den,basis_size=4L,spline_degree=3L)
  expect_equal(z$binomial_expected_successes,
    z$mean_functions*f$den,tolerance=1e-12)
  expect_true(all(z$mean_functions>0&z$mean_functions<1))
  expect_identical(z$binomial_denominators,f$den)
  f<-.etr_native_gee_fixture()
  exposure<-rep(2,36L)
  p<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",exposure=exposure,
    exposure_units="person_hours",basis_size=4L,spline_degree=3L)
  expect_equal(p$mean_functions,p$rate_functions*2,tolerance=1e-8)
  expect_identical(p$exposure_units,"person_hours")
  expect_true(p$exposure_expanded_from_curve)
  expect_error(etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",participant_column="participant_id",
    dimension="outcome",family="poisson",
    binomial_denominator=rep(2,36L),basis_size=4L),
    "must match declared family")
})

test_that("native generalized estimator rejects unsupported or invalid source domains",{
  f<-.etr_native_gee_fixture()
  call<-function(...)etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L,...)
  expect_error(call(working_correlation="exchangeable"),"independence")
  expect_error(call(covariance_type="naive"),"robust")
  expect_error(call(basis_size=2L),"basis_size")
  expect_error(etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="gaussian",basis_size=4L,spline_degree=3L),"family")
  expect_error(call(exposure=rep(-1,36L)),"positive")
  expect_error(etr_run_generalized_functional_workflow(
    f$x,f$design,list(predictors="treatment",
      participant_column="participant_id",dimension="outcome",
      family="poisson",preprocessing=list(normalize=TRUE))),
    "empty preprocessing")
})

test_that("published Python 1.2 direct GEE Poisson spline and robust SE agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 generalized GEE numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from eyetrajectoriespy.types import TrajectorySet
from eyetrajectoriespy.generalized_function_on_scalar import fit_generalized_function_on_scalar_regression
n=36
t=np.linspace(0,1,7)
idx=np.arange(1,n+1)[:,None]
j=np.arange(1,8)[None,:]
y=((idx+2*j+(idx*j)%3)%6).astype(float)
ids=tuple(f'curve{i:02d}' for i in range(1,n+1))
tr=TrajectorySet(time=t,values=y[:,:,None],curve_ids=ids,
 dimension_names=('outcome',),
 metadata=pd.DataFrame({'participant_id':[f'P{i:02d}' for i in range(1,13) for _ in range(3)]}),
 coordinate_system='unknown',time_unit='s')
ordered=np.arange(1,n+1)
design=pd.DataFrame({'curve_id':[f'curve{i:02d}' for i in ordered],
 'treatment':(ordered%4<2).astype(float)})
pygee=fit_generalized_function_on_scalar_regression(tr,design,
 ['treatment'],participant_column='participant_id',
 dimension='outcome',family='poisson',basis_size=4,spline_degree=3)
_pygee_oracle={'basis':pygee.basis,
 'coef':pygee.coefficient_functions,
 'se':pygee.coefficient_standard_errors,
 'mean':pygee.mean_functions,
 'cov':pygee.parameter_covariance}
")
  py<-reticulate::py_to_r(reticulate::py_eval("_pygee_oracle",
    convert=FALSE))
  f<-.etr_native_gee_fixture()
  r<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L)
  expect_equal(unname(r$basis),unname(py$basis),tolerance=1e-9)
  expect_equal(unname(r$coefficient_functions),unname(py$coef),
    tolerance=1e-5)
  expect_equal(unname(r$coefficient_standard_errors),unname(py$se),
    tolerance=1e-4)
  expect_equal(unname(r$mean_functions),unname(py$mean),tolerance=1e-5)
  expect_equal(unname(r$parameter_covariance),unname(py$cov),tolerance=1e-4)
})
