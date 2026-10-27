# Stage 9: deterministic native R tests and opt-in pinned Python source oracle.
# No Python is called unless ET_RUN_PYTHON_TESTS is explicitly true.

.etr9_fixture <- function() {
  t<-c(0,1,2,3,4)
  v<-array(0,c(4L,length(t),2L))
  for(i in 1:4) {
    v[i,,1L]<-sin(t/2+i/3)+i*t/11
    v[i,,2L]<-cos(t/3+i/4)-i*t^2/33
  }
  etr_trajectory_set(t,v,paste0("c",1:4),c("x","y"),
    coordinate_system="pixels",time_unit="s")
}

test_that("Stage 9 ALR and inverse preserve the declared simplex",{
  v<-array(0,c(2L,4L,3L))
  for(i in 1:2)for(j in 1:4)
    v[i,j,]<-c(.2+.02*i,.3+.01*j,.5-.02*i-.01*j)
  z<-etr_alr_transform(v,reference_dimension=-1L)
  expect_identical(dim(z),c(2L,4L,2L))
  recovered<-etr_inverse_alr(z,reference_dimension=-1L,n_dimensions=3L)
  expect_equal(recovered,v,tolerance=1e-12)
  z1<-etr_alr_transform(v,reference_dimension=1L)
  expect_equal(etr_inverse_alr(z1,1L,3L),v,tolerance=1e-12)
  with_zero<-v;with_zero[1L,1L,]<-c(0,.3,.7)
  zz<-etr_alr_transform(with_zero,epsilon=1e-6)
  back<-etr_inverse_alr(zz,-1L,3L)
  expect_true(all(is.finite(back)))
  expect_equal(sum(back[1L,1L,]),1)
  expect_gt(back[1L,1L,1L],0)
  expect_error(etr_alr_transform(v,epsilon=0),"epsilon")
  expect_error(etr_alr_transform(v,epsilon=Inf),"epsilon")
  expect_error(etr_inverse_alr(z,0L,4L),"dimensions")
  expect_error(etr_inverse_alr(z*Inf,-1L,3L),"nonfinite")
  expect_error(etr_alr_transform(array(1,c(2,4,1))),"simplex|dimensions")
})

test_that("Stage 9 FPCA component curves, selection, score frames and distances",{
  x<-.etr9_fixture()
  fit<-etr_fit_fpca(x,n_components=2L)
  expect_s3_class(fit,"etr_fpca")
  expect_equal(etr_select_n_components(fit,threshold=.01),1L)
  expected<-which(cumsum(fit$explained_variance_ratio)>=.9)
  target<-if(length(expected))expected[1L] else fit$n_components+1L
  expect_equal(etr_select_n_components(fit,threshold=.9),as.integer(target))
  expect_error(etr_select_n_components(fit,threshold=0),"threshold")
  tr<-etr_component_trajectories(fit,component=0L,sd_multipliers=c(-1,0,1))
  expect_identical(dim(tr),c(3L,5L,2L))
  expect_equal(tr[2L,,],fit$mean)
  expect_equal(tr[3L,,]-fit$mean,fit$mean-tr[1L,,],tolerance=1e-12)
  expect_error(etr_component_trajectories(fit,component=2L),"range")
  sf<-etr_fpca_score_frame(fit,prefix="PC")
  expect_identical(names(sf),c("curve_id","PC1","PC2"))
  expect_identical(sf$curve_id,x$curve_ids)
  expect_equal(as.matrix(sf[,2:3]),fit$scores,ignore_attr=TRUE)
  distances<-etr_score_distance_matrix(fit)
  expect_equal(diag(distances),rep(0,4))
  expect_equal(distances,t(distances))
  expect_equal(distances[1L,2L],sqrt(sum((fit$scores[1L,]-
    fit$scores[2L,])^2)),tolerance=1e-12)
  expect_error(etr_score_distance_matrix(fit,n_components=3L),"range")
  d<-etr_pairwise_functional_distances(x)
  expect_equal(d,t(d))
  expect_equal(diag(d),rep(0,4))
  expect_true(is.null(dimnames(d)))
  expect_equal(d[1L,2L],
    etr_l2_distance(.etr_curve(x,1L),.etr_curve(x,2L),x$time))
  y<-x;y$values[1L,2L,1L]<-NA_real_
  expect_error(etr_pairwise_functional_distances(y),"complete")
})

