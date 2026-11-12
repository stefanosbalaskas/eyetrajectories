# Eight native scientific nonlinear plotting artists.
# Frozen eyetrajectoriespy==1.2.0 nonlinear_plotting.py:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer source-scientific coordinates, not Python Axes identity.

.etr_eight_nonlinear_fixture <- function() {
  delay<-structure(list(
    table=data.frame(lag_time=c(.1,.2,.3,.4),
      average_mutual_information=c(.6,.2,.27,.3),
      autocorrelation=c(.9,.5,.2,-.1),
      first_ami_local_minimum=c(FALSE,TRUE,FALSE,FALSE)),
    curve_id="test",dimension="x",time_unit="s"),
    class="etr_embedding_delay_diagnostics")
  fnn<-structure(list(table=data.frame(
      embedding_dimension=c(2L,3L,4L),
      false_neighbor_fraction=c(.5,.25,.1)),
    curve_id="test",dimension="y"),
    class="etr_embedding_dimension_diagnostics")
  network<-structure(list(degree=c(1,2,1),
    normalized_degree=c(.5,1,.5),graph_density=2/3),
    class="etr_recurrence_network")
  radius<-structure(list(table=data.frame(
      radius=c(.1,.2,.3),recurrence_rate=c(.1,.4,.8)),
    metric="euclidean",curve_id="test"),
    class="etr_recurrence_radius_profile")
  window<-structure(list(table=data.frame(
      center_time=c(1,2,3,4),
      recurrence_rate=c(.2,.3,.4,.6),
      determinism=c(.5,.6,.6,.7),
      laminarity=c(.2,.3,.5,.7)),
    time_unit="s"),class="etr_windowed_rqa")
  divergence<-structure(list(time_lags=c(0,1,2,3,4),
    mean_log_divergence=c(-2,-1.5,-1,-.5,0),
    time_unit="ms",curve_id="test",
    provenance=list(estimator_family="Rosenstein")),
    class="etr_local_divergence")
  lyapunov<-structure(list(divergence=divergence,
    fit_start=1,fit_end=3,intercept=-1.5,
    exponent=500,exponent_unit="1/s"),
    class="etr_largest_lyapunov")
  surrogate<-structure(list(surrogate_statistics=c(1.1,1.3,1.8,2,2.2),
    observed_statistic=1.9,p_value=.3,
    statistic="largest_lyapunov",method="iaaft"),
    class="etr_surrogate_nonlinearity")
  crossing<-structure(list(states=matrix(c(1,1.4,1.8,1.5),ncol=1L),
    state_dimensions="x"),class="etr_poincare_crossings")
  fit<-structure(list(reference_state=1.5,intercept=.2,
    jacobian=matrix(.4,nrow=1L,ncol=1L)),
    class="etr_local_return_map")
  list(delay=delay,fnn=fnn,network=network,radius=radius,
    window=window,divergence=divergence,lyapunov=lyapunov,
    surrogate=surrogate,crossing=crossing,fit=fit)
}

.etr_eight_nonlinear_pdf <- function(expr) {
  f<-tempfile(fileext=".pdf")
  grDevices::pdf(f,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(f)
  },add=TRUE)
  force(expr)
}

test_that("strict embedding delay preserves two Matplotlib y axes and AMI marker",{
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    a<-etr_plot_embedding_delay_diagnostics(z$delay,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_nonlinear_scientific_artist_record")
    expect_identical(a$source_export,"plot_embedding_delay_diagnostics")
    expect_false(a$independently_certified)
    expect_false(a$matplotlib_object_identity)
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    expect_length(a$axes,2L)
    expect_identical(a$axes[[1L]]$ylabel,"Average mutual information")
    expect_identical(a$axes[[2L]]$ylabel,"Autocorrelation")
    expect_identical(a$axes[[2L]]$twinx_of,1L)
    expect_identical(a$axes[[1L]]$artists[[1L]]$marker,"o")
    expect_equal(a$axes[[1L]]$artists[[1L]]$ydata,
      c(.6,.2,.27,.3))
    expect_identical(a$axes[[1L]]$artists[[2L]]$marker,"x")
    expect_identical(a$axes[[1L]]$artists[[2L]]$size,70)
    expect_equal(a$axes[[1L]]$artists[[2L]]$offsets,
      matrix(c(.2,.2),nrow=1L))
    expect_equal(a$axes[[2L]]$artists[[1L]]$ydata,c(.9,.5,.2,-.1))
    none<-z$delay
    none$table$first_ami_local_minimum[]<-FALSE
    b<-etr_plot_embedding_delay_diagnostics(none,strict_source_record=TRUE)
    expect_length(b$axes[[1L]]$artists,1L)
    old<-etr_plot_embedding_delay_diagnostics(z$delay)
    expect_identical(old$first_ami_local_minimum_indices,1L)
  })
})

