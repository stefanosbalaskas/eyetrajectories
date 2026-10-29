# Stage 19: source-oriented multiverse, FPCA clusters and distance sensitivity.

.etr19_fixture <- function(){
  nt<-41L;t<-seq(0,2,length.out=nt);n<-8L
  z<-array(0,c(n,nt,2L))
  for(i in seq_len(n)){
    z[i,,1L]<-sin(t*(2+.03*i)+.21*i)+.16*cos(3*t+.3*i)+i*t/45
    z[i,,2L]<-cos(1.5*t+.17*i)+.09*sin(t*5+i*.18)+i*t/36
  }
  etr_trajectory_set(t,z,sprintf("c%02d",seq_len(n)),c("x","y"),
    time_unit="s",coordinate_system="normalized")
}
test_that("Stage 19 Rosenstein sensitivity retains complete declared fit grid",{
  x<-.etr19_fixture()
  s<-etr_lyapunov_parameter_sensitivity(x,"c01",c("x","y"),
    embedding_dimensions=2L,delays=c(1L,2L),
    theiler_windows=c(2L,3L),
    fit_intervals=list(c(1L,4L),c(2L,5L)),max_horizon=7L)
  expect_s3_class(s,"etr_lyapunov_parameter_sensitivity")
  expect_equal(nrow(s$table),8L)
  expect_identical(s$table$specification_id,
    sprintf("spec_%d",1:8))
  expect_true(all(is.finite(s$table$exponent)))
  expect_true(all(s$table$n_fit_points>=3L))
  expect_true(all(s$table$minimum_pair_count_in_fit>=0))
  expect_false(s$provenance$automatic_parameter_selection)
  e<-etr_delay_embed_trajectory(x,2L,1L,dimensions=c("x","y"))
  d<-etr_local_divergence_curve(e,"c01",2L,7L)
  z<-etr_estimate_largest_lyapunov_rosenstein(d,1L,4L)
  expect_equal(s$table$exponent[1L],z$exponent,tolerance=1e-12)
  expect_equal(s$table$standard_error[1L],z$standard_error,
    tolerance=1e-12)
  expect_error(etr_lyapunov_parameter_sensitivity(x,"c01","x",
    2L,1L,2L,list(c(1L,2L)),7L),"fewer than three")
  expect_error(etr_lyapunov_parameter_sensitivity(x,"c01","x",
    2L,c(1L,1L),2L,list(c(1L,4L)),7L),"distinct")
})

test_that("Stage 19 Kantz sensitivity reuses exact radius and explicit fits",{
  x<-.etr19_fixture()
  s<-etr_kantz_parameter_sensitivity(x,"c01",c("x","y"),
    embedding_dimensions=2L,delays=1L,
    radii=c(2,3),min_neighbors=c(1L,2L),
    theiler_windows=2L,
    fit_intervals=list(c(1L,4L),c(2L,5L)),max_horizon=7L)
  expect_s3_class(s,"etr_kantz_parameter_sensitivity")
  expect_equal(nrow(s$table),8L)
  expect_true(all(s$table$initial_supported_reference_fraction>=0&
    s$table$initial_supported_reference_fraction<=1))
  expect_true(all(s$table$minimum_reference_count_in_fit>=0))
  expect_identical(s$curve_id,"c01")
  expect_true(all(is.finite(s$table$exponent)))
  e<-etr_delay_embed_trajectory(x,2L,1L,dimensions=c("x","y"))
  d<-etr_kantz_divergence_curve(e,"c01",radius=2,
    theiler_window=2L,max_horizon=7L,min_neighbors=1L)
  z<-etr_estimate_largest_lyapunov_kantz(d,1L,4L)
  expect_equal(s$table$exponent[1L],z$exponent,tolerance=1e-12)
  expect_error(etr_kantz_parameter_sensitivity(x,"c01","x",
    2L,1L,radii=c(2,2),min_neighbors=1L,theiler_windows=2L,
    fit_intervals=list(c(1L,4L)),max_horizon=7L),"distinct")
})

