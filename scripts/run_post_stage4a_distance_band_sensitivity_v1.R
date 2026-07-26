#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
if (!mode %in% c("fixture", "production")) {
  stop("mode must be fixture or production", call. = FALSE)
}

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(file.path("R", "post_stage4a_sog_event_study_v1.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_distance_band_sensitivity_v1.R"),
  local = FALSE
)

if (mode == "fixture") {
  links <- data.frame(
    analysis_event_token = sprintf("edge_%02d", 1:13),
    event_day = c(
      -29L, -28L, -15L, -14L, -8L, -7L, -1L,
      0L, 3L, 4L, 14L, 15L, 28L
    ),
    distance_km = c(
      0, 1.999, 2, 3.999, 4, 5.999, 6,
      7.999, 8, 9.999, 10, 10.001, 20
    ),
    stringsAsFactors = FALSE
  )
  classified <- post_stage4a_classify_distance_band_links_v1(links)
  stopifnot(
    identical(
      classified$period,
      c(
        NA_character_, "baseline", "baseline", "early_pre", "early_pre",
        "immediate_pre", "immediate_pre", "spawn_start", "spawn_start",
        "early_egg", "early_egg", "late_egg", "late_egg"
      )
    ),
    identical(
      classified$band,
      c(
        "band_0_2", "band_0_2", "band_2_4", "band_2_4",
        "band_4_6", "band_4_6", "band_6_8", "band_6_8",
        "band_8_10", "band_8_10", "band_8_10",
        "band_10_20", "band_10_20"
      )
    )
  )

  events <- data.frame(
    analysis_event_token = c("a", "b"),
    event_block_token = c("block_a", "block_b"),
    observer_cluster_token = c("observer_a", "observer_b"),
    location_cluster_token = c("location_a", "location_b"),
    region = c("SoG", "SoG"),
    checklist_year = c(2020L, 2020L),
    concurrent_links = c(2L, 1L),
    stringsAsFactors = FALSE
  )
  paired_links <- data.frame(
    analysis_event_token = c("a", "a", "b"),
    region = c("SoG", "SoG", "SoG"),
    checklist_year = c(2020L, 2020L, 2020L),
    event_day = c(0L, 4L, -15L),
    distance_km = c(1, 5, 10),
    stringsAsFactors = FALSE
  )
  joint <- post_stage4a_add_distance_band_exposure_v1(
    events, paired_links
  )
  stopifnot(
    nrow(joint$events) == nrow(events),
    !anyDuplicated(joint$events$analysis_event_token),
    joint$events$db_band_0_2_spawn_start[[1L]] == 1L,
    joint$events$db_band_4_6_early_egg[[1L]] == 1L,
    joint$events$db_band_8_10_baseline[[2L]] == 1L,
    sum(joint$events[post_stage4a_distance_band_terms_v1()]) == 3L
  )

  coefficient_names <- c(
    "(Intercept)", post_stage4a_distance_band_terms_v1()
  )
  definitions <- post_stage4a_distance_band_contrasts_v1(
    coefficient_names
  )
  active <- definitions[[
    which(vapply(
      definitions,
      function(x) {
        identical(x$band, "band_0_2") &&
          identical(x$period, "active_0_14")
      },
      logical(1L)
    ))
  ]]
  early_egg <- definitions[[
    which(vapply(
      definitions,
      function(x) {
        identical(x$band, "band_2_4") &&
          identical(x$period, "early_egg")
      },
      logical(1L)
    ))
  ]]
  stopifnot(
    isTRUE(all.equal(
      active$vector[["db_band_0_2_spawn_start"]], 4 / 15
    )),
    isTRUE(all.equal(
      active$vector[["db_band_0_2_early_egg"]], 11 / 15
    )),
    isTRUE(all.equal(
      active$vector[["db_band_0_2_baseline"]], -1
    )),
    isTRUE(all.equal(
      early_egg$vector[["db_band_2_4_early_egg"]], 1
    )),
    isTRUE(all.equal(
      early_egg$vector[["db_band_2_4_baseline"]], -1
    ))
  )
  message("POST_STAGE4A_DISTANCE_BAND_SENSITIVITY_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  "R/post_stage4a_distance_band_sensitivity_v1.R",
  "scripts/run_post_stage4a_distance_band_sensitivity_v1.R",
  "scripts/run_post_stage4a_distance_band_sensitivity_v1.ps1",
  "metadata/post_stage4a_distance_band_sensitivity_spec_v1.yml",
  "metadata/post_stage4a_distance_band_sensitivity_authorization_v1.yml",
  "tests/testthat/test-post-stage4a-distance-band-sensitivity-v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Production is blocked until the distance-band code and specification are committed",
    call. = FALSE
  )
}
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)) {
  stop("Unable to resolve the committed execution code", call. = FALSE)
}
run_post_stage4a_distance_band_sensitivity_v1(
  execution_code_commit = execution_code_commit
)
