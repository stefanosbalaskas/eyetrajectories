# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture
# This demonstrates the native plotting API; not independent validation.
stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")
library(eyetrajectories)
metric <- list(name="mean_integrated_error",
  quantity="integrated_error",direction="lower_is_better",
  units="squared_units",scope="curve",
  description="Synthetic integrated reconstruction error")
value <- function(v) list(metric=metric,value=v,component=0L,source="curve")
key <- "mean_integrated_error.source_curve.component_1"
records <- list()
for(i in 1:6) for(group in c("baseline","regularized")) {
  v <- if(group=="baseline") .24+.028*i+.025*sin(i) else
       .13+.015*i+.012*cos(i)
  records[[length(records)+1L]] <- list(
    scenario_name=group,replicate=as.integer(i-1L),
    seed=as.integer(5600L+i),status="ok",
    metrics=setNames(v,key),metric_values=list(value(v)))
}
recovery <- etr_functional_recovery_result(records,list(metric))
summary <- etr_functional_recovery_summary_frame(recovery)
etr_plot_functional_recovery_summary(summary,metric="mean_integrated_error",statistic="median")
