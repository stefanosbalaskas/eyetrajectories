# Compare declared and realized native simulation score variance sources

Realized variances use the NumPy `ddof=0` population divisor, not the R
sample variance divisor. Source bar coordinates, component tick labels
and declared/realized legend ordering are retained without changing
actual simulated scores. Matplotlib runtime identity and exact pixel
colors remain outside the scientific contract.

## Usage

``` r
etr_plot_functional_simulation_score_variances(
    result, strict_source_record = FALSE)
```

## Arguments

- result:

  Real native functional simulation including curve, participant and
  trial latent scores and declared component variances.

- strict_source_record:

  Return a scientific native R artist record containing all six Python
  1.2 source-ordered bar groups with exact width, center and height; do
  not return a Python Matplotlib `Axes`.

## Value

Default invisible six-source bar geometry with declared/realized numeric
variance matrices; strict mode returns source-scientific one-panel bar
artist metadata.
