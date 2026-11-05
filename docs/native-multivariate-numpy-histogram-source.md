# Exact NumPy bin geometry in multivariate surrogate nonlinearity plots

Frozen source: `eyetrajectoriespy==1.2.0` at SHA
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/nonlinear_plotting.py::plot_multivariate_surrogate_nonlinearity`.

Published Python requires a `MultivariateSurrogateNonlinearityResult`
and an integer `bins >= 2`. It invokes
`ax.hist(result.surrogate_statistics, bins=bins, alpha=0.7)`,
which delegates finite-data integer bin edges and counts to NumPy.

The original native R
`etr_plot_multivariate_surrogate_nonlinearity(result,bins=20L)`
already used manually equal-width breaks, but it had two *numerical*
differences:

- Constant samples at nonzero values expanded to
  `[value-abs(value)*0.5, value+abs(value)*0.5]`, not NumPy's fixed
  `[value-0.5, value+0.5]`.
- Base `graphics::hist` counts use fuzzy bin-edge tolerance and can
  differ from NumPy `[left,right)` membership with a closed rightmost
  bin.

## Explicit bounded source mode

`etr_plot_multivariate_surrogate_nonlinearity(result,bins=20L,
python_boundary_mode=TRUE)` now uses the NumPy constant-data range,
exact equally spaced bin edges, and `findInterval` bin counts with
a closed final right edge. It replaces the plotted histogram's count
and density fields consistently, so the returned native geometry and
rendered bar heights agree. A conservative limit of 10,000 bins bounds
R graphics resource use; Python need not share this limit.

The **default** `python_boundary_mode=FALSE` preserves the prior
native R implementation and accepts integer-valued R doubles.
The source mode requires an integer storage type, like Python's
`isinstance(bins,int)` contract for valid counts.

## Evidence required to merge

`tests/testthat/test-native-multivariate-surrogate-numpy-histogram-source.R`
covers finite, constant (positive/negative/zero), skewed and
boundary-aligned samples, bin count and validation checks. The
`ET_RUN_PYTHON_TESTS=true` oracle constructs an actual frozen
`MultivariateSurrogateNonlinearityResult`, invokes the **actual**
Python 1.2 exported plotting function, and compares NumPy bin
edges plus real Matplotlib patch heights for 2/4/8 bins.

The full `native_r_offline` and `python_1_2_direct_source`
qualification selectors include this source suite. RStudio exact-head
execution of those suites is still required.

## Open scientific source gaps

This patch provides **histogram numerical geometry**, not Matplotlib
Axes objects, typed Python scientific result constructors, pixel-level
rendering equivalence or all accepted Python input/error domains.
The source-gap register retains the open
`plot_multivariate_surrogate_nonlinearity` backend/typed-input row,
and `0/508` independently signed full-domain scientific contracts
is unchanged. No source-gap count or CRAN release status is advanced
by this first-party source calculation alone.
