# Scientific Methods Atlas — all 904 exported R interfaces

[**Open the searchable scientific Methods Atlas**](methods-atlas.html)

The registry is constructed directly from the **immutable eyetrajectories v0.4.3 NAMESPACE** at website-build time. All 904 exported R names are included and validated by the build. Each interface has a proposed scientific tier, explicit execution backend, caveat and a method-specific evidence status.

**A scientific tier is not a scientific certificate.** Tier 1 (core) identifies methods intended as stable foundations; Tier 2 (advanced) identifies statistical modeling and uncertainty tools; Tier 3 (experimental/specialized) includes methods requiring more selective interpretation and optional bridges. The tier of a previously unreviewed interface is marked as provisional, not independently assessed. Only 41 method records have been individually curated to date; remaining records retain clear provisional status. An exported wrapper does not establish a new or independently validated estimator.

Backend status is also distinct: native R, R delegated to optional fdapace/refund packages, Python integration via reticulate, or a hybrid interface requiring source review. Use the [Research Workflow Portal](research-portal.html) for design-based navigation, [Four Flagship Workflows](flagship-workflows.html) for executable native R examples and [Plot Atlas](plot-atlas.html) for actual R-rendered plots.

The machine-readable JSON and CSV registry can be inspected or downloaded at [method-registry-v0.4.3.json](method-registry-v0.4.3.json) and [method-registry-v0.4.3.csv](method-registry-v0.4.3.csv). The [registry coverage manifest](methods-atlas-manifest.json) reports curated and provisional counts and the distribution of backend classifications.

The curated evidence source and implementation are maintained in [inst/method-registry/curated-evidence.json](https://github.com/stefanosbalaskas/eyetrajectories/blob/main/inst/method-registry/curated-evidence.json) and [the generator](https://github.com/stefanosbalaskas/eyetrajectories/blob/main/scripts/generate_scientific_method_registry.py).

**Data ethics:** No browser-local eye-tracking data is uploaded or processed by the Methods Atlas. It is a static method catalogue, not a model-selection service or inferential analysis engine.
