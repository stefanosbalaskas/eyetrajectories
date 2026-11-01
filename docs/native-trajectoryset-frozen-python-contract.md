# Frozen Python 1.2 TrajectorySet → native R partial class contract

**Status:** Native candidate documented; known source-domain differences unresolved;
independent full-domain approval **FALSE**. This is not a claim of
independent certification or a complete Python-to-R type port.

## Frozen source and native implementation

- Python tag 1.2.0 source pin: `c1cd95ad718327550f7e55393ff38582872f7a94`.
- Source: `src/eyetrajectoriespy/types.py`, frozen `TrajectorySet` dataclass,
  `__post_init__`, `dimension`, `subset`, `with_values`.
- Native constructor: `R/native-trajectories.R` / `etr_trajectory_set`.
- Existing native methods: `etr_subset`, `etr_dimension` and
  `R/native-trajectory-provenance.R` / `etr_with_values`.
- Native representation register:
  `inst/extdata/native_nonfunction_contract_review_v1.csv`,
  `root::TrajectorySet → etr_trajectory_set` (candidate mapping only).
- Explicit unresolved gap:
  `inst/extdata/native_nonfunction_source_gaps_v1.csv`.

## Shared implemented source-domain features (developer reviewed)

The native S3 trajectory object holds the same principal source field
categories: time, 3D values, curve identifiers, dimension identifiers,
metadata, coordinate system, time unit and provenance. Its `etr_with_values`
analogue preserves IDs and metadata while allowing a new time grid,
coordinate/time unit changes and shallow provenance-key replacement.
`test-native-source-trajectory-object.R` now verifies ordinary R copy
semantics, errors and a directly executed Python class method in the
opt-in pinned 1.2 source environment.

## Known blockers: source domain is NOT the same

| Dimension | Frozen Python 1.2 | Native R candidate |
|---|---|---|
| Missing gaze | `np.nan` values are preserved | Native constructor permits R `NA` but rejects `NaN` |
| Input coercion | `np.asarray(..., dtype=float)` accepts broader array-like values | Native requires an R numeric 3D array |
| Zero curves | Dataclass `__post_init__` does not explicitly forbid a zero-curve first axis | Native R constructor requires one or more curves |
| Immutability | `@dataclass(frozen=True)` prevents reassignment of fields | S3 list fields can be changed |
| Curve indexing | Python `subset` takes zero-based integer indices, including standard negative indices | R `etr_subset` uses 1-based IDs/indices and rejects repeated indices |
| Metadata | pandas DataFrame, index relabeled to curve IDs | base R data.frame with separate R rowname handling |
| Exceptions | Python exceptions for source validation | Native R errors/messages and rejection boundaries differ |

These differences block **FULL_SOURCE_PARITY**, even where finite
Python/R values match in targeted examples. They must be deliberately
resolved or independently signed as restricted-scope differences.
No method-name mapping, observed body field, synthetic test PASS, or
detached signature alone can close these gaps.

## Strict independent review policy

The exact Python source, native R commit, accepted and rejected input
domains, structural schema, scientific semantics and error behavior
must be audited by a qualified reviewer who was not responsible for
these implementations or tests. Independent reproducible fixtures and
scientific findings need separate signature and maintainer adjudication.
Until then, `etr_native_parity_catalog(require_complete=TRUE)` must
fail closed and the aggregate independent full-domain count remains 0/508.

The 508-export source queue now distinguishes **203 callable-function
source gaps** and **1 recorded nonfunction class gap**.
The 203 original callable gap rows remain in their original source
register; the class has its own separate one-row unsigned scientific
resolution queue. The provisional class mapping improves representation
inventory coverage to **1/128**, but not certified class coverage.
