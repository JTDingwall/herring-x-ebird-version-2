#!/usr/bin/env Rscript

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_paths <- c(
  Sys.getenv("EDITORIAL_GLMMTMB_LIBRARY", ""),
  Sys.getenv("EDITORIAL_R_LIBRARY", "")
)
library_paths <- library_paths[nzchar(library_paths)]
if (length(library_paths)) .libPaths(c(library_paths, .libPaths()))

packages <- c(
  "data.table", "digest", "lme4", "yaml", "ggplot2", "glmmTMB", "TMB"
)
loaded <- vapply(packages, function(package) {
  suppressPackageStartupMessages(
    require(package, character.only = TRUE, quietly = TRUE)
  )
}, logical(1L))
if (!all(loaded)) {
  stop(
    "Missing packages for session record: ",
    paste(packages[!loaded], collapse = ", "),
    call. = FALSE
  )
}

output_path <- file.path(
  "outputs", "editorial_requested_analysis_v1", "session_info.txt"
)
session <- capture.output(sessionInfo())
session <- sub("[[:space:]]+$", "", session)
writeLines(session, output_path, useBytes = TRUE)
message("EDITORIAL_SESSION_INFO_GATE=PASS")
