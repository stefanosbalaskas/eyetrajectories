# Frozen Python 1.2 multivariate IAAFT initialization replay (Batch 17)

Pinned Python: `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `multivariate_surrogates.py`. Qualified R baseline **`32b8f77`**.

The source draws independent initial time permutations for every selected channel in every surrogate from NumPy PCG64 and then iterates the original Fourier magnitude, phase-difference, rank-remapping loop. Base R uses a different RNG; matching integer `random_state` alone is not source parity.

The existing `etr_generate_multivariate_iaaft_surrogates()` now accepts optional `initial_permutations` as a zero-based integer-valued array of dimensions `(n_surrogates,n_time,n_selected_dimensions)`. Every per-channel index vector must be a complete 0..n_time-1 permutation. The declared dimension order matters. With the supplied arrays, no R RNG state is consumed, and the rest of the native numerical algorithm remains unchanged. Without them, the original native RNG route is retained.

`test-native-miaaft-fixed-permutation-source.R` constructs the **public** frozen Python generator's initial permutations using its own NumPy PCG64 stream, calls the public source generator on an identical real input, and compares the complete R surrogate trajectories, convergence iteration counts, Fourier magnitude and cross-spectrum error arrays. It checks both 23-point and 32-point grids, 3 channels, nontrivial channel order and a non-first reference channel. Malformed, missing, fractional, duplicate, out-of-range and wrong-shaped source initialization is rejected.

The identical optional replay is also forwarded through `etr_multivariate_surrogate_nonlinearity_test()` and checks its complete native surrogate-statistic and plus-one p-value calculation under fixed source initialization. The patch **does not** reproduce the NumPy PCG64 PRNG in R, establish a direct default-seed equivalence, cover all shape/error domains, or constitute external independent source-contract certification. The callable ledger flag stays `TRUE`.
