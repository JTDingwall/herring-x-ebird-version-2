test_that("post-Stage4A issue crosswalk contains R1 through R31 exactly once", {
  x <- utils::read.csv(
    repo_file("metadata", "post_stage4a_review_issue_crosswalk.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  expected_columns <- c(
    "issue_id", "original_claim", "scientific_status", "implementation_status",
    "exact_existing_files", "exact_existing_functions", "exact_existing_tests",
    "active_stage4a_code_path", "stage4a_relevance",
    "potential_stage4a_result_impact", "prospective_relevance", "required_action",
    "human_decision_required", "external_data_required", "evidence", "notes"
  )
  expect_identical(names(x), expected_columns)
  expect_equal(nrow(x), 31L)
  expect_equal(anyDuplicated(x$issue_id), 0L)
  expect_setequal(x$issue_id, paste0("R", 1:31))
  expect_identical(x$implementation_status[x$issue_id == "R10"],
                   "IMPLEMENTED_BUT_DEFECTIVE")
  expect_identical(x$potential_stage4a_result_impact[x$issue_id == "R10"],
                   "CONFIRMED_MATERIAL_STAGE4A_IMPACT")
})

test_that("estimand and model progression gates are complete and unique", {
  estimands <- utils::read.csv(
    repo_file("metadata", "estimand_progression_gate.csv"), stringsAsFactors = FALSE
  )
  models <- utils::read.csv(
    repo_file("metadata", "model_progression_gate.csv"), stringsAsFactors = FALSE
  )
  registry <- utils::read.csv(
    repo_file("metadata", "model_registry.csv"), stringsAsFactors = FALSE
  )
  expect_equal(nrow(estimands), 15L)
  expect_equal(anyDuplicated(estimands$estimand_id), 0L)
  expect_setequal(estimands$estimand_id, sprintf("E%02d", 1:15))
  expect_equal(nrow(models), 45L)
  expect_equal(anyDuplicated(models$model_id), 0L)
  expect_identical(models$model_id, registry$model_id)
  expect_identical(
    models$recommended_next_stage[models$model_id == "M31"],
    "PROSPECTIVE_LOCKED"
  )
})

test_that("prospective amendment is explicitly post-result draft and holdout locked", {
  amendment <- yaml::read_yaml(
    repo_file("metadata", "prospective_confirmation_amendment_draft.yml")
  )
  expect_identical(amendment$status, "DRAFT_PENDING_HUMAN_APPROVAL")
  expect_false(amendment$authority$signed)
  expect_false(amendment$authority$approved)
  expect_false(amendment$authority$frozen)
  expect_false(amendment$authority$authoritative)
  expect_true(amendment$chronology$created_after_stage4a_development_results_existed)
  expect_false(amendment$chronology$retroactively_modifies_stage4a)
  expect_true(amendment$prospective_holdout$remains_inaccessible)
  expect_equal(unlist(amendment$prospective_holdout$years), 2026:2028)
})

test_that("reconciliation is based on PR2 and leaves historical Stage4A path untouched", {
  manifest <- yaml::read_yaml(
    repo_file("metadata", "post_stage4a_branch_reconciliation.yml")
  )
  expect_identical(manifest$working_branch$based_on_sha,
                   "dae0be997a940c7e95c900f64d81500769c5f836")
  expect_identical(manifest$branches$pr3$head_sha,
                   "f887b6895ff4caaf495295443258b784e81d2224")
  expect_false(manifest$stage4a_result_artifacts$original_outputs_modified_by_reconciliation)

  production <- paste(readLines(repo_file("R", "stage4a_production.R"), warn = FALSE),
                      collapse = "\n")
  builder <- paste(readLines(repo_file("scripts", "Stage4AProtectedBuilder.cs"),
                             warn = FALSE), collapse = "\n")
  executed_path <- paste(production, builder, sep = "\n")
  expect_false(grepl("zero_fill_taxa\\s*\\(", executed_path))
  expect_false(grepl("candidate_event_links\\s*\\(", executed_path))
  expect_false(grepl("derive_herring_event_fields\\s*\\(", executed_path))
})

test_that("active instructions use current authority and model-specific gates", {
  active_files <- c("AGENTS.md", "README.md", "prompts/00_CODEX_MASTER_PROMPT.md")
  active <- paste(vapply(active_files, function(path) {
    full_path <- do.call(repo_file, as.list(strsplit(path, "/", fixed = TRUE)[[1]]))
    paste(readLines(full_path, warn = FALSE),
          collapse = "\n")
  }, character(1)), collapse = "\n")
  expect_true(grepl("Stage 4A", active, fixed = TRUE))
  expect_true(grepl("PR #3 is advisory", active, fixed = TRUE))
  expect_true(grepl("model-specific", active, fixed = TRUE))
  forbidden <- c(
    "target-group background fixes DFO exposure",
    "herring kernel is a fusion design",
    "directional hypotheses inherently invalidate negative controls",
    "PR #3 is automatically authoritative",
    "all S2 blocks all response models"
  )
  expect_false(any(vapply(tolower(forbidden), grepl, logical(1),
                          x = tolower(active), fixed = TRUE)))
})