test_that("Stage 9 sparse dimensional support preserves missingness",{
  t<-list(c(0,1,2,4),c(.3,.7,2.1))
  v<-list(matrix(c(1,2,NA,4,1,2,3,4),ncol=2L),
          matrix(c(NA,2,3,1,1,2),ncol=2L))
  x<-etr_irregular_trajectory_set(t,v,c("a","b"),c("x","y"))
  tab<-etr_sparse_dimension_summary(x,"x")
  expect_identical(names(tab),c("curve_id","n_sample_times",
    "n_observed","n_nonfinite","observed_fraction","time_start",
    "time_end","time_span","median_observed_interval",
    "max_observed_interval"))
  expect_equal(tab$n_observed,c(3L,2L))
  expect_equal(tab$n_nonfinite,c(1L,1L))
  expect_equal(tab$median_observed_interval,c(2,1.4),tolerance=1e-12)
  expect_error(etr_sparse_dimension_summary(x,"unknown"),"Unknown")
})

test_that("Stage 9 phase displacement is explicit and not an inverse warp",{
  x<-.etr9_fixture();t<-x$time
  w<-rbind(t,t+c(0,.1,.2,.1,0),t+c(0,-.1,-.2,-.1,0),
            t+c(0,.06,-.04,.08,0))
  reg<-list(original=x,warping_functions=w,method="declared_fixture",
            provenance=list(source="analytic"))
  delta<-etr_warping_displacement(reg)
  expect_equal(delta,w-matrix(t,nrow=4L,ncol=5L,byrow=TRUE))
  summary<-etr_phase_summary(reg)
  expect_equal(summary$mean_absolute_displacement,rowMeans(abs(delta)))
  expect_equal(summary$max_absolute_displacement,apply(abs(delta),1L,max))
  expect_equal(summary$signed_mean_displacement,rowMeans(delta))
  p<-etr_phase_trajectory_set(reg)
  expect_s3_class(p,"etr_trajectory_set")
  expect_equal(p$values[,,1L],delta)
  expect_identical(p$coordinate_system,"phase_time")
  expect_identical(p$dimension_names,"phase_displacement")
  expect_false(is.null(p$provenance$registration_method))
  expect_equal(etr_phase_trajectory_set(reg,"warping")$values[,,1L],w)
  expect_s3_class(etr_fit_phase_fpca(reg,n_components=1L),"etr_fpca")
  expect_error(etr_phase_trajectory_set(reg,"invalid"),"representation")
  joined<-etr_register_landmarks(x,
    source_landmarks=matrix(c(2.0,2.1,1.9,2.05),ncol=1L),
    target_landmarks=2.0)
  expect_s3_class(joined,"etr_landmark_registration")
  expect_equal(joined$warping_functions,joined$inverse_warps)
  expect_identical(joined$original$curve_ids,x$curve_ids)
  expect_equal(etr_warping_displacement(joined),
    sweep(joined$inverse_warps,2L,t,"-"))
  expect_equal(dim(etr_phase_trajectory_set(joined)$values),c(4L,5L,1L))
  bad<-reg;bad$warping_functions[2L,2L]<-99
  expect_error(etr_warping_displacement(bad),"increasing")
})

