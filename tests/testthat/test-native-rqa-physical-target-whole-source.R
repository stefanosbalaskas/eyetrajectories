# Frozen Python 1.2 functional_rqa.windowed_rqa_sensitivity:
# sample-unit, physical-time, target-density and source-result geometry.
# Scientific numerical source contract audit, not independent certification.

.etr_rqa_sensitivity_full_fixture <- function() {
  time <- (0:11)/10
  values <- array(0,c(3L,length(time),2L))
  for(i in 1:3) {
    values[i,,1L] <- sin(time*(4+i/3))+i*time/10
    values[i,,2L] <- cos(time*(3+i/4))+i*time/9
  }
  etr_trajectory_set(time,values,curve_ids=c("a","b","c"),
    dimension_names=c("x","y"),
    metadata=data.frame(participant=c("p1","p1","p2")),
    coordinate_system="normalized",time_unit="s")
}

.etr_rqa_sensitivity_compare_table <- function(a,b,context) {
  expect_s3_class(a,"data.frame")
  expect_s3_class(b,"data.frame")
  expect_identical(names(a),names(b),info=paste(context,"columns"))
  expect_identical(nrow(a),nrow(b),info=paste(context,"rows"))
  for(key in names(a)) {
    local <- a[[key]]
    source <- b[[key]]
    expect_identical(is.na(local),is.na(source),
      info=paste(context,key,"NA mask"))
    if(is.numeric(source) && is.numeric(local)) {
      finite <- is.finite(source) & is.finite(local)
      if(any(finite))
        expect_equal(as.numeric(local[finite]),
          as.numeric(source[finite]),tolerance=2e-8,
          info=paste(context,key,"source values"))
    } else
      expect_identical(as.character(local),as.character(source),
        info=paste(context,key,"source text"))
  }
}

test_that("RQA sensitivity honors physical time and exact resolved sample counts", {
  x <- .etr_rqa_sensitivity_full_fixture()
  sample <- etr_windowed_rqa_sensitivity(x,
    metrics=c("recurrence_rate","determinism"),
    window_step_pairs=list(c(6L,2L),c(8L,2L)),
    dimensions=c("x","y"),radius=.9,metric="euclidean",
    theiler_window=1L,undefined_policy="keep")
  physical <- etr_windowed_rqa_sensitivity(x,
    metrics=c("recurrence_rate","determinism"),
    window_step_pairs=list(c(600,200),c(800,200)),
    window_units="ms",step_units="ms",
    dimensions=c("x","y"),radius=.9,metric="euclidean",
    theiler_window=100,theiler_window_units="ms",
    undefined_policy="keep")
  expect_identical(sample$design_table$window_samples,c(6L,8L))
  expect_identical(sample$design_table$step_samples,c(2L,2L))
  for(field in setdiff(names(sample$design_table),
      c("requested_window","requested_step","window_units","step_units")))
    expect_equal(sample$design_table[[field]],
      physical$design_table[[field]],
      tolerance=1e-11,info=paste("physical-time",field))
  expect_equal(sample$summary_table,physical$summary_table,
    tolerance=1e-11)
  expect_equal(sample$pairwise_table,physical$pairwise_table,
    tolerance=1e-11)
  expect_identical(physical$provenance$no_automatic_specification_selection,
    TRUE)
  expect_identical(physical$provenance$interpolation_used_for_sensitivity_comparison,
    FALSE)
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",window_step_pairs=list(c(550,200)),
    window_units="ms",step_units="ms",radius=.9),
    "integer multiple")
})

test_that("target recurrence density permits appropriate RQA outcomes only", {
  x <- .etr_rqa_sensitivity_full_fixture()
  result <- etr_windowed_rqa_sensitivity(x,
    metrics=c("determinism","laminarity"),
    window_step_pairs=list(c(6L,2L),c(8L,2L)),
    target_recurrence_rate=.3,
    dimensions=c("x","y"),theiler_window=1L,
    undefined_policy="keep")
  expect_identical(as.character(result$metrics),
    c("determinism","laminarity"))
  expect_identical(nrow(result$summary_table),12L)
  expect_equal(result$design_table$window_samples,c(6,8))
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="recurrence_rate",window_step_pairs=list(c(6L,2L)),
    target_recurrence_rate=.3),
    "recurrence_rate cannot")
  expect_error(etr_windowed_rqa_sensitivity(x,
    metrics="determinism",window_step_pairs=list(c(6L,2L)),
    radius=.9,target_recurrence_rate=.3),
    "exactly one")
})

test_that("Python 1.2 RQA sensitivity exact tables and profiles match two policies", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Source 1.2 RQA sensitivity multi-policy oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x <- .etr_rqa_sensitivity_full_fixture()
  pd <- reticulate::import("pandas",convert=FALSE)
  p <- reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    metadata=pd$DataFrame(reticulate::r_to_py(x$metadata)),
    coordinate_system="normalized",time_unit="s")
  oracle <- etpy_get_export("windowed_rqa_sensitivity")
  tuple <- reticulate::tuple
  scenarios <- list(
    list(id="physical",pairs=list(c(600L,200L),c(800L,200L)),
      metrics=c("recurrence_rate","determinism"),
      settings=list(window_units="ms",step_units="ms",
        theiler_window=100L,theiler_window_units="ms",radius=.9)),
    list(id="target",pairs=list(c(6L,2L),c(8L,2L)),
      metrics=c("determinism","laminarity"),
      settings=list(target_recurrence_rate=.3,theiler_window=1L))
  )
  for(scenario in scenarios) {
    params <- c(list(trajectories=p,
      metrics=do.call(tuple,as.list(scenario$metrics)),
      window_step_pairs=do.call(tuple,lapply(scenario$pairs,
        function(z)do.call(tuple,as.list(z)))),
      dimensions=tuple("x","y"),undefined_policy="keep"),
      scenario$settings)
    source <- do.call(reticulate::py_call,c(list(oracle),params))
    native <- do.call(etr_windowed_rqa_sensitivity,c(list(
      trajectories=x,metrics=scenario$metrics,
      window_step_pairs=scenario$pairs,dimensions=c("x","y"),
      undefined_policy="keep"),scenario$settings))
    for(table in c("design_table","summary_table","pairwise_table"))
      .etr_rqa_sensitivity_compare_table(
        native[[table]],
        as.data.frame(et_to_r(reticulate::py_get_attr(source,table)),
          stringsAsFactors=FALSE,check.names=FALSE),
        paste(scenario$id,table))
    expect_identical(length(native$analyses),
      as.integer(reticulate::py_len(source$analyses)))
    for(i in seq_along(native$analyses)) {
      p_an <- reticulate::py_get_item(source$analyses,as.integer(i-1L))
      n_an <- native$analyses[[i]]
      p_derived <- p_an$trajectories
      expect_equal(n_an$trajectories$time,
        as.numeric(et_to_r(p_derived$time)),tolerance=1e-12)
      expect_equal(n_an$trajectories$values,
        et_to_r(p_derived$values),tolerance=2e-8,
        ignore_attr=TRUE,info=paste(scenario$id,i,"RQA profiles"))
      expect_equal(n_an$window_samples,
        as.integer(et_to_r(p_an$window_samples)))
      expect_equal(n_an$step_samples,
        as.integer(et_to_r(p_an$step_samples)))
    }
    expect_identical(native$provenance$operation,
      as.character(et_to_r(source$provenance$get("operation"))))
  }
})
