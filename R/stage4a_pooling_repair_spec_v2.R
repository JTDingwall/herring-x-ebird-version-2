stage4a_pooling_v2_version <- function() "stage4a_aggregate_pooling_repair_spec_v2"

stage4a_pooling_v2_reason_codes <- function() {
  c(
    INCLUDED_PRIMARY_REPRESENTATION = "Eligible primary representation",
    EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION = "M11/M12 duplicates an M01/M02 hurdle component",
    NON_ESTIMABLE_SINGLETON = "Fewer than two eligible components",
    NON_ESTIMABLE_MISSING_INPUT = "A required future numeric input is missing",
    NON_ESTIMABLE_NONFINITE_INPUT = "A required future numeric input is non-finite",
    NON_ESTIMABLE_NONPOSITIVE_STANDARD_ERROR = "A future standard error is not positive",
    INCOMPATIBLE_SCALE = "Component scale is incompatible with the frozen family",
    IDENTITY_MISSING = "A required registered identity field is missing or ambiguous",
    IDENTITY_COLLISION = "Distinct canonical identities produced the same identifier",
    FAMILY_COMPATIBILITY_FAILURE = "A required compatibility field varies within a family"
  )
}

.stage4a_pooling_v2_hex <- function(x) {
  if (length(x) != 1L || is.na(x) || !nzchar(trimws(as.character(x)))) {
    stop("POOLING_V2_IDENTITY_MISSING: canonical identity fields must be scalar and nonblank",
         call. = FALSE)
  }
  raw <- charToRaw(enc2utf8(trimws(as.character(x))))
  paste(sprintf("%02x", as.integer(raw)), collapse = "")
}

stage4a_pooling_v2_serialize <- function(values, field_order) {
  if (is.null(names(values)) || !identical(names(values), field_order)) {
    stop("POOLING_V2_SERIALIZATION: fields must be named and in the frozen order",
         call. = FALSE)
  }
  encoded <- vapply(values, .stage4a_pooling_v2_hex, character(1L))
  bytes <- vapply(values, function(x) length(charToRaw(enc2utf8(trimws(as.character(x))))), integer(1L))
  paste(paste0(field_order, "=", bytes, ":", encoded), collapse = "|")
}

stage4a_pooling_v2_id <- function(prefix, values, field_order = names(values)) {
  canonical <- stage4a_pooling_v2_serialize(values, field_order)
  paste0(prefix, substr(digest::digest(canonical, algo = "sha256", serialize = FALSE), 1L, 24L))
}

.stage4a_pooling_v2_assign_ids <- function(x, prefix, fields) {
  keys <- unique(x[, fields, with = FALSE])
  matrix <- as.matrix(keys[, fields, with = FALSE])
  keys[, generated_id := vapply(seq_len(.N), function(i) {
    values <- as.list(matrix[i, ])
    names(values) <- fields
    stage4a_pooling_v2_id(prefix, values, fields)
  }, character(1L))]
  keys[x, on = fields, generated_id]
}

stage4a_pooling_v2_family_fields <- function() {
  c("canonical_model_id", "model_architecture", "component_estimand_id",
    "response_state", "unit_class", "effect_scale", "exposure_definition",
    "temporal_window", "spatial_buffer", "analysis_population",
    "adjustment_set", "component_role", "coefficient_meaning", "variance_meaning")
}

stage4a_pooling_v2_evidence_fields <- function() {
  c(stage4a_pooling_v2_family_fields(), "stable_unit_id", "region", "contrast")
}

