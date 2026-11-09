# Accelerated frozen Python 1.2 ↔ native R development workflow

This document describes the consolidated author-side numerical implementation
workflow, NOT an independent source contract certification.

- Native release base: `a545694e09f722a6d9e424f3088e5fa597c54dfe`
  (branch `feat/native-trajectoryset-arraylike-metadata-20261105`).
- Scientific changes previously locally qualified at PRs #72–#74 are now
  included directly in the consolidated PR #75. Do not independently merge
  overlapping earlier PRs after merging the consolidated PR.
- Frozen Python 1.2 source commit:
  `c1cd95ad718327550f7e55393ff38582872f7a94`.

## One working branch / 32-function numerical backlog

`scripts/build_accelerated_scientific_wave.py` reads the historical
source-gap ledger without modifying it and writes an **unsigned queue**
for 32 substantive algorithm contracts in five related scientific families:

1. Sparse FPCA and optional FDApy/scikit-fda backends (12).
2. Mixed-effect model fitting, covariance sensitivity and bootstrapping (4).
3. Generalized functional regression and uncertainty (8).
4. FPCR prediction, cross-validation and wild bootstrap (6).
5. Multivariate IAAFT and surrogate inference (2).

These are **32 target functions**, not 32 implemented fixes. Each row
begins `PENDING_SOURCE_FIXTURE` until the numerical source, accepted
inputs, error behavior and complete return contract are actually tested.
The queue never modifies the 508-export source catalog or review approvals.

The 33-case **numerical differential runner** is separately implemented
on the four initial scalar/matrix numerical source contracts:
`functional_trapezoid_weights`, `alr_transform`, `inverse_alr` and
`score_distance_matrix`.

It calls the **actual published Python 1.2 functions** through the pinned
reticulate interpreter and native package R functions on the same fixtures.
Outcomes are separated into:
`PASS_NUMERIC`, `PASS_BOTH_REJECT`, `DIVERGENT_NUMERIC`,
`DIVERGENT_ACCEPTANCE`. Merely rejecting the same bad input does **not**
establish matching Python/R exception class, warning or entire-domain
behavior. Numeric agreement on a bounded case is not a complete contract
certificate.

## Commands in RStudio

Work from a clean checkout of the consolidated branch:

```r
system("git fetch origin")
system("git switch feat/native-zeroarg-source-semantic-closures-20261109")
system("git pull --ff-only")

# Fast iteration: targeted R tests, source-gap integrity tests, 32-target
# author queue and 33 live Python-vs-R numerical/error probes.
# NO repeated R CMD check here.
Sys.setenv(ET_SCIENTIFIC_WAVE_MODE="fast")
source("scripts/run_accelerated_scientific_wave.R",encoding="UTF-8")
```

To complete the first two narrow semantic closures, the previously built
source-closure gate is available:

```r
source("scripts/run_zeroarg_semantic_closure_wave_gate.R",encoding="UTF-8")
```

After the full scientific wave has stopped changing, run once:

```r
Sys.setenv(ET_SCIENTIFIC_WAVE_MODE="full")
source("scripts/run_accelerated_scientific_wave.R",encoding="UTF-8")
```

This does the targeted numerical tests first, then the native/full pinned
Python author qualification, and one clean Git snapshot CRAN-style check.
`ET_SCIENTIFIC_WAVE_MODE="cran"` only runs the CRAN-style gate, useful for
a scoped release. It does not establish scientific source equivalence.

If R and Python disagree in one of the 33 numerical probes, the runner
**records the discrepancy instead of hiding it**. To make any discrepancy
fail the fast iteration, opt in with:

```r
Sys.setenv(ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE="true")
```

The CSV report is written to
`artifacts/native_batch_numeric_diff/<current Git SHA 12>/`.
The 32-target numerical worklist is in
`artifacts/accelerated_scientific_wave/`. Both are generated evidence,
not merged package source or independent sign-off.

## Dynamic source-gap counts

`scripts/source_gap_inventory.py` is a strict historical ledger reader.
It retains the original 203 callable witnesses and one nonfunction
TrajectorySet difference, while computing currently open gaps from
`unresolved_source_gap`/nonfunction `unresolved` flags.

Only two specifically named deterministic zero-argument semantic table
cases are currently allowed to be closed, and only when pinned Python
replay evidence is recorded:
`functional_recovery_metric_catalog_frame` and
`mathematical_contract_frame`.

After those two semantic closures: 201 open callable + one open
nonfunction = **202** open differences. Native `data.frame` and Python
`pandas.DataFrame` still have distinct runtime identity. The closure is
a narrow output-table semantic adjudication, not Python class identity
or a full independent-source approval.

The 508-export reviewer verifier and batch builder obtain active counts
from the validated ledger. Historical cardinalities remain fixed to
prevent deletion of the published source witnesses. Changing a CSV
boolean without supported approved provenance is rejected by the Python
inventory tests. There is **no automatic source-gap closure**, no
independent-review flag mutation, no Git push or merge and no CRAN
publication.

The difference between **developer-tested functions**, **functions
without recorded gaps**, **full Python source scientific equivalence**,
and **independent 508-export certification** must remain explicit.
As of this wave, 0/508 independently certified contracts.
