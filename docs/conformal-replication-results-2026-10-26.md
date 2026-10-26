# Conformal FPCA expanded-run overlap audit — October 26, 2026

**Development-only, no release clearance.** R package 0.4.1.9000,
branch `research/native-parity-stage1`.

## Evidence types and important provenance distinction

1. The initial **200-dataset per scenario** pilot is independently checked
   from uploaded raw CSVs: `conformal_trials(1).csv` (1,200 rows),
   `conformal_summary(1).csv` (six cells), `MANIFEST(7).txt`.
   The manifest states R 4.6.1 Windows, Git SHA
   `ceebc39a6cb4f89fe61b524374bd6348d73efc93`, with **200 generated
   datasets per scenario**. There are 600 unique scenario/simulation/seed
   combinations, 1,200 paired-alpha records, and zero failures.
2. The **2,000-dataset per scenario** expanded run was executed by the
   author and its full six-cell numerical output was supplied in the
   RStudio console. This is **6,000 generated datasets in the larger
   archive**, 12,000 paired-alpha evaluation rows, and zero reported
   failures. The user then ran the raw-data audit locally: it found
   **600 overlapping scenario/seed identifiers** shared between the pilot
   and the larger archive. Therefore the larger archive is an
   **extension of the original pilot, not an independent replication**.
   Assuming the shared seed records give identical observations and
   statistics (verification pending), the larger archive contains
   **5,400 new generating datasets, 1,800 per scenario**. Combining
   the pilot and expanded archive without double-counting provides
   6,000 unique scenario/seed identifiers, not 6,600.
   The expanded trial-level CSV/manifest has not been uploaded here,
   so its per-row scores, flags and seed-offset provenance are still
   only author-console reported.
3. The terminal's subsequent repeated `source("scripts/run_conformal_monte_carlo.R")`
   had only printed its first simulation-progress line in the supplied
   transcript. Its outcome is not known. An otherwise identical rerun
   with identical seed settings would not constitute an independent third
   replication.

## 2,000-dataset replication: author-reported false alarms

| Scenario | alpha | False alarms / 2000 | Rate | Exact 95% Monte Carlo interval | Rank target under exchangeability |
|---|---:|---:|---:|---:|---:|
| iid exchangeable | .05 | 110 | .055 | [.04542, .06591] | .050 |
| iid exchangeable | .10 | 196 | .098 | [.08532, .11188] | .100 |
| dependent calibration | .05 | 158 | .079 | [.06755, .09170] | Not applicable |
| dependent calibration | .10 | 196 | .098 | [.08532, .11188] | Not applicable |
| test-only noise shift | .05 | 440 | .220 | [.20202, .23881] | Not applicable |
| test-only noise shift | .10 | 828 | .414 | [.39230, .43595] | Not applicable |

The exact intervals above were independently recalculated from the
author-reported event counts using exact binomial probabilities. The
2,000-dataset estimates remain legitimate single-run Monte Carlo
estimates even though the run is not an independent replication of
the 200-dataset pilot. Do NOT pool their reported counts or treat the
two runs as 2,200 independent datasets per scenario. Both
iid-exchangeable intervals include the classical split-conformal reference
rates (.05 and .10). These observations are compatible with the finite-
sample marginal rank argument in this specified exchangeable Gaussian
functional simulation. No conditional, batch-wise, participant-level,
missingness or empirical eye-tracking guarantee follows.

Test-only noise shift produces roughly 4.4 and 4.14 times the nominal
false-alarm levels, illustrating **lack of transportability of the
exchangeable-score guarantee to changed measurement-noise conditions**.
The dependent calibration trial results (.079/.098) have no direct
exchangeable-rank guarantee and should not be interpreted as validated
curve-level coverage for repeated participant observations.

The deliberately shifted test curves are a separately constructed
alternative, not an estimate of real-world anomaly detection power.
The reported shifted detection fractions ranged from .991 to 1.000 in
the iid/noise-shift designs, with other high fractions for clustered
calibration. No estimator was changed in these analyses.

