# Frozen Python 1.2 source-scientific conversion records: grid and irregular

**Source:** `eyetrajectoriespy==1.2.0`, frozen commit `c1cd95ad718327550f7e55393ff38582872f7a94`. Public implementations: `src/eyetrajectoriespy/backends.py::to_skfda_grid` and `src/eyetrajectoriespy/sparse.py::to_fdapy_irregular`.

## Two opt-in scientific paths

### `etr_to_skfda_grid(trajectories, strict_source_record=TRUE)`

The strict record preserves every original observed value without interpolation in an explicit `data_matrix` (curve × time × codomain) array. It carries the exact source constructor's `grid_points` one-dimensional numeric vector, `dataset_name="eyetrajectoriespy trajectories"`, and `coordinate_names` in original dimension order, alongside the normalized one-element `grid_points` tuple representation and the domain endpoints. The source record retains the original curve identifiers and time units as *native R provenance*, which Python's `FDataGrid` constructor call does not carry as separate arguments. Grid point ordering, dimensional cardinalities, sample counts and source zero-based row indexing are explicit. Missing numeric values are not replaced or fitted.

This is **an R scientific source-constructor record, not a `skfda.FDataGrid` class instance**. Functions, interpolation semantics, object-level evaluation, backend covariances and Python exception types on `FDataGrid` are not claimed.

### `etr_to_fdapy_irregular(trajectories, dimension, strict_source_record=TRUE)`

The strict record maps each original trajectory to `IrregularArgvals({i: DenseArgvals({"input_dim_0": time.copy()})})` and `IrregularValues({i: curve[:, index].copy()})`, where `i` is the frozen Python zero-based integer curve index and `index` is the selected original dimension. Native R names are strings `"0"`, `"1"`, etc.; the original integer-key semantics are separately retained in `python_integer_keys`. The selected values must be finite; missing unselected dimensions do not invalidate the selected dimension. Curves with only two observations are allowed in strict source mode in agreement with frozen Python's `IrregularTrajectorySet` validation. Observations are neither pooled nor interpolated.

The legacy default continues to emit `etr_sparse_curves` for explicit native `fdapace` calculations and retains its at-least-three-visits and at-least-three-curves scientific restrictions. The strict mode returns a separate **R source-constructor record, not an FDApy `IrregularFunctionalData` Python instance**. FDApy `UFPCA` is not called and its estimator/scoring parity remains an open gap.

## Validation strategy and limits

A native R regression suite tests direct array and list equality, missingness, two-observation irregular curves, zero-based key order, curve/channel selection, explicit source metadata, default-API stability and rejection of nonfinite selected observations.

An opt-in frozen Python 1.2 test invokes both actual Python public conversion functions with small signature-capturing replacement backend constructors (only the *optional import boundary* is replaced). The test verifies source constructor argument order, numeric shapes, zero-based keys and original measurements without requiring the large optional Python backends. **These replacement constructors are not real scikit-fda or FDApy scientific validation** and their passing is not full numerical or object parity. Future independent certification must verify actual backend instance behavior, methods, domain restrictions and warning/exception classes using pinned real optional dependencies.

Both records are provisional **scoped** native R scientific input-geometry conversions. No independent full-contract certification, completed exact-head CI, Python backend identity, full Python source parity, or CRAN release is claimed.
