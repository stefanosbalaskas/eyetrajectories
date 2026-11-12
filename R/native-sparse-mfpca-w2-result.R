# Frozen source: eyetrajectoriespy==1.2.0,
# commit c1cd95ad718327550f7e55393ff38582872f7a94,
# types.py::SparseMFPCAResult and sparse_multivariate.py::fit_sparse_mfpca.
# This is a 29-field scientific-data record, NOT a Python dataclass.
# Native-model extensions remain available without strict_source_record.

.etr_sparse_mfpca_w2_fields<-c(
  "scores","eigenvalues","eigenfunctions","mean",
  "evaluation_grid","dimensions","curve_ids","metadata",
  "coordinate_system","time_unit","n_components",
  "quadrature_weights","smoothed_cxx","smoothed_cxy",
  "smoothed_cyx","smoothed_cyy","covariance_cxx",
  "covariance_cxy","covariance_cyx","covariance_cyy",
  "measurement_error_covariance","score_diagnostics",
  "mean_support_counts","covariance_support_counts",
  "covariance_pair_counts","covariance_diagnostics",
  "fit_method","score_method","provenance")

.etr_sparse_mfpca_w2_scientific_record<-function(fit){
  .etr_assert(inherits(fit,"etr_sparse_mfpca_source")&&
    identical(fit$fit_method,"direct_sparse_block_covariance")&&
    identical(fit$score_method,"joint_PACE"),
    "frozen source record requires the genuine native joint PACE estimator")
  .etr_assert(all(.etr_sparse_mfpca_w2_fields%in%names(fit)),
    "native sparse MFPCA lacks a frozen Python scientific result field")
  .etr_assert(!anyDuplicated(.etr_sparse_mfpca_w2_fields),
    "source dataclass field list must have unique names")
  result<-fit[.etr_sparse_mfpca_w2_fields]
  .etr_assert(identical(names(result),.etr_sparse_mfpca_w2_fields),
    "source MFPCA 29-field order has changed")
  .etr_assert(is.matrix(result$scores)&&
    is.matrix(result$mean)&&
    length(dim(result$eigenfunctions))==3L&&
    nrow(result$scores)==length(result$curve_ids)&&
    ncol(result$scores)==result$n_components&&
    identical(dim(result$mean),
      c(length(result$evaluation_grid),2L)),
    "source MFPCA scientific score or mean shapes differ")
  .etr_assert(all(is.finite(result$scores))||
      (is.character(result$score_diagnostics$status_code)&&
       any(result$score_diagnostics$status_code!="ok")),
    "native source MFPCA contains unreported score nonfinite values")
  .etr_assert(is.data.frame(result$metadata)&&
    is.data.frame(result$score_diagnostics)&&
    is.list(result$covariance_support_counts)&&
    is.list(result$covariance_pair_counts)&&
    is.list(result$covariance_diagnostics),
    "native source MFPCA scientific tables or diagnostics are malformed")
  structure(result,class=c("etr_sparse_mfpca_w2_scientific_record","list"))
}
