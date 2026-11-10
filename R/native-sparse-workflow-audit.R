# Measure each executed primitive while retaining R's warning signaling.
.etr_sparse_timed_step <- function(name, function_name, parameters, expr) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  result <- withCallingHandlers(force(expr), warning = function(condition) {
    warnings <<- c(warnings, conditionMessage(condition))
  })
  elapsed <- proc.time()[["elapsed"]] - started
  list(result = result, step = list(
    name = name, `function` = function_name, status = "completed",
    parameters = parameters, elapsed_seconds = elapsed, warnings = warnings,
    duration_seconds = elapsed, duration_measured = TRUE
  ))
}
