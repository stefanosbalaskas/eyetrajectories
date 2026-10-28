# Stage 16: deterministic source-level TE and conditional TE qualification.

.etr16_fixture <- function(n=96L){
  i<-seq_len(n)-1L
  source<-as.integer((i^2+3L*i+floor(i/7L))%%3L)
  condition<-as.integer((2L*i+floor(i/5L))%%2L)
  target<-as.integer((source[pmax(1L,seq_len(n)-2L)]+
    condition[pmax(1L,seq_len(n)-1L)]+i%%3L)%%3L)
  list(x=source,y=target,z=condition)
}

test_that("Stage 16 discrete TE exact plug-in estimand and local contributions",{
  a<-.etr16_fixture()
  old<-reticulate::py_available(initialize=FALSE)
  fit<-etr_discrete_transfer_entropy(a$x,a$y,
    target_history=2L,source_history=2L,source_lag=1L)
  expect_s3_class(fit,"etr_discrete_transfer_entropy")
  expect_equal(fit$n_effective,94L)
  expect_equal(length(fit$local_transfer_entropy_bits),94L)
  expect_equal(fit$transfer_entropy_bits,
    mean(fit$local_transfer_entropy_bits),tolerance=1e-14)
  expect_equal(fit$time_indices,2:95)
  expect_true(is.finite(fit$transfer_entropy_bits))
  expect_true(fit$n_joint_histories>=fit$n_target_histories)
  expect_true(fit$singleton_joint_history_fraction>=0 &&
    fit$singleton_joint_history_fraction<=1)
  frame<-etr_transfer_entropy_local_frame(fit)
  expect_identical(names(frame),c("time_index","target_state",
    "target_history","source_history","local_transfer_entropy_bits"))
  expect_equal(frame$time_index,fit$time_indices)
  expect_equal(frame$local_transfer_entropy_bits,
    fit$local_transfer_entropy_bits)
  expect_identical(frame$target_history[[1L]],
    as.integer(c(a$y[2L],a$y[1L])))
  expect_true(grepl("does not by itself establish causal",
    etr_transfer_entropy_reporting_text(fit),fixed=TRUE))
  expect_identical(old,reticulate::py_available(initialize=FALSE))
  expect_error(etr_discrete_transfer_entropy(a$x+.5,a$y,1L,1L,1L),
    "integer-coded")
  expect_error(etr_discrete_transfer_entropy(a$x,a$y[-1L],1L,1L,1L),
    "lengths")
  expect_error(etr_discrete_transfer_entropy(a$x,a$y,1L,1L,0L),
    "positive")
  expect_error(etr_discrete_transfer_entropy(a$x,a$y,96L,1L,1L),
    "no transitions")
})

test_that("Stage 16 source-only TE circular null uses exact declared shifts",{
  a<-.etr16_fixture()
  z<-etr_transfer_entropy_circular_shift_test(a$x,a$y,
    target_history=1L,source_history=2L,source_lag=1L,shifts=c(3L,7L,13L))
  expect_s3_class(z,"etr_transfer_entropy_circular_shift_test")
  expect_identical(z$shifts,c(3L,7L,13L))
  expect_equal(z$p_value_resolution,.25)
  expect_true(z$upper_tail_p_value%in%c(.25,.5,.75,1))
  expect_equal(z$surrogate_mean_bits,mean(z$surrogate_transfer_entropy_bits))
  expect_equal(z$surrogate_centered_transfer_entropy_bits,
    z$observed$transfer_entropy_bits-z$surrogate_mean_bits)
  expect_equal(z$surrogate_transfer_entropy_bits[1L],
    etr_discrete_transfer_entropy(c(tail(a$x,3L),head(a$x,-3L)),
      a$y,1L,2L,1L)$transfer_entropy_bits,tolerance=1e-14)
  expect_true(grepl("does not establish causality",
    etr_transfer_entropy_circular_shift_reporting_text(z),fixed=TRUE))
  expect_error(etr_transfer_entropy_circular_shift_test(a$x,a$y,
    1L,1L,1L,c(2L,2L)),"distinct")
  expect_error(etr_transfer_entropy_circular_shift_test(a$x,a$y,
    1L,1L,1L,c(0L,2L)),"1 <= shift")
})

