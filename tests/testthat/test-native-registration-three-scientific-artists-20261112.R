# Frozen eyetrajectoriespy 1.2.0 src/eyetrajectoriespy/plotting.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Strict native R outputs source scientific artist arrays, NOT Python Axes.

.etr_reg_three_fixture <- function() {
  time<-as.numeric(0:6)
  values<-array(0,c(2L,length(time),1L))
  values[1L,,1L]<-sin(time/3)
  values[2L,,1L]<-cos(time/3)
  trajectories<-etr_trajectory_set(time,values,
    curve_ids=c("a","b"),dimension_names="x",
    coordinate_system="arbitrary",time_unit="s")
  etr_register_landmarks(trajectories,
    source_landmarks=matrix(c(2,4),nrow=2L,ncol=1L),
    target_landmarks=3)
}

.etr_reg_three_pdf <- function(code) {
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file,width=10,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(file)
  },add=TRUE)
  force(code)
}

test_that("three exact scientific artist records retain real fitted registration and original reconstruction data",{
  fit<-.etr_reg_three_fixture()
  expect_s3_class(fit,"etr_landmark_registration")
  reconstruction<-data.frame(
    n_components=c(3L,1L,2L),
    mean_integrated_rmse=c(.3,.9,.5))
  .etr_reg_three_pdf({
    a<-etr_plot_reconstruction_curve(reconstruction,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_registration_source_artist_record")
    expect_identical(a$source_export,"plot_reconstruction_curve")
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$axes[[1L]]$title,"FPCA reconstruction curve")
    expect_identical(a$axes[[1L]]$xlabel,
      "Retained functional principal components")
    expect_identical(a$axes[[1L]]$ylabel,"Mean integrated RMSE")
    expect_identical(a$axes[[1L]]$lines[[1L]]$marker,"o")
    expect_equal(a$axes[[1L]]$lines[[1L]]$xdata,c(3,1,2))
    expect_equal(a$axes[[1L]]$lines[[1L]]$ydata,c(.3,.9,.5))
    expect_identical(etr_plot_reconstruction_curve(reconstruction),
      reconstruction)
    b<-etr_plot_registration(fit,dimension="x",max_curves=2L,
      strict_source_record=TRUE)
    expect_s3_class(b,"etr_registration_source_artist_record")
    expect_identical(b$source_export,"plot_registration")
    expect_identical(b$panel_layout,c(1L,2L))
    expect_identical(b$python_return_kind,
      "tuple[matplotlib.figure.Figure,numpy.ndarray[matplotlib.axes.Axes]]")
    expect_length(b$axes,2L)
    expect_identical(vapply(b$axes,function(z)z$title,character(1L)),
      c("Original","Registered"))
    expect_identical(b$axes[[1L]]$xlabel,"Time (s)")
    expect_identical(b$axes[[2L]]$ylabel,"x")
    expect_equal(b$source_options$figure_size_inches,c(10,4))
    for(i in seq_len(2L)){
      expect_length(b$axes[[i]]$lines,2L)
      for(j in seq_len(2L)){
        line<-b$axes[[i]]$lines[[j]]
        x<-if(i==1L)fit$original else fit$registered
        expect_identical(line$alpha,.25)
        expect_identical(line$marker,"none")
        expect_equal(line$xdata,x$time,tolerance=0)
        expect_equal(line$ydata,
          as.numeric(x$values[j,,1L]),tolerance=1e-12)
      }
    }
    one<-etr_plot_registration(fit,max_curves=1L,
      strict_source_record=TRUE)
    expect_length(one$axes[[1L]]$lines,1L)
    expect_length(one$axes[[2L]]$lines,1L)
    expect_identical(one$source_options$curve_ids,"a")
    w<-etr_plot_warping_functions(fit,
      strict_source_record=TRUE)
    expect_identical(w$source_export,"plot_warping_functions")
    expect_identical(w$axes[[1L]]$xlabel,"Reference time (s)")
    expect_identical(w$axes[[1L]]$ylabel,"Warped source time")
    expect_true(w$axes[[1L]]$legend)
    expect_identical(w$axes[[1L]]$legend_labels,"identity")
    expect_length(w$axes[[1L]]$lines,3L)
    for(i in seq_len(2L)){
      line<-w$axes[[1L]]$lines[[i]]
      expect_equal(line$xdata,fit$original$time,tolerance=0)
      expect_equal(line$ydata,as.numeric(fit$warping_functions[i,]),
        tolerance=1e-12)
      expect_identical(line$alpha,.3)
    }
    expect_identical(w$axes[[1L]]$lines[[3L]]$label,"identity")
    expect_equal(w$axes[[1L]]$lines[[3L]]$ydata,
      fit$original$time,tolerance=0)
    d<-etr_plot_warping_functions(fit,displacement=TRUE,
      strict_source_record=TRUE)
    expect_false(d$axes[[1L]]$legend)
    expect_identical(d$axes[[1L]]$ylabel,"h(t) - t")
    expect_length(d$axes[[1L]]$lines,3L)
    expect_true(d$axes[[1L]]$lines[[3L]]$kind==
      "horizontal_reference")
    expect_equal(d$axes[[1L]]$lines[[3L]]$ydata,c(0,0))
    for(i in seq_len(2L))
      expect_equal(d$axes[[1L]]$lines[[i]]$ydata,
        as.numeric(fit$warping_functions[i,]-fit$original$time),
        tolerance=1e-12)
    expect_equal(etr_plot_warping_functions(fit,displacement=TRUE)$value,
      as.vector(t(sweep(fit$warping_functions,2L,fit$original$time,"-"))),
      tolerance=1e-12)
  })
})

