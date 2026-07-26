#!/usr/bin/env Rscript

# Privacy-safe spatial-support map for the frozen Strait of Georgia analysis frame.
#
# Join cardinalities:
#   1. frozen analysis frame -> protected checklist metadata: one-to-one
#   2. checklist -> herring source links: one-to-many by design; duplicate pairs forbidden
#   3. herring source token -> open DFO herring record: one-to-one
#
# No record-level identifier or coordinate is written. Checklist and herring
# locations are generalized to 10-km hexagons before plotting, and checklist
# cells with fewer than 20 records are suppressed.

suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(ggplot2)
  library(sf)
})

options(stringsAsFactors = FALSE, scipen = 999)
sf::sf_use_s2(FALSE)

save_map_outputs_enabled <- isTRUE(
  getOption("herring.sog_map.save_outputs", TRUE)
)

analysis_years <- 2005:2025
map_crs <- 3005
hex_cellsize_m <- 10000
checklist_release_threshold <- 20L
main_bbox_lonlat <- sf::st_bbox(
  c(xmin = -125.55, ymin = 48.15, xmax = -122.20, ymax = 50.60),
  crs = sf::st_crs(4326)
)

frame_path <- "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz"
link_path <- "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz"
checklist_cache_path <- "outputs/input_audit_local/stage2/sed_stage2_cache.rds"
output_png <- "reports/figures/sog_spawn_ebird_spatial_support.png"
output_pdf <- "reports/figures/sog_spawn_ebird_spatial_support.pdf"
output_svg <- "reports/figures/sog_spawn_ebird_spatial_support.svg"

require_file <- function(path, description) {
  if (!nzchar(path) || !file.exists(path)) {
    stop(description, " is unavailable: ", path, call. = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

hash_token <- function(domain, value) {
  vapply(
    as.character(value),
    function(x) {
      substr(
        digest::digest(
          paste0(domain, "|", if (is.na(x)) "" else x),
          algo = "sha256",
          serialize = FALSE
        ),
        1L,
        24L
      )
    },
    character(1L),
    USE.NAMES = FALSE
  )
}

clean_identity_field <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x)] <- ""
  x
}

resolve_herring_path <- function() {
  configured <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
  require_file(
    configured,
    paste0(
      "The open DFO herring source file. Set HERRING_EBIRD_V2_HERRING ",
      "to the configured 2025 herring CSV"
    )
  )
}

resolve_natural_earth_land <- function() {
  configured <- Sys.getenv("HERRING_EBIRD_V2_NATURAL_EARTH_LAND", unset = "")
  if (nzchar(configured)) {
    return(require_file(configured, "Natural Earth land polygons"))
  }

  cache_dir <- "data/derived/map_cache"
  zip_path <- file.path(cache_dir, "ne_10m_land.zip")
  shp_path <- file.path(cache_dir, "ne_10m_land.shp")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  if (!file.exists(shp_path)) {
    if (!file.exists(zip_path)) {
      download.file(
        "https://naturalearth.s3.amazonaws.com/10m_physical/ne_10m_land.zip",
        zip_path,
        mode = "wb",
        quiet = TRUE
      )
    }
    unzip(zip_path, exdir = cache_dir)
  }

  require_file(shp_path, "Natural Earth 1:10m land polygons")
}

message("Reading the frozen Strait of Georgia analysis frame")
frame <- data.table::fread(
  require_file(frame_path, "Frozen Stage 4A event metadata"),
  select = c("analysis_event_token", "region", "checklist_year"),
  showProgress = FALSE
)
frame <- unique(frame[
  region == "SoG" &
    checklist_year %in% analysis_years,
  .(analysis_event_token, checklist_year)
])
if (!nrow(frame) || anyNA(frame$analysis_event_token) ||
    anyDuplicated(frame$analysis_event_token)) {
  stop("Frozen Strait of Georgia frame key failure", call. = FALSE)
}

