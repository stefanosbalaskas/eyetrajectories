# Published Python 1.2 wild_selection.py: common basis and shared B-by-n
# multiplier rows across explicit adjacent inference truncations.
test_that("native wild truncation scan shares multiplier draws and full FPCA basis",{
  f<-.etr_wild_projection_fixture()
  scan<-etr_scan_wild_bootstrap_fpca_truncations(
    f$x,f$y,candidate_components=c(2L,3L),
    residual_components=2L,n_bootstrap=20L,
    multiplier_draws=f$draws,confidence_level=.95)
  expect_s3_class(scan,"etr_fpca_wild_bootstrap_truncation_scan")
  expect_identical(scan$candidate_components,c(2L,3L))
  expect_identical(scan$reference_fpca$n_components,3L)
  expect_identical(dim(scan$reference_projections),c(2L,24L))
  expect_identical(dim(scan$studentized_roots),c(2L,20L,24L))
  expect_equal(scan$centers,(scan$lower+scan$upper)/2)
  expect_equal(scan$widths,scan$upper-scan$lower)
  expect_true(scan$provenance$fpca_wild_bootstrap_truncation_scan$
    shared_multiplier_draws_across_h)
  expect_false(scan$provenance$fpca_wild_bootstrap_truncation_scan$
    source_full_contract_certified)
  top<-etr_wild_bootstrap_fpca_projection(f$x,f$y,
    n_bootstrap=20L,residual_components=2L,
    inference_components=3L,multiplier_draws=f$draws)
  expect_equal(as.numeric(scan$reference_projections[2L,]),
    top$reference_projection,tolerance=1e-9)
  expect_equal(as.numeric(scan$critical_values[2L,]),
    top$critical_values,tolerance=1e-8)
  expect_equal(unname(scan$studentized_roots[2L,,]),
    unname(top$studentized_roots),tolerance=1e-8)
  selected<-etr_select_fpca_wild_bootstrap_truncation(
    scan,width_threshold=100,center_threshold=100,
    stability_run=0L,on_failure="error")
  expect_equal(selected$selected_components,rep(2,24))
})

test_that("native wild scan rejects non-consecutive candidate grid",{
  f<-.etr_wild_projection_fixture()
  go<-function(h)etr_scan_wild_bootstrap_fpca_truncations(
    f$x,f$y,candidate_components=h,n_bootstrap=20L,
    residual_components=2L,multiplier_draws=f$draws)
  expect_error(go(2L),"candidate_components")
  expect_error(go(c(2L,4L)),"consecutive")
  expect_error(go(c(1L,2L)),"at least residual_components")
  expect_error(go(c(2L,2L)),"consecutive")
  expect_error(go(c(2L,3L,50L)),"consecutive")
})

