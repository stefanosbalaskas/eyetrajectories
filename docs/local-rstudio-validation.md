# Local RStudio development and scientific verification

You can keep this GitHub repository **private**. No hosted GitHub Actions
minutes are necessary for testing package source on your own Windows PC.

## Clone once on Windows

Use GitHub Desktop: File → Clone repository → GitHub.com →
stefanosbalaskas/eyetrajectories → choose local path → Clone.

Alternatively, use an authenticated Git terminal:

```text
git clone https://github.com/stefanosbalaskas/eyetrajectories.git
cd eyetrajectories
```

Do not paste access tokens, passwords, or credentials into ChatGPT.

## One-time R installation

Open RStudio with the cloned repository as the current working directory:

```r
install.packages(c("testthat", "pkgload", "rcmdcheck", "reticulate"))
# Optional R-native advanced-method integration:
# install.packages("fdapace")
# install.packages("refund")
```

The optional packages can bring larger dependencies; native core tests can
start without them. Tests that require an unavailable Suggested dependency
are designed to skip that component.

## Run R tests and package check locally

From RStudio, with working directory at the repository root:

```r
source("scripts/local_qualification.R")
```

Or from PowerShell in the repository root:

```powershell
Rscript scripts/local_qualification.R
```

The script performs actual native R testthat execution, then R CMD check.
It deliberately does **not** publish, install arbitrary Python code, make
the repository public or modify GitHub billing.

Reports are written to a sibling directory named
**eyetrajectories_local_qualification** outside the repository, including
SUMMARY.txt, testthat.txt, R-CMD-check.txt, sessionInfo.txt and manifest.txt.

Send the failure excerpts or those reports back in this conversation. Package
source can be fixed through the existing connected GitHub repository and
tested again locally.

## Later: optional Python integration

The reticulate Phase 1 tests require the explicitly pinned Python backend
and a compatible interpreter. Run those only after core native R checks are
understood. The source has an independent Python reference script but its
numerical parity is not yet release-qualified.

## GitHub Actions status

Hosted Actions jobs currently fail before runner allocation, including an
echo-only smoke test:
https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40188285732

Four workflows were temporarily changed to **workflow_dispatch only** to
stop further automatic failures. This is a temporary measure, not a passing
CI state. Once the repository's private-runner issue is corrected, manually
dispatch the smoke workflow, then restore push/pull_request triggers and
run the full matrix.

Public visibility is not required. As an alternative to local execution,
a private self-hosted runner may be set up on a dedicated trusted machine;
that requires appropriate security and maintenance controls.
