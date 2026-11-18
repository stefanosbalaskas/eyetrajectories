# Four Flagship Research Workflows — executable native R

[**Open the four complete synthetic R workflows**](flagship-workflows.html)

Each workflow is a complete example from an explicit scientific research question through generated input, model, numerical checks, figures and method-specific caveats. It uses the exact **published v0.4.3 native R API**, and the package's source-controlled scripts are executed in CI across Ubuntu, macOS and Windows.

**The data in all four examples are synthetic, not human eye-tracking observations.** The workflow figures are generated in R and published alongside full source code, CSV results, reproducibility notes and session manifests.

1. [**Complete gaze-trajectory analysis**](flagship-workflows.html#dense) constructs aligned two-channel trajectories, computes weighted L² distances and performs descriptive MFPCA with reconstruction.
2. [**Multilevel functional variation**](flagship-workflows.html#multilevel) decomposes repeated functional measurements into descriptive participant-mean and trial-residual strata. It does not assert mixed-model inferential validity.
3. [**Sparse and irregular recovery**](flagship-workflows.html#sparse) assesses an optional fdapace-backed PACE estimator on simulated irregular observations against independent analytic truth.
4. [**Uncertainty-aware paired comparison**](flagship-workflows.html#uncertainty) performs participant-level paired trajectory contrasts and exploratory pointwise/simultaneous bootstrap mean bands.

Each script is downloadable directly from the workflow page. An associated vector PDF and a browser-compatible R-generated preview show the actual deterministic output rather than a stock illustration. The scripts do not use the Python backend, do not fetch human observations, and do not claim validated nominal inference outside the demonstrated simulation scenarios.

For further reading, [explore the complete Methods Atlas](methods-atlas.html), [the Plot Atlas](plot-atlas.html), [the research navigation portal](research-portal.html) and [the scientific validation report](SITE_VALIDATION.html). The architecture is detailed in the project [scientific tiers and flagship protocol](https://github.com/stefanosbalaskas/eyetrajectories/blob/main/docs/SCIENTIFIC_TIERS_AND_FLAGSHIP_WORKFLOWS.md).