test_that("Stage 16 conditional TE retains all exact conditioning histories",{
  a<-.etr16_fixture()
  z<-etr_conditional_transfer_entropy(a$x,a$y,a$z,
    target_history=2L,source_history=2L,condition_history=2L,
    source_lag=1L,condition_lag=2L)
  expect_s3_class(z,"etr_conditional_transfer_entropy")
  expect_equal(z$n_effective,93L)
  expect_equal(z$time_indices,3:95)
  expect_equal(z$conditional_transfer_entropy_bits,
    mean(z$local_conditional_transfer_entropy_bits),tolerance=1e-14)
  expect_identical(dim(z$target_history_states),c(93L,2L))
  expect_identical(dim(z$source_history_states),c(93L,2L))
  expect_identical(dim(z$condition_history_states),c(93L,2L))
  expect_equal(z$n_condition_states,length(unique(a$z)))
  expect_true(z$n_joint_histories>=z$n_target_condition_histories)
  frame<-etr_conditional_transfer_entropy_local_frame(z)
  expect_identical(names(frame),c("time_index","target_state",
    "target_history","source_history","condition_history",
    "local_conditional_transfer_entropy_bits"))
  expect_identical(frame$condition_history[[1L]],
    as.integer(c(a$z[2L],a$z[1L])))
  expect_true(grepl("not evidence of causal",
    etr_conditional_transfer_entropy_reporting_text(z),fixed=TRUE))
  expect_error(etr_conditional_transfer_entropy(a$x,a$y,a$z[-1L],
    1L,1L,1L,1L,1L),"same length")
})

test_that("Stage 16 conditional source-only shifts preserve fixed confounder",{
  a<-.etr16_fixture()
  z<-etr_conditional_transfer_entropy_circular_shift_test(
    a$x,a$y,a$z,1L,2L,1L,1L,1L,shifts=c(4L,12L,20L))
  expect_s3_class(z,"etr_conditional_transfer_entropy_circular_shift_test")
  expect_equal(z$surrogate_mean_bits,
    mean(z$surrogate_conditional_transfer_entropy_bits))
  expect_equal(z$upper_tail_p_value,
    (1+sum(z$surrogate_conditional_transfer_entropy_bits>=
       z$observed$conditional_transfer_entropy_bits))/4)
  expect_equal(z$p_value_resolution,.25)
  expect_identical(z$provenance$fixed_processes,c("target","condition"))
  expect_true(grepl("not causal identification",
    etr_conditional_transfer_entropy_circular_shift_reporting_text(z),
    fixed=TRUE))
  expect_error(etr_conditional_transfer_entropy_circular_shift_test(
    a$x,a$y,a$z,1L,1L,1L,1L,1L,shifts=integer()),"shifts")
})

test_that("Stage 16 Cartesian sensitivity retains every declared specification",{
  a<-.etr16_fixture()
  z<-etr_transfer_entropy_parameter_sensitivity(a$x,a$y,
    target_histories=c(1L,2L),source_histories=c(1L,2L),
    source_lags=c(1L,3L))
  expect_s3_class(z,"etr_transfer_entropy_sensitivity")
  expect_equal(nrow(z$table),8L)
  expect_equal(nrow(z$summary_table),8L)
  expect_identical(z$table$specification_id,0:7)
  expect_identical(as.integer(z$table$target_history),
    c(1,1,1,1,2,2,2,2))
  expect_identical(as.integer(z$table$source_history),
    c(1,1,2,2,1,1,2,2))
  expect_true(all(is.na(z$table$surrogate_mean_bits)))
  expect_identical(z$parameter_columns,
    c("target_history","source_history","source_lag"))
  expect_equal(z$table$transfer_entropy_bits[1L],
    etr_discrete_transfer_entropy(a$x,a$y,1L,1L,1L)$transfer_entropy_bits)
  sh<-etr_transfer_entropy_parameter_sensitivity(a$x,a$y,
    target_histories=1L,source_histories=c(1L,2L),
    source_lags=1L,shifts=c(4L,8L))
  expect_true(all(is.finite(sh$table$upper_tail_p_value)))
  expect_equal(nrow(sh$table),2L)
  expect_true(grepl("No specification was selected automatically",
    etr_transfer_entropy_parameter_sensitivity_reporting_text(z),fixed=TRUE))
  expect_error(etr_transfer_entropy_parameter_sensitivity(a$x,a$y,
    target_histories=c(1L,1L),source_histories=1L,source_lags=1L),
    "distinct")
  expect_error(etr_transfer_entropy_parameter_sensitivity(a$x,a$y,
    target_histories=96L,source_histories=1L,source_lags=1L),
    "target_history=96")
})

