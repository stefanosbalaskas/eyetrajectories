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