test_that("Stage 19 fixed-radius RQA sensitivity preserves full Cartesian choices",{
  x<-.etr19_fixture()
  s<-etr_rqa_parameter_sensitivity(x,"c01",c("x","y"),
    embedding_dimensions=2L,delays=1L,
    theiler_windows=c(1L,2L),radii=c(.4,.8),
    min_diagonal_lengths=c(2L,3L),min_vertical_lengths=2L)
  expect_s3_class(s,"etr_rqa_parameter_sensitivity")
  expect_equal(nrow(s$table),8L)
  expect_true(all(s$table$recurrence_rate>=0&
    s$table$recurrence_rate<=1))
  expect_identical(s$table$threshold_policy,rep("fixed_radius",8))
  expect_identical(s$provenance$automatic_parameter_selection,FALSE)
  expect_false(anyDuplicated(s$table$specification_id)>0L)
  expect_equal(nrow(s$summary_table),8L)
  expect_error(etr_rqa_parameter_sensitivity(x,"c01","x",
    2L,1L,1L,2L,2L,target_recurrence_rates=.05),
    "adaptive")
  expect_error(etr_rqa_parameter_sensitivity(x,"c01","x",
    2L,1L,1L,2L,2L,radii=.1,distance_metric="manhattan"),
    "Euclidean")
})

test_that("Stage 19 native FPCA clustering respects score geometry and isolated RNG",{
  x<-.etr19_fixture()
  fit<-etr_fit_mfpca(x,n_components=3L)
  set.seed(191);before<-.Random.seed
  z<-etr_cluster_fpca_scores(fit,2L,2L,random_state=3L,n_init=4L)
  expect_identical(before,.Random.seed)
  expect_s3_class(z,"etr_fpca_clusters")
  expect_equal(length(z$labels),8L)
  expect_true(all(z$labels%in%0:1))
  expect_equal(dim(z$centers),c(2L,2L))
  expect_true(all(is.finite(z$centers)))
  expect_true(z$tot_withinss>=0)
  scores<-fit$scores[,1:2,drop=FALSE]
  for(group in 0:1){
    idx<-which(z$labels==group)
    expect_true(length(idx)>0L)
    expect_equal(as.numeric(z$centers[group+1L,]),
      as.numeric(colMeans(scores[idx,,drop=FALSE])),tolerance=1e-10)
  }
  again<-etr_cluster_fpca_scores(fit,2L,2L,random_state=3L,n_init=4L)
  expect_identical(z$labels,again$labels)
  expect_error(etr_cluster_fpca_scores(fit,9L),
    "must not exceed")
  expect_error(etr_cluster_fpca_scores(fit,2L,4L),
    "exceeds fitted")
})

