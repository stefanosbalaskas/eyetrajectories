# Engineering pairwise functional distances: an R-only OneStop performance benchmark

*Technical validation note · 17 November 2026 · eyetrajectories*

## Summary

A compiled distance-matrix path was developed for native `etr_pairwise_l2()` to remove repeated R-level pair evaluation. On one Windows 11/R 4.6.1 environment, processing **1,000 fixation-level eye-tracking trajectories sampled on a declared 128-point normalized time grid** took a median of **31.91 seconds** in the baseline and **0.305 seconds** in the optimized 0.4.3 development branch—a **104.6-fold observed speedup**. Six configurations showed a 104.6×–214.9× speedup. In both runs, the **21 declared numerical checks passed**. These findings support computational equivalence within the tested domain, not universal numerical parity or calibrated scientific inference.

## Scope and provenance

The input was a real repeated-reading fixation-level OneStop CSV member `fixations_Paragraph_repeated.csv`, extracted from an archive of 34.84 MiB with verified MD5 `650d93a8c73af6a9b3ca19a7c4e542fb`. The benchmark read 144,245 rows and 1,944 trials; 1,878 met the preregistered processing criterion of at least 24 valid fixation observations, and 1,000 trials were selected in deterministic identifier order rather than by observed outcomes.

The observed columns were `participant_id`, `TRIAL_INDEX`, `CURRENT_FIX_X`, `CURRENT_FIX_Y`, and `CURRENT_FIX_START`. Coordinates were fixation positions in pixels and timestamps were recorded in milliseconds. Curves were interpolated onto common grids of 64 or 128 positions in **within-trial normalized recorded time [0,1]**. This is a computational comparison on preprocessed fixation trajectories: it is **not** a raw 1,000 Hz gaze comparison, a physical velocity validation, or a claim that interpolation is scientifically harmless for all gaze estimands. Original source files were not modified.

Both baseline and optimized runs were R-only and measured three repetitions per configuration using base R process time, batching very fast operations where required. Only package calls were timed; data acquisition and preprocessing were not part of the timing.

## Mathematical implementation

For trajectories `x_i(t) ∈ R^p` and nonnegative channel weights `a_k`, the squared integrated distance on a common time grid is approximated by

```text
D(i,j)^2 = Σ_t w_t Σ_k a_k [x_i(t,k) − x_j(t,k)]² ,
```

where `w_t` are trapezoidal quadrature weights. Define the flattened weighted vector `z_i(t,k) = sqrt(w_t) sqrt(a_k) x_i(t,k)`. Its Euclidean norm satisfies `||z_i−z_j||₂ = D(i,j)`.

The baseline evaluated one trajectory pair at a time in interpreted R. The optimized finite-data implementation constructs a curve-by-feature matrix and applies compiled `stats::dist(..., method = "euclidean")`. It translates all trajectories relative to the first trajectory before scaling to reduce unnecessary overflow from large shared offsets. If transformation produces a non-finite value, the original scalar integration is retained as fallback.

The optimization retains pairwise distance matrix shape, curve IDs, zero diagonal, symmetric entries, irregular-grid quadrature and channel weights. The original public API of the older `main` development snapshot is preserved; the optional `python_boundary_mode` argument found in the newer 0.4.3 development branch was **not** added to older `main`.

## Observed performance

| Curves | Points | Baseline L² median (s) | Optimized L² median (s) | Baseline / optimized |
| ---: | ---: | ---: | ---: | ---: |
| 250 | 64 | 1.82 | 0.008657 | 210.2× |
| 500 | 64 | 7.52 | 0.035 | 214.9× |
| 1,000 | 64 | 29.58 | 0.150 | 197.2× |
| 250 | 128 | 1.95 | 0.017222 | 113.2× |
| 500 | 128 | 7.94 | 0.068 | 116.8× |
| 1,000 | 128 | 31.91 | 0.305 | 104.6× |

Source: independent author-side OneStop baseline `REAL_ONESTOP_PACKAGE_SCALING_V1` and optimized `REAL_ONESTOP_PACKAGE_SCALING_FASTPATH_V2` records (21/21 checks each), optimized exact source commit [2799d7e](https://github.com/stefanosbalaskas/eyetrajectories/commit/2799d7e37360f2c3a897adfb0c4ea28fb069c13b). The optimized benchmark used an isolated GitHub development-branch checkout; the published stable v0.4.3 package was not replaced. These ratios are observations on the given machine and inputs and are not cross-platform or competitor speed comparisons.

The computed 1,000-by-1,000 distance matrix occupies approximately 7.77 MiB as an R output object; this is not process peak RAM. The benchmark recorded R garbage-collector managed heap components, not peak operating-system resident set size. Timings for functions other than pairwise L² are not claimed as optimized.

## Numerical checks and boundaries

The optimized benchmark passed all 21 declared checks and reported zero numerical failures. The largest L² discrepancy against the benchmark's 16 independent R trapezoidal reference pairs per configuration was approximately **4.55 × 10⁻¹³**, below the declared configuration-specific tolerances (~1.0 × 10⁻⁶). Symmetry and diagonal identities also passed. The exact-head GitHub Actions [native pairwise L² regression](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/44071448881) passed for the source implementation; tests include irregular grids, unequal/zero weights, 1D–3D trajectories, near-coincident curves, invalid inputs, overflow fallback and the newer branch's optional nonfinite compatibility behavior.

**Limitations:** The independent benchmark does not prove performance on every possible trajectory size, numerical regime, operating system or hardware. The finite-input fast path is only one package operation. R-only testing cannot certify Python backend parity. No inferential calibration, clinical or behavioral validity, competing package benchmark, or independent external certification is inferred. The old `main` snapshot's separately ported fast path requires its own regression verification; the above timing numbers were measured on the 0.4.3 development branch.

## Reproducibility and release boundaries

- [Merged optimization PR #191](https://github.com/stefanosbalaskas/eyetrajectories/pull/191) is the source of the improved implementation and records independent real-data benchmark results.
- [Exact-head successful R CI](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/44071448881) tests the optimized release-development source.
- The archived [v0.4.3 release](https://github.com/stefanosbalaskas/eyetrajectories/releases/tag/v0.4.3) and [version DOI](https://doi.org/10.5281/zenodo.24288857) remain immutable; do **not** attribute the post-release optimization to those archived bytes.
- This page is a software engineering and computational validation report, **not a peer-reviewed journal article**.

For scientific application, record the exact commit or archive, time normalization/interpolation decisions, participant/trial structure and acquisition units. Investigators should verify that functional-distance assumptions match their data before interpreting gaze phenomena.
