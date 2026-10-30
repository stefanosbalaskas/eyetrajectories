# Frozen Python 1.2.0 FPCA envelope, sparse PACE, familywise bootstrap
# plot-data oracles. Strictly descriptive; no estimator or calibration change.
.etr_fpca_inference_visual_fixture <- function() {
  t<-c(0,.5,1)
  components<-array(0,dim=c(2L,3L,2L))
  components[1L,,1L]<-c(1,0,-1)
  components[1L,,2L]<-c(-1,0,1)
  components[2L,,1L]<-c(.5,1,.5)
  components[2L,,2L]<-c(.5,0,-.5)
  envelope<-list(reference=list(time=t,time_unit="s",
    dimension_names=c("x","y"),components=components),
    lower=components-.2,median=components,upper=components+.2,
    level=.95)
  sparse<-list(score_diagnostics=data.frame(
    n_samples=c(3,4,5,6),
    condition_number=c(4,2,Inf,8),
    status_code=c("ok","failed","failed","ok")))
  family<-list(projection_result=list(target_curve_ids=c("a","b","c")),
    adjusted_p_values=c(.2,.4,.6),
    targetwise_p_values=c(.1,.3,.5),
    significance_level=.05)
  list(envelope=envelope,sparse=sparse,family=family)
}
.etr_fpca_inference_visual_pdf <- function(code) {
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(code)
}
test_that("FPCA component, PACE score and familywise tail plots retain source data",{
  x<-.etr_fpca_inference_visual_fixture()
  .etr_fpca_inference_visual_pdf({
    a<-etr_plot_fpca_component_envelope(x$envelope)
    expect_equal(a$time,c(0,.5,1))
    expect_equal(a$median,c(1,0,-1))
    expect_equal(a$lower,c(.8,-.2,-1.2))
    expect_equal(a$upper,c(1.2,.2,-.8))
    b<-etr_plot_fpca_component_envelope(x$envelope,component=1L,
      dimension="y")
    expect_equal(b$reference,c(.5,0,-.5))
    score<-etr_plot_sparse_fpca_score_diagnostics(x$sparse)
    expect_equal(sum(score$geometry$finite),3L)
    expect_equal(sum(!score$geometry$finite),1L)
    expect_equal(sum(score$geometry$ok),2L)
    expect_equal(sum(score$geometry$flagged),1L)
    fam<-etr_plot_fpca_wild_bootstrap_family_test(x$family,
      max_targets=2L,show_targetwise=TRUE)
    expect_identical(fam$target_curve_id,c("a","b"))
    expect_identical(fam$target_index,0:1)
    expect_equal(fam$adjusted_p_value,c(.2,.4))
    expect_equal(fam$targetwise_p_value,c(.1,.3))
  })
})
test_that("scientific FPCA graphics reject invalid uncertainty and target inputs",{
  x<-.etr_fpca_inference_visual_fixture()
  .etr_fpca_inference_visual_pdf({
    bad<-x$envelope;bad$lower[1,1,1]<-Inf
    expect_error(etr_plot_fpca_component_envelope(bad),"lower")
    bad<-x$envelope;bad$median[1,1,1]<-100
    expect_error(etr_plot_fpca_component_envelope(bad),"ordered")
    expect_error(etr_plot_fpca_component_envelope(
      x$envelope,dimension="missing"),"Unknown dimension")
    expect_error(etr_plot_fpca_component_envelope(
      x$envelope,component=2L),"component")
    bad<-x$sparse;bad$score_diagnostics$condition_number[]<-Inf
    expect_error(etr_plot_sparse_fpca_score_diagnostics(bad),
      "positive finite")
    bad<-x$family;bad$adjusted_p_values[2]<-1.5
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(bad),
      "adjusted_p_values")
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(
      x$family,max_targets=0L),"max_targets")
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(
      x$family,show_targetwise=1L),"show_targetwise")
  })
})
test_that("three new FPCA scientific graphic mappings retain unsigned gaps",{
  names<-c("plot_fpca_component_envelope",
    "plot_sparse_fpca_score_diagnostics",
    "plot_fpca_wild_bootstrap_family_test")
  p<-etr_native_parity_catalog()
  z<-p[p$is_python_function&p$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(z),3L)
  expect_identical(sort(z$native_r_candidate),sort(paste0("etr_",names)))
  expect_true(all(z$native_implementation_started))
  expect_true(all(z$source_contract_gap_unresolved))
  expect_false(any(z$one_to_one_native_contract_complete))
  expect_equal(sum(p$is_python_function&p$named_native_candidate),321L)
  expect_equal(sum(p$native_implementation_started),296L)
  expect_equal(sum(p$source_contract_gap_unresolved),143L)
})
test_that("FPCA plot geometries agree with pinned Python 1.2 Matplotlib data",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("source FPCA/PACE/family graphic oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _iv_obj(cls,**fields):
    v=object.__new__(cls)
    for k,x in fields.items(): object.__setattr__(v,k,x)
    return v
_iv_time=np.array([0.,.5,1.])
_iv_components=np.zeros((2,3,2),dtype=float)
_iv_components[0,:,0]=[1.,0.,-1.]
_iv_components[0,:,1]=[-1.,0.,1.]
_iv_components[1,:,0]=[.5,1.,.5]
_iv_components[1,:,1]=[.5,0.,-.5]
_iv_ref=_iv_obj(et.FPCAResult,time=_iv_time,
    dimension_names=('x','y'),time_unit='s',components=_iv_components)
_iv_env=_iv_obj(et.FPCAComponentEnvelopeResult,
    reference=_iv_ref,lower=_iv_components-.2,
    median=_iv_components,upper=_iv_components+.2,
    level=.95)
_iv_sparse=_iv_obj(et.SparseFPCAResult,
    score_diagnostics=pd.DataFrame({
      'n_samples':[3,4,5,6],
      'condition_number':[4.,2.,np.inf,8.],
      'status_code':['ok','failed','failed','ok']}))
_iv_proj=_iv_obj(et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('a','b','c'),
    bootstrap_projections=np.zeros((2,3)))
_iv_family=_iv_obj(et.FPCAWildBootstrapFamilyTestResult,
    projection_result=_iv_proj,
    adjusted_p_values=np.array([.2,.4,.6]),
    targetwise_p_values=np.array([.1,.3,.5]),
    significance_level=.05)
_iv_ax_e=et.plot_fpca_component_envelope(_iv_env)
_iv_ax_s=et.plot_sparse_fpca_score_diagnostics(_iv_sparse)
_iv_ax_f=et.plot_fpca_wild_bootstrap_family_test(
    _iv_family,max_targets=2,show_targetwise=True)
_iv_oracle={
    'component_median':_iv_ax_e.lines[0].get_ydata(),
    'component_reference':_iv_ax_e.lines[1].get_ydata(),
    'family_adjusted':_iv_ax_f.collections[0].get_offsets()[:,1],
    'family_targetwise':_iv_ax_f.collections[1].get_offsets()[:,1],
    'sparse_good':_iv_ax_s.collections[0].get_offsets()[:,1],
    'sparse_flagged':_iv_ax_s.collections[1].get_offsets()[:,1]
}
plt.close('all')
")
  x<-.etr_fpca_inference_visual_fixture()
  .etr_fpca_inference_visual_pdf({
    a<-etr_plot_fpca_component_envelope(x$envelope)
    b<-etr_plot_sparse_fpca_score_diagnostics(x$sparse)
    c<-etr_plot_fpca_wild_bootstrap_family_test(
      x$family,max_targets=2L)
    actual<-list(component_median=a$median,
      component_reference=a$reference,
      family_adjusted=c$adjusted_p_value,
      family_targetwise=c$targetwise_p_value,
      sparse_good=b$geometry$condition_number[b$geometry$ok],
      sparse_flagged=b$geometry$condition_number[b$geometry$flagged])
    for(n in names(actual)){
      expected<-reticulate::py_eval(
        paste0("_iv_oracle['",n,"']"),convert=TRUE)
      expect_equal(actual[[n]],expected,
        tolerance=1e-12,ignore_attr=TRUE,
        info=paste("FPCA 1.2 plotted data",n))
    }
  })
})
