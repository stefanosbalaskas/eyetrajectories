# Source-scientific mixed residual comparison contract.
# Frozen eyetrajectoriespy==1.2.0, Python commit
# c1cd95ad718327550f7e55393ff38582872f7a94
# functional_mixed_effects_diagnostics.py. This is an already-fitted
# residual sensitivity comparison, not a source MixedLM refit.
.etr_residual_sensitivity_source_fixture<-function(
    serial=FALSE,which="reference",converged=TRUE){
  tt<-c(0,.2,.55,1)
  r1<-rbind(c(1,2,4,3),c(2.2,2.2,2.2,2.2),
            c(2,3,1,5))
  r2<-rbind(c(1,3,4,2),c(3.5,3.5,3.5,3.5),
            c(2.2,2.5,1.5,5.1))
  res<-if(identical(which,"reference"))r1 else r2
  cor<-if(serial)0.25^abs(outer(0:3,0:3,"-")) else NULL
  list(converged=converged,time=tt,time_unit="s",
    dimension_name="pupil",
    source_curve_ids=c("trial-a","trial-b","trial-c"),
    curve_participant_ids=c("p1","p1","p2"),
    residual_functions=res,residual_variance=.8,
    residual_correlation_matrix=cor,
    residual_correlation=if(serial)"ar1" else "iid",
    random_slope_predictor=NULL)
}

test_that("validated source mixed fits reproduce all residual comparison dimensions",{
  for(serial in c(FALSE,TRUE)){
    f<-.etr_residual_sensitivity_source_fixture(serial)
    g<-.etr_residual_sensitivity_source_fixture(serial,"comparison")
    for(scale in c("raw","whitened"," WHITENED ")){
      if(identical(scale," WHITENED ")&&!serial)next
      a<-etr_compare_functional_mixed_effects_residual_diagnostics(
        f,g,max_lag=3L,reference_label="baseline",
        comparison_label="alternative",residual_scale=scale)
      expect_s3_class(a,"data.frame")
      expect_identical(nrow(a),4L)
      expect_identical(ncol(a),20L)
      expect_identical(names(a),c("reference_label","comparison_label",
        "residual_scale","lag_index","lag_time_mean","lag_time_min",
        "lag_time_max","n_pairs","n_trials_total",
        "n_trials_acf_defined_reference","autocovariance_reference",
        "autocorrelation_reference","semivariance_reference",
        "n_trials_acf_defined_comparison","autocovariance_comparison",
        "autocorrelation_comparison","semivariance_comparison",
        "delta_autocovariance","delta_autocorrelation",
        "delta_semivariance"))
      expect_identical(a$lag_index,0:3)
      expect_identical(a$n_pairs,c(12L,9L,6L,3L))
      expect_identical(a$n_trials_total,rep(3L,4L))
      expect_true(all(a$reference_label=="baseline"))
      expect_true(all(a$comparison_label=="alternative"))
      expect_true(all(a$residual_scale==scale))
      for(metric in c("autocovariance","autocorrelation","semivariance"))
        expect_equal(a[[paste0("delta_",metric)]],
          a[[paste0(metric,"_comparison")]]-
            a[[paste0(metric,"_reference")]],tolerance=1e-12)
      expect_true(all(is.finite(a$delta_semivariance)))
      # Irregular observed grid must retain physical lag range.
      expect_gt(a$lag_time_max[2L],a$lag_time_min[2L])
      if(identical(scale,"raw")){
        expect_identical(a$n_trials_acf_defined_reference,rep(2L,4L))
        expect_identical(a$n_trials_acf_defined_comparison,rep(2L,4L))
      }
    }
  }
})

test_that("source fit acceptance fails closed for convergence, geometry and cohort mismatch",{
  a<-.etr_residual_sensitivity_source_fixture()
  b<-.etr_residual_sensitivity_source_fixture(
    which="comparison")
  bad<-a;bad$converged<-FALSE
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    bad,b,max_lag=1L),"converged")
  bad<-b;bad$time[3L]<-.6
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,bad,max_lag=1L),"same observed time grid")
  bad<-b;bad$source_curve_ids<-rev(b$source_curve_ids)
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,bad,max_lag=1L),"same source curves")
  bad<-b;bad$curve_participant_ids<-rev(b$curve_participant_ids)
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,bad,max_lag=1L),"participant mapping")
  bad<-b;bad$residual_variance<-0
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,bad,max_lag=1L),"variance")
  bad<-b;bad$residual_functions[1,2]<-NA_real_
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,bad,max_lag=1L),"finite")
  bad<-b;bad$residual_correlation_matrix<-diag(3)
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,bad,max_lag=1L),"n_time square")
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=4L),"max_lag")
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=1L,residual_scale="temperature"),"residual_scale")
})

test_that("pinned typed Python source returns exact 20-column raw/whitened comparison",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 source comparison oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _source_mixed_record(cls,**kw):
    obj=object.__new__(cls)
    for key,value in kw.items():object.__setattr__(obj,key,value)
    return obj
_sr_time=np.array([0.,.2,.55,1.])
_sr_reference=np.array([[1.,2.,4.,3.],[2.2,2.2,2.2,2.2],
                         [2.,3.,1.,5.]])
_sr_comparison=np.array([[1.,3.,4.,2.],[3.5,3.5,3.5,3.5],
                          [2.2,2.5,1.5,5.1]])
_sr_compare={}
for _serial in (False,True):
    _corr=.25**np.abs(np.subtract.outer(np.arange(4),np.arange(4))) if _serial else None
    _base=dict(time=_sr_time,time_unit='s',dimension_name='pupil',
               source_curve_ids=('trial-a','trial-b','trial-c'),
               curve_participant_ids=('p1','p1','p2'),
               residual_variance=.8,residual_correlation_matrix=_corr,
               residual_correlation='ar1' if _serial else 'iid',
               random_slope_predictor=None,converged=True)
    _a=_source_mixed_record(et.FunctionalMixedEffectsResult,
       **dict(_base,residual_functions=_sr_reference))
    _b=_source_mixed_record(et.FunctionalMixedEffectsResult,
       **dict(_base,residual_functions=_sr_comparison))
    for _scale in (('raw','whitened',' WHITENED ') if _serial else ('raw','whitened')):
        _sr_compare[(_serial,_scale)]=et.compare_functional_mixed_effects_residual_diagnostics(
            _a,_b,max_lag=3,reference_label='baseline',
            comparison_label='alternative',residual_scale=_scale)
")
  for(serial in c(FALSE,TRUE)){
    a<-.etr_residual_sensitivity_source_fixture(serial)
    b<-.etr_residual_sensitivity_source_fixture(serial,"comparison")
    for(scale in if(serial)c("raw","whitened"," WHITENED ")
        else c("raw","whitened")){
      actual<-etr_compare_functional_mixed_effects_residual_diagnostics(
        a,b,max_lag=3L,reference_label="baseline",
        comparison_label="alternative",residual_scale=scale)
      source<-reticulate::py_eval(paste0("_sr_compare[(",
        if(serial)"True" else "False",",'",scale,"')]"),
        convert=FALSE)
      expected<-et_to_r(source)
      expect_identical(names(actual),names(expected))
      for(col in names(actual)){
        if(is.numeric(actual[[col]]))
          expect_equal(actual[[col]],expected[[col]],
            tolerance=3e-12,ignore_attr=TRUE,
            info=paste("residual source",serial,scale,col))
        else
          expect_identical(as.character(actual[[col]]),
            as.character(expected[[col]]),
            info=paste("residual source labels",serial,scale,col))
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