test_that("Stage 19 distance multiverse compares raw matrices and exact neighbors",{
  x<-.etr19_fixture()
  specs<-list(
    list(name="l2",method="functional_l2"),
    list(name="frechet",method="discrete_frechet"),
    list(name="dtw",method="dtw",step_pattern="symmetric2",
      normalize=TRUE,window_radius=7L))
  z<-etr_trajectory_distance_sensitivity(x,specs,
    dimensions=c("x","y"),neighbor_k=2L)
  expect_s3_class(z,"etr_trajectory_distance_sensitivity")
  expect_identical(dim(z$distance_matrices),c(3L,8L,8L))
  expect_identical(dim(z$neighbor_orders),c(3L,8L,2L))
  expect_equal(nrow(z$comparison_table),3L)
  expect_equal(nrow(z$neighbor_overlap_table),3L*8L)
  expect_equal(nrow(z$pairwise_distance_table),3L*28L)
  expect_true(all(z$neighbor_orders>=0 & z$neighbor_orders<8))
  expect_true(all(z$comparison_table$mean_top_k_neighbor_jaccard>=0&
    z$comparison_table$mean_top_k_neighbor_jaccard<=1))
  expect_true(all(z$comparison_table$exact_top_k_neighbor_set_agreement_fraction>=0&
    z$comparison_table$exact_top_k_neighbor_set_agreement_fraction<=1))
  expect_equal(diag(z$distance_matrices[1L,,]),rep(0,8))
  expect_true(isTRUE(all.equal(z$distance_matrices[2L,,],
    t(z$distance_matrices[2L,,]))))
  a<-matrix(x$values[1L,,,drop=FALSE],41,2)
  b<-matrix(x$values[2L,,,drop=FALSE],41,2)
  expect_equal(z$distance_matrices[1L,1L,2L],
    etr_l2_distance(a,b,time=x$time),tolerance=1e-12)
  expect_equal(z$distance_matrices[2L,1L,2L],
    etr_discrete_frechet(a,b),tolerance=1e-12)
  expect_error(etr_trajectory_distance_sensitivity(x,specs[1L]),
    "at least two")
  expect_error(etr_trajectory_distance_sensitivity(x,specs,
    neighbor_k=8L),"neighbor_k")
  expect_error(etr_trajectory_distance_sensitivity(x,
    list(list(name="same",method="functional_l2"),
      list(name="same",method="discrete_frechet"))),"distinct")
})

test_that("Stage 19 frozen source remains 508 without false parity certification",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),213L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),167L)
  expect_equal(sum(z$native_implementation_started),188L)
  expect_equal(sum(z$native_implementation_stage==19L,na.rm=TRUE),5L)
  expect_equal(sum(!z$is_python_function &
    is.na(z$native_representation_stage)),121L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 19 pinned Python 1.2 deterministic distance and divergence oracle opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 19 pinned Python 1.2 deterministic numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr19_fixture()
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    time_unit="s",coordinate_system="normalized")
  specs<-list(list(name="l2",method="functional_l2"),
              list(name="frechet",method="discrete_frechet"))
  py<-reticulate::py_call(etpy_get_export("trajectory_distance_sensitivity"),
    trajectories=pyx,specifications=reticulate::r_to_py(specs),
    dimensions=as.list(c("x","y")),neighbor_k=as.integer(2L))
  r<-etr_trajectory_distance_sensitivity(x,specs,
    dimensions=c("x","y"),neighbor_k=2L)
  expect_equal(unname(r$distance_matrices),
    unname(et_to_r(py$distance_matrices)),tolerance=1e-10)
  expect_equal(unname(r$neighbor_orders),
    unname(et_to_r(py$neighbor_orders)),tolerance=0)
  expect_equal(unname(r$neighbor_cutoff_ties),
    unname(et_to_r(py$neighbor_cutoff_ties)),tolerance=0)
  e<-etr_delay_embed_trajectory(x,2L,1L,dimensions=c("x","y"))
  pye<-reticulate::py_call(etpy_get_export("delay_embed_trajectory"),
    trajectories=pyx,embedding_dimension=as.integer(2L),
    delay=as.integer(1L),dimensions=as.list(c("x","y")))
  pyr<-reticulate::py_call(etpy_get_export("local_divergence_curve"),
    embedding=pye,curve="c01",theiler_window=as.integer(2L),
    max_horizon=as.integer(7L))
  native<-etr_lyapunov_parameter_sensitivity(x,"c01",c("x","y"),
    2L,1L,2L,list(c(1L,4L)),7L)
  pr<-reticulate::py_call(etpy_get_export(
    "estimate_largest_lyapunov_rosenstein"),
    divergence=pyr,fit_start=as.integer(1L),fit_end=as.integer(4L))
  expect_equal(native$table$exponent[1L],
    as.numeric(et_to_r(pr$exponent)),tolerance=1e-8)
  expect_equal(native$table$standard_error[1L],
    as.numeric(et_to_r(pr$standard_error)),tolerance=1e-8)
})
