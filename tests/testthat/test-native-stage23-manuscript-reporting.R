# Stage 23 deterministic source-facing manuscript reporting contracts.
# Strings are descriptive and do not certify estimators or inference.

.etr23_fixtures <- function() {
  dtw<-structure(list(path=matrix(c(0L,0L,1L,1L),ncol=2L,byrow=TRUE),
    distance=2,raw_distance=4,normalized_distance=2,
    step_pattern="symmetric2",path_length=2L,n_points_a=2L,
    n_points_b=2L,window_radius=NULL,
    provenance=list(normalization_requested=TRUE)),class="etr_dtw_result")
  distance<-structure(list(
    comparison_table=data.frame(spearman_rank_correlation=.8,
      mean_top_k_neighbor_jaccard=.7,
      nearest_neighbor_identity_agreement_fraction=.5),
    specification_names=c("L2","DTW"),curve_ids=c("a","b","c"),
    dimensions=c("x","y"),neighbor_k=1L,
    neighbor_cutoff_ties=matrix(c(FALSE,TRUE,FALSE,FALSE,FALSE,FALSE),2L,3L)),
    class="etr_trajectory_distance_sensitivity")
  stability<-structure(list(reference=list(n_components=2L),
    similarities=matrix(c(.8,.9,.75,.7,.6,.8),3L,2L),
    resampling_unit="curve"),class="etr_fpca_stability")
  outlier<-structure(list(diagnostics=data.frame(
    review_flag=c(FALSE,TRUE,FALSE,TRUE)),
    method="fpca_reconstruction_and_score_space"),class="etr_fpca_outliers")
  influence<-structure(list(summary=data.frame(
    group=c("g1","g2"),influence_score=c(.1,.4),
    min_abs_component_similarity=c(.9,.6)),
    group_column=NULL),class="etr_fpca_influence")
  subspace<-structure(list(
    component_indices=c(0L,1L),
    principal_cosines=matrix(c(.9,.95,.8,.86),2L,2L),
    principal_angles_degrees=matrix(c(20,24,31,29),2L,2L),
    normalized_projector_distance=c(.2,.4),
    resampling_unit="curve"),class="etr_fpca_subspace_stability")
  cv<-structure(list(fold_errors=data.frame(
    fold=c(0L,1L,0L,1L),
    n_components=c(1L,1L,2L,2L),
    mean_integrated_rmse=c(.6,.4,.5,.38)),
    n_splits=2L,cv_unit="curve"),class="etr_fpca_cv")
  multilevel<-structure(list(
    between=list(explained_variance_ratio=c(.5,.3)),
    within=list(explained_variance_ratio=c(.4,.2))),
    class="etr_multilevel_fpca")
  list(dtw=dtw,distance=distance,stability=stability,outlier=outlier,
    influence=influence,subspace=subspace,cv=cv,multilevel=multilevel)
}

test_that("Stage 23 output text is deterministic and source-scope qualified",{
  z<-.etr23_fixtures()
  a<-etr_dynamic_time_warping_reporting_text(z$dtw)
  expect_match(a,"symmetric2 step pattern")
  expect_match(a,"N\\+M-normalized distance=2.000")
  expect_match(a,"no step pattern, window, preprocessing")
  expect_identical(a,etr_dynamic_time_warping_reporting_text(z$dtw))
  expect_error(etr_dynamic_time_warping_reporting_text(z$dtw,digits=NA),
    "digits")
  expect_error(etr_dynamic_time_warping_reporting_text(z$dtw,digits=-1L),
    "digits")
  expect_match(etr_trajectory_distance_sensitivity_reporting_text(
    z$distance),"2 predeclared distance specifications")
  expect_match(etr_trajectory_distance_sensitivity_reporting_text(
    z$distance),"1 specification-by-curve neighborhood cutoff ties")
  expect_match(etr_fpca_stability_reporting_text(z$stability),
    "median \\|similarity\\|")
  expect_match(etr_fpca_stability_reporting_text(z$stability),
    "not inferential probabilities")
  expect_error(etr_fpca_stability_reporting_text(z$stability,
    similarity_threshold=1.2),"similarity_threshold")
  expect_match(etr_fpca_outlier_reporting_text(z$outlier),
    "flagged 2 of 4 trajectories")
  expect_match(etr_fpca_influence_reporting_text(z$influence),
    "largest observed influence was for 'g2'")
  expect_match(etr_fpca_subspace_stability_reporting_text(z$subspace),
    "FPC1")
  expect_match(etr_fpca_subspace_stability_reporting_text(z$subspace),
    "descriptive eigenspace-stability summaries")
  expect_match(etr_fpca_cross_validation_reporting_text(z$cv,rule="minimum"),
    "2-fold curve-level held-out")
  expect_match(etr_fpca_cross_validation_reporting_text(z$cv,rule="one_se"),
    "parsimony heuristic")
  expect_error(etr_fpca_cross_validation_reporting_text(z$cv,rule="invented"),
    "rule")
  expect_match(etr_multilevel_fpca_reporting_text(z$multilevel),
    "80.0% of fitted participant-level variance")
  expect_match(etr_multilevel_fpca_reporting_text(z$multilevel),
    "60.0% of fitted trial-level variance")
})

