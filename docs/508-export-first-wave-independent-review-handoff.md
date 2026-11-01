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
