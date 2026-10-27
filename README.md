# eyetrajectories

## Native R Stage 6 — read Python 1.2 scientific-result snapshots

New `etr_read_python_portable_result()` provides a **Python-free R
reader for published `eyetrajectoriespy 1.2.0` portable scientific
results**. It reads `manifest.json` and `arrays.npz`, verifies the
NumPy archive's SHA-256 checksum, safely decodes supported
numeric/boolean/Unicode and JSON-backed string arrays, and preserves
scientific identifiers, units, metadata and provenance as inspectable
R objects. It never runs `reticulate` or Python.

Only optional R packages `jsonlite` and `digest` are needed at call
time. Unsupported NumPy dtypes, malformed/oversized archives and
nonrepresentable backend objects fail explicitly; arbitrary Python
objects are never unpickled or fitted. This is an **independent native
reader**, not yet a full replacement for Python's
`load_portable_result()` or a writer of Python-compatible archives.
The Stage 5 RDS snapshot remains a separate native R format.

```r
# Checkout research/full-native-r-parity-stage6-20261027 first
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage6-python-portable-reader")
testthat::test_local(".",filter="native-stage6-parity-ledger")

# Independent Python 1.2 source archive oracle only:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage6-python-portable-reader"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**Stage 6 passed its owner-run Windows qualification on 27 October
2026:** native R reader **18 PASS (one expected Python opt-in SKIP)**;
Stage 6 parity ledger **20 PASS**; independent pinned Python 1.2
generated JSON+NPZ interoperability oracle **79 PASS, 0 FAIL, 0
WARN, 0 SKIP**. The Python-enabled count includes native assertions;
these are not 117 independent cross-language cases.
Historical Windows tests: Stage 5 Python 1.2 `TrajectorySet` provenance
oracle **106/106**, Stage 4 advanced distances **733/733**.
GitHub Actions/Linux/macOS verification remains unavailable.
The frozen 508-export source register now identifies **46 mapped
candidate R functions among 380 Python callables, 334 unmapped
functions, one partially represented nonfunction class and 127
unreviewed nonfunction public objects**. No complete
508/508 native parity claim, merge or release.

**[Stage 6 source contract and security boundaries](docs/full-native-r-stage6-python-portable-reader.md)** · **[Draft Stage 6 PR #14](https://github.com/stefanosbalaskas/eyetrajectories/pull/14)**.


## Native R Stage 5 — trajectory provenance and snapshots (research)

The native `etr_trajectory_set()` now accepts an eighth, backwards-
compatible `provenance=list()` argument. New `etr_with_values()`
matches Python `TrajectorySet.with_values()`'s shallow provenance update
without Python, while `etr_trajectory_provenance()` retrieves the source
audit. Curve subsets and the earlier Stage 3 normalization/centering
methods now preserve provenance; `etr_from_long()` adds explicit source
audit fields.

`etr_trajectory_snapshot()` and
`etr_restore_trajectory_snapshot()` provide **versioned, validated
native R snapshot round-trips** through trusted RDS files. This is **not**
Python's JSON+NPZ scientific-result archive format, and it is not a claim
of cross-language file interchange.

**Stage 5 has now passed its owner-executed Windows tests**:
**62** native provenance/snapshot assertions (one intentionally skipped
Python oracle), **19** Stage 5 ledger assertions and **106** Python
1.2 object/provenance assertions with **zero failures, warnings or skips**.
Stage 4 previously passed **733/733** owner-executed Windows numerical
assertions. Cross-platform CI and Python JSON+NPZ interoperability
remain unverified. The strict mapping remains unchanged: **45 named native R
function candidates among 380 Python callables**, **335 unmapped
callables**, and **128 other Python public objects** (including
`TrajectorySet`) still requiring full representation review.

```r
# Checkout research/full-native-r-parity-stage5-20261027 first.
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage5-trajectory-provenance")
testthat::test_local(".",filter="native-stage5-parity-ledger")

# The Python reference comparison is optional and ONLY for tests:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".",filter="native-stage5-trajectory-provenance")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

