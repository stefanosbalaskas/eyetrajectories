# Stage 15: independent numerical bootstrap estimation and Python source checks.

.etr15_fixture<-function(grouped=TRUE){
  n<-12L;t<-seq(0,1,length.out=11L)
  z<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)){
    z[i,,1L]<-sin(2*pi*t)*(1+i/11)+.05*i*t+
      .04*cos(3*pi*t+i/7)
    z[i,,2L]<-cos(2*pi*t+i/8)+t^2*(i/7)+
      .04*sin(5*pi*t+i/5)
  }
  md<-if(grouped)data.frame(participant_id=rep(
    sprintf("p%02d",seq_len(6L)),each=2L))else NULL
  etr_trajectory_set(t,z,sprintf("c%02d",seq_len(n)),c("x","y"),
    metadata=md,coordinate_system="normalized",time_unit="s")
}

test_that("Stage 15 Gaussian multiplier mean is observed-grid and group-aware",{
  x<-.etr15_fixture()
  set.seed(415);rng<-.Random.seed
  curve<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    confidence_level=.9,random_state=12L)
  expect_identical(.Random.seed,rng)
  expect_s3_class(curve,"etr_functional_mean_band")
  expect_identical(dim(curve$mean),c(11L,2L))
  expect_equal(curve$mean,
    matrix(apply(x$values,c(2L,3L),mean),11,2),tolerance=1e-12)
  expect_equal(curve$pointwise_se,
    matrix(apply(x$values,c(2L,3L),stats::sd),11,2)/sqrt(12),
    tolerance=1e-12)
  expect_equal(length(curve$max_statistics),100L)
  expect_true(all(curve$lower<=curve$mean))
  expect_true(all(curve$upper>=curve$mean))
  expect_true(all(curve$max_statistics>=0))
  same<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    confidence_level=.9,random_state=12L)
  expect_identical(curve$critical_value,same$critical_value)
  expect_equal(curve$critical_value,
    sort(curve$max_statistics)[1L+ceiling(99*.9)],tolerance=0)
  group<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    unit="participant",participant_column="participant_id",random_state=7L)
  expect_equal(length(group$unit_ids),6L)
  expect_true(all(group$curves_per_unit==2L))
  expect_identical(group$unit,"participant")
  bad<-x;bad$coordinate_system<-"probability_simplex"
  expect_error(etr_multiplier_functional_mean_band(bad,n_multiplier=100L),
    "simplex")
  expect_error(etr_multiplier_functional_mean_band(x,n_multiplier=99L),
    "n_multiplier")
})

test_that("Stage 15 score bootstrap refits, projects fixed targets, and sign aligns",{
  x<-.etr15_fixture()
  target<-.etr12_subset(x,c(1L,3L,5L))
  z<-etr_bootstrap_fpca_score_uncertainty(x,targets=target,
    n_bootstrap=20L,n_components=2L,random_state=11L)
  expect_s3_class(z,"etr_fpca_score_uncertainty")
  expect_identical(z$target_curve_ids,target$curve_ids)
  expect_identical(dim(z$bootstrap_scores),c(20L,3L,2L))
  expect_identical(dim(z$reference_scores),c(3L,2L))
  expect_identical(dim(z$assignments),c(20L,2L))
  expect_true(all(z$assignments%in%0:1))
  expect_true(all(z$similarities>=0 & z$similarities<=1+1e-8))
  expect_true(all(z$lower<=z$median & z$median<=z$upper))
  expect_true(all(z$score_se>=0))
  expect_identical(z$target_source,"external")
  expect_equal(z$reference_scores,etr_transform_fpca(z$reference,target),
    tolerance=1e-10)
  tab<-etr_fpca_score_uncertainty_frame(z)
  expect_equal(nrow(tab),6L)
  expect_equal(sort(unique(tab$curve_id)),sort(target$curve_ids))
  again<-etr_bootstrap_fpca_score_uncertainty(x,targets=target,
    n_bootstrap=20L,n_components=2L,random_state=11L)
  expect_identical(z$bootstrap_scores,again$bootstrap_scores)
  gx<-etr_bootstrap_fpca_score_uncertainty(x,n_bootstrap=20L,
    n_components=1L,resample_unit="participant",
    participant_column="participant_id",random_state=10L)
  expect_identical(gx$resampling_unit,"participant")
  bad<-target;bad$time[2L]<-bad$time[2L]+.001
  expect_error(etr_bootstrap_fpca_score_uncertainty(x,bad,
    n_bootstrap=20L,n_components=1L),"time grid")
  expect_error(etr_bootstrap_fpca_score_uncertainty(x,
    n_bootstrap=19L),"n_bootstrap")
})

