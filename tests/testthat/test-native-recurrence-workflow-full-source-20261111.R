# Frozen Python eyetrajectoriespy==1.2.0 W4 recurrence workflow.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Source-scientific native R record boundaries; runtime dataclass classes,
# sparse CSR storage and exact cross-language timings are not identical.

.etr_w4_full_source_fixture<-function(){
  t<-seq(0,1,length.out=25L)
  z<-array(0,c(4L,25L,2L))
  for(i in 1:4){
    z[i,,1L]<-sin(2*pi*t+i/5)+i*t/10
    z[i,,2L]<-.3*cos(4*pi*t+i/3)+i*t/9
  }
  etr_trajectory_set(t,z,sprintf("c%02d",1:4),
    c("x","y"),coordinate_system="normalized",time_unit="s")
}
.etr_w4_full_source_config<-function(){
  list(curve=0L,dimensions=c("x","y"),embedding_dimension=2L,
    delay=2L,radius=.6,metric="euclidean",theiler_window=1L,
    min_diagonal_length=2L,min_vertical_length=2L)
}
.etr_w4_full_source_fields<-c("workflow_schema_version","workflow_contract",
  "config","embedding","recurrence","metrics","steps","decisions",
  "provenance","reports","tables")
.etr_w4_full_source_config_fields<-c("curve","dimensions",
  "embedding_dimension","delay","radius","delay_units","metric",
  "theiler_window","theiler_window_units","min_diagonal_length",
  "min_vertical_length","preprocessing")
.etr_w4_full_source_rec_fields<-c("matrix","time_a","time_b",
  "source_curve_ids","radius","target_recurrence_rate",
  "achieved_recurrence_rate","metric","theiler_window_samples",
  "kind","state_dimension","provenance","time_unit")
.etr_w4_full_source_metric_fields<-c("recurrence_rate","determinism",
  "mean_diagonal_length","max_diagonal_length","diagonal_entropy",
  "laminarity","trapping_time","max_vertical_length",
  "center_of_recurrence_mass","n_recurrence_points",
  "n_diagonal_lines","n_vertical_lines",
  "min_diagonal_length","min_vertical_length","provenance")

test_that("source W4 returns 11 field top-level and complete nested result",{
  x<-.etr_w4_full_source_fixture();base<-.etr_w4_full_source_config()
  for(metric in c("euclidean","cityblock","chebyshev")){
    cfg<-base;cfg$metric<-metric
    ans<-etr_run_recurrence_workflow(x,cfg,python_boundary_mode=TRUE)
    expect_s3_class(ans,"etr_recurrence_workflow")
    expect_identical(names(ans),.etr_w4_full_source_fields)
    expect_identical(names(ans$config),.etr_w4_full_source_config_fields)
    expect_identical(names(ans$config$preprocessing),"steps")
    expect_length(ans$config$preprocessing$steps,0L)
    expect_identical(names(ans$recurrence),.etr_w4_full_source_rec_fields)
    expect_identical(names(ans$metrics),.etr_w4_full_source_metric_fields)
    expect_identical(names(ans$tables$rqa_metrics),
      .etr_w4_full_source_metric_fields[-15L])
    expect_identical(nrow(ans$tables$rqa_metrics),1L)
    expect_identical(names(ans$provenance),c(
      "input_layout","state_representation","preprocessing_executed",
      "fixed_radius_policy","target_recurrence_rate_selection_performed",
      "automatic_embedding_parameter_selection",
      "automatic_rqa_parameter_selection"))
    expect_identical(names(ans$decisions),c(
      "curve","dimensions","embedding_dimension","delay","radius",
      "delay_units","metric","theiler_window","theiler_window_units",
      "min_diagonal_length","min_vertical_length",
      "resolved_delay_samples","resolved_theiler_window_samples"))
    expect_identical(vapply(ans$steps,function(v)v[["function"]],
      character(1L)),c("delay_embed_trajectory","recurrence_matrix","rqa_metrics"))
    expect_true(all(vapply(ans$steps,function(v)
      is.numeric(v$elapsed_seconds)&&v$elapsed_seconds>=0,
      logical(1L))))
    expect_identical(ans$recurrence$provenance$source_kind,
      "DelayEmbeddingResult")
    expect_identical(ans$recurrence$provenance$radius_policy,"fixed")
    expect_true(ans$recurrence$provenance$sparse)
    expect_identical(ans$recurrence$provenance$threshold_operator,"<=")
    expect_identical(ans$recurrence$provenance$diagonal_included,FALSE)
    expect_identical(ans$recurrence$state_dimension,4L)
    expect_identical(ans$metrics$provenance$operation,"rqa_metrics")
    expect_identical(ans$metrics$provenance$recurrence_provenance,
      ans$recurrence$provenance)
    expect_equal(ans$metrics$recurrence_rate,
      ans$recurrence$achieved_recurrence_rate,tolerance=0)
    expect_equal(ans$tables$rqa_metrics$recurrence_rate,
      ans$metrics$recurrence_rate,tolerance=0)
    expect_identical(ans$decisions$resolved_delay_samples$source,"derived")
    expect_identical(ans$decisions$resolved_delay_samples$value,2L)
    expect_match(ans$reports$rqa,"Recurrence analysis used auto recurrence",
      fixed=TRUE)
    legacy<-etr_run_recurrence_workflow(x,cfg)
    expect_identical(legacy$recurrence$matrix,ans$recurrence$matrix)
    expect_equal(legacy$metrics$recurrence_rate,
      ans$metrics$recurrence_rate,tolerance=0)
    expect_false(legacy$provenance$source_schema_equivalent)
  }
})

