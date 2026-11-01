# First-wave independent Python 1.2 → native R certification handoff

**This is an author-generated private review packet, not an independent scientific approval.**

Frozen Python source: c1cd95ad718327550f7e55393ff38582872f7a94. The captured native R SHA must come from an independently verified GitHub commit.

## Automatically prepared after successful two-mode RStudio qualification

The qualification runner now executes two source suites (native R and pinned Python 1.2) and the synthetic Python reviewer-packet integrity tests. It creates the original 508-export inventory, 203-gap review queue, four pilot comparisons and external-review packet. It additionally creates in the NEW packet directory:

- certification_508_prioritized_work_queue.csv — all 508 exports, known source gaps, alternate estimands and current approval gates.
- certification_first_function_and_nonfunction_batches.csv — 24 functions and 12 nonfunctions without RECORDED source differences. This is a prioritization hint, not a scientific equivalence claim.
- certification_first_batch_reviewer_checklist.csv — 10 independent-review criteria per export (360 total), all initially FALSE and unsigned.
- certification_first_batch_UNSIGNED_decisions.csv — 36 decisions, all PENDING_INDEPENDENT_REVIEW and with no reviewer identity.
- certification_first_batch_sha256_manifest.csv — SHA256 hashes of the four new files and exact Git/Python pins.
- python_unsigned_review_packet_tooling_tests.txt — first-party integrity-test transcript in the qualification evidence directory.

A green aggregate test suite or no-known-gap label is NOT proof of complete contract coverage, independent scientific parity, source-error equivalence, reviewer identity or approval.

## Owner — exact-head commands in RStudio

After pulling the new research branch:

~~~r
system("git pull --ff-only")
head <- system("git rev-parse HEAD", intern=TRUE)
stopifnot(length(head)==1L,grepl("^[a-f0-9]{40}$",head))
source("scripts/capture_native_source_qualification_evidence.R")
~~~

Use the newly generated qualification_YYYYMMDDTHHMMSS directory, not an old packet. Then verify real packet bytes (this verification remains author-side):

~~~r
py <- reticulate::py_config()$python
packet <- "artifacts/native_independent_review_packets/NEW_PACKET"
status <- system2(py,args=c(
  "scripts/verify_508_certification_batch.py",shQuote(packet),
  "--expected-r-head",head))
stopifnot(status==0L)
~~~

## Independent reviewer — actual scientific reproduction

A qualified third party who has not authored the implementation or its tests must obtain private access to the exact frozen Python and native R sources. The reviewer must design and execute additional verification, not merely rerun author tests. Each of the 36 exports needs:

1. Source signatures, default arguments, accepted input values, coercions and container types.
2. Numerical accuracy and randomized/analytic known-truth tests where appropriate.
3. Empty, missing, infinite and extreme numeric cases; warnings, exceptions and side effects.
4. Array rank, dtype, metadata and return-schema compatibility.
5. Reproduction of the same scientific estimand and backend semantics.
6. Independently recorded commands, logs, environment, source hashes, case evidence and per-export judgment.
7. A separately authenticated identity and detached signature with fingerprint verified through an independent channel.

Reviewer decisions should distinguish RESTRICTED_SUBSET_MATCH, NOT_EQUIVALENT and FULL_SOURCE_PARITY. The new 36-row CSV is only a BLANK template, not a signed or accepted review. The existing external GPG checking implementation applies only to the original four pilots; signed adjudication for other exports still requires separately implemented and independently verified registry ingestion.

## Promotion gates / remaining scientific work

The frozen API consists of 380 functions and 128 nonfunction exports. All 380 callable names are mapped but this is not a complete behavior or scientific certificate. Existing source gap records (203) and backend distinctions (19) must be resolved individually or explicitly accepted as restricted/non-equivalent.

