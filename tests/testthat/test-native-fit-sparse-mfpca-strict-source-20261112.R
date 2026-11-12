# Frozen eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Direct source reference: types.py::SparseMFPCAResult,
# sparse_multivariate.py::fit_sparse_mfpca.  No Python class impersonation.

.etr_sparse_mfpca_expected_source_fields<-c(
  "scores","eigenvalues","eigenfunctions","mean",
  "evaluation_grid","dimensions","curve_ids","metadata",
  "coordinate_system","time_unit","n_components",
  "quadrature_weights","smoothed_cxx","smoothed_cxy",
  "smoothed_cyx","smoothed_cyy","covariance_cxx",
  "covariance_cxy","covariance_cyx","covariance_cyy",
  "measurement_error_covariance","score_diagnostics",
  "mean_support_counts","covariance_support_counts",
  "covariance_pair_counts","covariance_diagnostics",
  "fit_method","score_method","provenance")

test_that("strict public sparse MFPCA emits 29 frozen Python source-scientific fields",{
  x<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  native<-do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="native_covariance"),args))
  strict<-do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="native_covariance",
      strict_source_record=TRUE),args))
  expect_s3_class(strict,"etr_sparse_mfpca_w2_scientific_record")
  expect_identical(names(strict),.etr_sparse_mfpca_expected_source_fields)
  expect_identical(names(strict),.etr_sparse_mfpca_w2_fields)
  expect_identical(strict$fit_method,"direct_sparse_block_covariance")
  expect_identical(strict$score_method,"joint_PACE")
  expect_identical(dim(strict$scores),c(24L,2L))
  expect_identical(dim(strict$mean),c(9L,2L))
  expect_identical(dim(strict$eigenfunctions),c(2L,9L,2L))
  expect_identical(length(strict$curve_ids),24L)
  expect_false("joint_scores"%in%names(strict))
  expect_false("source_python_full_contract_equivalent"%in%names(strict))
  expect_false("independently_fully_certified"%in%names(strict))
  for(field in names(strict))
    expect_identical(strict[[field]],native[[field]],
      info=paste("source scientific field",field))
  expect_true("joint_scores"%in%names(native))
  expect_false(native$independently_fully_certified)
  expect_false(native$source_python_full_contract_equivalent)
})

test_that("strict public sparse MFPCA refuses undeclared source and R-only controls",{
  x<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  call<-function(overrides=list(),fields=args){
    do.call(etr_fit_sparse_mfpca,c(
      list(trajectories=x,backend="native_covariance",
        strict_source_record=TRUE),fields,overrides))
  }
  expect_error(do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="native_covariance",
      strict_source_record=1L),args)),
    "strict_source_record")
  expect_error(do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="fdapace_joint_score_pca",
      strict_source_record=TRUE),args)),
    "native_covariance")
  invalid<-args;invalid$n_components<-NULL
  expect_error(call(fields=invalid),"mandatory")
  invalid<-args;invalid$measurement_error<-NULL
  expect_error(call(fields=invalid),"mandatory")
  expect_error(do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="native_covariance",
      strict_source_record=TRUE,max_marginal_components=4L),args)),
    "R-only marginal")
  expect_error(do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="native_covariance",
      strict_source_record=TRUE,options=list(bad=1)),args)),
    "R-only marginal")
  invalid<-args;invalid$n_components<-TRUE
  expect_error(call(fields=invalid),"n_components")
  invalid<-args;invalid$measurement_error_variance<-c(.07,-.01)
  expect_error(call(fields=invalid),"measurement_error")
})

