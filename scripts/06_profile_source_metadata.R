suppressPackageStartupMessages({library(data.table); library(yaml); library(digest)})
source("R/assert.R")
source("R/config.R")
source("R/herring_event_engineering.R")
source("R/metadata_audit.R")

paths <- resolve_input_paths(read_project_config())
sed <- profile_sed_metadata(paths[["ebird_sed"]])
herring <- profile_herring_metadata(paths[["herring_csv"]])
directory <- "outputs/input_audit_local/source_profiles"
dir.create(directory, recursive = TRUE, showWarnings = FALSE)
for (name in names(sed)) fwrite(sed[[name]], file.path(directory, paste0("sed_", name, ".csv")))
for (name in names(herring)) fwrite(herring[[name]], file.path(directory, paste0("herring_", name, ".csv")))
cat("Aggregate SED effort and herring source-metadata profiles written locally; no focal bird outcomes read.\n")
