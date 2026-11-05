# Independently certifying the 508 frozen Python 1.2 export contracts

**Status as of 2026-11-01: 0/508 independently certified FULL-DOMAIN contracts.**

This number is deliberately stricter than the number of implemented native R
analogues, passing tests, passing developer numerical fixtures, or accepted
**restricted-subset** reviews. The Python frozen source of record is
`eyetrajectoriespy==1.2.0`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`. All reviews must also
identify a complete R commit SHA.

## What the denominator actually means

The exported Python inventory contains **380 functions** and **128
nonfunctions** (classes, constants/configurations and related exported
objects). The native function name mapping covers 380/380 names, but
name mapping is not evidence of complete functionality, full-domain behavior
or scientific equivalence.

Two authoritative certification sources feed
`etr_native_parity_catalog()`:

1. `inst/extdata/native_contract_certification_pilots_v1.csv`
   currently lists **four function pilots**, with independently approved
   numerical, boundary/schema, scientific and reviewer fields initially FALSE.
   Further function contracts require evidence-linked review entries and
   controlled expansion of the registry; mapping alone cannot update the count.
2. `inst/extdata/native_nonfunction_contract_review_v1.csv`
   holds **128 distinct nonfunction contracts**. These must be reviewed on
   their own native representation, value/schema, scientific scope, and
   independent external findings—not renamed as functions.

`etr_native_parity_catalog(require_complete=TRUE)` **must fail closed**
until every one of the 508 exports is fully approved. The separate readiness
report `etr_native_certification_readiness_frame()` identifies which exact
conditions are not yet satisfied for every export.

## First fix qualification, without pretending it is certification

The owner ran commit `270a1922553ce3dd912ba56aca7f5bba8c2770b1`.
The Python 1.2 comparison log at
`qualification_20261101T204024` contained one assertion failure:
the native `etr_trapezoid_weights` returns an ordinary R vector while
a converted NumPy one-dimensional array carries `dim=c(3L)`.
These were different **R container schemas**, not demonstrated unequal
numeric weights. The subsequent test fix compares numeric payloads and
explicitly preserves the schema difference as an uncured source-contract
issue. This fix requires owner replay at its new exact SHA; never relabel
the failing bundle as green.

After checking out the current research commit in RStudio:

```r
pkgload::load_all(".", quiet=TRUE)
readiness <- etr_native_certification_readiness_frame()
stopifnot(nrow(readiness)==508L)
print(sort(table(readiness$first_unresolved_requirement),
           decreasing=TRUE))
print(readiness[readiness$python_name %in% c(
  "alr_transform", "inverse_alr", "score_distance_matrix",
  "functional_trapezoid_weights"), ])
