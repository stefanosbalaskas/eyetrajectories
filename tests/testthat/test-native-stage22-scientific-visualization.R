# Stage 22: source-aligned plot geometry. These are R graphics, not
# bitwise Matplotlib Axes or backend equivalence certificates.

.etr22_plot_device <- function(f) {
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  f()
}

test_that("Stage 22 eight public source-name analogues remain uncertified",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  names<-c("plot_embedding_delay_diagnostics",
    "plot_embedding_dimension_diagnostics",
    "plot_recurrence_network_degree","plot_recurrence_rate_curve",
    "plot_windowed_rqa","plot_local_divergence",
    "plot_surrogate_nonlinearity","plot_poincare_return_map")
  for(p in names){
    a<-z[z$python_name==p & z$namespace=="root",,drop=FALSE]
    expect_equal(nrow(a),1L)
    expect_identical(a$native_r_candidate,paste0("etr_",p))
    expect_identical(a$native_implementation_stage,22L)
    expect_true(a$native_implementation_started)
    expect_false(a$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate&z$is_python_function),222L)
  expect_equal(sum(z$is_python_function&!z$named_native_candidate),158L)
  expect_equal(sum(z$native_implementation_started),197L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 22 AMI and ACF plots retain separate source axes",{
  x<-structure(list(table=data.frame(
    lag_time=c(.1,.2,.3,.4),
    average_mutual_information=c(.6,.2,.27,.3),
    autocorrelation=c(.9,.5,.2,-.1),
    first_ami_local_minimum=c(FALSE,TRUE,FALSE,FALSE)),
    curve_id="test",dimension="x",time_unit="s"),
    class="etr_embedding_delay_diagnostics")
  .etr22_plot_device(function(){
    a<-etr_plot_embedding_delay_diagnostics(x)
    expect_equal(a$time,x$table$lag_time)
    expect_equal(a$ami,x$table$average_mutual_information)
    expect_equal(a$autocorrelation,x$table$autocorrelation)
    expect_identical(a$first_ami_local_minimum_indices,1L)
    y<-x;y$table$autocorrelation[2L]<-NA_real_
    expect_error(etr_plot_embedding_delay_diagnostics(y),"invalid values")
  })
})

test_that("Stage 22 FNN curve uses exact dimension/fractonal pairs",{
  x<-structure(list(table=data.frame(
    embedding_dimension=c(2L,3L,4L),
    false_neighbor_fraction=c(.5,.25,.1)),
    curve_id="test",dimension="y"),
    class="etr_embedding_dimension_diagnostics")
  .etr22_plot_device(function(){
    out<-etr_plot_embedding_dimension_diagnostics(x)
    expect_identical(out,x$table)
    invalid<-x;invalid$table$false_neighbor_fraction[2L]<-1.2
    expect_error(etr_plot_embedding_dimension_diagnostics(invalid),
      "fractions")
  })
})

test_that("Stage 22 network degree plot preserves sample index and normalization",{
  x<-structure(list(degree=c(1,2,1),
    normalized_degree=c(.5,1,.5),graph_density=2/3),
    class="etr_recurrence_network")
  .etr22_plot_device(function(){
    a<-etr_plot_recurrence_network_degree(x)
    b<-etr_plot_recurrence_network_degree(x,normalized=FALSE)
    expect_equal(a$state_index,c(0L,1L,2L))
    expect_equal(a$degree,c(.5,1,.5))
    expect_equal(b$degree,c(1,2,1))
    expect_error(etr_plot_recurrence_network_degree(x,NA),
      "normalized")
  })
})

test_that("Stage 22 radius profile reports exact radius and rate",{
  x<-structure(list(table=data.frame(radius=c(.1,.2,.3),
    recurrence_rate=c(.1,.4,.8)),
    metric="euclidean",curve_id="test"),
    class="etr_recurrence_radius_profile")
  .etr22_plot_device(function(){
    a<-etr_plot_recurrence_rate_curve(x)
    expect_identical(a,x$table)
    b<-x;b$table$recurrence_rate[2L]<-2
    expect_error(etr_plot_recurrence_rate_curve(b),"recurrence rates")
  })
})

