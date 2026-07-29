mer_library <- Sys.getenv("MER_R_LIBRARY", unset = "")
if (nzchar(mer_library)) {
  mer_library <- normalizePath(mer_library, winslash = "/", mustWork = TRUE)
  .libPaths(unique(c(mer_library, .libPaths())))
}

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

mer_root <- function() {
  normalizePath(getOption("mer.root", "."), winslash = "/", mustWork = TRUE)
}

mer_path <- function(...) file.path(mer_root(), ...)

ink <- "#26343D"
muted <- "#66747D"
grid <- "#D9E0E3"
marine <- "#2B6F8A"
marine_light <- "#C7DEE7"
gold <- "#C58B2A"
gold_light <- "#F1DFB5"
warm_grey <- "#8A8178"
light_grey <- "#E8ECEE"

outcome_colours <- c(
  checklist_reporting = marine,
  conditional_positive_numeric_count = gold
)

outcome_shapes <- c(
  checklist_reporting = 22,
  conditional_positive_numeric_count = 21
)

outcome_linetypes <- c(
  checklist_reporting = "22",
  conditional_positive_numeric_count = "solid"
)

outcome_labels <- c(
  checklist_reporting = "Checklist reporting",
  conditional_positive_numeric_count = "Reported number"
)

period_labels <- c(
  did_early_pre = "Early pre\n-14 to -8 d",
  did_immediate_pre = "Immediate pre\n-7 to -1 d",
  did_pre_14_day = "Pre-onset\n-14 to -1 d",
  did_spawn_start = "Spawn start\n0 to 3 d",
  did_early_egg = "Early egg\n4 to 14 d",
  did_late_egg = "Late egg\n15 to 28 d",
  did_active_0_14_day = "Active composite\n0 to 14 d"
)

theme_mer <- function(base_size = 10.5) {
  theme_minimal(base_family = "sans", base_size = base_size) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        colour = ink, face = "bold", size = rel(1.35),
        hjust = 0, margin = margin(b = 5)
      ),
      plot.subtitle = element_text(
        colour = muted, size = rel(0.95), hjust = 0,
        margin = margin(b = 12), lineheight = 1.08
      ),
      plot.caption = element_text(
        colour = muted, size = rel(0.80), hjust = 0,
        margin = margin(t = 10)
      ),
      axis.title = element_text(colour = ink, face = "plain"),
      axis.text = element_text(colour = ink),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(colour = grid, linewidth = 0.35),
      strip.text = element_text(
        colour = ink, face = "bold", size = rel(1.03), hjust = 0
      ),
      strip.background = element_blank(),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank(),
      legend.text = element_text(colour = ink),
      plot.margin = margin(14, 18, 14, 14)
    )
}

assert_unique_key <- function(x, columns, label) {
  if (!all(columns %in% names(x))) {
    stop(label, ": missing key columns: ",
         paste(setdiff(columns, names(x)), collapse = ", "), call. = FALSE)
  }
  if (x[, anyDuplicated(.SD), .SDcols = columns]) {
    stop(label, ": key is not unique: ", paste(columns, collapse = " + "),
         call. = FALSE)
  }
  invisible(TRUE)
}

read_figure_csv <- function(filename, expected_rows = NULL) {
  path <- mer_path("figures_out", filename)
  if (!file.exists(path)) stop("Missing figure input: ", path, call. = FALSE)
  x <- fread(path, na.strings = c("", "NA"))
  if (!is.null(expected_rows) && nrow(x) != expected_rows) {
    stop(filename, ": expected ", expected_rows, " rows; found ", nrow(x),
         call. = FALSE)
  }
  x
}

save_figure <- function(plot, stem, width, height, dpi = 600) {
  out <- mer_path("figures_out")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  pdf_path <- file.path(out, paste0(stem, ".pdf"))
  png_path <- file.path(out, paste0(stem, ".png"))
  ggsave(
    pdf_path, plot = plot, width = width, height = height, units = "in",
    device = grDevices::cairo_pdf, bg = "white", limitsize = FALSE
  )
  ggsave(
    png_path, plot = plot, width = width, height = height, units = "in",
    device = "png", dpi = dpi, bg = "white", limitsize = FALSE
  )
  paths <- c(pdf_path, png_path)
  sizes <- file.info(paths)$size
  if (any(!file.exists(paths)) || any(!is.finite(sizes)) || any(sizes <= 0)) {
    stop("Figure export failed: ", stem, call. = FALSE)
  }
  message(
    "FIGURE_EXPORTED=", stem,
    " PDF_BYTES=", sizes[[1L]],
    " PNG_BYTES=", sizes[[2L]],
    " PNG_DPI=", dpi
  )
  invisible(paths)
}
