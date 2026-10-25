#' Draw native cluster-mean or functional-contrast bands
#' @param fit etr_mean_band or etr_group_contrast.
#' @param dimension One-based channel index.
#' @param interval "simultaneous" or "pointwise".
#' @param ... Additional parameters to graphics::plot().
#' @export
etr_plot_functional_band <- function(fit, dimension = 1L,
                                     interval = c("simultaneous", "pointwise"), ...) {
  .etr_assert(inherits(fit, "etr_mean_band") ||
                inherits(fit, "etr_group_contrast"),
              "fit must be etr_mean_band or etr_group_contrast")
  interval <- match.arg(interval)
  mean <- if (inherits(fit, "etr_mean_band")) fit$mean else fit$difference
  nt <- nrow(mean); nd <- ncol(mean)
  .etr_assert(is.numeric(dimension) && length(dimension) == 1L &&
                is.finite(dimension) && dimension == as.integer(dimension) &&
                dimension >= 1L && dimension <= nd,
              "dimension must be valid one-based channel index")
  low <- fit[[paste0(interval, "_lower")]][, dimension]
  high <- fit[[paste0(interval, "_upper")]][, dimension]
  mu <- mean[, dimension]
  .etr_assert(all(is.finite(c(low,high,mu))) && length(mu) == nt,
              "cannot draw non-finite functional bands")
  tm <- fit$time
  graphics::plot(tm, mu, type = "n", ylim = range(c(low, high, mu)),
                 xlab = "Time", ylab = fit$dimensions[dimension],
                 main = paste("Experimental", interval, "functional band"), ...)
  graphics::polygon(c(tm, rev(tm)), c(low, rev(high)),
                    col = grDevices::adjustcolor("steelblue", alpha.f = .20),
                    border = NA)
  graphics::lines(tm, mu, lwd = 2L, col = "steelblue4")
  graphics::abline(h = 0, col = "grey60", lty = 3L)
  invisible(data.frame(time = tm, estimate = mu, lower = low, upper = high))
}

#' Plot observation support fraction by time bin
#' @param diagnostic Output of etr_sparse_design_diagnostics().
#' @param ... Additional arguments for graphics::barplot().
#' @export
etr_plot_sparse_support <- function(diagnostic, ...) {
  .etr_assert(is.list(diagnostic) && is.data.frame(diagnostic$support) &&
                all(c("bin","fraction_observed") %in% names(diagnostic$support)),
              "diagnostic must be etr_sparse_design_diagnostics output")
  graphics::barplot(diagnostic$support$fraction_observed,
                    names.arg = diagnostic$support$bin, ylim = c(0, 1),
                    xlab = "Time support bin",
                    ylab = "Fraction of participants observed",
                    main = "Sparse observation support (diagnostic)", ...)
  invisible(diagnostic$support)
}

#' Visualize TE observed estimate against surrogate distribution
#' @param x An etr_transfer_entropy_shift_test result.
#' @param ... Additional graphics::hist arguments.
#' @export
etr_plot_transfer_surrogates <- function(x, ...) {
  .etr_assert(is.list(x) && is.numeric(x$null_bits) &&
                length(x$null_bits) >= 19L &&
                is.numeric(x$observed_bits) && length(x$observed_bits) == 1L,
              "x must be an etr_transfer_entropy_shift_test result")
  graphics::hist(x$null_bits, main = "Transfer entropy: shift sensitivity",
                 xlab = "Shuffled-source TE (bits)", ...)
  graphics::abline(v = x$observed_bits, col = "firebrick", lwd = 2L)
  invisible(x$null_bits)
}
