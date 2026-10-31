# Frozen source wild_regression.py numerical fixed multiplier witness.
test_that("source frozen Gaussian FPCR wild bootstrap reuses fixed draws",{
  f<-.etr_wild_projection_fixture()
  x<-etr_wild_bootstrap_fpca_projection(f$x,f$y,
    n_bootstrap=20L,residual_components=2L,
    inference_components=3L,confidence_level=.95,
    multiplier_draws=f$draws)
  expect_s3_class(x,"etr_fpca_wild_bootstrap_projection")
  expect_identical(dim(x$bootstrap_projections),c(20L,24L))
  expect_identical(dim(x$studentized_roots),c(20L,24L))
  expect_equal(x$lower,x$reference_projection-
    x$critical_values*x$reference_se)
  expect_equal(x$upper,x$reference_projection+
    x$critical_values*x$reference_se)
  expect_equal(x$critical_values,
    vapply(seq_len(24L),function(i)
      sort(abs(x$studentized_roots[,i]))[20L],numeric(1L)))
  expect_true(all(is.finite(x$reference_projection)))
  expect_true(all(is.finite(x$reference_se)))
  expect_true(all(is.finite(x$studentized_roots)))
  expect_true(x$provenance$fpca_wild_bootstrap_projection$
    fixed_source_multiplier_draws_supplied)
  expect_false(x$provenance$fpca_wild_bootstrap_projection$
    source_full_contract_certified)
  frame<-etr_fpca_wild_bootstrap_projection_frame(x)
  expect_equal(nrow(frame),24L)
  family<-etr_fpca_wild_bootstrap_projection_family_test(x)
  expect_equal(length(family$targetwise_p_values),24L)
  expect_true(all(family$adjusted_p_values>=family$targetwise_p_values))
})

test_that("wild bootstrap rejects clustered or invalid scientific estimands",{
  f<-.etr_wild_projection_fixture()
  args<-list(trajectories=f$x,outcome=f$y,
    n_bootstrap=20L,residual_components=2L,
    inference_components=3L,multiplier_draws=f$draws)
  expect_error(do.call(etr_wild_bootstrap_fpca_projection,
    modifyList(args,list(n_bootstrap=19L))),"n_bootstrap")
  expect_error(do.call(etr_wild_bootstrap_fpca_projection,
    modifyList(args,list(inference_components=1L))),"inference_components")
  expect_error(do.call(etr_wild_bootstrap_fpca_projection,
    modifyList(args,list(multiplier="rademacher"))),"multiplier")
  expect_error(do.call(etr_wild_bootstrap_fpca_projection,
    modifyList(args,list(multiplier_draws=matrix(0,3,24)))),
    "multiplier_draws")
  f$x$metadata$participant<-rep(1:12,each=2L)
  args$trajectories<-f$x
  args$independent_unit_column<-"participant"
  expect_error(do.call(etr_wild_bootstrap_fpca_projection,args),
    "repeated unit IDs")
})

test_that("frozen Python 1.2 fixed wild multiplier numerical oracle matches R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 FPCR fixed wild multipliers direct-source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy.wild_regression as wildmod
from eyetrajectoriespy.types import TrajectorySet
n=24
tt=np.linspace(0,1,13)
y3=np.zeros((n,len(tt),1),dtype=float)
for i in range(1,n+1):
 y3[i-1,:,0]=.25*np.sin(2*np.pi*tt)+.13*np.cos(i*.8)*np.cos(np.pi*tt)+.09*np.sin(i*.57)*np.sin(3*np.pi*tt)+.07*np.cos(i*.21)*tt**2
yy=np.array([.6*np.cos(i*.8)-.35*np.sin(i*.57)+.04*np.cos(i*.37) for i in range(1,n+1)])
fixed=np.array([[.9*np.sin(i*j*.49)+.4*np.cos(i+j*.23) for j in range(1,n+1)] for i in range(1,21)])
t=TrajectorySet(time=tt,values=y3,
 curve_ids=tuple(f'curve{i:02d}' for i in range(1,n+1)),
 dimension_names=('x',),metadata=pd.DataFrame(index=range(n)),
 coordinate_system='unknown',time_unit='s')
old=wildmod._draw_wild_multipliers
counter=[0]
def fixed_draw(rng,*,n,multiplier):
 i=counter[0];counter[0]+=1
 return fixed[i].copy()
try:
 wildmod._draw_wild_multipliers=fixed_draw
 pyw=wildmod.wild_bootstrap_fpca_projection(t,yy,
  n_bootstrap=20,residual_components=2,inference_components=3,
  scaling='none',multiplier='normal',confidence_level=.95)
finally:
 wildmod._draw_wild_multipliers=old
_py_wild_projection={
 'reference':pyw.reference_projection,
 'pseudo_truth':pyw.pseudo_truth_projection,
 'se':pyw.reference_se,
 'projections':pyw.bootstrap_projections,
 'bootstrap_se':pyw.bootstrap_se,
 'roots':pyw.studentized_roots,
 'critical':pyw.critical_values}
")
  oracle<-reticulate::py_to_r(reticulate::py_eval(
    "_py_wild_projection",convert=FALSE))
  f<-.etr_wild_projection_fixture()
  fit<-etr_wild_bootstrap_fpca_projection(f$x,f$y,
    n_bootstrap=20L,residual_components=2L,
    inference_components=3L,confidence_level=.95,
    multiplier_draws=f$draws)
  expect_equal(unname(fit$reference_projection),
    unname(oracle$reference),tolerance=1e-6)
  expect_equal(unname(fit$pseudo_truth_projection),
    unname(oracle$pseudo_truth),tolerance=1e-6)
  expect_equal(unname(fit$reference_se),
    unname(oracle$se),tolerance=1e-5)
  expect_equal(unname(fit$bootstrap_projections),
    unname(oracle$projections),tolerance=1e-5)
  expect_equal(unname(fit$bootstrap_se),
    unname(oracle$bootstrap_se),tolerance=1e-5)
  expect_equal(unname(fit$studentized_roots),
    unname(oracle$roots),tolerance=1e-4)
  expect_equal(unname(fit$critical_values),
    unname(oracle$critical),tolerance=1e-4)
})
