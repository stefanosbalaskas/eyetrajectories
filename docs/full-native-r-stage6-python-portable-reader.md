# Native R Stage 6 — verified Python 1.2 portable-result imports

**Python source of record:** published `eyetrajectoriespy==1.2.0`,
`src/eyetrajectoriespy/portable_results.py` for
`export_portable_result()`, `load_portable_result()`,
`_PortableEncoder`, `_decode` and SHA-256 checks.

This research stage implements **one genuinely Python-free R loader
candidate**: `etr_read_python_portable_result()`. It reads Python
`manifest.json` plus NumPy `arrays.npz` bundles and validates the
archive checksum before decoding any payload. The Stage 5 native RDS
snapshot remains a separate, unchanged R-native format; this stage
does not mislabel it as Python-compatible.

## Included scientific behavior

- Verifies exact version-one manifest `format`,
  `schema_version`, prescribed `arrays_file` and SHA-256
  `arrays_sha256` of the archive using **R's optional `digest`
  package**, not Python.
- Parses NumPy `.npy` headers from the archive without invoking
  `reticulate`; supports NPY versions 1–3, little-endian
  `float32/float64`, signed/unsigned 8/16/32/64-bit integer
  samples (64-bit values only within exactly representable
  base-R double bounds), bool and UTF-32LE Unicode.
- Correctly distinguishes NumPy C-order from Fortran-order array
  layout and reconstructs R array dimensions without relying
  on NumPy.
- Supports Python's JSON-only primitive `object_array` marker
  for homogeneous character/numeric/logical arrays, common
  in pandas metadata. **No pickle is ever loaded**.
- Decodes portable `dataclass` fields as inert named R lists with
  `__python_type__`, explicit `mapping`, `tuple`, `path`,
  safe pandas `dataframe` and `series` representations,
  and `nonportable` markers. It does **not** reconstruct
  Python fitted estimators.
- Applies conservative resource limits: default 64 MiB per
  array and 128 MiB total advertised uncompressed ZIP data,
  rejects duplicate/unsafe ZIP paths, unrecognized types,
  truncated array payloads, inconsistent shapes, malformed
  object arrays and unsupported encodings.
- Returns an `etr_python_portable_snapshot` with
  `result_type`, `source_package_version`,
  `payload`, `units`, `nonportable_fields`,
  `environment`, verified `arrays_sha256`,
  the original `manifest` and decoded `archive_keys`.

There is **no new required R package dependency**. The native
reader uses two new optional suggested dependencies,
`jsonlite` for JSON and `digest` for SHA-256.
Neither Python nor `reticulate` is needed to call the
native reader. `reticulate` appears only inside the optional
independent Python 1.2 tests.

## Exact limitations — not full portability certification

The Python API can decode a broader set of NumPy array descriptors,
object arrays and pandas data types. Stage 6 explicitly fails
closed when a type cannot be represented correctly and safely in
base R. It also has R-specific resource limits absent from the
published Python function.

A checksum of `arrays.npz` detects accidental or deliberate archive
byte modifications **relative to the manifest**; the manifest is
not signed, and this is not an authenticated chain of custody.
Do not accept `manifest.json` as trusted provenance solely because
the array checksum matches. The reader does not implement a
portable **writer**, a backend model reconstruction service,
arbitrary dtype round-trip guarantees, or full Python dataclass
serialization equality.

The Python-format loader is separately callable, so existing Stage 5
`etr_trajectory_snapshot()` and
`etr_restore_trajectory_snapshot()` remain backward compatible
with trusted RDS.

## Exact native-parity inventory after Stage 6

The frozen Python v1.2 API remains **508 public exports**:
380 callable functions and 128 other objects.

- **46** Python function names now have a mapped native R candidate
  (including this new limited Python `load_portable_result` reader);
  **334** Python function names are still unmapped.
- Stages 2/3/4 introduced **14** independently written numeric R
  implementations and Stage 6 adds **one** independent portable
  reader (so **15** counted newly implemented callable candidates
  across those stages).
- Stage 5 separately introduced four R infrastructure functions,
  which do not represent four previously unmapped callable
  Python functions.
- Exactly one of the **128 nonfunction Python exports**
  (`TrajectorySet`) is partly represented in native R; the other
  **127** remain unreviewed.
- **Zero of 508 contracts** are automatically certified as
  fully complete by the source-level ledger. Passed test assertions
  in Stages 2–5 were Windows-local evidence for tested cases,
  not a complete formal contract proof.

## Reproduce Stage 6 tests

RStudio **Terminal**:

```sh
git status --short
git fetch origin
git switch research/full-native-r-parity-stage6-20261027
git pull --ff-only
```

If the branch is absent locally,
`git switch --track origin/research/full-native-r-parity-stage6-20261027`.
Never discard uncommitted local work.

R **Console** after restarting the R session:

```r
pkgload::load_all(".",quiet=TRUE)
stopifnot(requireNamespace("jsonlite",quietly=TRUE))
stopifnot(requireNamespace("digest",quietly=TRUE))

# Native-only parsing, integrity, safety and ledger tests
testthat::test_local(".",filter="native-stage6-python-portable-reader")
testthat::test_local(".",filter="native-stage6-parity-ledger")
testthat::test_local(".",filter="full-native-r-parity-ledger")

# Opt-in independent published Python v1.2 generated archives
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",
    filter="native-stage6-python-portable-reader"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

The Python oracle generates **three actual Python 1.2 dataclass
exports** (one-curve and two-curve; including incomplete gaze,
object-string metadata, numeric metadata and provenance).
It checks the Python loader independently accepts those archives,
then tests native-R array shapes, missingness, metadata,
source fields and checksum tampering.

**Do not mark these tests PASS before owner execution.** On this
repository GitHub Actions has previously failed with zero executed
steps across runners; such failures do not constitute numerical
or format-validation findings.

**Stage 6 status:** source/tests authored in a draft research PR,
no publication, merge or 508/508 completion claim. The next
interoperability increment should study a matching native R
portable writer and broader dtype/metadata support only after
the reader's Python-created bundles qualify.
