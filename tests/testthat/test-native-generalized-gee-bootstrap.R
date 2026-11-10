# Source frozen Python 1.2 participant-case GEE bootstrap:
# duplicate participant source bundles receive NEW independent bootstrap IDs.
.etr_native_gee_sampled_indices<-function(B=100L,np=12L){
  x<-matrix(0L,B,np)
  for(b in seq_len(B))x[b,]<-(0:(np-1L)+(b-1L))%%np
  x[1L,]<-rep(0:2,each=4L)
  x
}

test_that("native generalized GEE case bootstrap refits whole participant bundles",{
  f<-.etr_native_gee_fixture()
  fit<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L)
  B<-100L;index<-.etr_native_gee_sampled_indices(B)
  boot<-etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=B,sampled_participant_indices=index,
    random_state=47L)
  expect_s3_class(boot,"etr_generalized_function_on_scalar_bootstrap")
  expect_identical(dim(boot$bootstrap_coefficient_functions),c(100L,2L,7L))
  expect_identical(boot$sampled_participant_indices,index)
  expect_identical(length(boot$sampled_source_participant_ids),100L)
  expect_identical(boot$sampled_source_participant_ids[[1L]],
    fit$participant_ids[index[1L,]+1L])
  expect_identical(length(unique(boot$sampled_bootstrap_participant_ids[[1L]])),
    12L)
  expect_true(all(is.finite(boot$bootstrap_coefficient_functions)))
  expect_false(boot$provenance$
    generalized_function_on_scalar_bootstrap$failed_replicates_redrawn)
  expect_false(boot$provenance$
    generalized_function_on_scalar_bootstrap$full_source_contract_certified)
  expect_true(boot$provenance$
    generalized_function_on_scalar_bootstrap$duplicate_source_participants_receive_distinct_group_ids)
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=99L),"n_bootstrap")
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=100L,failed_replicate_policy="drop"),
    "failed_replicate_policy")
  expect_error(etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=100L,sampled_participant_indices=matrix(12,100,12)),
    "sampled_participant_indices")
})

test_that("frozen Python 1.2 manual participant-refit law agrees on duplicated clusters",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 whole-participant fixed-refit GEE oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from eyetrajectoriespy.types import TrajectorySet
from eyetrajectoriespy.generalized_function_on_scalar import fit_generalized_function_on_scalar_regression
n=36;tt=np.linspace(0,1,7)
ii=np.arange(1,37)[:,None];jj=np.arange(1,8)[None,:]
yy=((ii+2*jj+(ii*jj)%3)%6).astype(float)
participants=np.repeat([f'P{i:02d}' for i in range(1,13)],3)
design_treatment=(np.arange(1,37)%4<2).astype(float)
draws=np.repeat([0,1,2],4)
source_idx=np.concatenate([np.flatnonzero(participants==f'P{k+1:02d}') for k in draws])
boot_clusters=[f'bootstrap_0000_participant_{d:04d}' for d in range(12) for _ in range(3)]
ids=tuple(f'bootstrap_0000_curve_{k:04d}' for k in range(len(source_idx)))
tr=TrajectorySet(time=tt,values=yy[source_idx,:,None],
 curve_ids=ids,dimension_names=('outcome',),
 metadata=pd.DataFrame({'participant_id':boot_clusters}),
 coordinate_system='unknown',time_unit='s')
df=pd.DataFrame({'curve_id':ids,'treatment':design_treatment[source_idx]})
refit=fit_generalized_function_on_scalar_regression(tr,df,['treatment'],
 participant_column='participant_id',dimension='outcome',
 family='poisson',basis_size=4,spline_degree=3)
_gee_case_oracle={'coefficients':refit.coefficient_functions,
 'standard_errors':refit.coefficient_standard_errors}
")
  p<-reticulate::py_to_r(reticulate::py_eval(
    "_gee_case_oracle",convert=FALSE))
  f<-.etr_native_gee_fixture()
  fit<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",participant_column="participant_id",
    dimension="outcome",family="poisson",
    basis_size=4L,spline_degree=3L)
  z<-etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=100L,
    sampled_participant_indices=.etr_native_gee_sampled_indices())
  expect_equal(unname(z$bootstrap_coefficient_functions[1L,,]),
    unname(p$coefficients),tolerance=1e-4)
})

# Actual frozen-Python 1.2 source-symbol inspection on published exports.
# For alternate R estimands/backends this is NOT numerical source parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: bootstrap_generalized_function_on_scalar_coefficients",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("bootstrap_generalized_function_on_scalar_coefficients"),"bootstrap_generalized_function_on_scalar_coefficients")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("fixed-basis participant refit preserves native Poisson, exposure and grouped binomial coefficients",{
  for(spec in list(
      list(family="poisson",grouped=FALSE,exposed=FALSE),
      list(family="poisson",grouped=FALSE,exposed=TRUE),
      list(family="binomial",grouped=TRUE,exposed=FALSE))){
    f<-.etr_native_gee_fixture(spec$family,grouped=spec$grouped)
    exp<-if(spec$exposed)rep(2.5,36L) else NULL
    fit<-etr_fit_generalized_function_on_scalar_regression(
      f$x,f$design,"treatment",participant_column="participant_id",
      dimension="outcome",family=spec$family,
      binomial_denominator=f$den,exposure=exp,
      basis_size=4L,spline_degree=3L)
    direct<-.etr_gfosr_bootstrap_fixed_basis_refit(
      fit,seq_len(36L),fit$curve_participant_ids)
    expect_equal(unname(direct),unname(fit$coefficient_functions),
      tolerance=1e-8,info=paste(spec$family,spec$grouped,spec$exposed))
  }
})

test_that("whole-participant bootstrap accepts unseeded source input domain",{
  f<-.etr_native_gee_fixture()
  fit<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",participant_column="participant_id",
    dimension="outcome",family="poisson",basis_size=4L,spline_degree=3L)
  withr::local_seed(5831L)
  a<-etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=100L,random_state=NULL)
  set.seed(5831L)
  b<-etr_bootstrap_generalized_function_on_scalar_coefficients(
    fit,n_bootstrap=100L,random_state=NULL)
  expect_null(a$random_state)
  expect_equal(a$sampled_participant_indices,
    b$sampled_participant_indices,tolerance=0)
  expect_equal(a$bootstrap_coefficient_functions,
    b$bootstrap_coefficient_functions,tolerance=0)
})
