# Source-scientific native TrajectorySet class record

Frozen source: `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/types.py::TrajectorySet` (frozen Python dataclass).

Reviewed native R paths: `R/native-trajectories.R::etr_trajectory_set` with `python_boundary_mode=TRUE`, `etr_validate`, `etr_dimension`, `etr_subset` with `python_boundary_mode=TRUE`; `R/native-trajectory-provenance.R::etr_with_values`; and `R/native-trajectory-source-class-record-20261112.R::etr_trajectory_source_class_record`.

## Native R scientific class surface

The native package already implements the core frozen source scientific array/data structure in a strictly opt-in bounded Python-constructor mode, without opening a Python interpreter:

- Common sorted finite observation times, exact numeric array with shape `(n_curves,n_time,n_dimensions)`, including `NaN` missing measurements (never treated as zeros)
- Declared curve IDs and channel ordering, indexed one-row-per-curve metadata and named provenance; exact scientific units
- Constructor validation for time monotonicity, array shape, identifier uniqueness and metadata row counts (bounded native NumPy-like numeric coercions)
- `n_curves`, `n_time` and `n_dimensions` dimensions from original R array shape
- `dimension(name)` through `etr_dimension`, preserving the numeric curve-by-time matrix and original missing-value positions
- `subset(indices)` through `etr_subset(...,python_boundary_mode=TRUE)`, preserving **zero-based signed/negative positions**, source curve order and corresponding metadata; R's native default remains one-based
- `with_values` through `etr_with_values`, replacing numeric values or time while preserving original metadata and units, **shallow** provenance updates, and immutability of the original R object under normal R copy-on-modify semantics.

New exported `etr_trajectory_source_class_record(x)` provides an inspectable typed **native R** scientific record with all **eight** ordered frozen source dataclass fields, labeled metadata-index values, source array shape, all three source class dimension properties and native scientific method mapping. It enforces that the original R trajectory was explicitly constructed with `python_boundary_mode=TRUE`. No Python backend or reticulate is needed for this operation.

## Source comparison

Native regression tests cover all 8 source fields and their exact order, numeric array shape and actual values (including `NaN`), source-indexed metadata row labels, dimension slices, zero-based reordered subsets, empty subsets and preserved shallow provenance updates. An opt-in real frozen Python 1.2 `et.TrajectorySet` witness uses the **actual public dataclass** with real NumPy arrays and pandas metadata, and calls its actual `dimension`, `subset` and `with_values` methods; values and scientific fields are compared directly to native R.

## Explicit qualification limits

The scientific review is *source-scoped to bounded native R arrays, labels, metadata, unit/provenance data and documented public scientific method operations.* Native `etr_trajectory_source_class_record` is **not a Python dataclass**, a Python `pandas.DataFrame`, or a fully immutable CPython object. General NumPy type/shape coercion, pandas arbitrary index/duplicate index labels, Python dataclass equality and reflection, exact warning/exception classes and heterogeneous raw IDs that become duplicates only after `str()` conversion remain outside the approved R scientific data domain.

The native R record is explicitly marked `frozen_python_class_identity=FALSE` and `independently_source_certified=FALSE`; no independent full Python contract is claimed. The original R-native constructor mode remains unchanged. The entire set of frozen `TrajectorySet` Python object semantics, not just its scientific data/method surface, still requires independent qualification.

As with earlier reviews, a ledger closure means **provisional source-scientific R data and method coverage only**, not Python class identity or a certified general-language replacement.
