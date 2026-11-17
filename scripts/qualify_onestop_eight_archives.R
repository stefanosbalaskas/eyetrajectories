# eyetrajectories — eight-archive real-gaze evidence intake (R only)
# Author-side local audit. Does not certify scientific inference.
# No input ZIP extraction, no source modification, no uploading participant data.
#
# Run in RStudio: source(file.choose()) and select this downloaded script.
# Optional: Sys.setenv(ET_EIGHT_ARCHIVE_ROOT = "C:/path/to/eyetrajectoriesValidation")
# To load definitions without running: Sys.setenv(ET_EIGHT_ARCHIVE_NO_AUTORUN = "true")
#
# Outputs: archive_inventory.csv, member_schema.csv, numeric_checks.csv,
#           VALIDATION_SUMMARY.md, run_log.txt, R_session_info.txt.
#
# Full-file completeness cannot be inferred from a capped sample.
# For larger ZIPs, SHA-256/MD5 is deliberately opt-in via
# Sys.setenv(ET_EIGHT_ARCHIVE_HASH_LARGE = "true").
#
# Reproducibility note: package tests below use only source fields whose
# semantics are identified in a known fixation-level input contract.

.et8_stems <- c(
  "fixations_Paragraph_repeated.csv",
  "fixations_Paragraph_ordinary.csv",
  "ia_Paragraph_repeated.csv",
  "ia_Paragraph_ordinary.csv",
  "scanpaths", "scanpaths_merged", "fixations", "asc_files"
)

.et8_role <- function(fields, candidates, pattern) {
  for (name in candidates) if (name %in% fields) return(name)
  hit <- grep(pattern, fields, value = TRUE, ignore.case = TRUE)
  if (length(hit) == 1L) hit else ""
}

.et8_columns <- function(fields) {
  list(
    participant = .et8_role(fields,
      c("participant_id", "PARTICIPANT_ID", "participant", "subject_id", "RECORDING_SESSION_LABEL"),
      "^(participant|subject|recording_session).*(id|label)?$"),
    trial = .et8_role(fields,
      c("TRIAL_INDEX", "trial_id", "TRIAL_ID", "trial", "trial_index"),
      "^(trial|trial_?(id|index|number))$"),
    time = .et8_role(fields,
      c("CURRENT_FIX_START", "CURRENT_FIX_START_TIME", "fixation_start", "start_time", "timestamp", "time"),
      "(fix.*start|timestamp|^time$)"),
    x = .et8_role(fields,
      c("CURRENT_FIX_X", "fix_x", "fixation_x", "x"),
      "(^x$|^fix.*_x$|^current_fix_x$)"),
    y = .et8_role(fields,
      c("CURRENT_FIX_Y", "fix_y", "fixation_y", "y"),
      "(^y$|^fix.*_y$|^current_fix_y$)")
  )
}

.et8_safe <- function(expr) {
  tryCatch(expr, error = function(e) structure(
    list(message = conditionMessage(e)), class = "et8_error"))
}

.et8_num <- function(x) {
  suppressWarnings(as.numeric(gsub(",", ".", trimws(as.character(x)), fixed = TRUE)))
}

.et8_md5 <- function(path, allow_large = FALSE) {
  n <- file.info(path)$size
  if (!is.finite(n)) return("FILE_UNREADABLE")
  if (n > 100 * 1024^2 && !isTRUE(allow_large)) return("NOT_HASHED_LARGE_ARCHIVE")
  z <- .et8_safe(unname(tools::md5sum(path)))
  if (inherits(z, "et8_error")) paste0("HASH_ERROR: ", z$message) else as.character(z)
}

