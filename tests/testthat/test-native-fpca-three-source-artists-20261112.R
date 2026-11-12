# Frozen eyetrajectoriespy 1.2.0 plotting.py scientific artist data:
# plot_fpca_stability, plot_fpca_influence, plot_fpca_cross_validation.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# These are matched native scientific input arrays, not full Python class
# or bit-identical Matplotlib renderer parity.
.etr_fpca_art_pdf<-function(f){
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(f)
}

test_that("repair the seven-column published source gap inventory independently of testthat installation",{
  path<-system.file("extdata","native_source_contract_gaps_stage22.csv",
    package="eyetrajectories")
  expect_true(file.exists(path))
  # read.csv rejects inconsistent comma fields; check the full header,
  # count, canonical boolean cells, and previously malformed W3 entry.
  raw<-readLines(path,warn=FALSE)
  expect_identical(length(raw),204L)
  expect_false(any(grepl("\\r",raw)))
  header<-strsplit(raw[[1L]],",",fixed=TRUE)[[1L]]
  expect_identical(header,c("python_name","native_r_candidate",
    "gap_kind","known_source_difference","source_witness",
    "review_resolution","unresolved_source_gap"))
  nfield<-utils::count.fields(path,sep=",",quote='"')
  expect_identical(as.integer(nfield),rep(7L,204L))
  gap<-utils::read.csv(path,stringsAsFactors=FALSE,
    check.names=FALSE)
  expect_identical(nrow(gap),203L)
  expect_identical(names(gap),header)
  expect_true(is.logical(gap$unresolved_source_gap))
  row<-gap[gap$python_name=="run_functional_mixed_effects_workflow",,
    drop=FALSE]
  expect_identical(nrow(row),1L)
  expect_false(row$unresolved_source_gap)
  expect_match(row$known_source_difference,
    "ordered config, timed-step, decisions")
  expect_identical(row$native_r_candidate,
    "etr_run_functional_mixed_effects_workflow")
  expect_silent(etr_native_parity_catalog())
})

test_that("three native FPCA scientific artist records preserve source raw data and errorbar semantics",{
  x<-.etr_test_scientific_plot_fixture()
  .etr_fpca_art_pdf({
    st<-etr_plot_fpca_stability(x$st,strict_source_record=TRUE)
    expect_s3_class(st,"etr_fpca_source_artist_record")
    expect_identical(st$source_export,"plot_fpca_stability")
    expect_identical(st$axes[[1L]]$artist_kind,"boxplot")
    expect_identical(st$axes[[1L]]$xticklabels,c("FPC1","FPC2"))
    expect_identical(st$axes[[1L]]$ylim,c(0,1.02))
    expect_identical(st$python_return_kind,"matplotlib.axes.Axes")
    expect_false(st$matplotlib_object_identity)
    expect_false(st$independently_certified)
    for(i in 1:2){
      expected<-unname(stats::quantile(x$st$similarities[,i],
        c(.25,.5,.75),type=7,names=FALSE))
      expect_equal(st$axes[[1L]]$artists[[i]]$raw,
        x$st$similarities[,i],tolerance=0)
      expect_equal(st$axes[[1L]]$artists[[i]]$quartiles,
        expected,tolerance=0)
    }
    infl<-etr_plot_fpca_influence(x$infl,
      metric="influence_score",strict_source_record=TRUE)
    expect_identical(infl$source_export,"plot_fpca_influence")
    expect_identical(infl$axes[[1L]]$xticks,c(0,1,2))
    expect_identical(infl$axes[[1L]]$xticklabels,c("a","b","c"))
    expect_identical(infl$axes[[1L]]$xtick_rotation,90)
    expect_identical(infl$axes[[1L]]$artists[[1L]]$marker,"o")
    expect_equal(infl$axes[[1L]]$artists[[1L]]$ydata,c(.2,.5,.1))
    expect_identical(infl$axes[[1L]]$ylabel,"influence score")
    cv<-etr_plot_fpca_cross_validation(x$cv,
      strict_source_record=TRUE)
    expect_identical(cv$source_export,"plot_fpca_cross_validation")
    expect_identical(cv$axes[[1L]]$title,
      "FPCA reconstruction cross-validation")
    expect_identical(cv$axes[[1L]]$ylabel,
      "Held-out integrated RMSE")
    line<-cv$axes[[1L]]$artists[[1L]]
    expect_identical(line$kind,"errorbar")
    expect_identical(line$marker,"o")
    expect_identical(line$capsize,3)
    expect_equal(line$xdata,c(1,2),tolerance=0)
    expect_equal(line$ydata,c(.55,.325),tolerance=1e-12)
    expect_equal(line$lower,line$ydata-line$yerr,tolerance=1e-12)
    expect_equal(line$upper,line$ydata+line$yerr,tolerance=1e-12)
    expect_equal(line$yerr,
      etr_summarise_fpca_cross_validation(x$cv)$se_rmse,tolerance=0)
    # Non-strict old API outputs cannot change as a side effect of
    # opt-in plotting-science source geometry.
    expect_equal(etr_plot_fpca_stability(x$st),x$st$similarities)
    expect_identical(etr_plot_fpca_influence(x$infl,"influence_score")$group,
      c("a","b","c"))
    expect_equal(etr_plot_fpca_cross_validation(x$cv)$mean_rmse,
      c(.55,.325))
  })
})