message("Joining the frozen frame one-to-one to protected checklist coordinates")
checklist_cache <- readRDS(
  require_file(checklist_cache_path, "Protected checklist metadata cache")
)
if (!is.list(checklist_cache) || !"checklists" %in% names(checklist_cache)) {
  stop("Protected checklist cache schema failure", call. = FALSE)
}
checklists <- data.table::as.data.table(checklist_cache$checklists)
required_checklist_fields <- c(
  "analysis_id", "latitude", "longitude", "checklist_year",
  "standardized_eligible"
)
if (!all(required_checklist_fields %in% names(checklists))) {
  stop("Protected checklist cache is missing required fields", call. = FALSE)
}
checklists <- checklists[
  checklist_year %in% analysis_years &
    standardized_eligible == TRUE &
    is.finite(latitude) &
    is.finite(longitude),
  .(analysis_id, checklist_year, latitude, longitude)
]
if (anyNA(checklists$analysis_id) || anyDuplicated(checklists$analysis_id)) {
  stop("Protected checklist analysis key is not one-to-one", call. = FALSE)
}
checklists[, analysis_event_token := hash_token("analysis_event", analysis_id)]
if (anyDuplicated(checklists$analysis_event_token)) {
  stop("Hashed checklist token collision", call. = FALSE)
}

frame_match <- match(frame$analysis_event_token, checklists$analysis_event_token)
if (anyNA(frame_match)) {
  stop(
    "Frozen frame -> protected checklist join was not complete; unmatched rows: ",
    sum(is.na(frame_match)),
    call. = FALSE
  )
}
checklist_map_data <- checklists[
  frame_match,
  .(checklist_year, latitude, longitude)
]
if (nrow(checklist_map_data) != nrow(frame)) {
  stop("Frozen frame -> checklist join changed row count", call. = FALSE)
}
rm(checklist_cache, checklists, frame_match)
invisible(gc())

message("Resolving analysis-linked herring events to open DFO source points")
links <- data.table::fread(
  require_file(link_path, "Protected checklist-to-herring link table"),
  select = c(
    "analysis_event_token", "herring_source_token", "region",
    "checklist_year", "event_year"
  ),
  showProgress = FALSE
)
links <- links[
  region == "SoG" &
    checklist_year %in% analysis_years &
    event_year %in% analysis_years &
    analysis_event_token %chin% frame$analysis_event_token,
  .(analysis_event_token, herring_source_token, event_year)
]
if (!nrow(links) ||
    anyDuplicated(links[, .(analysis_event_token, herring_source_token)])) {
  stop("Checklist-to-herring link cardinality failure", call. = FALSE)
}

herring_path <- resolve_herring_path()
herring <- data.table::fread(
  herring_path,
  colClasses = "character",
  showProgress = FALSE
)
required_herring_fields <- c(
  "Region", "Year", "StatisticalArea", "Section", "LocationCode",
  "SpawnNumber", "Longitude", "Latitude"
)
if (!all(required_herring_fields %in% names(herring))) {
  stop("DFO herring source schema mismatch", call. = FALSE)
}
herring[, source_row := .I]
herring[, event_year := suppressWarnings(as.integer(Year))]
herring[, event_longitude := suppressWarnings(as.numeric(Longitude))]
herring[, event_latitude := suppressWarnings(as.numeric(Latitude))]
herring <- herring[
  event_year %in% analysis_years &
    Region == "SoG" &
    is.finite(event_longitude) &
    is.finite(event_latitude)
]
herring[, herring_identity := paste(
  source_row,
  event_year,
  clean_identity_field(StatisticalArea),
  clean_identity_field(Section),
  clean_identity_field(LocationCode),
  clean_identity_field(SpawnNumber),
  sep = "|"
)]
herring[, herring_source_token := hash_token("herring_source", herring_identity)]
if (anyDuplicated(herring$herring_source_token)) {
  stop("Herring source token is not one-to-one", call. = FALSE)
}

linked_herring_tokens <- unique(links$herring_source_token)
herring_match <- match(linked_herring_tokens, herring$herring_source_token)
if (anyNA(herring_match)) {
  stop(
    "Protected herring token -> open source record join was not complete; ",
    "unmatched rows: ", sum(is.na(herring_match)),
    call. = FALSE
  )
}
herring_map_data <- herring[
  herring_match,
  .(event_year, event_latitude, event_longitude)
]
rm(herring, herring_match, linked_herring_tokens)
invisible(gc())

message("Generalizing locations to privacy-safe 10-km hexagons")
checklist_points <- sf::st_as_sf(
  checklist_map_data,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = TRUE
)
checklist_points <- sf::st_transform(checklist_points, map_crs)