test_that("Stage 22 windowed RQA uses declared metrics and physical center times",{
  x<-structure(list(table=data.frame(center_time=1:4,
    recurrence_rate=c(.2,.3,.4,.6),
    determinism=c(.5,.6,.6,.7),
    laminarity=c(.2,.3,.5,.7)),time_unit="s"),
    class="etr_windowed_rqa")
  .etr22_plot_device(function(){
    a<-etr_plot_windowed_rqa(x,metrics=c("laminarity","recurrence_rate"))
    expect_identical(names(a),c("center_time","laminarity","recurrence_rate"))
    expect_equal(a$center_time,x$table$center_time)
    expect_equal(a$laminarity,x$table$laminarity)
    expect_error(etr_plot_windowed_rqa(x,metrics="missing"),
      "metrics")
    expect_error(etr_plot_windowed_rqa(x,metrics=c("laminarity","laminarity")),
      "metrics")
  })
})

test_that("Stage 22 source LLE fit uses declared time window and physical units",{
  div<-structure(list(time_lags=c(0,1,2,3,4),
    mean_log_divergence=c(-2,-1.5,-1,-.5,0),
    time_unit="ms",curve_id="test",
    provenance=list(estimator_family="Rosenstein")),
    class="etr_local_divergence")
  fit<-structure(list(divergence=div,fit_start=1,fit_end=3,
    intercept=-1.5,exponent=500,exponent_unit="1/s"),
    class="etr_largest_lyapunov")
  .etr22_plot_device(function(){
    a<-etr_plot_local_divergence(div)
    expect_true(all(is.na(a$fit)))
    b<-etr_plot_local_divergence(fit)
    expect_equal(b$fit,c(NA,-1,-.5,0,NA))
    expect_equal(b$time_lag,div$time_lags)
    corrupt<-div;corrupt$mean_log_divergence[]<-NA_real_
    expect_error(etr_plot_local_divergence(corrupt),
      "no finite")
  })
})

test_that("Stage 22 IAAFT histogram returns counts but not Matplotlib parity",{
  x<-structure(list(surrogate_statistics=c(1.1,1.3,1.8,2.0,2.2),
    observed_statistic=1.9,p_value=.3,statistic="largest_lyapunov",
    method="iaaft"),class="etr_surrogate_nonlinearity")
  .etr22_plot_device(function(){
    out<-etr_plot_surrogate_nonlinearity(x,bins=3L)
    expect_equal(sum(out$counts),length(x$surrogate_statistics))
    expect_equal(out$observed,1.9)
    expect_false(out$python_matplotlib_histogram_binning_equivalent)
    expect_error(etr_plot_surrogate_nonlinearity(x,bins=1L),"bins")
    expect_error(etr_plot_surrogate_nonlinearity(x,bins=NA),"bins")
  })
})

test_that("Stage 22 Poincare return plot keeps observed transitions",{
  crossings<-structure(list(states=matrix(c(1,1.4,1.8,1.5),ncol=1L),
    state_dimensions="x"),class="etr_poincare_crossings")
  fit<-structure(list(reference_state=1.5,intercept=.2,
    jacobian=matrix(.4,1L,1L)),class="etr_local_return_map")
  .etr22_plot_device(function(){
    a<-etr_plot_poincare_return_map(crossings)
    expect_equal(a$current,c(1,1.4,1.8))
    expect_equal(a$next_state,c(1.4,1.8,1.5))
    b<-etr_plot_poincare_return_map(crossings,fit=fit)
    fitted<-attr(b,"fit_curve")
    expect_equal(length(fitted$x),100L)
    expect_equal(fitted$y,1.7+.4*(fitted$x-1.5))
    invalid<-crossings;invalid$states<-cbind(
      invalid$states,invalid$states)
    expect_error(etr_plot_poincare_return_map(invalid),"one-dimensional")
  })
})
