# Full source-semantic pair for frozen Python eyetrajectoriespy==1.2.0.
# commit c1cd95ad718327550f7e55393ff38582872f7a94
# Scientific data.frames are native-language analogues of source pandas tables.

.etr_wild_source_audit_fixture <- function() {
  m<-matrix(seq_len(12L)/4,nrow=4L,byrow=TRUE)
  scan<-list(
    candidate_components=c(1L,3L,5L,8L),
    target_curve_ids=c("curveβ","curveA","curve9"),
    reference_projections=m,
    reference_se=m/2,
    critical_values=m/4,
    lower=m-1,
    upper=m+1,
    centers=m+2,
    widths=m/3)
  selection<-list(
    scan=scan,
    selected_components=c(1,NA_real_,5),
    selected_centers=c(.5,NA_real_,2.5),
    selected_widths=c(.25,NA_real_,1.25),
    selected_lower=c(0,NA_real_,1),
    selected_upper=c(1,NA_real_,4))
  list(scan=scan,selection=selection)
}

test_that("wild scan frame is candidate-major, exact nine columns and complete source cells",{
  z<-.etr_wild_source_audit_fixture()
  out<-etr_fpca_wild_bootstrap_truncation_scan_frame(z$scan)
  expect_identical(names(out),c("curve_id","inference_components",
    "reference_projection","heteroscedastic_se","critical_value",
    "lower","upper","center","width"))
  expect_identical(nrow(out),12L)
  expect_identical(out$curve_id,
    rep(c("curveβ","curveA","curve9"),times=4L))
  expect_identical(out$inference_components,
    rep(c(1L,3L,5L,8L),each=3L))
  expect_equal(out$reference_projection,as.numeric(t(z$scan$reference_projections)),tolerance=0)
  expect_equal(out$heteroscedastic_se,as.numeric(t(z$scan$reference_se)),tolerance=0)
  expect_equal(out$critical_value,as.numeric(t(z$scan$critical_values)),tolerance=0)
  expect_equal(out$lower,as.numeric(t(z$scan$lower)),tolerance=0)
  expect_equal(out$upper,as.numeric(t(z$scan$upper)),tolerance=0)
  expect_equal(out$center,as.numeric(t(z$scan$centers)),tolerance=0)
  expect_equal(out$width,as.numeric(t(z$scan$widths)),tolerance=0)
})

test_that("selection frame reproduces source nullable Int64 and full results",{
  z<-.etr_wild_source_audit_fixture()
  out<-etr_fpca_wild_bootstrap_truncation_selection_frame(z$selection)
  expect_identical(names(out),c("curve_id","selected_inference_components",
    "selected_center","selected_width","selected_lower","selected_upper"))
  expect_identical(out$curve_id,c("curveβ","curveA","curve9"))
  expect_identical(out$selected_inference_components,c(1L,NA_integer_,5L))
  expect_identical(out$selected_center,c(.5,NA_real_,2.5))
  expect_identical(out$selected_width,c(.25,NA_real_,1.25))
  expect_identical(out$selected_lower,c(0,NA_real_,1))
  expect_identical(out$selected_upper,c(1,NA_real_,4))
  z$selection$selected_components<-rep(NA_real_,3L)
  z$selection$selected_centers<-rep(NA_real_,3L)
  z$selection$selected_widths<-rep(NA_real_,3L)
  z$selection$selected_lower<-rep(NA_real_,3L)
  z$selection$selected_upper<-rep(NA_real_,3L)
  all_missing<-etr_fpca_wild_bootstrap_truncation_selection_frame(z$selection)
  expect_true(all(is.na(all_missing$selected_inference_components)))
  expect_identical(nrow(all_missing),3L)
})

test_that("wild scan/selection frame source boundaries fail closed on invalid scientific records",{
  z<-.etr_wild_source_audit_fixture()
  bad<-z$scan
  bad$candidate_components<-c(1,3,3,8)
  expect_error(etr_fpca_wild_bootstrap_truncation_scan_frame(bad),"distinct")
  bad<-z$scan
  bad$reference_se<-matrix(0,nrow=3L,ncol=3L)
  expect_error(etr_fpca_wild_bootstrap_truncation_scan_frame(bad),"expected shape")
  bad<-z$scan
  bad$reference_projections[1L,1L]<-Inf
  expect_error(etr_fpca_wild_bootstrap_truncation_scan_frame(bad),"finite matrix")
  bad<-z$selection
  bad$selected_components[[1L]]<-1.5
  expect_error(etr_fpca_wild_bootstrap_truncation_selection_frame(bad),"positive integers")
  bad<-z$selection
  bad$selected_components[[1L]]<-0
  expect_error(etr_fpca_wild_bootstrap_truncation_selection_frame(bad),"positive integers")
  bad<-z$selection
  bad$selected_centers<-c(.5,Inf,2.5)
  expect_error(etr_fpca_wild_bootstrap_truncation_selection_frame(bad),"finite or NA")
  bad<-z$selection
  bad$scan$target_curve_ids<-c("curveβ","curveβ","curve9")
  expect_error(etr_fpca_wild_bootstrap_truncation_selection_frame(bad),"unique")
})

