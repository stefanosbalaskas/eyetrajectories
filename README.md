# eyetrajectories

**Functional analysis of time-indexed eye-tracking trajectories in R**

**v0.4.4 — qualified source release of the native L² optimization.** Scientific software remains under active development; publication on GitHub and acceptance by CRAN are separate events. The release is not a claim of independently certified numerical parity across the full R/Python interface.

## Scope

The package contains **native, Python-free R methods** for trajectory structures and explicit preprocessing, kinematics, distances, dense common-grid functional PCA and multivariate PCA, recurrence analysis and visualization. Additional methods for sparse functional observations, multilevel decomposition, functional regression, uncertainty assessment and nonlinear analysis are experimental and have method-specific assumptions.

An **optional Python 1.2 bridge** through `reticulate` exposes selected functions from the separately published `eyetrajectoriespy` package. Loading `eyetrajectories` does **not** require a Python installation. Python wrappers, source-API mapping and author-tested R code should not be interpreted as exact native R implementations of all Python algorithms.

## Install the exact source revision

For testing the isolated 0.4.4 source, the release branch can be installed as follows. Its branch name is mutable; for reproducibility, pin `ref` to the full exact commit SHA listed with the final GitHub release:

```r
install.packages("remotes")
remotes::install_github(
  "stefanosbalaskas/eyetrajectories",
  ref = "release/0.4.4-l2-qualification-base",
  dependencies = NA
)
library(eyetrajectories)
packageVersion("eyetrajectories")
```

Installing from GitHub requires relevant R build tools and optional packages for the methods you choose. Use `install.packages("eyetrajectories")` only after CRAN has published the package.

## Native R: reproducible synthetic example

```r
library(eyetrajectories)

synthetic <- etr_simulate_hierarchical(
  n_subjects = 20L,
  trials_per_subject = 3L,
  n_time = 41L,
  seed = 2501L
)
fit <- etr_fit_multilevel_fpca(
  synthetic$trajectories,
  synthetic$participant,
  n_between = 2L,
  n_within = 2L
)
etr_multilevel_variance(fit)
```

This is **synthetic demonstration data**, not human observations, and the output is descriptive. Assess method-specific numerical assumptions and sampling units before drawing inferential conclusions. Review the individual function documentation with `help(package = "eyetrajectories")`.

## Scientific assurance: what we do and do not claim

A frozen Python 1.2 public-export ledger covers **508 names**, but this is a **provisional author-side source-contract inventory**, not 508 independent scientific certifications. The development qualification documentation records **0 independently certified full Python contracts**. Author-side unit tests and differential checks provide evidence only for their stated inputs and constraints.

The CRAN-style source checks test packaging, examples and included tests. Passing them does **not** independently certify estimator equivalence, calibration of bootstrap confidence bands, causal inference from transfer entropy, or generalization to untested acquisition and sampling designs.

## Reproduce qualification

v0.4.4 descends from the frozen v0.4.3 baseline via [PR #211](https://github.com/stefanosbalaskas/eyetrajectories/pull/211) and the [merged v0.4.4 qualification PR #220](https://github.com/stefanosbalaskas/eyetrajectories/pull/220). All 12 exact-candidate CI jobs passed. Consult the [publication checklist](https://github.com/stefanosbalaskas/eyetrajectories/issues/221) for final release-source provenance, separate CRAN status and the precise limitations of the OneStop benchmark. The following links describe earlier scientific assurance and scope.

- [Scientific versus source parity](https://github.com/stefanosbalaskas/eyetrajectories/blob/release/eyetrajectories-0.4.2-rc1-20261116/docs/SCIENTIFIC_VS_SOURCE_PARITY.md)
- [Experimental R release scope](https://github.com/stefanosbalaskas/eyetrajectories/blob/release/eyetrajectories-0.4.2-rc1-20261116/docs/experimental-release-scope.md)
- [Release qualification runbook](https://github.com/stefanosbalaskas/eyetrajectories/blob/release/eyetrajectories-0.4.2-rc1-20261116/docs/QUALIFICATION_RUNBOOK_20261113.md)
- [GitHub Actions](https://github.com/stefanosbalaskas/eyetrajectories/actions)
- [Issue tracker](https://github.com/stefanosbalaskas/eyetrajectories/issues)

The complete prior development README remains available in Git history; this release-candidate README focuses on the supported user-facing scope. The deployed scientific website and development-methods atlas have a separate lifecycle; they are not evidence of release-candidate numerical qualification.

## License

MIT. See the [LICENSE](LICENSE) file.