test_that("FNN, recurrence degree and recurrence radius are source aligned",{
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    fnn<-etr_plot_embedding_dimension_diagnostics(z$fnn,
      strict_source_record=TRUE)
    expect_identical(fnn$axes[[1L]]$ylim_lower,0)
    expect_identical(fnn$axes[[1L]]$ylabel,
      "False-nearest-neighbor fraction")
    expect_equal(fnn$axes[[1L]]$artists[[1L]]$xdata,c(2,3,4))
    expect_equal(fnn$axes[[1L]]$artists[[1L]]$ydata,c(.5,.25,.1))
    net<-etr_plot_recurrence_network_degree(z$network,
      strict_source_record=TRUE)
    expect_identical(net$axes[[1L]]$title,
      "Recurrence-network degree (density=0.667)")
    expect_identical(net$axes[[1L]]$ylabel,"Normalized degree")
    expect_equal(net$axes[[1L]]$artists[[1L]]$xdata,c(0,1,2))
    expect_equal(net$axes[[1L]]$artists[[1L]]$ydata,c(.5,1,.5))
    raw<-etr_plot_recurrence_network_degree(z$network,
      normalized=FALSE,strict_source_record=TRUE)
    expect_identical(raw$axes[[1L]]$ylabel,"Degree")
    expect_equal(raw$axes[[1L]]$artists[[1L]]$ydata,c(1,2,1))
    radius<-etr_plot_recurrence_rate_curve(z$radius,
      strict_source_record=TRUE)
    expect_identical(radius$axes[[1L]]$ylim,c(0,1))
    expect_identical(radius$axes[[1L]]$xlabel,
      "Radius (euclidean state-space distance)")
    expect_equal(radius$axes[[1L]]$artists[[1L]]$ydata,c(.1,.4,.8))
    expect_identical(etr_plot_embedding_dimension_diagnostics(z$fnn),
      z$fnn$table)
    expect_equal(etr_plot_recurrence_network_degree(z$network)$degree,
      c(.5,1,.5))
    expect_identical(etr_plot_recurrence_rate_curve(z$radius),
      z$radius$table)
  })
})

test_that("selected windowed RQA source metric lines retain original order",{
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    a<-etr_plot_windowed_rqa(z$window,
      metrics=c("laminarity","recurrence_rate"),strict_source_record=TRUE)
    expect_identical(a$source_export,"plot_windowed_rqa")
    expect_identical(a$axes[[1L]]$legend_labels,
      c("laminarity","recurrence_rate"))
    expect_length(a$axes[[1L]]$artists,2L)
    expect_equal(a$axes[[1L]]$artists[[1L]]$xdata,c(1,2,3,4))
    expect_equal(a$axes[[1L]]$artists[[1L]]$ydata,c(.2,.3,.5,.7))
    expect_equal(a$axes[[1L]]$artists[[2L]]$ydata,c(.2,.3,.4,.6))
    expect_identical(a$axes[[1L]]$xlabel,"Window center (s)")
    expect_identical(names(etr_plot_windowed_rqa(z$window,
      metrics=c("laminarity","recurrence_rate"))),
      c("center_time","laminarity","recurrence_rate"))
  })
})

test_that("Rosenstein divergence source fit uses physical seconds and finite window",{
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    a<-etr_plot_local_divergence(z$divergence,
      strict_source_record=TRUE)
    expect_identical(a$axes[[1L]]$title,"Rosenstein: test")
    expect_length(a$axes[[1L]]$artists,1L)
    expect_identical(a$axes[[1L]]$legend_labels,
      "Mean log divergence")
    b<-etr_plot_local_divergence(z$lyapunov,
      strict_source_record=TRUE)
    expect_length(b$axes[[1L]]$artists,2L)
    expect_identical(b$axes[[1L]]$legend_labels,
      c("Mean log divergence","LLE fit: 500 1/s"))
    expect_identical(b$axes[[1L]]$artists[[2L]]$linestyle,"--")
    expect_equal(b$axes[[1L]]$artists[[2L]]$xdata,c(1,2,3))
    expect_equal(b$axes[[1L]]$artists[[2L]]$ydata,c(-1,-.5,0),
      tolerance=1e-12)
    old<-etr_plot_local_divergence(z$lyapunov)
    expect_equal(old$fit,c(NA,-1,-.5,0,NA))
  })
})

