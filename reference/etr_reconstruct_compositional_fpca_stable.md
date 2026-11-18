# Overflow-stable compositional FPCA reconstruction

Reconstructs fitted ALR score curves and computes their stable inverse
ALR onto the probability simplex. Leaves the original reconstruction
unchanged.

## Usage

``` r
etr_reconstruct_compositional_fpca_stable(result, scores = NULL,
  n_components = NULL)
```

## Arguments

- result:

  Native compositional FPCA fit.

- scores:

  Optional replacement scores.

- n_components:

  Optional fitted component count.

## Value

Numeric array (curves by times by simplex dimensions).
