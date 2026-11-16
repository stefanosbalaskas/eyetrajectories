# Scientific validation and limitations

**Version 0.4.2 is a stable GitHub software release, while advanced scientific methods remain experimental.** A successful GitHub Actions check establishes that the tested code passed the specified job on a specified revision and environment. It does not independently certify every method or validate general scientific inference.

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

## Stable GitHub release 0.4.2 and scientific qualification

The exact 0.4.2 archive passed [five cross-platform package qualification jobs](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/43780072928). The maintainer's additional local Windows `R CMD check --as-cran` recorded zero errors, zero warnings, and one `New submission` NOTE.

The published Python package and the development R package have distinct release histories. The stable R package release on GitHub is **not yet a CRAN publication**.

## Reproducible reporting checklist

For substantive methods, record: input schema, sample/time units, preprocessing, estimand, estimation backend, software commit and versions, uncertainty construction, participant/trial clustering, simulation or external validation, and known limits. Report negative or incomplete validation findings rather than silently broadening claims.