.et8_scan_member <- function(zip, member, max_rows = 30000L) {
  ext <- tolower(tools::file_ext(member))
  if (ext == "asc") {
    con <- .et8_safe(unz(zip, member, open = "r"))
    if (inherits(con, "et8_error")) return(list(
      type = "ASC", status = "READ_ERROR", n = 0L, cols = character(),
      roles = list(), df = NULL, diagnostic = con$message))
    on.exit(close(con), add = TRUE)
    lines <- .et8_safe(readLines(con, n = 1000L, warn = FALSE))
    if (inherits(lines, "et8_error")) return(list(
      type = "ASC", status = "READ_ERROR", n = 0L, cols = character(),
      roles = list(), df = NULL, diagnostic = lines$message))
    # Only aggregated counts are retained: no raw trial events or gaze samples.
    classes <- c(
      "MSG" = sum(grepl("^MSG[[:space:]]", lines)),
      "EFIX" = sum(grepl("^EFIX[[:space:]]", lines)),
      "SFIX" = sum(grepl("^SFIX[[:space:]]", lines)),
      "numeric_lines" = sum(grepl("^[[:space:]]*[0-9]+[[:space:]]", lines))
    )
    return(list(type = "ASC", status = "RAW_SOURCE_SAMPLE_ONLY",
      n = length(lines), cols = character(), roles = list(), df = NULL,
      diagnostic = paste(names(classes), classes, collapse = "; ")))
  }
  if (!(ext %in% c("csv", "tsv"))) {
    return(list(type = ext, status = "FORMAT_NOT_SUPPORTED",
      n = 0L, cols = character(), roles = list(), df = NULL, diagnostic = ""))
  }
  con <- .et8_safe(unz(zip, member, open = "r"))
  if (inherits(con, "et8_error")) return(list(
    type = toupper(ext), status = "READ_ERROR", n = 0L, cols = character(),
    roles = list(), df = NULL, diagnostic = con$message))
  on.exit(close(con), add = TRUE)

  separator <- if (ext == "tsv") "\t" else ","
  hdr <- .et8_safe(readLines(con, n = 1L, warn = FALSE))
  if (inherits(hdr, "et8_error") || length(hdr) != 1L) {
    return(list(type = toupper(ext), status = "HEADER_ERROR", n = 0L,
      cols = character(), roles = list(), df = NULL, diagnostic = "Header unreadable"))
  }
  hdr <- sub("^\ufeff", "", hdr)
  schema <- .et8_safe(utils::read.table(text = hdr, sep = separator,
    header = TRUE, nrows = 0L, check.names = FALSE, stringsAsFactors = FALSE,
    quote = '"', comment.char = "", fill = TRUE))
  if (inherits(schema, "et8_error")) {
    return(list(type = toupper(ext), status = "HEADER_ERROR", n = 0L,
      cols = character(), roles = list(), df = NULL, diagnostic = schema$message))
  }
  fields <- names(schema)
  if (!length(fields)) {
    return(list(type = toupper(ext), status = "HEADER_ERROR", n = 0L,
      cols = character(), roles = list(), df = NULL, diagnostic = "No columns"))
  }
  roles <- .et8_columns(fields)
  needed <- unique(unlist(roles, use.names = FALSE))
  needed <- needed[nzchar(needed)]
  # A schema-only sample is deliberately not interpreted as numeric evidence.
  if (!length(needed)) needed <- fields[seq_len(min(6L, length(fields)))]
  classes <- ifelse(fields %in% needed, "character", "NULL")
  dat <- .et8_safe(utils::read.table(con, sep = separator, header = FALSE,
    col.names = fields, colClasses = classes, nrows = max_rows,
    check.names = FALSE, stringsAsFactors = FALSE, quote = '"',
    comment.char = "", fill = TRUE, blank.lines.skip = TRUE))
  if (inherits(dat, "et8_error")) {
    return(list(type = toupper(ext), status = "PARSE_ERROR", n = 0L,
      cols = fields, roles = roles, df = NULL, diagnostic = dat$message))
  }
  list(type = toupper(ext), status = "SAMPLED_SCHEMA", n = nrow(dat),
       cols = fields, roles = roles, df = dat,
       diagnostic = if (nrow(dat) >= max_rows) "ROW_CAP_REACHED" else "EOF_BEFORE_ROW_CAP")
}

