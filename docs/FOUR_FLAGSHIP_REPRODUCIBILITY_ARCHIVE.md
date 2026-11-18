# Four executed native-R flagship studies: reproducibility archive protocol

**As of 18 November 2026 — qualification workflow, not a stable release.** Published API: exact `eyetrajectories` tag `v0.4.3` at commit `20e6db830d480b55456c2acf85e5fdb12cfa398f`.

This evidence bundle is a **methods-demonstration reproducibility supplement**, not an independent real-gaze data validation or a software version released on CRAN/Zenodo. The R example scripts are from the later research-development source, deliberately executed using the older **published v0.4.3 installed API**. Stable source archives and original datasets are never modified.

## Archive production contract

A dedicated GitHub Actions workflow `.github/workflows/four-flagships-reproducibility-bundle.yml`:

1. Checks out two source revisions independently: current research implementation and immutable v0.4.3 package.
2. Installs native R dependencies and optional `fdapace`, with no Python model import.
3. Executes each of four versioned R scripts, including their numerical assertions and figure generation.
4. Packages the **generated** CSV tables, 12 actual vector PDF figures, methods-and-limitations reports, and R session manifests.
5. Bundles complete R source scripts, frozen package metadata/`NAMESPACE`, curated scientific evidence records and the existing versioned qualification documentation.
6. Writes `SHA256_MANIFEST.json` listing every included file, exact byte size and SHA-256 checksum, plus a single ZIP SHA-256.
7. Reopens the ZIP independently, validates all internal hashes and fails closed on missing outputs, invalid PDFs, absent synthetic-data disclosures or an unexpected package version.

The resulting GitHub Actions artifact is intended for a separate immutable public research deposit after scientific review, not automatically published to Zenodo or CRAN.

## Four research tasks and their inferential limits

| Task | Research object | Output focus | What is NOT established |
| --- | --- | --- | --- |
| 01 Dense gaze trajectories | 24 simulated participants × 2 conditions, 61-point paired x/y trajectories | L² matrix, two-component MFPCA, FPCA scores/reconstruction, three figures | No real gaze calibration, inferential condition effect, or acquisition time |
| 02 Repeated trials | 30 simulated participants × 4 trials, 61 points | Descriptive two-stratum functional decomposition | Not a REML mixed model or population covariance inference |
| 03 Irregular sparse curves | 80 synthetic curves, 7–12 measurements per curve | `fdapace` conditional-expectation sparse PACE against analytic known truth | Not independent PACE implementation, general missing-data robustness or coverage |
| 04 Paired uncertainty | 32 synthetic participants × 3 trials per condition, 51 points | Participant-average functional contrast and exploratory simultaneous/pointwise bootstrap bands | Not general 95% calibration, p-values under all designs or a causal test |

The example programs deliberately use no imported user or human observation data. Their R filenames, generated plots, source checksums and output table paths are fixed; statistical values themselves are derived at execution, never fabricated in this documentation.

## Evidence classification

This archive offers **reproducible functionality**, **known-truth synthetic recovery examples** and **transparent statistical scope**. It does not confer independent statistical certification across 904 exported interfaces.

Examples of separate substantive validation evidence:

- OneStop: bounded real fixation-level numerical tests and source-function performance benchmark; the optimized implementation still requires exact-candidate full package checks.
- PoTeC: 404,418/404,420 corrected fixation records uniquely paired to their original index; two ambiguous corrected rows remain explicitly unresolved.
- Bootstrap: separate calibration simulations found 96% simultaneous coverage for complete data and 90–92% under three missingness processes in their bounded configurations. Single flagship 04 is a demonstration, not a replicated coverage study.

The scientific method registry conservatively records **41 curated method profiles** and **863 provisional records** based on the complete published 904-export NAMESPACE. The registry schema distinguishes tier, execution backend and evidence status.

## Archive usability

Once the qualification workflow has succeeded, retrieve the single generated Actions artifact and inspect:

- `README.md` and `SHA256_MANIFEST.json` for scope, provenance and integrity.
- `published-package/` for the pinned v0.4.3 package identifiers.
- `method-registry/` for backend and evidence classification.
- `examples/01-dense`, `02-multilevel`, `03-sparse`, `04-uncertainty` for executable R scripts, figures, CSVs and methodological notes.

To regenerate outputs on another computer, install exact v0.4.3 and `fdapace` for example 03, set `ET_FLAGSHIP_OUTPUT` and execute each script from the versioned research checkout. Numerical results can vary slightly by R, BLAS and dependency versions. The manifest certifies the **produced artifact**, not bit-for-bit identical results on every operating system.

## Release and publication boundary

- **Allowed after passing bundle CI:** make workflow source, PDF figures and sanitized synthetic results available as a reproducibility example; report exact source version and CI run.
- **Not allowed solely because bundle CI passed:** assert that all 904 interfaces have independent method certification, claim causal effects from descriptive FPCA, label all bootstrap bands calibrated at 95%, or present PoTeC source reconciliation as raw eye-tracker calibration.
- **Stable version:** remain v0.4.3 until the separate optimized L² candidate passes real-data installed-performance and full release checks. No automatic CRAN submission or Zenodo upload occurs in this workflow.

**Acceptance target:** 4/4 executed synthetic R examples, 12/12 valid generated PDF figures, required source/CSV/notes manifests, unambiguous package version, and zero internal ZIP SHA-256 mismatches.
