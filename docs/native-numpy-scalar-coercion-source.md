# Frozen Python 1.2 bounded NumPy input conversion

Pinned source `eyetrajectoriespy==1.2.0` (`c1cd95ad718327550f7e55393ff38582872f7a94`): `fpca.py::functional_trapezoid_weights`, `analysis.py::discrete_frechet_distance`, and `analysis.py::dynamic_time_warping_distance` use `np.asarray(...,dtype=float)`.

The native R quadrature code now performs scalar-by-scalar conversion of mixed logical / numeric-string / numeric lists. Previously R `unlist()` promoted `TRUE` to the string `"TRUE"`, failing a legitimate NumPy-compatible input. Native Fréchet and DTW expose `python_boundary_mode=TRUE` to accept bounded, finite numeric-compatible 2D matrices or regular nested point rows, including Boolean and numeric-string weights. Default strict native-R validation is unchanged. The pairwise native R APIs `etr_pairwise_frechet` and `etr_pairwise_dtw_full` additionally support the same opt-in finite numeric-string/Boolean `dimension_weights`; their input trajectories remain native R trajectory sets.

Source unit tests in `tests/testthat/test-native-numpy-input-coercion.R` and `tests/testthat/test-native-pairwise-numpy-weights.R` cover numerical weights, distance, zero-based paths and weighted DTW costs with opt-in real frozen Python 1.2 calls. Irregular/ragged, nonfinite and zero-weight inputs fail closed. Native dense dynamic programming retains an explicit 5e6 point-pair guard absent in Python; Python typed dataclasses and R S3 classes differ. This is **not** a full input-domain or independent scientific certification.

Historical open gaps: **204** recorded exports. Independently approved full-domain contracts: **0/508**.
