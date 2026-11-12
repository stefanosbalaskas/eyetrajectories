# Frozen Python eyetrajectoriespy==1.2.0 workflows/_plotting.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native source geometry is NOT Matplotlib Axes object identity or pixel parity.

.etr_w4_source_fixture<-function(){
  time<-seq(0,1,length.out=11L)
  n<-10L
  a<-array(0,c(n,length(time),1L))
  for(i in seq_len(n))
    a[i,,1L]<-sin(2*pi*time)+i*.12+.06*i*time
  ids<-paste0("c",seq_len(n))
  curves<-etr_trajectory_set(time,a,ids,"x",
    coordinate_system="normalized",time_unit="s")
  list(
    fpca=etr_run_fpca_workflow(curves,list(n_components=1L)),
    fos=etr_run_function_on_scalar_workflow(curves,
      data.frame(curve_id=ids,dose=seq_len(n)),
      list(predictors="dose")),
    recurrence=etr_run_recurrence_workflow(curves,
      list(curve=0L,dimensions="x",embedding_dimension=2L,
        delay=1L,radius=.5)))
}
.etr_w4_source_pdf<-function(expr){
  p<-tempfile(fileext=".pdf")
  grDevices::pdf(p)
  on.exit({grDevices::dev.off();unlink(p)},add=TRUE)
  force(expr)
}

test_that("strict W4 dispatch preserves legacy defaults but exposes scientific geometry",{
  z<-.etr_w4_source_fixture()
  .etr_w4_source_pdf({
    old<-etr_plot_workflow_result(z$fpca,plot="fpca_component",component=0L)
    expect_s3_class(old,"data.frame")
    got<-etr_plot_workflow_result(z$fpca,plot="fpca_component",
      component=0L,strict_source_record=TRUE)
    expect_s3_class(got,"etr_workflow_scientific_plot_record")
    expect_identical(got$canonical_plot,"fpca_component")
    expect_equal(got$artist$lines[[1L]]$y,old$mean,tolerance=1e-12)
    expect_false(got$matplotlib_object_identity)
    expect_false(got$independently_certified)
    fos<-etr_plot_workflow_result(z$fos,
      plot="function_on_scalar_coefficient",coefficient="dose",
      strict_source_record=TRUE)
    expect_identical(fos$artist$source_export,
      "plot_function_on_scalar_coefficients")
    rec<-etr_plot_workflow_result(z$recurrence,plot="recurrence",
      strict_source_record=TRUE)
    expect_identical(rec$artist$matrix,z$recurrence$recurrence$matrix)
    expect_error(etr_plot_workflow_result(z$fpca,plot="missing",
      strict_source_record=TRUE),"seven declared")
    expect_error(etr_plot_workflow_result(z$fpca,plot="fpca_component",
      strict_source_record=TRUE),"component must be supplied")
    expect_error(etr_plot_workflow_result(z$fpca,plot="fpca_component",
      component=0,strict_source_record=TRUE),"integer")
    expect_error(etr_plot_workflow_result(z$fpca,plot="fpca_component",
      component=0L,ax=list(),strict_source_record=TRUE),"Matplotlib")
    expect_error(etr_plot_workflow_result(z$fpca,
      plot="generalized_functional_coefficient",
      coefficient="dose",strict_source_record=TRUE),
      "GeneralizedFunctionalWorkflowResult")
  })
})

