# Frozen Python 1.2: source-gap versus reviewer-fastlane accounting

This document describes **developer triage**, not full-domain equivalence
or independent scientific certification.

For the 508 frozen Python public exports, the historical source-gap
registry currently lists 380 callables and 128 nonfunctions.
Documented gaps are 203 callable and one nonfunction (204 overall).
Consequently, the **no-recorded-gap** complement is exactly
304 = (380 - 203) + (128 - 1), comprising 177 callables and
127 nonfunctions. None of these 304 has an independent full-domain
certificate solely by virtue of being in that complement.

The 508-export unsigned reviewer intake applies an **additional**
`backend_or_estimand_distinct == FALSE` eligibility gate. The
previous console report listed **174 callable and 127 nonfunction
fastlane candidates = 301**. The arithmetic difference from the
304-export no-recorded-gap complement is **three exports**.

The developer reconciler now emits these distinct categories and exact
excluded-export identities into `developer_progress_summary.json`:

- `no_recorded_gap_exports_total` (304 on the historical ledger).
- `no_recorded_gap_callable_exports_total` (177).
- `no_recorded_gap_nonfunction_exports_total` (127).
- `no_recorded_gap_fastlane_exports_total` (301 on the previous report).
- `no_recorded_gap_backend_distinct_exclusions` (three on the
  previous reported counts), split by callable/nonfunction.
- `no_recorded_gap_backend_distinct_export_keys` (namespaces,
  Python export names, kinds and R mapping candidates).

The exact names and the counts for the newly integrated branch must
be checked in the **new generated developer summary**; the historical
output counts are not evidence of a fresh post-merge source-gap
adjudication. `backend_or_estimand_distinct` can overlap an open
recorded gap, so **19 distinct backends/estimands must not be added
to the 204 source-gap total** as if they were disjoint categories.

The reconciler checks both partitions sum to their source inventory
and the synthetic reviewer test includes three no-gap backend-distinct
exports. It does not close gaps, rewrite scientific audit decisions,
approve source contracts, or alter the 0/508 independent certificate count.
