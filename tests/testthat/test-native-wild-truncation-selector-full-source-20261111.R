# Full source-semantic stabilized-volatility selector, rather than a refit.
# Frozen Python eyetrajectoriespy==1.2.0 wild_selection.py and types.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
.etr_truncation_selector_source_fixture <- function() {
  widths <- matrix(c(
    .90,.30,1.00,
    1.00,.70,1.60,
    1.05,.75,1.20,
    1.10,.80,.90),nrow=4L,byrow=TRUE)
  centers <- matrix(c(
    .50,.20,.50,
    .55,.30,.80,
    .60,.35,.60,
    .65,.40,.40),nrow=4L,byrow=TRUE)
  list(candidate_components=c(2L,3L,4L,5L),
    target_curve_ids=c("alpha","beta","none"),
    widths=widths,centers=centers,
    lower=centers-widths/2,upper=centers+widths/2,
    studentized_roots=array(0,dim=c(4L,20L,3L)),
    provenance=list(study="typed-source-selection"))
}

test_that("earliest qualifying run uses the full frozen source transition law", {
  x <- .etr_truncation_selector_source_fixture()
  s <- etr_select_fpca_wild_bootstrap_truncation(x,
    width_threshold=.12,center_threshold=.12,
    stability_run=1L,on_failure="ignore")
  expect_identical(names(s),c("scan","width_changes","center_changes",
    "stable_width","stable_center","stable_both",
    "selected_candidate_indices","selected_components",
    "selected_centers","selected_widths","selected_lower",
    "selected_upper","width_threshold","center_threshold",
    "stability_run","on_failure","provenance"))
  expect_equal(s$selected_candidate_indices,c(0L,1L,-1L))
  expect_equal(s$selected_components,c(2,3,NaN))
  expect_equal(s$selected_centers,c(.5,.3,NaN))
  expect_equal(s$selected_widths,c(.9,.7,NaN))
  expect_identical(dim(s$stable_both),c(3L,3L))
  expect_identical(s$stable_both[,1L],rep(TRUE,3L))
  expect_identical(s$stable_both[,2L],c(FALSE,TRUE,TRUE))
  expect_identical(s$stable_both[,3L],rep(FALSE,3L))
  expect_identical(s$provenance$study,"typed-source-selection")
  p <- s$provenance$fpca_wild_bootstrap_truncation_selection
  expect_equal(p$required_consecutive_stable_transitions,2L)
  expect_identical(p$selection,
    "earliest_candidate_h_starting_qualifying_stable_run")
  expect_false(p$silent_largest_h_fallback)
  # Decimal-text thresholds reproduce Python float("0.12") semantics.
  txt <- etr_select_fpca_wild_bootstrap_truncation(x,
    width_threshold="0.12",center_threshold="0.12",
    stability_run=1L,on_failure="ignore")
  expect_equal(txt$selected_components,s$selected_components)
})

test_that("source selector failure options do not choose the largest h", {
  x <- .etr_truncation_selector_source_fixture()
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,1L,on_failure="error"),
    "no qualifying run for 1 target")
  expect_warning(w <- etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,1L,on_failure="warn"),
    "no qualifying run for 1 target")
  expect_equal(w$selected_candidate_indices,c(0L,1L,-1L))
  expect_true(is.nan(w$selected_components[3L]))
  invisible(expect_silent(etr_select_fpca_wild_bootstrap_truncation(
    x,.12,.12,1L,on_failure="ignore")))
})

test_that("stability count and invalid scientific input fail closed", {
  x <- .etr_truncation_selector_source_fixture()
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,2147483647,on_failure="ignore"),
    "requires more consecutive stable transitions")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,3L,on_failure="ignore"),
    "requires more consecutive stable transitions")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    0,.12,1L,on_failure="ignore"),"width_threshold")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    Inf,.12,1L,on_failure="ignore"),"width_threshold")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,NA_real_,1L,on_failure="ignore"),"center_threshold")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,TRUE,on_failure="ignore"),"stability_run")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,-1L,on_failure="ignore"),"stability_run")
  expect_error(etr_select_fpca_wild_bootstrap_truncation(x,
    .12,.12,1L,on_failure="largest"),"on_failure")
  malformed <- x
  malformed$centers <- x$centers[-1L,,drop=FALSE]
  expect_error(etr_select_fpca_wild_bootstrap_truncation(
    malformed,.12,.12,1L,on_failure="ignore"),"centers")
})

test_that("frozen Python 1.2 typed source selector matches every scientific result field", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python source selector oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_source_scan = object.__new__(et.FPCAWildBootstrapTruncationScanResult)
_source_widths = np.array([[.90,.30,1.00],[1.00,.70,1.60],
                           [1.05,.75,1.20],[1.10,.80,.90]])
_source_centers = np.array([[.50,.20,.50],[.55,.30,.80],
                            [.60,.35,.60],[.65,.40,.40]])
_source_values = dict(
    candidate_components=(2,3,4,5),
    target_curve_ids=('alpha','beta','none'),
    widths=_source_widths, centers=_source_centers,
    lower=_source_centers-_source_widths/2,
    upper=_source_centers+_source_widths/2,
    studentized_roots=np.zeros((4,20,3)),
    provenance={'study':'typed-source-selection'})
for _key,_value in _source_values.items():
    object.__setattr__(_source_scan,_key,_value)
_source_selected = et.select_fpca_wild_bootstrap_truncation(
    _source_scan,width_threshold=.12,center_threshold=.12,
    stability_run=1,on_failure='ignore')
")
  x <- .etr_truncation_selector_source_fixture()
  native <- etr_select_fpca_wild_bootstrap_truncation(x,
    width_threshold=.12,center_threshold=.12,
    stability_run=1L,on_failure="ignore")
  source <- reticulate::py_eval("_source_selected",convert=FALSE)
  for(field in setdiff(names(native),c("scan","provenance"))) {
    got <- native[[field]]
    expected <- et_to_r(reticulate::py_get_attr(source,field))
    expect_equal(got,expected,tolerance=1e-12,ignore_attr=TRUE,
      info=paste("frozen typed selector",field))
  }
  expect_equal(native$provenance,
    et_to_r(reticulate::py_get_attr(source,"provenance")),
    tolerance=1e-12,ignore_attr=TRUE)
  source_scan <- reticulate::py_get_attr(source,"scan")
  expect_equal(native$scan$widths,
    et_to_r(reticulate::py_get_attr(source_scan,"widths")),
    tolerance=0,ignore_attr=TRUE)
  expect_equal(native$scan$centers,
    et_to_r(reticulate::py_get_attr(source_scan,"centers")),
    tolerance=0,ignore_attr=TRUE)
  expect_equal(native$scan$candidate_components,
    et_to_r(reticulate::py_get_attr(source_scan,"candidate_components")),
    ignore_attr=TRUE)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
