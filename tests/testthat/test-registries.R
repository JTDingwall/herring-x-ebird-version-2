source("R/assert.R")
source("R/species_registry.R")
source("R/model_registry.R")

test_that("species and guild registries are complete", {
  species <- read_species_registry()
  guilds <- read_guild_registry()
  expect_equal(nrow(species), 47L)
  expect_equal(sum(species$status == "include_v2"), 45L)
  expect_silent(validate_species_guilds(species, guilds))
})

test_that("model ids are unique", {
  models <- read_model_registry()
  expect_false(anyDuplicated(models$id) > 0)
  expect_true(all(c("primary", "supporting", "exploratory", "validation", "confirmation", "descriptive", "prerequisite", "bias_diagnostic", "sensitivity") %in% unique(models$tier)))
})
