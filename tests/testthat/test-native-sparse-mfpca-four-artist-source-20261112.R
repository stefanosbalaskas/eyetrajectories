# Source scientific Matplotlib artist geometry against frozen Python
# eyetrajectoriespy==1.2.0 at c1cd95ad718327550f7e55393ff38582872f7a94.
# These are four native R source-geometry records, not Python axes objects.
# The genuine native joint covariance/PACE fit is reused, not approximated
# by a marginal fdapace alternative.

.etr_sm_artist_pdf<-function(code){
  p<-tempfile(fileext=".pdf")
  grDevices::pdf(p,width=9,height=7)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(p)
  },add=TRUE)
  force(code)
}

.etr_sm_artist_fit<-function(){
  args<-c(list(trajectories=.etr_spnm_fixture(),
    backend="native_covariance",strict_source_record=TRUE),
    .etr_spnm_args())
  fit<-do.call(etr_fit_sparse_mfpca,args)
  expect_s3_class(fit,"etr_sparse_mfpca_w2_scientific_record")
  expect_identical(fit$fit_method,"direct_sparse_block_covariance")
  expect_identical(fit$score_method,"joint_PACE")
  fit
}

test_that("four paired sparse native source plots return inspectable scientific artist geometry",{
  fit<-.etr_sm_artist_fit()
  .etr_sm_artist_pdf({
    a<-etr_plot_sparse_mfpca_component(fit,component=0L,
      sd_multiplier=2,strict_source_record=TRUE)
    expect_s3_class(a,"etr_sparse_mfpca_artist_source_record")
    expect_identical(a$source_export,"plot_sparse_mfpca_component")
    expect_identical(a$panel_layout,c(1L,2L))
    expect_length(a$axes,2L)
    expect_identical(a$python_return_kind,
      "numpy.ndarray[matplotlib.axes.Axes]")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    for(d in seq_len(2L)){
      expect_identical(a$axes[[d]]$xdata,fit$evaluation_grid)
      expect_identical(a$axes[[d]]$ylabel,fit$dimensions[[d]])
      expect_identical(a$axes[[d]]$lines[[1L]]$ydata,
        fit$mean[,d])
      expected<-2*sqrt(fit$eigenvalues[[1L]])*
        fit$eigenfunctions[1L,,d]
      expect_equal(a$axes[[d]]$lines[[2L]]$ydata,
        fit$mean[,d]+expected,tolerance=1e-12)
      expect_equal(a$axes[[d]]$lines[[3L]]$ydata,
        fit$mean[,d]-expected,tolerance=1e-12)
      expect_identical(vapply(a$axes[[d]]$lines,
        function(x)x$label,character(1L)),
        c("mean","mean + 2 SD mode","mean - 2 SD mode"))
    }
    b<-etr_plot_sparse_mfpca_covariance_blocks(fit,stage="used",
      strict_source_record=TRUE)
    expect_identical(b$panel_layout,c(2L,2L))
    expect_identical(b$source_options$stage,"used")
    expect_identical(b$colorbar$label,"covariance")
    expect_identical(b$axes[[1L]]$image,unname(fit$covariance_cxx))
    expect_identical(b$axes[[2L]]$image,unname(fit$covariance_cxy))
    expect_identical(b$axes[[3L]]$image,unname(fit$covariance_cyx))
    expect_identical(b$axes[[4L]]$image,unname(fit$covariance_cyy))
    limit<-max(abs(c(fit$covariance_cxx,fit$covariance_cxy,
      fit$covariance_cyx,fit$covariance_cyy)))
    expect_equal(vapply(b$axes,function(x)x$vmin,numeric(1L)),
      rep(-limit,4L))
    expect_equal(vapply(b$axes,function(x)x$vmax,numeric(1L)),
      rep(limit,4L))
    expect_identical(b$axes[[2L]]$extent,
      c(fit$evaluation_grid[[1L]],
        tail(fit$evaluation_grid,1L),
        fit$evaluation_grid[[1L]],
        tail(fit$evaluation_grid,1L)))
    c<-etr_plot_sparse_mfpca_cross_covariance(fit,
      stage="smoothed",strict_source_record=TRUE)
    expect_identical(c$panel_layout,c(1L,2L))
    expect_identical(c$colorbar$label,"cross-covariance")
    expect_identical(c$axes[[1L]]$image,unname(fit$smoothed_cxy))
    expect_identical(c$axes[[2L]]$image,unname(fit$smoothed_cyx))
    expect_equal(c$axes[[2L]]$image,t(c$axes[[1L]]$image),
      tolerance=1e-10)
    expect_identical(c$axes[[1L]]$cmap,"coolwarm")
    d<-etr_plot_sparse_mfpca_score_diagnostics(fit,
      strict_source_record=TRUE)
    expect_identical(d$source_export,
      "plot_sparse_mfpca_score_diagnostics")
    expect_identical(d$panel_layout,c(1L,1L))
    expect_identical(d$python_return_kind,"matplotlib.axes.Axes")
    expect_true(d$axes[[1L]]$legend)
    expect_identical(d$axes[[1L]]$xlabel,
      "paired native observations")
    expect_identical(d$axes[[1L]]$ylabel,
      "conditional-system condition number")
    eligible<-is.finite(fit$score_diagnostics$n_time_points)&
      is.finite(fit$score_diagnostics$condition_number)&
      fit$score_diagnostics$status_code=="ok"
    expect_equal(d$axes[[1L]]$collections[[1L]]$offsets,
      cbind(as.numeric(fit$score_diagnostics$n_time_points[eligible]),
        as.numeric(fit$score_diagnostics$condition_number[eligible])),
      tolerance=0,ignore_attr=TRUE)
  })
})

