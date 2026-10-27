# Stage 8: frozen 508-export source register remains fail-closed.
test_that("ten Stage 8 recurrence public APIs have native implementations",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  target<-c(
    recurrence_network="etr_recurrence_network",
    recurrence_network_node_frame="etr_recurrence_network_node_frame",
    recurrence_network_summary_frame="etr_recurrence_network_summary_frame",
    joint_recurrence_matrix="etr_joint_recurrence_matrix",
    joint_recurrence_component_frame="etr_joint_recurrence_component_frame",
    joint_rqa_metrics="etr_joint_rqa_metrics",
    cross_rqa_metrics="etr_cross_rqa_metrics",
    recurrence_radius_profile="etr_recurrence_radius_profile",
    windowed_rqa="etr_windowed_rqa",
    windowed_rqa_trajectory_set="etr_windowed_rqa_trajectory_set")
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),77L)
  expect_equal(sum(!z$named_native_candidate & z$is_python_function),303L)
  expect_equal(sum(z$native_implementation_started),47L)
  expect_equal(sum(z$native_implementation_stage==8L,na.rm=TRUE),10L)
  expect_equal(sum(z$native_implementation_stage==7L,na.rm=TRUE),10L)
  for(n in names(target)){
    r<-z[z$python_name==n & z$namespace=="root",,drop=FALSE]
    expect_equal(nrow(r),1L)
    expect_identical(r$native_r_candidate,unname(target[[n]]))
    expect_identical(r$native_implementation_stage,8L)
    expect_true(r$native_implementation_started)
    expect_false(r$one_to_one_native_contract_complete)
  }
  classes<-c("RecurrenceNetworkResult","JointRecurrenceResult",
             "RecurrenceRadiusProfileResult","WindowedRQAResult",
             "WindowedRQAFunctionalResult")
  for(name in classes){
    r<-z[z$python_name==name & z$namespace=="root",,drop=FALSE]
    expect_equal(nrow(r),1L)
    expect_false(r$is_python_function)
    expect_identical(r$native_representation_stage,8L)
    expect_false(r$one_to_one_native_contract_complete)
  }
  expect_equal(sum(!is.na(z$native_representation_stage)),7L)
  expect_equal(sum(z$status==
     "class_or_constant_native_representation_not_reviewed"),121L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_identical(reticulate::py_available(initialize=FALSE),before)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
})