stage4a_pooling_v2_read_effects <- function(effect_file, character_columns,
                                             numeric_columns, region_file,
                                             required_identity_columns = character_columns) {
  requested <- unique(c(character_columns, numeric_columns))
  if (!length(requested) || anyDuplicated(requested)) {
    stop("POOLING_V2_READER_CONTRACT: requested columns must be unique and nonempty",
         call. = FALSE)
  }
  # Read every selected field losslessly as character. Missing-value semantics
  # are applied below by declared column type, never globally by fread/read.csv.
  x <- data.table::fread(effect_file, select = requested, colClasses = "character",
                         na.strings = NULL, strip.white = FALSE)
  assert_columns(x, requested, "Stage 4A aggregate repair input")
  data.table::setcolorder(x, requested)
  for (field in character_columns) x[, (field) := trimws(enc2utf8(get(field)))]
  missing_identity <- vapply(required_identity_columns, function(field) {
    any(is.na(x[[field]]) | !nzchar(x[[field]]))
  }, logical(1L))
  if (any(missing_identity)) {
    stop("POOLING_V2_IDENTITY_MISSING: required character identity is truly missing: ",
         paste(names(missing_identity)[missing_identity], collapse = ", "), call. = FALSE)
  }
  regions <- data.table::fread(region_file, colClasses = "character", na.strings = NULL)
  assert_columns(regions, c("region", "analysis_population"), "Stage 4A region registry v2")
  registered <- trimws(regions$region)
  if (anyNA(registered) || any(!nzchar(registered)) || anyDuplicated(registered)) {
    stop("POOLING_V2_REGION_REGISTRY: region codes must be complete and unique", call. = FALSE)
  }
  if ("region" %in% character_columns && any(!x$region %in% registered)) {
    stop("POOLING_V2_UNREGISTERED_REGION: ",
         paste(sort(unique(x$region[!x$region %in% registered])), collapse = ", "),
         call. = FALSE)
  }
  numeric_pattern <- "^[+-]?(([0-9]+\\.?[0-9]*)|(\\.[0-9]+))([eE][+-]?[0-9]+)?$|^[+-]?Inf$|^NaN$"
  for (field in numeric_columns) {
    raw <- trimws(x[[field]])
    missing <- is.na(raw) | raw %in% c("", "NA")
    invalid <- !missing & !grepl(numeric_pattern, raw)
    if (any(invalid)) {
      stop("POOLING_V2_NUMERIC_PARSE: invalid token in ", field, ": ",
           paste(head(sort(unique(raw[invalid])), 5L), collapse = ", "), call. = FALSE)
    }
    value <- rep(NA_real_, length(raw))
    value[!missing] <- as.numeric(raw[!missing])
    x[, (field) := value]
  }
  x
}

.stage4a_pooling_v2_contract <- function(model_id, unit_class, outcome, contrast, region) {
  canonical_model_id <- if (model_id %in% c("M11", "M12")) {
    if (unit_class == "guild") "M01" else if (unit_class %in% c("species", "specificity_panel")) "M02" else NA_character_
  } else model_id
  if (is.na(canonical_model_id) || !canonical_model_id %in% c("M01", "M02", "M05", "M08", "M29")) {
    stop("POOLING_V2_IDENTITY_MISSING: unsupported model/unit identity", call. = FALSE)
  }
  response_state <- switch(outcome,
    detection = "detection",
    positive_count = "positive_numeric_count_given_detection",
    stop("POOLING_V2_IDENTITY_MISSING: unsupported response state", call. = FALSE)
  )
  effect_scale <- if (outcome == "detection") "log_odds" else "log_expected_positive_numeric_count"
  component_role <- if (outcome == "detection") "hurdle_detection_component" else "hurdle_positive_count_component"
  coefficient_meaning <- if (outcome == "detection") {
    "registered_exposure_coefficient_on_binomial_logit_scale"
  } else {
    "registered_exposure_coefficient_on_positive_lognormal_log_scale"
  }
  region_population <- stats::setNames(
    c("SoG_2005_primary", "WCVI_2015_candidate_primary",
      "CC_1988_hierarchical_descriptive", "NA_1988_hierarchical_descriptive"),
    c("SoG", "WCVI", "CC", "NA")
  )
  analysis_population <- unname(region_population[region])
  if (is.na(analysis_population)) {
    stop("POOLING_V2_IDENTITY_MISSING: unsupported registered region", call. = FALSE)
  }
  model_architecture <- switch(canonical_model_id,
    M01 = "registered_guild_hurdle_gamm",
    M02 = "registered_species_hurdle_gamm",
    M05 = "registered_event_time_distance_hurdle_gamm",
    M08 = "registered_near_reference_mass_balance_hurdle_gamm",
    M29 = "registered_same_location_nonspawn_control_gamm"
  )
  component_estimand_id <- switch(canonical_model_id,
    M01 = "E04",
    M02 = if (outcome == "detection") "E01" else "E02",
    M05 = "E06", M08 = "E07", M29 = "E13"
  )
  exposure_definition <- switch(canonical_model_id,
    M01 = "active_near_candidate_primary_5km",
    M02 = "active_near_candidate_primary_5km",
    M05 = "event_time_by_source_point_distance",
    M08 = "active_near_vs_contemporaneous_reference",
    M29 = "same_location_active_vs_registered_nonspawn_control"
  )
  temporal_window <- switch(canonical_model_id,
    M01 = "registered_active_spawn_window",
    M02 = "registered_active_spawn_window",
    M05 = if (grepl("^event_time_", contrast)) contrast else "all_registered_event_time_strata_adjusted",
    M08 = "registered_contemporaneous_reference_window",
    M29 = "registered_same_location_nonspawn_control_window"
  )
  spatial_buffer <- switch(canonical_model_id,
    M01 = "candidate_primary_5km",
    M02 = "candidate_primary_5km",
    M05 = if (grepl("^distance_", contrast)) contrast else "registered_source_point_distance_rings_adjusted",
    M08 = "candidate_primary_5km_near_and_registered_reference",
    M29 = "same_registered_location"
  )
  adjustment_set <- switch(canonical_model_id,
    M01 = "registered_stage4a_core_hurdle_adjustment_set",
    M02 = "registered_stage4a_core_hurdle_adjustment_set",
    M05 = "registered_stage4a_event_time_distance_adjustment_set",
    M08 = "registered_stage4a_mass_balance_adjustment_set",
    M29 = "registered_stage4a_same_location_control_adjustment_set"
  )
  if (canonical_model_id == "M29") component_role <- "specificity_control_component"
  data.table::data.table(
    canonical_model_id, model_architecture, component_estimand_id, response_state,
    unit_class, effect_scale, exposure_definition, temporal_window, spatial_buffer,
    analysis_population, adjustment_set, component_role, coefficient_meaning,
    variance_meaning = "registered_model_coefficient_sampling_variance"
  )
}

