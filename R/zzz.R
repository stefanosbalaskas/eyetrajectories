# Declare requirements without importing or installing Python at package load.
# reticulate resolves the managed environment only when Python is first used.
.onLoad <- function(libname, pkgname) {
  reticulate::py_require(
    packages = "eyetrajectoriespy==1.2.0",
    python_version = ">=3.11,<3.14"
  )
}
