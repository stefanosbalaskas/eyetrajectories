# Batch 30 (2026-11-07): provisional native source-parity public dispatch.
# The existing public implementation in R/native-functional-scenario-design.R
# is NOT modified. It is preserved below for comparison and rollback.
# Source pin: eyetrajectoriespy==1.2.0, c1cd95ad718327550f7e55393ff38582872f7a94.
# This experimental dispatch has only bounded oracle evidence; it is NOT a
# declaration of complete Python or independent certification.
#
# This file intentionally sorts after zz-native-scenario-expansion-batch29.R.
# Before a CRAN release, reconcile into the single canonical definition and
# remove this provisional dispatcher after the full source contract is tested.

if (!exists("etr_expand_functional_simulation_scenarios", mode="function",
            inherits=FALSE) ||
    !exists("etr_expand_functional_simulation_scenarios_b29", mode="function",
            inherits=FALSE)) {
  stop("Batch 30 public dispatcher requires both the existing public and Batch 29 reference functions",call.=FALSE)
}

.etr_b30_legacy_public_scenario_expansion <-
  etr_expand_functional_simulation_scenarios

# This intentionally replaces the current binding after preserving the legacy
# implementation; the original NAMESPACE export remains unchanged.
etr_expand_functional_simulation_scenarios <- function(base, factors,
    seed_policy=c("shared", "disjoint")) {
  etr_expand_functional_simulation_scenarios_b29(
    base=base, factors=factors, seed_policy=seed_policy)
}