test_that("nonfinite or empty joint PACE diagnostics render exact source placeholder geometry",{
  fit<-.etr_sm_artist_fit()
  fit$score_diagnostics<-data.frame(
    n_time_points=c(4,6),condition_number=c(Inf,NaN),
    status_code=c("failed","failed"),stringsAsFactors=FALSE)
  .etr_sm_artist_pdf({
    a<-etr_plot_sparse_mfpca_score_diagnostics(fit,
      strict_source_record=TRUE)
    expect_identical(a$axes[[1L]]$n_rows,2L)
    expect_identical(a$axes[[1L]]$n_nonfinite,2L)
    expect_length(a$axes[[1L]]$collections,1L)
    expect_identical(a$axes[[1L]]$collections[[1L]]$label,
      "non-finite / failed")
    expect_identical(dim(a$axes[[1L]]$collections[[1L]]$offsets),
      c(0L,2L))
    old<-etr_plot_sparse_mfpca_score_diagnostics(fit)
    expect_identical(old$nonfinite_count,2L)
    expect_equal(nrow(old$finite),0L)
    fit$score_diagnostics<-fit$score_diagnostics[FALSE,,drop=FALSE]
    empty<-etr_plot_sparse_mfpca_score_diagnostics(fit,
      strict_source_record=TRUE)
    expect_false(empty$axes[[1L]]$legend)
    expect_length(empty$axes[[1L]]$collections,0L)
  })
})