The authoritative pilot function register is inst/extdata/native_contract_certification_pilots_v1.csv; the nonfunction register is inst/extdata/native_nonfunction_contract_review_v1.csv. The batch tools NEVER edit these registers or set any approval flags. They also do not introduce approval rows for the remaining functions without signed evidence. A fully reviewed, gap-resolved contract requires maintainer-controlled evidence and explicit source-pinned full-domain approval before it can count.

A cryptographic signature only authenticates the signed bytes and signing key; it cannot itself establish scientific truth, reviewer independence, or full-domain equality. No developer-generated signature can substitute for a real external independent reviewer.

The full 508-export certification gate remains fail-closed. A restricted-subset verdict never increments the full-domain numerator (currently 0/508). Draft PR #48 and independent-review issue #34 remain open.


## Signed receipt for a REAL reviewer (not a self-signoff)

The new read-only scripts/verify_508_external_attestation.py validates signed
decisions for one to 36 exports in the first batch. The independent reviewer
makes COPY files of both certification_first_batch_reviewer_checklist.csv
and certification_first_batch_UNSIGNED_decisions.csv, completing ten
case rows for each selected decision. Every case must have independently
replayed/reviewed=TRUE and actual reviewer-generated evidence and findings.
FULL_SOURCE_PARITY additionally requires all ten scope criteria and the
complete independent reviewer gates to pass. Restricted/negative scientific
findings are valid review outcomes but never full-domain approvals.

The reviewer signs BOTH completed CSV files, for example:

~~~bash
gpg --armor --detach-sign --output completed_cases.csv.asc completed_cases.csv
gpg --armor --detach-sign --output completed_decisions.csv.asc completed_decisions.csv
~~~

The maintainer must obtain and verify the complete GPG signer fingerprint
from an OUT-OF-BAND source independent of the CSVs, then invoke:

~~~bash
python scripts/verify_508_external_attestation.py PACKET_DIR \
  completed_cases.csv completed_decisions.csv \
  completed_cases.csv.asc completed_decisions.csv.asc \
  --expected-r-head FULL_TRUSTED_40_HEX_R_SHA \
  --trusted-fingerprint FULL_OUT_OF_BAND_GPG_FINGERPRINT
~~~

The verifier checks the unchanged unsigned author packet, all source
identifiers, ten independent cases per reviewed export, written findings,
reviewer-supplied declarations, two valid detached GPG signatures and the
out-of-band fingerprint. Signature acceptance does NOT prove that the signer
is professionally independent or that their judgments are scientifically
correct. The verifier **never writes** to any authorititative registry or
increments the 508 numerator. An actual maintainer/reviewer adjudication
of source-domain equivalence is separately required.

Synthetic author-only unit tests for cryptographic receipt structure mock
signature verification; they do NOT create or impersonate independent
reviewers. Actual GPG cryptography is exercised only when a real reviewer
submits signed documents and a separately trusted fingerprint.


## Additional first-wave source-interface evidence and real-packet gates

On exact-head qualification, the runner now records the FIRST-PARTY
observed interface inventory for all 36 first-wave exports:

- first_wave_source_interface_inventory.csv: frozen Python 1.2
  function signatures or nonfunction Python object classes, native R
  exported formals, source-lookup and introspection errors, native body
  hashes, immutable Python/R commits, and explicit FALSE flags for
  independent review and full-source certification.
- first_wave_source_interface_inventory_sha256.csv: author-generated
  SHA256 checksum and exact source pins.

Source-code signatures and function bodies are DESCRIPTIVE compatibility
evidence; they cannot prove numerical or scientific equivalence. Missing
source interface information is explicitly recorded rather than silently
converted into a PASS or a certification.

Following the two successful scientific source test suites, the actual
newly generated packet is verified by both read-only Python commands,
using the separately recorded R commit:

~~~bash
python scripts/verify_four_pilot_review_bundle.py PACKET_DIR --expected-r-head FULL_TRUSTED_R_SHA
python scripts/verify_508_certification_batch.py PACKET_DIR --expected-r-head FULL_TRUSTED_R_SHA
~~~

