# 508-export source-contract re-audit — Batch 21 (6 November 2026)

**Reference baseline:** locally qualified native R `fa210f9`; frozen Python 1.2 commit `c1cd95ad718327550f7e55393ff38582872f7a94`. Live GitHub access inspected both private repositories; the R remote feature branch at the time of this audit remained behind the user's later local qualification commits. This audit therefore reads the reconstructed qualified local package rather than assuming the GitHub default branch is current.

## Scope and evidence

- 508 Python public exports previously inventoried; 380 native R function candidates mapped. These are inventory figures, **not** full scientific approvals.
- 203 frozen callable source differences plus one nonfunction `TrajectorySet` constructor/class gap; all 204 strict blockers retained.
- Each of the 204 gaps is checked against a present named native R function definition (where static discovery can identify one). The result and the file locations are in `all_204_source_gaps.csv`.
- Every row receives **provisional** primary blocker triage. This is based on the frozen ledger, function name and the 19 explicitly documented alternative-estimator/backend markers (16 overlap the 204-gap ledger; three are additional blockers without a callable gap row). The categories can overlap; no row is automatically declared scientifically equivalent merely because its R function exists or its gap resembles a Python-specific class.
- `independent_review_handoff.csv` lists 36 prioritized exports, with separate pending numerical, accepted-domain/errors, scientific-estimand, return-schema and independent-review fields. No independent signatures are created or claimed.

## Provisional source-gap triage

| Primary category | Recorded gaps |
|:--|--:|
| `constructor_class_and_domain` | 1 |
| `mixed_input_domain_or_cross_language_representation` | 28 |
| `narrative_reporting_format_and_possible_domain` | 30 |
| `scientific_or_numeric_domain_and_result_schema` | 28 |
| `scientifically_alternative_estimator_or_backend` | 16 |
| `tabular_reporting_schema_and_possible_numerics` | 30 |
| `visualization_backend_and_graphical_schema` | 71 |
| **Total** | **204** |

Named function definitions located by static scan: **204/204**. A missing exact definition match is a follow-up flag, not proof of a missing algorithm. Source-ledger SHA256: `06d0945d95f0f8e93ebd1fc3539b41070e3b1b96f282678498149fea09314311`.

## Material source-checked findings

**Outdated source-gap text corrected (still unresolved):** Python `prediction.py` already supports Gaussian and binomial FPCR CV with numeric covariates and group/curve holdout. The existing native R functions already implement these families and accepts explicit Python-sourced folds; the old gap descriptions understated those features. Batch 21 adds **native-only opt-in** finite numeric-text covariates (including interdigit underscores) to both CV functions. The frozen Python validator parses these fields but `statsmodels` rejects the unconverted pandas object columns in the full estimator. Direct Python 1.2 oracle tests establish that object-typed input fails and compare Gaussian losses/predictions only after explicitly converting the Python covariate DataFrame to float. Native nested CV compares opted-in text inputs with identical numeric input.

**Remaining scientific and backend blockers:** Native R uses its own RNG for shuffled folds, may differ from `statsmodels` in binomial IRLS/boundary outcomes, retains R-specific result classes, and has 19 explicit alternative estimators/backends. These differences remain unresolved even when single-fixture values match.

**Reporting and graphics are not automatically waived:** Python pandas and Matplotlib objects do not have native R class identity. Scientific numerical/table geometry comparisons are still needed; the audit separates representation differences without treating them as resolved scientific or strict Python contracts.

## Required independent-review action

Use the existing four-pilot, SHA256, 508-wave, GPG-verified external-review workflow already in `scripts/`. The new handoff is an **unsigned prioritized queue**, not a replacement for the established independent sign-off system. Source-comparison tests and author-side evidence may be submitted, but only an actually independent reviewer can approve full-domain science and source return/error schema. `independent_scientific_certified` remains `FALSE` for **every** audited row.

## Limitations

The audit is an exhaustive **ledger-and-implementation triage of all 204 recorded gaps**, not 204 full numerical tests, and therefore cannot produce a scientifically defensible aggregate completion percentage. Counts must not be promoted to certification or strict one-to-one statements without contract-wide validated evidence. Two descriptions were updated, but **no original gap flag was cleared**.
