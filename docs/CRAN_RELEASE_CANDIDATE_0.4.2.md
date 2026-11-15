# eyetrajectories 0.4.2 — pre-submission audit

## Scope

CRAN package candidate: native R trajectory and functional-analysis tools
with optional Python interoperation. The published Python 1.2 package and
the provisional 508-export ledger are not the release target; no full
scientific source parity or independent certificate is claimed.

## Source and ancestry

- Base package science: exact draft PR #178 head 35c9726cf56eae6e4e86e86e45988cf6564349dc.
- CI fixes validated: fc8f05cd061aa0cd151d4bdd5ae29356cc6fa32f.
- Candidate branch: release/eyetrajectories-0.4.2-rc1-20261116.
- Important: source ancestry depends on stacked unmerged PRs; creating a
  release branch does NOT merge any ancestor into main.
- Separate website PR #180 is out of scope for this source tarball.

## Publication gates

- [ ] Freeze candidate commit after all necessary fixes.
- [ ] R CMD build creates \`eyetrajectories_0.4.2.tar.gz\` and SHA256.
- [ ] Exact same tarball passes R CMD check --as-cran on R-devel, Windows,
      macOS, Ubuntu release and Ubuntu previous-release environments.
- [ ] 0 ERROR and 0 WARNING everywhere; all NOTES reviewed and explained.
- [ ] Real source archive confirms license, size, no binaries and no
      research/CI artifacts accidentally packaged.
- [ ] DESCRIPTION, README, NEWS, examples, external URLs and maintainer
      contact confirmed.
- [ ] R-hub and/or CRAN win-builder external pre-submission checks run when
      practical; any special caveats documented.
- [ ] Stacked ancestry reconciled and release branch proposed for main.
- [ ] Submission approved by maintainer through official CRAN portal and
      verified from the email confirmation.
- [ ] Independent 508-contract certification tracked separately.

Never submit a prior development artifact on the strength of a release-candidate
result. Verify package version and commit provenance on the final tarball.