test_that("W4 strict source mode validates types and physical time geometry",{
  x<-.etr_w4_full_source_fixture();cfg<-.etr_w4_full_source_config()
  expect_error(etr_run_recurrence_workflow(x,cfg,
    python_boundary_mode=NA),"python_boundary_mode")
  expect_error(etr_run_recurrence_workflow(x,cfg,
    python_boundary_mode=1L),"python_boundary_mode")
  step<-x$time[2L]-x$time[1L]
  physical<-cfg;physical$curve<-"c01"
  physical$delay<-2*step;physical$delay_units<-"s"
  physical$theiler_window<-step;physical$theiler_window_units<-"s"
  a<-etr_run_recurrence_workflow(x,cfg,python_boundary_mode=TRUE)
  b<-etr_run_recurrence_workflow(x,physical,
    python_boundary_mode=TRUE)
  expect_equal(a$embedding$values,b$embedding$values,tolerance=0)
  expect_equal(a$recurrence$matrix,b$recurrence$matrix,tolerance=0)
  expect_identical(b$decisions$resolved_theiler_window_samples$value,1L)
  expect_identical(b$recurrence$source_curve_ids,"c01")
  wrong<-cfg;wrong$preprocessing<-list("smooth")
  expect_error(etr_run_recurrence_workflow(x,wrong,
    python_boundary_mode=TRUE),"empty preprocessing")
  wrong<-cfg;wrong$metric<-"manhattan"
  expect_error(etr_run_recurrence_workflow(x,wrong,
    python_boundary_mode=TRUE),"metric must be")
})

