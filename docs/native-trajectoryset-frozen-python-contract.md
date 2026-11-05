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
| Missing gaze | `np.nan` values are preserved | Strict native constructor permits R `NA` but rejects `NaN`; opt-in boundary mode accepts NaN/Inf |
| Input coercion | `np.asarray(..., dtype=float)` accepts broader array-like values | Strict native requires a numeric 3D array; opt-in boundary mode accepts regular numeric-like atomic 3D arrays |
| Zero curves | Dataclass `__post_init__` does not explicitly forbid a zero-curve first axis | Strict native requires curves; opt-in boundary mode accepts zero curves |
| Immutability | `@dataclass(frozen=True)` prevents reassignment of fields | S3 list fields can be changed |
| Curve indexing | Python `subset` takes zero-based integer indices, including standard negative indices | Default `etr_subset` is 1-based; opt-in boundary mode uses Python-style zero-based/negative indices, with duplicate ID rejection |
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

## November 5 opt-in constructor/subset domain extension — awaiting runtime qualification

At the development branch, `etr_trajectory_set(...,
python_boundary_mode=TRUE)` accepts the **bounded atomic-array** portion of
the frozen `TrajectorySet` source constructor: 1-D numeric-like finite time,
regular 3-D numeric/Boolean/numeric-string values, `NaN` missing samples,
infinite value observations, zero curves and zero dimensions. R `NA` values
are explicitly converted to NumPy-style `NaN` in this mode. This is an
**opt-in source-boundary representation**, not the default scientific contract.

`etr_validate` and `etr_with_values` preserve that explicit mode;
`etr_subset(x, indices, python_boundary_mode=TRUE)` uses Python-style
zero-based/negative curve indices and permits empty selections. Duplicate
indices still fail at the constructor's unique-ID validation (as in
`dataclasses.replace` on the frozen class).

The existing direct Python 1.2 source test now covers NaN/Inf values,
negative indices and zero-curve subsets; native tests also protect the
strict default contract. The new code **has not yet run** in the owner's
RStudio environment. Independent full-domain certification remains 0/508.

**Still outside the complete source contract:** all NumPy array-like inputs,
pandas index/value equivalence, Python dataclass immutability, exact Python
exception types, nested metadata conversion and all methods' full boundary
domains. The single known nonfunction `TrajectorySet` gap stays OPEN.
