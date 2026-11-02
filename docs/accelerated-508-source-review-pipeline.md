# Accelerated, evidence-backed 508-export review triage

This workflow separates four concepts that must never be conflated:

1. **Found in the native package**: 380 callable R candidates are identified.
2. **Source reference present**: an authored test file contains a frozen Python export reference; this is **not** necessarily an individually verified numerical test.
3. **Developer evidence ready for review**: six explicitly recorded checks are supported by an existing evidence file whose SHA256 was verified. This is **not** independent scientific certification.
4. **Independent full-domain certification**: the external reviewer independently replays the contract and documents a signed decision, followed by separate human adjudication. **Currently zero**.

The frozen Python source commit is
`c1cd95ad718327550f7e55393ff38582872f7a94`.
The R source commit must be taken independently from your own Git checkout,
not copied from an untrusted evidence CSV.

## Routine capture: one RStudio command

After `git pull --ff-only`, from the repository root:

```r
source("scripts/capture_native_source_qualification_evidence.R")
```

The existing procedure runs native-R and pinned-Python qualification, builds
the 508-export unsigned reviewer packet and 15 waves, verifies author-side
integrity, and **then** runs:

```text
scripts/reconcile_508_contract_progress.py
```

The new step writes, under the same
`artifacts/native_independent_review_packets/qualification_YYYYMMDDTHHMMSS/`
directory, a new `developer_reconciliation_<R_SHA_PREFIX>/` with:

- `contract_progress_508.csv`: one row for each immutable export.
- `reviewer_priority_508.csv`: source-gap- and evidence-aware order.
- `reviewer_dispatch_28.csv`: a compact, source-pinned 28-item external
  reviewer intake sheet in three separate lanes: four **known-gap pilots**
  for adversarial source replay, 12 functions without a recorded source gap
  (not yet verified as fully equivalent), and 12 nonfunction representation
  candidates. The source-pinned dispatch includes its own SHA256 manifest
  entry. All 28 rows have FALSE replay, approval, and certification flags.
- `developer_evidence_UNSIGNED_TEMPLATE.csv`: 508 unsigned, all-FALSE
  rows to copy and populate with individually reviewed developer evidence.
- `developer_progress_summary.json`: counts for historical source gaps,
  source-fixture candidates, SHA256-verified developer files, and review readiness.
- `developer_progress_sha256.json`: checksums of these outputs.

On a successful full qualification, the reconciler additionally imports the
existing ten numerical comparisons from
`four_pilot_developer_paired_numeric_replay.csv` as **four partial developer
evidence records**. Each receives only the numerical-oracle check, not the
other five gates. Thus the expected initial dashboard is four SHA256-verified
partial developer records, zero complete six-gate developer reviews, **zero
closed source gaps**, and **zero independent approvals**. The four pilot
source-gap entries remain open.

The dispatch is a **proposed independent reviewer assignment**, not a
certification fastlane. A known-gap pilot cannot be fully certified before
its documented source differences are scientifically resolved. A function
without a *recorded* gap still requires complete accepted-domain, numerical,
schema, error and estimand review. Nonfunction representation is not inferred
from a similarly named R constructor.

The original 508 queue, source-gap registry, external-review worksheets,
GPG receipts and authoritative certification ledger are **not modified**.
The historical 203 callable + 1 nonfunction source gaps stay open until a
separate explicit source-gap resolution review takes place.

## Record actual developer evidence

Copy the unsigned template to a new CSV outside its immutable output directory.
For **each contract that has really been verified**, provide all six check values
as TRUE or FALSE, detailed developer findings, an exact R/Python source pin,
and a real existing evidence-file path plus its SHA256:

```text
source_signature_checked
accepted_input_domain_checked
numerical_oracle_checked
boundary_and_exception_checked
result_schema_checked
scientific_estimand_checked
evidence_file
evidence_sha256
developer_findings
```

The six flags must represent actual, per-contract work. **A global test suite
PASS, a direct literal Python function reference, and an author's internal
checksum are not enough to set all flags TRUE.** In particular, a known
open source gap remains open even with six TRUE flags. The latter only means
the developer claims evidence *ready for gap re-evaluation*. Missing,
untrusted, duplicated, malformed or SHA-mismatched records are rejected.

To include a partially filled developer CSV in the *next* qualification run,
set the environment variable before sourcing the capture:

```r
Sys.setenv(ET_508_DEVELOPER_EVIDENCE_CSV =
  "C:/path/to/per_contract_developer_evidence.csv")
source("scripts/capture_native_source_qualification_evidence.R")
```

Because the protocol demands an exact R source pin, **evidence for a previous
commit cannot silently be reused for a new HEAD**. Re-run the reference tests
and produce or revalidate individually pinned evidence as appropriate.

Alternatively, reconcile an already qualified immutable packet directly:

```powershell
python scripts/reconcile_508_contract_progress.py "C:/path/to/qualification_PACKET" --expected-r-head FULL_40_CHAR_GIT_SHA --evidence-csv "C:/path/to/per_contract_developer_evidence.csv" --output-dir "C:/path/to/new_reconciliation_output"
```

This is useful when the code and immutable packet stay at a fixed source SHA:
no need to regenerate all other reviewer materials. Output directories are
never silently overwritten.

## Parallel scientific reviewer lanes

Use the prioritized CSV to assign disjoint exported contracts across
independent reviewers, each with its own signed findings and source-pinned
replay logs. The existing unsigned 508 review waves have 15 batches of at
most 36 exports and ten criteria per export. External reviewers use the
existing scripts:

```text
scripts/verify_508_external_attestation.py
scripts/verify_508_all_wave_attestation.py
```

Those read-only tools check submitted GPG signatures against an out-of-band
trusted fingerprint. Cryptographic verification proves file/signer integrity
within that trust arrangement, **not** scientific correctness, reviewer
independence, or final certification. Human scientific adjudication is still
required. No script can authentically act as an independent reviewer for
evidence that the same implementation team created.

## Regression testing

```powershell
python -m unittest discover -s tests -p test_reconcile_508_contract_progress.py -v
```

These synthetic tests protect against mismatched SHA256, wrong source commits,
duplicate/unknown records, forged review flags, and accidental promotion of
developer status to scientific approval.

**No numbered development batch, successful suite or automatically generated
status should increase the independently certified counter.**
