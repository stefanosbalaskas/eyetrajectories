# v0.4.3-derived L² optimization candidate — NOT an accepted release

**Initiated:** 18 November 2026. **Candidate version:** 0.4.3.9000 (development), not a published 0.4.4 release.

## Why this is a separate release branch

The public stable tag `v0.4.3` points to commit `20e6db830d480b55456c2acf85e5fdb12cfa398f` and contains a materially different package DESCRIPTION, import set, and public R API from development `main` (0.4.0.9000). The two histories have diverged. Promoting or retagging `main` as 0.4.4 would risk substantial unreviewed regressions. This release candidate starts from the immutable v0.4.3 commit, preserving its existing functions and documentation.

## Change under qualification

- The archived `etr_pairwise_l2(x, dimension_weights=NULL, python_boundary_mode=FALSE)` interface **remains unchanged**.
- Default strict native-R distance is computed by centered, time/channel-weighted matrix rows and `stats::dist` on the same complete trajectory collection.
- Source/compatibility mode `python_boundary_mode=TRUE` **always retains original scalar loops**, preserving documented Python 1.2 coercion and nonfinite behavior instead of silently forcing strict mode.
- Unstable numeric scaling falls back to the exact original scalar implementation.
- One-trajectory calls preserve legacy behavior even when optional dimension weights would be invalid for a multi-curve collection.

## Already supported empirical evidence — limited scope

A separate same-input real-OneStop benchmark (Windows, installed v0.4.3 scalar source versus pinned optimized **development source function** with shared numerical helpers) reported median speedups of 98.5–219.6× and maximum distance discrepancies of 1.14e-12, on 250–1000 curves and 64/128 interpolated grid points. This supports the **algorithmic approach**, not this newly ported 0.4.3-preserving package build. See [scientific audit on main](https://github.com/stefanosbalaskas/eyetrajectories/blob/main/docs/POTEC_REAL_SOURCE_AND_L2_RESULTS_20261118.md).

The candidate's own full CRAN-style checks, package archive validation, external installation and matched real-OneStop benchmark are **NOT YET COMPLETE**. No stable release, tag or Zenodo record should be created before those gates finish.

## Release gates and acceptance

1. **Source baseline check:** exact v0.4.3 ancestry and preserved package metadata, except deliberate development version.
2. **Three-OS focused CI:** new tests compare the optimized output with the archived scalar `etr_l2_distance` mathematical oracle across irregular grid, 3 channels, missing/negative weights, zero weights, large common offset, singleton, and unchanged `python_boundary_mode=TRUE` behavior.
3. **Broader regressions:** run original archived distance/core/source-option tests and R CMD check, including platform-specific optional dependencies; document any warnings, skips and NOTE(s).
4. **Real-data candidate measurement:** install this branch into an isolated R library, rerun paired OneStop scaling with exact source hash and record independent numerical reference errors and peak process RSS.
5. **Publication:** only after 1–4 pass, finalize DESCRIPTION to a version agreed for release (such as 0.4.4), rebuild the source tarball, verify checksum and release metadata, and create tag/Zenodo deposit. Do not replace the immutable v0.4.3 archive.

### CI

`.github/workflows/rc-043-l2-qualification.yml` uses a release-base PR and explicit Windows, macOS and Linux test jobs. The CI tests **synthetic** numerical contracts, not human raw gaze data.

No original PoTeC/OneStop data, stable tag, archived tarball or Zenodo DOI is changed by this candidate.