herring_points <- sf::st_as_sf(
  herring_map_data,
  coords = c("event_longitude", "event_latitude"),
  crs = 4326,
  remove = TRUE
)
herring_points <- sf::st_transform(herring_points, map_crs)

main_bbox_sfc <- sf::st_as_sfc(main_bbox_lonlat)
main_bbox_projected <- sf::st_transform(main_bbox_sfc, map_crs)
hex_grid <- sf::st_make_grid(
  main_bbox_projected,
  cellsize = hex_cellsize_m,
  square = FALSE
)
hex_grid <- sf::st_sf(hex_id = seq_along(hex_grid), geometry = hex_grid)

checklist_counts <- lengths(sf::st_intersects(hex_grid, checklist_points))
checklist_hex <- hex_grid[checklist_counts >= checklist_release_threshold, ]
checklist_hex$checklist_count <- checklist_counts[
  checklist_counts >= checklist_release_threshold
]

herring_counts <- lengths(sf::st_intersects(hex_grid, herring_points))
herring_hex <- hex_grid[herring_counts > 0L, ]
herring_hex$event_count <- herring_counts[herring_counts > 0L]
herring_centres <- suppressWarnings(sf::st_centroid(herring_hex))

if (sum(checklist_counts) != nrow(checklist_points)) {
  stop("At least one frozen-frame checklist fell outside the map grid", call. = FALSE)
}
if (sum(herring_counts) != nrow(herring_points)) {
  stop("At least one linked herring event fell outside the map grid", call. = FALSE)
}
if (!nrow(checklist_hex) || !nrow(herring_centres)) {
  stop("Generalized spatial layers are empty", call. = FALSE)
}

message("Reading Natural Earth land polygons through sf")
land <- sf::st_read(resolve_natural_earth_land(), quiet = TRUE)
if (is.na(sf::st_crs(land))) {
  stop("Natural Earth land CRS is missing", call. = FALSE)
}
main_land <- suppressWarnings(sf::st_crop(land, main_bbox_lonlat))
main_land <- sf::st_transform(main_land, map_crs)

north_america_bbox <- sf::st_bbox(
  c(xmin = -170, ymin = 10, xmax = -50, ymax = 76),
  crs = sf::st_crs(4326)
)
north_america_land <- suppressWarnings(sf::st_crop(land, north_america_bbox))
north_america_crs <- sf::st_crs(
  "+proj=laea +lat_0=45 +lon_0=-100 +datum=WGS84 +units=m +no_defs"
)
north_america_land <- sf::st_transform(north_america_land, north_america_crs)
focus_box <- sf::st_transform(main_bbox_sfc, north_america_crs)

city_labels <- data.frame(
  label = c("Campbell River", "Nanaimo", "Vancouver", "Victoria"),
  longitude = c(-125.2440, -123.9401, -123.1207, -123.3656),
  latitude = c(50.0244, 49.1659, 49.2827, 48.4284),
  label_dx_m = c(11000, -12000, -16000, -13000),
  label_dy_m = c(5000, -8000, 7000, -9000)
)
city_points <- sf::st_as_sf(
  city_labels,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)
city_points <- sf::st_transform(city_points, map_crs)
city_xy <- sf::st_coordinates(city_points)
city_labels$x <- city_xy[, 1]
city_labels$y <- city_xy[, 2]

place_labels <- data.frame(
  label = c("Vancouver Island", "Strait of Georgia"),
  longitude = c(-124.72, -123.68),
  latitude = c(48.95, 49.68),
  angle = c(-24, -25),
  fontface = c("italic", "italic")
)
place_points <- sf::st_as_sf(
  place_labels,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)
place_points <- sf::st_transform(place_points, map_crs)
place_xy <- sf::st_coordinates(place_points)
place_labels$x <- place_xy[, 1]
place_labels$y <- place_xy[, 2]

international_border <- sf::st_sfc(
  sf::st_linestring(matrix(
    c(-123.20, 49.00, -122.20, 49.00),
    ncol = 2,
    byrow = TRUE
  )),
  crs = 4326
)
international_border <- sf::st_transform(international_border, map_crs)

checklist_palette <- c("#DCEFF2", "#91C2C9", "#4A8D9A", "#145160")
event_fill <- "#E1873C"
event_outline <- "#68340F"
ink <- "#1D2E35"
land_fill <- "#EEEAE1"
land_outline <- "#858985"
water_fill <- "#EFF6F8"

