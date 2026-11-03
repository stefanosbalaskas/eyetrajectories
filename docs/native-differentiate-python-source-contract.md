# Native R first-/second-order trajectory differentiation

**Frozen source:** `eyetrajectoriespy==1.2.0` at immutable commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/kinematics.py::differentiate_trajectories`.

## Scientific integration

The prior 508-export source inventory mapped Python
`differentiate_trajectories` to `etr_velocity`: a genuine native R
first-order derivative, but it did not have the source's
`order=2` (second derivative) parameter or the Python
`provenance["derivative"]` record. A separate native
`etr_acceleration` convenience function computed a second
derivative, but did not give the mapped source export a unified
source-compatible interface. This constituted an actual coverage
difference despite a full 380/380 named-candidate inventory.

The new exported `etr_differentiate_trajectories(x, order=1L)`
uses the previously validated `.etr_gradient` irregular-time
second-order-edge finite difference twice for order 2, exactly
corresponding to the frozen Python recursive
`numpy.gradient(axis=1, edge_order=2)` definition. It
propagates the original channel order, curve IDs, metadata, time
grid, coordinate system, units, and prior named provenance,
and records:

```r
list(derivative=list(order=2L,method="numpy_gradient",smoothing=FALSE))
```

The returned dimensions are suffixed `_velocity` or
`_acceleration` following the frozen Python function. Native
`etr_velocity` and `etr_acceleration` remain unchanged,
with the original default object/provenance behavior.

`R/native-full-parity-ledger.R` now maps the Python source function
to this dedicated R analogue. The new function is exported from
`NAMESPACE` and described in
`man/etr_differentiate_trajectories.Rd`.

## Source validation

`tests/testthat/test-native-differentiate-source-contract.R`
contains four grouped tests:

1. Native order-1/order-2 values against established R
   velocity/acceleration and analytically known polynomial
   derivatives on an irregular time grid.
2. Source field/provenance preservation, Boolean TRUE order
   and the Python membership semantics for the numeric order 2.0.
3. Fail-closed unsupported order types/values, too-short grids,
   incomplete samples and exact named-candidate mapping.
4. Opt-in direct frozen Python 1.2 source calls at order 1 and 2,
   comparing all channels/curves, suffixes, coordinate semantics
   and recorded derivative provenance.

The cases are included in both native and direct Python
qualification modes; new source and test files are part of
the author-side SHA evidence inventory.

**Open boundaries:** Python can accept additional types for
`order` through its set membership semantics, source exceptions
are not reproduced byte-for-byte, and native R object class/
serialization differ. Full-domain source equivalence, Monte Carlo
inference and independent certification cannot be inferred from
first-party numerical tests. The 204 recorded source gaps and
zero independent 508-export certificates remain unchanged until
their review workflow explicitly resolves them.

**CRAN:** This research integration does not modify the separately
qualified staged 0.4.2 release candidate.
