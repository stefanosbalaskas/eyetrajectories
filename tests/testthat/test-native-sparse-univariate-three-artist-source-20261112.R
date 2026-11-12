# Frozen Python 1.2 plotting.py scientific artists:
# plot_sparse_fpca_covariance, plot_sparse_fpca_component,
# plot_sparse_irregular_dimension. Source commit:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R returns actual scientific geometry, not Python Matplotlib Axes.

.etr_su_artist_pdf<-function(code){
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(file)
  },add=TRUE)
  force(code)
}

.etr_su_artist_small_irregular<-function(){
  etr_irregular_trajectory_set(
    time=list(c(0,.5,1),c(.1,.7)),
    values=list(matrix(c(1,2,3,4,5,6),nrow=3L,
      ncol=2L,byrow=TRUE),
      matrix(c(7,8,9,10),nrow=2L,ncol=2L,byrow=TRUE)),
    curve_ids=c("A","B"),
    dimension_names=c("signal","other"),
    coordinate_system="degrees",time_unit="s")
}

test_that("three source scientific sparse plots preserve genuine native PACE covariance and mode geometry",{
  fit<-.etr_spn_fit_from_fixture(.etr_spn_source_fixture())
  expect_s3_class(fit,"etr_sparse_fpca_native")
  expect_identical(fit$score_method,"PACE")
  .etr_su_artist_pdf({
    a<-etr_plot_sparse_fpca_covariance(fit,strict_source_record=TRUE)
    expect_s3_class(a,"etr_sparse_univariate_artist_source_record")
    expect_identical(a$source_export,"plot_sparse_fpca_covariance")
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$panel_layout,c(1L,1L))
    expect_length(a$axes,1L)
    expect_identical(a$axes[[1L]]$image,unname(fit$covariance))
    expect_identical(a$axes[[1L]]$extent,
      c(fit$evaluation_grid[[1L]],tail(fit$evaluation_grid,1L),
        fit$evaluation_grid[[1L]],tail(fit$evaluation_grid,1L)))
    expect_identical(a$axes[[1L]]$cmap,"viridis")
    expect_equal(c(a$axes[[1L]]$vmin,a$axes[[1L]]$vmax),
      range(fit$covariance),tolerance=0)
    expect_identical(a$colorbar$label,"Latent covariance")
    b<-etr_plot_sparse_fpca_component(fit,component=0L,
      sd_multiplier=2,strict_source_record=TRUE)
    expect_identical(b$source_export,"plot_sparse_fpca_component")
    expect_identical(b$source_options$component,0L)
    expect_equal(b$source_options$sd_multiplier,2)
    expect_identical(b$axes[[1L]]$title,
      "Sparse FPC1: signal(t)")
    expect_identical(b$axes[[1L]]$ylabel,"signal")
    expect_true(b$axes[[1L]]$legend)
    expect_identical(vapply(b$axes[[1L]]$lines,function(x)
      x$label,character(1L)),
      c("fitted mean","-2 SD","+2 SD"))
    delta<-2*sqrt(fit$eigenvalues[[1L]])*
      as.numeric(fit$eigenfunctions[1L,])
    expect_equal(b$axes[[1L]]$lines[[1L]]$ydata,fit$mean)
    expect_equal(b$axes[[1L]]$lines[[2L]]$ydata,
      fit$mean-delta,tolerance=1e-12)
    expect_equal(b$axes[[1L]]$lines[[3L]]$ydata,
      fit$mean+delta,tolerance=1e-12)
    expect_identical(b$axes[[1L]]$lines[[1L]]$xdata,
      fit$evaluation_grid)
  })
})

