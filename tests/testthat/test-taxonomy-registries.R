test_that("taxonomy crosswalk keys and ambiguity rules are auditable", {
  x <- fread(repo_file("metadata", "source_taxonomy_crosswalk.csv"))
  a <- fread(repo_file("metadata", "ambiguous_taxon_rules.csv"))
  expect_false(anyDuplicated(x[, .(source_taxon_id, parent_candidate_name, final_mapping_decision)]) > 0)
  expect_true(all(a$ambiguity_flag))
  expect_true(all(a$final_rule != ""))
})

test_that("canonical registry counts and foreign keys reconcile", {
  counts <- validate_registry_bundle(project_root)
  expect_identical(unname(unlist(counts)), c(58L, 8L, 15L, 45L, 9L, 50L))
})

test_that("every registered model maps to one approved estimand and module", {
  models <- read_model_registry(repo_file("metadata", "model_registry.csv"))
  estimands <- read_estimand_registry(repo_file("metadata", "estimand_registry.csv"))
  modules <- read_analysis_module_registry(repo_file("metadata", "analysis_module_registry.csv"))
  expect_silent(validate_model_foreign_keys(models, estimands, modules))
  expect_true(all(estimands[match(models$estimand_id, estimands$estimand_id)]$approval_status == "approved_design"))
  expect_true(all(models$status == "registered_not_fitted"))
})
