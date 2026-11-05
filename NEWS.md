# eyetrajectories 0.4.1.9000 (development, unreleased)

## Native scientific integration

- Source-pinned native R field-schema records for 28 frozen Python 1.2
  public workflow dataclasses (303 declared fields). This is a
  data-representation layer, not proof of dataclass behavioral equivalence.
- Executable source-field configurations for native common-grid FPCA,
  function-on-scalar regression and fixed-radius recurrence/RQA.
- Native fixed-radius recurrence, cross-recurrence, W4 workflow and
  recurrence radius profiles use explicit L1/cityblock, L2/euclidean,
  and L-infinity/chebyshev distance metrics.
- New Python 1.2 source-compatible time-unit resolver for seconds,
  milliseconds and aliases on approximately regular observed time grids,
  without smoothing, interpolation, imputation or implicit resampling.
- Time-unit resolution now serves native multichannel delay embedding,
  W4 recurrence/RQA, Rosenstein and Kantz divergence, fixed-radius
  recurrence-radius profiles, sliding-window RQA and derived functional
  RQA trajectories. Nonintegral lag or window conversions fail explicitly.
- R recurrence workflow records three measured native scientific operations,
  with 11 source-aligned result fields. Python timings and result-class
  identity are NOT claimed.
- New developer direct frozen-Python numerical tests cover time-unit
  resolution, source metric geometry, 12 RQA estimands and explicit
  source boundary conditions.

## Packaging and release gates

- Added local Windows/WSL2/Docker qualification orchestration,
  SHA-checked evidence and isolated unverified 0.4.2 candidate staging.
  Use scripts/run_local_release_matrix.R and read
  docs/local-release-qualification.md; cross-platform tests still require
  the actual local environments and independent parity remains unsigned.


- Local experimental candidate gate:
  source("scripts/qualify_experimental_candidate.R").
  It executes the existing full R CMD check --as-cran plus native-smoke
  runner and the exact-head native/pinned Python scientific qualification.
- Experimental release scope is documented separately from full Python 1.2
  parity claims in docs/experimental-release-scope.md.
- GitHub Actions runner admission in the private repository is an unresolved
  external dependency (issue #3). No hosted matrix has been certified green.
- Current development version is NOT a ready-to-publish tag. This branch
  is draft, and no GitHub release or CRAN upload has been performed.

## Scientific qualification boundaries

A passing author-side scientific suite confirms the specific tested
estimands/domains. It does not establish complete source compatibility
for every export or independent full-domain review. Known source
contracts, scientific backend differences and reviewer decision state
remain explicit and unwaived. No independent sign-off is fabricated.
