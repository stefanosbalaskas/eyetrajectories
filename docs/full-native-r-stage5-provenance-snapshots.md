# Native R Stage 5 — trajectory provenance, metadata and trustworthy R snapshots

**Reference implementation inspected:** `eyetrajectoriespy` 1.2.0,
`src/eyetrajectoriespy/types.py` (`TrajectorySet`,
`TrajectorySet.subset()`, `TrajectorySet.with_values()`),
`preprocessing.py` (coordinate and time normalization, landmark centering),
and `portable_results.py` (separate JSON+NPZ scientific-result format).

Stage 5 is independently authored in **R only** on
`research/full-native-r-parity-stage5-20261027`, based on the
Stage 4 draft branch. Stage 4's owner-run Windows numerical tests passed
**733/733** assertions; Stage 5 source and tests have not yet been run
in RStudio or accepted by CI.

## Why this stage is necessary

The Python `TrajectorySet` dataclass includes a JSON-like `provenance`
mapping, allows a **nonmutating** `with_values()` copy with a **shallow
top-level** provenance update, and retains provenance during `subset()`.
Earlier R `etr_trajectory_set` objects had only seven data fields
(time, values, curve IDs, dimension names, metadata, coordinate system,
time unit) and dropped provenance in several basic transformations.
Consequently numeric agreement on gaze arrays did **not** establish
provenance/metadata parity.

## Native changes committed

- Backwards-compatible `etr_trajectory_set(..., provenance=list())`,
  introducing an eighth optional field **after all seven prior formals**.
  Provenance is a JSON-like named R list; malformed keys and unserializable
  programmatic values such as closures are rejected.
- `etr_trajectory_provenance(x)` returns the mapping, treating old R
  trajectory objects without this field as empty-provenance objects.
- `etr_with_values(x,values,time,provenance_update,time_unit,coordinate_system)`
  creates a new R trajectory, preserves IDs/metadata, and applies
  **shallow**, not recursive, provenance key replacement, matching the
  semantics of Python `TrajectorySet.with_values()`. NULL values in
  nested lists represent Python None.
- `etr_subset()` retains existing provenance while honoring its
  existing **one-based** R index semantics (Python uses zero-based).
- `etr_from_long()` includes the upstream-like audit keys:
  `source="long_dataframe"`, `curve_columns`, `time_column`,
  `value_columns`. A final optional `provenance=NULL` argument permits
  deliberate shallow override of those source-audit keys.
- Stage 3 `etr_normalize_coordinates()`,
  `etr_center_on_landmark()`, and
  `etr_normalize_time_interval()` now preserve previous source provenance
  and append their explicit Python 1.2 `coordinate_normalization`,
  `landmark_centering`, and `time_normalization` audit fields.
- The Stage 2/3 planar geometry result constructor now **retains** the
  source provenance mapping; its complete Python derived-function
  provenance extensions remain unqualified and are not fabricated.
- `etr_trajectory_snapshot()` creates a *version-one native R*
  snapshot including time, exact 3D numeric values (with missing gaze),
  curve IDs, names, factor-preserving metadata, units, provenance,
  explicit shape, format and schema labels.
- `etr_restore_trajectory_snapshot()` checks format, version,
  package identity, shape and all current trajectory-constructor
  invariants before returning a native trajectory.

The R snapshot can be passed through trusted base R
`saveRDS()`/`readRDS()` without requiring Python. There is **no
claim** that Python's `export_portable_result()` or
`load_portable_result()` understands these RDS records; Python's
portable format is an independent JSON+NPZ archive with array-level
hashes/manifest that has **not** been ported. These Stage 5 helpers
are native-R object infrastructure, **not additional proven Python
public function exports**.

## Tests and reproducibility

The committed tests contain:

- R-only validation of source provenance, reserved/duplicate keys,
  named nested mappings, default and legacy trajectories;
- shallow update and no-mutation tests for `etr_with_values()`;
- explicit unchanged IDs, channel names, clock/coordinate units and
  one-row-per-curve metadata;