test_that("Stage 16 frozen public source inventory remains conservatively closed",{
  was<-reticulate::py_available(initialize=FALSE)
  api<-etr_native_parity_catalog()
  expect_equal(nrow(api),508L)
  expect_equal(sum(api$is_python_function),380L)
  expect_equal(sum(api$named_native_candidate),154L)
  expect_equal(sum(api$is_python_function & !api$named_native_candidate),226L)
  expect_equal(sum(api$native_implementation_started),127L)
  expect_equal(sum(api$native_implementation_stage==16L,na.rm=TRUE),12L)
  expect_equal(sum(!api$is_python_function &
    is.na(api$native_representation_stage)),121L)
  expect_true(all(!api$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 16 exact Python 1.2 local TE and conditional oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 16 pinned Python 1.2 empirical TE oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  a<-.etr16_fixture()
  py<-reticulate::py_call(etpy_get_export("discrete_transfer_entropy"),
    source=reticulate::r_to_py(a$x),target=reticulate::r_to_py(a$y),
    target_history=as.integer(2),source_history=as.integer(2),
    source_lag=as.integer(1))
  native<-etr_discrete_transfer_entropy(a$x,a$y,2L,2L,1L)
  expect_equal(native$transfer_entropy_bits,
    as.numeric(et_to_r(py$transfer_entropy_bits)),tolerance=1e-12)
  expect_equal(native$local_transfer_entropy_bits,
    as.numeric(et_to_r(py$local_transfer_entropy_bits)),tolerance=1e-12)
  expect_equal(native$time_indices,as.integer(et_to_r(py$time_indices)))
  expect_equal(native$n_joint_histories,
    as.integer(et_to_r(py$n_joint_histories)))
  pyshift<-reticulate::py_call(etpy_get_export(
    "transfer_entropy_circular_shift_test"),
    source=reticulate::r_to_py(a$x),target=reticulate::r_to_py(a$y),
    target_history=as.integer(1),source_history=as.integer(2),
    source_lag=as.integer(1),shifts=as.list(c(3L,7L,13L)))
  shift<-etr_transfer_entropy_circular_shift_test(a$x,a$y,
    1L,2L,1L,c(3L,7L,13L))
  expect_equal(shift$surrogate_transfer_entropy_bits,
    as.numeric(et_to_r(pyshift$surrogate_transfer_entropy_bits)),
    tolerance=1e-12)
  expect_equal(shift$upper_tail_p_value,
    as.numeric(et_to_r(pyshift$upper_tail_p_value)),tolerance=1e-12)
  pyc<-reticulate::py_call(etpy_get_export("conditional_transfer_entropy"),
    source=reticulate::r_to_py(a$x),target=reticulate::r_to_py(a$y),
    condition=reticulate::r_to_py(a$z),
    target_history=as.integer(2),source_history=as.integer(2),
    condition_history=as.integer(2),source_lag=as.integer(1),
    condition_lag=as.integer(2))
  cond<-etr_conditional_transfer_entropy(a$x,a$y,a$z,2L,2L,2L,1L,2L)
  expect_equal(cond$conditional_transfer_entropy_bits,
    as.numeric(et_to_r(pyc$conditional_transfer_entropy_bits)),
    tolerance=1e-12)
  expect_equal(cond$local_conditional_transfer_entropy_bits,
    as.numeric(et_to_r(pyc$local_conditional_transfer_entropy_bits)),
    tolerance=1e-12)
  expect_equal(cond$condition_history_states,
    et_to_r(pyc$condition_history_states),tolerance=0)
  pys<-reticulate::py_call(etpy_get_export(
    "conditional_transfer_entropy_circular_shift_test"),
    source=reticulate::r_to_py(a$x),target=reticulate::r_to_py(a$y),
    condition=reticulate::r_to_py(a$z),
    target_history=as.integer(1),source_history=as.integer(2),
    condition_history=as.integer(1),source_lag=as.integer(1),
    condition_lag=as.integer(1),shifts=as.list(c(4L,12L,20L)))
  cs<-etr_conditional_transfer_entropy_circular_shift_test(a$x,a$y,a$z,
    1L,2L,1L,1L,1L,c(4L,12L,20L))
  expect_equal(cs$surrogate_conditional_transfer_entropy_bits,
    as.numeric(et_to_r(pys$surrogate_conditional_transfer_entropy_bits)),
    tolerance=1e-12)
  expect_equal(cs$upper_tail_p_value,
    as.numeric(et_to_r(pys$upper_tail_p_value)),tolerance=1e-12)
})
