read_model_registry <- function(path = "metadata/model_registry.csv") {
  dt <- data.table::fread(path)
  required <- c("model_id", "estimand_id", "module_id", "priority", "model_family",
                "level", "response_class", "candidate_engine", "status")
  assert_columns(dt, required, "model registry")
  assert_unique_key(dt, "model_id", "model registry")
  dt
}

read_estimand_registry <- function(path = "metadata/estimand_registry.csv") {
  dt <- data.table::fread(path)
  assert_columns(dt, c("estimand_id", "estimand_label", "unit_of_analysis", "quantity",
                       "outcome_state_policy", "approval_status"), "estimand registry")
  assert_unique_key(dt, "estimand_id", "estimand registry")
  dt
}

validate_model_foreign_keys <- function(models, estimands, modules) {
  bad_estimands <- setdiff(models$estimand_id, estimands$estimand_id)
  bad_modules <- setdiff(models$module_id, modules$module_id)
  if (length(bad_estimands)) stop("Undefined estimands: ", paste(bad_estimands, collapse = ", "), call. = FALSE)
  if (length(bad_modules)) stop("Undefined modules: ", paste(bad_modules, collapse = ", "), call. = FALSE)
  invisible(TRUE)
}

read_analysis_module_registry <- function(path = "metadata/analysis_module_registry.csv") {
  dt <- data.table::fread(path)
  assert_columns(dt, c("module_id", "priority", "analysis", "estimand_ids", "model_ids",
                       "outcome_class", "status"), "analysis module registry")
  assert_unique_key(dt, "module_id", "analysis module registry")
  dt
}

validate_registry_bundle <- function(root = ".") {
  species <- read_species_registry(file.path(root, "metadata", "canonical_species_registry.csv"))
  guilds <- read_guild_registry(file.path(root, "metadata", "canonical_guild_registry.csv"))
  estimands <- read_estimand_registry(file.path(root, "metadata", "estimand_registry.csv"))
  models <- read_model_registry(file.path(root, "metadata", "model_registry.csv"))
  modules <- read_analysis_module_registry(file.path(root, "metadata", "analysis_module_registry.csv"))
  validate_species_guilds(species, guilds)
  validate_model_foreign_keys(models, estimands, modules)
  list(species = nrow(species), guilds = nrow(guilds), estimands = nrow(estimands),
       models = nrow(models), cooccurrence = nrow(data.table::fread(file.path(root, "metadata", "cooccurrence_registry.csv"))),
       modules = nrow(modules))
}