- native Stage 3 source audit retention across chained transforms;
- versioned snapshot-RDS restoration including `NA` gaze,
  metadata factors, format/version/array shape tampering;
- native from-long default source audit and explicit overrides;
- **opt-in** independent Python 1.2 object comparisons on
  `TrajectorySet.with_values()`, `subset()` and three preprocessing
  transformations, checking array values, time, IDs and provenance.

From the RStudio **Terminal**:

```sh
git status --short
git fetch origin
git switch research/full-native-r-parity-stage5-20261027
git pull --ff-only
```

If the local branch is absent, use
`git switch --track origin/research/full-native-r-parity-stage5-20261027`.
Do not discard uncommitted scientific work. Restart RStudio, then in
the **R Console**:

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage5-trajectory-provenance")
testthat::test_local(".",filter="native-stage4-distance-contracts")
testthat::test_local(".",filter="native-stage3-preprocessing-distances")
testthat::test_local(".",filter="native-planar-geometry-parity")

# Optional Python object/provenance reference oracle only:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".",filter="native-stage5-trajectory-provenance")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

Stage 5's CI workflow runs native tests across Linux/macOS/Windows
and an opt-in pinned Python 1.2 comparison on Linux. Earlier GitHub
Actions attempts on this repository have failed *before any recorded
job steps*. The existence of the workflow is not a passing CI result.

## Limits and next research

Full native `TrajectorySet`-class parity is **not yet established**.
This stage does not cover all methods, output serializers,
pandas metadata conventions, float-NaN-vs-R-NA serialization,
round-trip cross-language files, or every older native R function
that reconstructs trajectory objects without passing provenance.
In particular, Python scientific snapshots use a **separate
portable-results schema**, and Stage 5 deliberately does not claim to
replicate that schema or cryptographic checks.

The frozen ledger continues to list **45 mapped R function candidates
among 380 callable Python public exports**, **335 unmapped callable
exports**, and **128 other public Python objects** awaiting native
representation audits. This stage materially improves native
`TrajectorySet` behavior but does not silently count the class as
independently completely qualified; the strict 508-source completion
gate remains **closed**.

**Research draft only. No main-branch merge, CRAN release, Python
package release, or claims about W3 interval calibration or MNAR
identifiability.**


## First owner-executed Stage 5 test: defect and fixture correction (27 Oct 2026)

The owner ran `testthat::test_local(".",filter="native-stage5-trajectory-provenance")`
in Windows RStudio on the original Stage 5 branch head. The result was
**PASS 54, FAIL 2, WARN 0, SKIP 1**. The skipped Python object/reference
oracle is deliberately opt-in.

The two failures were:

1. **Actual native validation defect:** The JSON-like `.etr_provenance_valid()`
   recursive predicate allowed a top-level character scalar
   (`provenance="bad"`), although Python `TrajectorySet.provenance`
   is a dictionary. This is now fixed by requiring the *root* to be
   a plain R list, while retaining JSON-like scalar and NULL values in
   nested entries. Added negative tests for string/numeric/logical roots,
   unnamed lists and data frames, plus a positive nested-NULL case.
2. **Incorrect test expectation:** The malformed R replacement
   `array(1,c(1,4,2))` changes curve count 2 to 1 while preserving
   the time dimension. Both the Python-like and R constructor perform
   curve-ID count validation and raise `curve_ids`, **not**
   `values dimensions`. The fixture now expects the correct error
   and separately checks `array(1,c(2,3,2))`, whose time dimension
   disagrees with the four-element common grid and correctly produces
   a `values dimensions` error. No trajectory calculation or numerical
   tolerance was modified.

**Source-only verification:** the amended R validator and tests are
committed. The corrected full R test suite has **not yet been executed**,
and neither the opt-in Python 1.2 object oracle nor cross-platform CI
has passed. Stage 4's earlier 733/733 Windows numerical verification
remains unchanged. Pull the updated Stage 5 branch head and rerun
both native and optional Python tests as described above; do not
report Stage 5 as passing on the strength of this fixture correction.
