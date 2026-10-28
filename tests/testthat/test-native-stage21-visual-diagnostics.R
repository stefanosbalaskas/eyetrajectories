# Stage 21: native visualization geometry tests, no Python initialization.
# No matplotlib Axes parity or full 508-export contract certification claimed.

.etr21_fixture <- function() {
  time<-seq(0,1,length.out=16L)
  v<-array(0,c(6L,length(time),2L))
  for(i in seq_len(6L)){
    v[i,,1L]<-sin(2*pi*time+.14*i)+i*.08*time
    v[i,,2L]<-cos(2*pi*time+.19*i)-i*.06*time
  }
  etr_trajectory_set(time,v,sprintf("curve%02d",seq_len(6L)),
    c("x","y"),time_unit="s")
}

test_that("Stage 21 registered public plotting names remain uncertified", {
  started<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  names<-c("plot_planar_trajectories","plot_fpca_component",
    "plot_dynamic_time_warping_alignment",
    "plot_trajectory_distance_rank_correlations")
  mapped<-paste0("etr_",names)
  for(i in seq_along(names)){
    row<-z[z$python_name==names[i] &
      z$namespace=="root",,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,mapped[i])
    expect_identical(row$native_implementation_stage,21L)
    expect_true(row$native_implementation_started)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$native_implementation_started),166L)
  expect_equal(sum(z$named_native_candidate&z$is_python_function),191L)
  expect_equal(sum(z$is_python_function&!z$named_native_candidate),189L)
  expect_equal(sum(z$contract_certification_candidate),3L)
  expect_equal(sum(z$contract_numerical_fixture_pass),3L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_identical(started,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 21 planar visualization preserves selected native geometry",{
  x<-.etr21_fixture()
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  g<-etr_plot_planar_trajectories(x,max_curves=2L,alpha=.6,
    invert_y=TRUE)
  expect_identical(g$curve_ids,x$curve_ids[1:2])
  expect_equal(g$xlim,range(x$values[1:2,,1L]))
  expect_equal(g$ylim,rev(range(x$values[1:2,,2L])))
  expect_equal(g$alpha,.6)
  expect_identical(g$backend,"base_R_graphics_not_matplotlib")
  expect_equal(length(etr_plot_planar_trajectories(x,
    max_curves=NULL)$curve_ids),6L)
  expect_error(etr_plot_planar_trajectories(x,max_curves=0L),
    "max_curves")
  expect_error(etr_plot_planar_trajectories(x,alpha=NaN),"alpha")
  expect_error(etr_plot_planar_trajectories(x,invert_y=NA),
    "invert_y")
})

test_that("Stage 21 FPCA graphics follow fitted score-SD geometry exactly",{
  x<-.etr21_fixture();fit<-etr_fit_mfpca(x,n_components=2L)
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  g<-etr_plot_fpca_component(fit,component=0L,dimension="x",
    sd_multiplier=1.5)
  ref<-etr_component_trajectories(fit,0L,c(-1.5,0,1.5))
  expect_equal(g$lower,as.numeric(ref[1L,,1L]))
  expect_equal(g$mean,as.numeric(ref[2L,,1L]))
  expect_equal(g$upper,as.numeric(ref[3L,,1L]))
  expect_equal(g$time,fit$time)
  expect_error(etr_plot_fpca_component(fit,component=9L),"range")
  expect_error(etr_plot_fpca_component(fit,dimension="missing"),
    "dimension")
  expect_error(etr_plot_fpca_component(fit,sd_multiplier=0),
    "sd_multiplier")
})

test_that("Stage 21 DTW plots use source zero-based audited path",{
  a<-matrix(c(0,1,2,2.5),ncol=1L)
  b<-matrix(c(0,.7,1.8,2.5),ncol=1L)
  result<-etr_dynamic_time_warping(a,b,
    step_pattern="symmetric2",return_path=TRUE,normalize=TRUE)
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  p<-etr_plot_dynamic_time_warping_alignment(result)
  expect_identical(p,result$path)
  expect_equal(p[1L,],c(0L,0L))
  expect_equal(p[nrow(p),],c(3L,3L))
  expect_error(etr_plot_dynamic_time_warping_alignment(
    list(path=matrix(0,2L,2L))),"native DTW")
  corrupt<-result;corrupt$path[1L,]<-c(1L,1L)
  expect_error(etr_plot_dynamic_time_warping_alignment(corrupt),
    "monotone")
})

test_that("Stage 21 distance agreement plot is symmetric and diagonal one",{
  x<-.etr21_fixture()
  result<-etr_trajectory_distance_sensitivity(x,
    list(list(name="L2",method="functional_l2"),
         list(name="Frechet",method="discrete_frechet")),
    neighbor_k=2L)
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  m<-etr_plot_trajectory_distance_rank_correlations(result)
  expect_equal(dim(m),c(2L,2L))
  expect_equal(unname(diag(m)),rep(1,2))
  expect_identical(names(diag(m)),c("L2","Frechet"))
  expect_equal(m,t(m),tolerance=0)
  expect_equal(m[1L,2L],
    result$comparison_table$spearman_rank_correlation[1L])
  expect_error(etr_plot_trajectory_distance_rank_correlations(list()),
    "native trajectory")
  missing<-result;missing$comparison_table<-
    missing$comparison_table[FALSE,,drop=FALSE]
  expect_error(etr_plot_trajectory_distance_rank_correlations(missing),
    "missing a specification pair")
})
