# Stage 8 — native R nonlinear recurrence and RQA: ten-function batch

Research branch: `research/full-native-r-parity-stage8-batch-20261028`.
Parent: Stage 7 draft PR #15, Windows native numerical tests
**115/115 PASS**. Stage 8 implements a further ten independent
Python-free native R methods sourced from the pinned published
`eyetrajectoriespy==1.2.0` `recurrence.py`,
`recurrence_networks.py`, `joint_recurrence.py` and
`nonlinear_types.py`.

## Methods authored

| Python v1.2 callable | Native R implementation |
|---|---|
| `recurrence_network` | `etr_recurrence_network` |
| `recurrence_network_node_frame` | `etr_recurrence_network_node_frame` |
| `recurrence_network_summary_frame` | `etr_recurrence_network_summary_frame` |
| `joint_recurrence_matrix` | `etr_joint_recurrence_matrix` |
| `joint_recurrence_component_frame` | `etr_joint_recurrence_component_frame` |
| `joint_rqa_metrics` | `etr_joint_rqa_metrics` |
| `cross_rqa_metrics` | `etr_cross_rqa_metrics` |
| `recurrence_radius_profile` | `etr_recurrence_radius_profile` |
| `windowed_rqa` | `etr_windowed_rqa` |
| `windowed_rqa_trajectory_set` | `etr_windowed_rqa_trajectory_set` |

The existing `recurrence_network` name was already present as an
*unimplemented* R candidate in the source ledger. It now has a real
native algorithm. Accordingly, **ten new native R implementations
increase named Python function candidates by nine**, not ten.

Stage 8 adds optional time-unit, source metric, state-dimension and
recurrence-denominator provenance fields to the existing native
`etr_recurrence_matrix()` output, without changing its numerical
recurrence matrix or threshold.

## Source contract and deliberate limits

Recurrence networks are undirected, unweighted simple graphs on
original sample/state indices. Local clustering for degree below two
is zero; global transitivity is undefined (NaN) when the graph has
no connected triples. Connected-component labels use zero-based
indices as in Python. Source time, threshold and Theiler exclusions
are never automatically altered.

Joint recurrence is a strict synchronized logical AND of two or more
*auto* recurrence matrices. All state time grids, temporal units,
Theiler windows and matrix shapes must agree **exactly**. No hidden
lag shifting, registration, metric harmonization or threshold
re-optimization occurs. A joint component frame preserves the
separate thresholds and achieved recurrence rates.

The radius-profile R result is an empirical cumulative distribution
of eligible state-space distances evaluated at explicitly declared
positive increasing radii. It excludes near-time state pairs
from both numerator and denominator, preserves radius order and
reports shell counts as increments. It does **not** select a
statistically optimal radius.

Windowed RQA uses declared fixed-radius **Euclidean** windows in
sample indices, records the number of unprocessed tail samples,
and explicitly reports functional window overlap. These windows
are **not independent observational units** in downstream inference.
The current native R functional-result class is a partial
representation, not a complete Python dataclass/serialization port.

**Unimplemented Python contract branches (explicit):**
time-unit-based window and Theiler specifications, automatically
estimated target recurrence rates, DelayEmbeddingResult sources,
alternate distance metrics in windowed RQA, sparse large-graph
calculations, broad undefined-value/NaN round trips and all provenance
schema details. `etr_recurrence_network()` has a native dense
**750-node maximum** and
`etr_recurrence_radius_profile()` a **2,500-node maximum**;
Python uses SciPy sparse/KDTree methods without identical fixed caps.
These restrictions prevent an unconditional one-to-one parity claim.

## Frozen 508-export inventory

| Measure | Stage 7 | Stage 8 |
|---|---:|---:|
| Public Python functions with R named candidates | 56 | **65** |
| Unmapped Python public callable functions | 324 | **315** |
| Independently authored native R callable implementations (Stages 2–4, 6–8) | 25 | **35** |
| Partially represented nonfunction Python result/object classes | 2 | **7** |
| Other nonfunction public exports awaiting review | 126 | **121** |
| Fully qualified 508/508 source contracts | 0 | **0** |

Stage 8 adds partial native records for
`RecurrenceNetworkResult`, `JointRecurrenceResult`,
`RecurrenceRadiusProfileResult`, `WindowedRQAResult`, and
`WindowedRQAFunctionalResult`. “Partial” is not a completed
Python scientific result contract.