test_that("Stage 23 reporting inputs fail closed on missing source evidence",{
  z<-.etr23_fixtures()
  x<-z$outlier;x$diagnostics$review_flag[1L]<-NA
  expect_error(etr_fpca_outlier_reporting_text(x),"review_flag")
  x<-z$stability;x$similarities[1L,1L]<-NA_real_
  expect_error(etr_fpca_stability_reporting_text(x),"similarities")
  x<-z$distance;x$comparison_table$spearman_rank_correlation[1L]<-Inf
  expect_error(etr_trajectory_distance_sensitivity_reporting_text(x),
    "Spearman")
  x<-z$influence;x$summary<-x$summary[FALSE,,drop=FALSE]
  expect_error(etr_fpca_influence_reporting_text(x),"summary")
  x<-z$multilevel;x$between$explained_variance_ratio<-Inf
  expect_error(etr_multilevel_fpca_reporting_text(x),"finite")
})

test_that("Stage 23 full 508-census retains unsigned source qualification",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  n<-c("dynamic_time_warping_reporting_text",
    "trajectory_distance_sensitivity_reporting_text",
    "fpca_stability_reporting_text","fpca_outlier_reporting_text",
    "fpca_influence_reporting_text",
    "fpca_subspace_stability_reporting_text",
    "fpca_cross_validation_reporting_text",
    "multilevel_fpca_reporting_text")
  for(x in n){
    a<-z[z$python_name==x & z$is_python_function,,drop=FALSE]
    expect_equal(nrow(a),1L)
    expect_identical(a$native_r_candidate,paste0("etr_",x))
    expect_identical(a$native_implementation_stage,23L)
    expect_false(a$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$native_implementation_started),211L)
  expect_equal(sum(z$named_native_candidate & z$is_python_function),236L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),144L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 23 direct published Python 1.2 reporting oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 text-oracle comparisons are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr23_fixtures()
  types<-reticulate::import("types")
  pd<-reticulate::import("pandas")
  outlier<-types$SimpleNamespace(method=z$outlier$method,
    diagnostics=pd$DataFrame(reticulate::r_to_py(
      list(review_flag=c(FALSE,TRUE,FALSE,TRUE)))))
  py<-reticulate::py_call(
    etpy_get_export("fpca_outlier_reporting_text"),result=outlier)
  expect_identical(etr_fpca_outlier_reporting_text(z$outlier),
    as.character(et_to_r(py)))

  stability<-types$SimpleNamespace(
    similarities=reticulate::r_to_py(z$stability$similarities),
    reference=types$SimpleNamespace(n_components=as.integer(2L)),
    n_bootstrap=as.integer(3L),resampling_unit="curve")
  py<-reticulate::py_call(
    etpy_get_export("fpca_stability_reporting_text"),result=stability)
  expect_identical(etr_fpca_stability_reporting_text(z$stability),
    as.character(et_to_r(py)))

  influence<-types$SimpleNamespace(
    summary=pd$DataFrame(reticulate::r_to_py(
      list(group=c("g1","g2"),
        influence_score=c(.1,.4),
        min_abs_component_similarity=c(.9,.6)))),
    group_column=reticulate::r_to_py(NULL))
  py<-reticulate::py_call(
    etpy_get_export("fpca_influence_reporting_text"),result=influence)
  expect_identical(etr_fpca_influence_reporting_text(z$influence),
    as.character(et_to_r(py)))
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})

test_that("Stage 23 regular nested ALR source sequences preserve 3D geometry", {
  nested<-list(
    list(c(.2,.3,.5),c(.1,.4,.5)),
    list(c(.3,.4,.3),c(.2,.2,.6)))
  array_fixture<-array(NA_real_,c(2L,2L,3L))
  for(i in seq_len(2L))for(j in seq_len(2L))
    array_fixture[i,j,]<-nested[[i]][[j]]
  expect_equal(etr_alr_transform(nested),
    etr_alr_transform(array_fixture),tolerance=0)
  expect_identical(dim(etr_alr_transform(nested)),c(2L,2L,2L))
  expect_error(etr_alr_transform(list(
    list(c(.2,.3,.5)),list(c(.2,.3)))),
    "equal scalar dimensions")
})
