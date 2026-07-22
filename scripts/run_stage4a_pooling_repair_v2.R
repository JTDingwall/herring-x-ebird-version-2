#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args)) args[[1L]] else file.path("outputs", "stage4a_pooling_repair_v2")
pre_execution_spec_commit <- "bee142b6878bb66d57910c5aee57e4097fb2adf9"
execution_code_files <- c(
  "R/stage4a_pooling_repair_spec_v2.R",
  "R/stage4a_pooling_repair_execute_v2.R",
  "scripts/run_stage4a_pooling_repair_v2.R"
)
execution_code_commit <- system2(
  "git", c("log", "-1", "--format=%H", "--", execution_code_files), stdout = TRUE
)
if (length(execution_code_commit) != 1L || !nzchar(execution_code_commit)) {
  stop("Unable to resolve execution code commit")
}
source(file.path("R", "assert.R"))
source(file.path("R", "stage4a_pooling_repair_spec_v2.R"))
source(file.path("R", "stage4a_pooling_repair_execute_v2.R"))
stage4a_pooling_v2_execute(
  repo_root = ".", output_dir = output_dir,
  pre_execution_spec_commit = pre_execution_spec_commit,
  execution_code_commit = execution_code_commit
)
message("Stage 4A aggregate pooling repair v2 complete: ", output_dir)
