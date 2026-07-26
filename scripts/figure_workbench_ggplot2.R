#!/usr/bin/env Rscript

# Editable ggplot2 workbench for the released analysis figures.
#
# Interactive use from the repository root:
#
#   source("scripts/figure_workbench_ggplot2.R")
#   figures <- load_analysis_figures()
#   names(figures)
#
#   p <- figures$Figure_3_focal_species_effects_v3
#   figure_data(figures, "Figure_3_focal_species_effects_v3")
#   p <- p + ggplot2::labs(title = "My revised title") +
#     ggplot2::theme(legend.position = "top")
#   ggplot2::ggsave("my_figure.pdf", p, width = 7.2, height = 7.2)
#
# Editable Strait of Georgia map and inset:
#
#   Sys.setenv(HERRING_EBIRD_V2_HERRING = "path/to/2025_herring.csv")
#   map <- load_sog_spatial_support_map()
#   map$main <- map$main + ggplot2::labs(title = "My revised map title")
#   map$inset <- map$inset + ggplot2::theme(plot.title = ggplot2::element_blank())
#   save_sog_spatial_support_map(map, "my_map.pdf")
#
# The loader reads only tracked aggregate outputs and does not fit models,
# rewrite manuscript tables, or overwrite the released figure files.

options(stringsAsFactors = FALSE)

analysis_figure_manifest <- function() {
  data.frame(
    figure = c(
      "Figure_1_study_area_map_v3",
      "Figure_2_descriptive_bird_patterns_v3",
      "Figure_3_focal_species_effects_v3",
      "Figure_4_event_time_v3",
      "Figure_5_specificity_distribution_v3",
      "Figure_6_regional_comparison_v3",
      "Figure_S1_exposure_design_v3",
      "Figure_S2_sampling_support_map_v3",
      "Figure_S3_complete_species_matrix_v3",
      "Figure_S4_guild_synthesis_v3",
      "Figure_S5_sensitivities_placebos_v3",
      "Figure_S6_diagnostics_v3"
    ),
    width_in = rep(7.2, 12L),
    height_in = c(6.0, 6.6, 7.2, 6.8, 5.0, 5.8, 4.2, 5.8, 10.2, 5.5, 6.0, 4.8),
    scope = c(rep("main", 6L), rep("supplement", 6L)),
    stringsAsFactors = FALSE
  )
}

analysis_repo_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "AGENTS.md")) &&
        file.exists(file.path(candidate, "DESCRIPTION"))
    ) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop(
        "Could not find the repository root above: ", start,
        call. = FALSE
      )
    }
    candidate <- parent
  }
}

.source_in_repo <- function(root, script, option_overrides = list()) {
  root <- analysis_repo_root(root)
  script_path <- file.path(root, script)
  if (!file.exists(script_path)) {
    stop("Figure builder is unavailable: ", script_path, call. = FALSE)
  }

  old_options <- options(option_overrides)
  on.exit(options(old_options), add = TRUE)
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)

  builder_environment <- new.env(parent = globalenv())
  sys.source(script_path, envir = builder_environment)
  builder_environment
}

load_analysis_figures <- function(root = analysis_repo_root()) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Install ggplot2 before loading the figure workbench.", call. = FALSE)
  }

  builder <- .source_in_repo(
    root,
    "scripts/build_mer_v3_descriptives_and_figures.R",
    list(
      herring.figure_builder.write_tables = FALSE,
      herring.figure_builder.save_figures = FALSE
    )
  )
  figures <- builder$mer_v3_figures
  expected <- analysis_figure_manifest()$figure

  if (!identical(names(figures), expected)) {
    stop("The MER v3 figure inventory changed; update the workbench manifest.", call. = FALSE)
  }
  is_ggplot <- vapply(figures, inherits, logical(1L), what = "ggplot")
  if (!all(is_ggplot)) {
    stop(
      "Non-ggplot objects returned for: ",
      paste(names(figures)[!is_ggplot], collapse = ", "),
      call. = FALSE
    )
  }
  figures
}

figure_data <- function(figures, figure) {
  if (!figure %in% names(figures)) {
    stop("Unknown figure: ", figure, call. = FALSE)
  }
  data <- attr(figures, "source_data", exact = TRUE)
  if (is.null(data) || is.null(data[[figure]])) {
    stop("No source-data object is attached to: ", figure, call. = FALSE)
  }
  data[[figure]]
}

figure_source <- function(figures, figure) {
  if (!figure %in% names(figures)) {
    stop("Unknown figure: ", figure, call. = FALSE)
  }
  sources <- attr(figures, "sources", exact = TRUE)
  unname(sources[[figure]])
}

figure_dimensions <- function(figures, figure) {
  if (!figure %in% names(figures)) {
    stop("Unknown figure: ", figure, call. = FALSE)
  }
  sizes <- attr(figures, "figure_sizes", exact = TRUE)
  sizes[sizes$figure == figure, , drop = FALSE]
}

