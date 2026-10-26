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
   The author then executed the revised read-only audit and confirmed
   matching scores, thresholds, anomaly flags and fit statuses for **all
   600 shared scenario/seed identifiers at both alpha levels**.
   Therefore the larger archive contains **5,400 new generating
   datasets, 1,800 per scenario**. Combining
   the pilot and expanded archive without double-counting provides
   6,000 unique scenario/seed identifiers, not 6,600.
   The expanded trial-level CSV/manifest has not been uploaded into
   this conversation, but the owner-run local audit read both saved
   files and verified matched rows and trial/summary counts.
   Its archived manifest records Git SHA
   `ceebc39a6cb4f89fe61b524374bd6348d73efc93`
   and no seed-offset setting. The script fetched independently from
   that exact commit contains the old
   `260000 + scenario * 100000 + simulation * 31` seed formula
   and has **no `ET_CONFORMAL_SEED_OFFSET` implementation**. The
   environment variable therefore could not have affected the
   expanded historical run.
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
The author synchronized the GitHub research branch successfully.
`scripts/read_conformal_results.R` then read the 2,000-per-scenario
archive and confirmed **6,000 study identifiers, 12,000 study-alpha
records and 0 failures**. The earlier missing helper was a transient
checkout synchronization issue, not a simulation failure.

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

- The matched-record numerical audit is now **complete**: 600 shared
  scenario/seed identifiers generated the same scores, cutoffs, flags
  and statuses at both alpha values. The historical Git SHA
  conclusively identifies the pre-offset implementation.
  Test the new preflight seed-collision guard independently before
  qualifying future nonoverlapping replications.
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

## Final archive identity audit — author-run PASS (26 October 2026)

Both saved raw archives were audited in RStudio using the revised
`scripts/audit_conformal_replication.R`. The check passed all
trial-summary counts, exact Monte Carlo confidence intervals and
paired-alpha monotonicity/score invariance checks. **All 600
overlapping scenario/seed identifiers produced identical scores,
thresholds, flags and fit statuses at both alpha values.**

| Quantity | Verified |
|---|---:|
| Original pilot generated datasets | 600 |
| Large archive generated datasets | 6,000 |
| Shared scenario/seed identities with matching outcomes | 600 |
| New datasets in the large archive | 5,400 |
| Unique scenario/seed datasets across both archives | 6,000 |
| Fit failures | 0 |

The new-only subset comprises **1,800 independently generated
datasets per scenario**. The audit's observed false alarms and exact
95% binomial Monte Carlo intervals are:

| Scenario | alpha | False alarms / 1,800 | Rate | Exact 95% Monte Carlo interval |
|---|---:|---:|---:|---:|
| iid exchangeable | .05 | 101 | .056111 | [.045933, .067765] |
| iid exchangeable | .10 | 184 | .102222 | [.088606, .117149] |
| dependent calibration | .05 | 143 | .079444 | [.067367, .092913] |
| dependent calibration | .10 | 178 | .098889 | [.085483, .113618] |
| test-only noise shift | .05 | 397 | .220556 | [.201591, .240435] |
| test-only noise shift | .10 | 753 | .418333 | [.395416, .441517] |

Both iid-exchangeable conditions remain compatible with their
exact continuous-score conformal rank references (.05 and .10).
The dependent-calibration 5% rate exceeds nominal under the
specific duplicated-latent-participant simulation, but the classical
iid exchangeability theorem does **not** cover that design.
The test-only measurement-noise shift produced substantial false-
alarm inflation, again outside the classical assumptions.

**Historical provenance:** the larger archive's manifest records
Git commit `ceebc39a6cb4f89fe61b524374bd6348d73efc93`
with no seed-offset metadata. Fetching the actual script at that
commit verifies that `ET_CONFORMAL_SEED_OFFSET` was not implemented
and the original deterministic seed formula was used. The offset
was specified in the user session but could not affect that run.

**Prevention:** the research branch now contains a preflight guard
that scans archived scenario/seed identifiers and refuses overlaps
before running FPCA or creating a new output archive, except when
the user explicitly enables intentional deterministic reproduction.
This revised guard has not yet been tested in the local R runtime.

The archives are preserved unchanged. These are verified
reproducibility and synthetic-study findings, **not CRAN acceptance,
real-world anomaly performance qualification, or a solution to the
separate simultaneous confidence-band undercoverage.**
