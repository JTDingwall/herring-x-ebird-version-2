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
  file.path("R", "post_stage4a_gwgu_distance_band_sensitivity_v1.R"),
  local = FALSE
)

if (mode == "fixture") {
  boundaries <- c(0, 1.999, seq(2, 26, by = 2))
  links <- data.frame(
    analysis_event_token = sprintf("edge_%02d", seq_along(boundaries)),
    event_day = 0L,
    distance_km = boundaries,
    link_provenance__ = "new_20_26",
    stringsAsFactors = FALSE
  )
  classified <- post_stage4a_gwgu_classify_distance_band_links_v1(links)
  expected <- c(
    "band_0_2", "band_0_2",
    paste0("band_", seq(2, 24, by = 2), "_", seq(4, 26, by = 2)),
    "band_24_26"
  )
  stopifnot(identical(classified$band, expected))

  boundary_20 <- data.frame(
    analysis_event_token = c("archived", "new"),
    event_day = 0L,
    distance_km = c(20, 20),
    link_provenance__ = c("archived_0_20", "new_20_26"),
    stringsAsFactors = FALSE
  )
  stopifnot(identical(
    post_stage4a_gwgu_classify_distance_band_links_v1(boundary_20)$band,
    c("band_18_20", "band_20_22")
  ))

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
    analysis_event_token = c("a", "a", "a", "b"),
    region = "SoG",
    checklist_year = 2020L,
    event_day = c(0L, 4L, 15L, -15L),
    distance_km = c(1, 5, 25, 10),
    link_provenance__ = c(
      "archived_0_20", "archived_0_20",
      "new_20_26", "archived_0_20"
    ),
    stringsAsFactors = FALSE
  )
  joint <- post_stage4a_gwgu_add_distance_band_exposure_v1(
    events, paired_links
  )
  stopifnot(
    nrow(joint$events) == nrow(events),
    !anyDuplicated(joint$events$analysis_event_token),
    joint$events$concurrent_links_0_26[[1L]] == 3L,
    joint$events$db_band_0_2_spawn_start[[1L]] == 1L,
    joint$events$db_band_4_6_early_egg[[1L]] == 1L,
    joint$events$db_band_24_26_late_egg[[1L]] == 1L,
    joint$events$db_band_10_12_baseline[[2L]] == 1L,
    length(post_stage4a_gwgu_distance_band_terms_v1()) == 78L
  )

  definitions <- post_stage4a_gwgu_distance_band_contrasts_v1(
    c("(Intercept)", post_stage4a_gwgu_distance_band_terms_v1())
  )
  target <- definitions[[
    which(vapply(
      definitions,
      function(x) {
        identical(x$band, "band_24_26") &&
          identical(x$period, "active_0_14")
      },
      logical(1L)
    ))
  ]]
  stopifnot(
    isTRUE(all.equal(
      target$vector[["db_band_24_26_spawn_start"]], 4 / 15
    )),
    isTRUE(all.equal(
      target$vector[["db_band_24_26_early_egg"]], 11 / 15
    )),
    isTRUE(all.equal(
      target$vector[["db_band_24_26_baseline"]], -1
    ))
  )
  message("POST_STAGE4A_GWGU_DISTANCE_BAND_SENSITIVITY_V1_FIXTURE=PASS")
  quit(status = 0L)
}

code_files <- c(
  "R/post_stage4a_gwgu_distance_band_sensitivity_v1.R",
  "scripts/run_post_stage4a_gwgu_distance_band_sensitivity_v1.R",
  "scripts/run_post_stage4a_gwgu_distance_band_sensitivity_v1.ps1",
  "scripts/postprocess_gwgu_distance_band_sensitivity_v1.R",
  "scripts/build_post_stage4a_distance_26km_links_v2.ps1",
  "scripts/preflight_post_stage4a_gwgu_distance_bands_v1.R",
  "metadata/post_stage4a_gwgu_distance_band_sensitivity_spec_v1.yml",
  "metadata/post_stage4a_gwgu_distance_band_sensitivity_authorization_v1.yml",
  "tests/testthat/test-post-stage4a-gwgu-distance-band-sensitivity-v1.R"
)
dirty <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all", "--", code_files),
  stdout = TRUE,
  stderr = TRUE
)
if (length(dirty) && any(nzchar(dirty))) {
  stop(
    "Production is blocked until the gull v1 code and specification are committed",
    call. = FALSE
  )
}
execution_code_commit <- system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
)
if (length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)) {
  stop("Unable to resolve committed gull v1 execution code", call. = FALSE)
}
run_post_stage4a_gwgu_distance_band_sensitivity_v1(
  execution_code_commit = execution_code_commit
)