.stage4a_pooling_v2_unit_map <- function(x, species, guilds) {
  species_map <- unique(species[, .(unit_label = trimws(common_name), stable_unit_id = trimws(analysis_taxon_id))])
  guild_map <- unique(guilds[, .(unit_label = trimws(guild_id), stable_unit_id = trimws(guild_id))])
  if (anyDuplicated(species_map$unit_label) || anyDuplicated(guild_map$unit_label)) {
    stop("POOLING_V2_IDENTITY_MISSING: ambiguous stable unit mapping", call. = FALSE)
  }
  x[, stable_unit_id := NA_character_]
  x[unit_class %in% c("species", "specificity_panel"), stable_unit_id := species_map$stable_unit_id[
    match(unit_label, species_map$unit_label)]]
  x[unit_class == "guild", stable_unit_id := guild_map$stable_unit_id[match(unit_label, guild_map$unit_label)]]
  if (anyNA(x$stable_unit_id) || any(!nzchar(x$stable_unit_id))) {
    stop("POOLING_V2_IDENTITY_MISSING: missing or ambiguous registered stable unit identity", call. = FALSE)
  }
  x
}

.stage4a_pooling_v2_assert_collisions <- function(x, id_col, identity_cols) {
  audit <- unique(x[, c(id_col, identity_cols), with = FALSE])
  collisions <- audit[, .N, by = id_col][N > 1L]
  if (nrow(collisions)) stop("POOLING_V2_IDENTITY_COLLISION: hash collision detected", call. = FALSE)
  invisible(TRUE)
}

