# Scientific figure gallery

<p class="et-eyebrow">FIVE REPRODUCIBLE NATIVE R FIGURES · SYNTHETIC DATA</p>

Explore how functional trajectories, multilevel variability, observation support and nonlinear diagnostics are represented. These are deterministic synthetic examples produced by the actual R research package and its existing figure scripts—not empirical participant recordings, proof of Python numerical parity, or evidence of calibrated statistical inference.

<div class="et-gallery-grid">
  <figure class="et-figure et-figure-wide">
    <a href="gallery/01_multilevel_variance.png"><img loading="lazy" src="gallery/01_multilevel_variance.png" alt="Descriptive between-participant and within-participant integrated variance bars from synthetic multilevel functional data." /></a>
    <figcaption><span class="et-figure-tag">01 / MULTILEVEL FPCA</span><h3>Between- and within-participant variation</h3><p>Integrated sample variance by stratum from 20 synthetic participants. Descriptive decomposition, <strong>not inferential variance-component estimation</strong>.</p><a href="gallery/01_multilevel_variance.png">Open full-resolution figure ↗</a></figcaption>
  </figure>
  <figure class="et-figure">
    <a href="gallery/02_participant_mean_band.png"><img loading="lazy" src="gallery/02_participant_mean_band.png" alt="Estimated participant-level mean trajectory over normalized time with a shaded experimental simultaneous bootstrap band." /></a>
    <figcaption><span class="et-figure-tag">02 / FUNCTIONAL UNCERTAINTY</span><h3>Participant-level mean band</h3><p>Participant-cluster bootstrap from simulated trajectories. Experimental simultaneous bands have <strong>no general coverage guarantee</strong>.</p><a href="gallery/02_participant_mean_band.png">Open full-resolution figure ↗</a></figcaption>
  </figure>
  <figure class="et-figure">
    <a href="gallery/03_group_contrast_band.png"><img loading="lazy" src="gallery/03_group_contrast_band.png" alt="Between-group functional contrast and experimental uncertainty ribbon over time, with a zero reference line." /></a>
    <figcaption><span class="et-figure-tag">03 / GROUP CONTRASTS</span><h3>Time-varying group difference</h3><p>Participant-resampled comparison between two simulated groups. Interpret the ribbon as experimental, not as validated inferential coverage.</p><a href="gallery/03_group_contrast_band.png">Open full-resolution figure ↗</a></figcaption>
  </figure>
  <figure class="et-figure">
    <a href="gallery/04_sparse_support.png"><img loading="lazy" src="gallery/04_sparse_support.png" alt="Fractions of simulated sparse trajectories observed across ten ordered time-support bins." /></a>
    <figcaption><span class="et-figure-tag">04 / SPARSE DATA</span><h3>Observed sampling support</h3><p>Coverage across ten bins from 35 synthetic sparse curves. Describes observed sampling only, <strong>without interpolation or imputation</strong>.</p><a href="gallery/04_sparse_support.png">Open full-resolution figure ↗</a></figcaption>
  </figure>
  <figure class="et-figure">
    <a href="gallery/05_transfer_entropy_surrogates.png"><img loading="lazy" src="gallery/05_transfer_entropy_surrogates.png" alt="Histogram of circular-shift surrogate transfer-entropy values, with the observed statistic stated separately." /></a>
    <figcaption><span class="et-figure-tag">05 / NONLINEAR ANALYSIS</span><h3>Transfer-entropy shift sensitivity</h3><p>Surrogate statistics from a coupled synthetic binary sequence. The observed value can be beyond the histogram limits; <strong>these results are not causal evidence</strong>.</p><a href="gallery/05_transfer_entropy_surrogates.png">Open full-resolution figure ↗</a></figcaption>
  </figure>
</div>

## Fully reproducible source

These images are generated from the existing package-owned scripts [run_native_ggplot_gallery.R](https://github.com/stefanosbalaskas/eyetrajectories/blob/feat/pkgdown-scientific-site-20261116/scripts/run_native_ggplot_gallery.R) and [run_native_worked_gallery.R](https://github.com/stefanosbalaskas/eyetrajectories/blob/feat/pkgdown-scientific-site-20261116/scripts/run_native_worked_gallery.R), with fixed seeds and a common synthetic dataset. To generate the PNG files for the site, from the R package root:

~~~r
install.packages(c("pkgload", "ggplot2"))
source("scripts/build_pkgdown_gallery.R")
~~~

The source also creates CSV summaries, a PDF figure collection and a qualification manifest under the build-ignored \`artifacts/native_ggplot_gallery/\` folder. The pkgdown site copies only the illustrative PNG files. The gallery does not change scientific estimators or sign off any 508-export source contracts.

For methods and caveats consult [Methods](SITE_METHODS.html) and [Validation](SITE_VALIDATION.html).
