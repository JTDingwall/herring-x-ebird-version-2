args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "fixture"
if (!mode %in% c("fixture", "production")) stop("mode must be fixture or production")

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
source(file.path("R", "stage4a_core.R"), local = FALSE)

registry <- read.csv(file.path("metadata", "model_registry.csv"),
                     stringsAsFactors = FALSE, check.names = FALSE)
disposition <- read.csv(file.path("metadata", "stage4a_model_disposition_v1.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)
stage4a_validate_disposition(registry, disposition)

if (mode == "fixture") {
  stage4a_fixture()
  message("STAGE4A_FIXTURE_GATE=PASS")
  quit(status = 0L)
}

if (!identical(Sys.getenv("STAGE4A_AUTHORIZED_RESPONSE_ACCESS"),
               "through_2025_after_lock_ci")) {
  stop("Production requires the post-lock Stage 4A response-access acknowledgement")
}

source(file.path("R", "stage4a_production.R"), local = FALSE)
run_stage4a_production()
