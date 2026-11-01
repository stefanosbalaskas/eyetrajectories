# Offline four-pilot external-review handoff

**Integrity checking is not independent scientific certification.** The original Python 1.2 public API contains 508 exports (380 functions, 128 other exports); independent full-domain approvals remain **0/508**. Do not unlock release/merge or change certification flags based on this document.

## Frozen source / unresolved scope

- Frozen Python `eyetrajectoriespy==1.2.0`: commit `c1cd95ad718327550f7e55393ff38582872f7a94`.
- Native R research branch: `research/native-generalized-fosr-prediction-20261030`; obtain the **exact reviewed commit SHA** independently.
- Candidate pairs: `alr_transform`/`etr_alr_transform`, `inverse_alr`/`etr_inverse_alr`, `score_distance_matrix`/`etr_score_distance_matrix`, `functional_trapezoid_weights`/`etr_trapezoid_weights`.
- Three documented source differences: NaN epsilon propagation; exponent overflow/nonfinite results; final +Inf time endpoint. The score-distance nonfinite rejection is shared, but score-container, class, error and accepted-domain equivalence remain unreviewed.
- Owner-verified prior baseline: `5f7e3b33ad2f63be87b32811544a2d5987297eb3`, 10 developer finite comparisons passed, four developer boundary observations; 203 source-gap entries remain unresolved.

## Author: regenerate exact-head evidence

On the current research commit, from the repository root in RStudio:

```r
source("scripts/capture_native_source_qualification_evidence.R")
```

Copy the newly created `artifacts/native_independent_review_packets/qualification_YYYYMMDDTHHMMSS` folder to the appointed reviewer using an approved **private** channel. Do not publish private repository material or personally identifying data. The packet is author-produced and is not self-authenticating. This tool does not transmit or sign any files.

## Reviewer: independent-of-R integrity check

The script `scripts/verify_four_pilot_review_bundle.py` is standard-library Python, read-only, and independent of R/reticulate dependencies:

```bash
python scripts/verify_four_pilot_review_bundle.py PATH_TO_PACKET --expected-r-head FULL_TRUSTED_40_HEX_R_COMMIT
```

The trusted R commit must be obtained **outside the supplied packet**. The verifier checks six SHA256 file hashes, the recorded source commit, 10 author numeric comparisons, four author boundary observations, the 16-case reviewer worklist, 203 unresolved source gaps, and the unsigned four-row reviewer template and evidence-manifest binding. A PASS only establishes **internal consistency and unsigned-state**, not publisher authenticity; replacing a packet and all hashes can defeat any purely internal hash check.

Developer-only regression tests:

```bash
python -m unittest discover -s tests -p 'test_verify_four_pilot_review_bundle.py' -v
```

## Independent scientific signoff

A real independent reviewer must obtain both source checkouts, reproduce numerical and error cases independently, inspect accepted containers, coercion, NaN/Inf, defaults, shape/dtype/schema, estimands and source exceptions, and provide their own logs and findings. The author-created four-pilot comparison outputs are starting evidence, **not** independently replayed cases.

With known source gaps unresolved, only `RESTRICTED_SUBSET_MATCH` or `NOT_EQUIVALENT` can be submitted; `FULL_SOURCE_PARITY` is prohibited. The independent reviewer signs the completed CSV using detached GPG and provides a separately verified full signing-key fingerprint. Existing R function `etr_check_four_pilot_external_attestation(...)` validates technical signature/manifest structure but cannot, by itself, establish scientific judgment or reviewer independence.

Human reviewer queue: [issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34). Research work: [draft PR #48](https://github.com/stefanosbalaskas/eyetrajectories/pull/48).