save_analysis_figure <- function(plot, filename, width, height, dpi = 400) {
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Install ggplot2 before exporting figures.", call. = FALSE)
  }
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = dpi,
    bg = "white",
    limitsize = FALSE
  )
  invisible(normalizePath(filename, winslash = "/", mustWork = TRUE))
}

.temporarily_set_envvar <- function(name, value) {
  old_value <- Sys.getenv(name, unset = NA_character_)
  if (!is.null(value)) {
    do.call(Sys.setenv, setNames(list(value), name))
  }
  function() {
    if (is.na(old_value)) {
      Sys.unsetenv(name)
    } else {
      do.call(Sys.setenv, setNames(list(old_value), name))
    }
  }
}

load_sog_spatial_support_map <- function(
    root = analysis_repo_root(),
    herring_file = NULL,
    natural_earth_land = NULL) {
  restore_herring <- .temporarily_set_envvar(
    "HERRING_EBIRD_V2_HERRING", herring_file
  )
  on.exit(restore_herring(), add = TRUE)
  restore_land <- .temporarily_set_envvar(
    "HERRING_EBIRD_V2_NATURAL_EARTH_LAND", natural_earth_land
  )
  on.exit(restore_land(), add = TRUE)

  builder <- .source_in_repo(
    root,
    "scripts/build_sog_spawn_ebird_map.R",
    list(herring.sog_map.save_outputs = FALSE)
  )
  map <- builder$sog_spawn_ebird_map
  if (
    !is.list(map) ||
      !inherits(map$main, "ggplot") ||
      !inherits(map$inset, "ggplot") ||
      !is.function(map$draw)
  ) {
    stop("The Strait of Georgia map builder returned an invalid object.", call. = FALSE)
  }
  map
}

save_sog_spatial_support_map <- function(
    map,
    filename,
    width = 9,
    height = 10,
    dpi = 300) {
  if (
    !is.list(map) ||
      !inherits(map$main, "ggplot") ||
      !inherits(map$inset, "ggplot") ||
      !is.function(map$draw)
  ) {
    stop("`map` must come from load_sog_spatial_support_map().", call. = FALSE)
  }

  extension <- tolower(tools::file_ext(filename))
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  device <- switch(
    extension,
    png = function(path) {
      grDevices::png(
        filename = path,
        width = round(width * dpi),
        height = round(height * dpi),
        res = dpi,
        type = "cairo",
        bg = "white"
      )
    },
    pdf = function(path) {
      grDevices::cairo_pdf(path, width = width, height = height, bg = "white")
    },
    svg = function(path) {
      grDevices::svg(path, width = width, height = height, bg = "white")
    },
    stop("Map export supports .png, .pdf, or .svg.", call. = FALSE)
  )

  map$draw(device, filename, main = map$main, inset = map$inset)
  invisible(normalizePath(filename, winslash = "/", mustWork = TRUE))
}

.print_workbench_usage <- function() {
  cat(
    paste0(
      "Editable ggplot2 figure workbench\n\n",
      "Interactive:\n",
      "  source(\"scripts/figure_workbench_ggplot2.R\")\n",
      "  figures <- load_analysis_figures()\n",
      "  p <- figures$Figure_3_focal_species_effects_v3\n\n",
      "Command line:\n",
      "  Rscript scripts/figure_workbench_ggplot2.R --list\n",
      "  Rscript scripts/figure_workbench_ggplot2.R ",
      "--figure Figure_3_focal_species_effects_v3 --output revised.pdf\n"
    )
  )
}

.run_workbench_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (!length(args) || "--help" %in% args) {
    .print_workbench_usage()
    return(invisible(NULL))
  }
  if ("--list" %in% args) {
    print(analysis_figure_manifest(), row.names = FALSE)
    return(invisible(NULL))
  }

  figure_arg <- grep("^--figure=", args, value = TRUE)
  output_arg <- grep("^--output=", args, value = TRUE)
  if (!length(figure_arg) && "--figure" %in% args) {
    i <- match("--figure", args)
    if (i < length(args)) figure_arg <- paste0("--figure=", args[[i + 1L]])
  }
  if (!length(output_arg) && "--output" %in% args) {
    i <- match("--output", args)
    if (i < length(args)) output_arg <- paste0("--output=", args[[i + 1L]])
  }
  if (length(figure_arg) != 1L || length(output_arg) != 1L) {
    stop("Supply exactly one --figure and one --output.", call. = FALSE)
  }

  figure <- sub("^--figure=", "", figure_arg)
  output <- sub("^--output=", "", output_arg)
  figures <- load_analysis_figures()
  if (!figure %in% names(figures)) {
    stop("Unknown figure: ", figure, ". Run with --list.", call. = FALSE)
  }
  size <- figure_dimensions(figures, figure)
  save_analysis_figure(
    figures[[figure]],
    output,
    width = size$width_in,
    height = size$height_in
  )
  message("Wrote ", normalizePath(output, winslash = "/", mustWork = TRUE))
}

if (sys.nframe() == 0L) {
  .run_workbench_cli()
}