test_that("Stage 15 spectrum intervals retain shape matching vs ranked cumulative",{
  x<-.etr15_fixture()
  r<-etr_bootstrap_fpca_spectrum_uncertainty(x,
    n_bootstrap=20L,n_components=2L,
    simultaneous_scope="family",random_state=9L)
  expect_s3_class(r,"etr_fpca_spectrum_uncertainty")
  expect_identical(dim(r$bootstrap_eigenvalues),c(20L,2L))
  expect_identical(dim(r$bootstrap_explained_variance_ratio),c(20L,2L))
  expect_identical(dim(r$bootstrap_cumulative_variance_ratio),c(20L,2L))
  expect_identical(dim(r$eigenvalue_max_statistics),c(20L,2L))
  expect_identical(dim(r$assignments),c(20L,2L))
  expect_true(all(r$eigenvalue_upper>=r$eigenvalue_lower))
  expect_true(all(r$explained_variance_ratio_upper>=
                  r$explained_variance_ratio_lower))
  expect_true(all(r$cumulative_variance_ratio_upper>=
                  r$cumulative_variance_ratio_lower))
  expect_equal(length(unique(r$eigenvalue_critical_values)),1L)
  expect_equal(r$bootstrap_cumulative_variance_ratio[,2L],
    rowSums(r$bootstrap_explained_variance_ratio),tolerance=1e-10)
  tab<-etr_fpca_spectrum_uncertainty_frame(r)
  expect_equal(nrow(tab),2L)
  expect_equal(tab$component,1:2)
  expect_error(etr_bootstrap_fpca_spectrum_uncertainty(x,
    n_bootstrap=20L,simultaneous_scope="invalid"),"simultaneous_scope")
})

test_that("Stage 15 component shape bands use signed matching and maxima",{
  x<-.etr15_fixture()
  res<-etr_bootstrap_fpca_component_bands(x,
    n_bootstrap=20L,n_components=2L,confidence_level=.9,
    simultaneous_scope="family",random_state=7L)
  expect_s3_class(res,"etr_fpca_component_band")
  expect_identical(dim(res$lower),c(2L,11L,2L))
  expect_identical(dim(res$pointwise_se),c(2L,11L,2L))
  expect_identical(dim(res$max_statistics),c(20L,2L))
  expect_true(all(res$lower<=res$reference$components+1e-12))
  expect_true(all(res$upper>=res$reference$components-1e-12))
  expect_true(all(res$pointwise_se>=0))
  expect_equal(length(unique(res$critical_values)),1L)
  expect_true(all(res$similarities>=0 & res$similarities<=1+1e-8))
  tab<-etr_fpca_component_band_frame(res)
  expect_equal(nrow(tab),2L*11L*2L)
  expect_identical(names(tab),c("component","time","dimension",
    "reference","pointwise_se","lower","upper"))
  expect_identical(tab$dimension[1L],"x")
  expect_error(etr_bootstrap_fpca_component_bands(x,
    n_bootstrap=20L,relative_gap_threshold=1),"relative_gap_threshold")
  expect_error(etr_bootstrap_fpca_component_bands(x,
    n_bootstrap=20L,on_near_tie="unknown"),"on_near_tie")
})

test_that("Stage 15 frozen 508-source register remains fail-closed",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),154L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),226L)
  expect_equal(sum(z$native_implementation_started),127L)
  expect_equal(sum(z$native_implementation_stage==15L,na.rm=TRUE),5L)
  expect_equal(sum(!is.na(z$native_representation_stage)),7L)
  expect_equal(sum(!z$is_python_function &
    is.na(z$native_representation_stage)),121L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 15 pinned Python 1.2 deterministic reference geometry is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 15 independent Python 1.2 source geometry oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr15_fixture(grouped=FALSE)
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  pymean<-reticulate::py_call(etpy_get_export(
    "multiplier_functional_mean_band"),
    trajectories=pyx,n_multiplier=as.integer(100L),random_state=0L)
  rmean<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,random_state=0L)
  expect_equal(unname(rmean$mean),unname(et_to_r(pymean$mean)),tolerance=1e-10)
  expect_equal(unname(rmean$pointwise_se),
    unname(et_to_r(pymean$pointwise_se)),tolerance=1e-10)
  # R and NumPy generate different multiplier streams; no assertion
  # of identical critical values or finite-replicate bands.
  pyfit<-reticulate::py_call(etpy_get_export("fit_mfpca"),
    trajectories=pyx,n_components=as.integer(2L))
  rfit<-etr_fit_mfpca(x,n_components=2L)
  expect_equal(rfit$explained_variance,
    as.numeric(et_to_r(pyfit$explained_variance)),tolerance=1e-8)
  # Comparisons of random bootstrap replicates are intentionally not
  # source-equivalent under identical numeric seed across languages.
  pyband<-reticulate::py_call(etpy_get_export(
    "bootstrap_fpca_component_bands"),
    trajectories=pyx,n_bootstrap=as.integer(20L),
    n_components=as.integer(2L),random_state=as.integer(1L))
  rband<-etr_bootstrap_fpca_component_bands(x,
    n_bootstrap=20L,n_components=2L,random_state=1L)
  expect_identical(dim(rband$lower),dim(et_to_r(pyband$lower)))
  expect_identical(dim(rband$max_statistics),
    dim(et_to_r(pyband$max_statistics)))
  # Eigenfunction global signs are unidentified across LAPACK backends.
  expect_equal(abs(unname(rband$reference$components)),
    abs(unname(et_to_r(pyband$reference$components))),tolerance=1e-8)
  pframe<-et_to_r(reticulate::py_call(
    etpy_get_export("fpca_component_band_frame"),result=pyband))
  expect_identical(names(etr_fpca_component_band_frame(rband)),names(pframe))
})
