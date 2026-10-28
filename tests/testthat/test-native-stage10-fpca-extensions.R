# Stage 10 Python-free analytic tests; pinned Python 1.2 oracle is opt-in.

.etr10_fixture <- function(){
  t<-seq(0,1,length.out=7L)
  n<-6L
  v<-array(0,c(n,length(t),3L))
  for(i in seq_len(n)) {
    v[i,,1L]<-sin(2*pi*t)*(1+i/7)+i*t/10
    v[i,,2L]<-cos(pi*t+i/5)+i*t^2/8
    v[i,,3L]<-t^3*(i/5)+cos(2*pi*t)*i/17
  }
  etr_trajectory_set(t,v,paste0("c",seq_len(n)),c("x","y","z"),
    coordinate_system="normalized",time_unit="s")
}

.etr10_simplex <- function() {
  x<-.etr10_fixture()
  v<-exp(x$values)
  for(i in seq_len(dim(v)[1L]))for(t in seq_len(dim(v)[2L]))
    v[i,t,]<-v[i,t,]/sum(v[i,t,])
  etr_trajectory_set(x$time,v,x$curve_ids,c("AOI1","AOI2","AOI3"),
    coordinate_system="probability_simplex",time_unit="s")
}

test_that("Stage 10 composition FPCA reconstructs into simplex without Python",{
  x<-.etr10_simplex()
  comp<-etr_fit_compositional_fpca(x,reference_dimension=-1L,
    n_components=2L)
  expect_s3_class(comp,"etr_compositional_fpca")
  expect_s3_class(comp$fpca,"etr_fpca")
  expect_equal(comp$reference_dimension,2L)
  expect_identical(comp$fpca$dimension_names,
    c("log(AOI1/AOI3)","log(AOI2/AOI3)"))
  y<-etr_reconstruct_compositional_fpca(comp)
  expect_identical(dim(y),dim(x$values))
  expect_true(all(is.finite(y)))
  expect_true(all(y>0))
  expect_equal(apply(y,c(1L,2L),sum),
    matrix(1,nrow=6L,ncol=7L),tolerance=1e-10)
  other<-etr_reconstruct_compositional_fpca(comp,
    scores=comp$fpca$scores[1L,,drop=FALSE])
  expect_identical(dim(other),c(1L,7L,3L))
  expect_equal(apply(other,c(1L,2L),sum),
    matrix(1,nrow=1L,ncol=7L))
  expect_error(etr_reconstruct_compositional_fpca(comp,
    scores=matrix(1,nrow=1L,ncol=1L),n_components=2L),
    "fewer columns")
  bad<-x;bad$values[1L,1L,1L]<-2
  expect_error(etr_fit_compositional_fpca(bad),"simplex|sum to one")
  two<-etr_trajectory_set(x$time,x$values[,,1:2],
    x$curve_ids,x$dimension_names[1:2])
  expect_error(etr_fit_compositional_fpca(two),"at least three|simplex")
})

test_that("Stage 10 component similarity is sign-aware and matching exact",{
  x<-.etr10_fixture()
  a<-etr_fit_fpca(x,n_components=2L)
  b<-a
  b$components[1L,,]<- -b$components[1L,,]
  b$components[2L,,]<- -b$components[2L,,]
  # Permute candidate components and retained scores consistently.
  b$components<-b$components[c(2L,1L),,,drop=FALSE]
  b$scores<-b$scores[,c(2L,1L),drop=FALSE]
  b$explained_variance<-b$explained_variance[c(2L,1L)]
  b$explained_variance_ratio<-b$explained_variance_ratio[c(2L,1L)]
  sim<-etr_component_similarity_matrix(a,b)
  expect_identical(dim(sim),c(2L,2L))
  expect_equal(sim[1L,2L],-1,tolerance=1e-9)
  expect_equal(sim[2L,1L],-1,tolerance=1e-9)
  match<-etr_match_fpca_components(a,b)
  expect_identical(match$assignments,c(1L,0L))
  expect_equal(match$signed_similarity,c(-1,-1),tolerance=1e-9)
  expect_error(etr_component_similarity_matrix(a,b,3L),"range")
  mismatch<-b;mismatch$time[2L]<-mismatch$time[2L]+.001
  expect_error(etr_component_similarity_matrix(a,mismatch),"time grid")
  mismatch<-b;mismatch$dimension_names<-rev(mismatch$dimension_names)
  expect_error(etr_component_similarity_matrix(a,mismatch),"dimensions")
})

