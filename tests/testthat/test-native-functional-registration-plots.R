# Stable public API. Stage numbers are retained only in audit filenames
# and historical verification labels, never in exported function names.

.etr_test_registration_plot_fixture <- function() {
  time<-as.numeric(0:6)
  values<-array(0,c(2L,length(time),1L))
  values[1L,,1L]<-sin(time/3)
  values[2L,,1L]<-cos(time/3)
  x<-etr_trajectory_set(time,values,
    curve_ids=c("a","b"),dimension_names="x",
    coordinate_system="arbitrary",time_unit="s")
  etr_register_landmarks(x,
    source_landmarks=matrix(c(2,4),nrow=2L,ncol=1L),
    target_landmarks=3)
}
.etr_test_registration_plot_pdf <- function(f) {
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  f()
}
test_that("stable public API has no exposed stage prefixes or numbered helpers",{
  for(n in c("etr_plot_reconstruction_curve","etr_plot_registration",
    "etr_plot_warping_functions"))
    expect_true(is.function(get(n,mode="function")))
  exports<-getNamespaceExports("eyetrajectories")
  expect_false(any(grepl("stage[0-9]+|etr[0-9]+_",exports,
    ignore.case=TRUE)))
  expect_false(any(grepl("^\\.etr(24|26|27|28|29)_",
    ls(envir=asNamespace("eyetrajectories"),all.names=TRUE))))
})

test_that("reconstruction curve faithfully plots original unsorted scientific rows",{
  tab<-data.frame(n_components=c(3L,1L,2L),
    mean_integrated_rmse=c(.3,.9,.5))
  .etr_test_registration_plot_pdf(function(){
    d<-etr_plot_reconstruction_curve(tab)
    expect_identical(d$n_components,tab$n_components)
    expect_identical(d$mean_integrated_rmse,tab$mean_integrated_rmse)
    expect_error(etr_plot_reconstruction_curve(tab[,1L,drop=FALSE]),
      "must contain")
    bad<-tab;bad$mean_integrated_rmse[1L]<-NA_real_
    expect_error(etr_plot_reconstruction_curve(bad),"finite")
  })
})

test_that("registration source plot retains exact original and registered values",{
  z<-.etr_test_registration_plot_fixture()
  .etr_test_registration_plot_pdf(function(){
    d<-etr_plot_registration(z,dimension="x",max_curves=2L)
    expect_identical(d$curve_ids,c("a","b"))
    expect_equal(nrow(d$original),14L)
    expect_equal(nrow(d$registered),14L)
    expect_equal(d$original$value[1:7],as.numeric(z$original$values[1L,,1L]))
    expect_equal(d$registered$value[8:14],
      as.numeric(z$registered$values[2L,,1L]))
    one<-etr_plot_registration(z,dimension="x",max_curves=1L)
    expect_equal(nrow(one$original),7L)
    expect_error(etr_plot_registration(z,dimension="z"),"dimension")
    expect_error(etr_plot_registration(z,max_curves=0L),"max_curves")
  })
})

test_that("warping plots preserve complete source and identity displacement",{
  z<-.etr_test_registration_plot_fixture()
  .etr_test_registration_plot_pdf(function(){
    a<-etr_plot_warping_functions(z,displacement=FALSE)
    b<-etr_plot_warping_functions(z,displacement=TRUE)
    expect_equal(nrow(a),14L)
    expect_equal(a$value[1:7],as.numeric(z$warping_functions[1L,]))
    expect_equal(b$value,a$value-a$time,tolerance=1e-14)
    expect_equal(b$value[1L],0)
    expect_equal(b$value[7L],0)
    expect_error(etr_plot_warping_functions(z,displacement=1L),
      "displacement")
  })
})

test_that("three real published Python names added to strict 508-export inventory",{
  catalog<-etr_native_parity_catalog()
  funcs<-c("plot_reconstruction_curve","plot_registration",
    "plot_warping_functions")
  for(fn in funcs){
    row<-catalog[catalog$python_name==fn&
      catalog$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",fn))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(catalog),508L)
  expect_equal(sum(catalog$is_python_function),380L)
  expect_equal(sum(catalog$named_native_candidate&
    catalog$is_python_function),232L)
  expect_equal(sum(catalog$native_implementation_started),207L)
  expect_equal(sum(catalog$is_python_function&
    !catalog$named_native_candidate),148L)
  expect_equal(sum(catalog$source_contract_gap_unresolved),53L)
  expect_equal(sum(catalog$one_to_one_native_contract_complete),0L)
})

test_that("direct published Python 1.2 reconstruction and warp geometry is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 reconstruction/registration geometry is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  plt<-reticulate::import("matplotlib.pyplot")
  pd<-reticulate::import("pandas")
  types<-reticulate::import("types")
  on.exit(plt$close("all"),add=TRUE)
  summary<-data.frame(n_components=c(3L,1L,2L),
    mean_integrated_rmse=c(.3,.9,.5))
  py_frame<-pd$DataFrame(reticulate::r_to_py(as.list(summary)))
  ax<-reticulate::py_call(etpy_get_export("plot_reconstruction_curve"),
    reconstruction_summary=py_frame)
  source_xy<-as.matrix(et_to_r(ax$lines[[0L]]$get_xydata()))
  .etr_test_registration_plot_pdf(function(){
    ours<-etr_plot_reconstruction_curve(summary)
    expect_equal(as.numeric(ours$n_components),source_xy[,1L],tolerance=0)
    expect_equal(ours$mean_integrated_rmse,source_xy[,2L],tolerance=0)
  })
  reg<-.etr_test_registration_plot_fixture()
  source_original<-types$SimpleNamespace(
    time=reticulate::r_to_py(reg$original$time),
    time_unit=reg$original$time_unit,
    dimension_names=reticulate::r_to_py(as.list(reg$original$dimension_names)),
    n_curves=as.integer(2L),
    values=reticulate::r_to_py(reg$original$values))
  source_registered<-types$SimpleNamespace(
    time=reticulate::r_to_py(reg$registered$time),
    values=reticulate::r_to_py(reg$registered$values))
  py_reg<-types$SimpleNamespace(original=source_original,
    registered=source_registered,
    warping_functions=reticulate::r_to_py(reg$warping_functions))
  py_ax<-reticulate::py_call(etpy_get_export("plot_warping_functions"),
    result=py_reg)
  expect_equal(as.integer(reticulate::py_len(py_ax$lines)),3L)
  for(i in 0:1){
    source_warp<-as.matrix(et_to_r(py_ax$lines[[as.integer(i)]]$get_xydata()))
    expect_equal(source_warp[,1L],reg$original$time,tolerance=0)
    expect_equal(source_warp[,2L],
      as.numeric(reg$warping_functions[i+1L,]),tolerance=0)
  }
  .etr_test_registration_plot_pdf(function(){
    ours<-etr_plot_warping_functions(reg)
    expect_equal(ours$value,
      as.vector(t(reg$warping_functions)),tolerance=0)
  })
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})
