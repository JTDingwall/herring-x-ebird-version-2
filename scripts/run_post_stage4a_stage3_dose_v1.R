args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) tolower(args[[1L]]) else "fixture"
allowed <- c("fixture", "case", "family", "sensitivities")
if (!mode %in% allowed) {
  stop(
    "Mode must be one of: ", paste(allowed, collapse = ", "),
    call. = FALSE
  )
}

source(file.path("R", "stage4a_core.R"), local = FALSE)
source(file.path("R", "stage4a_production.R"), local = FALSE)
source(
  file.path("R", "post_stage4a_sog_event_study_v1.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_staged_refit_v1.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_staged_refit_amendment_v1.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_staged_refit_stage2_v1.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_stage3_dose_v1.R"),
  local = FALSE
)
source(
  file.path("R", "post_stage4a_stage3_dose_amendment_v1.R"),
  local = FALSE
)

packages <- c("data.table", "digest", "lme4", "yaml")
missing_packages <- packages[!vapply(
  packages, requireNamespace, logical(1L), quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing packages: ", paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

if (mode == "fixture") {
  stage3_dose_fixture_v1()
  cat("STAGE3_DOSE_FIXTURE_PASS\n")
  quit(save = "no", status = 0L)
}

tracked_scope <- c(
  "R/post_stage4a_stage3_dose_v1.R",
  "R/post_stage4a_stage3_dose_amendment_v1.R",
  "scripts/run_post_stage4a_stage3_dose_v1.R",
  "scripts/run_post_stage4a_stage3_dose_v1.ps1",
  "scripts/validate_post_stage4a_stage3_dose_v1.R",
  "metadata/post_stage4a_stage3_dose_spec_v1.yml",
  "metadata/post_stage4a_stage3_dose_amendment_v1.yml",
  "metadata/data_dictionary_v2.csv"
)
status <- system2(
  "git",
  c("diff", "--quiet", "HEAD", "--", tracked_scope),
  stdout = FALSE, stderr = FALSE
)
if (!identical(status, 0L)) {
  stop(
    "STAGE3_DOSE_CODE_COMMIT_GATE: production files must be committed",
    call. = FALSE
  )
}
execution_code_commit <- trimws(system2(
  "git", c("rev-parse", "HEAD"), stdout = TRUE
))
if (
  length(execution_code_commit) != 1L ||
    !grepl("^[0-9a-f]{40}$", execution_code_commit)
) {
  stop("STAGE3_DOSE_CODE_COMMIT_GATE: unresolved HEAD", call. = FALSE)
}
herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
if (!nzchar(herring_path)) {
  herring_path <- file.path(
    "data", "raw",
    "Pacific_herring_spawn_index_data_2025_EN_frozen_crlf.csv"
  )
}

if (mode == "case") {
  run_post_stage4a_stage3_dose_case_v1(
    execution_code_commit, herring_path
  )
  cat("STAGE3_DOSE_CHECKPOINT_1_PASS\n")
} else if (mode == "family") {
  marker <- yaml::read_yaml(file.path(
    "data", "derived", "post_stage4a_stage3_dose_v1",
    "checkpoint_1_complete.yml"
  ))
  primary_model_code_commit <- marker$execution_code_commit
  core_status <- system2(
    "git",
    c(
      "diff", "--quiet", primary_model_code_commit, "--",
      "R/post_stage4a_stage3_dose_v1.R"
    ),
    stdout = FALSE, stderr = FALSE
  )
  if (!identical(core_status, 0L)) {
    stop(
      "STAGE3_DOSE_PRIMARY_CODE_GATE: checkpoint 1 core changed",
      call. = FALSE
    )
  }
  run_post_stage4a_stage3_dose_family_v1(
    primary_model_code_commit, herring_path
  )
  cat("STAGE3_DOSE_CHECKPOINT_2_PASS\n")
} else if (mode == "sensitivities") {
  marker <- yaml::read_yaml(file.path(
    "data", "derived", "post_stage4a_stage3_dose_v1",
    "checkpoint_1_complete.yml"
  ))
  primary_model_code_commit <- marker$execution_code_commit
  core_status <- system2(
    "git",
    c(
      "diff", "--quiet", primary_model_code_commit, "--",
      "R/post_stage4a_stage3_dose_v1.R"
    ),
    stdout = FALSE, stderr = FALSE
  )
  if (!identical(core_status, 0L)) {
    stop(
      "STAGE3_DOSE_PRIMARY_CODE_GATE: checkpoint 1 core changed",
      call. = FALSE
    )
  }
  run_post_stage4a_stage3_dose_amended_sensitivities_v1(
    primary_model_code_commit, execution_code_commit, herring_path
  )
  cat("STAGE3_DOSE_CHECKPOINT_3_PASS\n")
}
