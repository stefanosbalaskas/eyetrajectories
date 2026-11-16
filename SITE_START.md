# Get started

**Stable GitHub release · version 0.4.3.** Not yet published on CRAN. Advanced methods retain documented scientific limitations.

## Install the stable GitHub v0.4.3 release

Requires R 4.2 or newer. Install from a known branch or commit rather than silently using an unspecified development state:

~~~r
install.packages("remotes")
remotes::install_github(
  "stefanosbalaskas/eyetrajectories",
  ref = "v0.4.3",
  dependencies = TRUE
)
library(eyetrajectories)
packageVersion("eyetrajectories")
~~~

The exact qualified source archive is available from the [stable GitHub release](https://github.com/stefanosbalaskas/eyetrajectories/releases/tag/v0.4.3); verify SHA-256 `38f7b8eb05c71c3a0c4c266cc590b9afdb73906b0d9412cf52185523f649da5e`.

## Start with the native R API

Native R methods do not require Python to initialize. The exported functions and examples are documented in the [function reference](reference/index.html); a useful starting point is the trajectory construction, validation and functional decomposition family.

~~~r
library(eyetrajectories)

# Inspect the native trajectory constructor and its input contract.
help("etr_trajectory_set", package = "eyetrajectories")

# Explore the documented native principal component analysis.
help("etr_fit_mfpca", package = "eyetrajectories")
~~~

Read the help topic before selecting coordinate-system assumptions, units, missing-data policies and estimation settings. These commands access documentation; they do not execute analyses or imply independent scientific certification.

## Optional published Python 1.2 backend

For explicitly Python-backed operations, install the matching Python version and configure reticulate to use it. Read [Python bridge](SITE_BRIDGE.html) for the procedure and for the distinction between wrapper availability and native R parity.

## Navigate the site

- [Methods](SITE_METHODS.html): which methods and assumptions belong to which analysis family.
- [Reference](reference/index.html): auto-generated R help pages.
- [Validation](SITE_VALIDATION.html): evidence categories, tests and limits on scientific claims.
- [GitHub repository](https://github.com/stefanosbalaskas/eyetrajectories): exact code, issues and current development activity.
