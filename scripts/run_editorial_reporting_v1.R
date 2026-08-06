#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)
source(file.path("R", "editorial_reporting_v1.R"), local = FALSE)
run_editorial_reporting_v1()
