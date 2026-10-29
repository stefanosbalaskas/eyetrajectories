# Complete published Python 1.2 source-contract closure — deterministic first

**Certification review queue; not an approval certificate.**
Pinned source: `eyetrajectoriespy==1.2.0`
(`c1cd95ad718327550f7e55393ff38582872f7a94`).
Frozen public exports: **508** (380 callable; 128 other).
Source manifest SHA:
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Existing deterministic source-contract candidates: complete approval blocked

The published Python source and existing native R implementation have
been inspected to identify the exact **full-public-domain** mismatch.
Each of the four already has a passing targeted numerical fixture,
but **none** has independent all-domain type/schema/scientific review
and signoff, so `one_to_one_native_contract_complete=FALSE`.

| Python source name | Evidence already passed | Precise full-contract gap requiring a decision |
|---|---|---|
| `alr_transform` | Standard finite probability-simplex ALR and inverse fixtures | Published Python `np.asarray(..., dtype=float)` accepts more input containers, normalizes reference indices modulo `k`, and accepts `epsilon` whenever `epsilon <= 0` is false. R validates a narrower input container/epsilon domain. Rejecting nonstandard source inputs is a **cross-language behavior difference**, not numeric parity. |
| `inverse_alr` | Finite moderate log-ratio reconstruction, singleton case | Published Python computes direct `np.exp(z)`. Extreme but finite log-ratios can overflow, leading to nonfinite normalized outputs under NumPy's warning behavior. The native R implementation deliberately rejects nonfinite results, so the complete accepted-input/error contract differs. |
| `score_distance_matrix` | Finite FPCA score matrix and minimal object numeric fixtures | Published Python accepts duck-typed score objects and delegates to scikit-learn `pairwise_distances`; native R accepts audited R score lists and native fits, with different accepted classes, coercion/overflow and error boundaries. |
| `functional_trapezoid_weights` | Finite increasing-grid weights, including normalization | Published Python converts arbitrary numeric `time` containers with NumPy; `normalize` uses Python truthiness. Native R requires a narrower time/logical flag domain. Extreme/nonfinite grid values and invalid-input behavior require direct review. |

**Review decisions still required:** either (1) implement all applicable
published Python 1.2 coercions, input domains, overflow and error
semantics in the native R contract (accounting for language-specific
class representations), or (2) approve a deliberately **restricted
semantic cross-language contract** with a new, explicitly labeled
scope that does *not* misstate full original public source parity.

The original 508-export complete Python-source certification flag is
for **option 1 only**. Option 2 must carry a different field/label;
it cannot set `one_to_one_native_contract_complete` to TRUE.

## Required independent reviewer checklist

For a public Python source contract, record:

1. **Source freeze:** exact public name, distribution, pinned source
   tag/commit and frozen API census identity.
2. **Signatures and defaults:** full Python public signature,
   accepted types and duck-typing, coercions, numeric/axis shapes,
   default values, and explicit unsupported domains.
3. **Numerical/scientific behavior:** source-level numerical
   algorithm, tolerances, special finite/extreme inputs,
   random-number-engine boundaries, and inferential interpretation.
4. **Schema, errors, and return type:** all named fields, ordering,
   invalid input categories, Python object class and sensible
   cross-language R representation of that class.
5. **Independent evidence:** one test suite that calls the published
   Python object and the native R implementation on a qualification
   fixture matrix, with exact Git head and result URLs, verified
   by a reviewer other than the implementation author.
6. **Fail-closed approval:** no `numerical_oracle_approved`,
   `schema_boundary_approved`, `scientific_scope_approved` or
   `independent_reviewer_approved` flag set without
   corresponding signed/reproducible evidence. Existing source gaps
   always block the complete-source certification flag.

## Current audited status

- **207** authored native R functions from **232/380** mapped
  published Python root callable names, **148** unmapped names;
  **128** other public classes/constants remain source census items.
- **53** explicit known complete-public-source differences, each
  registered fail-closed in
  `inst/extdata/native_source_contract_gaps_stage22.csv`.
- **Four** prior targeted deterministic numerical fixture successes;
  **zero** complete independently approved source contracts out of
  508.
- Stage-free native **function names** are required across the entire
  public API. Historical numbered test files/ledger provenance are
  retained only as research audit evidence.
- The new seven native inference interfaces have direct published
  Python 1.2 real FOS and conformal source oracles authored but
  are **not yet runtime qualified**.
- GitHub-hosted CI admission continues to fail before any steps run
  ([issue #39](https://github.com/stefanosbalaskas/eyetrajectories/issues/39));
  owner RStudio exact-commit source tests remain a separate admissible
  preliminary qualification route, but cannot replace independent
  human full-contract review.

Reference review [issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).
**This document authorizes no release, merge, or certification flag.**