test_that("frozen typed Python W4 source matches entire scientific workflow",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 W4 full scientific workflow source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from eyetrajectoriespy.workflows._recurrence import RecurrenceWorkflowConfig
w4_t=np.linspace(0,1,25)
w4_v=np.empty((4,25,2))
for i in range(1,5):
 w4_v[i-1,:,0]=np.sin(2*np.pi*w4_t+i/5)+i*w4_t/10
 w4_v[i-1,:,1]=.3*np.cos(4*np.pi*w4_t+i/3)+i*w4_t/9
w4_x=et.TrajectorySet(
 time=w4_t,values=w4_v,
 curve_ids=tuple(f'c{i:02d}' for i in range(1,5)),
 dimension_names=('x','y'),coordinate_system='normalized',time_unit='s')
")
  x<-.etr_w4_full_source_fixture()
  source_fun<-etpy_get_export("run_recurrence_workflow",
    .namespace="workflows")
  for(metric in c("euclidean","cityblock","chebyshev")){
    cfg<-.etr_w4_full_source_config();cfg$metric<-metric
    native<-etr_run_recurrence_workflow(x,cfg,python_boundary_mode=TRUE)
    pycfg<-reticulate::py_call(
      reticulate::py_eval("RecurrenceWorkflowConfig",convert=FALSE),
      curve=0L,dimensions=reticulate::tuple("x","y"),
      embedding_dimension=2L,delay=2L,radius=.6,metric=metric,
      theiler_window=1L,min_diagonal_length=2L,
      min_vertical_length=2L)
    py<-reticulate::py_call(source_fun,
      trajectories=reticulate::py_eval("w4_x",convert=FALSE),
      config=pycfg)
    expect_equal(native$embedding$values,et_to_r(py$embedding$values),
      tolerance=1e-12,ignore_attr=TRUE,info=paste(metric,"embedding"))
    expect_equal(native$recurrence$matrix,
      et_to_r(py$recurrence$matrix$toarray()),
      tolerance=0,ignore_attr=TRUE,info=paste(metric,"recurrence"))
    expect_identical(names(native$provenance),
      names(et_to_r(py$provenance)))
    for(nm in names(native$provenance))
      expect_equal(native$provenance[[nm]],
        et_to_r(py$provenance)[[nm]],
        ignore_attr=TRUE,info=paste(metric,"workflow provenance",nm))
    for(nm in .etr_w4_full_source_metric_fields[-15L])
      expect_equal(as.numeric(native$metrics[[nm]]),
        as.numeric(et_to_r(reticulate::py_get_attr(py$metrics,nm))),
        tolerance=1e-10,info=paste(metric,"RQA",nm))
    source_table<-et_to_r(py$tables[["rqa_metrics"]])
    expect_identical(names(native$tables$rqa_metrics),
      names(source_table))
    for(nm in names(source_table))
      expect_equal(native$tables$rqa_metrics[[nm]],source_table[[nm]],
        tolerance=1e-10,ignore_attr=TRUE,info=paste(metric,"table",nm))
    expect_identical(native$reports$rqa,et_to_r(py$reports[["rqa"]]))
    expect_identical(names(native$decisions),
      names(et_to_r(py$decisions)))
    for(nm in names(native$decisions)){
      target<-py$decisions[[nm]]
      expect_identical(native$decisions[[nm]]$source,et_to_r(target$source))
      expect_equal(native$decisions[[nm]]$value,et_to_r(target$value),
        ignore_attr=TRUE,info=paste(metric,"decision",nm))
      expect_equal(native$decisions[[nm]]$criterion,
        et_to_r(target$criterion),ignore_attr=TRUE,
        info=paste(metric,"criterion",nm))
    }
    for(j in 1:3){
      step<-reticulate::py_get_item(py$steps,as.integer(j-1L))
      expect_identical(native$steps[[j]]$name,et_to_r(step$name))
      expect_identical(native$steps[[j]][["function"]],et_to_r(step[["function"]]))
      expect_identical(native$steps[[j]]$status,et_to_r(step$status))
      expect_equal(native$steps[[j]]$parameters,
        et_to_r(step$parameters),ignore_attr=TRUE)
      expect_true(is.finite(native$steps[[j]]$elapsed_seconds))
    }
    py_rec_prov<-et_to_r(py$recurrence$provenance)
    expect_identical(names(native$recurrence$provenance),names(py_rec_prov))
    for(nm in names(py_rec_prov)){
      if(nm=="source_provenance")next
      expect_equal(native$recurrence$provenance[[nm]],
        py_rec_prov[[nm]],tolerance=1e-12,ignore_attr=TRUE,
        info=paste(metric,"recurrence provenance",nm))
    }
    py_metric_prov<-et_to_r(py$metrics$provenance)
    expect_identical(names(native$metrics$provenance),names(py_metric_prov))
    for(nm in names(py_metric_prov)){
      if(nm=="recurrence_provenance")next
      expect_equal(native$metrics$provenance[[nm]],
        py_metric_prov[[nm]],tolerance=1e-12,ignore_attr=TRUE,
        info=paste(metric,"metric provenance",nm))
    }
  }
})
