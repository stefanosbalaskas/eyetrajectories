# Source-aligned integer histogram geometry for surrogate nonlinearity

Frozen upstream source: `eyetrajectoriespy==1.2.0`,
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/nonlinear_plotting.py::plot_surrogate_nonlinearity`.
Python validates an integer count at least two, then draws a Matplotlib
`Axes.hist(result.surrogate_statistics, bins=bins, alpha=0.7)`, delegating
the finite-data break/count convention to NumPy.

Existing native `etr_plot_surrogate_nonlinearity()` called
`graphics::hist(...,breaks=as.integer(bins))`: base R can replace a
requested count with a "pretty" break grid, so even numerical bar
geometry can differ on identical surrogate samples.

## Updated numerical behavior

With explicit `python_boundary_mode=TRUE` and `bins=20L` (or another
native integer count >=2), native R:

1. constructs exact equally spaced endpoints between sample min/max,
   with NumPy's ±0.5 expansion for a constant surrogate statistic;
2. counts each bin as left-closed/right-open, except the rightmost bin,
   which includes the final endpoint, avoiding R's fuzzy-edge bin
   tolerance;
3. keeps a source-compatible exact bin count (bounded at 10,000 native
   display bins, stricter than Python) and updates plotted histogram
   densities to agree with the revised counts;
4. returns the same native invisible geometry with
   `python_matplotlib_histogram_binning_equivalent=TRUE` **only for the
   histogram binning**, not the entire graphics object.

`python_boundary_mode=FALSE` retains the original R plot and its
input acceptance, including R integer-valued doubles for `bins`.
In the source-boundary mode a double `bins=2` is rejected, matching
Python's integer-only argument contract.

## Executed/source evidence to request

- `tests/testthat/test-native-surrogate-numpy-histogram-source.R`
  checks fixed samples `c(0,1,2,3,4)`, boundaries, count total and
  the exact `1,1,1,2` four-bin distribution.
- Constant and skewed finite surrogate samples, malformed inputs and
  explicit R/Python mode differences are tested offline.
- In the pinned Python direct-source qualification mode, tests call
  the **actual** `eyetrajectoriespy.plot_surrogate_nonlinearity` export
  on a typed `SurrogateNonlinearityResult`, then compare NumPy
  `histogram_bin_edges` and actual Matplotlib bar heights for
  2, 4, 7 and 20 integer bins.

## Open scientific gaps

The original source-gap classification remains **backend_and_histogram**:
Python returns a Matplotlib Axes object and validates a typed Python
result; native R uses base graphics and a validated source-record list.
The bounded histogram improvement is not equivalent to full output
object parity, exact renderer styling or arbitrary Python class input
semantics.

Do not reclassify any of the **204 recorded source-gap exports** or
approve any of the **508 unsigned full-domain contracts** based on
these first-party numerical regression tests.