.et8_numerical <- function(probe, package_available, max_curves = 64L) {
  empty <- list(status = "NOT_RUN", reason = "", curves = 0L,
    grid = 64L, independent_pairs = 0L, max_l2_abs_error = NA_real_,
    l2_tolerance = NA_real_, symmetry_error = NA_real_,
    fpca_ratio_abs_error = NA_real_, valid_sample_rows = NA_integer_,
    sampled_trials = NA_integer_, eligible_sampled_trials = NA_integer_,
    duplicate_timestamps = NA_integer_)
  if (!isTRUE(package_available)) {
    empty$reason <- "eyetrajectories package not installed"
    return(empty)
  }
  if (is.null(probe$df) || !is.data.frame(probe$df)) {
    empty$reason <- "No usable tabular data sample"
    return(empty)
  }
  roles <- probe$roles
  if (!all(c("participant","trial","time","x","y") %in% names(roles)) ||
      any(!nzchar(unlist(roles[c("participant","trial","time","x","y")])))) {
    empty$reason <- "No verified participant/trial/time/x/y schema; schema-only"
    return(empty)
  }
  dat <- probe$df
  want <- unlist(roles[c("participant","trial","time","x","y")])
  if (!all(want %in% names(dat))) {
    empty$reason <- "Required columns were not read"
    return(empty)
  }
  p <- as.character(dat[[roles$participant]])
  tr <- as.character(dat[[roles$trial]])
  tm <- .et8_num(dat[[roles$time]])
  xx <- .et8_num(dat[[roles$x]])
  yy <- .et8_num(dat[[roles$y]])
  good <- is.finite(tm) & is.finite(xx) & is.finite(yy) &
    !is.na(p) & nzchar(p) & !is.na(tr) & nzchar(tr)
  empty$valid_sample_rows <- sum(good)
  if (sum(good) < 48L) {
    empty$reason <- "Fewer than 48 complete records in capped sample"
    return(empty)
  }
  keys <- paste(p[good], tr[good], sep = "::")
  ix <- which(good)
  groups <- split(ix, keys)
  empty$sampled_trials <- length(groups)
  eligible <- list()
  duplicate_count <- 0L
  for (key in sort(names(groups))) {
    ids <- groups[[key]]
    t0 <- tm[ids]
    order0 <- order(t0, seq_along(t0))
    ids <- ids[order0]
    t0 <- t0[order0]
    duplicate_count <- duplicate_count + sum(duplicated(t0))
    if (length(ids) >= 24L && length(unique(t0)) >= 24L && diff(range(t0)) > 0) {
      ids <- ids[!duplicated(tm[ids])]
      eligible[[key]] <- ids
    }
  }
  empty$duplicate_timestamps <- duplicate_count
  empty$eligible_sampled_trials <- length(eligible)
  if (length(eligible) < 3L) {
    empty$reason <- "Insufficient eligible complete trajectories in capped sample"
    return(empty)
  }
  chosen <- head(names(eligible), max_curves)
  grid <- seq(0, 1, length.out = 64L)
  values <- array(NA_real_, dim = c(length(chosen), length(grid), 2L))
  for (i in seq_along(chosen)) {
    ids <- eligible[[chosen[i]]]
    times <- tm[ids]
    normalized <- (times - min(times)) / (max(times) - min(times))
    values[i, , 1] <- stats::approx(normalized, xx[ids], xout = grid,
                                    rule = 2, ties = "ordered")$y
    values[i, , 2] <- stats::approx(normalized, yy[ids], xout = grid,
                                    rule = 2, ties = "ordered")$y
  }
  if (!all(is.finite(values))) {
    empty$reason <- "Interpolation did not produce finite curves"
    return(empty)
  }
  ids <- sprintf("sample_%04d", seq_along(chosen))
  result <- .et8_safe({
    set <- eyetrajectories::etr_trajectory_set(
      time = grid, values = values, curve_ids = ids,
      dimension_names = c("x", "y"), coordinate_system = "pixels",
      time_unit = "normalized_trial_time")
    eyetrajectories::etr_validate(set, require_complete = TRUE)
    distances <- eyetrajectories::etr_pairwise_l2(set)

    # Independent trapezoidal integration for 16 deterministic pairs.
    delta <- diff(grid)
    weights <- c(delta[1L] / 2,
                 (delta[-1L] + delta[-length(delta)]) / 2,
                 delta[length(delta)] / 2)
    pairs <- utils::combn(seq_len(min(length(chosen), 8L)), 2L)
    pairs <- pairs[, seq_len(min(ncol(pairs), 16L)), drop = FALSE]
    err <- vapply(seq_len(ncol(pairs)), function(k) {
      i <- pairs[1L, k]
      j <- pairs[2L, k]
      dx <- values[i, , 1] - values[j, , 1]
      dy <- values[i, , 2] - values[j, , 2]
      reference <- sqrt(sum(weights * (dx^2 + dy^2)))
      abs(reference - distances[i, j])
    }, numeric(1))
    max_error <- max(err)
    tolerance <- 1e-7 + 1e-9 * max(abs(distances))
    symmetry <- max(abs(distances - t(distances)))

    # Separately construct an independent weighted SVD matrix for MFPCA.
    n <- length(chosen)
    mat <- matrix(0, n, 2L * length(grid))
    for (j in seq_len(2L)) for (t in seq_along(grid)) {
      col <- values[, t, j]
      mat[, (t - 1L) * 2L + j] <- (col - mean(col)) * sqrt(weights[t])
    }
    singular <- base::svd(mat, nu = 0L, nv = 0L)$d
    ratio <- singular^2 / sum(singular^2)
    fit <- eyetrajectories::etr_fit_mfpca(set, n_components = 1L)
    fpca_error <- abs(ratio[1L] - fit$explained_variance_ratio[1L])
    pass <- is.finite(max_error) && is.finite(fpca_error) &&
      max_error <= tolerance && symmetry <= 1e-12 &&
      fpca_error <= 1e-9 && all(diag(distances) == 0)
    list(
      status = if (pass) "NUMERICAL_SAMPLE_PASS" else "NUMERICAL_SAMPLE_FAIL",
      reason = if (pass) "Sample-level L2 and FPCA numerical contracts verified" else
        "One or more numerical check thresholds exceeded",
      curves = n, grid = length(grid), independent_pairs = ncol(pairs),
      max_l2_abs_error = max_error, l2_tolerance = tolerance,
      symmetry_error = symmetry, fpca_ratio_abs_error = fpca_error
    )
  })
  if (inherits(result, "et8_error")) {
    empty$status <- "NUMERICAL_ERROR"
    empty$reason <- result$message
    return(empty)
  }
  for (name in names(result)) empty[[name]] <- result[[name]]
  empty
}

