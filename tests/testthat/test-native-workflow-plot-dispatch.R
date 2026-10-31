# Exact plot selection for native R workflows. Published Python 1.2
# Matplotlib axes and rendering bytes are not claimed source-equivalent.

.etr_workflow_plot_fixture <- function(){
  time<-seq(0,1,length.out=21L)
  n<-8L
  values<-array(0,c(n,length(time),1L))
  for(i in seq_len(n))
    values[i,,1L]<-sin(2*pi*time)+i/10*cos(pi*time)+i/20
  etr_trajectory_set(time,values,
    sprintf("c%02d",seq_len(n)),"x",
    coordinate_system="normalized",time_unit="s")
}
.etr_workflow_plot_pdf <- function(expression){
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path)
  on.exit({grDevices::dev.off();unlink(path)},add=TRUE)
  force(expression)
}

test_that("workflow dispatch matches explicitly named FPCA component geometry",{
  x<-.etr_workflow_plot_fixture()
  fit<-etr_run_fpca_workflow(x,list(n_components=1L))
  frame<-.etr_workflow_plot_pdf(
    etr_plot_workflow_result(fit,plot="fpca_component",
      component=0L,sd_multiplier=2))
  expect_identical(nrow(frame),length(x$time))
  expected<-2*sqrt(fit$fit$explained_variance[1L])*
    as.numeric(fit$fit$components[1L,,1L])
  expect_equal(frame$upper-frame$mean,expected,tolerance=1e-12)
  expect_equal(frame$mean-frame$lower,expected,tolerance=1e-12)
  expect_error(etr_plot_workflow_result(fit,"fpca_component"),
    "component")
  expect_error(etr_plot_workflow_result(fit,"sparse_fpca_component"),
    "supported explicit")
  expect_error(etr_plot_workflow_result(fit,"fpca_component",
    component=5L),"component")
  expect_error(etr_plot_workflow_result(fit,"fpca_component",
    component=0L,ax=list()),"Matplotlib")
})

test_that("native workflow plotting dispatches declared FOS and recurrence",{
  x<-.etr_workflow_plot_fixture()
  design<-data.frame(curve_id=x$curve_ids,
    treatment=seq_len(length(x$curve_ids)))
  fos<-etr_run_function_on_scalar_workflow(x,design,
    config=list(predictors="treatment"))
  frame<-.etr_workflow_plot_pdf(
    etr_plot_workflow_result(fos,
      plot="function_on_scalar_coefficient",
      coefficient="treatment"))
  expect_equal(frame$estimate,
    as.numeric(fos$fit$coefficients[2L,,1L]),
    tolerance=1e-12)
  expect_error(etr_plot_workflow_result(fos,
    "function_on_scalar_coefficient"),"coefficient")
  rec<-etr_run_recurrence_workflow(x,
    config=list(curve=0L,dimensions="x",
      embedding_dimension=2L,delay=1L,radius=.5))
  plotted<-.etr_workflow_plot_pdf(
    etr_plot_workflow_result(rec,plot="recurrence"))
  expect_identical(plotted,rec$recurrence$matrix)
  expect_error(etr_plot_workflow_result(rec,
    plot="recurrence",max_points=2L),"max_points")
})

test_that("native figure writer emits explicit PDF and protects destinations",{
  x<-.etr_workflow_plot_fixture()
  fit<-etr_run_fpca_workflow(x,list(n_components=1L))
  directory<-tempfile()
  dest<-file.path(directory,"figures","fpca.pdf")
  on.exit(unlink(directory,recursive=TRUE),add=TRUE)
  result<-etr_save_workflow_figure(fit,dest,
    plot="fpca_component",component=0L)
  expect_true(file.exists(result))
  expect_true(file.info(result)$size>0)
  expect_error(etr_save_workflow_figure(fit,dest,
    plot="fpca_component",component=0L),"not overwritten")
  expect_error(etr_save_workflow_figure(fit,
    file.path(directory,"bad.txt"),plot="fpca_component",
    component=0L),"png")
  expect_error(etr_save_workflow_figure(fit,
    file.path(directory,"bad.pdf"),plot="fpca_component",
    component=0L,dpi=0),"dpi")
  expect_error(etr_save_workflow_figure(fit,
    file.path(directory,"bad.pdf"),plot="fpca_component",
    component=0L,close=FALSE),"closes")
})

test_that("frozen Python 1.2 workflow plot selection requires explicit type",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 W7 explicit plot dispatch oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.workflows._plotting import plot_workflow_result
try:
 plot_workflow_result(None,plot='missing')
 _native_workflow_unknown_plot_error=False
except ValueError:
 _native_workflow_unknown_plot_error=True
try:
 plot_workflow_result(None,plot='fpca_component',component=0)
 _native_workflow_wrong_type_error=False
except TypeError:
 _native_workflow_wrong_type_error=True
")
  expect_true(reticulate::py_to_r(reticulate::py_eval(
    "_native_workflow_unknown_plot_error",convert=FALSE)))
  expect_true(reticulate::py_to_r(reticulate::py_eval(
    "_native_workflow_wrong_type_error",convert=FALSE)))
})
