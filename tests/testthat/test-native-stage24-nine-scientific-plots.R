# Stage 24: native scientific plot geometry and published Python shape witnesses.
.etr24_pdf <- function(f) {
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  f()
}
.etr24_fixture <- function(){
  st<-structure(list(similarities=matrix(c(.9,.8,.95,.7,.75,.8),3L,2L),
    reference=list(n_components=2L)),class="etr_fpca_stability")
  infl<-structure(list(summary=data.frame(group=c("a","b","c"),
    influence_score=c(.2,.5,.1),
    min_abs_component_similarity=c(.8,.5,.9))),
    class="etr_fpca_influence")
  out<-structure(list(diagnostics=data.frame(
    reconstruction_robust_z=c(.1,3,1),
    score_mahalanobis_sq=c(2,10,4),
    score_cutoff=c(7,7,7),
    review_flag=c(FALSE,TRUE,FALSE)),
    provenance=list(reconstruction_z_threshold=2.5)),
    class="etr_fpca_outliers")
  cv<-structure(list(fold_errors=data.frame(
    fold=c(0L,1L,0L,1L),
    n_components=c(1L,1L,2L,2L),
    mean_integrated_rmse=c(.5,.6,.3,.35))),
    class="etr_fpca_cv")
  sub<-structure(list(component_indices=c(0L,1L),
    principal_cosines=matrix(c(.9,.95,.8,.85),2L,2L),
    principal_angles_degrees=matrix(c(20,26,30,29),2L,2L),
    normalized_projector_distance=c(.15,.3)),
    class="etr_fpca_subspace_stability")
  band<-structure(list(time=c(0,.5,1),
    mean=matrix(c(1,2,3),3L,1L),
    lower=matrix(c(.5,1.5,2.5),3L,1L),
    upper=matrix(c(1.5,2.5,3.5),3L,1L),
    dimension_names="x",time_unit="s",confidence_level=.95),
    class="etr_functional_mean_band")
  m<-matrix(c(TRUE,FALSE,TRUE,FALSE,FALSE,TRUE,
    TRUE,TRUE,TRUE),3L,3L)
  joint<-structure(list(matrix=m,joint_recurrence_rate=.75,
    component_labels=c("x","y")),class="etr_joint_recurrence")
  vals<-array(c(.1,.2,.3,.4,.5,.6),c(2L,3L,1L))
  traj<-etr_trajectory_set(time=c(1,2,3),values=vals,
    curve_ids=c("a","b"),dimension_names="recurrence_rate",
    coordinate_system="rqa_metrics",time_unit="s")
  win<-structure(list(trajectories=traj,metrics="recurrence_rate",
    time_unit="s"),class="etr_windowed_rqa_functional")
  tab<-data.frame(embedding_dimension=c(2L,3L,4L),
    radius=c(.2,.2,.2),delay_samples=c(1L,1L,1L),
    recurrence_rate=c(.3,.5,.65))
  sens<-structure(list(table=tab,
    parameter_columns=c("embedding_dimension","radius","delay_samples"),
    metric_columns="recurrence_rate",curve_id="test"),
    class="etr_rqa_parameter_sensitivity")
  list(st=st,infl=infl,out=out,cv=cv,sub=sub,band=band,
    joint=joint,win=win,sens=sens)
}

test_that("Stage 24 nine scientific visualization mappings are unique and unsigned",{
  z<-etr_native_parity_catalog()
  names<-c("plot_fpca_stability","plot_fpca_influence",
    "plot_fpca_outlier_diagnostics","plot_fpca_cross_validation",
    "plot_fpca_subspace_stability","plot_functional_mean_band",
    "plot_joint_recurrence","plot_windowed_rqa_trajectories",
    "plot_rqa_sensitivity")
  for(n in names){
    row<-z[z$python_name==n&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",n))
    expect_identical(row$native_implementation_stage,24L)
    expect_true(row$native_implementation_started)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate&z$is_python_function),213L)
  expect_equal(sum(z$is_python_function&!z$named_native_candidate),167L)
  expect_equal(sum(z$native_implementation_started),188L)
  expect_equal(sum(z$contract_certification_candidate),4L)
  expect_equal(sum(z$source_contract_gap_unresolved),34L)
  expect_true(all(z$source_contract_gap_unresolved[
    z$native_implementation_stage==24L &
      !is.na(z$native_implementation_stage)]))
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})

test_that("Stage 24 matched FPC similarity boxplots keep source geometry",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    m<-etr_plot_fpca_stability(x$st)
    expect_equal(m,x$st$similarities,tolerance=0)
    y<-x$st;y$similarities[1L,1L]<-1.2
    expect_error(etr_plot_fpca_stability(y),"valid native")
  })
})

test_that("Stage 24 FPCA influence respects declared metric, groups and order",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_fpca_influence(x$infl,metric="influence_score")
    expect_identical(d$group,c("a","b","c"))
    expect_equal(d$value,c(.2,.5,.1))
    expect_error(etr_plot_fpca_influence(x$infl,metric="missing"),"metric")
  })
})

