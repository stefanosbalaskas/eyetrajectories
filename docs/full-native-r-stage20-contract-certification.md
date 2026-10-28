# Stage 20 — source-contract certification program and IAAFT numeric method

Published source of record: **eyetrajectoriespy==1.2.0**, tagged release commit `c1cd95ad718327550f7e55393ff38582872f7a94`. The frozen 508-name R API census separately records its development-snapshot commit `7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`. These **are different commits and are audited independently**.

## Why Stage 19's green tests did not turn 0/508 into 170/508

The 170 prior mapped Python names only identify native R candidate functions. Stage-specific numerical oracles validate *tested configurations*, not every accepted argument, invalid input, output schema, edge case, provenance or scientific meaning. Source contract certification is a distinct, evidence-based approval status.

Stage 20 introduces the first three **certification pilots**:

| Frozen Python callable | Native R candidate | Python source | Status |
|---|---|---|---|
| `alr_transform` | `etr_alr_transform` | `compositional.py` | Pending runtime/review |
| `inverse_alr` | `etr_inverse_alr` | `compositional.py` | Pending runtime/review |
| `score_distance_matrix` | `etr_score_distance_matrix` | `analysis.py` | Pending runtime/review |

The machine-readable registry is `inst/extdata/native_contract_certification_pilots_v1.csv`. Each record must have **all four explicit approvals**: independent pinned Python numeric oracle, full in-domain shape/boundary behavior, scientific-scope review and independent human reviewer signoff with review evidence. The register pins **both the development inventory SHA and published v1.2.0 release commit**, plus the candidate's mapped R export, and rejects mismatched values offline. Approval also requires a real GitHub evidence URL, not a blank flag.

**All four full-contract approval flags remain FALSE. The direct numerical fixtures have passed, but complete source-contract numerical/schema behavior and independent source review remain unapproved. No test automatically mutates the approval registry.** Even if the first three pilots pass, approval is per public source contract, not inference about neighboring functions or subcontracts.

## Qualified test-fixture milestone — three candidates, zero complete contracts

The owner has now passed the corrected Stage 9 (114 assertions), Stage 20 native (63), full source census (39), and Python 1.2 direct Stage 20 oracle (84), all with zero failures and warnings. The single-channel simplex source behavior was added and verified.

The registry distinguishes **`numerical_fixture_pass=TRUE` for all three pilots** from **`numerical_oracle_approved=FALSE`**, which requires exhaustive accepted-domain/source-contract review. Schema, scope and independent reviewer approvals remain FALSE as well. Each numerical fixture result is linked to the owner's Stage 20 GitHub PR evidence. Consequently **3/3 source numerical fixture checks passed, 0/508 complete public contracts independently certified**. The new evidence-state assertions themselves still need an exact-head rerun.

[Candidate-level edge findings](full-native-r-stage20-certification-edge-audit.md).

## Approval checklist and audit contract

1. Confirm the source callable from the pinned published Python package—not master or a changing main branch—and lock the complete signature, defaults and 508-name API SHA.
2. Compare exact same input geometry and deterministic results through `ET_RUN_PYTHON_TESTS=true`, including 3-D simplex shape, all supported reference indices, epsilon/zero clipping and finite inverse, and score matrix component truncation. Compare the Python public callable directly, not just shared algebra.
3. Verify success and failure boundaries: error on malformed simplex, non-finite inputs, unsupported dimension, zero/nonpositive epsilon, score component out of range, and shape handling. Explicitly distinguish Python and R errors when idioms differ.
4. Audit output structure, numerical tolerance, lack of silent coercion, use of original source units, and any R-only restrictions against the full public Python source contract.
5. Independently review the committed tests, identified failure boundaries and GitHub commit. Only then commit an evidence record marking `evidence_state=approved_and_reproducible`, four approvals TRUE, and a GitHub review-evidence URL referencing exact code/test head and owner-run outputs. A failed obligation must remain pending.
6. Preserve the offline strict `require_complete=TRUE` failure until **all 508** pass independently.

A lock-state test asserts exactly three candidates and zero approved; only after review may that test be intentionally updated alongside the signed-off registry. Avoid artificially passing it by changing the count expectations in advance.

## New substantial numerical method

`etr_surrogate_nonlinearity_test` independently implements univariate iterative amplitude-adjusted Fourier transform (IAAFT) surrogate generation and re-estimates Rosenstein's largest-Lyapunov statistic for every surrogate. It uses base-R complex FFT and deterministic stable rank reassignment, a declared maximum-iteration convergence screen, and finite Monte Carlo plus-one p-values (two-sided twice the smaller tail). The R and NumPy random streams are *not identical*, and this source-name mapping has **not** been certified. Sample-unit input is currently supported; invalid time-unit requests fail.

## Inventories (authored vs qualified)

| Inventory | Stage 19 owner-qualified fixtures | Stage 20 authored |
|---|---:|---:|
| Native R mapped implementations | 145 | **146** |
| Unique mapped Python callable names | 170/380 | **171/380** |
| Unmapped callable names | 210 | **209** |
| Other source exports not represented | 121 | **121** |
| Certification pilot candidates | 0 | **3** |
| Fully independently certified source contracts | 0/508 | **0/508 pending verification** |

## Owner-run RStudio execution

```r
pkgload::load_all(".", quiet=TRUE)
testthat::test_local(".", filter="native-stage20-certification")
testthat::test_local(".", filter="full-native-r-parity-ledger")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(".",filter="native-stage20-certification"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
z <- etr_native_parity_catalog()
z[z$contract_certification_candidate,
  c("python_name","native_r_candidate","contract_certification_evidence_state",
    "one_to_one_native_contract_complete")]
```

No merge, publication, release, version bump, full parity statement or causal/chaos claim.