test_that("frozen Python 1.2 shared-multiplier scan numerical oracle matches R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 shared multiplier FPCR scan oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy.wild_selection as wildsel
from eyetrajectoriespy.types import TrajectorySet
n=24
tt=np.linspace(0,1,13)
yy3=np.zeros((n,len(tt),1),dtype=float)
for i in range(1,n+1):
 yy3[i-1,:,0]=.25*np.sin(2*np.pi*tt)+.13*np.cos(i*.8)*np.cos(np.pi*tt)+.09*np.sin(i*.57)*np.sin(3*np.pi*tt)+.07*np.cos(i*.21)*tt**2
scalary=np.array([.6*np.cos(i*.8)-.35*np.sin(i*.57)+.04*np.cos(i*.37) for i in range(1,n+1)])
draws=np.array([[.9*np.sin(i*j*.49)+.4*np.cos(i+j*.23) for j in range(1,n+1)] for i in range(1,21)])
traj=TrajectorySet(time=tt,values=yy3,
 curve_ids=tuple(f'curve{i:02d}' for i in range(1,n+1)),
 dimension_names=('x',),metadata=pd.DataFrame(index=range(n)),
 coordinate_system='unknown',time_unit='s')
old=wildsel._draw_wild_multipliers
idx=[0]
def oracle_draw(rng,*,n,multiplier):
 out=draws[idx[0]].copy()
 idx[0]+=1
 return out
try:
 wildsel._draw_wild_multipliers=oracle_draw
 scan=wildsel.scan_wild_bootstrap_fpca_truncations(
  traj,scalary,candidate_components=(2,3),
  n_bootstrap=20,residual_components=2,confidence_level=.95)
finally:
 wildsel._draw_wild_multipliers=old
_py_wild_scan={
 'reference':scan.reference_projections,
 'se':scan.reference_se,
 'critical':scan.critical_values,
 'centers':scan.centers,
 'widths':scan.widths,
 'roots':scan.studentized_roots}
")
  # Repeat source scan with the same 20 multipliers, preserving
  # the Python test-oracle random-draw boundary and checking source arrays.
  reticulate::py_run_string("
def _source_public_scan_replay(fn):
    original=wildsel._draw_wild_multipliers
    position=[0]
    def draw(rng,*,n,multiplier):
        if n!=24 or position[0]>=len(draws):
            raise AssertionError('source scan wild multiplier count mismatch')
        z=draws[position[0]].copy()
        position[0]+=1
        return z
    try:
        wildsel._draw_wild_multipliers=draw
        result=fn(traj,scalary,candidate_components=(2,3),
            n_bootstrap=20,residual_components=2,confidence_level=.95)
        if position[0]!=20:
            raise AssertionError('source scan did not consume all fixed draws')
        return result
    finally:
        wildsel._draw_wild_multipliers=original
")
  direct<-reticulate::py_call(
    reticulate::py_eval("_source_public_scan_replay",convert=FALSE),
    etpy_get_export("scan_wild_bootstrap_fpca_truncations"))
  saved<-reticulate::py_eval("scan",convert=FALSE)
  for(field in c("reference_projections","reference_se",
    "critical_values","centers","widths","studentized_roots")){
    expect_equal(et_to_r(reticulate::py_get_attr(direct,field)),
      et_to_r(reticulate::py_get_attr(saved,field)),
      tolerance=1e-12,ignore_attr=TRUE,
      info=paste("exact source wild scan replay",field))
  }
  # Verify the public source scan tables and exact target-wise
  # stabilized-volatility selection on the same fixed Python scan.
  py_scan<-reticulate::py_eval("scan",convert=FALSE)
  table<-et_to_r(reticulate::py_call(
    etpy_get_export("fpca_wild_bootstrap_truncation_scan_frame"),
    result=py_scan))
  expect_identical(nrow(table),48L)
  expect_setequal(unique(as.integer(table$inference_components)),
    c(2L,3L))
  expect_identical(length(unique(as.character(table$curve_id))),24L)
  selected<-reticulate::py_call(
    etpy_get_export("select_fpca_wild_bootstrap_truncation"),
    scan=py_scan,width_threshold=100,center_threshold=100,
    stability_run=0L,on_failure="error")
  # The native R-only selection test independently verifies the same
  # earliest h=2 decision; avoid a redundant second expensive R scan.
  expect_equal(as.numeric(et_to_r(reticulate::py_get_attr(
    selected,"selected_components"))),rep(2,24L),
    tolerance=0,ignore_attr=TRUE)
  selection_frame<-et_to_r(reticulate::py_call(
    etpy_get_export("fpca_wild_bootstrap_truncation_selection_frame"),
    result=selected))
  expect_identical(nrow(selection_frame),24L)
  expect_identical(as.integer(
    selection_frame$selected_inference_components),
    rep(2L,24L))
  oracle<-reticulate::py_to_r(reticulate::py_eval(
    "_py_wild_scan",convert=FALSE))
  f<-.etr_wild_projection_fixture()
  x<-etr_scan_wild_bootstrap_fpca_truncations(
    f$x,f$y,candidate_components=c(2L,3L),
    residual_components=2L,n_bootstrap=20L,
    multiplier_draws=f$draws,confidence_level=.95)
  expect_equal(unname(x$reference_projections),
    unname(oracle$reference),tolerance=1e-6)
  expect_equal(unname(x$reference_se),
    unname(oracle$se),tolerance=1e-5)
  expect_equal(unname(x$critical_values),
    unname(oracle$critical),tolerance=1e-4)
  expect_equal(unname(x$centers),
    unname(oracle$centers),tolerance=1e-5)
  expect_equal(unname(x$widths),
    unname(oracle$widths),tolerance=1e-5)
  expect_equal(unname(x$studentized_roots),
    unname(oracle$roots),tolerance=1e-4)
})

test_that("unseeded wild scan shares ambient-R multiplier draws across h", {
  f<-.etr_wild_projection_fixture()
  withr::local_seed(23873L)
  a<-etr_scan_wild_bootstrap_fpca_truncations(
    f$x,f$y,candidate_components=c(2L,3L),
    residual_components=2L,n_bootstrap=20L,random_state=NULL)
  set.seed(23873L)
  b<-etr_scan_wild_bootstrap_fpca_truncations(
    f$x,f$y,candidate_components=c(2L,3L),
    residual_components=2L,n_bootstrap=20L,random_state=NULL)
  expect_null(a$random_state)
  expect_equal(a$studentized_roots,b$studentized_roots,tolerance=0)
  expect_true(all(is.finite(a$widths)))
})
