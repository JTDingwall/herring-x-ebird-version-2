#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)

root <- "outputs/post_stage4a_descriptive_summaries_v1"
required <- c(
  file.path(root, "spawn_event_summaries.csv"),
  file.path(root, "spawn_season_by_year.csv"),
  file.path(root, "assemblage_by_zone_period.csv"),
  file.path(root, "assemblage_top_species.csv"),
  file.path(root, "assemblage_guild_shares.csv"),
  file.path(root, "execution_record_v1.yml"),
  "DESCRIPTIVE_SUMMARIES_REPORT.md"
)
if (!all(file.exists(required))) {
  stop("VALIDATION_OUTPUT_GATE: required output unavailable",
       call. = FALSE)
}

read_csv <- function(name) {
  utils::read.csv(
    file.path(root, name),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
spawn <- read_csv("spawn_event_summaries.csv")
season <- read_csv("spawn_season_by_year.csv")
cell <- read_csv("assemblage_by_zone_period.csv")
top <- read_csv("assemblage_top_species.csv")
guild <- read_csv("assemblage_guild_shares.csv")
execution <- yaml::read_yaml(file.path(root, "execution_record_v1.yml"))

if (
    !identical(sort(unique(spawn$item_order)), 1:8) ||
      nrow(cell) != 4L ||
      !setequal(
        cell$cell,
        c("near_pre", "near_active", "reference_pre", "reference_active")
      ) ||
      any(cell$checklists < 20L) ||
      nrow(top) != 20L ||
      !setequal(
        top$ranking_metric,
        c(
          "percentage_of_checklists",
          "summed_numeric_individuals_lower_bound"
        )
      ) ||
      !all(vapply(
        split(top$rank, top$ranking_metric),
        identical, logical(1L), 1:10
      )) ||
      all(cell$percent_positive_records_unquantified_x == 0) ||
      any(cell$percent_positive_records_unquantified_x < 0 |
            cell$percent_positive_records_unquantified_x > 100) ||
      any(trimws(top$display_value) != top$display_value) ||
      !isTRUE(all.equal(
        sum(guild$share_of_registered_richness_percent),
        100, tolerance = 1e-8
      ))
) {
  stop("VALIDATION_STRUCTURE_GATE: descriptive structure changed",
       call. = FALSE)
}

small_spawn_counts <- spawn$release_type == "count" &
  !is.na(spawn$value_numeric) &
  spawn$value_numeric > 0 & spawn$value_numeric < 20
small_top_counts <-
  top$ranking_metric == "summed_numeric_individuals_lower_bound" &
  top$value > 0 & top$value < 20
if (
    any(small_spawn_counts) ||
      any(small_top_counts) ||
      any(cell$checklists > 0 & cell$checklists < 20)
) {
  stop("VALIDATION_SUPPRESSION_GATE: released count below 20",
       call. = FALSE)
}

forbidden_columns <- c(
  "analysis_event_token", "event_block_token", "observer_cluster_token",
  "location_cluster_token", "herring_source_token", "longitude", "latitude",
  "locality", "location_key", "checklist_id", "observer_id"
)
released_names <- tolower(unlist(lapply(
  list(spawn, season, cell, top, guild), names
)))
if (any(vapply(
    forbidden_columns,
    function(x) any(grepl(x, released_names, fixed = TRUE)),
    logical(1L)
))) {
  stop("VALIDATION_PRIVACY_GATE: identifying column released",
       call. = FALSE)
}

if (
    !identical(execution$analysis_guards$models_fitted, FALSE) ||
      !identical(
        execution$analysis_guards$statistical_tests_run, FALSE
      ) ||
      !identical(execution$analysis_guards$p_values_produced, FALSE) ||
      !identical(execution$analysis_guards$maximum_response_year, 2025L) ||
      !identical(execution$analysis_guards$start_date_anchor, TRUE)
) {
  stop("VALIDATION_SCOPE_GATE: execution guard changed",
       call. = FALSE)
}

report <- readLines(
  "DESCRIPTIVE_SUMMARIES_REPORT.md",
  warn = FALSE,
  encoding = "UTF-8"
)
headings <- c(
  "## 1. Table 2",
  "## 2. Spawn paragraph values",
  "## 3. Assemblage paragraph values",
  "## 4. Records omitted or unavailable",
  "## 5. Values I advise against reporting"
)
positions <- vapply(
  headings,
  function(x) {
    hit <- grep(x, report, fixed = TRUE)
    if (!length(hit)) NA_integer_ else hit[[1L]]
  },
  integer(1L)
)
if (anyNA(positions) || is.unsorted(positions, strictly = TRUE)) {
  stop("VALIDATION_REPORT_ORDER_GATE: manuscript mapping changed",
       call. = FALSE)
}
report_text <- paste(report, collapse = "\n")
if (grepl(
    "\\bp\\s*[<=>]\\s*0?\\.[0-9]+|confidence interval|standard error",
    report_text,
    ignore.case = TRUE,
    perl = TRUE
)) {
  stop("VALIDATION_INFERENCE_GATE: inferential result detected",
       call. = FALSE)
}

manifest_path <- file.path(root, "output_hash_manifest_v1.csv")
if (!file.exists(manifest_path)) {
  stop("VALIDATION_MANIFEST_GATE: output manifest unavailable",
       call. = FALSE)
}
manifest <- utils::read.csv(
  manifest_path, stringsAsFactors = FALSE, check.names = FALSE
)
manifest_index <- match(gsub("\\\\", "/", required), manifest$file)
if (anyNA(manifest_index)) {
  stop("VALIDATION_MANIFEST_GATE: required output omitted",
       call. = FALSE)
}
actual_hashes <- vapply(required, .post_stage4a_sha256_v1, character(1L))
if (!identical(
    unname(manifest$sha256[manifest_index]),
    unname(actual_hashes)
)) {
  stop("VALIDATION_MANIFEST_GATE: output hash mismatch",
       call. = FALSE)
}

message("POST_STAGE4A_DESCRIPTIVE_SUMMARIES_VALIDATION=PASS")