test_that("Stage 10 reconstruction RMSE decreases and respects curve ID order",{
  x<-.etr10_fixture()
  fit<-etr_fit_fpca(x,n_components=3L)
  table<-etr_reconstruction_error_by_curve(fit,x,2L)
  expect_identical(names(table),c("curve_id","n_components","integrated_rmse"))
  expect_identical(table$curve_id,x$curve_ids)
  expect_true(all(is.finite(table$integrated_rmse) &
    table$integrated_rmse>=0))
  expect_true(all(table$n_components==2L))
  curve<-etr_fpca_reconstruction_curve(fit,x)
  expect_identical(names(curve),c("n_components","mean_integrated_rmse",
    "median_integrated_rmse","cumulative_variance_ratio"))
  expect_equal(curve$n_components,1:3)
  expect_true(all(diff(curve$mean_integrated_rmse)<=1e-9))
  expect_true(all(diff(curve$cumulative_variance_ratio)>=-1e-12))
  expect_error(etr_reconstruction_error_by_curve(fit,x,n_components=4L),
    "range")
  bad<-x;bad$curve_ids<-rev(bad$curve_ids)
  expect_error(etr_reconstruction_error_by_curve(fit,bad),"IDs/order")
})

test_that("Stage 10 registered sensitivity and eigengaps are descriptive",{
  x<-.etr10_fixture()
  reg<-etr_register_landmarks(x,
    source_landmarks=matrix(c(.42,.45,.38,.41,.44,.40),ncol=1L),
    target_landmarks=.42)
  fit<-etr_compare_registered_unregistered_fpca(reg,n_components=2L)
  expect_s3_class(fit,"etr_registration_sensitivity")
  tab<-etr_registration_sensitivity_frame(fit)
  expect_identical(names(tab),c("unregistered_component",
    "registered_component","signed_component_similarity",
    "absolute_component_similarity","score_correlation"))
  expect_equal(tab$unregistered_component,1:2)
  expect_equal(sort(tab$registered_component),1:2)
  expect_true(all(tab$absolute_component_similarity>=0 &
    tab$absolute_component_similarity<=1+1e-10))
  expect_true(grepl("Registration sensitivity compared",
    etr_registration_sensitivity_reporting_text(fit),fixed=TRUE))
  a<-fit$unregistered_fpca
  gaps<-etr_fpca_eigenvalue_gap_table(a,relative_gap_threshold=.5)
  expect_equal(nrow(gaps),1L)
  expect_true("near_tie_flag" %in% names(gaps))
  expect_identical(gaps$next_component,2L)
  expect_true(grepl("smallest adjacent retained FPCA eigengap",
    etr_fpca_eigengap_reporting_text(a,.5),fixed=TRUE))
  expect_error(etr_fpca_eigenvalue_gap_table(a,1),"relative_gap_threshold")
  expect_error(etr_fpca_eigenvalue_gap_table(
    etr_fit_fpca(x,n_components=1L)),"At least two")
})