test_that("frozen typed Python 1.2 wild scan and selection source frames match native R cellwise",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 wild selection/scan source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_wild_source_dataclass(cls, **fields):",
    "    obj=object.__new__(cls)",
    "    for name,value in fields.items():object.__setattr__(obj,name,value)",
    "    return obj",
    "_etr_wild_scan_matrix=np.arange(1,13,dtype=float).reshape((4,3))/4.",
    "_etr_wild_scan=_etr_wild_source_dataclass(et.FPCAWildBootstrapTruncationScanResult,",
    "    candidate_components=(1,3,5,8),",
    "    target_curve_ids=('curveβ','curveA','curve9'),",
    "    reference_projections=_etr_wild_scan_matrix,",
    "    reference_se=_etr_wild_scan_matrix/2.,",
    "    critical_values=_etr_wild_scan_matrix/4.,",
    "    lower=_etr_wild_scan_matrix-1.,",
    "    upper=_etr_wild_scan_matrix+1.,",
    "    centers=_etr_wild_scan_matrix+2.,",
    "    widths=_etr_wild_scan_matrix/3.)",
    "_etr_wild_select=_etr_wild_source_dataclass(et.FPCAWildBootstrapTruncationSelectionResult,",
    "    scan=_etr_wild_scan,",
    "    selected_components=np.array([1.,np.nan,5.]),",
    "    selected_centers=np.array([.5,np.nan,2.5]),",
    "    selected_widths=np.array([.25,np.nan,1.25]),",
    "    selected_lower=np.array([0.,np.nan,1.]),",
    "    selected_upper=np.array([1.,np.nan,4.]))",
    "_etr_wild_py_scan=et.fpca_wild_bootstrap_truncation_scan_frame(_etr_wild_scan)",
    "_etr_wild_py_selection=et.fpca_wild_bootstrap_truncation_selection_frame(_etr_wild_select)",
    "object.__setattr__(_etr_wild_select,'selected_components',np.full(3,np.nan))",
    "object.__setattr__(_etr_wild_select,'selected_centers',np.full(3,np.nan))",
    "object.__setattr__(_etr_wild_select,'selected_widths',np.full(3,np.nan))",
    "object.__setattr__(_etr_wild_select,'selected_lower',np.full(3,np.nan))",
    "object.__setattr__(_etr_wild_select,'selected_upper',np.full(3,np.nan))",
    "_etr_wild_py_all_missing=et.fpca_wild_bootstrap_truncation_selection_frame(_etr_wild_select)"
  ),collapse="\n"),convert=FALSE)
  z<-.etr_wild_source_audit_fixture()
  actual<-list(
    etr_fpca_wild_bootstrap_truncation_scan_frame(z$scan),
    etr_fpca_wild_bootstrap_truncation_selection_frame(z$selection))
  z$selection$selected_components<-rep(NA_real_,3L)
  for(k in c("selected_centers","selected_widths","selected_lower","selected_upper"))
    z$selection[[k]]<-rep(NA_real_,3L)
  actual[[3L]]<-etr_fpca_wild_bootstrap_truncation_selection_frame(z$selection)
  oracle_names<-c("_etr_wild_py_scan","_etr_wild_py_selection","_etr_wild_py_all_missing")
  for(i in seq_along(oracle_names)){
    from_python<-as.data.frame(et_to_r(reticulate::py_eval(oracle_names[[i]],convert=FALSE)),
      check.names=FALSE)
    native<-actual[[i]]
    expect_identical(names(from_python),names(native),info=paste("columns",i))
    expect_identical(nrow(from_python),nrow(native),info=paste("rows",i))
    for(field in names(from_python)){
      v<-from_python[[field]]
      w<-native[[field]]
      if(all(is.na(v))){
        expect_true(all(is.na(w)),info=paste("all-missing",i,field))
      }else if(is.numeric(v)&&is.numeric(w)){
        expect_equal(as.numeric(w),as.numeric(v),tolerance=1e-12,
          info=paste("numeric",i,field))
      }else{
        expect_identical(as.character(w),as.character(v),
          info=paste("character",i,field))
      }
    }
  }
})
