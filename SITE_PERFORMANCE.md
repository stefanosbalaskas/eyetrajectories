# Real-data benchmark: accelerating native R trajectory distances

*17 November 2026 · Technical note · `eyetrajectories`*

**Development-branch result, not a new stable release.** A compiled finite-data implementation of `etr_pairwise_l2()` reduced pairwise functional-distance computation times by approximately **105–215×** across six measured OneStop eye-tracking configurations, while passing all 21 declared numerical checks. This note documents exactly what was tested and what the result does *not* establish.

## At a glance

| Metric | Result |
| --- | --- |
| Real-data source | OneStop repeated-reading fixation-level CSV |
| Input audit | 144,245 rows; 1,944 trials; 1,878 eligible |
| Curves selected | 1,000, deterministic identifier order |
| Common time grids | 64 and 128 interpolated points in normalized trial time |
| Numerical checks | 21/21 PASS in both original and optimized runs |
| Largest optimized L² reference discrepancy | Approximately 4.55 × 10⁻¹³, below the declared per-case tolerance |
| Main bottleneck at 1,000 curves × 128 points | 31.91 s → 0.305 s median (104.6×) |
| R source | Compiled base R `stats::dist()` for finite trajectories, scalar safety fallback |
| Software release | Archived v0.4.3 unchanged; optimized development commits separately tracked |

## Results: every measured configuration

All values are medians from three base R timing repetitions; the original and optimized runs used the same declared preparation and curve/grid combinations.

| Number of trajectories | Samples per curve | Original L² (s) | Optimized L² (s) | Observed ratio |
| ---: | ---: | ---: | ---: | ---: |
| 250 | 64 | 1.82 | 0.008657 | 210.2× |
| 500 | 64 | 7.52 | 0.035 | 214.9× |
| 1,000 | 64 | 29.58 | 0.150 | 197.2× |
| 250 | 128 | 1.95 | 0.017222 | 113.2× |
| 500 | 128 | 7.94 | 0.068 | 116.8× |
| 1,000 | 128 | 31.91 | 0.305 | 104.6× |

The baseline scales approximately quadratically with the number of trajectories, as expected of a full pairwise distance matrix. The compiled implementation retains this pair count and the same matrix dimensions, but substantially reduces interpreted R overhead on the tested machine. **This does not establish that the algorithm has subquadratic computational complexity**: a dense 1,000-by-1,000 matrix is still produced (approximately 7.77 MiB as an R result).

## Why the optimized calculation is equivalent in the tested domain

For multichannel curves sampled on a shared grid, the trapezoidal approximation to the integrated weighted squared L² distance is

\[
D^2(i,j) = \sum_{t} w_t \sum_{k=1}^{p} a_k
  \left(x_i(t,k)-x_j(t,k)\right)^2,
\]

where `w_t` are quadrature weights and `a_k` are nonnegative channel weights. Flattening the curve into a feature vector and multiplying each coordinate by `sqrt(w_t a_k)` converts this expression into an ordinary Euclidean distance. The new finite-data path performs those calculations using compiled `stats::dist()` rather than calling R-level integration for each pair.

The implementation centers input curves on the first observed trajectory before scaling, reducing avoidable overflow from a large common coordinate offset. If numerical transformation becomes non-finite, it uses the established scalar implementation rather than returning a potentially misleading compiled result. Irregular time grids, channel weights, zero weights, symmetric output and original curve IDs are covered by regression tests.

## What the real gaze data mean

These were **real fixation-level observations**, not synthetic gaze records. The input was the verified ZIP member `fixations_Paragraph_repeated.csv` (source archive MD5 `650d93a8c73af6a9b3ca19a7c4e542fb`). Required columns included participant ID, trial identifier, fixation position in pixels and fixation start time in original milliseconds. The benchmark accepted trials with at least 24 valid observations, and made its 1,000-trial selection by deterministic identifier order.

To fit common-grid numerical contracts, observations were interpolated to 64- and 128-point *within-trial normalized-time grids*. These preprocessed curves are **not equivalent to raw 1,000 Hz gaze streams**, and their derivatives should not be interpreted as physical eye speed. The original source recordings were not modified.

## Accuracy, reproducibility and limitations

The original and optimized runs each passed **21 of 21** numerical benchmark checks. The optimized L² path agreed with 16 separately calculated trapezoidal R reference pairs per configuration to within the declared tolerances; its largest discrepancy was approximately `4.55e-13`. Symmetry and identity checks also passed. The [exact-head focused R regression workflow](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/44071448881) completed successfully on the optimized implementation.

Interpret these findings with appropriate limits:

- The speedup applies to one measured machine, six configurations and a particular finite-input dataset. Other hardware, curve lengths, memory conditions and numerical domains require separate tests.
- Both timing exercises measured package calls only. The comparison does not include acquisition, interpolation, file loading, or end-to-end study processing.
- Garbage-collector component highs were recorded, **not** peak operating-system resident memory.
- No statistical inferential calibration, clinical performance, behavioral hypothesis test or comparison against competing tools was carried out.
- Passing unit and benchmark tests does not constitute full independent scientific certification.

## Code, archive and responsible citation

The optimization and its qualification record are available in [GitHub PR #191](https://github.com/stefanosbalaskas/eyetrajectories/pull/191), merged into the 0.4.3 *release-development* branch. A separately adapted implementation is integrated into the older `main` development API, with branch-specific tests. The original [stable GitHub release v0.4.3](https://github.com/stefanosbalaskas/eyetrajectories/releases/tag/v0.4.3) and [Zenodo DOI 10.5281/zenodo.24288857](https://doi.org/10.5281/zenodo.24288857) remain immutable. **Do not describe the archived stable release as containing this post-release optimization.**

For technical detail, see the [full reproducibility report in the repository](https://github.com/stefanosbalaskas/eyetrajectories/blob/main/docs/onestop-pairwise-l2-performance-2026-11-17.md). This is an openly documented engineering benchmark, **not** a peer-reviewed journal article.
