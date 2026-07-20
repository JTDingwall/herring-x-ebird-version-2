library(data.table)
project_root <- normalizePath(file.path(getwd(), "..", ".."), winslash = "/", mustWork = TRUE)
repo_file <- function(...) file.path(project_root, ...)
for (file in c("assert.R", "config.R", "join_assertions.R", "input_manifest.R",
               "ebird_ingestion.R", "herring_event_engineering.R", "exposure_surfaces.R",
               "spatial_linkage.R", "species_registry.R", "model_registry.R", "privacy_scan.R")) {
  source(repo_file("R", file))
}
