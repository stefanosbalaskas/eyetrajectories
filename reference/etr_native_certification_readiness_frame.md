# Audit full Python source-contract certification evidence

Return a fail-closed, one-row-per-public-export register of the exact
evidence still needed to qualify 508 frozen eyetrajectoriespy 1.2.0
contracts. This function reads existing source-contract registries and
cannot approve or alter any contract.

## Usage

``` r
etr_native_certification_readiness_frame(
  include_nonfunctions = TRUE, only_unapproved = FALSE
)
```

## Arguments

- include_nonfunctions:

  Whether to include Python classes, constants and other nonfunction
  exports in addition to callable operations.

- only_unapproved:

  Whether to restrict to incomplete or unapproved source contracts.

## Details

A Python-to-R function name mapping, working implementation, passing
numerical fixture or Python source-oracle comparison is not sufficient
for full certification. Full source certification also requires
acceptance of the complete input and output schema, scientific scope,
all recorded source differences, reproducible review evidence and
independent reviewer approval. Open source gaps block approval.

Published source reference: Python eyetrajectoriespy 1.2.0; frozen
manifest of 508 public exports including 380 callable functions. The
register is read-only and does not invoke the Python runtime.

## Value

A native R data frame with frozen Python name, kind and source SHA,
native mapping status, native implementation status, known source gaps,
numerical/schema/scientific/reviewer approval flags, full certification
status, and first/all outstanding evidence requirements.
