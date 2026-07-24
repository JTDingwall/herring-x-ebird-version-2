#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)
source(file.path("R", "editorial_finite_x_correction_v1.R"), local = FALSE)

output_dir <- file.path("outputs", "editorial_requested_analysis_v1")
editorial_write_output_manifest_v1(output_dir)
message("EDITORIAL_OUTPUT_MANIFEST_GATE=PASS")
