test_that("NumPy group profiles reproduce different tie orders without Python",{
  counts <- c(2L,2L,1L,1L)
  expect_identical(.etr_numpy_group_argsort_simd(counts),4:1)
  expect_identical(.etr_numpy_group_argsort_scalar(counts),c(3L,4L,1L,2L))
  counts <- rep(c(1L,2L,1L,2L),2L)
  expect_identical(.etr_numpy_group_argsort_simd(counts),c(1L,3L,7L,5L,4L,2L,6L,8L))
  expect_identical(.etr_numpy_group_argsort_scalar(counts),c(1L,3L,5L,7L,2L,4L,6L,8L))
  counts <- rep(1L,17L)
  expect_identical(.etr_numpy_group_argsort_simd(counts),seq_along(counts))
  expect_identical(.etr_numpy_group_argsort_scalar(counts),
    c(1L,15L,14L,13L,12L,11L,10L,16L,9L,7L,6L,5L,4L,3L,2L,8L,17L))
  expect_identical(.etr_numpy_group_argsort_simd(rep(1L,300L)),seq_len(300L))
  expect_identical(.etr_numpy_group_argsort_simd(300:1),300:1)
})

test_that("GroupKFold source profiles reach native CV and explicit fold replay",{
  fixture <- .etr_wild_projection_fixture()
  counts <- rep(c(1L,2L,1L,2L),4L)
  fixture$x$metadata$group <- rep(sprintf("P%02d",seq_along(counts)),counts)
  x <- fixture$x
  args <- list(trajectories=x,candidate_components=1:2,n_splits=4L,
    cv_unit="group",group_column="group",shuffle=FALSE)
  before <- reticulate::py_available(initialize=FALSE)
  fitted <- do.call(etr_cross_validate_fpca_reconstruction,
    c(args,list(group_tie_order="numpy_simd")))
  native <- do.call(etr_cross_validate_fpca_reconstruction,args)
  expect_false(identical(fitted$assignments,native$assignments))
  ids <- match(x$curve_ids,fitted$assignments$curve_id)
  expect_identical(fitted$provenance$fold_source,"numpy_simd_groupkfold")
  replay <- do.call(etr_cross_validate_fpca_reconstruction,c(args,list(
    group_tie_order="numpy_scalar",fold_assignments=fitted$assignments$fold[ids])))
  expect_identical(fitted$fold_errors,replay$fold_errors)
  expect_identical(fitted$assignments,replay$assignments)
  expect_identical(replay$provenance$fold_source,"explicit_zero_based_source_replay")
  expect_identical(reticulate::py_available(initialize=FALSE),before)
  expect_true(all(vapply(split(fitted$assignments$fold,fitted$assignments$group),
    function(z)length(unique(z))==1L,logical(1L))))
})

test_that("large tied SIMD cohorts can use declared source folds",{
  counts <- rep(c(2L,1L),150L)
  groups <- rep(sprintf("g%03d",seq_along(counts)),counts)
  x <- list(curve_ids=as.character(seq_along(groups)),
    metadata=data.frame(group=groups))
  expect_error(.etr_cv_fold_assignment(x,3L,"group","group",FALSE,NULL,
    group_tie_order="numpy_simd"),"requires explicit fold_assignments")
  folds <- rep((seq_along(counts)-1L)%%3L,counts)
  replay <- .etr_cv_explicit_fold_assignment(x,3L,"group","group",folds,
    "numpy_simd")
  expect_identical(replay$fold,folds)
  scalar <- .etr_cv_fold_assignment(x,3L,"group","group",FALSE,NULL,
    group_tie_order="numpy_scalar")
  expect_identical(sort(unique(scalar$fold)),0:2)
  expect_true(all(vapply(split(scalar$fold,groups),
    function(z)length(unique(z))==1L,logical(1L))))
})
