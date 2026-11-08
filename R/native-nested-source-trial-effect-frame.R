# Explicit R dataframe analogue of frozen Python 1.2 trial-BLUP frame.
# This does not replace the existing etr_functional_trial_random_effect_frame
# public mapping and does not imply Python's typed dataclass semantics.
#' Source-order nested-trial functional random-effect frame
#'
#' Return one row per source curve and time point. The eight column names,
#' zero-based curve index, order, and values follow the frozen Python 1.2
#' functional_trial_random_effect_frame scientific data schema.
#' This accepts checked native nested S3 fits rather than the Python dataclass.
#'
#' @param result A fitted native nested trial or nested random-slope model.
#' @return Data frame with curve_index, curve_id, participant_id,
#'   source_trial_id, trial_id, time, effect, value.
#' @export
etr_nested_source_trial_effect_frame <- function(result) {
  .etr_assert(inherits(result,"etr_joint_bspline_mixed_nested_trial") ||
    inherits(result,"etr_joint_bspline_mixed_nested_slope"),
    "result must be a fitted native nested trial functional mixed model")
  nc <- as.integer(result$n_curves)
  nt <- length(result$time)
  .etr_assert(length(nc)==1L && is.finite(nc) && nc>=1L && nt>=2L &&
    all(is.finite(result$time)) && all(diff(result$time)>0),
    "invalid native nested-trial fit dimensions or time")
  mat <- result$trial_random_effect_functions
  .etr_assert(is.matrix(mat) && identical(dim(mat),c(nc,nt)) &&
    all(is.finite(mat)),
    "nested trial random effects require finite n_curves x n_time matrix")
  keys <- c("curve_ids","curve_participant_ids","curve_trial_ids","trial_ids")
  .etr_assert(all(vapply(keys,function(k)
    length(result[[k]])==nc && !anyNA(result[[k]]),logical(1))),
    "nested trial source identifiers are missing or misaligned")
  curve_index <- rep(seq_len(nc)-1L,each=nt)
  idx <- rep(seq_len(nc),each=nt)
  out <- data.frame(
    curve_index=as.integer(curve_index),
    curve_id=as.character(result$curve_ids[idx]),
    participant_id=as.character(result$curve_participant_ids[idx]),
    source_trial_id=as.character(result$curve_trial_ids[idx]),
    trial_id=as.character(result$trial_ids[idx]),
    time=rep(as.numeric(result$time),nc),
    effect=rep("trial_functional_intercept",nc*nt),
    value=as.numeric(t(mat)),
    stringsAsFactors=FALSE,check.names=FALSE)
  rownames(out) <- NULL
  out
}