test_that("strict registered scientific plots reject invalid data and unsupported Python axes protocol",{
  fit<-.etr_reg_three_fixture()
  tab<-data.frame(n_components=c(3L,1L,2L),
    mean_integrated_rmse=c(.3,.9,.5))
  .etr_reg_three_pdf({
    expect_error(etr_plot_reconstruction_curve(tab,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_registration(fit,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_warping_functions(fit,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_reconstruction_curve(
      tab[,1L,drop=FALSE],strict_source_record=TRUE),
      "must contain")
    expect_error(etr_plot_registration(fit,dimension="unknown",
      strict_source_record=TRUE),"dimension")
    expect_error(etr_plot_registration(fit,max_curves=0L,
      strict_source_record=TRUE),"max_curves")
    expect_error(etr_plot_warping_functions(fit,displacement=1L,
      strict_source_record=TRUE),"displacement")
    expect_error(etr_plot_warping_functions(unclass(fit),
      strict_source_record=TRUE),"registration")
  })
})

test_that("pinned Python 1.2 public reconstruction and landmark registration Matplotlib artist geometry matches native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 direct Matplotlib source geometry is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fit<-.etr_reg_three_fixture()
  summary<-data.frame(n_components=c(3L,1L,2L),
    mean_integrated_rmse=c(.3,.9,.5))
  .etr_reg_three_pdf({
    a<-etr_plot_reconstruction_curve(summary,
      strict_source_record=TRUE)
    b<-etr_plot_registration(fit,strict_source_record=TRUE,
      max_curves=2L)
    c<-etr_plot_warping_functions(fit,strict_source_record=TRUE)
    d<-etr_plot_warping_functions(fit,displacement=TRUE,
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
from types import SimpleNamespace
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _etr_reg_three_source_oracle(table, time, original,
     registered, warps):
    source=SimpleNamespace(
      time=np.asarray(time,dtype=float),
      time_unit='s',
      dimension_names=('x',),
      n_curves=2,
      values=np.asarray(original,dtype=float))
    registered=SimpleNamespace(
      time=np.asarray(time,dtype=float),
      values=np.asarray(registered,dtype=float))
    obj=SimpleNamespace(
      original=source,registered=registered,
      warping_functions=np.asarray(warps,dtype=float))
    a=et.plot_reconstruction_curve(pd.DataFrame(table))
    fig,panels=et.plot_registration(obj,
      dimension='x',max_curves=2)
    w=et.plot_warping_functions(obj,displacement=False)
    d=et.plot_warping_functions(obj,displacement=True)
    def extract(ax):
       return {'title':ax.get_title(),
         'xlabel':ax.get_xlabel(),'ylabel':ax.get_ylabel(),
         'lines':[{'x':np.asarray(z.get_xdata(),dtype=float),
           'y':np.asarray(z.get_ydata(),dtype=float),
           'alpha':z.get_alpha(),
           'label':z.get_label(),
           'linestyle':z.get_linestyle()}
           for z in ax.lines],
         'legend':ax.get_legend() is not None}
    data={'reconstruction':extract(a),
          'panels':[extract(ax) for ax in panels],
          'warps':extract(w),'displacement':extract(d),
          'registration_figure_size':np.asarray(fig.get_size_inches())}
    plt.close('all')
    return data
")
    py<-reticulate::py_call(
      reticulate::py_eval("_etr_reg_three_source_oracle",convert=FALSE),
      table=summary,time=fit$original$time,
      original=fit$original$values,
      registered=fit$registered$values,
      warps=fit$warping_functions)
    get<-function(name)et_to_r(reticulate::py_get_item(py,name))
    pairs<-list(list(ours=a$axes[[1L]],expected=get("reconstruction")),
      list(ours=b$axes[[1L]],expected=get("panels")[[1L]]),
      list(ours=b$axes[[2L]],expected=get("panels")[[2L]]),
      list(ours=c$axes[[1L]],expected=get("warps")),
      list(ours=d$axes[[1L]],expected=get("displacement")))
    expect_equal(b$source_options$figure_size_inches,
      get("registration_figure_size"),tolerance=0,ignore_attr=TRUE)
    for(p in pairs){
      for(key in c("title","xlabel","ylabel","legend"))
        expect_identical(p$ours[[key]],p$expected[[key]])
      expect_identical(length(p$ours$lines),
        length(p$expected$lines))
      for(i in seq_along(p$ours$lines)){
        ourline<-p$ours$lines[[i]]
        pyline<-p$expected$lines[[i]]
        if(!isTRUE(ourline$kind=="horizontal_reference")){
          expect_equal(ourline$xdata,pyline$x,
            tolerance=1e-12,ignore_attr=TRUE)
        }
        expect_equal(ourline$ydata,pyline$y,
          tolerance=1e-12,ignore_attr=TRUE)
        if(!is.null(ourline$alpha))
          expect_equal(ourline$alpha,pyline$alpha)
        if(!isTRUE(ourline$kind=="horizontal_reference"))
          expect_identical(ourline$label,pyline$label)
      }
    }
  })
})