**[Stage 5 contracts and RDS limitations](docs/full-native-r-stage5-provenance-snapshots.md)** ·
**[Stage 5 draft PR #13](https://github.com/stefanosbalaskas/eyetrajectories/pull/13)**.
Draft research branch only; no merge/release/508-contract certification.


## Native R Stage 4 — complete Fréchet coupling and audited DTW (draft)

Three additional Python-free R implementations now expose the Python
1.2.0 sequence-distance contracts missing from the earlier short
`etr_frechet()` / `etr_dtw()` functions:

- `etr_discrete_frechet()`: scalar or deterministic optimal coupling,
  0-based path indices, local costs, and provenance.
- `etr_dynamic_time_warping()`: symmetric1/symmetric2 step weighting,
  Sakoe-Chiba index windows, normalizable symmetric2 scores, and
  complete 0-based alignment path/cost audits.
- `etr_pairwise_dtw_full()`: full options and selected channels for
  Python-equivalent unlabeled pairwise DTW distance matrices.

**These are native R algorithms. No Python is executed by them.**
Stage 4's Python reference tests are explicitly opt-in. **On 27
October 2026 the owner ran the native R tests (64 PASS, two intentionally
skipped Python cases), the Stage 4 ledger (26 PASS), and the full opt-in
Python 1.2 numerical oracle (733 PASS, no failures/warnings/skips)
on Windows.** Source static checks and owner-run numerical tests are
distinct from cross-OS CI, which has not yet executed.

The frozen Python 1.2 inventory is still **508 public exports**:
**380 callable functions + 128 other types/objects**. Currently
**45** function names have an identified native R candidate, with
**335 unmapped** function names; Stage 2–4 have added **14** genuinely
new R implementations. The completion ledger remains fail-closed,
not a claim of 45 qualified equivalents.

```r
# First checkout: research/full-native-r-parity-stage4-20261027
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage4-distance-contracts")
testthat::test_local(".",filter="native-stage4-parity-ledger")
testthat::test_local(".",filter="full-native-r-parity-ledger")
source("scripts/report_full_native_r_parity.R")

# Optional independently executed Python v1.2.0 comparison:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".",filter="native-stage4-distance-contracts")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

**[Stage 4 method contracts and reproducibility](docs/full-native-r-stage4-frechet-dtw.md)** · **[Stage 4 draft PR #12](https://github.com/stefanosbalaskas/eyetrajectories/pull/12)**.
Research-only; no release/merge and no general scientific inferential
qualification.


## Native R Stage 3 — seven more Python-free methods (research)

Stage 3 adds **seven independently implemented R functions** for
coordinates, landmark centering, explicit time intervals, wrapped heading,
per-curve tortuosity, weighted pairwise discrete Fréchet distance and
nearest trajectories. Stage 2's four kinematics methods passed **296/296**
owner-run Python 1.2 numerical assertions on Windows. Stage 3 subsequently
passed **347/347** complete Python 1.2 numerical assertions on Windows.

At the Stage 3 checkpoint, the exact 508-symbol inventory identified **44 native candidates**
(11 additions from Stages 2–3 plus 33 existing analogues), while
**336 Python functions remain unmapped** and 128 public nonfunction
symbols require native representation review. These are names/candidates,
not 44 fully verified one-to-one numerical contracts.

```r
# Checkout research/full-native-r-parity-stage3-20261027 first.
pkgload::load_all(".", quiet=TRUE)
testthat::test_local(".", filter="native-stage3-preprocessing-distances")
testthat::test_local(".", filter="native-stage3-parity-ledger")
source("scripts/report_full_native_r_parity.R")

# Optional independent numerical comparison only:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".", filter="native-stage3-preprocessing-distances")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

**[Stage 3 scientific contracts and instructions](docs/full-native-r-stage3-preprocessing-distances.md)** ·
**[Stage 3 draft PR](https://github.com/stefanosbalaskas/eyetrajectories/pull/11)**.
No release or native 508/508 parity claim.


## Complete native-R parity programme — 508 Python public source contracts

**Target:** every public `eyetrajectoriespy 1.2.0` algorithm available as an
independent R implementation **without executing Python**. The existing
`reticulate` bridge remains optional; it is **not** native parity.

The initial Stage 2 research branch added four native R algorithms
(`etr_acceleration_magnitude()`, `etr_distance_to_landmark()`,
`etr_signed_curvature()`, `etr_turning_rate()`), Python-free analytic
tests and an optional independent Python numerical-oracle test.

At the Stage 2 checkpoint, the strict `etr_native_parity_catalog()` identified **41 named
native counterparts/candidates** across **380 Python functions** (37 prior,
4 new); **339 functions lack a specifically mapped native counterpart**.
A further **128 public Python classes/configurations/constants** remain
to be reviewed for native representation. Native name similarity does not
qualify numerical, behavioral or scientific one-to-one parity.

```r
# Source branch: research/full-native-r-parity-stage2-20261027
pkgload::load_all(".", quiet = TRUE)
testthat::test_local(".", filter = "native-planar-geometry-parity")
testthat::test_local(".", filter = "full-native-r-parity-ledger")
source("scripts/report_full_native_r_parity.R")
```

**[Full native parity roadmap](docs/full-native-r-one-to-one-roadmap.md)** ·
**[Draft native PR #9](https://github.com/stefanosbalaskas/eyetrajectories/pull/9)** ·
**[Completion issue #10](https://github.com/stefanosbalaskas/eyetrajectories/issues/10)**.

**If `testthat` says "No test files found", you are almost certainly
running an older branch.** The two native tests exist only on the
`research/full-native-r-parity-stage2-20261027` branch, not on the older
`feat/full-python12-hybrid-parity-20261027` or `research/native-parity-stage1`
branches. In the **RStudio Terminal** (not the R console), first check for
uncommitted work and fetch the new research branch:

```sh
git status --short
git fetch origin
git switch research/full-native-r-parity-stage2-20261027
```

If `git switch` reports the local branch does not exist yet, use
`git switch --track origin/research/full-native-r-parity-stage2-20261027`.
Do **not** use `--force` or discard local research changes. Then update
with `git pull --ff-only` and **restart RStudio**. Verify:

```r
getwd()
file.exists("tests/testthat/test-native-planar-geometry-parity.R")
file.exists("tests/testthat/test-full-native-r-parity-ledger.R")
# Both must return TRUE before calling test_local().
```

Stage 2 and Stage 3 completed owner-executed Windows numeric oracle tests;
Stage 4 still needs runtime checks, and cross-platform GitHub Actions
has not executed steps. **No merge, release, or claim that
all Python algorithms are implemented natively in R.**


## Scientific qualification: functional bootstrap confidence bands (HOLD)

**27 October 2026 follow-up:** The independently seeded
[four-DGP, 200-dataset-per-condition robustness expansion](docs/native-band-robustness-expanded-2026-10-27.md)
completed **2,400 generating datasets / 14,400 paired method evaluations**
with no reported fit failures. Existing fixed-SE 90% simultaneous bands
remain severely under-covering in several small-cluster conditions
(heavy-t(3) N=12 group contrast **53.5%**). Experimental studentization
improved observed coverage in all **24** cells, but its bands were
**1.063–2.036× wider**, and three cells remained below 90% observed
coverage. The owner-run **read-only trial-level audit passed**,
verifying 2,400 generating study keys, all 14,400 method/estimand
records, all 72 summary cells and 48 paired comparisons without
missing fits. All 48 candidate comparisons had **zero observed
baseline-covered/candidate-missed study outcomes**, but the
candidates were uniformly wider on average; this is not a
coverage-validity theorem. **No missingness scenario has been tested.**
A separate [missing-gaze observation-process research protocol](docs/missing-gaze-observation-process-qualification-2026-10-27.md) now defines full-population versus selected/observed estimands and distinguishes MCAR, MAR, MNAR, participant dropout and sparse asynchronous sampling. It has **not been executed** and does not add or replace an estimator.

No estimator substitution, merge or release is authorized.

On 26 October 2026, the author ran the
[known-truth band stress pilot](docs/native-band-coverage-stress-2026-10-26.md):
**60 independently generated datasets** (20 each at N=12, 24, 48
participant clusters), with paired participant-mean and true-null
two-group contrast methods (120 fits), B=99 and nominal 90%
simultaneous coverage. All fits completed, but coverage ranged from
**75–90%** for the mean bands and **65–85%** for group contrasts.
At N=24, the contrast covered 13/20 datasets (65%; exact 95% MC
interval 40.8–84.6%). These are exploratory synthetic results,
not proof of nominal calibration.

A larger, **disjoint** 200-dataset-per-size / B=399 study is now
**complete**, with zero fitting failures. Across N=12/24/48, the
participant mean achieved **63.0%, 75.5%, 87.0%** simultaneous
coverage and the two-group null contrast **55.0%, 76.0%, 83.5%**,
respectively (nominal 90%). Five of six exact 95% Monte Carlo
intervals exclude the nominal target on the low side. This
strongly reinforces that the fixed-SE bands are **not calibrated**
in the tested known-truth hierarchical design.

A [paired experimental interval comparison](scripts/compare_native_band_intervals.R)
has now completed a 30-study-per-participant-size pilot (B=199) with
**540 successful candidate evaluations and no failures**.
The studentized cluster bootstrap improved observed simultaneous
coverage in all six cells relative to fixed-SE bands, but required
**8.0–78.3% wider intervals**, depending on participant count
and estimand. N=24 and N=48 group contrast coverage remained below
90% nominal. The Gaussian Bonferroni-t reference yielded still
wider bands and has **restricted normality/equal-variance assumptions**.
The independently seeded **200-study-per-participant-size**
comparison (B=399) has also completed **3,600/3,600 candidate
evaluations**, with zero reported fit failures. Studentized coverage
improved relative to fixed-SE in all six cells (mean:
73.0%→97.5%, 80.0%→88.0%, 82.5%→87.5%; null contrast:
62.5%→97.0%, 80.5%→91.0%, 88.0%→94.5% for N=12/24/48).
However, studentization increased average band width by
**7.1%–73.7%**, and these results do not establish general
90% calibration. The reference Gaussian Bonferroni-t intervals
remained substantially wider under their restricted assumptions.

Both the 30-study and 200-study
[paired candidate archive audits](scripts/audit_paired_band_candidates.R)
**passed** in the author's R environment. The expanded read-only audit
verified 3,600 paired records and showed that all studentized
coverage gains corresponded to recovered previously missed datasets,
with **zero observed baseline-covered/candidate-missed records**.
The studentized candidate was consistently wider than the fixed-SE
baseline; this does **not** prove calibration.

A [distributional robustness stress script](scripts/stress_native_band_distributions.R)
is now staged to compare methods across Gaussian, heavy-tailed
Student-t, unequal group-variance and centered skew-lognormal
participant effects. This script is **not yet executed locally**,
and deliberately excludes missingness, which requires a separate
known-estimand observation-process study. Another source-review correction: the comparison's
legacy `avg_pointwise_rate` field actually represented average
coordinate inclusion *within a simultaneous band*, not
pointwise confidence-interval coverage. The research script now
uses an accurate field name; archived results remain unchanged.
No method has been certified or substituted into the package. The script
[`scripts/stress_native_band_coverage.R`](scripts/stress_native_band_coverage.R)
now checks previous trial archives for seed collisions before any
new simulation. Use `ET_BAND_MC_SEED_OFFSET=30000000` for a
new study instead of reusing the pilot offset. This preflight
guard **passed its author-run negative acceptance test** on five
known repeated generating-study seeds, before fitting.
Bootstrap inference remains **experimental and not
release-qualified**. No estimators were modified.

## Split-conformal false-alarm pilot and 2,000-study replication completed

A failure-inclusive [frozen-FPCA conformal Monte Carlo study](docs/conformal-fpca-monte-carlo-audit.md)
is now part of this research branch. The author successfully completed its
200-study-per-scenario pilot on Windows 11 / R 4.6.1 on 26 October 2026,
with zero fit failures across 600 independently generated datasets.
[Full pilot evidence and exact Monte Carlo intervals](docs/conformal-pilot-results-2026-10-26.md)
are documented separately. It evaluates one independent held-out inlier and a paired
deliberately shifted curve per simulation, under three separate scenarios:
exchangeable curves, test-noise distribution shift, and correlated
calibration trials from repeated participants. **Only the first design**
has the classical finite-sample exchangeability guarantee.

~~~r
Sys.setenv(ET_CONFORMAL_REPS = "200",
           ET_CONFORMAL_ALPHAS = "0.05,0.10")
source("scripts/run_conformal_monte_carlo.R")
~~~

Results are archived under
`artifacts/conformal_monte_carlo/run_YYYYMMDD_HHMMSS_pidNNNN/`, with
per-study seeds, fit status, exact Monte Carlo intervals and diagnostic plots.
Use `source("scripts/read_conformal_results.R")` to inspect the most recent
completed archive. The rank-oracle R test fixture passed.
In the exchangeable condition, observed false alarms were 4.5% and 6%
against rank references 5% and 10%; both exact 95% Monte Carlo intervals
contain the benchmark. Test-only noise shift raised false alarms to
21.5% and 37.5%. This is an exploratory pilot, **not final empirical
conformal qualification**, and it does not repair functional-band
undercoverage. No merger or release is implied.

Large-run results and their **600 overlapping pilot seeds** are
recorded in [the 2,000-study conformal audit](docs/conformal-replication-results-2026-10-26.md).
The 2,000-dataset-per-scenario run is an extension of the 200-study
pilot, not a disjoint replication. Its **author-run revised audit
passed**, verifying numerical identity of all 600 overlapping study
IDs and confirming 1,800 genuinely new datasets per scenario.
The pre-run conformal seed-collision guard passed its local
author-executed negative acceptance test.
Under independent exchangeability, author-reported false alarms were
**.055 and .098**, consistent with .05/.10 rank references given Monte
Carlo uncertainty; test-only noise shift inflated rates to .220/.414.
The uploaded 1,200-row file belongs to the initial 200-study pilot.
The larger archive's matched records were verified on the author's
local R session. Its remaining scientific limitations are distinct
from this reproducibility correction; no release claims are warranted.
Run `source('scripts/audit_conformal_replication.R')` again to
reproduce the read-only overlap and new-only estimates.

***
## Research branch: native R parity stage 1 (WINDOWS CHECK PASSED)

This development branch is **0.4.1.9000, not released or CRAN qualified**.
It adds 10 narrow native-R research exports to the previous 88 native
functions, while preserving all 380 named optional Python-backed wrappers.
New methods cover explicit piecewise-linear landmark registration,
time-delay embedding, scalar event return maps, undirected recurrence
network diagnostics, frozen-FPCA split-conformal anomaly screening,
and an offline R backend catalog. These are not full Python algorithm parity.

See [official CRAN package survey and remaining scientific gaps](docs/native-parity-research-2026-10.md). Pull this research branch before
running the dedicated test fixtures and full CRAN check:

~~~r
Sys.setenv(ET_RUN_PYTHON_TESTS = "false", MPLBACKEND = "Agg")
testthat::test_local(".", filter = "native-parity-stage1",
                     reporter = "summary")
source("scripts/local_qualification.R")
source("scripts/run_cran_qualification.R")
~~~

**Test evidence:** the author-run full Windows R 4.6.1 CRAN-style check
of 0.4.1.9000 completed with 0 errors, 0 warnings and 1 incoming NOTE,
including tests, manual builds, and successful native research examples.
The research examples were refined after this check; the refinements
require a new test/example run. Linux/macOS and independent numerical
and scientific qualification remain open. Do not merge or release yet.

***
## Python–R capability parity: what is available?

The R package has **380 named optional Python-backed function wrappers**
(362 root + 18 workflow callables), and the author-verified installed
Python API census was **380/380 callable**. These are available *through
reticulate*, not 380 independent native R implementations. The package
also exports **98 native `etr_*` functions on this research branch**, but their count is not
a 1-to-1 algorithm mapping against the Python functions. Classes and
constants are available via `etpy_get_export()`.

A new [capability matrix](docs/r-python-capability-parity.md) identifies
the main native gaps and distinguishes package interfaces from numerical
or inferential qualification. You can produce an exact full export and
candidate native analog report with:

~~~r
source("scripts/report_python_r_capabilities.R")
~~~

The report saves CSVs in `artifacts/capability_parity/` and does not
initialize Python unless `ET_CAPABILITY_CHECK_PYTHON=true`. A further
review against Python `main` on 26 October 2026 found **no changes**
to either namespace's exported symbol list since the October 25
snapshot. Real behavioral and scientific parity remain incomplete;
notably sparse asynchronous multivariate modelling, functional
mixed-effects inference, generalized regression, registration/elastic
analysis, nonlinear dynamics, and uncertainty calibration.

***
## Optional ggplot2 figure upgrade (all plots remain in R)

Run `install.packages('ggplot2')` once, then from the source project root:

~~~r
source("scripts/run_native_ggplot_gallery.R")
~~~

This reuses **exactly the same synthetic datasets and estimates** as the
five-figure native/base-R example. It adds cleaner horizontal multilevel
labels, participant mean and group-contrast ribbons, sparse-support bars,
and transfer-entropy surrogate plots with an explicit annotation when
the observed statistic lies outside the surrogate x-range.

The output folder `artifacts/native_ggplot_gallery/` contains a multipage
PDF, five standalone PNG figures, summary CSV and provenance manifest.
The visual rewrite is optional development tooling: it adds **no required
Python dependency, no scientific estimator changes, and no new CRAN
required imports**. The script and its output have not been tested
by local RStudio yet.

***
## October 2026 follow-up: native worked gallery and interval audit

The author executed these native R examples on Windows 11 / R 4.6.1,
alongside full CRAN-style checks. The examples and earlier 0.4.0.9000
version passed without errors or warnings (one incoming NOTE):

~~~r
# Five native graphics and CSV diagnostics; no Python required
source("scripts/run_native_worked_gallery.R")

# Paired study: original fixed-SE bands versus an independent Gaussian
# Student-t Bonferroni reference, reporting coverage AND interval width
Sys.setenv(ET_INTERVAL_SIMS = "30", ET_INTERVAL_B = "199")
source("scripts/run_phase3_interval_comparison.R")
~~~

The gallery writes to `artifacts/native_worked_gallery/`, the paired study
to `artifacts/phase3_interval_comparison/`, and both retain failure-inclusive
or methodological provenance. The comparator is deliberately conservative
under its stated independent Gaussian assumptions and is not a replacement
for any estimator or a general confidence-band guarantee.

A new **manual-only** R cross-platform matrix targets Windows, Ubuntu
and macOS plus Ubuntu previous R release. GitHub runner admission remains
unresolved, and the matrix has not executed.

See [native worked examples and platforms](docs/native-worked-gallery-and-platform-plan.md)
and [paired interval study](docs/phase3-paired-interval-comparison.md).

***
## Full CRAN-style checks and examples

The pre-submission local test runner is
[scripts/run_cran_qualification.R](scripts/run_cran_qualification.R):

~~~r
source("scripts/run_cran_qualification.R")
~~~

It performs source-build `R CMD check --as-cran` including the PDF manual
(requires a working TeX installation), exercises the package Rd examples
and test suite, and runs a separate native example that creates numerical
outputs and a three-figure PDF. Generated qualification reports go to a
timestamped directory beside the repository rather than into the package.
For the standalone example, PDF and CSV outputs are now saved in
`artifacts/cran_native_example/` under the project root.
The CRAN-facing stage disables opt-in Python tests and is offline-safe;
Python integrations are tested separately. The owner-run full Windows
`--as-cran` check on 25 October 2026 finished with **0 errors,
0 warnings and 1 CRAN incoming-feasibility NOTE** (new submission /
development version). The full PDF/HTML manuals, package tests and real
examples passed. The runner now reports notes as requiring review, rather
than misclassifying a no-error/no-warning run as a test failure.
This is **not CRAN submission approval**. See
[the qualification runbook](docs/cran-qualification-runbook.md).

***
## Complete Python-backed function API — 380 explicit R wrappers

**Python bridge expansion introduced in 0.4.0.9000 (private; unreleased).** The
eyetrajectoriespy GitHub main snapshot on 25 October 2026 defines 362
root public functions and 18 module-scoped workflow functions.
All **380 Python callables** now have named R wrappers:

- `etpy_fit_fpca(...)` and the other 361 `etpy_*` root wrappers
- `etpy_workflow_run_fpca_workflow(...)` and 17 other workflow wrappers
- `etpy_catalog()` gives the exact 380-function manifest without initializing Python
- `etpy_catalog(include_nonfunctions = TRUE)` catalogs 508 symbols:
  458 root and 50 workflow exports; 128 are classes or constants
- `etpy_verify_api(strict = TRUE)` verifies that your installed Python
  distribution actually provides every recorded callable
- `etpy_get_export("FPCAWorkflowConfig", .namespace = "workflows")`
  retrieves an exported Python class or constant without invoking it

~~~r
library(eyetrajectories)
nrow(etpy_catalog())  # 380 recorded root + workflow functions
gaze <- etpy_simulate_planar_trajectories(
  n_participants = 6L, trials_per_participant = 2L,
  n_time = 41L, random_state = 7L
)
fit <- etpy_fit_mfpca(gaze, n_components = 0.95,
                      scaling = "dimension_sd")
head(et_to_r(etpy_fpca_score_frame(fit)))
etpy_verify_api(strict = TRUE)
~~~

**Scientific scope:** The new 380 functions are thin Python-backed wrappers,
not 380 independently implemented R estimators. The native `etr_*`
functions remain available without Python (88 in 0.4.0.9000; 98 in the
current 0.4.1.9000 research branch). The named wrappers
require `reticulate` and the declared `eyetrajectoriespy==1.2.0` runtime;
a GitHub source snapshot may differ from the installed PyPI artifact.
Scientific assumptions, optional Python dependencies, and experimental
uncertainty/calibration limitations are inherited from the Python backend.

**Local qualification, 25 October 2026: PASS (user-executed).**
On Windows 11 / R 4.6.1, development version **0.4.0.9000** passed
`testthat` and `R CMD check --no-manual` with **0 errors, 0 warnings,
0 notes**, with opt-in Python bridge and generated-wrapper integration
tests enabled (`ET_RUN_PYTHON_TESTS=true`, `MPLBACKEND=Agg`).
A separate strict installed-runtime census confirmed **380/380**
recorded Python functions were exported and callable. This does **not**
mean every Python function was individually exercised or scientifically
validated. Linux/macOS checks remain pending; GitHub-hosted runners are
still blocked before allocation for this private repository.
[Qualification evidence and open risks](docs/phase3-qualification-status.md).

**Independent known-truth coverage grid:** 100 studies per design
at 12, 24, 48 independent participants had group-contrast simultaneous
coverage 65%, 79%, 84% and participant-mean coverage 63%, 89%, 86%
at a 90% nominal target, with no fit failures. These results do not
qualify the experimental uncertainty procedures; see
[coverage-grid evidence](docs/phase3-coverage-grid-2026-10-25.md).

Source inventory: `inst/extdata/python_api_2026-10-25.csv`.
Call documentation: `?etpy_python_functions`.

***
## Native R scientific core — expanded Phase 3

**Current development version 0.4.1.9000 on this research branch,
private / unreleased.** The native R core exposes **98 native R functions**:
38 Phase 2 core, 50 experimental Phase 3 advanced methods and 10 additional
experimental native parity extensions. Native functions do not initialize Python, although sparse PACE requires
the optional R package fdapace.
The Phase 1 Python bridge remains available under the original et_* interface
for methods not yet ported.

**Current qualification:** [Evidence matrix and remaining work](docs/phase3-qualification-status.md). The local Windows 11 / R 4.6.1 suite passed for 0.4.0.9000, including the 380-function API census and opt-in Python integration tests. Hosted GitHub Actions remains unavailable before runner allocation.

### Advanced R methods (experimental)

The new Phase 3 functions add: fdapace-backed univariate sparse PACE,
two-level descriptive participant/trial FPCA, participant-cluster bootstrap
mean bands, plug-in discrete transfer entropy with circular-shift sensitivity
diagnostics, auditable workflow wrappers and known-truth simulation audits.

~~~r
library(eyetrajectories)
sim <- etr_simulate_hierarchical(n_subjects = 20L, seed = 12L)
multi <- etr_run_multilevel_workflow(sim$trajectories, sim$participant)
print(multi$diagnostics$variances)

bands <- etr_run_mean_band_workflow(sim$trajectories, sim$participant,
                                    B = 199L, alpha = 0.10, seed = 99L)
print(bands$diagnostics)

# Independent synthetic recovery and coverage diagnostics (not validation claims):
coverage <- etr_evaluate_mean_band_coverage(simulations = 10L, B = 99L)
print(coverage$simultaneous_coverage)
~~~

Univariate sparse PACE requires an optional R dependency:

~~~r
install.packages("fdapace")
sparse <- etr_simulate_sparse_known_truth(n_subjects = 45L, seed = 5L)
fit_sparse <- etr_fit_sparse_pace(sparse$curves, max_components = 2L)
head(etr_sparse_pace_scores(fit_sparse))
~~~

The expanded toolkit also includes **participant-stratified treatment contrasts**,
**independently simulated coverage diagnostics**, **participant-grouped FPCA
cross-validation** (rebuilding the PCA on each training fold), marginal sparse
PACE support diagnostics, an optional `refund::pffr` functional mixed-effects
adapter, and explicit transfer-entropy bias/null diagnostics and plots.
All are experimentally scoped rather than qualified inference.

Read the [Phase 3 scientific qualification note](docs/phase3-scientific-qualification.md)
and the [expansion methods article](docs/phase3-expansion-methods.md).
These estimators do **not** yet establish generalized inference calibration,
causal direction, or full Python API parity. Hosted CI remains blocked before runner allocation; local RStudio checks of version 0.4.0.9000 passed.

### Native R quick start (no Python)

~~~r
library(eyetrajectories)

time <- seq(0, 1, length.out = 81)
values <- array(0, c(8, length(time), 2))
for (i in seq_len(8)) {
  values[i, , 1] <- sin(2 * pi * time + i / 10)
  values[i, , 2] <- cos(2 * pi * time + i / 10)
}
gaze <- etr_trajectory_set(
  time, values, curve_ids = paste0("trial_", seq_len(8)),
  dimension_names = c("x", "y"),
  coordinate_system = "normalized", time_unit = "s"
)
fit <- etr_fit_mfpca(gaze, n_components = 0.95,
                     scaling = "dimension_sd")
print(etr_fpca_variance_frame(fit))
print(head(etr_fpca_scores(fit)))
print(etr_pairwise_l2(gaze))
rqa <- etr_rqa_metrics(
  etr_recurrence_matrix(gaze, curve = "trial_1",
                        radius = 0.15, theiler = 2L)
)
print(rqa)
etr_plot_trajectories(gaze)
~~~

The example uses only deterministic synthetic mathematical trajectories.
For reproducible PDF figures, see
[the native Phase 2 example](inst/examples/native_phase2_demo.R)
and the [native methods article](docs/native-methods.md).

**Qualification notice:** This is a draft implementation, not an independently
validated scientific release. The R tests assert 17 frozen mathematical
reference targets, and CI is configured to verify them against published
Python 1.2.0. The original native numerical fixtures passed locally on Windows; cross-platform verification remains outstanding. No calibrated
uncertainty inference or native sparse FPCA is claimed.

***


**Optional experimental R interface to [eyetrajectoriespy 1.2.0](https://github.com/stefanosbalaskas/eyetrajectoriespy)** for continuous and functional analysis of eye-tracking trajectories.

**Phase 1 history:** The optional `et_*` interface still delegates to the published Python 1.2.0 backend; the new `etr_*` interface is independently implemented native R. Neither interface has completed full cross-platform or scientific release qualification.

## Python-backed Phase 1 interface (optional)

- Declare Python 3.11–3.13 and eyetrajectoriespy 1.2.0 using reticulate::py_require().
- Import common-grid gaze data from R data frames without hidden interpolation.
- Simulate reproducible planar gaze trajectories using the Python backend.
- Fit FPCA and MFPCA, extract score tables and explained variance into R.
- Run the published typed Python common-grid FPCA workflow.
- Create matplotlib trajectory/variance figures and save them as PNG or PDF.
- Reach other Python public exports through et_call(), without implying that they have dedicated R interface tests.

Loading the R package **does not initialize Python**. The first bridge function does.

## Installation (authenticated private repository)

Using an authenticated GitHub client, for example pak:

~~~r
install.packages("pak")
pak::pak("stefanosbalaskas/eyetrajectories")
library(eyetrajectories)
~~~

If reticulate manages Python, the declared Python requirement may be downloaded when first needed. For a manually managed Python environment, install the matching Python package first:

~~~sh
python -m pip install "eyetrajectoriespy==1.2.0"
~~~

Select your existing interpreter **before** Python is initialized in the R session (e.g. set RETICULATE_PYTHON to the full path of that interpreter before starting R). See the official [reticulate package guidance](https://rstudio.github.io/reticulate/articles/package.html).

## Quick start: synthetic gaze, MFPCA, scores

~~~r
library(eyetrajectories)

# Synthetic examples only, not human-subject observations.
gaze <- et_simulate_planar(
  n_participants = 20L,
  trials_per_participant = 6L,
  random_state = 7L
)

fit <- et_fit_mfpca(
  gaze, n_components = 0.95, scaling = "dimension_sd"
)

head(et_scores(fit))
et_explained_variance(fit)
et_explained_variance(fit, cumulative = TRUE)

ax <- et_plot_planar(gaze, max_curves = 20L)
et_save_plot(ax, "synthetic-gaze.png")
~~~

## R data frame to Python trajectories

~~~r
gaze_long <- data.frame(
  participant = rep(c("p1", "p2"), each = 8L),
  time = rep(seq(0, 1, length.out = 8L), times = 2L)
)
gaze_long$x <- gaze_long$time + as.numeric(gaze_long$participant == "p2")
gaze_long$y <- gaze_long$time^2

gaze <- et_from_long(
  gaze_long,
  curve_columns = "participant",
  time_column = "time",
  value_columns = c("x", "y"),
  coordinate_system = "normalized",
  time_unit = "s"
)
fit <- et_fit_mfpca(gaze, n_components = 1L)
head(et_scores(fit))
~~~

Every trajectory must share a common time grid; duplicate timestamps and hidden interpolation are intentionally not accepted. Missingness, preprocessing, and coordinate semantics require deliberate treatment upstream.

## Declared Python workflow

~~~r
gaze <- et_simulate_planar(random_state = 7L)
run <- et_run_fpca_workflow(gaze, scaling = "dimension_sd")
head(et_scores(run$fit))
~~~

Other public Python functions and workflow constructors remain accessible using:

~~~r
et_call("fit_fpca", gaze, n_components = 0.95)
# Advanced workflows are module-scoped:
et_call("FPCAWorkflowConfig", n_components = 0.95,
        .namespace = "workflows")
~~~

The default is to retain Python objects as Python proxies. Convert supported results explicitly with et_to_r().

## Check and integration tests

~~~sh
R CMD build .
R CMD check --as-cran eyetrajectories_0.4.0.9000.tar.gz
~~~

R-only tests do not need an installed Python backend. Real bridge integration tests are opt-in:

~~~sh
ET_RUN_PYTHON_TESTS=true Rscript -e 'testthat::test_local(".", filter = "python-integration")'
~~~

The integration environment must already have Python 3.11–3.13 and eyetrajectoriespy 1.2.0, or allow reticulate to resolve the managed environment. GitHub Actions defines separate R-only checks and real Python integration tests.

## Scientific scope and roadmap

The Python implementation is the numerical source of truth during Phase 1. Interface parity with Python does **not** establish independent R implementation, estimator calibration, or scientific validity. Existing Python research limitations, particularly for W3 inference calibration and observation-dependent missing gaze, remain in force.

See [Phase 1 design and boundaries](docs/phase1-scope.md). Planned Phase 2 work is a separately validated native R core; no CRAN release is authorized by this development branch.

Copyright (c) 2026 Stefanos Balaskas. MIT License.
