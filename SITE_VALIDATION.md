# Scientific validation and limitations

**The package is under active research development.** A successful GitHub Actions check establishes that the tested code passed the specified job on a specified revision and environment. It does not independently certify every method or validate general scientific inference.

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

## Current CI and release decisions

Review the [live Actions runs](https://github.com/stefanosbalaskas/eyetrajectories/actions), their **exact commit SHA**, test logs and notes before describing an environment as qualified. This website prototype does not dynamically assert that any future CI result or CRAN submission has passed.

The published Python package and the development R package have distinct release histories. The R development package should not be called CRAN-published until an actual CRAN release is verified.

## Reproducible reporting checklist

For substantive methods, record: input schema, sample/time units, preprocessing, estimand, estimation backend, software commit and versions, uncertainty construction, participant/trial clustering, simulation or external validation, and known limits. Report negative or incomplete validation findings rather than silently broadening claims.