.et8_csv <- function(path, rows) {
  if (length(rows)) {
    df <- do.call(rbind, lapply(rows, function(x)
      as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)))
  } else df <- data.frame()
  utils::write.csv(df, path, row.names = FALSE, na = "")
}

et8_run_audit <- function(root = Sys.getenv("ET_EIGHT_ARCHIVE_ROOT",
                            file.path(Sys.getenv("USERPROFILE"), "Downloads",
                                      "eyetrajectoriesValidation")),
                          max_rows = 30000L, max_members = 3L) {
  if (!dir.exists(root)) stop("Expected directory does not exist: ", root)
  max_rows <- as.integer(max_rows)
  max_members <- as.integer(max_members)
  stopifnot(max_rows >= 500L, max_members >= 1L)
  out <- tempfile("EYETRAJECTORIES_EIGHT_ARCHIVE_QUALIFICATION_", tmpdir = root)
  if (!dir.create(out, recursive = FALSE)) stop("Could not create output directory")
  log <- character()
  note <- function(...) {
    msg <- paste0(...)
    message(msg)
    log <<- c(log, msg)
  }
  note("EYETRAJECTORIES_EIGHT_ARCHIVE_AUDIT_V1")
  note("LOCAL_ONLY=TRUE; ZIP_SOURCES_UNMODIFIED=TRUE; RAW_PARTICIPANT_DATA_NOT_EXPORTED=TRUE")
  note("ROW_CAP_PER_CSV=", max_rows, "; MAX_MEMBERS_PER_ARCHIVE=", max_members)
  note("OUTPUT=", out)
  package_available <- requireNamespace("eyetrajectories", quietly = TRUE)
  note("PACKAGE=", if (package_available)
       as.character(utils::packageVersion("eyetrajectories")) else "NOT_INSTALLED")
  zipfiles <- list.files(root, pattern = "\\.zip$", full.names = TRUE,
                         ignore.case = TRUE, recursive = FALSE)
  inv <- list(); members <- list(); checks <- list()
  allow_hash_large <- identical(tolower(Sys.getenv("ET_EIGHT_ARCHIVE_HASH_LARGE")), "true")
  for (stem in .et8_stems) {
    expected <- paste0(stem, ".zip")
    selected <- zipfiles[tolower(basename(zipfiles)) == tolower(expected)]
    note("ARCHIVE=", expected, " FOUND=", length(selected))
    a <- list(archive = expected, present = length(selected) == 1L,
      compressed_bytes = NA_real_, md5 = "NOT_AVAILABLE", valid_members = NA_integer_,
      sampled_members = 0L, archive_status = "ARCHIVE_NOT_FOUND")
    nstatus <- list(archive = expected, status = "NOT_RUN",
      reason = "Source archive missing or could not be parsed", curves = 0L,
      grid = 64L, independent_pairs = 0L,
      max_l2_abs_error = NA_real_, l2_tolerance = NA_real_,
      symmetry_error = NA_real_, fpca_ratio_abs_error = NA_real_,
      valid_sample_rows = NA_integer_, sampled_trials = NA_integer_,
      eligible_sampled_trials = NA_integer_,
      duplicate_timestamps = NA_integer_)
    if (length(selected) == 1L) {
      z <- selected[1L]
      a$compressed_bytes <- unname(file.info(z)$size)
      a$md5 <- .et8_md5(z, allow_hash_large)
      listing <- .et8_safe(utils::unzip(z, list = TRUE))
      if (inherits(listing, "et8_error")) {
        a$archive_status <- paste("ZIP_LIST_ERROR", listing$message)
      } else {
        names0 <- listing$Name
        good <- !grepl("/$", names0) &&
          !grepl("(^|/)__MACOSX(/|$)", names0, ignore.case = TRUE) &&
          grepl("\\.(csv|tsv|asc)$", names0, ignore.case = TRUE)
        names0 <- names0[good]
        a$valid_members <- length(names0)
        names0 <- head(names0, max_members)
        a$sampled_members <- length(names0)
        a$archive_status <- if (!length(names0))
          "NO_SUPPORTED_MEMBERS" else "SAMPLED_NOT_FULLY_VALIDATED"
        for (name in names0) {
          note("  MEMBER=", name)
          p <- .et8_scan_member(z, name, max_rows = max_rows)
          roles <- p$roles
          m <- list(archive = expected, member = name,
            member_type = p$type, status = p$status,
            sampled_rows_or_lines = p$n, source_columns = length(p$cols),
            header_fields = paste(p$cols, collapse = " | "),
            participant_field = if (length(roles)) roles$participant else "",
            trial_field = if (length(roles)) roles$trial else "",
            time_field = if (length(roles)) roles$time else "",
            x_field = if (length(roles)) roles$x else "",
            y_field = if (length(roles)) roles$y else "",
            diagnostic = p$diagnostic)
          members[[length(members) + 1L]] <- m
          # One representative compatible CSV per archive. Never claim full
          # multi-file archive validation from this selection.
          if (identical(nstatus$status, "NOT_RUN") &&
              identical(p$status, "SAMPLED_SCHEMA")) {
            nstatus <- c(list(archive = expected),
                         .et8_numerical(p, package_available))
            note("  NUMERICAL_STATUS=", nstatus$status,
                 "; CURVES=", nstatus$curves, "; REASON=", nstatus$reason)
          }
        }
        if (a$sampled_members < a$valid_members) {
          note("  MORE_MEMBERS_EXIST=", a$valid_members - a$sampled_members,
               " (not inspected)")
        }
      }
    }
    inv[[length(inv) + 1L]] <- a
    checks[[length(checks) + 1L]] <- nstatus
  }
  .et8_csv(file.path(out, "archive_inventory.csv"), inv)
  .et8_csv(file.path(out, "member_schema.csv"), members)
  .et8_csv(file.path(out, "numeric_checks.csv"), checks)
  statuses <- vapply(checks, function(z) z$status, character(1L))
  present <- vapply(inv, function(z) isTRUE(z$present), logical(1L))
  fmt <- function(v) if (is.null(v) || !length(v) || is.na(v)) "NA" else as.character(v)
  table_rows <- vapply(seq_along(.et8_stems), function(i) {
    paste0("| ", inv[[i]]$archive, " | ",
           if (present[i]) "PRESENT" else "MISSING", " | ",
           statuses[i], " | ",
           checks[[i]]$curves, " | ",
           gsub("\\|", "/", checks[[i]]$reason), " |")
  }, character(1L))
  md <- c(
    "# Eight-archive real-gaze qualification — local audit",
    "",
    paste0("Executed: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    "",
    "**IMPORTANT: This is an author-side input and sampled numerical audit,",
    "not scientific certification of eight datasets or of every package method.**",
    "",
    paste0("Archives found: ", sum(present), "/8. Numeric sample checks PASS: ",
           sum(statuses == "NUMERICAL_SAMPLE_PASS"), "/8."),
    "",
    "| Archive | Available | Numeric sample contract | Curves | Reason |",
    "| --- | --- | --- | ---: | --- |",
    table_rows, "",
    "## Boundaries",
    "",
    paste0("- Sample cap per CSV/TSV member: ", max_rows,
           " rows; the rest of any large member is not audited."),
    paste0("- At most ", max_members, " eligible members inspected per ZIP."),
    "- ASC data are sampled as raw event-line types only, not parsed into",
    "  independently verified fixations, saccades, calibration or gaze ground truth.",
    "- Numerical tests require identifiable participant, trial, time, x and y",
    "  fields. Unrecognized schemas receive NOT_RUN rather than a false PASS.",
    "- Numerical verification on eligible sample trajectories uses 64-point",
    "  *within-trial normalized-time interpolation*, 16 separately computed",
    "  trapezoidal L2 references and an independently constructed weighted",
    "  SVD variance-ratio reference. This is not physical eye-velocity validation.",
    "- Large ZIPs are not hashed by default; set",
    "  ET_EIGHT_ARCHIVE_HASH_LARGE=true to hash every archive.",
    "- Acquisition/calibration validation, cross-representation agreement,",
    "  participant-level inference, uncertainty coverage and external ground",
    "  truth remain NOT_CERTIFIED until appropriate records and analyses exist.",
    "- No raw participant data are written to these evidence CSVs.",
    "- Nothing here modifies or replaces the v0.4.3 Zenodo archive.",
    "",
    "## Interpretation",
    "",
    "NUMERICAL_SAMPLE_PASS confirms only the stated sample-level computational",
    "contracts. It must never be written as FULL_SCIENTIFIC_VALIDATION_PASS.",
    "Review member_schema.csv and run_log.txt for field mismatches and data",
    "cap limits before designing archive-specific domain tests.",
    ""
  )
  writeLines(md, file.path(out, "VALIDATION_SUMMARY.md"), useBytes = TRUE)
  writeLines(log, file.path(out, "run_log.txt"), useBytes = TRUE)
  writeLines(capture.output(utils::sessionInfo()),
             file.path(out, "R_session_info.txt"), useBytes = TRUE)
  note("COMPLETED: archive evidence outputs are under ", out)
  invisible(list(output = out, inventory = inv, checks = checks))
}

if (!identical(tolower(Sys.getenv("ET_EIGHT_ARCHIVE_NO_AUTORUN")), "true")) {
  et8_run_audit()
}
