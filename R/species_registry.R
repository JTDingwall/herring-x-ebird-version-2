read_species_registry <- function(path = "metadata/species_registry_v2.csv") {
  x <- data.table::fread(path)
  required <- c("legacy_analysis_taxon_id", "common_name", "guild_id", "v2_analysis_role", "status")
  assert_columns(x, required, "species registry")
  assert_unique_key(x, "legacy_analysis_taxon_id", "species registry")
  if (anyDuplicated(x$common_name)) stop("Species common names must be unique", call. = FALSE)
  x
}

read_guild_registry <- function(path = "metadata/guild_registry_v2.csv") {
  x <- data.table::fread(path)
  assert_columns(x, c("guild_id", "guild_label", "mechanism", "analysis_priority"), "guild registry")
  assert_unique_key(x, "guild_id", "guild registry")
  x
}

validate_species_guilds <- function(species, guilds) {
  missing <- setdiff(unique(species$guild_id), guilds$guild_id)
  if (length(missing)) stop("Species reference undefined guilds: ", paste(missing, collapse = ", "), call. = FALSE)
  invisible(TRUE)
}
