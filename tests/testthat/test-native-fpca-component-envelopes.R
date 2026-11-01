# Frozen Python 1.2 stability.py descriptive component-envelope contract.
.etr_fpca_envelope_fixture<-function() {
  nt<-19L;n<-12L
  t<-seq(0,1,length.out=nt)
  a<-array(0,c(n,nt,2L))
  for(i in seq_len(n)) {
    a[i,,1L]<-sin(2*pi*t)*(1+i/23)+
      .3*cos(4*pi*t+i/7)+t*i/13
    a[i,,2L]<-cos(2*pi*t+i/9)+(i/17)*sin(pi*t)+.1*t^2
  }
  etr_trajectory_set(t,a,sprintf("c%02d",seq_len(n)),
    c("x","y"),
    metadata=data.frame(subject=rep(sprintf("p%02d",1:6),each=2)),
    coordinate_system="normalized",time_unit="s")
}

test_that("matched bootstrap descriptive FPCA envelopes have coherent shapes",{
  x<-.etr_fpca_envelope_fixture()
  set.seed(193L)
  rng<-.Random.seed
  z<-etr_bootstrap_fpca_component_envelopes(
    x,n_bootstrap=5L,n_components=2L,level=.8,
    resample_unit="participant",participant_column="subject",
    random_state=41L)
  expect_identical(rng,.Random.seed)
  expect_s3_class(z,"etr_fpca_component_envelope")
  expect_identical(dim(z$lower),c(2L,19L,2L))
  expect_identical(dim(z$median),c(2L,19L,2L))
  expect_identical(dim(z$upper),c(2L,19L,2L))
  expect_identical(dim(z$similarities),c(5L,2L))
  expect_true(all(z$lower<=z$median & z$median<=z$upper))
  expect_true(all(is.finite(z$lower)))
  expect_true(all(is.finite(z$similarities)))
  expect_true(all(z$similarities>=0 & z$similarities<=1+1e-12))
  expect_identical(z$provenance$coverage_claim,"descriptive_pointwise_only")
  expect_false(z$provenance$source_python_equivalent_stochastic_draws)
  again<-etr_bootstrap_fpca_component_envelopes(x,5L,2L,
    level=.8,resample_unit="participant",participant_column="subject",
    random_state=41L)
  expect_identical(z$lower,again$lower)
  expect_identical(z$median,again$median)
  expect_identical(z$upper,again$upper)
})

test_that("native FPC envelopes fail closed on unsupported specifications",{
  x<-.etr_fpca_envelope_fixture()
  f<-etr_bootstrap_fpca_component_envelopes
  expect_error(f(x,n_bootstrap=1L),"n_bootstrap")
  expect_error(f(x,n_components=length(x$curve_ids)),"n_components")
  expect_error(f(x,n_components=0L),"n_components")
  expect_error(f(x,level=1),"level")
  expect_error(f(x,level=NA_real_),"level")
  expect_error(f(x,resample_unit="wrong"),"resample_unit")
  expect_error(f(x,resample_unit="participant"),"participant_column")
  bad<-x;bad$values[1L,1L,1L]<-NA_real_
  expect_error(f(bad),"complete")
})

test_that("NumPy 1.2 pointwise quantiles match native R type seven",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 component-envelope quantile oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  sample<-array(seq_len(5L*2L*3L*2L)/17,
    c(5L,2L,3L,2L))
  native<-eyetrajectories:::.etr_fpca_envelope_quantiles(sample,.8)
  reticulate::py_run_string("
import numpy as np
def frozen_component_envelope_source_quantiles(values,level):
    alpha=(1.0-level)/2.0
    return (np.quantile(values,alpha,axis=0),
            np.median(values,axis=0),
            np.quantile(values,1.0-alpha,axis=0))
")
  fn<-reticulate::py_eval(
    "frozen_component_envelope_source_quantiles",convert=FALSE)
  source<-reticulate::py_to_r(reticulate::py_call(fn,
    reticulate::r_to_py(sample),as.numeric(.8)))
  expect_equal(unname(native$lower),unname(source[[1L]]),
    tolerance=1e-12)
  expect_equal(unname(native$median),unname(source[[2L]]),
    tolerance=1e-12)
  expect_equal(unname(native$upper),unname(source[[3L]]),
    tolerance=1e-12)
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})

# Actual pinned-Python 1.2 public export and source-signature witness.
# This verifies callable/source availability, NOT native scientific parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: bootstrap_fpca_component_envelopes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("bootstrap_fpca_component_envelopes"),"bootstrap_fpca_component_envelopes")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
