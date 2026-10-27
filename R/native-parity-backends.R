#' Survey installed optional R backends for advanced functional methods
#'
#' Local-only inventory. Uses installed.packages() without loading or
#' downloading third-party packages; install status is NOT parity/validation.
#' @return Data frame with package, family, official CRAN URL, version,
#'   and an explicit FALSE scientific-parity flag.
#' @export
etr_r_backend_catalog <- function() {
  packages <- c(
    "fda", "fda.usc", "fdapace", "MFPCA", "funData", "tf", "refund",
    "FDboost", "denseFLMM", "sparseFLMM", "fdasrvf", "registr",
    "conformalInference.fd", "SCBmeanfd", "clubSandwich", "mgcv",
    "nlme", "crqa", "casnet", "nonlinearTseries", "rEDM",
    "RTransferEntropy", "infotheo", "entropy", "fdaoutlier", "mlr3fda")
  family <- c(
    "basis and functional data", "functional regression and depths",
    "sparse PACE", "joint multivariate FPCA", "multivariate function classes",
    "regular/irregular function data", "penalized functional regression",
    "boosted functional models", "dense functional mixed effects",
    "sparse functional mixed effects", "elastic SRVF registration",
    "joint registration and FPCA", "functional conformal prediction",
    "simultaneous mean bands", "cluster-robust CR2/CR3", "additive models",
    "mixed-effect models", "cross-recurrence and RQA", "recurrence/RQA",
    "nonlinear time-series statistics", "empirical dynamic modelling",
    "Shannon/Renyi transfer entropy", "discrete information theory",
    "entropy shrinkage", "functional outlier detection",
    "functional machine learning")
  installed <- utils::installed.packages()
  names_installed <- rownames(installed)
  yes <- packages %in% names_installed
  version <- rep(NA_character_, length(packages))
  version[yes] <- as.character(installed[packages[yes], "Version"])
  data.frame(package = packages, family = family,
             url = paste0("https://CRAN.R-project.org/package=", packages),
             installed = yes, version = version,
             scientific_parity_verified = FALSE,
             stringsAsFactors = FALSE)
}