test_that("strict source stage, class, and component controls fail closed",{
  fit<-.etr_sm_artist_fit()
  .etr_sm_artist_pdf({
    expect_error(etr_plot_sparse_mfpca_covariance_blocks(
      fit,source="used",stage="smoothed",
      strict_source_record=TRUE),"source and stage")
    expect_error(etr_plot_sparse_mfpca_cross_covariance(
      fit,stage="unknown",strict_source_record=TRUE),
      "source must be")
    expect_error(etr_plot_sparse_mfpca_component(fit,
      component=2L,strict_source_record=TRUE),"component")
    expect_error(etr_plot_sparse_mfpca_component(fit,
      sd_multiplier=-.01,strict_source_record=TRUE),"sd_multiplier")
    expect_error(etr_plot_sparse_mfpca_component(fit,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_sparse_mfpca_component(fit,
      strict_source_record=1L),"strict_source_record")
    naked<-unclass(fit)
    expect_error(etr_plot_sparse_mfpca_component(naked,
      strict_source_record=TRUE),"native fitted sparse MFPCA")
    corrupted<-fit
    corrupted$smoothed_cxy<-matrix(NA_real_,
      nrow=length(fit$evaluation_grid),
      ncol=length(fit$evaluation_grid))
    expect_error(etr_plot_sparse_mfpca_cross_covariance(
      corrupted,stage="smoothed",strict_source_record=TRUE),
      "smoothed_cxy")
  })
})

test_that("frozen Python 1.2 Matplotlib line, imshow and scatter artists match native source geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 matplotlib artist geometry oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fit<-.etr_sm_artist_fit()
  .etr_sm_artist_pdf({
    rc<-etr_plot_sparse_mfpca_component(fit,strict_source_record=TRUE)
    rb<-etr_plot_sparse_mfpca_covariance_blocks(fit,stage="used",
      strict_source_record=TRUE)
    rx<-etr_plot_sparse_mfpca_cross_covariance(fit,stage="smoothed",
      strict_source_record=TRUE)
    rs<-etr_plot_sparse_mfpca_score_diagnostics(fit,
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _etr_sm_artist_oracle(grid,mean,modes,lambdas,dimensions,
                         used,smoothed,diagnostics):
    obj=object.__new__(et.SparseMFPCAResult)
    mapping={
      'evaluation_grid':np.asarray(grid,dtype=float),
      'mean':np.asarray(mean,dtype=float),
      'eigenfunctions':np.asarray(modes,dtype=float),
      'eigenvalues':np.asarray(lambdas,dtype=float),
      'n_components':int(len(lambdas)),
      'dimensions':tuple(str(x) for x in dimensions),
      'time_unit':'s',
      'score_diagnostics':pd.DataFrame(diagnostics),
    }
    for prefix,blocks in [('covariance',used),('smoothed',smoothed)]:
      for suffix in ('cxx','cxy','cyx','cyy'):
        mapping[prefix+'_'+suffix]=np.asarray(blocks[suffix],dtype=float)
    for key,value in mapping.items():
      object.__setattr__(obj,key,value)
    c=et.plot_sparse_mfpca_component(obj,component=0,sd_multiplier=2)
    b=et.plot_sparse_mfpca_covariance_blocks(obj,stage='used')
    x=et.plot_sparse_mfpca_cross_covariance(obj,stage='smoothed')
    d=et.plot_sparse_mfpca_score_diagnostics(obj)
    line_data=[{
      'title':ax.get_title(),
      'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'lines':[{'label':ln.get_label(),'x':ln.get_xdata(),
          'y':ln.get_ydata()} for ln in ax.lines]
      } for ax in c]
    map_data=[{
      'title':ax.get_title(),
      'matrix':np.asarray(ax.images[0].get_array()),
      'clim':np.asarray(ax.images[0].get_clim(),dtype=float),
      'extent':np.asarray(ax.images[0].get_extent(),dtype=float),
      'xlabel':ax.get_xlabel(),'ylabel':ax.get_ylabel()
      } for ax in b.flat]
    cross_data=[{
      'title':ax.get_title(),
      'matrix':np.asarray(ax.images[0].get_array()),
      'clim':np.asarray(ax.images[0].get_clim(),dtype=float)
      } for ax in x]
    scatter=[{'label':col.get_label(),
         'offsets':np.asarray(col.get_offsets().data)}
         for col in d.collections]
    expected={'component':line_data,'blocks':map_data,
      'cross':cross_data,'score':scatter,
      'score_title':d.get_title(),
      'component_class':type(c[0]).__name__,
      'figure_axes':len(b.flat[0].figure.axes)}
    plt.close('all')
    return expected
")
    used<-setNames(lapply(c("cxx","cxy","cyx","cyy"),function(k)
      fit[[paste0("covariance_",k)]]),c("cxx","cxy","cyx","cyy"))
    smooth<-setNames(lapply(c("cxx","cxy","cyx","cyy"),function(k)
      fit[[paste0("smoothed_",k)]]),c("cxx","cxy","cyx","cyy"))
    source<-reticulate::py_call(
      reticulate::py_eval("_etr_sm_artist_oracle",convert=FALSE),
      grid=fit$evaluation_grid,mean=fit$mean,
      modes=fit$eigenfunctions,lambdas=fit$eigenvalues,
      dimensions=as.list(fit$dimensions),
      used=used,smoothed=smooth,
      diagnostics=fit$score_diagnostics)
    get<-function(name)et_to_r(reticulate::py_get_item(source,name))
    pc<-get("component")
    expect_identical(get("component_class"),"Axes")
    for(d in 1:2){
      expect_identical(rc$axes[[d]]$title,pc[[d]]$title)
      expect_identical(rc$axes[[d]]$xlabel,pc[[d]]$xlabel)
      expect_identical(rc$axes[[d]]$ylabel,pc[[d]]$ylabel)
      for(j in 1:3){
        expect_equal(rc$axes[[d]]$lines[[j]]$ydata,
          pc[[d]]$lines[[j]]$y,
          tolerance=1e-9,ignore_attr=TRUE)
        expect_identical(rc$axes[[d]]$lines[[j]]$label,
          pc[[d]]$lines[[j]]$label)
      }
    }
    pb<-get("blocks")
    expect_identical(as.integer(get("figure_axes")),5L)
    for(j in 1:4){
      expect_equal(rb$axes[[j]]$image,
        pb[[j]]$matrix,tolerance=1e-9,ignore_attr=TRUE)
      expect_equal(c(rb$axes[[j]]$vmin,rb$axes[[j]]$vmax),
        pb[[j]]$clim,tolerance=1e-9,ignore_attr=TRUE)
      expect_equal(rb$axes[[j]]$extent,pb[[j]]$extent,
        tolerance=0,ignore_attr=TRUE)
      expect_identical(rb$axes[[j]]$title,pb[[j]]$title)
    }
    px<-get("cross")
    for(j in 1:2){
      expect_equal(rx$axes[[j]]$image,
        px[[j]]$matrix,tolerance=1e-9,ignore_attr=TRUE)
      expect_equal(c(rx$axes[[j]]$vmin,rx$axes[[j]]$vmax),
        px[[j]]$clim,tolerance=1e-9,ignore_attr=TRUE)
      expect_identical(rx$axes[[j]]$title,px[[j]]$title)
    }
    ps<-get("score")
    expect_identical(rs$axes[[1L]]$title,get("score_title"))
    expect_identical(length(rs$axes[[1L]]$collections),length(ps))
    for(j in seq_along(ps)){
      expect_identical(rs$axes[[1L]]$collections[[j]]$label,
        ps[[j]]$label)
      expect_equal(rs$axes[[1L]]$collections[[j]]$offsets,
        ps[[j]]$offsets,tolerance=1e-9,ignore_attr=TRUE)
    }
  })
})