map_extent <- sf::st_bbox(main_bbox_projected)
scale_x <- unname(map_extent[["xmin"]]) + 18000
scale_y <- unname(map_extent[["ymin"]]) + 24000

main_map <- ggplot2::ggplot() +
  ggplot2::geom_sf(
    data = main_land,
    fill = land_fill,
    colour = land_outline,
    linewidth = 0.25
  ) +
  ggplot2::geom_sf(
    data = checklist_hex,
    ggplot2::aes(fill = checklist_count),
    colour = NA,
    alpha = 0.86
  ) +
  ggplot2::geom_sf(
    data = herring_centres,
    ggplot2::aes(size = event_count),
    shape = 21,
    fill = event_fill,
    colour = event_outline,
    stroke = 0.55,
    alpha = 0.94
  ) +
  ggplot2::geom_sf(
    data = international_border,
    colour = "#737A7D",
    linewidth = 0.45,
    linetype = "22"
  ) +
  ggplot2::geom_point(
    data = city_labels,
    ggplot2::aes(x = x, y = y),
    shape = 21,
    size = 1.8,
    stroke = 0.45,
    fill = "white",
    colour = ink
  ) +
  ggplot2::geom_text(
    data = city_labels,
    ggplot2::aes(
      x = x + label_dx_m,
      y = y + label_dy_m,
      label = label
    ),
    colour = ink,
    size = 2.8,
    fontface = "bold",
    check_overlap = TRUE
  ) +
  ggplot2::geom_text(
    data = place_labels,
    ggplot2::aes(
      x = x,
      y = y,
      label = label,
      angle = angle,
      fontface = fontface
    ),
    colour = "#5F6B6E",
    size = 3.0,
    alpha = 0.9
  ) +
  ggplot2::annotate(
    "segment",
    x = scale_x,
    xend = scale_x + 50000,
    y = scale_y,
    yend = scale_y,
    colour = ink,
    linewidth = 1.1,
    lineend = "butt"
  ) +
  ggplot2::annotate(
    "segment",
    x = c(scale_x, scale_x + 50000),
    xend = c(scale_x, scale_x + 50000),
    y = scale_y - 4000,
    yend = scale_y + 4000,
    colour = ink,
    linewidth = 0.7
  ) +
  ggplot2::annotate(
    "text",
    x = scale_x + 25000,
    y = scale_y + 11000,
    label = "50 km",
    colour = ink,
    size = 3.2
  ) +
  ggplot2::scale_fill_gradientn(
    colours = checklist_palette,
    trans = "log10",
    name = "eBird checklists\nper 10-km cell",
    labels = function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE),
    guide = ggplot2::guide_colourbar(
      title.position = "top",
      order = 2,
      barheight = grid::unit(35, "mm"),
      barwidth = grid::unit(4.5, "mm")
    )
  ) +
  ggplot2::scale_size_continuous(
    range = c(1.8, 5.6),
    name = "Herring spawn events\nper 10-km cell",
    breaks = pretty(range(herring_centres$event_count), n = 4),
    guide = ggplot2::guide_legend(
      title.position = "top",
      order = 1,
      override.aes = list(fill = event_fill, colour = event_outline, alpha = 1)
    )
  ) +
  ggplot2::coord_sf(
    crs = sf::st_crs(map_crs),
    xlim = unname(map_extent[c("xmin", "xmax")]),
    ylim = unname(map_extent[c("ymin", "ymax")]),
    datum = sf::st_crs(4326),
    expand = FALSE
  ) +
  ggplot2::labs(
    title = "Spatial coverage of herring spawn and eBird checklists",
    subtitle = paste0(
      "Strait of Georgia analysis window, 2005-2025  |  ",
      format(nrow(frame), big.mark = ","), " eligible checklists  |  ",
      format(nrow(herring_points), big.mark = ","), " linked spawn events"
    ),
    x = NULL,
    y = NULL,
    caption = paste0(
      "Locations generalized to 10-km hexagons; checklist cells with fewer than ",
      checklist_release_threshold, " records are suppressed.\n",
      "Herring: DFO Pacific herring spawn index, 2025 release. ",
      "Land: Natural Earth 1:10m."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10, base_family = "sans") +
  ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = water_fill, colour = NA),
    panel.grid.major = ggplot2::element_line(colour = "#C8D9DE", linewidth = 0.28),
    panel.grid.minor = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.title = ggplot2::element_text(
      colour = ink, face = "bold", size = 15, margin = ggplot2::margin(b = 4)
    ),
    plot.subtitle = ggplot2::element_text(
      colour = "#52646A", size = 9.5, margin = ggplot2::margin(b = 9)
    ),
    plot.caption = ggplot2::element_text(
      colour = "#5C6A6E", size = 8.2, hjust = 0, margin = ggplot2::margin(t = 9)
    ),
    axis.text = ggplot2::element_text(colour = "#51656B", size = 8.5),
    legend.position = "right",
    legend.box = "vertical",
    legend.title = ggplot2::element_text(colour = ink, size = 9.2),
    legend.text = ggplot2::element_text(colour = "#52646A", size = 8.3),
    legend.spacing.y = grid::unit(5, "mm"),
    plot.margin = ggplot2::margin(14, 12, 10, 12)
  )

