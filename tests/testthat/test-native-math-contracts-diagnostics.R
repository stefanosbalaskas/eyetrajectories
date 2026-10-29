# Stage 28: complete source Python 1.2 mathematical metadata and native
# nonlinear sensitivity visualization tests (public source approvals stay false).
.etr_test_nonlinear_diagnostic_pdf<-function(f){
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  f()
}
.etr_test_nonlinear_sensitivity_fixture<-function(kind) {
  t<-data.frame(embedding_dimension=c(2,3,4),
    requested_delay=c(1,1,1),exponent=c(.12,.25,.17),
    r_squared=c(.65,.78,.72),standard_error=c(.05,.04,.05))
  structure(list(table=t,
    curve_id="curve_1",exponent_unit="1/s"),
    class=kind)
}
.etr_test_window_rqa_plot_fixture<-function(){
  a<-function(time,v,w,s){
    values<-array(NA_real_,c(2L,length(time),1L))
    values[1L,,1L]<-v
    values[2L,,1L]<-v+.1
    tr<-list(curve_ids=c("a","b"),dimension_names="recurrence_rate",
      time=time,values=values)
    list(trajectories=tr,window_samples=w,step_samples=s,time_unit="s")
  }
  structure(list(analyses=list(
    a(c(2,4,6),c(.2,.3,.4),5L,2L),
    a(c(3,6,9),c(.25,.4,.5),7L,3L)),
    metrics="recurrence_rate",
    provenance=list(specification_ids=c("spec_1","spec_2"))),
    class="etr_windowed_rqa_sensitivity")
}
test_that("published 41-contract registry retains every 88 API row",{
  frame<-etr_mathematical_contract_frame()
  contracts<-etr_list_mathematical_contracts()
  expect_equal(nrow(frame),88L)
  expect_identical(names(frame),
    c("contract_key","title","function","latex","site_anchor","scope"))
  expect_length(contracts,41L)
  expect_identical(names(contracts),unique(frame$contract_key))
  expect_false(anyDuplicated(frame[["function"]])>0L)
  expect_identical(frame$contract_key[1L],"quadrature")
  expect_identical(contracts[[1L]]$public_api,
    "functional_trapezoid_weights")
  expect_identical(contracts[[4L]]$key,"sparse-mfpca-joint-pace")
  expect_identical(etr_get_mathematical_contract("fit_sparse_mfpca")$key,
    "sparse-mfpca-joint-pace")
  expect_identical(etr_get_mathematical_contract("quadrature")$key,
    "quadrature")
  expect_match(frame$latex[1L],"w_1=")
  expect_match(frame$scope[1L],"observed grids")
  expect_true(all(vapply(contracts,function(z)
    inherits(z,"etr_mathematical_contract")&&
      length(z$equations)>=1L&&all(nzchar(z$equations)),
    logical(1L))))
  expect_error(etr_get_mathematical_contract("nonexistent"),
    "No mathematical contract")
  expect_error(etr_get_mathematical_contract(1L),
    "single string")
})

test_that("Kantz and Rosenstein require unambiguous full-grid slices",{
  k<-.etr_test_nonlinear_sensitivity_fixture("etr_kantz_parameter_sensitivity")
  lle<-.etr_test_nonlinear_sensitivity_fixture("etr_lyapunov_parameter_sensitivity")
  .etr_test_nonlinear_diagnostic_pdf(function(){
    a<-etr_plot_kantz_sensitivity(k,parameter="embedding_dimension")
    expect_equal(a$embedding_dimension,c(2,3,4))
    expect_equal(a$exponent,c(.12,.25,.17))
    b<-etr_plot_lyapunov_sensitivity(lle,parameter="embedding_dimension",
      response="r_squared")
    expect_equal(b$r_squared,c(.65,.78,.72))
    expect_error(etr_plot_kantz_sensitivity(k,
      parameter="missing"),"parameter")
    expect_error(etr_plot_lyapunov_sensitivity(lle,
      parameter="embedding_dimension",response="improper"),
      "response")
    d<-k
    d$table<-rbind(d$table,d$table[1L,,drop=FALSE])
    d$table$requested_delay[4L]<-2
    expect_error(etr_plot_kantz_sensitivity(d,
      parameter="embedding_dimension"),"multiple rows")
    filt<-etr_plot_kantz_sensitivity(d,
      parameter="embedding_dimension",
      filters=list(requested_delay=1))
    expect_equal(nrow(filt),3L)
    expect_error(etr_plot_kantz_sensitivity(d,
      parameter="embedding_dimension",
      filters=list(requested_delay=99)),
      "no sensitivity specifications")
  })
})

