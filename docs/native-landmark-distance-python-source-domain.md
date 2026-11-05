# Landmark-distance scientific source-domain integration

**Frozen Python 1.2 source of record:** `eyetrajectoriespy` commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/kinematics.py::distance_to_landmark_function`.

## Gap closed within a bounded numerical domain

Frozen Python computes planar gaze-to-landmark distance as
`sqrt((x - landmark_x)^2 + (y - landmark_y)^2)`, uses
`np.asarray(landmark_x/y, dtype=float)`, broadcasts true
0-dimensional scalar landmarks across curves, and accepts one
numeric-convertible value per curve otherwise. This includes
Boolean scalars, numeric strings, Boolean vectors, and
heterogeneous Python lists with finite numeric-convertible elements.

Previously, native `etr_distance_to_landmark` accepted only finite
numeric scalars/vectors, rejecting these frozen-source inputs.
Now `python_boundary_mode=TRUE` reuses the independently developed
`.etr_preprocessing_python_landmarks` conversion logic from
`center_on_landmark`, including per-element mixed-list coercion
(`True -> 1`), the distinction between scalar broadcasting and a
one-element list, finite-domain validation and exact trajectory count.

The native Euclidean distance geometry is unchanged; **both modes
remain Python-free**. The default
`etr_distance_to_landmark(x, landmark_x, landmark_y)`
retains its previous strict numeric input rules and result semantics.

## Python provenance alignment

The frozen function constructs an output
`TrajectorySet` preserving source time, curve IDs, metadata,
coordinate system, time units and original provenance while setting
`provenance["derived_function"]="distance_to_landmark"`.

The new explicit source mode applies the same named provenance
addition through the native JSON-like trajectory constructor. The
legacy default native path retains its original provenance. Extra
input channels are ignored for Euclidean planar output, as in Python.
Missing gaze values still propagate to the affected derived samples.

## Regression and reproducibility

`tests/testthat/test-native-landmark-distance-source-domain.R`
has four source-grounded test groups:

- Mixed Boolean/string/numeric per-curve landmarks against
  pure numeric R controls, including provenance and metadata.
- Scalar broadcasting and fail-closed malformed/ambiguous domains.
- Missing gaze propagation at one source sample with all
  unaffected samples checked.
- An opt-in pinned Python 1.2 source oracle that calls the **actual**
  `distance_to_landmark_function` export for heterogeneous per-curve
  lists, numeric-string/Boolean vectors and Boolean/string scalars,
  comparing values and selected metadata/provenance.

Tests are registered in both `native_r_offline` and
`python_1_2_direct_source` qualification modes; their source file
and modified R module are tracked in the evidence inventory.

**Limits:** Not all arbitrary Python objects, nonfinite landmarks,
or foreign NumPy dtypes are emulated. Source Python output classes,
all exception messages, serialization and entire callable input domain
remain unqualified. Scientific fidelity on the tested domain should
be checked by exact-HEAD Windows RStudio qualification, then by
independent third-party review; the test packet alone cannot certify
a source contract or reduce the 204 documented full-domain gaps.
The separately staged CRAN 0.4.2 candidate is not modified.
