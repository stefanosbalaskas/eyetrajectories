# Full-string contracts from eyetrajectoriespy==1.2.0, frozen c1cd95ad718327550f7e55393ff38582872f7a94
.etr_five_wild_report_fixture<-function(variant="base"){
 p<-list(bootstrap_projections=matrix(0,8L,3L),
   reference_se=c(.23,.34,.45),lower=c(.50,1.25,2.10),
   upper=c(1.5,2.75,3.90),confidence_level=.925,
   residual_components=2L,inference_components=3L,
   multiplier="mammen",independent_unit_column="fish_id")
 s<-list(projection_result=p,lower=c(.45,1.2,2.05),
   upper=c(1.55,2.8,3.95),confidence_level=.95,critical_value=2.35)
 f<-list(projection_result=p,reject_familywise=c(TRUE,FALSE,FALSE),
   pvalue_correction="plus_one",significance_level=.05,
   global_statistic=2.4,global_p_value=.075)
 m<-list(family_test_result=f,adjusted_decision_stable=c(TRUE,FALSE,TRUE),
   confidence_level=.95,global_tail_probability=.125,
   global_interval_lower=.05,global_interval_upper=.25)
 t<-list(scan=list(candidate_components=2:6,residual_components=2L),
   selected_components=c(2,NA_real_,5),width_threshold=.15,
   center_threshold=.08,stability_run=1L)
 if(variant=="alternate"){
   p["independent_unit_column"]<-list(NULL)
   s$projection_result<-p
   f$projection_result<-p;f$pvalue_correction<-"none"
   m$family_test_result<-f
   t$selected_components<-rep(NA_real_,3L)
 }
 list(p=p,s=s,f=f,m=m,t=t)
}
.etr_five_wild_report_texts<-function(z,digits){
 c(
   etr_fpca_wild_bootstrap_projection_reporting_text(z$p,digits),
   etr_fpca_wild_bootstrap_simultaneous_reporting_text(z$s,digits),
   etr_fpca_wild_bootstrap_family_test_reporting_text(z$f,digits),
   etr_fpca_wild_bootstrap_monte_carlo_reporting_text(z$m,digits),
   etr_fpca_wild_bootstrap_truncation_reporting_text(z$t,digits))
}
test_that("five wild-bootstrap report strings contain all scientific qualifications",{
 z<-.etr_five_wild_report_fixture()
 v<-.etr_five_wild_report_texts(z,3L)
 expect_identical(length(v),5L)
 expect_true(all(nzchar(v)))
 expect_match(v[[1L]],"median reference SE=0.340")
 expect_match(v[[1L]],"'fish_id'",fixed=TRUE)
 expect_match(v[[2L]],"critical value was 2.350")
 expect_match(v[[3L]],"1 target(s) were rejected",fixed=TRUE)
 expect_match(v[[4L]],"1 of 3 maxT-adjusted")
 expect_match(v[[5L]],"Selected h ranged from 2 to 5")
 w<-.etr_five_wild_report_texts(.etr_five_wild_report_fixture("alternate"),3L)
 expect_match(w[[1L]],"Curve rows were assumed")
 expect_match(w[[3L]],"empirical exceedance proportion")
 expect_match(w[[5L]],"No target received a qualifying h.")
})
test_that("wild reporting strings reject malformed scientific records",{
 z<-.etr_five_wild_report_fixture()
 p<-z$p;p$reference_se[[1L]]<-Inf
 expect_error(etr_fpca_wild_bootstrap_projection_reporting_text(p),"reference_se")
 s<-z$s;s$critical_value<--1
 expect_error(etr_fpca_wild_bootstrap_simultaneous_reporting_text(s),"nonnegative")
 f<-z$f;f$reject_familywise<-c(TRUE,NA,FALSE)
 expect_error(etr_fpca_wild_bootstrap_family_test_reporting_text(f),"complete logical")
 m<-z$m;m$global_interval_lower<-.7
 expect_error(etr_fpca_wild_bootstrap_monte_carlo_reporting_text(m),"interval")
 t<-z$t;t$scan$candidate_components<-c(2,3,5,6)
 expect_error(etr_fpca_wild_bootstrap_truncation_reporting_text(t),"consecutive")
 expect_error(etr_fpca_wild_bootstrap_projection_reporting_text(z$p,-1L),"digits")
})
test_that("30 native reporting strings exactly match frozen typed Python 1.2",{
 if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
   skip("direct frozen Python 1.2 report oracle opt-in")
 expect_identical(et_python_version(),"1.2.0")
 reticulate::py_run_string(paste(c(
 "import numpy as np",
 "import eyetrajectoriespy as et",
 "def _etr_text_record(cls,**kw):",
 "    z=object.__new__(cls)",
 "    for k,v in kw.items():object.__setattr__(z,k,v)",
 "    return z",
 "def _etr_five_text_py(variant,digits):",
 "    p=_etr_text_record(et.FPCAWildBootstrapProjectionResult,",
 "      bootstrap_projections=np.zeros((8,3)),",
 "      reference_se=np.array([.23,.34,.45]),",
 "      lower=np.array([.50,1.25,2.10]),",
 "      upper=np.array([1.5,2.75,3.90]),",
 "      confidence_level=.925,residual_components=2,inference_components=3,",
 "      multiplier='mammen',independent_unit_column='fish_id' if variant=='base' else None)",
 "    s=_etr_text_record(et.FPCAWildBootstrapSimultaneousResult,",
 "      projection_result=p,lower=np.array([.45,1.2,2.05]),",
 "      upper=np.array([1.55,2.8,3.95]),confidence_level=.95,critical_value=2.35)",
 "    f=_etr_text_record(et.FPCAWildBootstrapFamilyTestResult,",
 "      projection_result=p,reject_familywise=np.array([True,False,False]),",
 "      pvalue_correction='plus_one' if variant=='base' else 'none',",
 "      significance_level=.05,global_statistic=2.4,global_p_value=.075)",
 "    m=_etr_text_record(et.FPCAWildBootstrapMonteCarloDiagnosticResult,",
 "      family_test_result=f,adjusted_decision_stable=np.array([True,False,True]),",
 "      confidence_level=.95,global_tail_probability=.125,",
 "      global_interval_lower=.05,global_interval_upper=.25)",
 "    scan=_etr_text_record(et.FPCAWildBootstrapTruncationScanResult,",
 "      candidate_components=(2,3,4,5,6),residual_components=2)",
 "    t=_etr_text_record(et.FPCAWildBootstrapTruncationSelectionResult,",
 "      scan=scan,selected_components=np.array([2.,np.nan,5.]) if variant=='base' else np.full(3,np.nan),",
 "      width_threshold=.15,center_threshold=.08,stability_run=1)",
 "    return [",
 "      et.fpca_wild_bootstrap_projection_reporting_text(p,digits=digits),",
 "      et.fpca_wild_bootstrap_simultaneous_reporting_text(s,digits=digits),",
 "      et.fpca_wild_bootstrap_family_test_reporting_text(f,digits=digits),",
 "      et.fpca_wild_bootstrap_monte_carlo_reporting_text(m,digits=digits),",
 "      et.fpca_wild_bootstrap_truncation_reporting_text(t,digits=digits)]"
 ),collapse="\n"),convert=FALSE)
 fn<-reticulate::py_get_attr(reticulate::py,"_etr_five_text_py")
 for(variant in c("base","alternate")){
   z<-.etr_five_wild_report_fixture(variant)
   for(digits in c(0L,3L,5L)){
     expected<-reticulate::py_to_r(
       reticulate::py_call(fn,variant,as.integer(digits)))
     actual<-.etr_five_wild_report_texts(z,digits)
     expect_identical(length(actual),length(expected))
     for(i in seq_along(actual))
       expect_identical(actual[[i]],as.character(expected[[i]]),
         info=paste("text",variant,digits,i))
   }
 }
})