test_that("three strict source plots reject non-native and malformed scientific data",{
  x<-.etr_test_scientific_plot_fixture()
  .etr_fpca_art_pdf({
    expect_error(etr_plot_fpca_stability(
      unclass(x$st),strict_source_record=TRUE),
      "genuine native")
    expect_error(etr_plot_fpca_influence(
      unclass(x$infl),strict_source_record=TRUE),
      "genuine native")
    expect_error(etr_plot_fpca_cross_validation(
      unclass(x$cv),strict_source_record=TRUE),
      "genuine native")
    expect_error(etr_plot_fpca_stability(x$st,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_influence(x$infl,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_fpca_cross_validation(x$cv,
      strict_source_record=NA),"strict_source_record")
    bad<-x$st;bad$similarities[1L,1L]<-Inf
    expect_error(etr_plot_fpca_stability(bad,
      strict_source_record=TRUE),"valid native")
    bad<-x$infl;bad$summary$influence_score[1L]<-NaN
    expect_error(etr_plot_fpca_influence(bad,
      metric="influence_score",strict_source_record=TRUE),"metric")
    bad<-x$cv;bad$fold_errors$mean_integrated_rmse[1L]<-Inf
    expect_error(etr_plot_fpca_cross_validation(bad,
      strict_source_record=TRUE),"finite")
  })
})

test_that("frozen Python 1.2 actual Matplotlib artists match source FPCA box median influence and CV uncertainty",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 boxplot/line/errorbar oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_test_scientific_plot_fixture()
  .etr_fpca_art_pdf({
    st<-etr_plot_fpca_stability(x$st,strict_source_record=TRUE)
    infl<-etr_plot_fpca_influence(x$infl,
      metric="influence_score",strict_source_record=TRUE)
    cv<-etr_plot_fpca_cross_validation(x$cv,strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _etr_fpca_three_oracle(sim,folds,group,metric):
    def make(cls, **fields):
        obj=object.__new__(cls)
        for name,value in fields.items():
            object.__setattr__(obj,name,value)
        return obj
    m=np.asarray(sim,dtype=float)
    stability=make(et.FPCAStabilityResult,
       similarities=m,n_bootstrap=int(m.shape[0]),
       reference=make(et.FPCAResult,n_components=int(m.shape[1])))
    influence=make(et.FPCAInfluenceResult,
       summary=pd.DataFrame({'group':group,'influence_score':metric}))
    cv=make(et.FPCACrossValidationResult,fold_errors=pd.DataFrame(folds))
    a=et.plot_fpca_stability(stability)
    b=et.plot_fpca_influence(influence,metric='influence_score')
    c=et.plot_fpca_cross_validation(cv)
    medians=[np.asarray(a.lines[i*6+4].get_ydata(),dtype=float)
             for i in range(m.shape[1])]
    result={
      'stability':{
          'title':a.get_title(),'ylabel':a.get_ylabel(),
          'xticklabels':[txt.get_text() for txt in a.get_xticklabels()],
          'medians':medians,'ylim':np.asarray(a.get_ylim(),dtype=float)},
      'influence':{
          'title':b.get_title(),'xlabel':b.get_xlabel(),
          'ylabel':b.get_ylabel(),
          'x':np.asarray(b.lines[0].get_xdata(),dtype=float),
          'y':np.asarray(b.lines[0].get_ydata(),dtype=float),
          'xticklabels':[txt.get_text() for txt in b.get_xticklabels()]},
      'cv':{
          'title':c.get_title(),'xlabel':c.get_xlabel(),
          'ylabel':c.get_ylabel(),
          'x':np.asarray(c.lines[0].get_xdata(),dtype=float),
          'y':np.asarray(c.lines[0].get_ydata(),dtype=float),
          'n_errorbar_containers':len(c.containers),
          'se':np.asarray(et.summarise_fpca_cross_validation(cv)['se_rmse'],
                         dtype=float)}
    }
    plt.close('all')
    return result
")
    src<-reticulate::py_call(
      reticulate::py_eval("_etr_fpca_three_oracle",convert=FALSE),
      sim=x$st$similarities,folds=x$cv$fold_errors,
      group=as.list(x$infl$summary$group),
      metric=x$infl$summary$influence_score)
    get<-function(key)et_to_r(reticulate::py_get_item(src,key))
    a<-get("stability")
    expect_identical(st$axes[[1L]]$title,a$title)
    expect_identical(st$axes[[1L]]$ylabel,a$ylabel)
    expect_identical(st$axes[[1L]]$xticklabels,
      as.character(a$xticklabels))
    expect_equal(st$axes[[1L]]$ylim,a$ylim,tolerance=0,
      ignore_attr=TRUE)
    for(i in seq_along(a$medians))
      expect_equal(st$axes[[1L]]$artists[[i]]$quartiles[[2L]],
        a$medians[[i]][[1L]],tolerance=1e-12)
    b<-get("influence")
    for(key in c("title","xlabel","ylabel"))
      expect_identical(infl$axes[[1L]][[key]],b[[key]])
    expect_equal(infl$axes[[1L]]$artists[[1L]]$xdata,
      b$x,tolerance=0,ignore_attr=TRUE)
    expect_equal(infl$axes[[1L]]$artists[[1L]]$ydata,
      b$y,tolerance=1e-12,ignore_attr=TRUE)
    c<-get("cv")
    for(key in c("title","xlabel","ylabel"))
      expect_identical(cv$axes[[1L]][[key]],c[[key]])
    expect_identical(as.integer(c$n_errorbar_containers),1L)
    expect_equal(cv$axes[[1L]]$artists[[1L]]$xdata,
      c$x,tolerance=0,ignore_attr=TRUE)
    expect_equal(cv$axes[[1L]]$artists[[1L]]$ydata,
      c$y,tolerance=1e-12,ignore_attr=TRUE)
    expect_equal(cv$axes[[1L]]$artists[[1L]]$yerr,
      c$se,tolerance=1e-12,ignore_attr=TRUE)
  })
})
