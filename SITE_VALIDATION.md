# Scientific validation and limitations

**Version 0.4.3 is a stable GitHub software release, while advanced scientific methods remain experimental.** A successful GitHub Actions check establishes that the tested code passed the specified job on a specified revision and environment. It does not independently certify every method or validate general scientific inference.

## Interpret the evidence correctly

| Evidence category | What it establishes | What it does not establish |
| --- | --- | --- |
| Documentation / public export | A declared callable, argument or help topic exists | Correct numerics or stable inference |
| Unit and regression tests | Specific tested inputs meet the asserted expectations | Behavior on untested data or domains |
| R CMD check | Package structure, code and examples meet the executed R checks | Complete scientific validity or CRAN acceptance |
| Python bridge test | Selected bridge operations and source checks execute | Native R algorithm parity for every function |
| Source-contract audit | Selected output/input behavior is compared against a frozen backend | General calibration or independent approval |
| Independent scientific certification | Reviewed domain-specific evidence and explicit sign-off for named contracts | Automatic certification of unrelated functions |

## Provisional 508-export work

The internal 508-export development ledger is *provisional author-side evidence*. The November 2026 qualification runbook explicitly records **0 independently certified full Python contracts**. A source-gap closure or a passing smoke workflow must not be relabelled as full independent parity.

See the [original qualification runbook](https://github.com/stefanosbalaskas/eyetrajectories/blob/fix/package-wide-qualification-20261113/docs/QUALIFICATION_RUNBOOK_20261113.md) and [experimental release scope](https://github.com/stefanosbalaskas/eyetrajectories/blob/fix/package-wide-qualification-20261113/docs/experimental-release-scope.md).

## Stable GitHub release 0.4.3 and scientific qualification

The exact 0.4.3 archive passed [six cross-platform package qualification jobs](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/43862845556). The maintainer's additional local Windows `R CMD check --as-cran` recorded zero errors, zero warnings, and one `New submission` NOTE.

The published Python package and the development R package have distinct release histories. The stable R package release on GitHub is **not yet a CRAN publication**.

## Measured real-data software performance (17 November 2026)

The R-only OneStop repeated-reading fixation-level benchmark of the `etr_pairwise_l2()` optimization passed all 21 declared numerical checks in both original and optimized runs. Six cases with 250/500/1,000 trajectories and 64/128 interpolated normalized-time points showed 104.6×–214.9× observed L² speedups. At 1,000 curves and 128 points, the original 31.91-second median fell to 0.305 seconds. These are author-side measurements on specified hardware and data, not an independently replicated general benchmark. The source code and exact-head CI qualification are documented in [merged PR #191](https://github.com/stefanosbalaskas/eyetrajectories/pull/191).

The optimized source was developed *after* the v0.4.3 archive was frozen. The archived release and DOI are unchanged. The benchmark used real fixations interpolated to standardized comparison grids, **not raw 1,000 Hz gaze samples**, and excluded preprocessing time. The validation did not measure process peak RSS, inference calibration or performance against competing implementations.

[Read the technical benchmark article](SITE_PERFORMANCE.html).

## Reproducible reporting checklist

For substantive methods, record: input schema, sample/time units, preprocessing, estimand, estimation backend, software commit and versions, uncertainty construction, participant/trial clustering, simulation or external validation, and known limits. Report negative or incomplete validation findings rather than silently broadening claims.
