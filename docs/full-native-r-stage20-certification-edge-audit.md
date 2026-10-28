# Stage 20 certification edge audit — owner-run Stage 20 evidence

**Scope:** review of the three pilot Python **v1.2.0** public function contracts against the standalone native R implementations. Published v1.2.0 release resolves to `c1cd95ad718327550f7e55393ff38582872f7a94`. The frozen Python API-name census records a separate development snapshot at `7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`. These must not be conflated.

## Exact evidence received from the owner

On the original Stage 20 PR #28 head `59f1da79032b298bf052fca4b97568460d0c812d`, Windows RStudio reported:

| Suite | Pass | Fail | Warn | Skip |
|---|---:|---:|---:|---:|
| Native Stage 20 certification/IAAFT | 61 | 0 | 0 | 1 opt-in Python |
| Full native R parity ledger | 39 | 0 | 0 | 0 |
| Pinned published Python 1.2 ALR and score-distance oracle | 79 | 0 | 0 | 0 |

The catalog returned exactly three pilot candidates; all were `pending_owner_runtime_and_review` with `one_to_one_native_contract_complete=FALSE`. This proves the **tested fixtures** passed on that head, not full-domain parity.

**A further source audit revealed a valid-domain mismatch that the 79 assertions did not cover.** The native ALR and inverse-ALR functions rejected a one-dimensional simplex, whereas the published Python implementations accept it: ALR returns shape `(n_curves,n_time,0)` and inverse-ALR maps it to all-ones shape `(n_curves,n_time,1)`. The native functions and inherited Stage 9/Stage 20 regression tests have now been corrected on a *newer commit* in this PR. The owner must rerun the revised test head before that source edge can be qualified.

## Candidate-by-candidate remaining certification gaps

| Python public contract | Evidence already collected | Source boundary still to resolve or approve | Certification |
|---|---|---|---|
| `alr_transform` | Multiple Python-vs-R reference indices and clipping floors; native valid-input shape and simplex checks | New one-dimensional simplex edge must pass the exact published Python oracle. R rejects non-finite epsilon while Python's `if epsilon <= 0` check does not explicitly reject NaN; document whether these invalid-input semantics belong to the accepted full contract. Python `np.asarray` also accepts some sequence inputs that native R requires as arrays | **Pending** |
| `inverse_alr` | Published Python vs native R roundtrip and valid transformed arrays | New zero-log-ratio-channel singleton case must run. For extreme inputs, Python may return nonfinite values due to `np.exp` overflow, while native R deliberately fails closed on nonfinite inputs/normalization. This is a deliberate safety difference and **not exact behavior parity** unless the source public contract is explicitly restricted to the finite in-domain cases | **Pending** |
| `score_distance_matrix` | Direct Python `sklearn.pairwise_distances` vs native `stats::dist` comparison on exact fitted scores, retained-component boundaries and symmetric/distance invariants | Native R requires an `etr_fpca` fit; the Python duck-typed routine reads `fpca.scores` and `fpca.n_components` and may accept any compatible object. Review malformed/empty/nonfinite score matrices, differences in source estimator container fields, and whether the full fit-object domain is equivalent | **Pending** |

**Important:** matching deterministic calculations on a finite, declared, scientifically valid domain can justify a *domain-restricted equivalence claim*, but it does not justify labeling the *entire* Python public API source contract fully certified when different accepted inputs or return/error behaviors remain.

## Admission criteria

For each candidate:

1. Retest the **latest exact PR head**, including native Stage 9 behavior affected by the single-channel fix and the pinned Python 1.2 Stage 20 oracle.
2. Verify successful output shape and values on ordinary and edge-domain inputs, including the singleton simplex.
3. Document the public Python signature/defaults, allowed input forms, handling of invalid and extreme cases, output schemas, type/shape/order, tolerance, metadata and scientific limitations. No silent R-only restriction can be called *full* one-to-one parity.
4. Obtain independent source-level reviewer evidence with a GitHub URL, and set all four CSV approval flags only after that reviewer confirms the complete contract and exact commit/test head.
5. Keep `etr_native_parity_catalog(require_complete=TRUE)` closed until **all 508** source contracts have individually passed.

**Current result:** numerical oracles on the prior head **green**, new edge-contract tests **await runtime**, reviewer signoff **not obtained**, **fully certified = 0/508**. This is conservative and intentional; none of the existing evidence should be discarded or relabeled as a full certification.
