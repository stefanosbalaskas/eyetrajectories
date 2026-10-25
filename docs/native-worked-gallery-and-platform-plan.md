# Native worked gallery and platform plan

Run the reproducible native R gallery from the package root:

```r
source("scripts/run_native_worked_gallery.R")
```

It generates synthetic demonstrations of multilevel FPCA and variance
decomposition, participant-cluster mean and randomized contrast bands,
sparse observation support, and descriptive discrete transfer entropy
with circular-shift surrogates. The functional intervals are **experimental
and not calibrated**. Shift sensitivity is **not causal inference**.

Outputs are under `artifacts/native_worked_gallery/`:
`native_worked_figures.pdf` (five graphics), `native_worked_summary.csv`,
`multilevel_variance.csv`, `sparse_observation_support.csv`, `MANIFEST.txt`.

The cross-platform workflow `.github/workflows/R-cross-platform-manual.yaml`
adds four CRAN-style checks on Ubuntu/Windows/macOS and older R on Ubuntu.
It is deliberately **manual only** until private runner admission issue #3
is resolved, and no jobs have run. No claims of Linux/macOS passing.

The scientific inference HOLD remains in place for the 90% simultaneous
bands, following the six-design Monte Carlo undercoverage evidence.
## Optional improved ggplot2 gallery

The new optional script `scripts/run_native_ggplot_gallery.R` sources the
existing base-R gallery in a separate R environment, then redraws its
five figures using `ggplot2`, **without changing fitted estimates**.
Horizontal labels prevent clipping; the transfer-entropy histogram
explicitly prints an observed TE above the surrogate range in its subtitle
(the original base-R plot's observed vertical line could be outside
its displayed limits). Results are stored under
`artifacts/native_ggplot_gallery/`: 5 PNG files, 1 PDF, CSV and manifest.
Run `install.packages('ggplot2')` and
`source('scripts/run_native_ggplot_gallery.R')` from the project root.
The gallery is not part of R CMD check and has not been executed locally.