test_that("windowed RQA plot preserves every declared center grid",{
  x<-.etr_test_window_rqa_plot_fixture()
  .etr_test_nonlinear_diagnostic_pdf(function(){
    a<-etr_plot_windowed_rqa_sensitivity(x,curve="a",
      metric="recurrence_rate")
    expect_equal(length(a),2L)
    expect_equal(a[[1L]]$time,c(2,4,6))
    expect_equal(a[[2L]]$time,c(3,6,9))
    expect_equal(a[[1L]]$window,rep(5,3))
    expect_equal(a[[2L]]$step,rep(3,3))
    expect_equal(a[[1L]]$value,c(.2,.3,.4))
    b<-etr_plot_windowed_rqa_sensitivity(x,curve=0L,
      metric="recurrence_rate")
    expect_equal(a,b)
    expect_error(etr_plot_windowed_rqa_sensitivity(x,
      curve=2L,metric="recurrence_rate"),"zero-based")
    expect_error(etr_plot_windowed_rqa_sensitivity(x,
      curve="missing",metric="recurrence_rate"),"curve_id")
    expect_error(etr_plot_windowed_rqa_sensitivity(x,
      curve="a",metric="missing"),"metric")
  })
})

test_that("508-source census remains strict and unsigned",{
  z<-etr_native_parity_catalog()
  names<-c("list_mathematical_contracts",
    "get_mathematical_contract","mathematical_contract_frame",
    "plot_kantz_sensitivity","plot_lyapunov_sensitivity",
    "plot_windowed_rqa_sensitivity")
  for(name in names){
    row<-z[z$python_name==name&z$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",name))
    expect_identical(row$native_implementation_stage,28L)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_gte(sum(z$named_native_candidate&z$is_python_function),236L)
  expect_gte(sum(z$native_implementation_started),211L)
  expect_lte(sum(z$is_python_function&!z$named_native_candidate),144L)
  expect_gte(sum(z$source_contract_gap_unresolved),57L)
  expect_equal(sum(z$contract_certification_candidate),4L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})

test_that("full 88-row published Python 1.2 source oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 complete mathematical source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fn<-etpy_get_export("mathematical_contract_frame")
  original<-as.data.frame(et_to_r(reticulate::py_call(fn)),
    stringsAsFactors=FALSE)
  native<-etr_mathematical_contract_frame()
  expect_equal(nrow(original),88L)
  expect_identical(names(native),names(original))
  for(col in names(native))
    expect_identical(enc2utf8(as.character(native[[col]])),
      enc2utf8(as.character(original[[col]])),
      info=paste("Published source mismatch in contract field",col))
  pylist<-reticulate::py_call(
    etpy_get_export("list_mathematical_contracts"))
  expect_equal(as.integer(reticulate::py_len(pylist)),41L)
  local<-etr_list_mathematical_contracts()
  for(i in seq_len(41L)){
    obj<-pylist[[as.integer(i-1L)]]
    expect_identical(local[[i]]$key,as.character(et_to_r(obj$key)))
    expect_identical(local[[i]]$title,as.character(et_to_r(obj$title)))
    expect_identical(local[[i]]$public_api,
      as.character(et_to_r(obj$public_api)))
    expect_identical(local[[i]]$equations,
      as.character(et_to_r(obj$equations)))
    expect_identical(local[[i]]$site_anchor,
      as.character(et_to_r(obj$site_anchor)))
    expect_identical(local[[i]]$scope,as.character(et_to_r(obj$scope)))
  }
  pyget<-reticulate::py_call(
    etpy_get_export("get_mathematical_contract"),
    name="fit_sparse_mfpca")
  expect_identical(
    etr_get_mathematical_contract("fit_sparse_mfpca")$key,
    as.character(et_to_r(pyget$key)))
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})
