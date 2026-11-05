# Python 1.2 native preprocessing scalar/coercion integration

**Frozen Python:** `eyetrajectoriespy==1.2.0` at commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/preprocessing.py`.

## Source differences addressed

1. `normalize_coordinates` tests `width <= 0` and `height <= 0`,
   then divides the first two trajectory channels by these extents.
   Python Boolean `True` therefore behaves like width/height 1,
   while `False` fails the positive-extent check. Native
   `etr_normalize_coordinates(...,python_boundary_mode=TRUE)`
   supports these Boolean source scalars. FALSE retains strict
   finite numeric scalar checks.
2. `center_on_landmark` converts `landmark_x/y` using
   `np.asarray(dtype=float)`, repeats 0-D scalars, and otherwise
   requires exactly `n_curves` entries. Native
   `etr_center_on_landmark(...,python_boundary_mode=TRUE)`
   accepts finite numeric-string and Boolean scalar/vector
   landmarks and explicit one-element-per-curve lists. An R list
   of length one on a three-curve collection correctly fails rather
   than silently broadcasting. The source still supports other
   duck-typed scalar/vector objects outside this bounded native
   implementation.
3. `normalize_time` maps `start/end` through ordinary Python
   arithmetic, so Boolean False/True behave as 0/1. Native
   `etr_normalize_time_interval(...,python_boundary_mode=TRUE)`
   implements Boolean endpoints while retaining native strict
   finite numeric defaults.

Scientific output values preserve input curve IDs, metadata and
unmodified channels. No smoothing, imputation or Python execution
happens in the native functions.

### Mixed scalar landmarks: November 3 correction

Author-side RStudio qualification at `ee66a4df6b720b64e01188a5311f3a1a89db4aa0`
reported one `center_on_landmark` test failure in both native-offline and
Python-source modes. The source was an R-only conversion bug:
`as.numeric(unlist(list("1.5", 2, TRUE)))` loses the Boolean type because
`unlist()` first coerces the heterogeneous list to strings. The frozen
Python source `np.asarray(..., dtype=float)` instead converts its
elements to `[1.5, 2.0, 1.0]`.

The R implementation now applies scalar numerical coercion independently
inside `vapply(..., numeric(1L))`; malformed strings and nonfinite
values still fail. The native regression includes two mixed-type
landmark lists and compares against pure numeric inputs. The opt-in
Python test additionally calls the actual frozen source with
`[True, "2.5", 0]` and `[False, 1, "3.5"]`.
This is a *specific source-domain alignment*, not full source review.

## Direct frozen-source evidence

`tests/testthat/test-native-preprocessing-python-boundary-source.R`
provides four grouped regression cases, including true Python
runtime oracles for all three Python public exports:
`normalize_coordinates`, `center_on_landmark`, `normalize_time`.
The file is included in both developer qualification modes and
the source-file evidence inventory.

These improvements are **bounded numerical-input-domain
alignments, not full Python API equivalence**. For example, Python
provenance may retain the original Boolean parameter type whereas
the R numeric compatibility path records its numeric interpretation;
Python allows some malformed/nonfinite scalar behavior that the R
scientific API deliberately rejects, and Python can accept
additional duck-typed scalar objects. These are explicit
representation/exception boundaries for later scientific review.

**Verification status:** source implementation and tests committed;
independent RStudio tests must be rerun at the exact new research
HEAD. Do not change historical source-gap counts or independently
certified fields based on author-side fixtures. The earlier separately
staged CRAN `0.4.2` candidate is unchanged and is not qualified at
this newer research HEAD.
