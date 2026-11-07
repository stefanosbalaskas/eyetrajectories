# Frozen Python 1.2 nested window/step pair input domain

Upstream frozen source:
`stefanosbalaskas/eyetrajectoriespy` commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/functional_rqa.py`,
`_validated_window_step_pairs` and `windowed_rqa_sensitivity`.

## The source boundary being implemented

Python 1.2 accepts any nonempty outer sequence of exact length-two
`Sequence` objects. Every `window` and `step` must be a strictly
positive finite Python or NumPy integer/floating scalar. Boolean values,
non-numeric strings, irregular pair sizes, NaNs and infinities are
rejected *before* any source NumPy or pandas computation. In sample
units, counts must resolve to integers; valid physical-time units may
be fractional if exactly convertible on the observed grid.

Previously, native R accepted an outer list of numeric length-two
vectors or a two-column numeric matrix but rejected an outer list
whose inner pairs were themselves two-element scalar lists, the
natural native analogue of Python lists/tuples.

## New native implementation

`.etr_validate_rqa_window_pairs` accepts a nested pair such as
`list(list(5L,2L),list(7L,3L))` and normalizes each inner pair into a
numeric vector **only after** checking the two individual input
types, scalar lengths and finiteness. This prevents implicit Boolean
coercion (for example `list(TRUE,2L)`) from being misinterpreted as
a valid source pair. Existing R numeric-vector and matrix forms,
source physics/units, recurrence algorithms, descriptive statistics,
pairwise exact-center comparisons and provenance remain unchanged.

## First-party tests and limitations

`tests/testthat/test-native-windowed-rqa-python-pair-sequence.R`
exercises native nested versus vector representations, source invalid
input domains, duplicate resolved pair detection, fractional physical
time and source provenance. In `ET_RUN_PYTHON_TESTS=true` it invokes
the **actual frozen Python 1.2 public export** and compares numerical
design, summary and pairwise dataframe columns against native R.

The tests are included in both the offline and direct pinned-source
qualification modes, with a source-file integrity manifest entry.
This is an **input-domain improvement**; the full recorded
`windowed_rqa_sensitivity` gap remains open because typed Python
results, error categories, input and numerical domains still require
comprehensive independent review. Independent full-domain
certification remains **0/508**, and no record is closed merely by
this developer-side experiment.
