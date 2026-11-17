# Synthetic-only local qualification runner tests. No human gaze data included.
Sys.setenv(ET_EIGHT_ARCHIVE_NO_AUTORUN = "true")
source("scripts/qualify_onestop_eight_archives.R", local = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE)) stop("pkgload required")
pkgload::load_all(".", quiet = TRUE)

stopifnot(length(.et8_stems) == 8L)
columns <- c("participant_id", "TRIAL_INDEX", "trial_index",
             "CURRENT_FIX_START", "CURRENT_FIX_X", "CURRENT_FIX_Y")
picked <- .et8_columns(columns)
stopifnot(identical(picked$trial, "TRIAL_INDEX"))
stopifnot(identical(picked$x, "CURRENT_FIX_X"))
stopifnot(identical(picked$y, "CURRENT_FIX_Y"))

# Regression: the real OneStop ZIP can have multiple entries, including
# metadata. Every predicate must be vectorized and preserve member order.
member_names <- c("fixations_Paragraph_repeated.csv",
                  "__MACOSX/._fixations_Paragraph_repeated.csv",
                  "folder/", "notes.txt", "._sidecar.csv",
                  "subdir/scans.ASC", "other.tsv")
stopifnot(identical(.et8_supported_members(member_names),
                     c(TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE)))
stopifnot(identical(.et8_supported_members(character()), logical()))


dat <- do.call(rbind, lapply(seq_len(5L), function(i) {
  t <- seq(0, 2, length.out = 30L)
  data.frame(participant_id = paste0("p", i),
             TRIAL_INDEX = paste0("trial_", i),
             CURRENT_FIX_START = as.character(round(1000*t)),
             CURRENT_FIX_X = as.character(100 + 40*t + i^2 +
               3*sin(2*pi*t/(2 + i / 5))),
             CURRENT_FIX_Y = as.character(200 + 12*t + 2*i +
               7*cos(2*pi*t/(2 + i / 3))),
             check.names = FALSE, stringsAsFactors = FALSE)
}))
probe <- list(status = "SAMPLED_SCHEMA", df = dat, roles = picked)
result <- .et8_numerical(probe, package_available = TRUE)
if (!identical(result$status, "NUMERICAL_SAMPLE_PASS")) {
  stop("Numerical contract test failed: ", result$status, " ", result$reason)
}
stopifnot(result$curves == 5L, result$independent_pairs >= 10L,
          result$max_l2_abs_error <= result$l2_tolerance,
          result$fpca_ratio_abs_error <= 1e-9)
stopifnot(identical(.et8_numerical(list(df = dat, roles = list()),
                                   package_available = TRUE)$status, "NOT_RUN"))

# End-to-end zip path if the runner provides a 'zip' binary.
if (nzchar(Sys.which("zip"))) {
  root <- tempfile("et8_test_")
  dir.create(root)
  file <- file.path(root, "fixations_Paragraph_repeated.csv")
  utils::write.csv(dat, file, row.names = FALSE)
  # Include an AppleDouble-style CSV and an unrelated note in the actual ZIP.
  # The member enumeration must ignore these while processing the real CSV.
  dir.create(file.path(root, "__MACOSX"))
  writeLines("metadata placeholder",
    file.path(root, "__MACOSX", "._fixations_Paragraph_repeated.csv"))
  writeLines("unrelated note", file.path(root, "notes.txt"))
  old <- getwd()
  setwd(root)
  utils::zip("fixations_Paragraph_repeated.csv.zip",
             files = c(basename(file),
               "__MACOSX/._fixations_Paragraph_repeated.csv",
               "notes.txt"), flags = "-q")
  dir.create("asc_files")
  writeLines(c("MSG 1 START", "SFIX R 5", "1 50 80 100", "EFIX R 5 10 5 50 80"),
             file.path("asc_files", "01.asc"))
  utils::zip("asc_files.zip", files = "asc_files/01.asc", flags = "-q")
  setwd(old)
  source_archive <- file.path(root, "fixations_Paragraph_repeated.csv.zip")
  before <- unname(tools::md5sum(source_archive))
  done <- et8_run_audit(root, max_rows = 500L, max_members = 2L)
  after <- unname(tools::md5sum(source_archive))
  stopifnot(identical(before, after))
  out <- done$output
  stopifnot(file.exists(file.path(out, "archive_inventory.csv")),
            file.exists(file.path(out, "member_schema.csv")),
            file.exists(file.path(out, "numeric_checks.csv")),
            file.exists(file.path(out, "VALIDATION_SUMMARY.md")))
  inventory <- utils::read.csv(file.path(out, "archive_inventory.csv"),
                              stringsAsFactors = FALSE)
  row <- inventory[inventory$archive == "fixations_Paragraph_repeated.csv.zip", ]
  stopifnot(nrow(row) == 1L, row$valid_members == 1L,
            row$sampled_members == 1L)
  schema <- utils::read.csv(file.path(out, "member_schema.csv"),
                           stringsAsFactors = FALSE)
  stopifnot(nrow(schema) == 2L,
            "fixations_Paragraph_repeated.csv" %in% schema$member,
            "asc_files/01.asc" %in% schema$member)
  checks <- utils::read.csv(file.path(out, "numeric_checks.csv"),
                            stringsAsFactors = FALSE)
  status <- checks$status[checks$archive ==
                          "fixations_Paragraph_repeated.csv.zip"]
  if (!identical(status, "NUMERICAL_SAMPLE_PASS")) {
    stop("ZIP end-to-end failed: ", status,
         "; see ", file.path(out, "member_schema.csv"))
  }
  stopifnot(sum(checks$status == "NOT_RUN") == 7L)
  asc_reason <- checks$reason[checks$archive == "asc_files.zip"]
  stopifnot(length(asc_reason) == 1L,
            grepl("ASC event-line members sampled", asc_reason, fixed = TRUE))
  cat("EIGHT_ARCHIVE_SYNTHETIC_ZIP_END_TO_END_PASS\n")
} else {
  cat("EIGHT_ARCHIVE_SYNTHETIC_ZIP_SKIPPED_NO_ZIP_BINARY\n")
}
cat("EIGHT_ARCHIVE_NUMERICAL_CONTRACT_TESTS_PASS\n")
