# Bridge to the Python eyetrajectoriespy API

Access public Python exports while keeping fitted Python objects intact.

## Usage

``` r
et_python()

et_python_version()

et_call(name, ..., .namespace = c("root", "workflows"), .convert = FALSE)

et_to_r(x)
```

## Arguments

- name:

  Single public exported callable name.

- ...:

  Arguments passed to the Python callable.

- .namespace:

  Python export namespace: `"root"` or `"workflows"`.

- .convert:

  Convert returned Python objects to R, where supported.

- x:

  A Python object to convert explicitly.

## Value

`et_python()` returns a Python module object; `et_python_version()`
returns a version string; `et_call()` returns the Python result unless
`.convert = TRUE`; `et_to_r()` requests reticulate conversion.

## Details

Only names in the selected Python module's `__all__` are accepted.
Python objects that are not representable as ordinary R objects remain
Python proxies. Loading the R package does not initialize Python.

## Examples

``` r
if (FALSE) { # \dontrun{
library(eyetrajectories)
et_python_version()
et_call("simulate_planar_trajectories", n_participants = 4L,
        trials_per_participant = 2L, random_state = 7L)
} # }
```
