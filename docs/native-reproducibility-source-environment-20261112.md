# Native R scientific reproducibility environment and frozen Python 1.2 schema crosswalk

Authoritative source: `eyetrajectoriespy==1.2.0`, frozen commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/portable_results.py::capture_environment`.

## Scientific task and the unavoidable language boundary

The frozen Python function returns a timestamped **Python process environment**:

1. `schema_version` = 1.
2. `captured_at_utc` = current aware UTC timestamp.
3. `package` = installed `eyetrajectoriespy` version and optional Git commit.
4. `python` = actual Python interpreter version, implementation and executable.
5. `platform` = operating system, kernel release, machine, platform string, processor and logical CPU count.
6. `dependencies` = installed versions or missing status for **numpy, pandas, scipy, scikit-learn, matplotlib, statsmodels**.
7. `optional_backends` = installed versions or missing status for **scikit-fda, FDApy, fdasrsf**.
8. `numerical_thread_environment` = OMP/OPENBLAS/MKL/NUMEXPR_NUM_THREADS string values or Python None.

A truly **Python-runtime-identical report cannot be generated from a Python-independent native R process** without either invoking Python or receiving genuine pre-captured Python provenance. Pretending R's interpreter, package and dependency versions are Python's would damage research reproducibility.

## Native R scoped scientific implementation

The existing `etr_capture_environment()` already captures actual **R** process information (native package name, installed version, R runtime, platform, R core dependencies and optional backend versions, CPU count, UTC timestamp and the same four numeric thread-variable values). Its default return and historical `r` runtime field remain unchanged.

New `etr_capture_environment(strict_source_record=TRUE)` returns an inspectable `etr_native_environment_scientific_record`:

- `native_environment` with the actually measured full native R schema and package, runtime and numerical thread facts. No Python imports or subprocesses are made.
- `native_R_executable_path`, if the actual R executable file can be resolved from `R.home("bin")`.
- `scientific_crosswalk`, containing the exact ordered frozen Python 1.2 eight source keys and eight corresponding native R keys. The source's `python` field maps explicitly to the native `r` interpreter field; source dependencies and backend package names are **not falsely reported as installed in Python**. The four numerical thread environment keys have the exact same spellings and logical meanings.
- `original_python_environment=NULL` when no independent Python evidence was provided; `full_Python_runtime_source_parity=FALSE` and `independently_source_certified=FALSE`.

New `etr_capture_environment(strict_source_record=TRUE, python_source_snapshot=...) ` additionally accepts **a genuine already-captured Python source record** and strictly validates it against the frozen source: all eight top-level fields in their original order, complete package and Python interpreter keys, UTC ISO date, OS/platform values, exact 6+3 dependency keys and 4 thread keys, and correct string/NULL optional versions.

It preserves the original Python snapshot losslessly (native R list semantics, not a new measurement), while *separately* measuring R. It never claims that the R package independently captured the Python process. This gives a scientifically useful, portable **paired reproducibility audit** that can be attached to a cross-language EyeTrajectories analysis.

## Regression and source witnesses

- Native R tests ensure exact default API backward compatibility, real measured R facts (not placeholder Python values), expected field order, thread names, availability of an actual R executable only when present, missing optional dependency semantics, and no implicit Python interpreter initialization.
- Constructed **test-only** source-shaped Python fixture validates the schema validator and preserves all values, while rejecting wrong interpreter name, invalid timezones, missing dependency names, booleans as versions, incorrect schema version and extraneous API parameters.
- **Opt-in real Python 1.2** test calls the frozen public `eyetrajectoriespy.capture_environment()` directly and validates/retains the exact resulting real Python dictionary alongside the native R measurements. This demonstrates that we have not copied an invented Python process fingerprint.

## Coverage declaration and qualification limits

This is an **author-reviewed native R scientific reproducibility environment capture and optional verified Python source-attestation contract**, not a full Python-runtime implementation.

The source Python process fingerprint, Python distribution set, Python-specific `platform.platform()` rendering, `subprocess git rev-parse` fallback and exact Python runtime exception behaviors **remain outside this bounded R-native scientific contract**. Source snapshot must be acquired externally. No independently certified full Python contract, true direct runtime parity, passing exact-head CI, or CRAN certification is asserted.

A provisional export-level source-scientific ledger entry for `capture_environment` means the native **research purpose** is now recorded with these explicit bounds; it must not be interpreted as the native R method magically reporting Python interpreter facts. In downstream scientific documents, explicitly label native R versus attached Python environmental provenance.
