# Independent scientific certification workflow — all 508 Python 1.2 exports

Frozen Python source: eyetrajectoriespy 1.2.0, commit c1cd95ad718327550f7e55393ff38582872f7a94.
Native R review requires a separately checked complete R commit SHA.
Author-side package CI and SHA256 manifests do not establish independent science.

## Current scientific status

508 exports = 380 callable functions + 128 nonfunctions; 380 names mapped;
203 callable source differences plus 1 nonfunction source difference remain;
19 alternative backend or estimand distinctions (possibly overlapping).
Independently FULL-domain source-certified exports: 0/508.

## Generate 15 author-side unsigned reviewer waves

From the R repository root after the two-mode source-qualification suite
has generated an original qualification_YYYYMMDDTHHMMSS packet:

    python scripts/build_508_all_export_review_waves.py build PACKET_DIR --expected-r-head 40_HEX_R_SHA
    python scripts/build_508_all_export_review_waves.py verify PACKET_DIR --expected-r-head 40_HEX_R_SHA

The main R qualification script now calls both commands automatically.
The tool validates the original source-pinned 508 inventory and its first-wave
integrity records, then writes the full 15 waves with 5,080 blank per-export
criteria and one pending unsigned decision per export. The last wave has four.
No certification or source-gap flag changes; tampering fails closed.

## Genuine external reviewer and authenticated scientific findings

Invite a scientifically qualified person independent of the source port's
implementation and fixture authors. Reviewer must inspect pinned Python
source and dependencies, native implementation, all accepted domains,
boundary/invalid inputs, return types, estimands, random engines, numerics,
side effects and errors. Reviewer adds their own independently executed tests.
Reviewers must preserve original source/identity columns in their completed
copies of wave_NN/cases_UNSIGNED.csv and wave_NN/decisions_UNSIGNED.csv.
One wave can be submitted in multiple independently signed partial receipts.

Each decision must be FULL_SOURCE_PARITY, RESTRICTED_SUBSET_MATCH or
NOT_EQUIVALENT, with 10 evidence-backed case findings per reviewed export.
Known source gaps, distinct backends or missing native representations
prevent a full-source-parity request. Source resolution requires a new exact
R SHA and reviewer replay; a signed negative finding is valid evidence.

The reviewer signs BOTH their completed CSV copies with GPG detached
signatures. The maintainer verifies the complete signer fingerprint
independently of those documents, and runs:

    python scripts/verify_508_all_wave_attestation.py PACKET_DIR \
      --wave 1 --cases completed_cases.csv --decisions completed_decisions.csv \
      --cases-signature completed_cases.csv.asc \
      --decisions-signature completed_decisions.csv.asc \
      --expected-r-head 40_HEX_R_SHA \
      --trusted-fingerprint VERIFIED_40_HEX_GPG_FINGERPRINT

Receipt verification checks exact pins, original unsigned wave integrity,
full criterion coverage, independently written findings, trusted signer
fingerprint and both detached signatures. Signature ownership alone is
NOT proof of scientific truth or independence. The verifier is read-only;
no signed CSV is allowed to set authoritative 508 certification flags.

## Scientific acceptance is separate from receipt validity

Only human/maintainer adjudication after complete-domain gap closure and
independent replication can promote an export in the authoritative R ledger.
Until that occurs, the publicly reported independently certified count is
zero. Do not use unsigned author receipts or a restricted-subset match to
increment the full-domain denominator.

## Observed interfaces for all 508 exports

After successful source qualification, scripts/capture_all_508_source_interfaces.R
records all 508 frozen Python export lookups, function signatures or object
classes, corresponding exported native R formals or nonfunction
representations, native body hashes, and the exact source-gap/backend
blockers. Errors in individual Python interface inspection remain explicit
in the CSV. The resulting all_508_source_interface_inventory.csv and
all_508_source_interface_inventory_sha256.csv are author-side observations;
every independent replay and certification flag is FALSE.
