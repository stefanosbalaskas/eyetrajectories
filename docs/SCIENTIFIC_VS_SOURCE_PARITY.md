# Batch 32: scientific R functionality versus Python 1.2 source contracts

**Frozen Python source:** `eyetrajectoriespy` 1.2.0 at
`c1cd95ad718327550f7e55393ff38582872f7a94`, file
`src/eyetrajectoriespy/compositional.py::inverse_alr`.

Python source exponentiates ALR coordinates directly and normalizes their
sum. At large positive finite logits, `np.exp` overflows and may result in
`NaN`. That behavior is an existing **source contract**, and is deliberately
NOT changed, hidden, or called equivalent to a stable inverse.

This batch adds two **native scientific R functions**:

- `etr_inverse_alr_stable()`: log-sum-exp normalization of finite ALR logits,
  and an explicit optional limiting policy for positive/negative infinities.
- `etr_reconstruct_compositional_fpca_stable()`: FPCA inverse transform through
  the stable ALR path; the original FPCA reconstruction remains untouched.

Tested contracts: normal-valued direct Python results (when the frozen Python
runtime is available), extreme finite sample-wise normalization, arbitrary
zero-based reference index, exact simplex support, nonfinite and malformed
input rejection. No source-gap ledger item is closed by introducing these
**additional** scientific methods. No independent certification is claimed.

## Release lanes

1. Native R scientific readiness: proper inputs, mathematical invariants,
   numerical robustness, appropriate R outputs, documentation and unit tests.
2. Exact Python source parity: separate source-specific exceptional semantics,
   Python container classes and numerical boundary comparisons.
3. CRAN: clean committed snapshot, full `R CMD build`, `R CMD check --as-cran`,
   no unexpected WARNINGS/ERRORS, and review of any NOTES.

Do not infer a CRAN pass or 508-function scientific certification from a
passing smoke suite. The historical gap ledger remains 204 rows with
202 developer-active items; independent full certification is 0/508.