## Independent audit of uploaded raw 200-study pilot

All six summary cells were recalculated against the uploaded raw
1,200-row pilot trial file: counts of false alarms and shifted detections,
exact binomial confidence intervals, study identifiers and fit failures
matched. In each pair of alpha evaluations, scores were the same and
cutoffs and anomaly flags nested monotonically as alpha increased.
No test curve was tied to its threshold within absolute 1e-12.
There was no evidence of a mismatch in the uploaded pilot material.
These raw files must not be mislabeled as the 2,000-study replication.

## Archive reader and seed-disjoint validation

Both simulation scripts write dated non-overwriting archives below
`artifacts/conformal_monte_carlo/run_YYYYMMDD_HHMMSS_pidNNNN/`.
The helper `scripts/read_conformal_results.R` exists on the
**GitHub research branch**, but the author's local checkout produced
`No such file or directory`; it needs a GitHub Desktop Fetch/Pull before
calling `source()`. This is a repository synchronization issue, not a
statistical failure.

The read-only `scripts/audit_conformal_replication.R` initially verified
each archive's trial-summary consistency but **stopped on detection of
600 seed overlaps**. It has now been improved to identify overlap,
compare matched score/cutoff/flag records, and calculate a
**new-only 1,800-study-per-scenario subset** if overlapping outputs are
identical. If identical seeds produce different outcomes, the audit
appropriately stops rather than assuming safe deduplication. Run after fetching/pulling
the branch, from the project root:

```r
stopifnot(file.exists("scripts/audit_conformal_replication.R"))
source("scripts/audit_conformal_replication.R")
source("scripts/read_conformal_results.R")
```

To inspect replication directly without pulling, read its printed folder
`artifacts/conformal_monte_carlo/run_20261026_105113_pid51684/`.
The pilot is `run_20261026_103751_pid51684/`.

## Remaining scientific blockers

- Inspect the actual 2,000-study raw trials and manifest, including the
  600 shared seed records. Verify whether they produce **identical
  scores, cutoffs, statuses and flags**; do not assume it from seed
  equality alone. The earlier environment request included
  `ET_CONFORMAL_SEED_OFFSET=1000000`, but the run's actual seeds
  demonstrably overlapped the original pilot, indicating the local
  runner likely preceded the seed-offset implementation.
- Broaden calibration sizes, train sizes, observation noise, waveform
  shapes and measurement processes, including informative missingness.
- Develop and qualify separate **participant-level** procedures for
  repeated-trial dependence.
- Address previously observed undercoverage of **90% simultaneous
  participant/group functional bands** independently.
- Finish cross-platform Linux/macOS and R-version checks and external
  Python-R behavioral equivalence validation.

**Conclusion: supportive expanded Monte Carlo study under stipulated
independent exchangeability, but NOT a disjoint replication of the
pilot; not comprehensive scientific calibration, CRAN acceptance or
publication authorization.**

## Correction after user-run seed audit (26 October 2026)

The author's local `source('scripts/audit_conformal_replication.R')`
reported exactly **600 scenario-specific seed overlaps** (200 per
scenario) and then stopped; this was an audit safeguard, not a fit
failure. The large archive retains its original 2,000 studies per
scenario. The new audit revision tests numerical identity of all
matched outcomes at both alpha levels and reports the 1,800 new-study
subset separately if the outcomes agree. No synthetic dataset is
discarded or modified.

The simulation runner now performs a **preflight seed-collision check
before creating a new archive or fitting FPCA**. Overlapping proposed
scenario/seed identifiers stop by default with a precise message;
intentional deterministic reproduction must be explicitly enabled
with `ET_CONFORMAL_ALLOW_SEED_REUSE='true'`. This change has not been
executed in RStudio yet. Pull the branch and first rerun the **read-only
archive audit**; do not rerun the whole 6,000-dataset experiment merely
to correct the classification.
