# Complete one-to-one Python 1.2.0 → native R implementation programme

**Target: Python-free execution of every public scientific capability**, not merely calling Python functions from R. The existing `reticulate` bridge stays optional for compatibility and as an external numerical oracle; a function cannot be classified as complete unless its native R implementation itself executes without Python.

**Reference:** published `eyetrajectoriespy==1.2.0`, Python `__all__` snapshot pinned in `inst/extdata/python_api_2026-10-25.csv`. The public API comprises **380 functions** (362 root + 18 workflow) and **128 other symbols** (Python classes, configuration objects and constants). Not all symbols are independently meaningful algorithms; nevertheless, *each* must receive an explicit native-R representation or documented compatibility boundary. No automatic mechanical one-to-one equivalence is presumed.

## Baseline — structural, not scientific parity

- R research branch `0.4.1.9000` has **98** native `etr_*` exports and **380** optional Python-backed `etpy_*` wrappers before this native stage. Counts are not comparable algorithm-for-algorithm.
- Existing R code reports **37 named native-function analogues**, but their names alone do not demonstrate mathematical/behavioral parity.
- This stage adds **4 genuine Python-free R algorithms**: `etr_acceleration_magnitude` (`acceleration_magnitude_function`), `etr_distance_to_landmark` (`distance_to_landmark_function`), `etr_signed_curvature` (`signed_curvature_function`) and `etr_turning_rate` (`turning_rate_function`). These follow the published Python finite-difference definitions and missing-value policies. Dedicated analytic irregular-grid tests and *opt-in* independent R–Python numerical oracle tests have been committed; execution has not yet been confirmed.
- The initial conservative full register therefore has **41 named native analogues/candidates, including 4 new implementations**, **339 Python function names without a specified native counterpart**, and **128 additional Python symbols whose native representation is not yet reviewed**. **Zero claims of fully independently qualified one-to-one contracts** are automatically granted by the register. The register is a gap inventory, not a measure of algorithm correctness.

Run from the updated native research checkout:

```r
pkgload::load_all(".", quiet = TRUE)
testthat::test_local(".", filter = "native-planar-geometry-parity")
testthat::test_local(".", filter = "full-native-r-parity-ledger")
source("scripts/report_full_native_r_parity.R")

# Optional independent Python numerical oracles (NOT required for native use):
Sys.setenv(ET_RUN_PYTHON_TESTS = "true", MPLBACKEND = "Agg")
testthat::test_local(".", filter = "native-planar-geometry-parity")
Sys.unsetenv(c("ET_RUN_PYTHON_TESTS", "MPLBACKEND"))
```

Native functions work without Python; only the optional cross-language oracle test imports Python. The report writes a **508-row machine-readable audit**, grouped statuses and a non-overwriting manifest to `artifacts/full_native_r_parity/audit_.../`.

## Workstreams required for full parity

| Family | Required native-R work and qualification |
|---|---|
| Data contracts / preprocessing / coordinate metadata | Reproduce Python `TrajectorySet` fields, validation, provenance, reversible R serialization, missing-data policies, smoothing, phase transforms |
| Continuous dense functional analysis | Weighted FPCA/MFPCA, score reconstruction, eigenvector subspace invariance, numerical quadrature and advanced uncertainty |
| Sparse and irregular functional data | PACE, joint asynchronous multivariate covariance, irregular channels, bandwidth selection, sparse multilevel and sparse predictions |
| Hierarchical inference | Full functional mixed effects, covariance variants, nested random effects, bootstrap refits, prediction and residual diagnostics |
| Functional regression | Function-on-scalar and scalar-on-function, generalized models, wild/bootstrap inference, model selection and prediction |
| Alignment / elastic geometry | Registration, phase FPCA, elastic square-root velocity, compositional/phase-aware geometry |
| Nonlinear methods | Recurrence, joint/cross recurrence, RQA, networks, Lyapunov/embedding, transfer entropy, multivariate surrogates and sensitivity |
| Anomaly / uncertainty | Conformal validity, outliers, score/spectrum inference and split/partial conformal conditions |
| Public workflow layer | Every declared Python workflow entry, configuration object, result class, reporting/plotting, export/portability schema |
| Scientific qualification | Independent known-truth Monte Carlo, robustness, coverage, conditional observation support, failure-inclusive auditing |

Develop functions in small reviewable native groups, but maintain the 508-symbol inventory across every group. A source-name count or a bare R wrapper will never qualify a missing estimator.

## Acceptance rules for each Python function

A native function must satisfy **all** of the following before it is marked one-to-one equivalent:

1. **Python-free runtime:** the R method does not invoke `reticulate`, Python or shell-out Python, including inside optional branches.
2. **Contract equivalence:** supported inputs, dimensions, defaults, missingness behavior, exceptions, numerical assumptions, metadata and output schema are documented against the exact pinned Python code.
3. **Independent numeric oracle:** tests compare R results with Python reference outputs on **independent** fixed and randomized cases, using appropriate invariant subspace/phase comparisons where raw coefficients are non-unique.
4. **Failure and edge cases:** small `n`, irregular time, incomplete observations, singular operators, degenerate eigenvalues and unavailable optional backends fail or recover as specified.
5. **Reproducibility:** deterministic seeds, provenance, pinned dependencies, artifacts, cross-platform R CI and exact-head review pass.
6. **Inference claims separated:** coverage/power/identifiability must be demonstrated separately, not inferred from implementation or computational equivalence.

The fail-closed `etr_native_parity_catalog(require_complete=TRUE)` must remain an error until the entire inventory genuinely meets the required contracts. It intentionally does **not** grant a pass merely because all `etr_*` functions are present.

## Product and merge boundary

The Python-backed integration PR #7 remains a separate user-convenience path, not fulfillment of native parity. This native project is independently staged against `research/native-parity-stage1`. It does not modify or promote known-failing 90% simultaneous confidence bands or unresolved MNAR identification. No main merge, public release or CRAN submission is implied.


## Owner-executed Stage 2 qualification — 27 October 2026

On the native branch in RStudio, both expected test files were present, and
the owner completed these independent local tests:

- `testthat::test_local(".", filter="native-planar-geometry-parity")`:
  **40 PASS, 1 SKIP, 0 FAIL, 0 WARN**. The sole skip was the
  explicitly opt-in Python-vs-R numerical oracle; all native analytical
  and boundary checks executed successfully.
- `testthat::test_local(".", filter="full-native-r-parity-ledger")`:
  **35 PASS, 0 SKIP, 0 FAIL, 0 WARN**.
- `source("scripts/report_full_native_r_parity.R")`:
  generated the full 508-symbol catalog; **380 function contracts,
  128 nonfunction contracts, 41 name candidates, 4 newly implemented native
  algorithms, 37 existing but unqualified analogues, 339 unmapped Python
  functions and zero independently certified one-to-one contracts**.

Owner-local output:
`artifacts/full_native_r_parity/audit_20261027_182923_pid51684/`.
The source CSV was not uploaded/independently read; counts above are from
the owner's console transcript.

**Next required test:** In a separately verified managed Python 3.12
environment containing stable `eyetrajectoriespy==1.2.0`:

```r
pkgload::load_all(".", quiet = TRUE)
stopifnot(identical(et_python_version(), "1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS = "true")
testthat::test_local(".", filter = "native-planar-geometry-parity")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

This runs the independent numeric Python-reference test as well. It is
only a **four-method fixture comparison**, not exhaustive parity on all
input distributions or all Python functions.

**Superseded for the four fixed-reference cases:** the owner later executed
the opt-in numerical oracle successfully (details below). Generalized
numerical and scientific one-to-one qualification, full 508-symbol parity,
and cross-platform CI remain open. Keep PR #9 draft and the release gate
closed; GitHub Actions has still not executed any steps.

## Independent Python v1.2.0 numerical comparison — owner PASS, 27 October 2026

On Windows in RStudio, the owner explicitly verified
`identical(et_python_version(), "1.2.0")`, enabled
`ET_RUN_PYTHON_TESTS=true` and executed

```r
testthat::test_local(".", filter="native-planar-geometry-parity")
```

The complete output was **FAIL 0, WARN 0, SKIP 0, PASS 56**. The opt-in
independent R-vs-Python numerical oracle was **executed**, not skipped.
All four newly implemented R methods (`etr_acceleration_magnitude`,
`etr_distance_to_landmark`, `etr_signed_curvature`,
`etr_turning_rate`) therefore agree with the published Python reference
for the original deterministic, irregular-grid fixtures within the test
tolerance. This also preserves the previously observed 40/40 native
analytic and 35/35 ledger assertions.

**Do not interpret these 56 assertions as 56 independently tested
methods**, nor automatically set `one_to_one_native_contract_complete`
to TRUE: additional randomized inputs, low-speed/missingness boundary
comparisons, explicit output-schema/provenance agreement and cross-platform
tests still matter. The conservative native parity ledger therefore
continues to report **0 of 508 fully qualified one-to-one public contracts**.
The independent test output is owner-provided console evidence, not CI
or an uploaded test artifact.


## Expanded owner-run independent numerical oracle — PASS 296/296

**Observed on 27 October 2026:** After updating the native research branch,
the owner reran `testthat::test_local(".", filter =
"native-planar-geometry-parity")` with `ET_RUN_PYTHON_TESTS=true`
and exact Python `eyetrajectoriespy==1.2.0` already verified in
the preceding qualification. RStudio reported:

```text
native-planar-geometry-parity [1.2s]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 296 ]
```

This includes the previous **56 assertions** and **240 additional
assertions** from 12 deterministic seeded irregular/noisy/degenerate
scenarios, across four newly written independent native R kinematic
operations. The 12 scenarios exercise varying numbers of curves,
irregular time grids, perturbed nonlinear trajectories, exactly stationary
trajectories, per-curve landmarks, low-speed undefined masks, output
dimensions and named channels; numerical comparison tolerance on the
added cases is `1e-8`. This is a real executed cross-language oracle
at the tested configurations, not a simple import/name-availability
check.

**Qualification boundary:** The above is owner-provided local RStudio
console evidence; a machine-readable oracle archive was not supplied.
These 296 test expectations are **not 296 separately implemented
functions**. The native implementations and their tested numerical
behavior are validated on these fixtures, but semantic exceptions,
metadata/provenance representation, exhaustive missing-data patterns,
randomized coverage across broader parameter regions, independent
Windows/Linux/macOS reproduction, and all remaining Python public
exports remain to be addressed. The fail-closed `etr_native_parity_catalog()`
still marks **zero complete 508-symbol contracts** automatically, because
the ledger is a conservative static inventory rather than a proof derived
from test execution.

Next development work is broader native R algorithm coverage and
standalone scientific/data-contract qualification, rather than rerunning
the same four-method fixture repeatedly.


## Stage 3 native-R expansion — draft PR #11 (code complete; runtime pending)

[Stage 3 draft PR #11](https://github.com/stefanosbalaskas/eyetrajectories/pull/11)
adds seven Python-free native R algorithms spanning pixel normalization,
per-curve landmark centering, arbitrary time-domain normalization, heading
with stationary-gaze policy, tortuosity tables, weighted pairwise discrete
Fréchet distances, and functional-L2 nearest-trajectory ranking. These
seven source functions replace four under-specified earlier native
analogues and add three previously unmapped Python function names.

**Updated exact map:** 44 native analogue candidates among 380 public
Python functions; **336 unmapped** function names; **128 other public
Python objects** still awaiting native representation; **11 newly
implemented algorithms** across Stages 2 and 3 (four and seven).
A candidate count is **not** a numerical parity rate.

**Superseded by the owner-run result of 27 October 2026:** the native-only Stage 3 tests passed **60 assertions** (two optional Python skips), and the complete Python-enabled suite then passed **347/347 assertions, zero failures or skips** on Windows. The console also emitted two Python NumPy RuntimeWarnings on deliberately incomplete gaze; see [the full Stage 3 record](full-native-r-stage3-preprocessing-distances.md). The strict 508-contract completeness requirement remains separate from these seven numerical oracle results. The multi-OS workflow
[run #40571516967](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40571516967)
failed at runner admission with zero recorded steps in all four jobs,
which is not a scientific algorithm outcome. The strict 508-source
completion gate remains closed; no release or main merge.


## Stage 4 — full native R path-based Fréchet / DTW (draft)

Stage 4 extends [the Stage 3 Windows-verified 347/347 numeric assertion
checkpoint](full-native-r-stage3-preprocessing-distances.md) with three
independently written Python-free R sequence-distance methods:
`etr_discrete_frechet()` for deterministic optimal coupling,
`etr_dynamic_time_warping()` for symmetric1/symmetric2 index-windowed
alignment and path-normalization/cost audits, and
`etr_pairwise_dtw_full()` for complete pairwise distance options.
The two standalone full scalar/path functions supersede narrower name
analogues for *new* calls while preserving old user-facing R functions.

**Cumulative port inventory:** 45 named native R candidates out of
380 callable Python 1.2 public exports, **335 unmapped Python function
names**, 128 other public objects still to review, and **14 new
independently implemented native R functions** over Stages 2/3/4
(4+7+3). The name count is not numerical equivalence qualification.

Stage 4 [contract specification and test instructions](full-native-r-stage4-frechet-dtw.md)
define zero-based coupling indices, deterministic Python tie order,
unconstrained/Sakoe-Chiba DTW and normalizable symmetric2.
A **declared resource cap of 5 million point pairs** is a deliberate
native R/Python behavioral deviation and still requires policy review.
Machine-readable full 508-contract gate must remain fail-closed. The
new native-only tests have now passed locally (**64 PASS, two expected
Python-test SKIPs**), and the owner-run Python 1.2 numerical oracle passed
**733/733 assertions, zero FAIL/WARN/SKIP** on Windows after separately
confirming the reference version. The Stage 4 parity ledger passed
**26/26** assertions. Cross-OS CI remains unverified because the GitHub
Actions jobs still run **zero steps**. See the
[qualified Stage 4 record](full-native-r-stage4-frechet-dtw.md#stage-4-windows-qualification--owner-run-pass-27-october-2026)
for scope, evidence, and remaining source-contract deviations. No release
or main merge.


## Stage 5 — native trajectory provenance and versioned R snapshots (draft PR #13)

[Stage 5 draft PR #13](https://github.com/stefanosbalaskas/eyetrajectories/pull/13)
introduces backwards-compatible native R `etr_trajectory_set(provenance=list())`,
a Python-`TrajectorySet.with_values`-style nonmutating shallow
update, provenance-preserving `etr_subset()`, source audits
for `etr_from_long()`, and preservation of input provenance through
Stage 3 normalization/centering and planar derived functions.
The new `etr_trajectory_snapshot()` and
`etr_restore_trajectory_snapshot()` support versioned RDS
round-trips with explicit schema and shape validation.

This work improves object/metadata scientific traceability, *not* the
source-level mapping count of Python callable exports. The frozen
inventory remains **45 named candidate R functions among 380 Python
callables**, **335 unmapped callable names** and **128 other public
objects**. Among those 128, exactly **one Python class —
`TrajectorySet` — is now classified as a partial Stage 5 native
representation** and **127 remain not reviewed**. The Stage 5
`TrajectorySet` representation is deliberately **not** marked as a
fully qualified one-to-one Python contract. The legacy Python-backed
`reticulate` bridge is not a native replacement.

The native R snapshot is **not** Python's
`portable_results.py` JSON+NPZ scientific-result interchange schema:
no Python portable loader or cryptographic integrity proof is claimed.
The full 508-export parity completion gate remains CLOSED.

Stage 5's owner-run Windows qualification has **passed**:
native-only `native-stage5-trajectory-provenance` **62 PASS /
1 expected Python-oracle SKIP**, the Stage 5 parity ledger **19 PASS**,
and the opt-in Python 1.2 `TrajectorySet` provenance/reference suite
**106 PASS / 0 FAIL / 0 WARN / 0 SKIP**. See the
[Stage 5 technical record](full-native-r-stage5-provenance-snapshots.md#stage-5-corrected-qualification--windows-rstudio-pass-27-october-2026).
Complete ecosystem regression testing, Python JSON+NPZ portable-format
equivalence and independent 3-OS CI remain open. No main merge or release.


## Stage 6 — Python-format scientific result imports in pure R (research)

[Stage 6 source contract and repeatable qualification steps](full-native-r-stage6-python-portable-reader.md)
extend Stage 5's RDS-only native snapshots with a genuinely native R
**read-only** implementation for Python's published v1
`load_portable_result()` JSON+NPZ scientific-result format. The
loader verifies `arrays.npz` SHA-256, rejects unsafe/unsupported
NumPy payload descriptors without pickle, and reconstructs the
supported scientific state (arrays, identifiers, units, numeric and
string metadata, explicit nonportable object markers) without
initializing Python. The JSON manifest itself is not signed.

Only optional R packages `jsonlite` and `digest` are added as
suggested dependencies. No Python package or Python runtime is
required by the native loader. Reproducibility tests generate actual
Python 1.2 dataclass snapshots using the published
`export_portable_result()` oracle and verify independent R decoding.

**Cumulative inventory:** **46** of **380** public Python callable
names now have identified native R candidate functions, **334**
remain unmapped, **15** independently written native R functions
have been added over Stages 2/3/4/6 (four plus seven plus three
plus one). Stage 5's four native R support functions are counted
separately, not invented mappings. Among **128** other public
objects, one `TrajectorySet` representation remains partial and
127 are not yet reviewed. Full **508/508** source-contract
completion remains blocked.

Important qualification boundary: Stage 6's native reader uses a
restricted dtype/subtype set and explicit resource limits. It
does not implement a Python portable **writer**, unsupported Python
dtype behavior, fitted-backend reconstruction, or general Python
`load_portable_result` equivalence. The prior Windows-local
Stage 2–5 qualification results remain unchanged. **Stage 6 has now
passed owner-run Windows tests:** native R parser **18 PASS with one
intentionally skipped Python reference test**, strict Stage 6 ledger
**20 PASS**, and opt-in Python 1.2 JSON+NPZ interoperability oracle
**79 PASS / 0 FAIL / 0 WARN / 0 SKIP**. These are selected Windows
fixture results, not general Python-format equivalence.
[Execution evidence and boundaries](full-native-r-stage6-python-portable-reader.md#owner-windows-rstudio-verification--pass-on-27-october-2026).
Independent CI remains blocked before job execution; keep draft PR
#14, releases and main merge on HOLD.


## Stage 7 — faster batch parity development (10 independent native R methods)

[Draft PR #15](https://github.com/stefanosbalaskas/eyetrajectories/pull/15)
implements ten published Python 1.2 public callable candidates in
one research increment. Three scientific validation functions
(`validate_common_grid`, `validate_simplex`,
`validate_no_long_missing_runs`), six irregular-trajectory
functions (curve-specific long-form import, overlap domain,
common grid, explicit grid resampling, convenience resampling,
sampling summary), and registration landmark deviation reporting
are independently written in R. The new R-native irregular
trajectory object retains per-curve time grids and source metadata.

**Frozen source inventory now: 56 / 380 Python callable function
names have native R candidates, 324 remain unmapped.**
Across Stages 2–4, 6 and 7, **25 new R callable implementations**
were written (4+7+3+1+10). Stage 5 infrastructure remains separately
counted. Among 128 nonfunction public Python symbols, only two
(`TrajectorySet`, `IrregularTrajectorySet`) are partially represented
and **126 others remain unreviewed**. Full source contract
qualification is still **0/508**, with the strict completeness gate
intentionally failing until supported by more evidence.

The new source-to-native test matrix includes independent Python 1.2
comparisons over three irregular multi-curve sampling scenarios,
overlap/union grids, linear interpolation and max-gap missing-value
preservation; analytical validation tests and updated offline source
inventory are committed. **Stage 7 has now passed owner-executed
Windows tests:** native-only **58 PASS / 1 expected Python-oracle SKIP**,
native parity ledger **69 PASS**, and independently enabled Python
1.2 oracle **115 PASS / 0 FAIL / 0 WARN / 0 SKIP**.
[Detailed owner-run qualification](full-native-r-stage7-ten-function-batch.md#owner-executed-stage-7-qualification--windows-pass-28-october-2026).
Python PCHIP remains explicitly unsupported, complete R/Python
data-frame metadata equivalence is not claimed, and cross-platform
GitHub CI had zero executed job steps. The research PR stays DRAFT;
no release/merge is authorized.


## Stage 8 — recurrence-network and nonlinear RQA, ten-function batch

This stage extends the qualified Stage 7 irregular-data work
(owner-run Windows **115/115** Python 1.2 oracle assertions) with
ten independently implemented native R nonlinear recurrence
functions: `recurrence_network`, its node and summary frames,
`joint_recurrence_matrix`, joint component frames and RQA,
cross-RQA, declared recurrence-radius profiles, and
windowed RQA with a functional trajectory representation.

**Counts:** 65 mapped Python callable names among 380 (+9
over Stage 7, because recurrence_network was already listed as
a candidate), **315 unmapped** callable names; **35** independently
new native R callable implementations over Stages 2/3/4/6/7/8,
a growth of ten. Exactly **7** of 128 other public Python
objects/classes have a partial native representation and
**121** remain unreviewed. Full 508-source contract completion
remains zero; the fail-closed gate has not changed.

Independent Python 1.2 reference tests and R analytical cases
were added with the
[Stage 8 nonlinear implementation and reproduction guide](full-native-r-stage8-recurrence-nonlinear.md).
**Stage 8 owner-run numerical qualification (Windows, 28 October
2026): PASS.** The corrected native recurrence filter passed **62
assertions** with **one expected Python-opt-in skip**; the Stage 8
ledger passed **82 assertions** without skips; after verifying the
Python reference version was exactly **1.2.0**, the Python-enabled
recurrence filter passed **189 assertions** without failures, warnings
or skips. The 189 include native assertions and are not independent
additional oracle cases. A malformed negative time-grid fixture was
corrected; no native scientific algorithm or tolerance changed.
[Stage 8 qualification details](full-native-r-stage8-recurrence-nonlinear.md).

**Cross-platform qualification remains blocked:** Stage 8
[Actions run #40598507486](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40598507486)
failed with zero recorded steps in each of four jobs, so GitHub did not
execute numerical CI. Python sparse-graph methods, time-based windows,
target-rate threshold selection, and complete result schemas exceed
the declared native R partial contracts. The 508/508 fail-closed gate
remains closed. This branch is DRAFT, not merged or released.


## Stage 9 — twelve Python-free functional and phase diagnostics (draft)

Published Python 1.2 functions independently implemented in R:
ALR and inverse ALR; component trajectories, variance component selection,
FPCA score frames and score-distance matrices; pairwise functional L2
distance matrices; sparse observed-time density diagnostics; displacement
and phase summaries; phase functional trajectories and native phase FPCA.
These methods share existing Python-free native trajectory, FPCA,
registration and irregular-sampling infrastructure.

**Frozen 508-export inventory:** 77 mapped names among 380 callable
Python APIs, 303 unmapped callable names, 47 newly authored native R
callable implementations (Stages 2-9), seven partly represented
nonfunction Python objects, and **zero fully qualified out of 508**.

A Stage 9 deterministic test suite, optional pinned Python 1.2 direct
numerical oracle and three-OS CI workflow were committed. **No Stage 9
R or Python runtime test execution is claimed** at authoring time.
Earlier Stage 8 Windows results remain independently documented and
must not be misattributed to Stage 9. Cross-platform job admission,
broader input/schemas, inferential validity and actual equivalence
qualification are still outstanding. Research draft only; no release.

[Detailed Stage 9 source and reproduction guide](full-native-r-stage9-functional-diagnostics.md).

## Stage 10 — 15 Python-free FPCA extension contracts (research draft)

Published source version: eyetrajectoriespy==1.2.0, with direct source
inspection of compositional, stability, phase, subspace, reporting and
inference modules. Stage 10 adds 15 Python-free native R functions.
Compositional inverse maps reconstruct onto the simplex; component
matching uses a globally optimal exact assignment for up to 12 FPCs;
reconstruction diagnostics, phase sensitivity, eigengaps and reporting
are separated from inferential certification.

The frozen inventory becomes **92/380 named callable candidates**, **288
unmapped callable functions**, **62 independently authored native R
implementations**, **7 partially represented other symbols**, and
**0/508 fully qualified public contracts**. The Stage 10 deterministic
and pinned Python 1.2 source-oracle tests have been authored but are
awaiting actual execution; the previous Stage 9 owner-reported test
passes do not qualify Stage 10. Research PR must remain draft.

[Stage 10 source-level implementation and reproduction guide](full-native-r-stage10-fpca-extensions.md).

## Stage 11 — Python-free nonlinear scientific reporting

Fifteen additional Python-root reporting callable names are independently
implemented in R. These are **manuscript-text and result-adapter utilities**,
not new RQA/uncertainty/surrogate estimators. Five families consume native
Stage 8 recurrence and windowed-RQA objects directly. Other reports accept
validated source-shaped R results pending upstream estimator implementation.

The 508-export inventory now records **107/380 mapped Python callable
names**, **273 unmapped callable names**, **77 independently authored native
R callable implementations across Stages 2–11**, **7 partial object
representations**, and **0/508 fully certified source contracts**. The
implementation method tally includes 15 new descriptive reporting functions.
Stage 11 tests and Python 1.2 reporting oracle were authored but are not yet
runtime-qualified. The Stage 10 tuple-indexing oracle fixture correction
(182f4dbe) likewise requires an owner-run numerical recheck.

[Stage 11 reporting contracts and qualifications](full-native-r-stage11-nonlinear-reporting.md).

## Stage 12 — native held-out functional PCA CV and source-shaped inference reporting

Stage 12 introduces **14** independently authored Python-free R
functions, including a substantive leakage-aware FPCA held-out
reconstruction CV routine that refits the functional basis inside
each training fold, supports group-blocked participant holdouts, and
applies an explicit minimum-mean or one-standard-error retention
criterion. Declared fixed-target uncertainty, conformal anomaly,
distance-sensitivity and functional-regression prediction frames
are separate non-estimator adapters: no bootstrap or conformal
coverage claim is inferred from table construction alone.

Exact published Python source modules were inspected; direct oracle
comparison uses unshuffled curve KFold, because R's shuffled
permutations and tied group-fold allocation are intentionally not
claimed bitwise identical to scikit-learn. Numerical, leakage and
validation tests are authored but **have not yet run**.

Cumulative frozen register: **121 / 380** named Python callable
mappings, **259** unmapped callable names, **91** Python-free authored
R functions including adapters, **7** partial other-export
representations, **0 / 508** one-to-one certified source contracts.
The 508-contract release gate remains closed.

[Stage 12 full source-level methods and qualification](full-native-r-stage12-cv-uncertainty.md).

## Stage 13 — numerical function-on-scalar models and nonlinear dynamics

Twelve additional independently authored Python-free R functions target
function-on-scalar observed-grid OLS with HC1 standard errors, participant
aggregation, fixed-design wild bootstrap, coefficient/family simultaneous
bands, AMI delay and FNN diagnostics, eigenvalue-based return-map stability,
two reproducible trajectory simulators, Poincare crossings, local return-map fitting and explicit irregular-grid
projection. They are **numerical methods**, not ten reporting aliases.

Inventories: **132/380 mapped callable function names**, **248 unmapped**,
**103 independently authored native R functions**, **7 other symbol
representations** and **0/508 fully certified public source contracts**.
The complete source policy remains fail-closed. Stage 12 owner-run Windows
RStudio native, ledger and pinned Python oracle tests passed 69, 39, and 79
assertions respectively. Stage 13 tests are authored but have not executed.

[Stage 13 source contracts and explicit cross-language limitations](full-native-r-stage13-functional-models.md).


## Stage 14 — native FPCA influence and eigenspace stability (draft)

Seven Python-free R methods now compare weighted principal-angle FPC
subspaces, bootstrap complete curve or participant blocks, summarize
matched component stability, calculate leave-one-group-out influence,
and screen fitted curves using explicit **empirical** score covariance
plus reconstruction-MAD diagnostics. Unsupported robust MCD covariance
fails closed. None of these reports automatically excludes curves or
establishes bootstrap calibration.

Authored research inventory: **110 native R implementations**,
**139 / 380 mapped Python function names**, **241 unmapped**, **7
partially represented other exports**, and still **0 / 508 fully
certified source contracts**. Stage 13 owner-run Windows RStudio
native, oracle and ledger tests passed; Stage 14 tests are authored
but **have not been executed**. All research code remains draft.

[Stage 14 numerical contracts and restrictions](full-native-r-stage14-fpca-stability.md).



## Stage 15 — native observed-grid mean/FPCA bootstrap uncertainty (research draft)

Five additional independently authored Python-free R methods implement
Gaussian-multiplier simultaneous functional-mean bands, sign-aligned
fixed-target FPCA score bootstrap, matched-eigenvalue/ratio bootstrap,
simultaneous FPC shape bands with optional eigengap screening, and
component band tables.

Research inventory: **115 native R implementations**, **144 / 380
mapped Python callable names**, **236 unmapped**, **7 partial other
exports** and **0 / 508 fully certified source contracts**.
Stage 14 Windows RStudio native and Python 1.2 tests passed; Stage 15
is authored but **not runtime qualified**. All intervals are
observed-grid approximations, not exact coverage guarantees.

[Stage 15 source-level methods and statistical boundaries](full-native-r-stage15-bootstrap-inference.md).



## Stage 16 — native discrete and conditional transfer entropy (research draft)

Twelve independent Python-free R functions now calculate exact
integer-coded empirical transfer entropy, conditional transfer entropy,
their local history contributions, analyst-declared source-only
circular-shift nulls, and Cartesian parameter-sensitivity analyses,
with conservative scientific reporting. No discretization, lag
selection, shift generation, causal identification or Python bridge
occurs implicitly.

Cumulative authored inventory: **127 native R functions**, **154 / 380
mapped Python callable names**, **226 unmapped**, **121 pending
nonfunction exports**, and **0 / 508 certified full source contracts**.
Stage 15 owner-run RStudio tests passed all native and pinned Python
source comparisons; Stage 16 is authored but **not runtime-qualified**.

[Stage 16 information-theory source contracts](full-native-r-stage16-transfer-entropy.md).



## Stage 17 — native nonlinear divergence and independent-unit RQA bootstrap (draft)

Six more independently authored Python-free numerical R functions
reconstruct explicitly selected multichannel delay coordinates, estimate
Rosenstein and fixed-radius Kantz divergence curves, fit explicitly
declared Lyapunov slope intervals, and bootstrap curve-level RQA metric
means with optional equal-weight participant aggregation.

The source-census now covers **133 native R implementations** and
**159/380 mapped Python callable names**, leaving **221 unmapped**.
The prior `delay_embed_trajectory` candidate was **replaced**, not
double-counted; 121 other exports remain unrepresented and
**0/508 full public source contracts are certified**. Stage 16 local
native and pinned Python tests passed; Stage 17 code/test suites are
authored but not runtime-qualified. Positive slopes do not establish
deterministic chaos. Adaptive recurrence thresholds and time-unit
delay parameters are explicitly unsupported.

[Stage 17 scientific source contracts](full-native-r-stage17-divergence.md).



## Stage 18 — native restricted functional repeated-measures estimation (research draft)

Seven independently authored Python-free R functions now estimate a
**restricted two-level functional method-of-moments model**, derive
participant covariance and linear-prediction functions, whiten
within-trial residuals, audit physical-time lagged residual dependence,
expose exact residual-pair records, and produce variance and fixed-effect
tables.

**Important:** this is **not** the published Python 1.2
`statsmodels` spline-basis MixedLM/REML likelihood estimator and is
not certified as a replacement. The estimator uses pointwise fixed
effects and participant-group covariance moments, including an explicit
positive ridge. Random slopes, nested trial random functions,
likelihood-optimized serial covariance and simultaneous mixed-model
inference are not implemented.

Frozen inventory: **140 independent R implementations**;
**165 / 380 mapped callable source names**; **215 unmapped**;
**121 pending other source exports**; **0 / 508 fully certified
source contracts**. Stage 17 owner-run native and pinned Python tests
passed; Stage 18 test code has **not yet been executed**.

[Stage 18 numerical contract and limitations](full-native-r-stage18-mixed-diagnostics.md).



## Stage 19 — five native numerical sensitivity/clustering integrations (draft)

Five new **Python-free, independently authored numerical R methods**
evaluate exhaustive Rosenstein/Kantz/RQA parameter multiverses, fit
explicitly seeded K-means to native FPCA score matrices, and audit the
raw-metric rank and nearest-neighbor sensitivity of trajectory-distance
choices. All parameter combinations are retained, with fail-closed
invalid contracts and **no** implicit optimizer/tuning winner.

Cumulative conservative source census: **145 native R implementations**,
**170 / 380 unique mapped Python callable names** and **210 unmapped**;
seven other public exports have partial representations and 121 are
pending; **0 / 508 full source contracts are certified**. Stage 18 owner
RStudio native and NumPy formula checks passed. Stage 19 test fixtures
have been authored, **not run**.

The RQA multiverse currently requires Euclidean fixed-radius/sample-unit
contracts. Hartigan–Wong K-means is **not** bitwise scikit-learn KMeans.
These methods support descriptive sensitivity, not chaos probabilities
or inferential coverage.

[Stage 19 numerical contracts](full-native-r-stage19-multiverse-clustering.md).



## Stage 20 — auditable native source-contract certification starts (research draft)

**Three source contracts now have candidate-level evidence records**:
`alr_transform`, `inverse_alr` and `score_distance_matrix`.
A frozen-source-SHA certification registry independently tracks direct
Python numeric tests, in-domain shape and invalid-input boundaries,
scientific scope and independent reviewer signoff. All four approvals
are required before any contract is **fully certified**; all currently
remain **pending**. **Fully certified: 0 / 508**, not an inflated mapping
count. A new source-oracle suite and explicit owner-run qualification
commands have been committed.

The new **native IAAFT surrogate nonlinearity test** calculates
declared largest-Lyapunov statistics under independent Fourier
surrogates and exact plus-one Monte Carlo tails. This is one additional
Python-free numerical R implementation, not a stochastic NumPy RNG
equivalence claim.

Cumulative inventory: **146 native R implementations**,
**171 / 380 uniquely mapped Python callable names**,
**209 unmapped functions**; 121 other public exports unrepresented.
Stage 19 owner-run tests passed; Stage 20 tests have **not** yet run.

[Stage 20 certification evidence, scientific contracts and audit plan](full-native-r-stage20-contract-certification.md).



## Stage 21 — native R plot geometries and direct source-boundary witnesses (draft)

Four Python-free visual entrypoints now plot native planar gaze, fitted
FPCA component mean/SD profiles, audited zero-based DTW alignment and
descriptive rank-agreement matrices. The Matplotlib Axes result type is
not reproduced: this is a deliberate backend/return-object divergence.

**Cumulative authored census: 150 native R implementations, 175/380
mapped Python public callables and 205 unmapped functions.** Stage 20's
three numerical-fixture candidate records are retained, with explicit
Python 1.2 boundary divergences now covered by source tests.
**Full public source-contract certification remains 0/508.** This
research head is unmerged, unreleased and has not completed
exact-head RStudio or cross-platform CI qualification.

[Stage 21 native visual integration and source-boundary evidence](full-native-r-stage21-visual-contracts.md).


## Stage 22 — eight scientific plotting integrations and stronger certification gate

Eight source-aligned native R plots now cover embedding, recurrence,
divergence, surrogate inference and one-dimensional Poincare transitions
using base graphics. Geometry is retained for numerical audit rather
than obscured by a Python/Matplotlib bridge.

The authored **cumulative** inventory is **158 native implementations,
183/380 mapped public Python functions, 197 unmapped callable functions
and 0/508 fully approved public source contracts**. Stage 21 owner-run
verification passed; Stage 22 source/tests are authored but not yet
runtime qualified. The newly machine-readable 12-gap source registry
prevents certification of known-divergent contracts even if review
flags are erroneously switched to TRUE.

[Stage 22 native plotting and hard-fail published-source certification](full-native-r-stage22-certification-and-plots.md).


## Stage 23 — eight manuscript reporting integrations (draft)

Eight independent Python-free R descriptive text entrypoints build
manuscript-ready summaries from already computed native scientific
objects. Direct source-oracle comparisons are authored for three
deterministic text outputs and native fail-closed checks for all eight.

**Authored census: 166 native implementations; 191/380 source names
mapped; 189 unmapped Python callable names.** No new independent
complete-contract certification has been obtained: **0/508**
public source contracts fully certified. Stage 22 owner-run Windows
RStudio tests passed; Stage 23 remains unexecuted on the new head.

[Stage 23 method and verification](full-native-r-stage23-manuscript-source-contracts.md).


## Stage 24 — nine Python-free scientific plots and 21 explicit source blockers

Nine new source-aligned native R plotting methods span matched FPC
stability, influence, outlier review, FPCA cross-validation,
eigenspace diagnostics, functional mean bands, joint recurrence,
windowed-RQA trajectories and fixed-dimensional RQA sensitivity.
A direct published-Python 1.2 Axes coordinates oracle is authored.

**Cumulative authored census**: **175 native implementations**,
**200/380 mapped source functions**, **180 unmapped source callables**,
**4 targeted numerical candidate fixtures**, and **0/508 independent
fully certified Python public source contracts**. The 21-row
known-source behavior difference register now hard-gates all graphical
output classes. Plot source geometry equivalence does not certify
backend or public return classes.

[Stage 24 scientific plots and certification limits](full-native-r-stage24-nine-scientific-plots.md).


## Stage 26 — scientific multiscale RQA and 27 recovery metric definitions

Native numerical multiscale windowed RQA sensitivity now compares
only exact shared window-center times, quantifies deterministic
source-sample reuse and preserves predeclared (window, step) settings.
The native whole-unit simultaneous band applies Gaussian multipliers
to complete derived RQA curves or participant functional units,
rather than treating overlapping windows as independent samples.

Four more new source-name integrations publish the entire pinned
**27-metric** functional-recovery catalog, its exact Python-source
metadata frame, canonical component/source keys and semantic
assessment frames. Direct pinned Python 1.2 catalog/text oracles
are authored, but execution is pending.

**181 native R functions**, **206/380 mapped callable source names**,
**174 unmapped source callables**, **27 hard-blocked source differences**
and **0/508 independently fully certified public source contracts**.

[Stage 26 scientific and certification review](full-native-r-stage26-functional-rqa-recovery.md).