inset_map <- ggplot2::ggplot() +
  ggplot2::geom_sf(
    data = north_america_land,
    fill = "#E3E0D8",
    colour = "#9D9A91",
    linewidth = 0.18
  ) +
  ggplot2::geom_sf(
    data = focus_box,
    fill = event_fill,
    colour = event_outline,
    linewidth = 0.65,
    alpha = 0.92
  ) +
  ggplot2::coord_sf(crs = north_america_crs, datum = NA, expand = FALSE) +
  ggplot2::labs(title = "Location in North America") +
  ggplot2::theme_void(base_family = "sans") +
  ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = water_fill, colour = NA),
    plot.background = ggplot2::element_rect(
      fill = "white", colour = "#68777B", linewidth = 0.45
    ),
    plot.title = ggplot2::element_text(
      colour = ink, face = "bold", size = 9, hjust = 0.04,
      margin = ggplot2::margin(3, 0, 2, 0)
    ),
    plot.margin = ggplot2::margin(4, 4, 4, 4)
  )

draw_map <- function(device, path, main = main_map, inset = inset_map) {
  device(path)
  print(main)
  grid::pushViewport(grid::viewport(
    x = grid::unit(0.655, "npc"),
    y = grid::unit(0.752, "npc"),
    width = grid::unit(0.255, "npc"),
    height = grid::unit(0.205, "npc")
  ))
  print(inset, newpage = FALSE)
  grid::popViewport()
  grDevices::dev.off()
}

sog_spawn_ebird_map <- list(
  main = main_map,
  inset = inset_map,
  draw = draw_map,
  source_data = list(
    checklist_cells_10km = checklist_hex,
    herring_cells_10km = herring_hex
  ),
  release_rules = list(
    crs = map_crs,
    hex_cellsize_m = hex_cellsize_m,
    checklist_release_threshold = checklist_release_threshold
  )
)

if (save_map_outputs_enabled) {
  dir.create(dirname(output_png), recursive = TRUE, showWarnings = FALSE)

  draw_map(
    function(path) {
      grDevices::png(
        filename = path,
        width = 2700,
        height = 3000,
        res = 300,
        type = "cairo",
        bg = "white"
      )
    },
    output_png
  )
  draw_map(
    function(path) {
      grDevices::cairo_pdf(
        filename = path,
        width = 9,
        height = 10,
        bg = "white"
      )
    },
    output_pdf
  )
  draw_map(
    function(path) {
      grDevices::svg(
        filename = path,
        width = 9,
        height = 10,
        bg = "white"
      )
    },
    output_svg
  )
}

message(
  "Map complete: ", format(nrow(frame), big.mark = ","), " checklists; ",
  format(nrow(herring_points), big.mark = ","), " linked herring events; ",
  format(nrow(checklist_hex), big.mark = ","), " released checklist cells; ",
  format(sum(checklist_counts < checklist_release_threshold & checklist_counts > 0L),
         big.mark = ","), " checklist cells suppressed."
)
if (save_map_outputs_enabled) {
  message("Wrote ", output_png)
  message("Wrote ", output_pdf)
  message("Wrote ", output_svg)
} else {
  message("Created editable `main_map` and `inset_map` ggplot2 objects without exporting.")
}
