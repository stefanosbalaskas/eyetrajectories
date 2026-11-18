# v0.4.3-derived L2 release candidate — qualification and remaining gate

**Scientific release decision: HOLD** until the exact candidate passes Windows, Linux and macOS source-archive checks and the locally executed real OneStop benchmark. Published v0.4.3 and its Zenodo DOI remain immutable.

## Windows PDF-manual evidence (18 November 2026)

Archived failed Windows check run 44268599200: Windows R 4.6.2, development 0.4.3.9000. Results: 0 errors, 1 warning (indexed PDF manual), 4 notes; testthat native tests and package installation passed. The Rdlatex log showed a written PDF, no conventional fatal TeX-error line, numerous line-overflow messages and no Rd2.ind. PDF generation **without the index** passed. This warrants testing makeindex but does not establish that line overflow caused the warning or that the indexer is the only possible cause.

The earlier check was on a development checkout; it also reported a non-standard top-level benchmarks NOTE. That is not equivalent to checking the distributable source archive.

## Code and workflow qualification improvements

1. The .Rbuildignore file excludes benchmarks, whose qualification harness scripts must not be included in the released package.
2. The full CRAN CI installs and independently smoke-tests makeindex, using a relative .idx path from inside a temporary working directory. TeX Live openout_any=p may refuse absolute-path output creation.
3. The CI now builds a proper source tarball with pkgbuild::build and checks that exact archive using rcmdcheck --as-cran; it verifies no benchmarks files were packaged and records a checksum.
4. Actual errors/warnings continue to fail qualification. Explanatory notes remain visible, not suppressed.
5. The real installed package L2 comparison is independent from synthetic tests and release packaging.

## Exact installed real OneStop comparison: local RStudio command

The qualification program is at benchmarks/rc_l2_onestop_real_release_audit.R. Set SHA to the **complete, immutable, CI-qualified, forty-character candidate commit**, then execute the following R code:

    root <- file.path(Sys.getenv("USERPROFILE"),"Downloads","eyetrajectoriesValidation")
    sha <- "<QUALIFIED_40_CHARACTER_CANDIDATE_SHA>"
    script <- file.path(root,"rc_l2_onestop_real_release_audit.R")
    download.file(paste0(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/",
      sha,"/benchmarks/rc_l2_onestop_real_release_audit.R"
    ),script,mode="wb")
    source(script)
    result <- etr_qualify_real_onestop_l2(root=root,candidate_sha=sha)
    print(result$summary)
    cat(result$folder)

The script expects the previously authenticated OneStop archive fixations_Paragraph_repeated.csv.zip (MD5 650d93a8c73af6a9b3ca19a7c4e542fb). It aborts if the ZIP checksum changes or fewer than 1,000 eligible trajectories are available. The fixed 200,000-row cap must not be reached.

The program installs v0.4.3 and the exact SHA-pinned development candidate into **separate R libraries**. It executes etr_pairwise_l2 in fresh Rscript subprocesses, on the **same** 250/500/1000 curve × 64/128 grid input objects, with repeated timing and an independent trapezoid numerical oracle. It preserves the source ZIP and uses only opaque trajectory labels in derived matrices.

Only de-identified aggregate CSV, numerical checks, Git SHA/MD5 provenance and the session report should be shared. The source CSV/ZIP, intermediate derived per-curve inputs and distance matrices remain locally stored. Optional process RSS from bench is a since-start process high-water measurement, not an operation-specific allocation measurement; unavailable data must remain NA.

**Scope limitation:** OneStop repeated-fixation-level analysis with declared common-grid interpolation is not raw 1000 Hz eye-tracker validation or general scientific calibration of the entire 904-interface API.

No new version tag, CRAN submission or Zenodo archive is authorized by a successful synthetic benchmark alone.
