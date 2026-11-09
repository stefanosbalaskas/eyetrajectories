# Evidence-gated large-batch callable source-gap closure

The historical 203 callable gap witnesses and the frozen Python 1.2 reference
remain unchanged. Counts are dynamically computed from the current CSV flags.
The legacy two zero-argument semantic closures are preserved.

A **new callable gap** can be marked `unresolved_source_gap=FALSE` only after
a human author has reviewed the **complete** source contract, not merely a
finite numeric differential fixture. Add a corresponding row to
`inst/extdata/reviewed_source_contract_closures_v1.csv` and a SHA-256-pinned
JSON record under `docs/source_contract_reviews/`.

The JSON record must specify `audit_version=source-contract-v1`,
`python_name`, `frozen_python_commit`, `scope=FULL_SOURCE_CONTRACT`,
`author_decision=FULL_CONTRACT_REVIEWED`,
`independently_certified=false`, a reviewer statement (at least 40
characters), and `case_evidence` containing existing tests with exact
relative paths and SHA-256 digests for all six kinds:

1. `source_signature`
2. `accepted_input_domain`
3. `numerical_outputs`
4. `exception_semantics`
5. `returned_schema`
6. `scientific_estimand`

The manifest row must pin the frozen source SHA, JSON digest, author decision
`AUTHOR_FULL_CONTRACT_REVIEWED`, and
`independently_certified=FALSE`. A changed source test or missing review
file will cause a **hard failure**, not a count reduction. A bare CSV flag
or automatically generated finite-domain evidence **cannot** close a gap.

These are **developer-reviewed source contract closures**. Independent
scientific certification requires a separate actual external review and is
never granted by this mechanism.

The accelerated 32-function implementation queue is replenished from currently
open scientific contracts when previous targets are reviewed as complete; it
cannot block progress by insisting that permanently-open historical names
remain in every new wave. Evidence is still recorded separately for author
tests, independently signed reviews, and source-gap inventory.