The 508 verifier additionally validates the descriptive interface file
when present, including the required SHA256 sidecar, 36 exact export
identities, frozen Python source, unchanged R commit, and FALSE approval
flags. The qualification runner prints the actual verifier results and
writes separate *_AUTHOR_INTEGRITY_CHECK.txt logs under the packet.
A failure stops the capture rather than silently allowing a tampered
or mismatched reviewer worklist.

Neither SHA256 verification, Python introspection nor developer-generated
boundary cases constitute an external independent scientific replay. The
current full-domain certified count must remain 0/508 until an actually
independent, qualified reviewer has submitted and defended source-specific
scientific findings and the relevant source gaps and registry approvals
have been legitimately adjudicated.

## First-wave namespace and native representation audit (2026-11-01)

The owner-qualified `qualification_20261101T213648` at R SHA
`89d465c495675daea44e0d46602ed1eb5b1a0ac1` passed both
source qualification modes and both actual packet SHA256 verifiers.
The first-wave inventory nevertheless reported 33/36 Python export
lookups and 24/24 native R functions observed.

Repository source inspection identified a specific capture bug:
`etpy_get_export(name)` defaults to Python namespace `root`.
Three selected exported classes belong to the `workflows` namespace:
`PreprocessingPlan`, `FPCAWorkflowConfig`, `FPCAWorkflowResult`.
The source-interface capture now explicitly uses each catalogued
namespace. A pinned-Python regression exercises all three classes.
Any still-unresolvable Python export stops the capture after preserving
its descriptive source-inspection CSV for diagnosis.

Also important: all 128 currently catalogued Python nonfunctions have
an EMPTY native-representation field in the authoritative
`inst/extdata/native_nonfunction_contract_review_v1.csv` register.
Successful Python class imports do not constitute a native R
representation or a full-domain semantic certificate.
The new first-wave interface inventory reports the actual native
nonfunction representation, a first review blocker and the next
scientific action for each of the 36 exports. An absent R-side class
or object is explicitly classified
`NATIVE_R_NONFUNCTION_REPRESENTATION_MISSING`.
The source-inventory integrity checker now verifies these reasons
against observed Python lookup and native candidate presence rather
than accepting an unsupported descriptive summary.

After owner exact-head replay, the expected observation is 36/36
Python exports found, 24 native R functions found, and 12 first-wave
nonfunction R representations still missing until separately
implemented and qualified. This is a PREDICTION until the new
commit runs in owner RStudio; no independent scientific approval
is inferred. Full-domain certifications remain 0/508.

## First native nonfunction candidate and explicit class gap

The source-backed native `TrajectorySet` candidate is now recorded as
`etr_trajectory_set` in the 128-entry nonfunction register, with all
scientific, schema, reviewer and numerical approval fields still FALSE.
All other nonfunction native representation fields remain blank.
This is **1/128 provisional object mappings, 0/128 class certifications**.

The frozen Python dataclass remains different from the native S3 object
on NaN/missing values, array coercion, zero-curve behavior, immutability,
Python indexing, pandas metadata and exception semantics. These differences
are explicitly tracked in `inst/extdata/native_nonfunction_source_gaps_v1.csv`
and [the source-specific TrajectorySet dossier](native-trajectoryset-frozen-python-contract.md).
The full-domain 508 catalog **fails closed** on this gap regardless of
provisional class mapping or any future author-generated test PASS.

The complete unsigned priority queue now reports 203 known callable
source differences and one separately registered nonfunction source
difference (204 total), with a one-row unsigned class resolution queue
`native_nonfunction_source_gap_resolution_queue.csv`.
The first no-known-gap reviewer batch excludes `TrajectorySet` until the
source differences have been scientifically addressed. All independent
source replay and certification flags remain FALSE.