test_that("surrogate bins and Poincare return maps retain NumPy-style source artists",{
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    a<-etr_plot_surrogate_nonlinearity(z$surrogate,bins=3L,
      strict_source_record=TRUE)
    expect_identical(a$source_export,"plot_surrogate_nonlinearity")
    expect_identical(a$axes[[1L]]$legend_labels,"Observed")
    expect_identical(a$axes[[1L]]$artists[[1L]]$kind,"histogram")
    expect_identical(a$axes[[1L]]$artists[[1L]]$alpha,.7)
    expect_equal(sum(a$axes[[1L]]$artists[[1L]]$counts),5)
    expect_equal(a$axes[[1L]]$artists[[1L]]$edges,
      seq(1.1,2.2,length.out=4L),tolerance=1e-12)
    expect_identical(a$axes[[1L]]$artists[[2L]]$linestyle,"--")
    expect_equal(a$axes[[1L]]$artists[[2L]]$xdata,c(1.9,1.9))
    expect_error(etr_plot_surrogate_nonlinearity(z$surrogate,
      bins=3,strict_source_record=TRUE),"bins")
    b<-etr_plot_poincare_return_map(z$crossing,
      fit=z$fit,strict_source_record=TRUE)
    expect_identical(b$source_export,"plot_poincare_return_map")
    expect_identical(b$axes[[1L]]$legend_labels,
      c("Successive crossings","Identity","Local affine fit"))
    expect_length(b$axes[[1L]]$artists,3L)
    expect_equal(b$axes[[1L]]$artists[[1L]]$offsets,
      unname(cbind(c(1,1.4,1.8),c(1.4,1.8,1.5))))
    expect_equal(b$axes[[1L]]$artists[[2L]]$xdata,c(1,1.8))
    expect_identical(b$axes[[1L]]$artists[[2L]]$linestyle,":")
    expect_identical(b$axes[[1L]]$artists[[3L]]$linestyle,"--")
    expect_length(b$axes[[1L]]$artists[[3L]]$xdata,100L)
    expect_equal(b$axes[[1L]]$artists[[3L]]$ydata,
      1.7+.4*(b$axes[[1L]]$artists[[3L]]$xdata-1.5))
    none<-etr_plot_poincare_return_map(z$crossing,
      strict_source_record=TRUE)
    expect_length(none$axes[[1L]]$artists,2L)
    old<-etr_plot_surrogate_nonlinearity(z$surrogate,bins=3L)
    expect_false(old$python_matplotlib_histogram_binning_equivalent)
    original<-etr_plot_poincare_return_map(z$crossing,fit=z$fit)
    expect_equal(nrow(attr(original,"fit_curve")),100L)
  })
})

