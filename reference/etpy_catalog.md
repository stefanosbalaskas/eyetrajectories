# Python source API catalog and installed-runtime verification

Inspect the recorded GitHub main API snapshot without Python, or verify
that public functions are present and callable in an installed Python
eyetrajectoriespy distribution.

## Usage

``` r
etpy_catalog(include_nonfunctions = FALSE)
etpy_verify_api(include_nonfunctions = FALSE, strict = FALSE)
etpy_get_export(name, .namespace = c("root", "workflows"), .convert = FALSE)
```

## Arguments

- include_nonfunctions:

  Logical. Include class and constant names.

- strict:

  Logical. Error if recorded symbols are missing or uncallable.

- name:

  Public Python export to retrieve without calling.

- .namespace:

  Either root or workflows.

- .convert:

  Logical. Explicit Python-to-R conversion.

## Value

etpy_catalog returns a data.frame of 380 functions by default, or 508
total exported symbols with include_nonfunctions TRUE. etpy_verify_api
adds availability, callability and installed version columns.
etpy_get_export returns the selected Python object or converted R value.

## Details

All structural information comes from the recorded source API, not from
empirical eye-tracking data. Installed Python availability must be
checked separately, and scientific properties remain unqualified.

## Examples

``` r
api <- etpy_catalog()
stopifnot(nrow(api) == 380L)
head(api[, c("namespace", "python_name", "r_wrapper")])
# Run etpy_verify_api() only when the optional Python backend is installed.
```
