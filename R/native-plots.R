#' Plot planar gaze trajectories with base R graphics
#'
#' No matplotlib or Python is needed. Returns curve indices invisibly.
#' @param x Complete native collection with at least two channels.
#' @param max_curves Maximum number of curves to show.
#' @param invert_y Display screen-style Y coordinates.
#' @param ... Graphical parameters forwarded to graphics::plot().
#' @export
etr_plot_trajectories <- function(x, max_curves = 40L, invert_y = TRUE, ...) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "plot requires at least two dimensions")
  .etr_assert(length(max_curves) == 1L && is.numeric(max_curves) &&
                is.finite(max_curves) && max_curves >= 1L &&
                max_curves == as.integer(max_curves),
              "max_curves must be positive integer")
  chosen <- seq_len(min(as.integer(max_curves), dim(x$values)[1]))
  xx <- x$values[chosen, , 1]; yy <- x$values[chosen, , 2]
  ylimit <- range(yy)
  if (isTRUE(invert_y)) ylimit <- rev(ylimit)
  graphics::plot(NA_real_, NA_real_, xlim = range(xx), ylim = ylimit, type = "n",
                 xlab = x$dimension_names[1], ylab = x$dimension_names[2],
                 main = sprintf("Native planar gaze (n=%d)", length(chosen)), ...)
  for (i in chosen) graphics::lines(x$values[i, , 1], x$values[i, , 2],
                                   col = grDevices::adjustcolor("steelblue", alpha.f = 0.3))
  invisible(chosen)
}

#' Plot native FPCA explained variance
#' @param fit Native FPCA result.
#' @param cumulative Show cumulative rather than individual proportions.
#' @param ... Additional base plot parameters.
#' @export
etr_plot_fpca_variance <- function(fit, cumulative = TRUE, ...) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  y <- if (isTRUE(cumulative)) cumsum(fit$explained_variance_ratio) else
    fit$explained_variance_ratio
  graphics::plot(seq_along(y), 100 * y, type = "b", pch = 19,
                 xlab = "Functional principal component",
                 ylab = if (isTRUE(cumulative)) "Cumulative variance (%)" else "Variance (%)",
                 ...)
  invisible(data.frame(component = seq_along(y), variance = y))
}

#' Plot a native recurrence matrix using base R graphics
#' @param recurrence Native auto- or cross-recurrence result.
#' @param ... Further arguments for graphics::image().
#' @export
etr_plot_recurrence <- function(recurrence, ...) {
  .etr_assert(inherits(recurrence, "etr_recurrence"),
              "recurrence must be a native etr_recurrence")
  m <- recurrence$matrix
  graphics::image(seq_len(nrow(m)), seq_len(ncol(m)), matrix(as.numeric(m), nrow(m)),
                  col = c("white", "black"), xlab = "Sample A", ylab = "Sample B", ...)
  invisible(m)
}
