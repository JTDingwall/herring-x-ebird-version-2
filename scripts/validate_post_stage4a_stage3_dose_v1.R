root <- "outputs/post_stage4a_stage3_dose_v1"
required <- c(
  "index_aggregation_audit.csv",
  "dose_estimates_49x2.csv",
  "dose_within_between.csv",
  "dose_lrt.csv",
  "dose_method_sensitivity.csv",
  "dose_extent_sensitivity.csv",
  "dose_effort_outcomes.csv",
  "dose_placebo_tallies.csv",
  "dose_guild_meta.csv",
  "dose_terciles_case_species.csv",
  "figures/dose_terciles_case_species.pdf",
  "figures/dose_terciles_case_species_600dpi.png",
  "execution_record_v1.yml",
  "output_hash_manifest_v1.csv"
)
paths <- file.path(root, required)
stopifnot(all(file.exists(paths)), file.exists("STAGE3_DOSE_REPORT.md"))

read <- function(name) {
  utils::read.csv(
    file.path(root, name),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
primary <- read("dose_estimates_49x2.csv")
within_between <- read("dose_within_between.csv")
lrt <- read("dose_lrt.csv")
method <- read("dose_method_sensitivity.csv")
audit <- read("index_aggregation_audit.csv")
extent <- read("dose_extent_sensitivity.csv")
effort <- read("dose_effort_outcomes.csv")
placebo <- read("dose_placebo_tallies.csv")
guild <- read("dose_guild_meta.csv")
tercile <- read("dose_terciles_case_species.csv")

stopifnot(
  nrow(primary) == 98L,
  nrow(within_between) == 196L,
  nrow(lrt) == 98L,
  nrow(method) == 98L,
  nrow(extent) == 98L,
  nrow(effort) == 3L,
  nrow(placebo) == 4L,
  nrow(guild) == 14L,
  nrow(tercile) == 12L,
  length(unique(primary$analysis_taxon_id)) == 49L,
  setequal(unique(primary$outcome), c(
    "checklist_reporting", "conditional_positive_numeric_count"
  )),
  all(primary$component == "within_location"),
  setequal(unique(within_between$component), c(
    "within_location", "between_location"
  )),
  setequal(unique(placebo$offset_days), c(-90L, 90L)),
  setequal(unique(tercile$within_year_tercile), 1:3)
)
stopifnot(
  all(method$sensitivity == "dive_only"),
  all(method$linked_candidate_events == 950L),
  all(method$surface_linked_candidate_events == 68L),
  all(method$surface_only_status ==
        "non_estimable_insufficient_method_support_68_linked_events"),
  audit$count[
    audit$metric == "events_no_recorded_component"
  ] == 125L,
  audit$count[audit$metric == "dive_observed_events"] == 950L,
  audit$count[audit$metric == "surface_observed_events"] == 68L
)

excluded <- c(
  "American Robin", "Chestnut-backed Chickadee",
  "Gadwall", "Northern Shoveler"
)
for (table in list(
    primary, within_between, lrt, method, extent, tercile
)) {
  if ("species" %in% names(table)) {
    stopifnot(!any(table$species %in% excluded))
  }
}
stopifnot(
  all(primary$full_fixed_effect_covariance_used %in% TRUE),
  all(within_between$full_fixed_effect_covariance_used %in% TRUE),
  all(guild$variance_method ==
        "inverse variance from exact full fixed-effect covariance")
)

prohibited <- c(
  "analysis_event_token", "analysis_checklist_id",
  "observer_cluster_token", "location_cluster_token",
  "event_block_token", "herring_source_token",
  "dose_event_token", "dose_location_token",
  "latitude", "longitude", "locality", "coordinates",
  "source_id", "analysis_id"
)
csv_paths <- paths[grepl("\\.csv$", paths)]
for (path in csv_paths) {
  header <- tolower(names(utils::read.csv(
    path, nrows = 1L, check.names = FALSE
  )))
  stopifnot(!length(intersect(header, prohibited)))
}

manifest <- read("output_hash_manifest_v1.csv")
stopifnot(
  !anyDuplicated(manifest$file),
  all(file.exists(manifest$file))
)
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("digest unavailable", call. = FALSE)
}
observed <- vapply(
  manifest$file,
  function(path) digest::digest(
    path, algo = "sha256", file = TRUE, serialize = FALSE
  ),
  character(1L)
)
stopifnot(identical(unname(observed), manifest$sha256))

report <- readLines("STAGE3_DOSE_REPORT.md", warn = FALSE)
sentences <- paste(report[seq_len(min(12L, length(report)))],
                   collapse = " ")
stopifnot(
  grepl("prespecified Stage 3 dose pattern", sentences, fixed = TRUE),
  grepl("post-result estimand refinement", sentences, fixed = TRUE),
  any(grepl("What this analysis does not claim", report, fixed = TRUE))
)
stopifnot(
  any(grepl(
    "surface-only set contained 68/1,120", report, fixed = TRUE
  )),
  any(grepl(
    "descriptive `0.00` for those 125 events", report, fixed = TRUE
  ))
)

execution <- yaml::read_yaml(file.path(root, "execution_record_v1.yml"))
stopifnot(
  identical(execution$population$records_2026_plus_read, 0L),
  identical(execution$population$fixed_family_species, 49L),
  identical(
    execution$parent_stage2_bh_positive$
      conditional_positive_numeric_count,
    20L
  ),
  identical(
    execution$parent_stage2_bh_positive$checklist_reporting,
    13L
  ),
  identical(execution$parent_outputs_unchanged, TRUE),
  identical(
    execution$historical_withdrawn_control_outputs_retained_unchanged,
    TRUE
  ),
  identical(
    execution$method_sensitivity$surface_only$model_fit, FALSE
  ),
  identical(
    execution$method_sensitivity$dive_only$linked_candidate_events,
    950L
  ),
  identical(
    execution$index$linked_candidates_with_no_recorded_component,
    125L
  )
)

cat("STAGE3_DOSE_VALIDATION_PASS\n")
