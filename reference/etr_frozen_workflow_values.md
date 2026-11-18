# Frozen Python 1.2 workflow source scalar values

Return native R copies of three public scalar values defined by frozen
eyetrajectoriespy 1.2.0 `workflows/_core.py`. The values document Python
source metadata; they are not claims of native bundle-format
interoperability or full scientific source equivalence.

## Usage

``` r
etr_frozen_workflow_values()
```

## Value

A named R list with two integer scalars, `WORKFLOW_SCHEMA_VERSION` and
`WORKFLOW_BUNDLE_SCHEMA_VERSION`, and one character scalar,
`WORKFLOW_BUNDLE_FORMAT`.

## Details

The Python workflow bundle format string is
`eyetrajectoriespy-workflow-bundle`. Native R workflow bundles use a
different format. All source-object full-domain certification decisions
remain independent and unapproved.

## Examples

``` r
values <- etr_frozen_workflow_values()
stopifnot(identical(values$WORKFLOW_SCHEMA_VERSION, 1L))
```