test_that("source scientific irregular plot preserves every native sample and Python artist property",{
  x<-.etr_su_artist_small_irregular()
  expect_s3_class(x,"etr_irregular_trajectory_set")
  .etr_su_artist_pdf({
    b<-etr_plot_sparse_irregular_dimension(x,"signal",
      strict_source_record=TRUE)
    expect_s3_class(b,"etr_sparse_univariate_artist_source_record")
    expect_identical(b$source_export,"plot_sparse_irregular_dimension")
    expect_identical(b$axes[[1L]]$title,
      "Native irregular observations: signal")
    expect_identical(b$axes[[1L]]$xlabel,"Time (s)")
    expect_identical(b$axes[[1L]]$ylabel,"signal")
    expect_true(b$axes[[1L]]$legend)
    expect_identical(b$source_options$n_curves,2L)
    expect_identical(vapply(b$axes[[1L]]$lines,
      function(a)a$label,character(1L)),c("A","B"))
    expect_identical(b$axes[[1L]]$lines[[1L]]$xdata,c(0,.5,1))
    expect_identical(b$axes[[1L]]$lines[[1L]]$ydata,c(1,3,5))
    expect_identical(b$axes[[1L]]$lines[[2L]]$xdata,c(.1,.7))
    expect_identical(b$axes[[1L]]$lines[[2L]]$ydata,c(7,9))
    expect_identical(b$axes[[1L]]$lines[[1L]]$marker,"o")
    expect_identical(b$axes[[1L]]$lines[[1L]]$linewidth,1)
    expect_identical(b$axes[[1L]]$lines[[1L]]$alpha,.55)
    original<-etr_plot_sparse_irregular_dimension(x,"signal")
    expect_identical(names(original),
      c("curve_ids","time","values","dimension"))
  })
  many<-.etr_spn_source_fixture()
  .etr_su_artist_pdf({
    a<-etr_plot_sparse_irregular_dimension(many,"signal",
      strict_source_record=TRUE)
    expect_length(a$axes[[1L]]$lines,24L)
    expect_false(a$axes[[1L]]$legend)
    expect_identical(a$source_options$n_curves,24L)
  })
})

