# Frozen source: eyetrajectoriespy==1.2.0 wild_regression.py and
# wild_selection.py commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Numerical scientific R record parity; Python sklearn/statsmodels and
# frozen dataclass objects are not represented by an R runtime class.

test_that("source wild projection has the 21 canonical fields and no native audit keys",{
  f<-.etr_wild_projection_fixture()
  for(law in c("normal","mammen")){
    z<-etr_wild_bootstrap_fpca_projection(
      f$x,f$y,n_bootstrap=20L,residual_components=2L,
      inference_components=3L,multiplier=law,random_state=89L,
      python_boundary_mode=TRUE)
    expect_identical(names(z),c(
      "reference_fpca","target_curve_ids","reference_projection",
      "pseudo_truth_projection","reference_se",
      "bootstrap_projections","bootstrap_se","studentized_roots",
      "critical_values","lower","upper","residuals","confidence_level",
      "residual_components","inference_components","scaling","multiplier",
      "target_source","independent_unit_column","random_state","provenance"))
    expect_identical(dim(z$bootstrap_projections),c(20L,24L))
    expect_identical(dim(z$bootstrap_se),c(20L,24L))
    expect_identical(dim(z$studentized_roots),c(20L,24L))
    expect_equal(z$lower,z$reference_projection-z$critical_values*z$reference_se,
      tolerance=1e-12)
    expect_equal(z$upper,z$reference_projection+z$critical_values*z$reference_se,
      tolerance=1e-12)
    p<-z$provenance$fpca_wild_bootstrap_projection
    expect_identical(names(p),c("method","family","estimand","n_bootstrap",
      "residual_components_k","pseudo_truth_components_g",
      "inference_components_h","g_equals_k","h_at_least_g",
      "scaling","multiplier","multiplier_contract","studentization",
      "interval","confidence_level","fpca_basis_refit_in_bootstrap",
      "functional_regressors_fixed","target_curves_fixed",
      "independence_assumption","independent_unit_column",
      "clustered_wild_bootstrap","future_outcome_prediction_interval",
      "simultaneous_across_targets",
      "component_selection_uncertainty_included","random_state"))
    expect_false(p$fpca_basis_refit_in_bootstrap)
    expect_false(p$clustered_wild_bootstrap)
    expect_true(all(is.finite(z$reference_se)))
  }
})

test_that("source wild truncation scan has the 20 canonical fields",{
  f<-.etr_wild_projection_fixture()
  for(law in c("normal","mammen")){
    z<-etr_scan_wild_bootstrap_fpca_truncations(
      f$x,f$y,candidate_components=c(2L,3L),n_bootstrap=20L,
      residual_components=2L,multiplier=law,random_state=89L,
      python_boundary_mode=TRUE)
    expect_identical(names(z),c(
      "reference_fpca","target_curve_ids","candidate_components",
      "residual_components","pseudo_truth_projection",
      "reference_projections","reference_se","critical_values","lower",
      "upper","centers","widths","studentized_roots","confidence_level",
      "scaling","multiplier","target_source","independent_unit_column",
      "random_state","provenance"))
    expect_identical(dim(z$reference_projections),c(2L,24L))
    expect_identical(dim(z$studentized_roots),c(2L,20L,24L))
    expect_equal(z$centers,(z$lower+z$upper)/2,tolerance=0)
    expect_equal(z$widths,z$upper-z$lower,tolerance=0)
    p<-z$provenance$fpca_wild_bootstrap_truncation_scan
    expect_identical(names(p),c(
      "method","family","residual_components_k",
      "pseudo_truth_components_g","candidate_inference_components_h",
      "g_equals_k","all_h_at_least_g",
      "shared_multiplier_draws_across_h","n_bootstrap",
      "confidence_level","scaling","multiplier","interval",
      "functional_regressors_fixed","fpca_basis_refit_in_bootstrap",
      "target_curves_fixed","independence_assumption",
      "independent_unit_column","simultaneous_across_targets",
      "random_state"))
    expect_identical(as.integer(p$candidate_inference_components_h),
      c(2L,3L))
    expect_true(p$shared_multiplier_draws_across_h)
    expect_false(p$simultaneous_across_targets)
  }
})

test_that("strict source mode rejects native multiplier and RNG extensions",{
  f<-.etr_wild_projection_fixture()
  for(export in c("projection","scan")){
    fn<-if(export=="projection")etr_wild_bootstrap_fpca_projection
      else etr_scan_wild_bootstrap_fpca_truncations
    base<-c(list(trajectories=f$x,outcome=f$y,n_bootstrap=20L,
      residual_components=2L),
      if(export=="scan")list(candidate_components=c(2L,3L))
      else list(inference_components=3L))
    expect_error(do.call(fn,c(base,list(python_boundary_mode=TRUE,
      multiplier_draws=f$draws))),"fixed multiplier_draws")
    expect_error(do.call(fn,c(base,list(python_boundary_mode=TRUE,
      random_engine="base_R"))),"NumPy PCG64")
    expect_error(do.call(fn,c(base,list(python_boundary_mode=1))),
      "python_boundary_mode")
  }
  native<-etr_wild_bootstrap_fpca_projection(f$x,f$y,
    n_bootstrap=20L,residual_components=2L,inference_components=3L,
    multiplier_draws=f$draws)
  expect_true(native$provenance$fpca_wild_bootstrap_projection$
    fixed_source_multiplier_draws_supplied)
  expect_false(native$provenance$fpca_wild_bootstrap_projection$
    source_full_contract_certified)
})

