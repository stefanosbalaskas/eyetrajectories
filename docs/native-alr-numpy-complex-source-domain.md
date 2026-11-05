# Frozen Python 1.2 ALR: complex ndarray casting and output shapes

Pinned upstream: `stefanosbalaskas/eyetrajectoriespy` commit
`c1cd95ad718327550f7e55393ff38582872f7a94`, file
`src/eyetrajectoriespy/compositional.py`:
`alr_transform` and `inverse_alr`.

## Inspected frozen Python behavior

Both source functions first use `np.asarray(..., dtype=float)`.
For a **complex NumPy ndarray** this casts to the real component and
emits a `ComplexWarning`; for a Python nested sequence of complex
scalar objects the numeric float conversion may raise instead.
The native opt-in implementation supports the former representation
but does not claim support for the latter.

`alr_transform` validates a simplex **after** numeric casting, clips
by a declared epsilon, renormalizes and computes log ratios against
the zero-based reference channel.

`inverse_alr` checks 3D logit shape, creates an `np.ones` output with
the requested `n_dimensions`, inserts `np.exp(z)`, and divides by the
third-axis sum. In NumPy this expression can produce NaN/Inf for
extreme logits. The source passes Boolean reference indices via
Python integer arithmetic, but `np.ones` rejects Boolean or
integer-valued floating-point output-shape scalars.

The reference `np.ones(shape)` API requires an integer or integer
sequence. See https://numpy.org/doc/stable/reference/generated/numpy.ones.html
and https://numpy.org/doc/stable/reference/generated/numpy.exceptions.ComplexWarning.html.

## Native R changes

With `python_boundary_mode=TRUE` only:
- `etr_alr_transform` casts complex atomic 3D arrays to real before
  simplex validation, and accepts a Boolean reference index as 0/1.
- `etr_inverse_alr` casts complex atomic 3D logit arrays to real,
  accepts Boolean reference indices and requires an integer R storage
  type for `n_dimensions`. Nonfinite arithmetic from exponentiation
  and division remains source-style rather than forced finite.
- `n_dimensions=1L` with an empty final logit channel remains a
  mathematically defined 3D output of ones.

The **default mode** retains strict, finite native-R validation and
the previous integer-valued-double `n_dimensions` acceptance.

## Executable evidence and limitations

`tests/testthat/test-native-alr-numpy-complex-source.R` includes
finite simplex, complex imaginary part including NaN/Inf,
zero-based and Boolean reference indices, ordinary inverse
reconstruction, single-channel and overflow/nonfinite cases,
plus error tests for NumPy-compatible output shape types.

Under `ET_RUN_PYTHON_TESTS=true`, tests invoke the actual frozen
public Python 1.2 exports, suppress expected complex/overflow
warnings in the Python oracle, and directly compare numerical
arrays and NaN positions. Both the offline R and pinned Python
direct-source qualification runners include this suite.

These are developer tests, not independent full-domain certification.
Source-mode conversion does not reproduce every possible Python
container, typed exception, memory/array subclass or backend
return-object contract. The historical ALR source-gap register
therefore remains **unresolved** pending full-domain audit, and
`0/508` independently certified public exports remains unchanged.
