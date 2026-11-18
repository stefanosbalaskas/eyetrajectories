# Known-truth inverse phase-warp recovery audit

Compares fitted reference-to-observed warps with the inverses of
source-generating latent phase warps, without altering latent or fitted
trajectories. Source dataclass and error schema equivalence remain
uncertified.

## Usage

``` r
etr_evaluate_registration_recovery(result, truth)
```

## Arguments

- result:

  Source-shaped registration warp result and original grid.

- truth:

  Simulator truth on an exactly equal grid with generating warps.

## Value

Native recovery assessment with integrated squared inverse-warp error
and maximum absolute inverse-warp error.
