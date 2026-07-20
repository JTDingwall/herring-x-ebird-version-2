read_species_registry <- function(path = "metadata/canonical_species_registry.csv") {
  x <- data.table::fread(path)
  required <- c("analysis_taxon_id", "common_name", "scientific_name", "ebird_taxon_code",
                "source_taxon_concept_ids", "taxonomy_version", "guild_ids", "priority_tier",
                "ecological_mechanism", "evidence_strength", "expected_direction",
                "expected_timing", "count_strategy", "taxonomic_complications",
                "support_status", "species_model_status", "guild_model_status", "approval_status")
  assert_columns(x, required, "species registry")
  assert_unique_key(x, "analysis_taxon_id", "species registry")
  if (anyDuplicated(x$common_name)) stop("Species common names must be unique", call. = FALSE)
  x
}

read_guild_registry <- function(path = "metadata/canonical_guild_registry.csv") {
  x <- data.table::fread(path)
  assert_columns(x, c("guild_id", "guild_label", "mechanism", "membership_rule",
                      "expected_timing", "expected_spatial_response", "primary_outcomes",
                      "dominance_audit_required", "ambiguity_bound_rule", "analysis_priority"),
                 "guild registry")
  assert_unique_key(x, "guild_id", "guild registry")
  x
}

validate_species_guilds <- function(species, guilds) {
  memberships <- unique(unlist(strsplit(species$guild_ids, "\\|", fixed = FALSE)))
  missing <- setdiff(memberships, guilds$guild_id)
  if (length(missing)) stop("Species reference undefined guilds: ", paste(missing, collapse = ", "), call. = FALSE)
  invisible(TRUE)
}