test_that("Stage 24 FPCA review graphics preserve robust-z and score thresholds",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_fpca_outlier_diagnostics(x$out)
    expect_equal(d$reconstruction_robust_z,c(.1,3,1))
    expect_equal(d$score_cutoff,c(7,7,7))
    y<-x$out;y$diagnostics$review_flag[1L]<-NA
    expect_error(etr_plot_fpca_outlier_diagnostics(y),"review flags")
  })
})

test_that("Stage 24 FPCA cross-validation is tied to held-out fold errors",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_fpca_cross_validation(x$cv)
    expect_equal(d$n_components,c(1L,2L))
    expect_equal(d$mean_rmse,c(.55,.325))
    expect_gt(d$se_rmse[1L],0)
  })
})

test_that("Stage 24 eigenspace metric derivation uses per-bootstrap cosine",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_fpca_subspace_stability(x$sub,
      metric="min_principal_cosine")
    expect_equal(d$value,apply(x$sub$principal_cosines,1L,min))
    a<-etr_plot_fpca_subspace_stability(x$sub,
      metric="max_principal_angle_degrees")
    expect_equal(a$value,apply(x$sub$principal_angles_degrees,1L,max))
    expect_error(etr_plot_fpca_subspace_stability(x$sub,
      metric="invalid"),"metric")
  })
})

test_that("Stage 24 simultaneous mean plot preserves confidence bounds",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_functional_mean_band(x$band)
    expect_equal(d$time,c(0,.5,1))
    expect_equal(d$mean,c(1,2,3))
    expect_equal(d$lower,c(.5,1.5,2.5))
    expect_equal(d$upper,c(1.5,2.5,3.5))
    expect_error(etr_plot_functional_mean_band(x$band,dimension="z"),
      "dimension")
  })
})

test_that("Stage 24 joint recurrence preserves source zero-based indexes",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_joint_recurrence(x$joint)
    expect_equal(nrow(d),sum(x$joint$matrix))
    expect_true(all(d$row_index>=0L & d$row_index<3L))
    expect_true(all(d$col_index>=0L & d$col_index<3L))
    expect_error(etr_plot_joint_recurrence(x$joint,max_points=1L),
      "exceeds max_points")
    expect_error(etr_plot_joint_recurrence(x$joint,max_points=0L),
      "max_points")
  })
})

test_that("Stage 24 windowed RQA functional plot retains the actual source cube",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_windowed_rqa_trajectories(x$win,
      metric="recurrence_rate",show_mean=TRUE,max_curves=1L)
    expect_equal(d$time,c(1,2,3))
    expect_equal(d$curve_values[1L,],x$win$trajectories$values[1L,,1L])
    expect_equal(d$across_curve_mean,
      colMeans(matrix(x$win$trajectories$values,nrow=2L)))
    expect_error(etr_plot_windowed_rqa_trajectories(x$win,
      metric="missing"),"metric")
  })
})

test_that("Stage 24 RQA sensitivity fails closed when slice not identified",{
  x<-.etr24_fixture()
  .etr24_pdf(function(){
    d<-etr_plot_rqa_sensitivity(x$sens,
      parameter="embedding_dimension",metric="recurrence_rate")
    expect_equal(d$embedding_dimension,c(2L,3L,4L))
    expect_equal(d$recurrence_rate,c(.3,.5,.65))
    y<-x$sens;y$table$radius[2L]<-.3
    expect_error(etr_plot_rqa_sensitivity(y,
      parameter="embedding_dimension",metric="recurrence_rate"),
      "fix other varying")
    expect_error(etr_plot_rqa_sensitivity(x$sens,
      parameter="missing",metric="recurrence_rate"),"parameter and metric")
  })
})

test_that("Stage 24 direct pinned Python 1.2 plot geometry oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Direct published Python 1.2 Matplotlib/Axes geometry is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr24_fixture()
  plt<-reticulate::import("matplotlib.pyplot")
  on.exit(plt$close("all"),add=TRUE)
  types<-reticulate::import("types")
  pd<-reticulate::import("pandas")
  obj<-types$SimpleNamespace(
    summary=pd$DataFrame(reticulate::r_to_py(list(
      group=c("a","b","c"),
      influence_score=c(.2,.5,.1),
      min_abs_component_similarity=c(.8,.5,.9)))))
  ax<-reticulate::py_call(etpy_get_export("plot_fpca_influence"),
    result=obj,metric="influence_score")
  # reticulate indexes a Python list from zero; Axes.plot adds one line.
  expect_equal(as.integer(reticulate::py_len(ax$lines)),1L)
  xy<-as.matrix(et_to_r(ax$lines[[0L]]$get_xydata()))
  expect_equal(unname(xy[,1L]),c(0,1,2))
  expect_equal(unname(xy[,2L]),c(.2,.5,.1),tolerance=1e-12)
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  d<-etr_plot_fpca_influence(x$infl,metric="influence_score")
  expect_equal(d$value,xy[,2L],tolerance=1e-12)
  expect_true(reticulate::py_has_attr(ax,"figure"))
  expect_false(inherits(d,"python.builtin.object"))
})
