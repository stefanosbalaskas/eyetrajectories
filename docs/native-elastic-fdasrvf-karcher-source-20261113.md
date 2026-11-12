# True native R elastic Karcher registration and geodesic shape FPCA: bounded Python scientific contract

## Frozen source and independent native R mathematical engine

The target is the frozen public `eyetrajectoriespy==1.2.0` function `fit_elastic_fpca` in `src/eyetrajectoriespy/elastic.py`, Python source commit `c1cd95ad718327550f7e55393ff38582872f7a94`. Python uses `fdasrsf>=2.7` `fdacurve(beta,N=n_time,scale=scale_curves)`, then `karcher_mean(rotation=rotation,parallel=False,lam=lam,method=method)`, `srvf_align(...)`, and `shape_pca(no=n_components)` from the genuine Python `fdasrsf` implementation. Primary scientific source: `jdtuck/fdasrsf_python`, inspected source revision `ddcb36695f43331d9876aa25b07dbc24e4c48a49`, files `fdasrsf/curve_stats.py` and `fdasrsf/curve_functions.py`. The Python source computes nonidentity geodesic shooting vectors and dynamic-programming curve warps; no identity-warp substitute is scientifically equivalent.

The independently maintained **R-native** source-scientific counterpart is CRAN `fdasrvf>=2.5.1` (published 2026-10-29), maintained by J. Derek Tucker and Aymeric Stamm; source GitHub `jdtuck/fdasrvf_R` audited at commit `da551a77239506bf1e7a3e24199c344961be9e3b`, files `R/multivariate_karcher_mean.R`, `R/multivariate_karcher_cov.R`, `R/multivariate_pca.R`. This is a genuine R scientific package implementing the elastic SRVF Karcher alignment framework and native optimizers, not a Python import, a reticulate bridge, or merely a vector-distance registration alternative.

The new opt-in API, with the historical native unregistered SRVF behavior unchanged by default, is:

```r
fit <- etr_fit_elastic_fpca(
  trajectories,
  n_components = 2L,
  rotation = FALSE,
  scale_curves = FALSE,
  lam = 0,
  method = "DP",
  strict_source_record = TRUE
)
```

The optional R package must be installed by the R user as `fdasrvf>=2.5.1`; it is declared under `Suggests` rather than adding a mandatory Python or external native dependency. The historical `method="identity_only"`, `strict_source_record=FALSE` still returns `etr_unregistered_srvf_fpca` with identity warp. Source mode does not silently remap an identity request to DP.

## Actual source-scientific R algorithm

1. Validate complete finite numeric curves, >=2 measured channels, >=5 observation times and >=3 independent curves, positive integer component count <= n_curves-1, nonnegative finite `lam`, explicit Boolean `rotation`/`scale_curves`, and `method="DP"`. Arbitrary R/Python/NumPy coercions and `RBFGS` are excluded, not silently replaced.
2. Transpose input from **curve × time × channel** to the source's **channel × time × curve** layout by `aperm(values,c(3,2,1))`. Pass *all* available measured dimensions, not only the first two.
3. Fit a true **SRVF Karcher mean + elastic DP time alignment** using `fdasrvf::multivariate_karcher_mean(beta,mode="O",alignment=TRUE,rotation,scale=scale_curves,lambda=lam,maxit=20,ms="mean",exact_medoid=FALSE,ncores=1,verbose=FALSE)`. This explicitly estimates the source-like phase warp and tangent shooting vectors and returns real aligned curves `betan`, warped SRVFs `qn`, normalized-domain warps `gamma`, Karcher curve `betamean`, tangent vectors `v` and optimization diagnostics.
4. Compute **geodesic/tangent-space shape PCA**, not Euclidean FPCA on unregistered coordinates: `fdasrvf::multivariate_pca(km,no=max(2,k),ci=seq(-2,2.5,by=.5),mode="O",showplot=FALSE)`. The **10** deformation standard-deviation samples are chosen to match Python `shape_pca` source's 10 geodesic directions with `0.5*(i-5)` for `i=1,...,10`. Asking the R package for at least two components prevents an implementation-specific one-column dimension drop for `k=1`; only requested leading `k` are returned.
5. Convert output to frozen public scientific layouts: `aligned.values` **curve × time × channel**, `warping_functions` **curve × time**, `scores` **curve × k**, `principal_directions` numeric **channel × time × k × 10**, `mean_curve` **channel × time**. Preserve original time coordinates, curve identifiers, dimension names, metadata, coordinate and temporal units, and existing provenance via `etr_with_values`.
6. Return a typed native R `etr_native_elastic_karcher_pca_scientific_record`, including original R `fdacurve` and `curve_pca` objects as `native_backend_object` and `native_pca_object`, native SRVF and tangent diagnostics, real nonidentity warping functions and phase/amplitude warning. Its `backend_object=NULL` explicitly avoids representing a genuine Python `fdasrsf.fdacurve` object which has not been instantiated.