test_that("pinned typed Python wild projection and shared scan agree for two laws and seeds",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python wild projection/scan numerical source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  f<-.etr_wild_projection_fixture()
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_py_wild_t=np.linspace(0,1,13)
_py_wild_values=np.zeros((24,13,1),dtype=float)
for i in range(1,25):
 _py_wild_values[i-1,:,0]=(.25*np.sin(2*np.pi*_py_wild_t)
    +.13*np.cos(i*.8)*np.cos(np.pi*_py_wild_t)
    +.09*np.sin(i*.57)*np.sin(3*np.pi*_py_wild_t)
    +.07*np.cos(i*.21)*_py_wild_t**2)
_py_wild_y=np.array([.6*np.cos(i*.8)-.35*np.sin(i*.57)
    +.04*np.cos(i*.37) for i in range(1,25)])
_py_wild_x=et.TrajectorySet(
    time=_py_wild_t,values=_py_wild_values,
    curve_ids=tuple(f'curve{i:02d}' for i in range(1,25)),
    dimension_names=('x',),coordinate_system='unknown',time_unit='s')
_py_wild_source={}
for law in ('normal','mammen'):
 for seed in (7,89):
  _py_wild_source[(law,seed,'projection')]=et.wild_bootstrap_fpca_projection(
    _py_wild_x,_py_wild_y,n_bootstrap=20,
    residual_components=2,inference_components=3,
    multiplier=law,random_state=seed)
  _py_wild_source[(law,seed,'scan')]=et.scan_wild_bootstrap_fpca_truncations(
    _py_wild_x,_py_wild_y,candidate_components=(2,3),
    n_bootstrap=20,residual_components=2,
    multiplier=law,random_state=seed)
")
  for(law in c("normal","mammen")) for(seed in c(7L,89L)){
    args<-list(trajectories=f$x,outcome=f$y,n_bootstrap=20L,
      residual_components=2L,multiplier=law,random_state=seed,
      python_boundary_mode=TRUE)
    for(kind in c("projection","scan")){
      actual<-if(kind=="projection")
        do.call(etr_wild_bootstrap_fpca_projection,
          c(args,list(inference_components=3L))) else
        do.call(etr_scan_wild_bootstrap_fpca_truncations,
          c(args,list(candidate_components=c(2L,3L))))
      py<-reticulate::py_eval(paste0("_py_wild_source[('",
        law,"',",seed,",'",kind,"')]"),convert=FALSE)
      fields<-if(kind=="projection")c(
        "reference_projection","pseudo_truth_projection",
        "reference_se","bootstrap_projections","bootstrap_se",
        "studentized_roots","critical_values","lower","upper","residuals")
        else c("pseudo_truth_projection","reference_projections",
          "reference_se","critical_values","lower","upper","centers",
          "widths","studentized_roots")
      for(field in fields){
        source<-et_to_r(reticulate::py_get_attr(py,field))
        expect_equal(actual[[field]],source,tolerance=2e-6,
          ignore_attr=TRUE,info=paste(kind,law,seed,field))
      }
      refpy<-reticulate::py_get_attr(py,"reference_fpca")
      expect_equal(actual$reference_fpca$explained_variance,
        et_to_r(reticulate::py_get_attr(refpy,"explained_variance")),
        tolerance=2e-6,ignore_attr=TRUE)
      provpy<-et_to_r(reticulate::py_get_attr(py,"provenance"))
      expect_identical(names(actual$provenance),names(provpy))
      key<-if(kind=="projection")
        "fpca_wild_bootstrap_projection" else
        "fpca_wild_bootstrap_truncation_scan"
      sourcep<-provpy[[key]];nativep<-actual$provenance[[key]]
      expect_identical(names(nativep),names(sourcep))
      for(field in names(nativep)){
        a<-nativep[[field]];b<-sourcep[[field]]
        if(identical(field,"candidate_inference_components_h")){
          expect_identical(as.integer(unlist(a)),
            as.integer(unlist(b)))
        } else if(identical(field,"multiplier_contract")){
          expect_identical(names(a),names(b))
          for(nm in names(a))
            expect_equal(a[[nm]],b[[nm]],tolerance=1e-12,
              ignore_attr=TRUE)
        } else expect_equal(a,b,tolerance=1e-12,ignore_attr=TRUE,
          info=paste("provenance",kind,law,field))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