## Reproduction

In the RStudio **Terminal**, preserving uncommitted changes:

```sh
git status --short
git fetch origin
git switch research/full-native-r-parity-stage8-batch-20261028
git pull --ff-only
```

If the branch is not present locally, use
`git switch --track origin/research/full-native-r-parity-stage8-batch-20261028`.

Restart R, then run:

```r
pkgload::load_all(".",quiet=TRUE)
stopifnot(file.exists(
  "tests/testthat/test-native-stage8-nonlinear-recurrence.R"))
testthat::test_local(".",filter="native-stage8-nonlinear-recurrence")
testthat::test_local(".",filter="native-stage8-parity-ledger")
testthat::test_local(".",filter="full-native-r-parity-ledger")

# Independent numerical comparison, Python used only by the tests:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(".",
  filter="native-stage8-nonlinear-recurrence"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

Analytic tests cover graph components/triangles,
joint matrix intersection, declared radius CDF,
synchronized-source mismatch rejection, window-center grids and
non-independent window overlap. The independent Python oracle
compares two recurrence-state curves for network topology, node
tables and global summaries, radius counts, joint-component
statistics and selected windowed-RQA metrics, with pinned Python 1.2.

**Current qualification — owner-run Windows RStudio, 28 October 2026:**

| Stage 8 check | PASS | FAIL | WARN | SKIP |
|---|---:|---:|---:|---:|
| `native-stage8-nonlinear-recurrence`, R-only | **62** | 0 | 0 | 1 expected opt-in Python skip |
| `native-stage8-parity-ledger` | **82** | 0 | 0 | 0 |
| `native-stage8-nonlinear-recurrence`, Python oracle enabled | **189** | 0 | 0 | 0 |

The owner checked `identical(et_python_version(), "1.2.0")`
before enabling `ET_RUN_PYTHON_TESTS=true`; the direct Python 1.2
reference comparison then completed without skips. The Python-enabled
189 assertions **include** the native expectations; these rows must
not be summed as independent scientific oracle tests. The previous
57 PASS / 1 ERROR / 1 SKIP run was a malformed negative *test fixture*;
its monotonicity/synchronization expectations were corrected without
changing recurrence algorithms, numerical tolerances or thresholds.

The [final-head Stage 8 Actions run #40598507486](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40598507486)
failed at job admission for all four jobs (Windows, Ubuntu, macOS and
Linux pinned-Python oracle): **zero recorded steps each**. Therefore
cross-platform CI execution is **not** qualified. The owner-provided
Windows console transcript is numerical evidence for the executed
fixtures, not a GitHub runner or complete Python-contract certificate.

**Research draft only:** no main merge, CRAN/PyPI release,
or inference/coverage/identifiability claim.

## First local Stage 8 run: malformed time-grid fixture (28 October 2026)

The owner ran `testthat::test_local(".",filter="native-stage8-nonlinear-recurrence")`.
The test output was **57 PASS, 1 ERROR, 0 WARN, 1 expected SKIP**
for the opt-in Python reference.

The error occurred in the negative joint-recurrence time-alignment
assertion. The original test changed only the initial timestamp
(`bad$time[1] <- 99`), unintentionally making the component's own time
vector non-increasing. The native `.etr8_rec()` validity check
correctly rejected that malformed component with
`"recurrence time must match state count and be strictly increasing"`,
before the cross-component alignment validator ran. It was thus
incorrect for that specific malformed input to expect
`"same time grid"`.

The corrected tests now explicitly distinguish:

1. **Malformed individual recurrence grid:** assert the intrinsic
   `"strictly increasing"` failure for `bad$time[1] <- 99`.
2. **Valid but unsynchronized recurrence grids:** shift the entire
   vector `bad$time <- r2$time + 0.5`, preserving strict monotonicity,
   and require the intended `"same time grid"` rejection.

No recurrence estimators, time-alignment requirements, numerical
thresholds or RQA calculations were changed. **Only the test
fixture and assertions were modified.**

This fix is committed to research Stage 8 draft PR #16. Subsequently,
the corrected Windows native suite passed 62 assertions, the ledger
passed 82 and the Python 1.2-enabled suite passed 189 with no skips.
Cross-platform execution and full-contract equivalence remain pending.
