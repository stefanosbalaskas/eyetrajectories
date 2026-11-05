# Frozen Python 1.2 recurrence: selected-state finite-domain integration

**R research branch:** `research/native-generalized-fosr-prediction-20261030` (not the previously Windows-qualified CRAN candidate).

**Frozen Python source:** `eyetrajectoriespy` commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/recurrence.py::_state_from_source`.

## Scientifically meaningful source-aligned change

For a Python `TrajectorySet`, the frozen source resolves **one requested curve and
explicit named dimensions** into a state matrix *before* checking for finite
values. This means missing measurements on unrelated curves or unused
channels do not invalidate a valid selected-state recurrence analysis.

The original native R `etr_recurrence_matrix()` had an unintended
complete-collection gate: the `dimensions` path made a proxy containing
**all curves** and recursively used `require_complete=TRUE`. The original
`etr_cross_recurrence_matrix()` rejected both whole collections before
subsetting. Embedded `etr_delay_embedding_set` recurrence and the embedded
radius-profile route also checked the complete array rather than the one
requested curve.

The new native scientific implementation now:

1. Validates requested curve IDs and ordered channels; selects the *single*
   relevant R curve before a local finite check.
2. Preserves the source curve ID, coordinate system, time unit, per-curve
   metadata, source provenance, explicit selected dimension names and the
   full unmodified original collection.
3. Reuses the **existing real native R** L1/L2/L-infinity distance kernels,
   Theiler exclusion, 48-step inclusive target-rate radius selection and
   recurrence CDF; it never silently imputes, fills, drops or interpolates
   selected missing values.
4. Applies equivalent selected-state validation in source-aligned
   cross-recurrence and embedded-state recurrence/radius-profile paths.
5. Retains `dimensions=NULL`'s **existing legacy R all-channel behavior**
   for backwards compatibility (not represented as complete Python parity).

## Regression evidence required before claiming PASS

`tests/testthat/test-native-recurrence-selected-state-source.R` adds:

- Native selected-curve auto-recurrence comparisons across
  `euclidean`, `cityblock`, `chebyshev`, each under fixed and
  target-rate policies.
- Native cross-recurrence selected-state comparisons under all three
  metrics and both radius policies.
- Embedded source selected-curve recurrence, cross-recurrence and radius
  empirical-CDF regression with missing states in an unrelated curve.
- Direct **actual frozen Python runtime calls** to
  `recurrence_matrix`, `cross_recurrence_matrix`, and
  `recurrence_radius_profile`, including geometry, selected rates,
  radius, CDF schema and values.
- Rejection when the *selected* channel/curve contains missing values.

The test file is registered under both `native_r_offline` and
`python_1_2_direct_source` author qualification filters, as well as the
source-file evidence inventory.

**Status: implementation committed; author-side RStudio execution required.**
The R runtime is not available in the implementation environment, and no
independent party has signed a full-domain contract review. Do not increase
the independent certification counter or automatically close any historical
source-gap entry.

## Unresolved source gaps

Native output remains a dense S3 list, **not** Python's
`scipy.sparse.csr_matrix` and `RecurrenceResult` dataclass; the native R
dense-state and pair-count limits remain. The legacy R zero-radius support
is outside Python's strictly positive fixed-radius domain. Input exception
classes, strict language-level zero/one-based index semantics, and schema
serialization are not fully one-to-one. Complete full-domain science and
independent adjudication remain outstanding.

The staged CRAN `0.4.2` Windows check at prior commit
`bc3c6d140184068472376d26181ce483094911d3` passed with only
the reviewed `New submission` NOTE. Research commits made **after**
that HEAD are not part of that previously qualified candidate.
