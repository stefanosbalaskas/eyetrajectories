# Opt-in Python test sessions must not depend on Windows Tcl/Tk.
# Loaded before the test files by testthat, including in R CMD check.
if (identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true")) {
  Sys.setenv(MPLBACKEND = "Agg")
}
