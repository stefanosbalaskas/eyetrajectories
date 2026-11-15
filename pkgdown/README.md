# eyetrajectories pkgdown prototype

This is the source for the experimental pkgdown website. Do not publish it as a CRAN or scientific-certification announcement.

- Site configuration: ../_pkgdown.yml
- Homepage: index.md
- Theme adjustments: extra.css
- Supplementary source pages: ../SITE_START.md, ../SITE_METHODS.md, ../SITE_BRIDGE.md, ../SITE_VALIDATION.md
- Rendered output: ../site/ (deliberately **not** docs/, which stores original scientific evidence)
- CI build: ../.github/workflows/pkgdown-prototype.yaml

For local preview, from the R package root:

~~~r
install.packages(c("pkgdown", "pkgload"))
pkgdown::build_site(
  examples = FALSE, devel = TRUE,
  new_process = FALSE, install = FALSE, preview = FALSE
)
pkgdown::preview_site()
~~~

The manual CI workflow creates an artifact; it does not deploy to GitHub Pages. Review its content and links before enabling public publishing.

## Scientific figure atlas

- Page: ../SITE_GALLERY.md
- Generator: ../scripts/build_pkgdown_gallery.R
- Original source: ../scripts/run_native_ggplot_gallery.R (which reuses the native worked gallery)
- Five deterministic synthetic PNGs are produced into pkgdown/assets/gallery before the site builds.
- Figure caveats are displayed adjacent to the graphics, not hidden in release notes.

Generate locally before building the site:

~~~r
install.packages(c("pkgload", "ggplot2", "pkgdown"))
source("scripts/build_pkgdown_gallery.R")
pkgdown::build_site(examples = FALSE, devel = TRUE,
                    new_process = FALSE, install = FALSE, preview = FALSE)
~~~

## Pages deployment (NOT enabled yet)

The staged workflow ../.github/workflows/pkgdown-pages-publish.yaml can only
publish on the repository default branch main and requires a manual workflow
dispatch with confirm_publish=true. It never runs on push or pull requests.

After approving the design and integrating this draft branch into main:

1. Open repository Settings > Pages and select GitHub Actions as the source.
2. Set environment github-pages to allow only main, with reviewers where available.
3. Manually run "Publish approved pkgdown website" on main with confirm_publish=true.
4. Inspect the live site and all figures/reference links.

Until then, Pages is not configured and the build artifacts are PRIVATE to
the GitHub Actions preview workflow. Do not mistake a preview build for a
publicly deployed website.