test_that("strict W4 dispatch resolves sparse, generalized, and mixed plotters",{
  grid<-c(0,.5,1)
  uni<-structure(list(
    evaluation_grid=grid,mean=c(1,2,3),
    covariance=diag(3L),
    eigenfunctions=matrix(c(1,0,-1,.5,0,-.5),2L,3L,byrow=TRUE),
    eigenvalues=c(4,1),n_components=2L,dimension="x",
    time_unit="s",fit_method="native_covariance",score_method="PACE"),
    class="etr_sparse_fpca_native")
  multi<-structure(list(
    evaluation_grid=grid,mean=cbind(x=c(1,2,3),y=c(3,2,1)),
    eigenfunctions=array(0,dim=c(2L,3L,2L)),
    eigenvalues=c(4,1),n_components=2L,
    dimensions=c("x","y"),time_unit="s"),
    class="etr_sparse_mfpca_source")
  multi$eigenfunctions[1L,,1L]<-c(1,0,-1)
  multi$eigenfunctions[1L,,2L]<-c(-1,0,1)
  general<-list(time=grid,time_unit="s",family="poisson",
    link="log",coefficient_names=c("Intercept","dose"),
    coefficient_functions=matrix(c(1,2,3,-1,0,1),2L,3L,byrow=TRUE))
  mixed<-list(time=grid,time_unit="s",dimension_name="x",
    coefficient_names=c("Intercept","dose"),
    coefficient_functions=general$coefficient_functions,
    coefficient_standard_errors=matrix(.05,2L,3L))
  .etr_w4_source_pdf({
    a<-etr_plot_workflow_result(
      structure(list(fit=uni),class="etr_sparse_fpca_workflow"),
      plot="sparse_fpca_component",component=0L,
      strict_source_record=TRUE)
    expect_identical(a$artist$source_export,"plot_sparse_fpca_component")
    b<-etr_plot_workflow_result(
      structure(list(fit=multi),class="etr_native_sparse_mfpca_workflow"),
      plot="sparse_mfpca_component",component=0L,
      strict_source_record=TRUE)
    expect_identical(b$artist$source_export,"plot_sparse_mfpca_component")
    expect_identical(b$python_return_kind,
      "numpy.ndarray[matplotlib.axes.Axes]")
    g<-etr_plot_workflow_result(
      structure(list(fit=general),class="etr_generalized_functional_workflow"),
      plot="generalized_functional_coefficient",
      coefficient="dose",strict_source_record=TRUE)
    expect_equal(g$artist$axes[[1L]]$artists[[1L]]$ydata,c(-1,0,1))
    m<-etr_plot_workflow_result(
      structure(list(fit=mixed),class="etr_functional_mixed_effects_workflow"),
      plot="functional_mixed_effects_coefficient",
      coefficient="dose",strict_source_record=TRUE)
    expect_identical(m$artist$source_options$interval_type,
      "pointwise_95_Wald_not_simultaneous")
    expect_error(etr_plot_workflow_result(
      structure(list(fit=general),class="etr_generalized_functional_workflow"),
      plot="generalized_functional_coefficient",
      coefficient=1L,strict_source_record=TRUE),
      "explicit coefficient name")
  })
})

test_that("strict W4 file export writes and overwrites real native figures",{
  z<-.etr_w4_source_fixture()
  root<-tempfile()
  dest<-file.path(root,"figures","analysis.pdf")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  first<-etr_save_workflow_figure(z$fpca,dest,plot="fpca_component",
    component=0L,dpi=150L,strict_source_record=TRUE)
  expect_true(file.exists(first))
  expect_gt(file.info(first)$size,0)
  second<-etr_save_workflow_figure(z$fos,dest,
    plot="function_on_scalar_coefficient",coefficient="dose",
    strict_source_record=TRUE)
  expect_identical(first,second)
  expect_gt(file.info(second)$size,0)
  expect_error(etr_save_workflow_figure(z$fpca,
    file.path(root,"fail.pdf"),plot="fpca_component",
    component=0L,close=FALSE,strict_source_record=TRUE),
    "close=FALSE")
  expect_error(etr_save_workflow_figure(z$fpca,
    file.path(root,"fail.jpeg"),plot="fpca_component",
    component=0L,strict_source_record=TRUE),"png")
  expect_error(etr_save_workflow_figure(z$fpca,
    file.path(root,"fail.pdf"),plot="fpca_component",
    component=0L,dpi=0L,strict_source_record=TRUE),"dpi")
})

test_that("frozen Python W4 names and signatures remain pinned public source",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 source symbol verification is opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import inspect
from eyetrajectoriespy.workflows import plot_workflow_result, save_workflow_figure
_expected = ('fpca_component','sparse_fpca_component','sparse_mfpca_component',
'function_on_scalar_coefficient','functional_mixed_effects_coefficient',
'generalized_functional_coefficient','recurrence')
from eyetrajectoriespy.workflows._plotting import SUPPORTED_WORKFLOW_PLOTS
assert tuple(SUPPORTED_WORKFLOW_PLOTS)==_expected
assert 'max_points' in inspect.signature(plot_workflow_result).parameters
assert 'close' in inspect.signature(save_workflow_figure).parameters
")
  expect_true(reticulate::py_to_r(reticulate::py_eval(
    "tuple(SUPPORTED_WORKFLOW_PLOTS)==_expected")))
})
