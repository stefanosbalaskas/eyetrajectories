#' Draw planar trajectories using the Python plotting backend
#'
#' Returns a Python matplotlib Axes object. This is not an R graphics object;
#' use et_save_plot() to write the figure to disk.
#' @param trajectories A Python TrajectorySet.
#' @param max_curves Maximum number of paths to draw (NULL for all).
#' @param alpha Line transparency.
#' @param invert_y Invert the screen Y axis.
#' @export
et_plot_planar <- function(trajectories, max_curves = 40L,
                           alpha = 0.35, invert_y = TRUE) {
  et_call(
    "plot_planar_trajectories",
    trajectories,
    max_curves = if (is.null(max_curves)) NULL else as.integer(max_curves),
    alpha = as.numeric(alpha),
    invert_y = invert_y
  )
}

#' Draw a functional PCA variance curve
#' @param fit A Python FPCAResult.
#' @param cumulative Whether to show cumulative explained variance.
#' @export
et_plot_fpca_variance <- function(fit, cumulative = TRUE) {
  et_call("plot_fpca_variance", fit, cumulative = cumulative)
}

#' Save a matplotlib Axes figure
#' @param axes Python matplotlib Axes returned by a plotting bridge.
#' @param file File path with extension (for example .png or .pdf).
#' @param dpi Raster resolution.
#' @export
et_save_plot <- function(axes, file, dpi = 150L) {
  if (!is.character(file) || length(file) != 1L ||
      is.na(file) || !nzchar(file)) {
    stop("file must be a nonempty destination path", call. = FALSE)
  }
  axes$figure$savefig(file, dpi = as.integer(dpi), bbox_inches = "tight")
  invisible(file)
}
