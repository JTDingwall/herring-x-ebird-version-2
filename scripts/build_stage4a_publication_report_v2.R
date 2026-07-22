#!/usr/bin/env Rscript

source(file.path("R", "assert.R"))
source(file.path("R", "stage4a_pooling_repair_spec_v2.R"))
source(file.path("R", "stage4a_pooling_repair_execute_v2.R"))
source(file.path("R", "stage4a_pooling_report_v2.R"))
source(file.path("R", "stage4a_publication_report_v2.R"))
result <- build_stage4a_publication_report_v2(".")
message("Stage 4A publication report v2 written: ", result$report)
