# Get started

**Development preview · R package 0.4.1.9000.** This is not a CRAN installation guide or a statement of complete scientific qualification. The site describes the current development branch.

## Install an explicitly selected development revision

Requires R 4.2 or newer. Install from a known branch or commit rather than silently using an unspecified development state:

~~~r
install.packages("remotes")
remotes::install_github(
  "stefanosbalaskas/eyetrajectories",
  ref = "35c9726cf56eae6e4e86e86e45988cf6564349dc",
  dependencies = TRUE
)
library(eyetrajectories)
packageVersion("eyetrajectories")
~~~

The pinned SHA is the source baseline used to create this website prototype. If you choose a newer commit, recheck the package's tests, examples, supported inputs and scientific limitations. Installing from GitHub may require build tools and optional R dependencies.

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
