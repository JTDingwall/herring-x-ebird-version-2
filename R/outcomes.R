# Backward-compatible names for the generalized count-state utilities.
parse_ebird_count <- parse_ebird_count_state

build_guild_outcomes <- function(checklist_species, species_registry) {
  assert_join_cardinality(checklist_species, species_registry,
    c("analysis_taxon_id" = "analysis_taxon_id"), "many-to-one", "species-to-guild registry")
  if (any(grepl("\\|", species_registry$guild_ids))) {
    stop("Multi-guild species must be expanded under an explicit registered membership rule", call. = FALSE)
  }
  registry <- species_registry[, .(analysis_taxon_id, guild_id = guild_ids)]
  x <- merge(checklist_species, registry,
             by = "analysis_taxon_id", all.x = TRUE, sort = FALSE)
  assert_join_row_accounting(nrow(checklist_species), nrow(x), "many-to-one", "species-to-guild registry")
  guild_count_bounds(x)
}