test_that("pinned Python 1.2 sparse MFPCA dataclass order and joint PACE arrays match strict R source",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 public sparse MFPCA direct oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  nr<-do.call(etr_fit_sparse_mfpca,c(
    list(trajectories=x,backend="native_covariance",
      strict_source_record=TRUE),args))
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _spm_et
import eyetrajectoriespy.types as _spm_types
def _spm_input(times,values,ids,groups):
    return _spm_et.IrregularTrajectorySet(
       time=tuple(np.asarray(t,dtype=float) for t in times),
       values=tuple(np.asarray(v,dtype=float) for v in values),
       curve_ids=tuple(str(s) for s in ids),
       dimension_names=('x','y'),
       metadata=pd.DataFrame({'block':list(groups)}),
       coordinate_system='degrees',time_unit='s')
")
  mk<-reticulate::py_eval("_spm_input",convert=FALSE)
  pyi<-reticulate::py_call(mk,
    times=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    ids=reticulate::r_to_py(as.list(as.character(x$curve_ids))),
    groups=reticulate::r_to_py(as.list(x$metadata$block)))
  pya<-args
  pya$dimensions<-reticulate::tuple("x","y")
  pya$evaluation_grid<-reticulate::r_to_py(as.numeric(args$evaluation_grid))
  pya$measurement_error_variance<-reticulate::tuple(.08,.10)
  py<-do.call(reticulate::py_call,c(
    list(etpy_get_export("fit_sparse_mfpca"),
      trajectories=pyi),pya))
  fields<-as.character(et_to_r(reticulate::py_eval(
    "tuple(_spm_types.SparseMFPCAResult.__dataclass_fields__)",
    convert=FALSE)))
  expect_identical(names(nr),fields)
  for(field in c(
      "scores","eigenvalues","eigenfunctions","mean",
      "evaluation_grid","quadrature_weights",
      "smoothed_cxx","smoothed_cxy","smoothed_cyx","smoothed_cyy",
      "covariance_cxx","covariance_cxy","covariance_cyx",
      "covariance_cyy","measurement_error_covariance",
      "mean_support_counts")){
    actual<-nr[[field]]
    expected<-et_to_r(reticulate::py_get_attr(py,field))
    expect_equal(unname(actual),unname(expected),
      tolerance=3e-6,ignore_attr=TRUE,info=paste("source field",field))
  }
  expect_identical(as.character(nr$curve_ids),
    as.character(et_to_r(py$curve_ids)))
  expect_identical(as.character(nr$dimensions),
    as.character(et_to_r(py$dimensions)))
  expect_identical(nr$fit_method,et_to_r(py$fit_method))
  expect_identical(nr$score_method,et_to_r(py$score_method))
  for(field in c("cxx","cxy","cyy")){
    actual<-nr$covariance_support_counts[[field]]
    expected<-et_to_r(reticulate::py_get_item(
      py$covariance_support_counts,field))
    expect_equal(actual,expected,ignore_attr=TRUE,
      info=paste("source support",field))
  }
  for(field in names(nr$covariance_pair_counts)){
    expect_equal(as.numeric(nr$covariance_pair_counts[[field]]),
      as.numeric(et_to_r(reticulate::py_get_item(
        py$covariance_pair_counts,field))),
      info=paste("source covariance pair count",field))
  }
  source_diag<-et_to_r(py$score_diagnostics)
  expect_identical(names(nr$score_diagnostics),names(source_diag))
  for(field in names(source_diag)){
    a<-nr$score_diagnostics[[field]]
    b<-source_diag[[field]]
    if(is.numeric(a))
      expect_equal(as.numeric(a),as.numeric(b),tolerance=3e-6,
        info=paste("source score diagnostics",field))
    else expect_identical(as.character(a),as.character(b))
  }
  for(field in names(nr$covariance_diagnostics)){
    theirs<-et_to_r(reticulate::py_get_item(
      py$covariance_diagnostics,field))
    ours<-nr$covariance_diagnostics[[field]]
    if(is.numeric(ours))
      expect_equal(as.numeric(ours),as.numeric(theirs),tolerance=3e-6,
        info=paste("source PSD diagnostic",field))
    else expect_identical(as.character(ours),as.character(theirs))
  }
})
