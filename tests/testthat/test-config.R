test_that("configuration keeps protected paths and the outcome gate", {
  withr::local_envvar(stats::setNames(rep("", 5L), c(
    "HERRING_EBIRD_V2_EBD", "HERRING_EBIRD_V2_SED", "HERRING_EBIRD_V2_HERRING",
    "HERRING_EBIRD_V2_SHORELINE", "HERRING_EBIRD_V2_SECTIONS"
  )))
  cfg <- read_project_config(repo_file("config", "project.yml"))
  expect_identical(cfg$project$outcome_gate, "metadata_design_only")
  expect_false(cfg$analysis_policy$bird_outcomes_authorized_in_setup)
  expect_error(resolve_input_paths(cfg), "INPUT_ENV_GATE")
})

test_that("environment expansion works without persisting a path", {
  old <- Sys.getenv("V2_FIXTURE_PATH", unset = NA_character_)
  on.exit(if (is.na(old)) Sys.unsetenv("V2_FIXTURE_PATH") else Sys.setenv(V2_FIXTURE_PATH = old))
  Sys.setenv(V2_FIXTURE_PATH = "fixture-value")
  expect_identical(expand_env_scalar("${V2_FIXTURE_PATH}"), "fixture-value")
})
