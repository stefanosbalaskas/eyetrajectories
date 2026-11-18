# Native R provenance-preserving trajectories and versioned snapshots

Python-independent handling of `TrajectorySet`-like scientific
provenance, nonmutating transformations and native R snapshot restore.
The source of the `with_values` semantics is the published Python
eyetrajectoriespy 1.2.0 `types.py` definition. Native R snapshots are
not Python portable-scientific-result JSON and NPZ bundles.

## Usage

``` r
etr_trajectory_provenance(x)

etr_with_values(x, values = x$values, time = NULL,
                provenance_update = NULL, time_unit = NULL,
                coordinate_system = NULL)

etr_trajectory_snapshot(x)

etr_restore_trajectory_snapshot(snapshot)
```

## Arguments

- x:

  A native R `etr_trajectory_set`, including objects created before the
  provenance field was added.

- values:

  A numeric three-dimensional trajectory array with compatible
  curve/time/channel shape. Explicit R `NA_real_` means missing gaze.

- time:

  Optional strictly increasing finite time vector. NULL retains the
  original grid.

- provenance_update:

  Optional JSON-like named R list with unique, nonempty keys. Updated
  top-level keys replace existing entries; unlike
  [`utils::modifyList`](https://rdrr.io/r/utils/modifyList.html), nested
  dictionaries are not recursively merged.

- time_unit,coordinate_system:

  Optional single nonempty character scalars; NULL retains the
  corresponding existing unit.

- snapshot:

  A version-one `etr_trajectory_snapshot` list. Only use untrusted
  serialized files after separate input-security review.

## Value

`etr_trajectory_provenance()` returns an independent JSON-like named
list, with an empty list for legacy native trajectory objects.

`etr_with_values()` returns a new native R trajectory collection without
modifying `x`; existing curve IDs, channel names and one-row-per-curve
metadata are retained.

`etr_trajectory_snapshot()` returns an `etr_trajectory_snapshot` S3 list
with the exact R numeric array, time vector, IDs, metadata and factors,
coordinate/time units, provenance, format label, schema version and
array shape. Snapshots record an explicit Python boundary mode when the
original trajectory uses it.

`etr_restore_trajectory_snapshot()` validates the snapshot and
reconstructs a native `etr_trajectory_set`.

## Details

The
[`etr_trajectory_set()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)
constructor now accepts optional `provenance=list()` as the last formal
argument, preserving every older positional argument.
[`etr_validate()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)
checks provenance,
[`etr_subset()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)
retains it and
[`etr_from_long()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)
appends source audit defaults. Stage 3 normalization/centering
operations preserve earlier provenance and append documented Python
preprocessing keys.

Python's `TrajectorySet` is a frozen dataclass, whose `with_values()`
method uses a shallow top-level dictionary update. This R-native
implementation follows those audit semantics without reticulate. For
some unrelated older native R transforms, provenance retention is not
yet fully implemented or verified.

A native snapshot can be saved with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) and read back with
[`readRDS()`](https://rdrr.io/r/base/readRDS.html); it is meant for
trusted native R environments. It is NOT the cross-language, audited
`eyetrajectoriespy` `export_portable_result()` scientific-result schema,
which stores JSON and NPZ and has different manifest/array hash
requirements. Do not imply compatible Python loading, cryptographic
verification, execution sandboxing, or full public API parity.

## Examples

``` r
time <- c(0,.2,1,2)
values <- array(1:16,c(2,4,2))
x <- etr_trajectory_set(time,values,curve_ids=c("A","B"),
                        dimension_names=c("x","y"),
                        provenance=list(source="recording"))
y <- etr_with_values(x,values=values+1,
                     provenance_update=list(preprocessing="offset"))
stopifnot(identical(y$provenance$source,"recording"))
snapshot <- etr_trajectory_snapshot(y)
restored <- etr_restore_trajectory_snapshot(snapshot)
stopifnot(identical(restored,y))
```
