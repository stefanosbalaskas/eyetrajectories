# EyeTrajectories — observed Python 1.2 / native R elastic numerical differential

**Status:** local Windows RStudio result supplied by the user on 2026-11-13; result recorded verbatim to available precision. **Not independently reproduced or certified in CI.**

## Scientific context

The identical six-curve, two-coordinate, 25-time-point phase-varying fixture is passed to:

- Real frozen public Python `eyetrajectoriespy==1.2.0`, `fdasrsf==2.7.4` `fit_elastic_fpca(..., n_components=2, rotation=False, scale_curves=False, lam=0, method="DP")`, with real Karcher mean, separate SRVF phase alignment and shape PCA, called in `joblib.parallel_config(backend="threading")` to bypass Windows reticulate/loky handle limitations.
- Native R `etr_fit_elastic_fpca(..., n_components=2, rotation=FALSE, scale_curves=FALSE, lam=0, method="DP", strict_source_record=TRUE)` using actual R `fdasrvf>=2.5.1` Karcher DP and tangent-space shape PCA.

The Python test performed three logged Karcher updates. All structural and scientific-domain invariants in `tests/testthat/test-native-elastic-fdasrvf-karcher-pca-20261113.R` passed. A warning indicated that R `fdasrvf` was compiled under a slightly newer R 4.6 point release. There were no reported test errors or skips.

## Actual observed discrepancies

```text
ELASTIC_PYTHON12_NATIVE_R_DIFFERENTIAL_NUMERICAL_AUDIT
  warp_rmse = 0.0919100238219
  warp_max_abs = 0.15
  aligned_centered_rmse = 0.251928599932
  karcher_mean_centered_rmse = 0.505506516285
  score_pairwise_distance_rmse = 0.598456909462
  numerical_parity_certified = FALSE
```

| Quantity | Exact calculation | Observation | Meaning |
| --- | --- | ---: | --- |
| `warp_rmse` | `sqrt(mean((R_gamma - Python_gamma)^2))` | 0.0919100238219 | Root mean square phase-warp discrepancy in the **normalized 0–1 time domain** |
| `warp_max_abs` | `max(abs(R_gamma - Python_gamma))` | 0.15 | Maximum individual normalized-time difference, **15% of the normalized interval**; not 0.15 milliseconds |
| `aligned_centered_rmse` | RMS after subtracting each curve's channel-wise temporal mean | 0.251928599932 | Spatial/alignment discrepancy after removing per-curve translation |
| `karcher_mean_centered_rmse` | RMS after subtracting each mean curve's channel-wise temporal mean | 0.505506516285 | Difference in estimated mean geometric shapes, with translation removed |
| `score_pairwise_distance_rmse` | RMS between vectors of Euclidean pairwise distances among six samples' 2-D PCA scores | 0.598456909462 | Invariant to component sign flips, permutations, common orthogonal rotations; **not** invariant to scale or algorithmic subspace differences |

**Do not compare raw coordinate/score RMSE values as percentages.** Their scales differ and no relative normalization, null baseline, confidence interval or independent source-acceptance tolerance was pre-established. All values are descriptive discrepancies, not hypothesis-test p-values or estimates of real-data error.

## Inspection of actual source implementations

Frozen Python `elastic.py` calls `fdacurve.karcher_mean`, then **separately** `fdacurve.srvf_align`, then `shape_pca`. The upstream Python `fdasrsf/curve_stats.py` initializes its first mean with the **first curve** and, in `srvf_align`, applies the estimated gamma to the original curve coordinates via `group_action_by_gamma_coord`.

The independent native R `fdasrvf::multivariate_karcher_mean` initializes from the **SRVF medoid** (determined by source distances) and derives its aligned curves with `q_to_curve` from aligned SRVFs inside the Karcher fit. Its `multivariate_pca` computes covariance/SVD on the returned native tangent-shooting vectors. Both are real elastic algorithms, but not implementation-identical.

These distinctions can account for non-zero numerical discrepancies; their **causal contributions have not yet been separated or empirically assigned**. Do not assert that initialization alone explains the 0.5055 mean RMSE, or that different solver choices necessarily make further improvement impossible. The real Python and R implementations each need known-truth independent scientific calibration.

## Next scientific gate

1. Repeat this fixture with **per-curve** warp and aligned-shape error breakdown, native vs Python deviation from *the same unregistered input*, and **relative** RMSE referenced to the observed shape/score scale.
2. Disentangle the difference in Karcher mean initialization (Python first curve versus native medoid) from the second coordinate-space alignment/reconstruction choice, using independent source-faithful implementations or controlled ablation comparisons; preserve true DP matching.
3. Compare tangent covariance eigenspectra, sign/permutation/rotation-invariant PCA score geometry, and leading eigen-subspace projectors, separating scale differences from subspace differences.
4. Validate each solver against **known simulated warping truth and reconstruction fidelity**, including trials with multiple curve orderings, phase perturbations, and out-of-sample shapes. Choose acceptance criteria in advance; a retrospective tolerance wide enough to pass this case is not certification.
5. Only close the `full_numeric_qualification_and_broad_data_domain` scoped gap after independent numerical evidence, method-domain review, and exact-head CI qualification. **The present gap remains OPEN.**

The recorded **508/508 author-scoped native implementation coverage** is not equivalent to complete `eyetrajectoriespy` numerical parity; independent full Python-contract certification remains zero.

## Follow-up diagnostic decomposition added (awaiting execution)

The next unexecuted test extension in `test-native-elastic-fdasrvf-karcher-pca-20261113.R` prints `ELASTIC_PYTHON12_NATIVE_R_DIFFERENTIAL_DECOMPOSITION` and records:

- Warp deformation RMSE **relative to identity** separately for Python and native R.
- Centered input, Python aligned and Python mean coordinate RMS scales.
- Relative score pairwise-distance scale, an optimized *single scalar* mapping native score distances to Python score distances, and residual pairwise-distance RMSE after that mapping.
- Rank-preserving Pearson correlation of pairwise PCA score distances (a measure of score geometry concordance, not proof of eigenspace parity).
- Six individual per-curve warp RMSE values and six per-curve centered aligned-geometry RMSE values.

This separates scale-related disagreement from shape/phase geometry and highlights possible curve-specific registration failures. The original five-metric values above remain the confirmed local observations. **No values from the new decomposition have been observed**, no scientific acceptance threshold was changed, and numerical parity remains unqualified.
