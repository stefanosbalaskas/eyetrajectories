# Scientific figure gallery

FIVE REPRODUCIBLE NATIVE R FIGURES · SYNTHETIC DATA

Explore how functional trajectories, multilevel variability, observation
support and nonlinear diagnostics are represented. These are
deterministic synthetic examples produced by the actual R research
package and its existing figure scripts—not empirical participant
recordings, proof of Python numerical parity, or evidence of calibrated
statistical inference.

[![Descriptive between-participant and within-participant integrated
variance bars from synthetic multilevel functional
data.](gallery/01_multilevel_variance.png)](https://stefanosbalaskas.github.io/eyetrajectories/gallery/01_multilevel_variance.png)

01 / MULTILEVEL FPCA

### Between- and within-participant variation

Integrated sample variance by stratum from 20 synthetic participants.
Descriptive decomposition, **not inferential variance-component
estimation**.

[Open full-resolution figure
↗](https://stefanosbalaskas.github.io/eyetrajectories/gallery/01_multilevel_variance.png)

[![Estimated participant-level mean trajectory over normalized time with
a shaded experimental simultaneous bootstrap
band.](gallery/02_participant_mean_band.png)](https://stefanosbalaskas.github.io/eyetrajectories/gallery/02_participant_mean_band.png)

02 / FUNCTIONAL UNCERTAINTY

### Participant-level mean band

Participant-cluster bootstrap from simulated trajectories. Experimental
simultaneous bands have **no general coverage guarantee**.

[Open full-resolution figure
↗](https://stefanosbalaskas.github.io/eyetrajectories/gallery/02_participant_mean_band.png)

[![Between-group functional contrast and experimental uncertainty ribbon
over time, with a zero reference
line.](gallery/03_group_contrast_band.png)](https://stefanosbalaskas.github.io/eyetrajectories/gallery/03_group_contrast_band.png)

03 / GROUP CONTRASTS

### Time-varying group difference

Participant-resampled comparison between two simulated groups. Interpret
the ribbon as experimental, not as validated inferential coverage.

[Open full-resolution figure
↗](https://stefanosbalaskas.github.io/eyetrajectories/gallery/03_group_contrast_band.png)

[![Fractions of simulated sparse trajectories observed across ten
ordered time-support
bins.](gallery/04_sparse_support.png)](https://stefanosbalaskas.github.io/eyetrajectories/gallery/04_sparse_support.png)

04 / SPARSE DATA

### Observed sampling support

Coverage across ten bins from 35 synthetic sparse curves. Describes
observed sampling only, **without interpolation or imputation**.

[Open full-resolution figure
↗](https://stefanosbalaskas.github.io/eyetrajectories/gallery/04_sparse_support.png)

[![Histogram of circular-shift surrogate transfer-entropy values, with
the observed statistic stated
separately.](gallery/05_transfer_entropy_surrogates.png)](https://stefanosbalaskas.github.io/eyetrajectories/gallery/05_transfer_entropy_surrogates.png)

05 / NONLINEAR ANALYSIS

### Transfer-entropy shift sensitivity

Surrogate statistics from a coupled synthetic binary sequence. The
observed value can be beyond the histogram limits; **these results are
not causal evidence**.

[Open full-resolution figure
↗](https://stefanosbalaskas.github.io/eyetrajectories/gallery/05_transfer_entropy_surrogates.png)

## Fully reproducible source

These images are generated from the existing package-owned scripts
[run_native_ggplot_gallery.R](https://github.com/stefanosbalaskas/eyetrajectories/blob/feat/pkgdown-scientific-site-20261116/scripts/run_native_ggplot_gallery.R)
and
[run_native_worked_gallery.R](https://github.com/stefanosbalaskas/eyetrajectories/blob/feat/pkgdown-scientific-site-20261116/scripts/run_native_worked_gallery.R),
with fixed seeds and a common synthetic dataset. To generate the PNG
files for the site, from the R package root:

``` r
install.packages(c("pkgload", "ggplot2"))
source("scripts/build_pkgdown_gallery.R")
```

The source also creates CSV summaries, a PDF figure collection and a
qualification manifest under the build-ignored
\`artifacts/native_ggplot_gallery/\` folder. The pkgdown site copies
only the illustrative PNG files. The gallery does not change scientific
estimators or sign off any 508-export source contracts.

For methods and caveats consult
[Methods](https://stefanosbalaskas.github.io/eyetrajectories/SITE_METHODS.md)
and
[Validation](https://stefanosbalaskas.github.io/eyetrajectories/SITE_VALIDATION.md).