test_that("native sparse source three artists refuse unsupported classes and invalid component geometry",{
  fit<-.etr_spn_fit_from_fixture(.etr_spn_source_fixture())
  x<-.etr_su_artist_small_irregular()
  .etr_su_artist_pdf({
    expect_error(etr_plot_sparse_fpca_covariance(unclass(fit),
      strict_source_record=TRUE),"genuine native covariance/PACE")
    expect_error(etr_plot_sparse_fpca_component(fit,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_sparse_fpca_component(fit,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_sparse_fpca_component(fit,
      component=fit$n_components,strict_source_record=TRUE),
      "component")
    expect_error(etr_plot_sparse_fpca_component(fit,
      sd_multiplier=0,strict_source_record=TRUE),
      "sd_multiplier")
    bad<-fit;bad$covariance[1L,1L]<-NA_real_
    expect_error(etr_plot_sparse_fpca_covariance(bad,
      strict_source_record=TRUE),"covariance")
    expect_error(etr_plot_sparse_irregular_dimension(unclass(x),
      "signal",strict_source_record=TRUE),
      "native irregular trajectories")
    expect_error(etr_plot_sparse_irregular_dimension(x,
      "not_a_dimension",strict_source_record=TRUE),
      "Unknown dimension")
    expect_error(etr_plot_sparse_irregular_dimension(x,
      "signal",strict_source_record=1L),"strict_source_record")
  })
})

test_that("frozen Python 1.2 Matplotlib imshow and line artists equal real native R scientific geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 sparse univariate Matplotlib oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fit<-.etr_spn_fit_from_fixture(.etr_spn_source_fixture())
  ir<-.etr_su_artist_small_irregular()
  .etr_su_artist_pdf({
    rc<-etr_plot_sparse_fpca_covariance(fit,strict_source_record=TRUE)
    rp<-etr_plot_sparse_fpca_component(fit,strict_source_record=TRUE)
    ri<-etr_plot_sparse_irregular_dimension(ir,"signal",
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _etr_su_compare_artist(grid,mean,cov,eigenfunctions,eigenvalues,
                           times,values,ids):
    sparse=object.__new__(et.SparseFPCAResult)
    fields={
      'evaluation_grid':np.asarray(grid,dtype=float),
      'mean':np.asarray(mean,dtype=float),
      'covariance':np.asarray(cov,dtype=float),
      'eigenfunctions':np.asarray(eigenfunctions,dtype=float),
      'eigenvalues':np.asarray(eigenvalues,dtype=float),
      'n_components':int(len(eigenvalues)),
      'dimension':'signal','time_unit':'s'
    }
    for name,value in fields.items():
       object.__setattr__(sparse,name,value)
    irregular=object.__new__(et.IrregularTrajectorySet)
    irregular_fields={
      'curve_ids':tuple(ids),
      'time':tuple(np.asarray(t,dtype=float) for t in times),
      'values':tuple(np.asarray(v,dtype=float) for v in values),
      'dimension_names':('signal','other'),
      'time_unit':'s'
    }
    for name,value in irregular_fields.items():
       object.__setattr__(irregular,name,value)
    c=et.plot_sparse_fpca_covariance(sparse)
    p=et.plot_sparse_fpca_component(sparse)
    i=et.plot_sparse_irregular_dimension(irregular,dimension='signal')
    expected={
      'covariance':{
        'matrix':np.asarray(c.images[0].get_array().data),
        'clim':tuple(c.images[0].get_clim()),
        'extent':tuple(c.images[0].get_extent()),
        'title':c.get_title(),'xlabel':c.get_xlabel(),
        'ylabel':c.get_ylabel(),'cmap':c.images[0].get_cmap().name,
        'figure_axes':len(c.figure.axes)
      },
      'component':{
        'title':p.get_title(),'xlabel':p.get_xlabel(),
        'ylabel':p.get_ylabel(),
        'lines':[{
          'label':ln.get_label(),
          'xdata':np.asarray(ln.get_xdata()),
          'ydata':np.asarray(ln.get_ydata())
        } for ln in p.lines]
      },
      'irregular':{
        'title':i.get_title(),'xlabel':i.get_xlabel(),
        'ylabel':i.get_ylabel(),
        'lines':[{
          'label':ln.get_label(),
          'xdata':np.asarray(ln.get_xdata()),
          'ydata':np.asarray(ln.get_ydata()),
          'alpha':ln.get_alpha(),
          'linewidth':ln.get_linewidth(),
          'marker':ln.get_marker()
        } for ln in i.lines],
        'legend':i.get_legend() is not None
      }
    }
    plt.close('all')
    return expected
")
    source<-reticulate::py_call(
      reticulate::py_eval("_etr_su_compare_artist",convert=FALSE),
      grid=fit$evaluation_grid,mean=fit$mean,cov=fit$covariance,
      eigenfunctions=fit$eigenfunctions,eigenvalues=fit$eigenvalues,
      times=ir$time,values=ir$values,ids=as.list(ir$curve_ids))
    get<-function(x)et_to_r(reticulate::py_get_item(source,x))
    pycov<-get("covariance")
    expect_equal(rc$axes[[1L]]$image,pycov$matrix,
      tolerance=1e-10,ignore_attr=TRUE)
    expect_equal(c(rc$axes[[1L]]$vmin,rc$axes[[1L]]$vmax),
      pycov$clim,tolerance=1e-10,ignore_attr=TRUE)
    expect_equal(rc$axes[[1L]]$extent,pycov$extent,tolerance=0,
      ignore_attr=TRUE)
    expect_identical(rc$axes[[1L]]$title,pycov$title)
    expect_identical(rc$axes[[1L]]$cmap,pycov$cmap)
    expect_identical(as.integer(pycov$figure_axes),2L)
    component<-get("component")
    for(key in c("title","xlabel","ylabel"))
      expect_identical(rp$axes[[1L]][[key]],component[[key]])
    for(j in seq_along(component$lines)){
      expect_identical(rp$axes[[1L]]$lines[[j]]$label,
        component$lines[[j]]$label)
      expect_equal(rp$axes[[1L]]$lines[[j]]$xdata,
        component$lines[[j]]$xdata,tolerance=0,ignore_attr=TRUE)
      expect_equal(rp$axes[[1L]]$lines[[j]]$ydata,
        component$lines[[j]]$ydata,tolerance=1e-10,ignore_attr=TRUE)
    }
    irregular<-get("irregular")
    for(key in c("title","xlabel","ylabel","legend"))
      expect_identical(ri$axes[[1L]][[key]],irregular[[key]])
    for(j in seq_along(irregular$lines)){
      for(key in c("label","marker","linewidth","alpha"))
        expect_equal(ri$axes[[1L]]$lines[[j]][[key]],
          irregular$lines[[j]][[key]])
      for(key in c("xdata","ydata"))
        expect_equal(ri$axes[[1L]]$lines[[j]][[key]],
          irregular$lines[[j]][[key]],
          tolerance=1e-12,ignore_attr=TRUE)
    }
  })
})