## Essential differences from Python source (NOT FULL METHOD-DOMAIN PARITY)

Both packages implement the same *scientific family* of elastic SRVF Karcher mean, time reparameterization and tangent-geodesic PCA. However their **code paths and optimizer choices are not numerical clones**. In the inspected sources:

- Python `fdasrsf.fdacurve.karcher_mean` initializes the Karcher mean with the **first input curve** and separately calls `srvf_align` afterwards. Current R `fdasrvf::multivariate_karcher_mean` initializes with an SRVF **medoid**, and returns already aligned native R curves. Different local minima and resulting warps may occur. Different aligned-curve construction and centering are also possible.
- The R backend uses its own DP/elastic implementations. `method="DP"` is accepted as a **source-scientific equivalent family**. Python `RBFGS` and other source-private aligners are not implemented in native R strict mode. When `scale_curves=TRUE`, the R tangent covariance/PCA currently treats normalized SRVFs, while Python `fdasrsf` appends the original curve-length component to its Karcher covariance. Therefore full amplitude/scale PCA parity is **not** claimed, even though true R scale-invariant elastic registration is performed.
- Both implementations compute tangent covariance and geodesic shape variation, but particular numerical geodesics, singular vector signs, optimization convergence and score ordering can differ. No false exact array equality is asserted.
- Python source `backend="fdasrsf"` and `backend_object` containing `fdasrsf.fdacurve`; native R returns `backend="native_fdasrvf"`, `backend_object=NULL`, and an independent native R `fdacurve` object. Python `ElasticFPCAResult` object identity, Python exception/warning types and unconstrained accepted input domains are not ported.
- Frozen public Python uses `n_components>=1` with no explicit upper rank bound, while the bounded native R source requires independent geometric support and `n_components<=n_curves-1` for stable tangent covariance.
- The native R data domain requires a meaningful open curve and complete finite multi-channel samples; self-intersections, degenerate zero-length curves, rotation/scaling singularities, nonconvergent DP fits and other difficult edge cases require independent scientific qualification.

This is a **developer-reviewed bounded native R scientific elastically aligned FPCA export**, and NOT 1:1 Python `fdasrsf` method parity, a Python backend replacement, an independent full-domain certification, or a guarantee of numerically identical returned aligned arrays.

## Tests, comparison, qualification

The new test suite covers the unchanged identity-only historic baseline, explicit DP opt-in, actual R Karcher-aligned arrays, native R backend type, real warps with monotonicity/endpoints, source-aligned shape/PCA/mean array orientations, 10 geodesic PCA directions, 1-component edge path, original metadata/time/provenance, rotation/scaling options, supported-method guards, and failure on missing/degenerate observations.

The opt-in **real frozen public** `eyetrajectoriespy==1.2.0` + **real Python fdasrsf>=2.7** comparison fits identical phase-shifted curves to verify input/output geometry, time, identifiers and finite real warps/PCA in both actual independent scientific backends. **It deliberately does not claim numerical value equality between the independently implemented optimizers.**

All tests, source review and CI are newly authored; none can be claimed green before actual exact-commit GitHub Actions evidence. Independent full Python contract certifications remain zero. Remaining source-specific subdomains are tracked in `inst/extdata/native_scoped_elastic_submethod_gaps_20261113.csv`.
