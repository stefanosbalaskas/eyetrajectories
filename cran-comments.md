## eyetrajectories 0.4.2 — proposed first CRAN submission

**Status: release candidate; not yet submitted to CRAN.**

The package contains native R trajectory/functional-analysis methods and an
optional Python interoperability interface. No claim of 508 independently
certified Python-parity source contracts is made. This proposal does not
claim calibrated uncertainty or causal conclusions for experimental models.

### Qualification evidence before final review

- The 0.4.1.9000 development matrix passed (Windows, macOS, Linux release
  and oldrel-1) at fc8f05cd061aa0cd151d4bdd5ae29356cc6fa32f.
- The 0.4.2 source tarball was built and inspected at release-candidate
  commit c0fad8d0ce01ec4bc00475878d68d8be575a7788. The archive is
  approximately 1.49 MB and contains no compiled executable binary or
  excluded research/CI files.
- Windows release, macOS release, Ubuntu release and Ubuntu oldrel-1
  passed R CMD check --as-cran on the same source archive with **0 errors
  and 0 warnings** at GitHub run 43776369818.
- V8 was available in these candidate checks, eliminating the earlier
  missing-V8 mathematical-rendering NOTE.
- An expected first-submission NOTE remains. Optional Markdown/HTML
  validation NOTES on the first candidate run were caused by missing or
  outdated Pandoc/HTML Tidy; the next qualification run explicitly
  installs those tools.
- R-devel exact-tarball qualification and the *final corrected* source
  tarball results remain pending at the time of this document update.

CRAN submission will only follow the final check evidence, release-source
integration review and maintainer authorization. Do not submit this
historical candidate archive while subsequent fixes are in progress.