stage4a_pooling_v2_build_registries <- function(effect_file, species_file, guild_file,
                                                 region_file) {
  identity_columns <- c("model_id", "region", "unit_label", "unit_class", "outcome", "contrast")
  invalid_columns <- c("partial_pool_estimate", "partial_pool_standard_error")
  effects <- stage4a_pooling_v2_read_effects(
    effect_file, identity_columns, invalid_columns, region_file, identity_columns
  )
  affected <- effects[is.finite(partial_pool_estimate) | is.finite(partial_pool_standard_error),
                      ..identity_columns]
  if (nrow(affected) != 6562L) {
    stop("POOLING_V2_SCOPE: exact tracked scope must contain 6,562 finite released rows",
         call. = FALSE)
  }
  species <- data.table::fread(species_file, select = c("analysis_taxon_id", "common_name"))
  guilds <- data.table::fread(guild_file, select = c("guild_id"))
  affected <- .stage4a_pooling_v2_unit_map(affected, species, guilds)

  contract <- data.table::rbindlist(lapply(seq_len(nrow(affected)), function(i) {
    .stage4a_pooling_v2_contract(affected$model_id[i], affected$unit_class[i],
                                affected$outcome[i], affected$contrast[i], affected$region[i])
  }))
  candidate <- cbind(affected, contract)
  candidate[, legacy_undercount_scope := region != "NA"]
  if (candidate[legacy_undercount_scope == TRUE, .N] != 4890L) {
    stop("POOLING_V2_SCOPE: documented legacy undercount subset must contain 4,890 rows",
         call. = FALSE)
  }
  family_fields <- stage4a_pooling_v2_family_fields()
  evidence_fields <- stage4a_pooling_v2_evidence_fields()
  candidate[, pooling_family_id_v2 := .stage4a_pooling_v2_assign_ids(
    candidate, "pf2_", family_fields)]
  candidate[, component_evidence_id := .stage4a_pooling_v2_assign_ids(
    candidate, "ce2_", evidence_fields)]
  row_fields <- c("model_id", evidence_fields)
  candidate[, v1_effect_row_id := .stage4a_pooling_v2_assign_ids(
    candidate, "v1r_", row_fields)]
  v1_family_fields <- c("region", "outcome", "contrast")
  candidate[, v1_pooling_family_id := .stage4a_pooling_v2_assign_ids(
    candidate, "pf1_invalid_", v1_family_fields)]
  candidate[, disposition_reason_code := ifelse(
    model_id %in% c("M11", "M12"),
    "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
    "INCLUDED_PRIMARY_REPRESENTATION")]
  candidate[, included_in_future_estimator := !model_id %in% c("M11", "M12")]

  selected <- candidate[included_in_future_estimator == TRUE]
  if (anyDuplicated(selected[, .(pooling_family_id_v2, component_evidence_id)])) {
    stop("POOLING_V2_DUPLICATE_EVIDENCE: selected evidence is not unique within family", call. = FALSE)
  }
  .stage4a_pooling_v2_assert_collisions(candidate, "pooling_family_id_v2", family_fields)
  .stage4a_pooling_v2_assert_collisions(candidate, "component_evidence_id", evidence_fields)
  .stage4a_pooling_v2_assert_collisions(candidate, "v1_effect_row_id", row_fields)

  compatibility <- selected[, c(
    list(component_count = .N, pooling_axis_count = data.table::uniqueN(stable_unit_id)),
    lapply(.SD, data.table::uniqueN)),
    by = pooling_family_id_v2, .SDcols = family_fields]
  count_cols <- paste0(family_fields, "_unique_n")
  data.table::setnames(compatibility, family_fields, count_cols)
  compatibility[, compatibility_status := ifelse(
    rowSums(.SD != 1L) == 0L, "PASS", "FAMILY_COMPATIBILITY_FAILURE"),
    .SDcols = count_cols]
  compatibility[, estimability_status := ifelse(component_count >= 2L,
                                                  "ELIGIBLE_MINIMUM_COMPONENT_COUNT",
                                                  "NON_ESTIMABLE_SINGLETON")]
  if (any(compatibility$compatibility_status != "PASS")) {
    stop("POOLING_V2_FAMILY_COMPATIBILITY_FAILURE: incompatible family", call. = FALSE)
  }

  family_registry <- unique(selected[, c("pooling_family_id_v2", family_fields), with = FALSE])
  family_registry <- compatibility[, .(pooling_family_id_v2, component_count, pooling_axis_count,
                                        estimability_status)][family_registry, on = "pooling_family_id_v2"]
  family_registry[, `:=`(allowed_pooling_axis = "stable_unit_id",
                         estimator_contract_version = stage4a_pooling_v2_version())]
  data.table::setcolorder(family_registry, c("pooling_family_id_v2", family_fields,
                                             "allowed_pooling_axis", "component_count",
                                             "pooling_axis_count", "estimability_status",
                                             "estimator_contract_version"))

  evidence_registry <- selected[, c("pooling_family_id_v2", "component_evidence_id",
                                    "stable_unit_id", "region", "contrast",
                                    "canonical_model_id", "unit_class", "response_state",
                                    "component_estimand_id", "included_in_future_estimator",
                                    "disposition_reason_code"), with = FALSE]
  row_disposition <- candidate[, .(v1_effect_row_id, model_id, canonical_model_id,
    pooling_family_id_v2, component_evidence_id, included_in_future_estimator,
    disposition_reason_code, legacy_undercount_scope)]
  crosswalk <- candidate[, .(v1_effect_row_id, v1_pooling_family_id,
    pooling_family_id_v2, component_evidence_id, model_id, canonical_model_id,
    included_in_future_estimator, disposition_reason_code,
    legacy_undercount_scope)]

  selected_lookup <- selected[, .(pooling_family_id_v2, component_evidence_id,
                                  selected_model_id = model_id, selected_v1_effect_row_id = v1_effect_row_id)]
  excluded_lookup <- candidate[included_in_future_estimator == FALSE, .(
    pooling_family_id_v2, component_evidence_id,
    excluded_v1_effect_row_id = v1_effect_row_id,
    excluded_representation = model_id,
    unit_class, response_state
  )]
  duplicate_audit <- selected_lookup[excluded_lookup,
    on = c("pooling_family_id_v2", "component_evidence_id")]
  if (nrow(duplicate_audit) != nrow(excluded_lookup) ||
      anyNA(duplicate_audit$selected_model_id)) {
    stop("POOLING_V2_DUPLICATE_RESOLUTION: every M11/M12 row must resolve to one M01/M02 row",
         call. = FALSE)
  }
  duplicate_audit <- duplicate_audit[, .(
    duplicate_group_id = component_evidence_id,
    pooling_family_id_v2,
    selected_v1_effect_row_id,
    selected_representation = selected_model_id,
    excluded_v1_effect_row_id,
    excluded_representation,
    unit_class,
    response_state,
    reason_code = "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
    source_metadata = "R/stage4a_production.R;docs/14_STAGE4A_CORE_METHODS.md"
  )]

  v1_audit <- candidate[, .(
    affected_row_count = .N,
    model_id_count = data.table::uniqueN(model_id),
    unit_class_count = data.table::uniqueN(unit_class),
    duplicate_evidence_count = .N - data.table::uniqueN(component_evidence_id),
    invalidation_status = "INVALID_COMPUTED_PARTIAL_POOL_VALUES"
  ), by = .(v1_pooling_family_id, region, outcome, contrast)]
  if (nrow(v1_audit) != 112L) {
    stop("POOLING_V2_SCOPE: exact tracked scope must contain 112 affected v1 families",
         call. = FALSE)
  }
  legacy_audit <- candidate[legacy_undercount_scope == TRUE, .(
    affected_row_count = .N,
    model_id_count = data.table::uniqueN(model_id),
    unit_class_count = data.table::uniqueN(unit_class),
    duplicate_evidence_count = .N - data.table::uniqueN(component_evidence_id),
    invalidation_status = "SUPERSEDED_UNDERCOUNT_SUBSET_ALL_VALUES_REMAIN_INVALID",
    scope_note = "Legacy 4,890/84 undercount; literal NA region was omitted by parsing"
  ), by = .(v1_pooling_family_id, region, outcome, contrast)]
  if (nrow(legacy_audit) != 84L || sum(legacy_audit$affected_row_count) != 4890L) {
    stop("POOLING_V2_SCOPE: legacy authorized 4,890-row/84-family accounting failed",
         call. = FALSE)
  }

  for (tab in list(family_registry, evidence_registry, row_disposition, crosswalk,
                   duplicate_audit, compatibility, v1_audit, legacy_audit)) {
    data.table::setorderv(tab, names(tab))
  }
  list(
    family_registry = family_registry,
    evidence_registry = evidence_registry,
    row_disposition = row_disposition,
    crosswalk = crosswalk,
    duplicate_audit = duplicate_audit,
    compatibility_audit = compatibility,
    v1_family_invalidation_audit = v1_audit,
    legacy_authorized_scope_audit = legacy_audit
  )
}

stage4a_pooling_v2_write_registries <- function(registries, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  files <- c(
    family_registry = "stage4a_pooling_family_registry_v2.csv",
    evidence_registry = "stage4a_component_evidence_registry_v2.csv",
    row_disposition = "stage4a_pooling_row_disposition_v2.csv",
    crosswalk = "stage4a_pooling_v1_to_v2_crosswalk.csv",
    duplicate_audit = "stage4a_m11_m12_duplicate_resolution_v2.csv",
    compatibility_audit = "stage4a_pooling_family_compatibility_audit_v2.csv",
    v1_family_invalidation_audit = "stage4a_pooling_v1_family_invalidation_audit.csv",
    legacy_authorized_scope_audit = "stage4a_pooling_legacy_4890_row_84_family_audit.csv"
  )
  for (name in names(files)) {
    data.table::fwrite(registries[[name]], file.path(output_dir, files[[name]]),
                       quote = TRUE, na = "", eol = "\n", bom = FALSE)
  }
  invisible(file.path(output_dir, files))
}
