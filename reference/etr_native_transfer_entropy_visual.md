# Native source-aligned transfer-entropy sensitivity and circular-shift graphics

Three independent Python-free native R graphics presenting already
estimated discrete transfer-entropy sensitivity, source-only
circular-shift null distributions, and conditional transfer entropy. No
TE estimator is rerun or adjusted by the plots.

## Plotting parameters

- result:

  Native TE parameter sensitivity or circular source-shift test result,
  including a complete observed statistic and surrogate distribution as
  relevant.

- parameter:

  One declared TE sensitivity specification parameter.

- metric:

  One native scientific TE sensitivity metric to plot.

- filters:

  Named list fixing other varying parameter dimensions. Ambiguous slices
  fail rather than silently averaging any cells.

- bins:

  Explicit positive integer histogram bin count or `"auto"`. Explicit
  bins use equal-width source min/max breaks. The default native R
  `"auto"` retains Sturges for backward compatibility. With
  `python_boundary_mode=TRUE`, automatic bins use the selected NumPy
  finite-data estimator and exact bin counts.

- python_boundary_mode:

  Logical. When TRUE with `bins="auto"`, use explicitly declared
  NumPy-style automatic histogram geometry, without importing or calling
  Python. Defaults to FALSE.

- numpy_auto_policy:

  Either `"relaxed"` (the FD/Sqrt/Sturges width rule observed in modern
  NumPy) or `"classic"` (classic FD/Sturges fallback observed in older
  NumPy). Explicit selection is necessary because frozen Python 1.2
  declares `numpy>=1.26`, not a single histogram implementation.

- ...:

  Additional base R graphics arguments.

## Value

Plots render on the active native R graphics device and invisibly return
exact numeric source coordinates or surrogate/observed statistics and
histogram count/bin geometry. These are not Matplotlib Axes and
therefore are not equivalent public Python return types.

## Details

The circular-source-shift null is a statistical procedure under an
explicit source wrap-around assumption and is not a causal
identification design. In conditional TE the target and conditioning
processes remain fixed while the source is shifted. The selected TE
multiverse slice is descriptive; no automatic parameter selection or
statistical multiplicity correction is inferred. Full public source
certification requires typed result-schema equivalence, full
NumPy-version-dependent histogram behavior, Matplotlib Axes return
identity, and independent review. Finite numerical histogram geometry
and bin counts now have explicit source-boundary options, but
source-side plotting remains a different graphics backend.