test_that("Stage 9 frozen 508 source register counts only native implementations",{
  before<-reticulate::py_available(initialize=FALSE)
  x<-etr_native_parity_catalog()
  want<-c(
    alr_transform="etr_alr_transform",inverse_alr="etr_inverse_alr",
    component_trajectories="etr_component_trajectories",
    select_n_components="etr_select_n_components",
    fpca_score_frame="etr_fpca_score_frame",
    score_distance_matrix="etr_score_distance_matrix",
    pairwise_functional_distances="etr_pairwise_functional_distances",
    sparse_dimension_summary="etr_sparse_dimension_summary",
    warping_displacement="etr_warping_displacement",
    phase_summary="etr_phase_summary",
    phase_trajectory_set="etr_phase_trajectory_set",
    fit_phase_fpca="etr_fit_phase_fpca")
  expect_equal(nrow(x),508L)
  expect_equal(sum(x$is_python_function),380L)
  expect_equal(sum(x$named_native_candidate),77L)
  expect_equal(sum(x$is_python_function & !x$named_native_candidate),303L)
  expect_equal(sum(x$native_implementation_started),47L)
  expect_equal(sum(x$native_implementation_stage==9L,na.rm=TRUE),12L)
  for (n in names(want)) {
    one<-x[x$namespace=="root" & x$python_name==n,,drop=FALSE]
    expect_equal(nrow(one),1L)
    expect_identical(one$native_r_candidate,unname(want[[n]]))
    expect_identical(one$native_implementation_stage,9L)
    expect_false(one$one_to_one_native_contract_complete)
  }
  expect_equal(sum(!is.na(x$native_representation_stage)),7L)
  expect_true(all(!x$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 9 source-level Python 1.2 numeric oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 9 pinned Python numerical oracle is opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")
  x<-.etr9_fixture()
  v<-array(0,c(3L,4L,3L))
  for(i in 1:3)for(j in 1:4)v[i,j,]<-c(.2+.01*i,.3+.01*j,
                                          .5-.01*i-.01*j)
  py_alr<-etpy_get_export("alr_transform")
  py_ialr<-etpy_get_export("inverse_alr")
  pz<-reticulate::py_call(py_alr,values=reticulate::r_to_py(v),
       reference_dimension=as.integer(-1L),epsilon=1e-8)
  rz<-etr_alr_transform(v)
  expect_equal(rz,et_to_r(pz),tolerance=1e-10)
  py_back<-reticulate::py_call(py_ialr,transformed=pz,
       reference_dimension=as.integer(-1L),n_dimensions=as.integer(3L))
  expect_equal(etr_inverse_alr(rz,-1L,3L),et_to_r(py_back),
               tolerance=1e-10)
  constructor<-etpy_get_export("TrajectorySet")
  px<-reticulate::py_call(constructor,time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="pixels",time_unit="s")
  py_pair<-etpy_get_export("pairwise_functional_distances")
  expect_equal(etr_pairwise_functional_distances(x),
    et_to_r(reticulate::py_call(py_pair,trajectories=px)),tolerance=1e-9)
  fpca_py<-reticulate::py_call(etpy_get_export("fit_fpca"),
    trajectories=px,n_components=as.integer(2L))
  fit<-etr_fit_fpca(x,n_components=2L)
  np_score_dist<-reticulate::py_call(etpy_get_export("score_distance_matrix"),
    fpca=fpca_py,n_components=as.integer(2L))
  expect_equal(etr_score_distance_matrix(fit),et_to_r(np_score_dist),
               tolerance=1e-8)
  py_n<-reticulate::py_call(etpy_get_export("select_n_components"),
    result=fpca_py,threshold=.25)
  expect_equal(etr_select_n_components(fit,threshold=.25),
    as.integer(et_to_r(py_n)))
  py_curves<-reticulate::py_call(etpy_get_export("component_trajectories"),
    result=fpca_py,component=as.integer(0L),
    sd_multipliers=as.list(c(-1,0,1)))
  nc<-etr_component_trajectories(fit,0L,c(-1,0,1))
  pc<-et_to_r(py_curves)
  expect_equal(nc[2L,,],pc[2L,,],tolerance=1e-8)
  expect_equal(abs(nc[3L,,]-nc[2L,,]),
               abs(pc[3L,,]-pc[2L,,]),tolerance=1e-8)
  py_score_frame<-et_to_r(reticulate::py_call(
    etpy_get_export("fpca_score_frame"),result=fpca_py,prefix="Z"))
  native_frame<-etr_fpca_score_frame(fit,prefix="Z")
  expect_identical(names(native_frame),names(py_score_frame))
  expect_identical(as.character(native_frame$curve_id),
                   as.character(py_score_frame$curve_id))
  expect_equal(abs(as.matrix(native_frame[,-1L])),
               abs(as.matrix(py_score_frame[,-1L])),tolerance=1e-8)
  # Irregular single-dimension support: exact source schema and values.
  ir<-etr_irregular_trajectory_set(
    list(c(0,1,2,4),c(.3,.7,2.1)),
    list(matrix(c(1,NA,3,5,10,11,12,13),ncol=2L),
         matrix(c(2,4,6,9,8,7),ncol=2L)),
    c("a","b"),c("x","y"))
  pir<-reticulate::py_call(etpy_get_export("IrregularTrajectorySet"),
    time=lapply(ir$time,reticulate::r_to_py),
    values=lapply(ir$values,reticulate::r_to_py),
    curve_ids=as.list(ir$curve_ids),
    dimension_names=as.list(ir$dimension_names))
  ir_tab<-etr_sparse_dimension_summary(ir,"x")
  py_ir_tab<-et_to_r(reticulate::py_call(
    etpy_get_export("sparse_dimension_summary"),
    trajectories=pir,dimension="x"))
  expect_identical(names(ir_tab),names(py_ir_tab))
  expect_equal(as.character(ir_tab$curve_id),as.character(py_ir_tab$curve_id))
  for(col in setdiff(names(ir_tab),"curve_id"))
    expect_equal(as.numeric(ir_tab[[col]]),as.numeric(py_ir_tab[[col]]),
      tolerance=1e-10,info=paste("sparse",col))

  # Registration is specified with source/reference orientation h_i(t).
  t<-x$time
  w<-rbind(t,t+c(0,.1,.2,.1,0),t+c(0,-.1,-.2,-.1,0),
            t+c(0,.06,-.04,.08,0))
  reg<-list(original=x,warping_functions=w,
    method="declared_fixture",provenance=list(source="oracle"))
  pyreg<-reticulate::py_call(etpy_get_export("RegistrationResult"),
    registered=px,original=px,
    warping_functions=reticulate::r_to_py(w),
    reference_landmarks=reticulate::r_to_py(c(2)),
    observed_landmarks=reticulate::r_to_py(
      matrix(c(2,2.1,1.9,2),ncol=1L)),
    method="declared_fixture")
  expect_equal(etr_warping_displacement(reg),
    et_to_r(reticulate::py_call(etpy_get_export("warping_displacement"),
      result=pyreg)),tolerance=1e-10)
  ps<-et_to_r(reticulate::py_call(etpy_get_export("phase_summary"),
                                result=pyreg))
  rs<-etr_phase_summary(reg)
  expect_identical(names(rs),names(ps))
  for(field in names(rs))
    expect_equal(as.numeric(rs[[field]]),as.numeric(ps[[field]]),
                 tolerance=1e-10,info=field)
  pyphase<-reticulate::py_call(etpy_get_export("phase_trajectory_set"),
    registration=pyreg,representation="displacement")
  rphase<-etr_phase_trajectory_set(reg,"displacement")
  expect_equal(rphase$values,et_to_r(pyphase$values),tolerance=1e-10)
  fit_phase_py<-reticulate::py_call(etpy_get_export("fit_phase_fpca"),
    registration=pyreg,n_components=as.integer(1L))
  fit_phase_r<-etr_fit_phase_fpca(reg,n_components=1L)
  expect_equal(fit_phase_r$mean,et_to_r(fit_phase_py$mean),
               tolerance=1e-8)
  expect_equal(fit_phase_r$explained_variance,
               as.numeric(et_to_r(fit_phase_py$explained_variance)),
               tolerance=1e-8)
  expect_equal(abs(fit_phase_r$scores),abs(et_to_r(fit_phase_py$scores)),
               tolerance=1e-8)

})
