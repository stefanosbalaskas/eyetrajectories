# Frozen Python 1.2 scikit-fda Modified Band Depth functional-boxplot source

Frozen public export: `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/backends.py::detect_functional_outliers_skfda(method="boxplot")`.

Mathematical backend source snapshot inspected: GAA-UAM/scikit-fda commit `9e21b2a0bf7674ebea906851f48883c3f4c0c375`: `skfda/exploratory/outliers/_boxplot.py`, `_envelopes.py`, `skfda/exploratory/depth/_depth.py::ModifiedBandDepth`, `multivariate.py::SimplicialDepth`, `skfda/representation/grid.py::FDataGrid.integrate` and `skfda/_utils/ndfunction/_functions.py::average_function_value`.

## Scientific correction

Previously, `etr_detect_functional_outliers_skfda` only implemented a **marginal pointwise Tukey envelope**, a different estimand from the source `BoxplotOutlierDetector`.

The source uses **Modified Band Depth (MBD)** and a deepest-half central envelope. The new opt-in native R function `etr_detect_functional_outliers_skfda(x,dimension,method="boxplot",factor=1.5,strict_source_record=TRUE)` implements this actual mathematical chain.

Given **n** complete univariate functional curves `Y[i,j]` on a finite increasing observation grid `t[j]`:

1. **Pointwise SimplicialDepth:** For each time j and curve i, let `L[i,j]` count training curves strictly **below** `Y[i,j]` and `U[i,j]` count those strictly **above** it. Source depth is `D[i,j] = [choose(n,2)-choose(L[i,j],2)-choose(U[i,j],2)]/choose(n,2)`. Exactly equal measurements are included in both-sided simplex containment (ties are not silently ordered).
2. **Source integrated MBD:** `MBD[i] = scipy.integrate.simpson(D[i,],x=t)/(max(t)-min(t))`. Native R uses an explicit vector of composite **nonuniform-grid Simpson weights**, including SciPy's even-sample final-interval Cartwright correction; this is not a uniform-time simple average.
3. **Central functional envelope:** Select the top `ceil(n/2)` curves ordered by descending MBD, take their pointwise min and max `L[j],U[j]`.
4. **Expanded non-outlying fences:** `L_fence[j] = L[j] - factor*(U[j]-L[j])`; `U_fence[j]= U[j]+factor*(U[j]-L[j])`.
5. **Source binary labels:** Any sample position outside the respective fence labels the entire curve **-1** (review flag TRUE); otherwise label **+1**. The original data remain unaltered.

The returned typed R `etr_skfda_mbd_boxplot_scientific_record` includes the source-compatible `FunctionalOutlierResult` scientific fields (`diagnostics`, `method="skfda_boxplot"`, `reference=NULL`, `provenance`) and exposes the full depth, weighting, central selection and envelopes for review, with `backend_object=NULL`. The scientific warning that flags are **review diagnostics rather than automatic exclusions** is preserved. The source `random_state` is accepted and preserved but is not used by this deterministic default boxplot method.

## Bounded accepted domain

- Finite complete curves with at least three curves and at least two sorted distinct finite observation times.
- One selected observed channel, finite positive factor.
- To avoid pretending to reproduce Python NumPy's default **unstable quicksort**, the native strict mode **rejects tied MBD values that straddle the deepest-half boundary**, because tied-cutoff membership can be Python runtime-dependent. Ties within either retained/rejected group are supported.
- The legacy default `strict_source_record=FALSE` continues producing the prior pointwise marginal Tukey envelope unchanged. Nothing is silently switched.

## Explicit unresolved source capabilities

The frozen source also supports `method="msplot"`. Real `MSPlotOutlierDetector` requires **directional outlyingness**, robust `sklearn.covariance.MinCovDet` fitting, empirically tabulated or asymptotic **F**-distribution cutoffs, and controlled stochastic operations. **None of this is claimed or implemented in this boxplot wave.** Passing `method="msplot"` to strict R deliberately raises a clear error; the frozen source accepts it. A full-method-domain, real Python `MSPlotOutlierDetector`, returned Python `backend_object`, Python warning/exception, non-tie and singular-edge parity remain unqualified.

An R native regression suite checks the published 4-curve scikit-fda example (expected labels `[-1,1,1,-1]` and its exact MBD values), Simpson polynomial exactness on nonuniform sample times, central envelopes, input immutability, tie exclusions and the unchanged default. An **opt-in actual frozen Python 1.2 + real scikit-fda** differential comparison calls the true public function on regular and nonuniform grids and compares its depths and flags directly.

This is a **provisional default-boxplot scoped mathematical-source review**, not complete source export method coverage and not independent full-contract certification. Tests are authored but are not claimed executed green until GitHub Actions reports success.
