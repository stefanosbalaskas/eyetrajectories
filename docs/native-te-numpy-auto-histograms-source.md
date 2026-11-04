# Frozen Python 1.2 transfer-entropy automatic histogram source-domain work

Source of record: `eyetrajectoriespy==1.2.0` at
`c1cd95ad718327550f7e55393ff38582872f7a94`.
The Python plot exports
`plot_transfer_entropy_circular_shift_test` and
`plot_conditional_transfer_entropy_circular_shift_test`
pass their surrogate samples to Matplotlib
`Axes.hist(values, bins="auto")`. This delegates histogram
edges to the installed NumPy version; the published Python
package declares `numpy>=1.26`, not an exact NumPy patch version.

## Bounded native numerical improvements

`etr_plot_transfer_entropy_circular_shift_test` and
`etr_plot_conditional_transfer_entropy_circular_shift_test` retain
their existing default R Sturges geometry. With
`python_boundary_mode=TRUE` and `bins="auto"` they now implement:

- `numpy_auto_policy="classic"`: the old NumPy FD/Sturges selector
  with Sturges fallback for zero IQR.
- `numpy_auto_policy="relaxed"`: the modern NumPy FD/Sqrt/Sturges
  selector, constraining FD width to at least half the sqrt-rule width,
  then choosing the minimum of the relaxed FD and Sturges widths.
- Exact finite-source NumPy bin-edge interpolation, final right-edge
  inclusion, and explicit counts, rather than R histogram's fuzzy
  edge tolerance. Rendered plots remain base R graphics and return
  native R histogram geometry rather than Matplotlib Axes.

The reference source can produce distinct automatic histograms on
different NumPy versions. The chosen algorithm must be declared
rather than inferred from the `eyetrajectoriespy` version alone.
No Python interpreter is required for native plotting.

## Evidence and boundaries

`tests/testthat/test-native-te-numpy-auto-histograms.R` checks
different automatic bin counts on an explicitly skewed distribution,
constant-null handling, exact counts, edge preservation, and
both real frozen Python 1.2 plot exports when
`ET_RUN_PYTHON_TESTS=true`. That test determines which of the two
supported NumPy bin estimators agrees with the observed runtime
`numpy.histogram_bin_edges` before comparing actual Axes bar
heights and edges.

The native source mode rejects invalid policies, non-finite surrogate
samples, non-finite effective data ranges and automatic bin counts
exceeding 10,000; Python does not share the exact same resource
limits or all R validation semantics. Matplotlib Axes return identity,
typed Python result classes, rendering metadata and unbounded
NumPy environment variation remain open.

**Do not close either recorded source-contract gap, amend the
508-export certification inventory, or assert independent scientific
approval on these numerical developer witnesses.**
