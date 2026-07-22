library(data.table)
project_root <- normalizePath(file.path(getwd(), "..", ".."), winslash = "/", mustWork = TRUE)
repo_file <- function(...) file.path(project_root, ...)
for (file in c("assert.R", "config.R", "join_assertions.R", "input_manifest.R",
               "ebird_ingestion.R", "herring_event_engineering.R", "exposure_surfaces.R",
               "spatial_linkage.R", "dfo_survey_effort.R", "post_stage4a_audit.R", "species_registry.R",
               "model_registry.R", "privacy_scan.R", "stage4a_pooling_repair_spec_v2.R",
               "stage4a_pooling_repair_execute_v2.R", "stage4a_pooling_report_v2.R",
               "stage4a_publication_sensitivity_v2.R",
               "stage4a_publication_report_v2.R")) {
  source(repo_file("R", file))
}