test_that("Stage 10 reporting frames and frozen source inventory",{
  x<-.etr10_fixture()
  fit<-etr_fit_fpca(x,n_components=2L)
  info<-etr_summarise_trajectory_set(x)
  expect_equal(info$n_curves,6L)
  expect_equal(info$n_time,7L)
  expect_equal(info$n_dimensions,3L)
  expect_equal(info$missing_fraction,0)
  expect_identical(info$dimensions,"x, y, z")
  var<-etr_summarise_fpca(fit)
  expect_identical(names(var),c("component","explained_variance",
    "explained_variance_ratio","cumulative_variance_ratio"))
  expect_equal(var$explained_variance,fit$explained_variance)
  expect_true(grepl("Functional PCA retained 2 component(s)",
    etr_fpca_reporting_text(fit),fixed=TRUE))
  t<-c(0,.5,1)
  band<-list(time=t,dimension_names=c("x","y"),
    mean=matrix(1:6,nrow=3L),pointwise_se=matrix(.1,3,2),
    lower=matrix(1:6-.2,nrow=3L),
    upper=matrix(1:6+.2,nrow=3L))
  long<-etr_functional_mean_band_frame(band)
  expect_identical(names(long),
    c("time","dimension","mean","pointwise_se","lower","upper"))
  expect_equal(long$time,rep(t,times=2L))
  expect_equal(long$mean,1:6)
  expect_equal(long$dimension,rep(c("x","y"),each=3L))
  expect_error(etr_functional_mean_band_frame(within(band,lower<-1)),
    "band matrix|invalid")
  census<-etr_native_parity_catalog()
  expect_equal(nrow(census),508L)
  expect_equal(sum(census$is_python_function),380L)
  expect_equal(sum(census$named_native_candidate),107L)
  expect_equal(sum(census$is_python_function & !census$named_native_candidate),273L)
  expect_equal(sum(census$native_implementation_started),77L)
  expect_equal(sum(census$native_implementation_stage==10L,na.rm=TRUE),15L)
  expect_true(all(!census$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
})

test_that("Stage 10 pinned Python 1.2 direct numerical reference is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 10 Python source reference tests are opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")
  x<-.etr10_fixture()
  py<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),dimension_names=as.list(x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  pfit<-reticulate::py_call(etpy_get_export("fit_fpca"),
    trajectories=py,n_components=as.integer(2L))
  rfit<-etr_fit_fpca(x,n_components=2L)
  pinfo<-et_to_r(reticulate::py_call(
    etpy_get_export("summarise_trajectory_set"),trajectories=py))
  expect_identical(names(etr_summarise_trajectory_set(x)),names(pinfo))
  psum<-et_to_r(reticulate::py_call(
    etpy_get_export("summarise_fpca"),result=pfit))
  rsum<-etr_summarise_fpca(rfit)
  expect_identical(names(rsum),names(psum))
  for(n in setdiff(names(rsum),"component"))
    expect_equal(rsum[[n]],as.numeric(psum[[n]]),tolerance=1e-8,info=n)
  pr<-et_to_r(reticulate::py_call(
    etpy_get_export("reconstruction_error_by_curve"),
    result=pfit,trajectories=py,n_components=as.integer(2L)))
  rr<-etr_reconstruction_error_by_curve(rfit,x,2L)
  expect_identical(names(rr),names(pr))
  expect_equal(rr$integrated_rmse,as.numeric(pr$integrated_rmse),tolerance=1e-8)
  pcurve<-et_to_r(reticulate::py_call(
    etpy_get_export("fpca_reconstruction_curve"),result=pfit,trajectories=py))
  rcurve<-etr_fpca_reconstruction_curve(rfit,x)
  for(n in setdiff(names(rcurve),"n_components"))
    expect_equal(rcurve[[n]],as.numeric(pcurve[[n]]),tolerance=1e-8,info=n)
  pcomp<-et_to_r(reticulate::py_call(etpy_get_export(
    "component_similarity_matrix"),reference=pfit,candidate=pfit))
  rcomp<-etr_component_similarity_matrix(rfit,rfit)
  expect_equal(abs(rcomp),abs(pcomp),tolerance=1e-8)
  sm<-etr_match_fpca_components(rfit,rfit)
  expect_identical(sm$assignments,c(0L,1L))
  pm<-reticulate::py_call(etpy_get_export("match_fpca_components"),
    reference=pfit,candidate=pfit)
  # Convert the whole Python tuple before R 1-based list indexing.
  # Indexing the Python tuple directly with [[1L]] selects its SECOND item
  # (signed cosine similarities), not its zero-based assignment vector.
  pm_r<-reticulate::py_to_r(pm)
  expect_identical(length(pm_r),2L)
  expect_equal(as.integer(sm$assignments),
    as.integer(pm_r[[1L]]))
  expect_equal(as.numeric(sm$signed_similarity),
    as.numeric(pm_r[[2L]]),tolerance=1e-8)
  pgap<-et_to_r(reticulate::py_call(etpy_get_export(
    "fpca_eigenvalue_gap_table"),result=pfit,
    relative_gap_threshold=.5))
  rgap<-etr_fpca_eigenvalue_gap_table(rfit,.5)
  expect_identical(names(rgap),names(pgap))
  expect_equal(rgap$relative_gap,as.numeric(pgap$relative_gap),
    tolerance=1e-8)
  ptext<-as.character(et_to_r(reticulate::py_call(etpy_get_export(
    "fpca_reporting_text"),result=pfit,digits=as.integer(1L))))
  expect_identical(etr_fpca_reporting_text(rfit,digits=1L),ptext)
  s<-.etr10_simplex()
  ps<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(s$time),values=reticulate::r_to_py(s$values),
    curve_ids=as.list(s$curve_ids),dimension_names=as.list(s$dimension_names),
    coordinate_system="probability_simplex",time_unit="s")
  pcf<-reticulate::py_call(etpy_get_export("fit_compositional_fpca"),
    trajectories=ps,n_components=as.integer(2L))
  rcf<-etr_fit_compositional_fpca(s,n_components=2L)
  pvals<-et_to_r(reticulate::py_call(
    etpy_get_export("reconstruct_compositional_fpca"),result=pcf))
  expect_equal(etr_reconstruct_compositional_fpca(rcf),pvals,tolerance=1e-8)
  # Matching component orientations are allowed to differ by sign; no
  # raw eigenvector-sign equality is required.
})