test_that("nonlinear strict modes fail closed on bad flags and scientific domains",{
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    expect_error(etr_plot_embedding_delay_diagnostics(z$delay,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_embedding_dimension_diagnostics(z$fnn,
      strict_source_record=1),"strict_source_record")
    expect_error(etr_plot_recurrence_network_degree(z$network,
      strict_source_record="yes"),"strict_source_record")
    expect_error(etr_plot_recurrence_rate_curve(z$radius,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_windowed_rqa(z$window,
      strict_source_record=0),"strict_source_record")
    expect_error(etr_plot_local_divergence(z$divergence,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_surrogate_nonlinearity(z$surrogate,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_poincare_return_map(z$crossing,
      strict_source_record=1L),"strict_source_record")
    bad<-z$delay;bad$table$autocorrelation[1L]<-NA_real_
    expect_error(etr_plot_embedding_delay_diagnostics(bad,
      strict_source_record=TRUE),"invalid values")
    bad<-z$fnn;bad$table$false_neighbor_fraction[1L]<-1.2
    expect_error(etr_plot_embedding_dimension_diagnostics(bad,
      strict_source_record=TRUE),"fractions")
    bad<-z$network;bad$degree[1L]<-Inf
    expect_error(etr_plot_recurrence_network_degree(bad,
      strict_source_record=TRUE),"valid native")
    bad<-z$radius;bad$table$recurrence_rate[1L]<-1.2
    expect_error(etr_plot_recurrence_rate_curve(bad,
      strict_source_record=TRUE),"recurrence rates")
    bad<-z$window;bad$table$recurrence_rate[]<-NA_real_
    bad$table$determinism[]<-NA_real_
    bad$table$laminarity[]<-NA_real_
    expect_error(etr_plot_windowed_rqa(bad,
      strict_source_record=TRUE),"undefined")
    bad<-z$divergence;bad$mean_log_divergence[]<-NA_real_
    expect_error(etr_plot_local_divergence(bad,
      strict_source_record=TRUE),"no finite")
    bad<-z$crossing;bad$states<-matrix(1,nrow=1,ncol=1)
    expect_error(etr_plot_poincare_return_map(bad,
      strict_source_record=TRUE),"one-dimensional")
  })
})

test_that("frozen Python 1.2 nonlinear source plot geometry matches typed native artists",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 nonlinear Matplotlib oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_eight_nonlinear_fixture()
  .etr_eight_nonlinear_pdf({
    r<-list(
      etr_plot_embedding_delay_diagnostics(z$delay,strict_source_record=TRUE),
      etr_plot_embedding_dimension_diagnostics(z$fnn,strict_source_record=TRUE),
      etr_plot_recurrence_network_degree(z$network,strict_source_record=TRUE),
      etr_plot_recurrence_rate_curve(z$radius,strict_source_record=TRUE),
      etr_plot_windowed_rqa(z$window,
        metrics=c("laminarity","recurrence_rate"),
        strict_source_record=TRUE),
      etr_plot_local_divergence(z$lyapunov,strict_source_record=TRUE),
      etr_plot_surrogate_nonlinearity(z$surrogate,
        bins=3L,strict_source_record=TRUE),
      etr_plot_poincare_return_map(z$crossing,fit=z$fit,
        strict_source_record=TRUE))
    reticulate::py_run_string("
import numpy as np, pandas as pd
from scipy.sparse import csr_matrix
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
from types import SimpleNamespace as S

delay=S(table=pd.DataFrame({
 'lag_time':[.1,.2,.3,.4],
 'average_mutual_information':[.6,.2,.27,.3],
 'autocorrelation':[.9,.5,.2,-.1],
 'first_ami_local_minimum':[False,True,False,False]}),
 curve_id='test',dimension='x',time_unit='s')
fnn=S(table=pd.DataFrame({'embedding_dimension':[2,3,4],
 'false_neighbor_fraction':[.5,.25,.1]}),curve_id='test',dimension='y')
network=object.__new__(et.RecurrenceNetworkResult)
for key,val in dict(
 degree=np.array([1,2,1]),normalized_degree=np.array([.5,1,.5]),
 adjacency=csr_matrix((3,3)),graph_density=2./3.).items():
 object.__setattr__(network,key,val)
radius=S(table=pd.DataFrame({'radius':[.1,.2,.3],
 'recurrence_rate':[.1,.4,.8]}),metric='euclidean',curve_id='test')
window=S(table=pd.DataFrame({'center_time':[1.,2.,3.,4.],
 'recurrence_rate':[.2,.3,.4,.6],
 'determinism':[.5,.6,.6,.7],
 'laminarity':[.2,.3,.5,.7]}),time_unit='s')
div=S(time_lags=np.array([0.,1.,2.,3.,4.]),
 mean_log_divergence=np.array([-2.,-1.5,-1.,-.5,0.]),
 time_unit='ms',curve_id='test',
 provenance={'estimator_family':'Rosenstein'})
lyap=object.__new__(et.LargestLyapunovResult)
for key,val in dict(divergence=div,fit_start=1,fit_end=3,
 intercept=-1.5,exponent=500.,exponent_unit='1/s').items():
 object.__setattr__(lyap,key,val)
sur=S(surrogate_statistics=np.array([1.1,1.3,1.8,2.,2.2]),
 observed_statistic=1.9,p_value=.3,
 statistic='largest_lyapunov',method='iaaft')
cross=S(states=np.array([[1.],[1.4],[1.8],[1.5]]),
 n_crossings=4,state_dimensions=('x',))
fit=S(reference_state=np.array([1.5]),intercept=np.array([.2]),
 jacobian=np.array([[.4]]))
axes=[
 et.plot_embedding_delay_diagnostics(delay),
 et.plot_embedding_dimension_diagnostics(fnn),
 et.plot_recurrence_network_degree(network),
 et.plot_recurrence_rate_curve(radius),
 et.plot_windowed_rqa(window,metrics=('laminarity','recurrence_rate')),
 et.plot_local_divergence(lyap),
 et.plot_surrogate_nonlinearity(sur,bins=3),
 et.plot_poincare_return_map(cross,fit=fit)]
def _line(line):
 return {'x':np.asarray(line.get_xdata(),dtype=float),
         'y':np.asarray(line.get_ydata(),dtype=float),
         'marker':line.get_marker(),
         'linestyle':line.get_linestyle()}
def _axis(ax):
 return {'title':ax.get_title(),'xlabel':ax.get_xlabel(),
  'ylabel':ax.get_ylabel(),
  'lines':[_line(line) for line in ax.lines],
  'legend':None if ax.get_legend() is None else
    [i.get_text() for i in ax.get_legend().get_texts()]}
oracle=[_axis(ax) for ax in axes]
oracle[0]['twin_ylabel']=axes[0].figure.axes[1].get_ylabel()
oracle[0]['twin_line']=_line(axes[0].figure.axes[1].lines[0])
oracle[0]['mark']=np.asarray(axes[0].collections[0].get_offsets(),dtype=float)
oracle[1]['ylim']=np.asarray(axes[1].get_ylim(),dtype=float)
oracle[3]['ylim']=np.asarray(axes[3].get_ylim(),dtype=float)
oracle[6]['hist_counts']=np.asarray(
 [p.get_height() for p in axes[6].patches],dtype=float)
oracle[6]['hist_edges']=np.asarray(
 [p.get_x() for p in axes[6].patches]+[
   axes[6].patches[-1].get_x()+axes[6].patches[-1].get_width()],dtype=float)
oracle[7]['scatter']=np.asarray(axes[7].collections[0].get_offsets(),dtype=float)
plt.close('all')
")
    py<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    expect_length(py,8L)
    for(i in seq_along(py)){
      ax<-r[[i]]$axes[[1L]]
      for(k in c("title","xlabel","ylabel"))
        expect_identical(ax[[k]],py[[i]][[k]],
          info=paste("axis",i,k))
    }
    for(i in c(1L,2L,3L,4L,5L,6L)){
      native<-r[[i]]$axes[[1L]]$artists[[1L]]
      source<-py[[i]]$lines[[1L]]
      expect_equal(native$xdata,as.numeric(source$x),tolerance=0,
        info=paste("line x",i))
      expect_equal(native$ydata,as.numeric(source$y),tolerance=1e-12,
        info=paste("line y",i))
      expect_identical(native$marker,source$marker)
      expect_identical(native$linestyle,source$linestyle)
    }
    expect_identical(r[[1L]]$axes[[2L]]$ylabel,py[[1L]]$twin_ylabel)
    expect_equal(r[[1L]]$axes[[2L]]$artists[[1L]]$ydata,
      as.numeric(py[[1L]]$twin_line$y))
    expect_equal(r[[1L]]$axes[[1L]]$artists[[2L]]$offsets,
      as.matrix(py[[1L]]$mark),ignore_attr=TRUE)
    expect_equal(r[[2L]]$axes[[1L]]$ylim_lower,as.numeric(py[[2L]]$ylim)[1L])
    expect_equal(r[[4L]]$axes[[1L]]$ylim,as.numeric(py[[4L]]$ylim))
    expect_identical(r[[5L]]$axes[[1L]]$legend_labels,
      as.character(py[[5L]]$legend))
    expect_equal(r[[6L]]$axes[[1L]]$artists[[2L]]$xdata,
      as.numeric(py[[6L]]$lines[[2L]]$x),tolerance=0)
    expect_equal(r[[6L]]$axes[[1L]]$artists[[2L]]$ydata,
      as.numeric(py[[6L]]$lines[[2L]]$y),tolerance=1e-12)
    expect_equal(r[[7L]]$axes[[1L]]$artists[[1L]]$counts,
      as.numeric(py[[7L]]$hist_counts),tolerance=0)
    expect_equal(r[[7L]]$axes[[1L]]$artists[[1L]]$edges,
      as.numeric(py[[7L]]$hist_edges),tolerance=1e-12)
    expect_equal(r[[8L]]$axes[[1L]]$artists[[1L]]$offsets,
      as.matrix(py[[8L]]$scatter),ignore_attr=TRUE)
    expect_equal(r[[8L]]$axes[[1L]]$artists[[2L]]$xdata,
      as.numeric(py[[8L]]$lines[[1L]]$x),tolerance=0)
    expect_equal(r[[8L]]$axes[[1L]]$artists[[3L]]$ydata,
      as.numeric(py[[8L]]$lines[[2L]]$y),tolerance=1e-12)
  })
})