stopifnot(sum(readiness$fully_certified)==0L)
```

Save the full readiness CSV and source qualification records into a
commit-pinned evidence directory and include their file hashes.

## Evidence for each individual function contract

A reviewer must evaluate the original Python 1.2 implementation **and its
dependencies**, corresponding native R implementation, and an explicit
contract matrix. At minimum:

- Frozen source Git SHA, exact native R Git SHA, function name and namespace,
  native candidate, dependency versions/platform/seed, chosen scientific
  estimator, and input/output schemas.
- Accepted input family, ranges, shapes, missing and infinite values, scalar
  and array broadcasting, default parameters, zero/one-dimensional edges,
  nested containers, numerical strings, logical inputs and invalid inputs.
- Return rank, storage/type/dtype, element order, metadata/attributes,
  exception class/message/warnings, nonfinite/overflow behavior, tolerance
  rationale, determinism, and side effects.
- Analytic or independently implemented reference fixtures where possible,
  plus fixed and randomized/metamorphic comparisons, numerical precision
  stress tests, adversarial boundaries, and known-truth scientific recovery.
- All deviations documented and adjudicated. An opt-in R compatibility mode
  **does not prove that the default native R callable matches the Python
  callable's full domain or signature.**
- Independent reviewer-generated evidence with recorded command lines,
  outputs and hashes; conflicts and uncertainty in the scientific
  estimand must be resolved before a full-domain finding is possible.

The reviewer must perform original independent verification. Re-running
author-written tests alone cannot supply the independent scientific finding.
No finite suite mathematically proves total program equivalence; the
full-domain claim also needs source inspection and a carefully scoped,
defensible equivalence specification.

## Start with the four already packaged function pilots

- `alr_transform`: NaN/+Inf epsilon, simplex validation/coercion and
  clipping behavior; original native defaults reject nonfinite epsilon.
- `inverse_alr`: NaN/Inf input and direct exp overflow, return shape/type
  and normalization; original native default explicitly rejects overflow.
- `functional_trapezoid_weights`: monotone infinite grid endpoints,
  NumPy 1-D array versus ordinary R vector, truthy normalize objects and
  other accepted input containers.
- `score_distance_matrix`: duck-typed score-bearing inputs, score array
  rank/dtype, scikit-learn's Euclidean implementation, error behavior,
  nonfinite inputs and exceptional numerical magnitudes.

At the time this plan was written, three default-source behavioral
differences plus one shared nonfinite score rejection were captured. The
opt-in `python_boundary_mode` was introduced to support *restricted*
exception-domain comparisons without silently changing native scientific
defaults. These findings do **not** warrant changing any full-domain
approval boolean.

Use the existing review bundle in
`artifacts/native_independent_review_packets/qualification_*`, its SHA256
manifest, `four_pilot_EXTERNAL_REVIEW_TEMPLATE.csv`, and
`EXTERNAL_REVIEW_AND_SIGNATURE_INSTRUCTIONS.md`.

The standard-library first-party integrity checker is
`scripts/verify_four_pilot_review_bundle.py`. Its PASS attests only
file integrity and unsigned-state consistency; it does not authenticate
the author or establish scientific independence.

## What independent signoff actually requires

1. Assign a qualified reviewer **not responsible for developing the R port
   or its author-built comparison fixtures**. Provide limited private repo
   access and a separately verified expected R SHA. This repository is
   private: do not publicly post the full source or confidential evidence.
2. Reviewer checks out independently, executes direct-source and native
   replay, inspects boundaries and scientific scope, and provides independent
   logs and an individually reasoned verdict for **each** of the four pilots:
   `RESTRICTED_SUBSET_MATCH`, `NOT_EQUIVALENT`, or (only when all
   full-domain differences are actually closed) `FULL_SOURCE_PARITY`.
3. Capture reviewer identity, affiliation, evidence location, exact source
   pins, scope, exceptions, numerical output/return-schema findings, and
   completed review CSV. Sign with detached GPG; verify the signer's trusted
   fingerprint **out of band**. A cryptographic signature authenticates
   evidence ownership, not scientific truth.
4. Use `etr_check_four_pilot_external_attestation(...)` to check the
   detached signature and submission structure. **Present code prohibits
   FULL_SOURCE_PARITY while source differences remain open** and does not
   write any 508-export registry approvals. Restricted review leaves the
   full-domain count unchanged.
5. Only after actual full-domain gap resolution, independent signoff and
   separate human/maintainer adjudication may the authoritative register
   be updated: all required booleans TRUE, evidence_state
   `approved_and_reproducible`, and a full-SHA GitHub commit evidence URL.
   Do not change these values based solely on author tests or a green PR.
6. Re-run `etr_native_parity_catalog()` to confirm any counted approval
   is tied to real evidence, has no open source gap or alternative
   backend/estimand, and is not missing a native implementation. A reviewer
   finding of restricted-subset match belongs in a **separate restricted
   compatibility ledger**, not the 508 FULL-domain numerator.

## Scaling to 508 without fabricating numbers

Use priority batches, starting with small deterministic mathematical
functions, then models and structured outputs, then stochastic/statistical
estimators, visualization/third-party backends, and finally the 128
nonfunction contracts. Record both the full-domain and restricted-subset
counts. The existing **203** inventoried open source differences and
**19** backend/estimand distinctions must be resolved one by one or
recognized as inherently restricted/non-equivalent. Any unresolved one
blocks its associated full-domain certification.

A realistic scorecard uses these separate categories:

- Mapped name (currently 380/380 callable names).
- Native implementation checked and independently tested.
- Developer direct-source fixture PASS.
- Independently reproduced *restricted* match.
- Full-domain difference resolved, independently reviewed, signed and
  `approved_and_reproducible`: **only this final category increments 0/508**.

Do not equate the number 508 with a promise that Python runtime objects,
error semantics, third-party engines or every dtype can always have an
identical pure-native R representation. A small fully verified subset plus
honestly labeled restricted interfaces is scientifically stronger than
508 unsupported certifications.

Tracking: issue #34 for external review; draft PR #48 for current research
implementation and exact-head qualification evidence.
