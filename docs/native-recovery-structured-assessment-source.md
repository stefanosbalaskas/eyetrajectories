# Structured recovery assessments through source-aligned native scenarios

**Immutable Python reference:** `eyetrajectoriespy==1.2.0`,
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/simulate.py::run_functional_recovery_scenarios`
and `src/eyetrajectoriespy/recovery.py::FunctionalRecoveryAssessment`,
`FunctionalRecoveryValue`, `FunctionalRecoveryMetric`,
`functional_recovery_value_key`.

## Material implementation change

Before this integration, the native R scenario recovery runner
`etr_run_functional_recovery_scenarios` accepted only a named
finite numeric vector returned from its `recovery` callback.
Its existing native scientific evaluators
`etr_evaluate_hierarchy_truth_recovery` and
`etr_evaluate_registration_recovery`, among others, return
structured `etr_functional_recovery_assessment` records,
including metrics with semantically meaningful component/source
labels and definitions. Such values could not be passed directly
through the source scenario runner.

The source Python 1.2 runner accepts both plain numeric metric
mappings and `FunctionalRecoveryAssessment` objects. The
native R runner now supports the parallel mechanism:

- The estimator still receives **observations and declared
  scenario only**, never true latent scores, generating warps
  or the source simulator truth object.
- Only after fitting does the recovery callback receive
  `(fit,truth,scenario)`.
- A callback may return its original named numeric vector,
  or a structured native assessment containing nonempty
  `values` and optional JSON-like `provenance`.
- Each structured value retains its six-field metric
  definition `name/quantity/direction/units/scope/description`,
  finite numerical value, optional **zero-based** component
  index and optional nonempty source identifier.
- Flattened scalar metric keys follow frozen Python
  `name[.source_SOURCE][.component_(INDEX+1)]`; source
  semantic triples and flattened names must be unique.
- The resulting `etr_functional_recovery_result` retains
  `metric_values` and `assessment_provenance` per successful
  replicate. Its ordered `metric_definitions` are derived
  from the first appearance of each scientific metric.
- An incompatible definition of the same metric name in a
  later replicate is a **hard scientific error**, not a
  failure to be silently recorded under `failure_action="record"`.
  This follows Python's outside-try definition consistency
  policy.
- With `failure_action="record"`, simulation/estimation/
  recovery exceptions are recorded in the original declared
  replicate order, with no redraw or metric substitution.
  Plain named numeric callbacks remain supported unchanged.

The new pure-R helper
`R/native-functional-recovery-assessment-orchestration.R`
validates and normalizes the structured source-domain
assessment boundary without importing Python. The existing
`R/native-functional-recovery-orchestration.R` now
propagates this scientific evidence and retains the original
fit/truth isolation.

## Tests and source comparison

`tests/testthat/test-native-recovery-structured-orchestration-source.R`
adds five groups:

1. End-to-end native recovery assessments produced by the
   **actual hierarchical known-truth recovery evaluator**,
   using a **Student-t dense** scenario and an
   **irregular Student-t with power-phase/contiguous-block
   missingness** scenario. Validates truth isolation,
   successful replicates, source metric labels and the
   native recovery value/failure frames.
2. Backward compatibility for plain named numeric recovery
   callback outputs.
3. Invalid metric records, duplicate source/component
   labels, invalid units, invalid provenance and definition
   drift across independent replicates. Definition drift
   must fail even with `failure_action="record"`.
4. A real estimator callback failure is preserved as a
   failed replicate without retry, source remapping
   or spurious scientific metric output.
5. Direct pinned Python 1.2 semantic recovery dataclass
   and `as_mapping()` source calls, with exact
   source/numeric key comparisons and semantic definition
   provenance.

All tests are registered in native offline and frozen
Python direct-source qualification modes. Source, test and
documentation artifacts are included in the exact-HEAD
developer evidence inventory.

## Scientific and certification boundaries

The source simulator's advanced stochastic laws are now
available to the native scenario runner through the
already supported scenario fields; this work makes
semantic recovered metrics compatible as well.

Native S3 assessments are **not** Python immutable
dataclass instances, R numeric vector dictionaries are
not MappingProxyType objects, and no full Python
error/accepted-type identity is claimed. The native
runner deliberately rejects malformed records instead
of silently discarding scientific evidence. NumPy PCG64,
the full unrestricted Python domain and independent
full-domain scientific certification are not established. The
full 508-export third-party certification requirement
remains unsigned. The separate CRAN 0.4.2 release
candidate remains untouched.

**The new research HEAD requires a fresh Windows RStudio
source qualification before developer test PASS may be
claimed.**
