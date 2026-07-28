post_stage4a_descriptive_version_v1 <- function() {
  "post_stage4a_descriptive_summaries_v1"
}

post_stage4a_descriptive_gate_v1 <- function(
    path = "metadata/post_stage4a_descriptive_summaries_spec_v1.yml") {
  if (!file.exists(path)) {
    stop("DESCRIPTIVE_SPEC_GATE: specification unavailable", call. = FALSE)
  }
  spec <- yaml::read_yaml(path)
  if (
    !identical(spec$spec_version, post_stage4a_descriptive_version_v1()) ||
      !identical(spec$scope$models_fitted, FALSE) ||
      !identical(spec$scope$statistical_tests_run, FALSE) ||
      !identical(spec$scope$p_values_produced, FALSE) ||
      !identical(spec$release_control$suppression_threshold, 20L)
  ) {
    stop("DESCRIPTIVE_SPEC_GATE: specification changed", call. = FALSE)
  }
  spec
}

post_stage4a_descriptive_require_v1 <- function(x, fields, label) {
  missing <- setdiff(fields, names(x))
  if (length(missing)) {
    stop(label, " missing fields: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}

post_stage4a_descriptive_num_v1 <- function(x) {
  clean <- staged_refit_clean_v1(x)
  clean[staged_refit_missing_text_v1(clean)] <- NA_character_
  suppressWarnings(as.numeric(clean))
}

post_stage4a_descriptive_date_v1 <- function(x) {
  clean <- staged_refit_clean_v1(x)
  clean[staged_refit_missing_text_v1(clean)] <- NA_character_
  data.table::as.IDate(clean, format = "%Y-%m-%d")
}

post_stage4a_descriptive_method_v1 <- function(x) {
  clean <- tolower(staged_refit_clean_v1(x))
  missing <- staged_refit_missing_text_v1(clean)
  out <- rep("missing", length(clean))
  out[grepl("surface", clean, fixed = TRUE)] <- "Surface"
  out[grepl("dive", clean, fixed = TRUE)] <- "Dive"
  out[grepl("incomplete", clean, fixed = TRUE)] <- "Incomplete"
  out[missing] <- "missing"
  unresolved <- !missing & out == "missing"
  if (any(unresolved)) {
    stop(
      "DESCRIPTIVE_METHOD_GATE: unresolved survey-method category",
      call. = FALSE
    )
  }
  out
}

post_stage4a_descriptive_herring_v1 <- function(path) {
  expected_hash <-
    "6d3b2c08e3586bde52f5fe2af602c63014468b54e49dc906bd1f8dfe6706e8ac"
  if (!file.exists(path) ||
      !identical(.post_stage4a_sha256_v1(path), expected_hash)) {
    stop("DESCRIPTIVE_HERRING_SOURCE_GATE: frozen source mismatch",
         call. = FALSE)
  }
  required <- c(
    "Region", "Year", "StatisticalArea", "Section", "LocationCode",
    "LocationName", "SpawnNumber", "StartDate", "EndDate", "Longitude",
    "Latitude", "Length", "Width", "Method", "Surface", "Macrocystis",
    "Understory"
  )
  source <- data.table::fread(
    path,
    select = required,
    colClasses = "character",
    na.strings = NULL,
    showProgress = FALSE
  )
  post_stage4a_descriptive_require_v1(source, required, "DFO source")
  source[, source_row__ := .I]
  for (field in required) {
    data.table::set(
      source, j = field, value = staged_refit_clean_v1(source[[field]])
    )
  }
  source[, event_year__ := suppressWarnings(as.integer(Year))]
  source[, start_date__ := post_stage4a_descriptive_date_v1(StartDate)]
  source[, end_date__ := post_stage4a_descriptive_date_v1(EndDate)]
  source[, anchor_date__ := start_date__]
  source[is.na(anchor_date__), anchor_date__ := end_date__]
  source[, longitude__ := post_stage4a_descriptive_num_v1(Longitude)]
  source[, latitude__ := post_stage4a_descriptive_num_v1(Latitude)]
  source[, length_m__ := post_stage4a_descriptive_num_v1(Length)]
  source[, width_m__ := post_stage4a_descriptive_num_v1(Width)]
  source[, surface__ := post_stage4a_descriptive_num_v1(Surface)]
  source[, macrocystis__ := post_stage4a_descriptive_num_v1(Macrocystis)]
  source[, understory__ := post_stage4a_descriptive_num_v1(Understory)]
  source[, method__ := post_stage4a_descriptive_method_v1(Method)]
  source[, span_days__ := as.integer(end_date__ - start_date__)]
  source[, span_invalid_negative__ :=
    !is.na(span_days__) & span_days__ < 0L]
  source[span_invalid_negative__ == TRUE, span_days__ := NA_integer_]
  in_year <- !is.na(source$event_year__) &
    source$event_year__ >= 1988L & source$event_year__ <= 2025L
  has_date <- !is.na(source$anchor_date__)
  valid_coordinate <- is.finite(source$longitude__) &
    is.finite(source$latitude__) &
    source$longitude__ >= -180 & source$longitude__ <= 180 &
    source$latitude__ >= -90 & source$latitude__ <= 90
  valid <- source[in_year & has_date & valid_coordinate]
  valid[, source_identity__ := paste(
    source_row__, event_year__, StatisticalArea, Section,
    LocationCode, SpawnNumber, sep = "|"
  )]
  valid[, herring_source_token := staged_refit_hash_token_v1(
    "herring_source", source_identity__
  )]
  if (anyNA(valid$herring_source_token) ||
      anyDuplicated(valid$herring_source_token)) {
    stop("DESCRIPTIVE_EVENT_KEY_GATE: source token is not unique",
         call. = FALSE)
  }
  components <- cbind(
    valid$surface__, valid$macrocystis__, valid$understory__
  )
  valid[, component_missing_n__ := rowSums(is.na(components))]
  valid[, any_component_missing__ := component_missing_n__ > 0L]
  valid[, no_component_recorded__ := component_missing_n__ == 3L]
  valid[, relative_spawn_index__ := rowSums(components, na.rm = TRUE)]
  valid[, anchor_day_of_year__ := as.integer(format(
    as.Date(anchor_date__), "%j"
  ))]
  valid[, location_key__ := paste(
    StatisticalArea, Section, LocationCode, sep = "\r"
  )]
  valid[, section_key__ := paste(
    StatisticalArea, Section, sep = "\r"
  )]
  attr(valid, "raw_rows") <- nrow(source)
  attr(valid, "valid_rows") <- nrow(valid)
  attr(valid, "source_hash") <- expected_hash
  valid
}

post_stage4a_descriptive_quantiles_v1 <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(c(q25 = NA_real_, median = NA_real_, q75 = NA_real_))
  }
  stats::quantile(
    x, probs = c(0.25, 0.5, 0.75), names = FALSE,
    type = 7, na.rm = TRUE
  ) |>
    stats::setNames(c("q25", "median", "q75"))
}

post_stage4a_descriptive_display_v1 <- function(
    value, digits = 1L, integer = FALSE) {
  if (!is.finite(value)) return("not available")
  if (integer) return(format(round(value), big.mark = ",", scientific = FALSE))
  formatC(value, format = "f", digits = digits, big.mark = ",")
}

post_stage4a_descriptive_release_count_v1 <- function(value) {
  if (is.finite(value) && value > 0 && value < 20) return("<20")
  as.integer(value)
}

post_stage4a_descriptive_percentage_text_v1 <- function(value) {
  if (identical(value, "suppressed")) return("suppressed")
  paste0(value, "%")
}

post_stage4a_descriptive_summary_builder_v1 <- function() {
  rows <- list()
  add <- function(
      item_order, metric_id, subgroup, statistic, value,
      unit, release_type = "continuous", denominator = NA_real_,
      digits = 1L, note = "") {
    suppressed <- FALSE
    released <- value
    display <- post_stage4a_descriptive_display_v1(
      value, digits = digits, integer = release_type == "count"
    )
    if (
      release_type == "count" && is.finite(value) &&
        value > 0 && value < 20
    ) {
      suppressed <- TRUE
      released <- NA_real_
      display <- "<20"
    }
    rows[[length(rows) + 1L]] <<- data.frame(
      item_order = as.integer(item_order),
      metric_id = as.character(metric_id),
      subgroup = as.character(subgroup),
      statistic = as.character(statistic),
      value_numeric = as.numeric(released),
      display_value = display,
      unit = as.character(unit),
      release_type = as.character(release_type),
      denominator = as.numeric(denominator),
      suppressed_below_20 = suppressed,
      note = as.character(note),
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
  add_percentage <- function(
      item_order, metric_id, subgroup, numerator, denominator,
      digits = 1L, note = "") {
    if (
      is.finite(numerator) && numerator > 0 && numerator < 20
    ) {
      rows[[length(rows) + 1L]] <<- data.frame(
        item_order = as.integer(item_order),
        metric_id = as.character(metric_id),
        subgroup = as.character(subgroup),
        statistic = "percentage",
        value_numeric = NA_real_,
        display_value = "suppressed",
        unit = "percent",
        release_type = "percentage",
        denominator = as.numeric(denominator),
        suppressed_below_20 = TRUE,
        note = as.character(note),
        stringsAsFactors = FALSE
      )
    } else {
      value <- if (denominator > 0) 100 * numerator / denominator else NA_real_
      add(
        item_order, metric_id, subgroup, "percentage", value,
        "percent", "percentage", denominator, digits, note
      )
    }
    invisible(NULL)
  }
  result <- function() do.call(rbind, rows)
  list(add = add, add_percentage = add_percentage, result = result)
}

post_stage4a_descriptive_spawn_summaries_v1 <- function(
    analysis_events, all_strait_events) {
  b <- post_stage4a_descriptive_summary_builder_v1()
  n_events <- nrow(analysis_events)
  n_all <- nrow(all_strait_events)
  b$add(
    1L, "analysis_events", "analysis-linked", "count",
    n_events, "events", "count"
  )
  b$add(
    1L, "all_strait_events", "all valid Strait records", "count",
    n_all, "events", "count"
  )
  event_year_counts <- table(analysis_events$event_year__)
  b$add(
    1L, "events_per_year", "analysis-linked", "median",
    stats::median(as.numeric(event_year_counts)), "events", "count"
  )
  b$add(
    1L, "events_per_year", "analysis-linked", "minimum",
    min(as.numeric(event_year_counts)), "events", "count"
  )
  b$add(
    1L, "events_per_year", "analysis-linked", "maximum",
    max(as.numeric(event_year_counts)), "events", "count"
  )
  b$add(
    1L, "represented_years", "analysis-linked", "count",
    length(event_year_counts), "years", "count"
  )

  spans <- analysis_events$span_days__
  span_q <- post_stage4a_descriptive_quantiles_v1(spans)
  for (name in names(span_q)) {
    b$add(2L, "recorded_span_days", "analysis-linked", name,
          span_q[[name]], "days", digits = 1L)
  }
  b$add(
    2L, "recorded_span_days", "analysis-linked", "maximum",
    max(spans, na.rm = TRUE), "days", digits = 0L
  )
  b$add(
    2L, "recorded_span_missing", "analysis-linked", "count",
    sum(is.na(spans)), "events", "count"
  )
  b$add(
    2L, "recorded_span_negative_interval", "analysis-linked", "count",
    sum(analysis_events$span_invalid_negative__), "events", "count",
    note = paste(
      "End date preceded start date; the event was retained but its",
      "recorded span was excluded."
    )
  )
  span_bin <- cut(
    spans,
    breaks = c(-Inf, 1, 3, 5, 7, Inf),
    labels = c("0-1", "2-3", "4-5", "6-7", "8+"),
    right = TRUE
  )
  for (category in levels(span_bin)) {
    count <- sum(span_bin == category, na.rm = TRUE)
    b$add(
      2L, "recorded_span_distribution", category, "count",
      count, "events", "count", denominator = sum(!is.na(span_bin))
    )
    b$add_percentage(
      2L, "recorded_span_distribution", category,
      count, sum(!is.na(span_bin))
    )
  }

  doy_q <- post_stage4a_descriptive_quantiles_v1(
    analysis_events$anchor_day_of_year__
  )
  for (name in names(doy_q)) {
    b$add(
      3L, "first_spawn_day_of_year", "analysis-linked", name,
      doy_q[[name]], "day_of_year", digits = 0L
    )
  }

  season <- data.table::as.data.table(analysis_events)[
    ,
    .(
      first_anchor_date = min(anchor_date__),
      last_anchor_date = max(anchor_date__),
      first_day_of_year = min(anchor_day_of_year__),
      last_day_of_year = max(anchor_day_of_year__)
    ),
    by = .(year = event_year__)
  ]
  season[, season_span_days := as.integer(
    as.Date(last_anchor_date) - as.Date(first_anchor_date)
  )]
  data.table::setorder(season, year)
  season_q <- post_stage4a_descriptive_quantiles_v1(
    season$season_span_days
  )
  for (name in names(season_q)) {
    b$add(
      4L, "within_year_season_span", "analysis-linked years", name,
      season_q[[name]], "days", digits = 1L
    )
  }

  index <- analysis_events$relative_spawn_index__
  index_q <- post_stage4a_descriptive_quantiles_v1(index)
  for (name in names(index_q)) {
    b$add(
      5L, "relative_spawn_index", "analysis-linked", name,
      index_q[[name]], "relative_index", digits = 2L
    )
  }
  b$add(
    5L, "relative_spawn_index", "analysis-linked", "minimum",
    min(index), "relative_index", digits = 2L
  )
  b$add(
    5L, "relative_spawn_index", "analysis-linked", "maximum",
    max(index), "relative_index", digits = 2L
  )
  b$add(
    5L, "no_spawn_component_recorded", "analysis-linked", "count",
    sum(analysis_events$no_component_recorded__), "events", "count"
  )
  b$add(
    5L, "component_zero_fill_affected", "analysis-linked", "count",
    sum(analysis_events$any_component_missing__), "events", "count",
    note = paste(
      "At least one component was unrecorded; missingness was retained",
      "and the unrecorded component contributed zero only to the derived total."
    )
  )
  b$add(
    5L, "component_zero_fill_affected", "all valid Strait records", "count",
    sum(all_strait_events$any_component_missing__), "events", "count"
  )

  for (field in c("length_m__", "width_m__")) {
    metric <- sub("__$", "", field)
    values <- analysis_events[[field]]
    q <- post_stage4a_descriptive_quantiles_v1(values)
    for (name in names(q)) {
      b$add(
        6L, metric, "analysis-linked", name, q[[name]],
        "metres", digits = 1L
      )
    }
    b$add(
      6L, paste0(metric, "_missing"), "analysis-linked", "count",
      sum(!is.finite(values)), "events", "count"
    )
  }

  method_levels <- c("Surface", "Dive", "Incomplete", "missing")
  for (method in method_levels) {
    count <- sum(analysis_events$method__ == method)
    b$add(
      7L, "survey_method", method, "count", count,
      "events", "count", denominator = n_events
    )
    b$add_percentage(
      7L, "survey_method", method, count, n_events
    )
  }

  locations <- unique(analysis_events[, c(
    "location_key__", "event_year__"
  ), with = FALSE])
  location_years <- locations[, .(
    years_recorded = data.table::uniqueN(event_year__)
  ), by = location_key__]
  b$add(
    8L, "distinct_locations", "analysis-linked", "count",
    data.table::uniqueN(analysis_events$location_key__),
    "locations", "count"
  )
  b$add(
    8L, "distinct_sections", "analysis-linked", "count",
    data.table::uniqueN(analysis_events$section_key__),
    "sections", "count"
  )
  b$add(
    8L, "locations_multiple_years", "analysis-linked", "count",
    sum(location_years$years_recorded > 1L),
    "locations", "count"
  )
  year_categories <- ifelse(
    location_years$years_recorded >= 5L, "5+",
    as.character(location_years$years_recorded)
  )
  for (category in c("1", "2", "3", "4", "5+")) {
    count <- sum(year_categories == category)
    b$add(
      8L, "years_per_location", category, "count", count,
      "locations", "count", denominator = nrow(location_years)
    )
    b$add_percentage(
      8L, "years_per_location", category, count, nrow(location_years)
    )
  }
  season_out <- as.data.frame(season)
  season_out$first_anchor_date <- as.character(
    season_out$first_anchor_date
  )
  season_out$last_anchor_date <- as.character(
    season_out$last_anchor_date
  )
  list(summary = b$result(), season = season_out)
}

post_stage4a_descriptive_cell_membership_v1 <- function(links) {
  classified <- post_stage4a_classify_links_v1(links)
  period_group <- ifelse(
    classified$period %in% c("early_pre", "immediate_pre"), "pre",
    ifelse(
      classified$period %in% c("spawn_start", "early_egg"),
      "active", NA_character_
    )
  )
  keep <- !is.na(period_group)
  membership <- data.frame(
    analysis_event_token = classified$analysis_event_token[keep],
    zone = classified$zone[keep],
    period = period_group[keep],
    stringsAsFactors = FALSE
  )
  membership$cell <- paste(membership$zone, membership$period, sep = "_")
  membership <- unique(membership)
  if (anyDuplicated(paste(
      membership$analysis_event_token, membership$cell, sep = "\r"
  ))) {
    stop("DESCRIPTIVE_CELL_GATE: duplicate checklist-cell membership",
         call. = FALSE)
  }
  membership
}

post_stage4a_descriptive_checklist_metrics_v1 <- function(
    events, states, core_taxa) {
  state <- states[
    states$analysis_taxon_id %in% core_taxa &
      suppressWarnings(as.integer(states$detection)) == 1L,
    ,
    drop = FALSE
  ]
  if (anyDuplicated(paste(
      state$analysis_event_token, state$analysis_taxon_id, sep = "\r"
  ))) {
    stop("DESCRIPTIVE_STATE_GATE: duplicate checklist-species state",
         call. = FALSE)
  }
  state$numeric_count__ <- suppressWarnings(
    as.numeric(state$numeric_count)
  )
  state$x_record__ <- tolower(as.character(state$count_type)) ==
    "unquantified_x"
  state_dt <- data.table::as.data.table(state)
  metric <- state_dt[
    ,
    .(
      registered_richness = .N,
      lower_bound_individuals = sum(numeric_count__, na.rm = TRUE),
      positive_records = .N,
      x_records = sum(x_record__)
    ),
    by = analysis_event_token
  ]
  index <- match(events$analysis_event_token, metric$analysis_event_token)
  out <- data.frame(
    analysis_event_token = events$analysis_event_token,
    registered_richness = ifelse(
      is.na(index), 0L, metric$registered_richness[index]
    ),
    lower_bound_individuals = ifelse(
      is.na(index), 0, metric$lower_bound_individuals[index]
    ),
    positive_records = ifelse(
      is.na(index), 0L, metric$positive_records[index]
    ),
    x_records = ifelse(
      is.na(index), 0L, metric$x_records[index]
    ),
    stringsAsFactors = FALSE
  )
  if (nrow(out) != nrow(events) ||
      anyDuplicated(out$analysis_event_token)) {
    stop("DESCRIPTIVE_CHECKLIST_METRIC_GATE: one-to-one join failed",
         call. = FALSE)
  }
  list(metrics = out, positive_states = as.data.frame(state))
}

post_stage4a_descriptive_assemblage_v1 <- function(
    events, states, membership, core_taxa, species_registry, guild_map) {
  metrics <- post_stage4a_descriptive_checklist_metrics_v1(
    events, states, core_taxa
  )
  event_fields <- events[, c(
    "analysis_event_token", "protocol", "duration_minutes",
    "effort_distance_km", "observer_count"
  )]
  enriched <- merge(
    membership, event_fields,
    by = "analysis_event_token", all.x = TRUE, sort = FALSE
  )
  if (nrow(enriched) != nrow(membership) ||
      anyNA(enriched$duration_minutes)) {
    stop("DESCRIPTIVE_CELL_EVENT_JOIN_GATE: checklist join failed",
         call. = FALSE)
  }
  enriched <- merge(
    enriched, metrics$metrics,
    by = "analysis_event_token", all.x = TRUE, sort = FALSE
  )
  if (nrow(enriched) != nrow(membership) ||
      anyNA(enriched$registered_richness)) {
    stop("DESCRIPTIVE_CELL_METRIC_JOIN_GATE: metric join failed",
         call. = FALSE)
  }
  cell_order <- c(
    "near_pre", "near_active", "reference_pre", "reference_active"
  )
  enriched$cell <- factor(enriched$cell, levels = cell_order)
  if (anyNA(enriched$cell)) {
    stop("DESCRIPTIVE_CELL_GATE: unexpected cell", call. = FALSE)
  }
  cell <- data.table::as.data.table(enriched)[
    ,
    {
      richness_q <- post_stage4a_descriptive_quantiles_v1(
        registered_richness
      )
      individual_q <- post_stage4a_descriptive_quantiles_v1(
        lower_bound_individuals
      )
      list(
        checklists = .N,
        richness_median = richness_q[["median"]],
        richness_q25 = richness_q[["q25"]],
        richness_q75 = richness_q[["q75"]],
        richness_mean = mean(registered_richness),
        lower_bound_individuals_median =
          individual_q[["median"]],
        lower_bound_individuals_q25 = individual_q[["q25"]],
        lower_bound_individuals_q75 = individual_q[["q75"]],
        percent_with_registered_species =
          100 * mean(registered_richness > 0),
        duration_minutes_median = as.numeric(
          stats::median(duration_minutes)
        ),
        effort_distance_km_median =
          as.numeric(stats::median(effort_distance_km)),
        observers_median = as.numeric(stats::median(observer_count)),
        positive_records = sum(positive_records),
        x_records = sum(x_records),
        percent_positive_records_unquantified_x =
          100 * sum(x_records) / sum(positive_records)
      )
    },
    by = .(cell, zone, period)
  ]
  data.table::setorder(cell, cell)
  if (nrow(cell) != 4L || any(cell$checklists < 20L)) {
    stop("DESCRIPTIVE_CELL_GATE: expected four releasable cells",
         call. = FALSE)
  }
  cell[, c("positive_records", "x_records") := NULL]

  near_active_tokens <- membership$analysis_event_token[
    membership$cell == "near_active"
  ]
  near_active_n <- length(unique(near_active_tokens))
  active_states <- metrics$positive_states[
    metrics$positive_states$analysis_event_token %in% near_active_tokens,
    ,
    drop = FALSE
  ]
  species_lookup <- species_registry[, c(
    "analysis_taxon_id", "common_name"
  )]
  index <- match(
    active_states$analysis_taxon_id, species_lookup$analysis_taxon_id
  )
  if (anyNA(index)) {
    stop("DESCRIPTIVE_SPECIES_JOIN_GATE: species label missing",
         call. = FALSE)
  }
  active_states$species <- species_lookup$common_name[index]
  species <- data.table::as.data.table(active_states)[
    ,
    .(
      detected_checklists = data.table::uniqueN(analysis_event_token),
      summed_numeric_individuals = sum(numeric_count__, na.rm = TRUE),
      x_records = sum(x_record__)
    ),
    by = .(analysis_taxon_id, species)
  ]
  species[, percent_checklists := 100 * detected_checklists / near_active_n]
  prevalence <- species[order(-percent_checklists, species)][1:10]
  prevalence[, `:=`(
    ranking_metric = "percentage_of_checklists",
    rank = seq_len(.N),
    value = percent_checklists,
    display_value = sprintf("%.1f%%", percent_checklists),
    unit = "percent",
    denominator = near_active_n
  )]
  individuals <- species[
    order(-summed_numeric_individuals, species)
  ][1:10]
  individuals[, `:=`(
    ranking_metric = "summed_numeric_individuals_lower_bound",
    rank = seq_len(.N),
    value = summed_numeric_individuals,
    display_value = format(
      summed_numeric_individuals, big.mark = ",", scientific = FALSE
    ),
    unit = "individuals_lower_bound",
    denominator = near_active_n
  )]
  top <- rbind(
    prevalence[, .(
      ranking_metric, rank, species, value,
      display_value, unit, denominator
    )],
    individuals[, .(
      ranking_metric, rank, species, value,
      display_value, unit, denominator
    )]
  )
  if (any(
      prevalence$detected_checklists > 0 &
        prevalence$detected_checklists < 20
  ) || any(
      individuals$summed_numeric_individuals > 0 &
        individuals$summed_numeric_individuals < 20
  )) {
    stop("DESCRIPTIVE_TOP_SPECIES_SUPPRESSION_GATE: small count",
         call. = FALSE)
  }

  core_guild <- guild_map[
    guild_map$analysis_taxon_id %in% core_taxa &
      !as.logical(guild_map$duplicate_in_primary_totals),
    ,
    drop = FALSE
  ]
  if (
    nrow(core_guild) != length(core_taxa) ||
      anyDuplicated(core_guild$analysis_taxon_id) ||
      !setequal(core_guild$analysis_taxon_id, core_taxa)
  ) {
    stop("DESCRIPTIVE_GUILD_GATE: one primary guild per species required",
         call. = FALSE)
  }
  guild_index <- match(
    active_states$analysis_taxon_id, core_guild$analysis_taxon_id
  )
  if (anyNA(guild_index)) {
    stop("DESCRIPTIVE_GUILD_JOIN_GATE: active state missing guild",
         call. = FALSE)
  }
  active_states$primary_guild_id <-
    core_guild$primary_guild_id[guild_index]
  guild_labels <- utils::read.csv(
    "metadata/canonical_guild_registry.csv",
    stringsAsFactors = FALSE
  )
  guild <- data.table::as.data.table(active_states)[
    ,
    .(
      richness_contributions = .N,
      registered_species_detected =
        data.table::uniqueN(analysis_taxon_id)
    ),
    by = primary_guild_id
  ]
  guild[, share_of_registered_richness_percent :=
    100 * richness_contributions / sum(richness_contributions)]
  label_index <- match(
    guild$primary_guild_id, guild_labels$guild_id
  )
  if (anyNA(label_index)) {
    stop("DESCRIPTIVE_GUILD_LABEL_GATE: guild label missing",
         call. = FALSE)
  }
  guild$guild_label <- guild_labels$guild_label[label_index]
  data.table::setorder(guild, -share_of_registered_richness_percent)
  guild[, rank := seq_len(.N)]
  if (any(
      guild$richness_contributions > 0 &
        guild$richness_contributions < 20
  )) {
    stop("DESCRIPTIVE_GUILD_SUPPRESSION_GATE: small guild count",
         call. = FALSE)
  }
  guild <- guild[, .(
    rank, guild_label, share_of_registered_richness_percent
  )]

  active_rows <- enriched[enriched$cell == "near_active", , drop = FALSE]
  protocol_counts <- sort(table(active_rows$protocol), decreasing = TRUE)
  typical <- list(
    protocol = names(protocol_counts)[[1L]],
    duration_minutes = stats::median(active_rows$duration_minutes),
    effort_distance_km = stats::median(active_rows$effort_distance_km),
    observers = stats::median(active_rows$observer_count),
    richness = stats::median(active_rows$registered_richness),
    lower_bound_individuals =
      stats::median(active_rows$lower_bound_individuals)
  )
  membership_per_checklist <- table(membership$analysis_event_token)
  list(
    cell = as.data.frame(cell),
    top = as.data.frame(top),
    guild = as.data.frame(guild),
    typical = typical,
    membership_overlap = sum(membership_per_checklist > 1L),
    membership_checklists = length(membership_per_checklist),
    metrics = metrics
  )
}

post_stage4a_descriptive_lookup_v1 <- function(
    summary, metric, statistic, subgroup = NULL) {
  use <- summary$metric_id == metric &
    summary$statistic == statistic
  if (!is.null(subgroup)) use <- use & summary$subgroup == subgroup
  value <- summary$display_value[use]
  if (length(value) != 1L) {
    stop("DESCRIPTIVE_REPORT_LOOKUP_GATE: unresolved summary value",
         call. = FALSE)
  }
  value
}

post_stage4a_descriptive_report_v1 <- function(
    spawn, season, assemblage, linked_n, unlinked_n,
    linked_outside_cells_n, output_path) {
  lookup <- function(metric, statistic, subgroup = NULL) {
    post_stage4a_descriptive_lookup_v1(
      spawn, metric, statistic, subgroup
    )
  }
  cell <- assemblage$cell
  cell$richness <- sprintf(
    "%.1f [%.1f-%.1f]; mean %.2f",
    cell$richness_median, cell$richness_q25,
    cell$richness_q75, cell$richness_mean
  )
  cell$individuals <- sprintf(
    "%.1f [%.1f-%.1f]",
    cell$lower_bound_individuals_median,
    cell$lower_bound_individuals_q25,
    cell$lower_bound_individuals_q75
  )
  table_lines <- c(
    "| Zone | Window | Checklists | Registered-species richness, median [IQR]; mean | Numeric individuals, median [IQR], lower bound | Checklists with >=1 registered species | Duration, min | Distance, km | Observers | Positive records reported as X |",
    "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"
  )
  for (i in seq_len(nrow(cell))) {
    table_lines <- c(table_lines, sprintf(
      "| %s | %s | %s | %s | %s | %.1f%% | %.1f | %.2f | %.1f | %.1f%% |",
      ifelse(cell$zone[[i]] == "near", "Near (<5 km)",
             "Reference (5-20 km)"),
      ifelse(cell$period[[i]] == "pre", "Pre-spawn (-14 to -1)",
             "Active (0 to 14)"),
      format(cell$checklists[[i]], big.mark = ","),
      cell$richness[[i]], cell$individuals[[i]],
      cell$percent_with_registered_species[[i]],
      cell$duration_minutes_median[[i]],
      cell$effort_distance_km_median[[i]],
      cell$observers_median[[i]],
      cell$percent_positive_records_unquantified_x[[i]]
    ))
  }
  season_rows <- vapply(seq_len(nrow(season)), function(i) {
    sprintf(
      "| %d | %s | %s | %d | %d | %d |",
      season$year[[i]], season$first_anchor_date[[i]],
      season$last_anchor_date[[i]], season$first_day_of_year[[i]],
      season$last_day_of_year[[i]], season$season_span_days[[i]]
    )
  }, character(1L))
  top_prev <- assemblage$top[
    assemblage$top$ranking_metric == "percentage_of_checklists", ]
  top_ind <- assemblage$top[
    assemblage$top$ranking_metric ==
      "summed_numeric_individuals_lower_bound", ]
  guild <- assemblage$guild
  top_prev_text <- paste(sprintf(
    "%d. %s (%s)", top_prev$rank, top_prev$species,
    top_prev$display_value
  ), collapse = "; ")
  top_ind_text <- paste(sprintf(
    "%d. %s (%s)", top_ind$rank, top_ind$species,
    top_ind$display_value
  ), collapse = "; ")
  guild_text <- paste(sprintf(
    "%s (%.1f%%)", guild$guild_label,
    guild$share_of_registered_richness_percent
  ), collapse = "; ")
  span_bins <- paste(vapply(
    c("0-1", "2-3", "4-5", "6-7", "8+"),
    function(bin) sprintf(
      "%s days: %s (%s)",
      bin,
      lookup("recorded_span_distribution", "count", bin),
      post_stage4a_descriptive_percentage_text_v1(
        lookup("recorded_span_distribution", "percentage", bin)
      )
    ),
    character(1L)
  ), collapse = "; ")
  method_text <- paste(vapply(
    c("Surface", "Dive", "Incomplete", "missing"),
    function(method) sprintf(
      "%s: %s (%s)", method,
      lookup("survey_method", "count", method),
      post_stage4a_descriptive_percentage_text_v1(
        lookup("survey_method", "percentage", method)
      )
    ),
    character(1L)
  ), collapse = "; ")
  location_year_text <- paste(vapply(
    c("1", "2", "3", "4", "5+"),
    function(category) sprintf(
      "%s year%s: %s (%s)",
      category, ifelse(category == "1", "", "s"),
      lookup("years_per_location", "count", category),
      post_stage4a_descriptive_percentage_text_v1(
        lookup("years_per_location", "percentage", category)
      )
    ),
    character(1L)
  ), collapse = "; ")
  typical <- assemblage$typical
  lines <- c(
    "# Descriptive summaries for the opening of the Results",
    "",
    "All values below are descriptive summaries using the adopted start-date anchor. No model estimates or inferential comparisons are included.",
    "",
    "## 1. Table 2 — Checklist effort and registered bird assemblage by zone and period",
    "",
    table_lines,
    "",
    sprintf(
      "Eligible-frame coverage: %s checklists were linked to at least one event and %s were unlinked. Of the linked set, %s did not enter the four pre-spawn/active cells.",
      format(linked_n, big.mark = ","),
      format(unlinked_n, big.mark = ","),
      format(linked_outside_cells_n, big.mark = ",")
    ),
    "",
    sprintf(
      "Concurrent events placed %s checklists in more than one cell. Each checklist is counted once within a cell; cell counts must not be summed or interpreted as independent samples.",
      format(assemblage$membership_overlap, big.mark = ",")
    ),
    "",
    sprintf(
      "**Typical near-zone active checklist.** %s protocol; %.1f minutes; %.2f km travelled; %.1f registered species; %.1f numerically reported individuals as a lower bound.",
      typical$protocol, typical$duration_minutes,
      typical$effort_distance_km,
      typical$richness, typical$lower_bound_individuals
    ),
    "",
    "## 2. Spawn paragraph values, in manuscript order",
    "",
    sprintf(
      "1. **Events.** The analysis used %s spawning events linked to eligible SoG checklists; the frozen source contained %s valid records carrying the official SoG region label. The median number of linked events per year was %s, with a range from %s to %s across %s represented years. The linked-event total retains boundary events from adjacent source-region labels when they occur within 20 km, matching the main analysis.",
      lookup("analysis_events", "count", "analysis-linked"),
      lookup("all_strait_events", "count", "all valid Strait records"),
      lookup("events_per_year", "median", "analysis-linked"),
      lookup("events_per_year", "minimum", "analysis-linked"),
      lookup("events_per_year", "maximum", "analysis-linked"),
      lookup("represented_years", "count", "analysis-linked")
    ),
    "",
    sprintf(
      "2. **Recorded span.** Median %s days (IQR %s-%s); maximum %s days; span unavailable for %s events. Distribution: %s.",
      lookup("recorded_span_days", "median", "analysis-linked"),
      lookup("recorded_span_days", "q25", "analysis-linked"),
      lookup("recorded_span_days", "q75", "analysis-linked"),
      lookup("recorded_span_days", "maximum", "analysis-linked"),
      lookup("recorded_span_missing", "count", "analysis-linked"),
      span_bins
    ),
    "",
    sprintf(
      "3. **First recorded spawn timing.** Median day of year %s (IQR %s-%s).",
      lookup("first_spawn_day_of_year", "median", "analysis-linked"),
      lookup("first_spawn_day_of_year", "q25", "analysis-linked"),
      lookup("first_spawn_day_of_year", "q75", "analysis-linked")
    ),
    "",
    sprintf(
      "4. **Within-year season span.** Median %s days (IQR %s-%s). The full annual series is shown below.",
      lookup("within_year_season_span", "median", "analysis-linked years"),
      lookup("within_year_season_span", "q25", "analysis-linked years"),
      lookup("within_year_season_span", "q75", "analysis-linked years")
    ),
    "",
    "| Year | First event | Last event | First day of year | Last day of year | Season span, days |",
    "|---:|---:|---:|---:|---:|---:|",
    season_rows,
    "",
    sprintf(
      "5. **Relative spawn index.** Median %s (IQR %s-%s), range %s-%s. No component was recorded for %s analysis events. Treating unrecorded components as zero in the derived sum affected %s analysis events and %s all-Strait events; component missingness remains explicit, and the sum is not absolute biomass.",
      lookup("relative_spawn_index", "median", "analysis-linked"),
      lookup("relative_spawn_index", "q25", "analysis-linked"),
      lookup("relative_spawn_index", "q75", "analysis-linked"),
      lookup("relative_spawn_index", "minimum", "analysis-linked"),
      lookup("relative_spawn_index", "maximum", "analysis-linked"),
      lookup("no_spawn_component_recorded", "count", "analysis-linked"),
      lookup("component_zero_fill_affected", "count", "analysis-linked"),
      lookup("component_zero_fill_affected", "count", "all valid Strait records")
    ),
    "",
    sprintf(
      "6. **Extent.** Length median %s m (IQR %s-%s; %s missing); width median %s m (IQR %s-%s; %s missing).",
      lookup("length_m", "median", "analysis-linked"),
      lookup("length_m", "q25", "analysis-linked"),
      lookup("length_m", "q75", "analysis-linked"),
      lookup("length_m_missing", "count", "analysis-linked"),
      lookup("width_m", "median", "analysis-linked"),
      lookup("width_m", "q25", "analysis-linked"),
      lookup("width_m", "q75", "analysis-linked"),
      lookup("width_m_missing", "count", "analysis-linked")
    ),
    "",
    sprintf("7. **Survey method.** %s.", method_text),
    "",
    sprintf(
      "8. **Spatial recurrence.** %s distinct locations and %s sections were represented; %s locations recorded spawn in more than one year. Years per location: %s.",
      lookup("distinct_locations", "count", "analysis-linked"),
      lookup("distinct_sections", "count", "analysis-linked"),
      lookup("locations_multiple_years", "count", "analysis-linked"),
      location_year_text
    ),
    "",
    "## 3. Assemblage paragraph values, in manuscript order",
    "",
    "1. **Checklists per cell.** Use the four checklist counts in Table 2.",
    "",
    "2. **Registered-species richness.** Table 2 gives the median, IQR and mean for each cell.",
    "",
    "3. **Numerically reported individuals.** Table 2 gives the median and IQR as lower bounds; unquantified X reports were never converted to zero individuals.",
    "",
    "4. **Checklists with registered species.** Table 2 gives the percentage with at least one of the fixed 49 species.",
    "",
    "5. **Effort.** Duration, distance travelled and observer count appear alongside richness in Table 2.",
    "",
    "6. **Unquantified reports.** Table 2 gives the percentage of positive registered-species records reported as X.",
    "",
    sprintf(
      "7. **Ten species by checklist prevalence, near-zone active window.** %s.",
      top_prev_text
    ),
    "",
    sprintf(
      "8. **Ten species by summed numeric individuals, near-zone active window.** %s. These totals are lower bounds because X reports do not contribute invented counts.",
      top_ind_text
    ),
    "",
    sprintf(
      "9. **Guild shares of registered-species richness, near-zone active window.** %s. Shares are species-checklist detection contributions, not individual-abundance shares.",
      guild_text
    ),
    "",
    "Diversity indices were not calculated because unquantified X reports are missing non-randomly when flocks are large; richness is the requested primary measure.",
    "",
    "## 4. Records omitted or unavailable",
    "",
    sprintf(
      "- %s eligible checklists had no event link within the frozen 20 km source-point link table and were excluded from linked-checklist summaries.",
      format(unlinked_n, big.mark = ",")
    ),
    sprintf(
      "- %s linked checklists had no start-anchored link in days -14 to 14 and therefore did not enter the four-cell table.",
      format(linked_outside_cells_n, big.mark = ",")
    ),
    sprintf(
      "- Recorded span was unavailable for %s analysis events, including %s with an end date before its start date; length was unavailable for %s and width for %s. Those events remained in all other summaries.",
      lookup("recorded_span_missing", "count", "analysis-linked"),
      lookup(
        "recorded_span_negative_interval", "count", "analysis-linked"
      ),
      lookup("length_m_missing", "count", "analysis-linked"),
      lookup("width_m_missing", "count", "analysis-linked")
    ),
    "- Records through 2025 only were used. No 2026-2028 response record was accessed.",
    "- No event, checklist, observer, locality or exact-coordinate identifier is released.",
    "",
    "## 5. Values I advise against reporting without the stated qualification",
    "",
    "- Do not describe the relative spawn index as biomass. It is a method-dependent sum of three recorded components.",
    "- Do not describe summed numeric individuals as total abundance. They are checklist-level lower bounds because X reports remain unquantified.",
    "- Do not compare the four cells inferentially. They are unadjusted descriptives, concurrent-event membership can overlap, and effort differs across cells.",
    "- Do not report Shannon or Simpson diversity from these records without a counted-subset analysis that explicitly states the expected downward bias from large flocks reported as X.",
    "- Do not interpret guild richness shares as shares of individuals; they are shares of detected species-checklist contributions.",
    ""
  )
  writeLines(lines, output_path, useBytes = TRUE)
  invisible(output_path)
}

post_stage4a_descriptive_snapshot_v1 <- function(root) {
  files <- sort(list.files(root, recursive = TRUE, full.names = TRUE))
  files <- files[file.info(files)$isdir %in% FALSE]
  stats::setNames(
    vapply(files, .post_stage4a_sha256_v1, character(1L)),
    gsub("\\\\", "/", files)
  )
}

run_post_stage4a_descriptive_summaries_v1 <- function(
    execution_code_commit,
    output_root = "outputs/post_stage4a_descriptive_summaries_v1") {
  started <- Sys.time()
  spec <- post_stage4a_descriptive_gate_v1()
  if (dir.exists(output_root) &&
      length(list.files(output_root, all.files = TRUE, no.. = TRUE))) {
    stop("DESCRIPTIVE_OUTPUT_GATE: output directory is not empty",
         call. = FALSE)
  }
  parent_root <- "outputs/post_stage4a_sog_event_study_v1"
  stage1_root <- "outputs/post_stage4a_staged_refit_v1"
  parent_before <- post_stage4a_descriptive_snapshot_v1(parent_root)
  stage1_before <- post_stage4a_descriptive_snapshot_v1(stage1_root)

  protected <- c(
    events =
      "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    states =
      "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    links =
      "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz"
  )
  expected_hashes <- c(
    events =
      "03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2",
    states =
      "0f02ac6bdbb561a8e4df58cc8d53340ec29f9519b85a99f4748cb8367fc33cb5",
    links =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b"
  )
  if (!all(file.exists(protected))) {
    stop("DESCRIPTIVE_INPUT_GATE: protected input unavailable",
         call. = FALSE)
  }
  protected_hashes <- vapply(
    protected, .post_stage4a_sha256_v1, character(1L)
  )
  if (!identical(protected_hashes, expected_hashes)) {
    stop("DESCRIPTIVE_INPUT_HASH_GATE: protected input mismatch",
         call. = FALSE)
  }
  herring_path <- Sys.getenv("HERRING_EBIRD_V2_HERRING", unset = "")
  herring <- post_stage4a_descriptive_herring_v1(herring_path)
  events_all <- .stage4a_prepare_events(.stage4a_read_gz(protected[["events"]]))
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  events <- events_all[selected, , drop = FALSE]
  if (
    nrow(events) != 217200L ||
      anyDuplicated(events$analysis_event_token) ||
      any(as.integer(events$checklist_year) > 2025L)
  ) {
    stop("DESCRIPTIVE_CHECKLIST_POPULATION_GATE: changed",
         call. = FALSE)
  }
  links_all <- .stage4a_read_gz(protected[["links"]])
  anchor_lookup <- staged_refit_build_anchor_lookup_v1(herring_path)
  anchored_all <- staged_refit_reanchor_links_v1(
    links_all, anchor_lookup
  )
  event_tokens <- as.character(events$analysis_event_token)
  links <- anchored_all[
    anchored_all$analysis_event_token %in% event_tokens,
    ,
    drop = FALSE
  ]
  if (
    any(!links$analysis_event_token %in% event_tokens) ||
      nrow(links) > nrow(anchored_all)
  ) {
    stop("DESCRIPTIVE_LINK_CHECKLIST_GATE: invalid selected link",
         call. = FALSE)
  }
  source_index <- match(
    links$herring_source_token, herring$herring_source_token
  )
  if (anyNA(source_index)) {
    stop("DESCRIPTIVE_LINK_EVENT_JOIN_GATE: unmatched source token",
         call. = FALSE)
  }
  if (!all(
      as.integer(links$event_year) ==
        as.integer(herring$event_year__[source_index])
  )) {
    stop("DESCRIPTIVE_LINK_EVENT_JOIN_GATE: event year disagreement",
         call. = FALSE)
  }
  linked_source_tokens <- unique(as.character(links$herring_source_token))
  analysis_events <- herring[
    herring$herring_source_token %in% linked_source_tokens
  ]
  if (
    nrow(analysis_events) != length(linked_source_tokens) ||
      anyDuplicated(analysis_events$herring_source_token)
  ) {
    stop("DESCRIPTIVE_ANALYSIS_EVENT_GATE: event grain changed",
         call. = FALSE)
  }
  all_strait_events <- herring[
    Region == "SoG" &
      event_year__ >= 2005L & event_year__ <= 2025L
  ]
  if (!nrow(all_strait_events) ||
      anyDuplicated(all_strait_events$herring_source_token)) {
    stop("DESCRIPTIVE_ALL_STRAIT_GATE: invalid source population",
         call. = FALSE)
  }
  spawn <- post_stage4a_descriptive_spawn_summaries_v1(
    analysis_events, all_strait_events
  )
  membership <- post_stage4a_descriptive_cell_membership_v1(links)
  linked_tokens <- unique(as.character(links$analysis_event_token))
  linked_n <- length(linked_tokens)
  unlinked_n <- nrow(events) - linked_n
  cell_tokens <- unique(membership$analysis_event_token)
  linked_outside_cells_n <- length(setdiff(linked_tokens, cell_tokens))

  states_all <- .stage4a_read_gz(protected[["states"]])
  states <- states_all[
    states_all$analysis_event_token %in% event_tokens,
    ,
    drop = FALSE
  ]
  if (nrow(states_all) != 1169612L || nrow(states) > nrow(states_all)) {
    stop("DESCRIPTIVE_STATE_POPULATION_GATE: changed",
         call. = FALSE)
  }
  support <- utils::read.csv(
    "outputs/stage2_design_lock/species_support_summary.csv",
    stringsAsFactors = FALSE
  )
  core_taxa <- support$analysis_taxon_id[
    support$named_species_recommendation == "named_species_core"
  ]
  if (length(core_taxa) != 49L || anyDuplicated(core_taxa)) {
    stop("DESCRIPTIVE_SPECIES_FAMILY_GATE: fixed 49 changed",
         call. = FALSE)
  }
  species_registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv",
    stringsAsFactors = FALSE
  )
  guild_map <- utils::read.csv(
    "metadata/species_primary_guild.csv",
    stringsAsFactors = FALSE
  )
  assemblage <- post_stage4a_descriptive_assemblage_v1(
    events, states, membership, core_taxa, species_registry, guild_map
  )

  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  paths <- c(
    spawn_event_summaries =
      file.path(output_root, "spawn_event_summaries.csv"),
    spawn_season_by_year =
      file.path(output_root, "spawn_season_by_year.csv"),
    assemblage_by_zone_period =
      file.path(output_root, "assemblage_by_zone_period.csv"),
    assemblage_top_species =
      file.path(output_root, "assemblage_top_species.csv"),
    assemblage_guild_shares =
      file.path(output_root, "assemblage_guild_shares.csv")
  )
  .post_stage4a_write_csv_v1(spawn$summary, paths[["spawn_event_summaries"]])
  .post_stage4a_write_csv_v1(spawn$season, paths[["spawn_season_by_year"]])
  .post_stage4a_write_csv_v1(
    assemblage$cell, paths[["assemblage_by_zone_period"]]
  )
  .post_stage4a_write_csv_v1(
    assemblage$top, paths[["assemblage_top_species"]]
  )
  .post_stage4a_write_csv_v1(
    assemblage$guild, paths[["assemblage_guild_shares"]]
  )
  report_path <- "DESCRIPTIVE_SUMMARIES_REPORT.md"
  post_stage4a_descriptive_report_v1(
    spawn$summary, spawn$season, assemblage,
    linked_n, unlinked_n, linked_outside_cells_n, report_path
  )
  if (!identical(parent_before, post_stage4a_descriptive_snapshot_v1(parent_root)) ||
      !identical(stage1_before, post_stage4a_descriptive_snapshot_v1(stage1_root))) {
    stop("DESCRIPTIVE_HISTORY_GATE: protected history changed",
         call. = FALSE)
  }
  output_paths <- c(paths, report = report_path)
  staged_refit_privacy_column_gate_v1(output_paths)
  if (any(grepl(
      "p_value|q_value|standard_error|confidence_interval",
      unlist(lapply(paths, function(path) names(
        utils::read.csv(path, check.names = FALSE)
      ))),
      ignore.case = TRUE
  ))) {
    stop("DESCRIPTIVE_INFERENCE_GATE: inferential column detected",
         call. = FALSE)
  }
  finished <- Sys.time()
  versions <- c("R", "data.table", "yaml")
  package_versions <- stats::setNames(
    vapply(versions, function(x) {
      if (x == "R") as.character(getRversion()) else
        as.character(utils::packageVersion(x))
    }, character(1L)),
    versions
  )
  membership_counts <- table(membership$analysis_event_token)
  execution <- list(
    analysis_version = post_stage4a_descriptive_version_v1(),
    analysis_status = "descriptive_only_post_result_manuscript_support",
    execution_code_commit = execution_code_commit,
    started_at_utc = format(
      as.POSIXct(started, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    finished_at_utc = format(
      as.POSIXct(finished, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    elapsed_seconds = as.numeric(difftime(
      finished, started, units = "secs"
    )),
    authorization = list(
      variable = "POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED",
      expected_value = "through_2025_post_result_refinement_v1",
      verified_in_shell_before_production = TRUE,
      set_by_agent = FALSE
    ),
    analysis_guards = list(
      start_date_anchor = TRUE,
      end_date_fallback = TRUE,
      models_fitted = FALSE,
      statistical_tests_run = FALSE,
      p_values_produced = FALSE,
      maximum_response_year = 2025L,
      suppression_threshold = 20L,
      privacy_column_gate = "PASS"
    ),
    input_hashes = c(
      herring = attr(herring, "source_hash"),
      as.list(protected_hashes)
    ),
    populations = list(
      eligible_checklists =
        post_stage4a_descriptive_release_count_v1(nrow(events)),
      linked_checklists =
        post_stage4a_descriptive_release_count_v1(linked_n),
      unlinked_checklists =
        post_stage4a_descriptive_release_count_v1(unlinked_n),
      linked_checklists_outside_four_cells =
        post_stage4a_descriptive_release_count_v1(
          linked_outside_cells_n
        ),
      analysis_herring_events =
        post_stage4a_descriptive_release_count_v1(
          nrow(analysis_events)
        ),
      all_strait_herring_events =
        post_stage4a_descriptive_release_count_v1(
          nrow(all_strait_events)
        ),
      fixed_registered_species =
        post_stage4a_descriptive_release_count_v1(length(core_taxa))
    ),
    join_cardinality = list(
      checklist_key = "one row per analysis token PASS",
      links_to_checklists = "many-to-one PASS",
      links_to_herring_events = "many-to-one complete coverage PASS",
      states = "unique checklist-by-species PASS",
      cell_membership = "unique checklist-by-cell PASS",
      checklist_metrics = "one-to-one PASS",
      guild_mapping = "one primary guild per species PASS"
    ),
    concurrent_event_handling = list(
      all_links_retained = TRUE,
      within_cell_deduplication = "one checklist membership indicator",
      checklists_in_multiple_cells =
        post_stage4a_descriptive_release_count_v1(
          sum(membership_counts > 1L)
        ),
      cells_may_be_summed_as_independent_samples = FALSE
    ),
    missingness = list(
      recorded_span_missing =
        post_stage4a_descriptive_release_count_v1(
          sum(is.na(analysis_events$span_days__))
        ),
      recorded_span_negative_interval =
        post_stage4a_descriptive_release_count_v1(
          sum(analysis_events$span_invalid_negative__)
        ),
      length_missing =
        post_stage4a_descriptive_release_count_v1(
          sum(!is.finite(analysis_events$length_m__))
        ),
      width_missing =
        post_stage4a_descriptive_release_count_v1(
          sum(!is.finite(analysis_events$width_m__))
        ),
      no_spawn_component_recorded =
        post_stage4a_descriptive_release_count_v1(
          sum(analysis_events$no_component_recorded__)
        ),
      any_spawn_component_unrecorded =
        post_stage4a_descriptive_release_count_v1(
          sum(analysis_events$any_component_missing__)
        ),
      records_dropped_for_missing_component = 0L,
      x_reports_converted_to_numeric = 0L
    ),
    suppression = list(
      counts_below_20_withheld = TRUE,
      suppressed_spawn_summary_rows =
        sum(spawn$summary$suppressed_below_20),
      top_species_small_count_rows = 0L,
      guild_small_count_rows = 0L
    ),
    package_versions = as.list(package_versions),
    source_notes = list(
      official_source =
        "Fisheries and Oceans Canada Pacific herring spawn index data 2025",
      frozen_source_line_endings =
        "CRLF byte representation matching the registered frozen SHA-256",
      diversity_indices = "not calculated"
    ),
    output_gate = "PASS_PENDING_REPORT_VALIDATION"
  )
  execution_path <- file.path(output_root, "execution_record_v1.yml")
  staged_refit_write_yaml_lf_v1(execution, execution_path)
  output_paths <- c(output_paths, execution_record = execution_path)
  manifest <- data.frame(
    file = gsub("\\\\", "/", unname(output_paths)),
    sha256 = vapply(output_paths, .post_stage4a_sha256_v1, character(1L)),
    stringsAsFactors = FALSE
  )
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  message("POST_STAGE4A_DESCRIPTIVE_SUMMARIES_GATE=PASS")
  invisible(list(
    spawn = spawn, assemblage = assemblage, execution = execution,
    outputs = output_paths
  ))
}

post_stage4a_descriptive_fixture_v1 <- function() {
  spec <- post_stage4a_descriptive_gate_v1()
  stopifnot(
    identical(spec$scope$models_fitted, FALSE),
    identical(spec$scope$statistical_tests_run, FALSE)
  )
  x <- data.frame(
    analysis_event_token = c("a", "a", "b", "c"),
    event_day = c(-14L, -1L, 0L, 14L),
    distance_km = c(1, 1, 5, 4.9),
    stringsAsFactors = FALSE
  )
  membership <- post_stage4a_descriptive_cell_membership_v1(x)
  stopifnot(
    nrow(membership) == 3L,
    setequal(
      membership$cell,
      c("near_pre", "reference_active", "near_active")
    )
  )
  b <- post_stage4a_descriptive_summary_builder_v1()
  b$add(1L, "small", "fixture", "count", 19, "events", "count")
  b$add(1L, "large", "fixture", "count", 20, "events", "count")
  out <- b$result()
  stopifnot(
    is.na(out$value_numeric[out$metric_id == "small"]),
    out$display_value[out$metric_id == "small"] == "<20",
    out$value_numeric[out$metric_id == "large"] == 20
  )
  message("POST_STAGE4A_DESCRIPTIVE_SUMMARIES_FIXTURE=PASS")
  invisible(TRUE)
}
