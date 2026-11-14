# Scientific source guard for R 32-bit integer overflow in wild FPCA
# truncation selection. This does NOT claim independent Python parity.
test_that("wild FPCA selection rejects huge source integer before R coercion",{
  scan<-list(candidate_components=1:3,target_curve_ids="fish_01",
    widths=matrix(c(.1,.1,.1),ncol=1L),
    centers=matrix(c(1,1,1),ncol=1L),
    lower=matrix(c(.9,.9,.9),ncol=1L),
    upper=matrix(c(1.1,1.1,1.1),ncol=1L))
  expect_error(
    etr_select_fpca_wild_bootstrap_truncation(scan,
      width_threshold=.1,center_threshold=.1,stability_run=2^31),
    "more consecutive stable transitions")
  expect_error(
    etr_select_fpca_wild_bootstrap_truncation(scan,
      width_threshold=.1,center_threshold=.1,
      stability_run=.Machine$integer.max),
    "more consecutive stable transitions")
  # The same source contract remains valid for small admissible counts.
  # Match the published selector's actual zero-based output field.
  chosen<-etr_select_fpca_wild_bootstrap_truncation(scan,
    width_threshold=.1,center_threshold=.1,stability_run=0L)
  expect_identical(chosen$selected_components,1)
  expect_identical(chosen$selected_candidate_indices,0L)
})
