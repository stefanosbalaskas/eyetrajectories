# First conformal FPCA pilot — observed Windows evidence (2026-10-26)

**Provenance:** results transcribed from the owner's RStudio console for the
`research/native-parity-stage1` branch, R package `0.4.1.9000`.
The raw study CSV has not been uploaded for independent row-wise verification.
The corresponding timestamped on-disk archive was printed by the actual
R script as:

`artifacts/conformal_monte_carlo/run_20261026_103751_pid51684/`

The standalone source reports **200 independent generated datasets per
scenario**, 24 independent FPCA training curves, 19 calibration curves,
41 observation times, alpha=.05/.10, one ordinary held-out curve and a
paired deliberately shifted version. The two alpha settings reuse generated
datasets and **must not be counted as independent studies**.
The `testthat` fixture `native-parity-conformal-qualification` passed.

The full archive has **600 independent generated datasets across three
scenarios**, **1,200 scenario-by-alpha evaluations**, and **zero reported
fit failures**. This is **software/synthetic-study evidence**, not real-eye-
tracking external validation.

## Results: marginal one-curve false alarms

| Scenario | alpha | Flags / 200 | Rate | Exact 95% Monte Carlo interval | Exact exchangeable rank reference |
|---|---:|---:|---:|---:|---:|
| Independent/exchangeable | 0.05 | 9 | 0.045 | [0.02078, 0.08370] | 0.050 |
| Independent/exchangeable | 0.10 | 12 | 0.060 | [0.03138, 0.10246] | 0.100 |
| Dependent calibration | 0.05 | 15 | 0.075 | [0.04258, 0.12068] | Not guaranteed |
| Dependent calibration | 0.10 | 18 | 0.090 | [0.05421, 0.13851] | Not guaranteed |
| Test-only noise shift | 0.05 | 43 | 0.215 | [0.16018, 0.27847] | Not guaranteed |
| Test-only noise shift | 0.10 | 75 | 0.375 | [0.30771, 0.44605] | Not guaranteed |

### Interpretation

Both independent-exchangeable pilot intervals contain the exact continuous
no-ties split-conformal rank benchmark (one of 20 held-out ranks at
alpha=.05; two of 20 at alpha=.10). The observed 0.060 at alpha=.10
is lower than the 0.100 theoretical benchmark, but its upper exact
95% confidence limit is 0.10246. Thus the pilot cannot establish a real
departure from the reference; the larger prespecified Monte Carlo audit
should clarify precision. The two alpha outcomes are nested/paired, not
independent evidence.

In contrast, test-only measurement-noise changes yield much larger
false-alarm fractions (0.215 and 0.375). This deliberate violation of
exchangeability demonstrates sensitivity in this simulation and **does not
contradict the classical guarantee**, which does not apply in that condition.

The dependent-calibration case yields 0.075 and 0.090; these results
neither establish marginal guarantee nor demonstrate its violation under
arbitrary within-participant dependence. The effective number of
independent participant units differs from the 19 curve observations.
An explicit participant-cluster conformal procedure would require its
own definition and simulations.

### Shifted test curve detection (illustrative only)

Shifted-curve flags across the same 200 generated studies were 199/200
for both independent-exchangeable alphas; 199/200 and 200/200 for
dependent calibration at alpha=.05/.10; and 197/200 and 200/200
for test-only noise shift at alpha=.05/.10. These constructed waveforms
produce high detection frequency, but this is not general anomaly power
for naturalistic gaze or other shifts.

## Execution and results inspection

The archive is timestamped by design to preserve previous simulations.
The initial console attempt to read
`artifacts/conformal_monte_carlo/conformal_summary.csv` failed because
the CSV lives **one level below** the base directory.

Read this pilot directly:

```r
pilot_dir <- file.path("artifacts", "conformal_monte_carlo",
                       "run_20261026_103751_pid51684")
results <- read.csv(file.path(pilot_dir, "conformal_summary.csv"))
print(results, row.names = FALSE)
```

Or, after pulling the newer research branch, have the package's
`scripts/read_conformal_results.R` find the most recent complete archive,
read summary/trials and cross-check per-scenario counts automatically:

```r
source("scripts/read_conformal_results.R")
```

Do not rename or delete the pilot archive before retaining its manifest,
trial records and figures. The helper reads existing archives only and
does **not** rerun simulations.

## Next qualification gates

1. Review trial-level CSV, `MANIFEST.txt`, seed independence, alpha pairing,
   numerical ties, score continuity and any omitted fit status.
2. Rerun with **2,000 independent generating datasets per scenario**
   (6,000 datasets total) and the same alpha values, using a nonzero
   `ET_CONFORMAL_SEED_OFFSET` to avoid reusing the pilot's first 200 seeds.
   Every run archives separately. At reference p=.10, the idealized Monte
   Carlo standard error with 2,000 datasets is about 0.0067; at p=.05,
   about 0.0049. Example:

   ```r
   Sys.setenv(ET_CONFORMAL_REPS = "2000",
              ET_CONFORMAL_SEED_OFFSET = "1000000")
   source("scripts/run_conformal_monte_carlo.R")
   source("scripts/read_conformal_results.R")
   ```
3. Vary calibration/training participant counts, contamination strength,
   measurement noise, model dimension and genuinely participant-level
   repeated-trial dependence; add missingness/observation-process stress.
4. Keep the existing 90% multivariate functional simultaneous-band
   undercoverage a *separate* unresolved statistical problem. A conformal
   anomaly screen is not a confidence-band estimator.
5. Cross-platform R qualification (Windows/Linux/macOS) and Python bridge
   behavioral parity remain outstanding.

**Release status: HOLD.** Passing software tests and one favorable
exchangeable split-conformal pilot does not qualify the broad Python API,
real-world anomaly performance or advanced simultaneous inference.
