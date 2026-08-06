stage3_dose_version_v1 <- function() {
  "post_stage4a_stage3_dose_v1"
}

stage3_dose_source_files_v1 <- function() {
  c(
    event_metadata =
      "data/derived/stage4a_protected/stage4a_event_metadata.tsv.gz",
    detectability = file.path(
      "data", "derived", "post_stage4a_staged_refit_stage2_v1",
      "stage2_detectability_covariates.tsv.gz"
    ),
    source_links_archived =
      "data/derived/stage3_phase2_protected/metadata_source_point_links.tsv.gz",
    source_links_placebo = paste0(
      "data/derived/post_stage4a_staged_refit_amendment_v1/",
      "placebo_link_builder/metadata_source_point_links.tsv.gz"
    ),
    reported_states =
      "data/derived/stage4a_protected/stage4a_reported_states.tsv.gz",
    ambiguity_masks =
      "data/derived/stage4a_protected/stage4a_ambiguity_masks.tsv.gz"
  )
}

stage3_dose_expected_hashes_v1 <- function() {
  c(
    event_metadata =
      "03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2",
    detectability =
      "8a43d3f84d1914ab2b1ce53978aa5b40092b5a777924b8d0c376f975da03a429",
    source_links_archived =
      "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b",
    source_links_placebo =
      "2605fed6fd3e511dc634ce7ac684a54ec652730b261816bf903c2a8ff31b749c",
    reported_states =
      "0f02ac6bdbb561a8e4df58cc8d53340ec29f9519b85a99f4748cb8367fc33cb5",
    ambiguity_masks =
      "c0e063f8a8c6ccfb97535183d8e669a9f4bb1eaea31bae144dffa3d81d57d3ff"
  )
}

stage3_dose_authorization_gate_v1 <- function() {
  authorization <- staged_refit_authorization_gate_v1()
  expected <- authorization$environment_acknowledgement$value
  observed <- Sys.getenv(
    "POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED", unset = ""
  )
  if (!identical(observed, expected)) {
    stop(
      "STAGE3_DOSE_AUTHORIZATION_GATE: exact author-set shell value absent",
      call. = FALSE
    )
  }
  invisible(authorization)
}

stage3_dose_spec_gate_v1 <- function(
    path = "metadata/post_stage4a_stage3_dose_spec_v1.yml") {
  if (!file.exists(path)) {
    stop("STAGE3_DOSE_SPEC_GATE: prespecification absent", call. = FALSE)
  }
  spec <- yaml::read_yaml(path)
  if (
    !identical(spec$spec_version, "post_stage4a_stage3_dose_spec_v1") ||
      !identical(spec$species_scope$family, "fixed_49_registered_species") ||
      !identical(spec$dose_definition$transform,
                 "log(relative_spawn_index_t)") ||
      !identical(spec$models$primary_component, "within_location") ||
      !identical(unlist(spec$sensitivities$placebo$offsets_days),
                 c(-90L, 90L))
  ) {
    stop("STAGE3_DOSE_SPEC_GATE: prespecification mismatch", call. = FALSE)
  }
  invisible(spec)
}

stage3_dose_parent_gate_v1 <- function() {
  root <- "outputs/post_stage4a_staged_refit_stage2_v1"
  staged_refit_s2_verify_manifest_v1(root)
  execution <- yaml::read_yaml(file.path(root, "execution_record_v1.yml"))
  tallies <- execution$headline_primary_contrast
  count_row <- Filter(
    function(x) identical(x$outcome,
                          "conditional_positive_numeric_count"),
    tallies
  )
  reporting_row <- Filter(
    function(x) identical(x$outcome, "checklist_reporting"),
    tallies
  )
  if (
    length(count_row) != 1L || length(reporting_row) != 1L ||
      !identical(count_row[[1L]]$positive_bh_q_lt_0_05, 20L) ||
      !identical(reporting_row[[1L]]$positive_bh_q_lt_0_05, 13L)
  ) {
    stop("STAGE3_DOSE_PARENT_GATE: Stage 2 headline changed", call. = FALSE)
  }
  invisible(execution)
}

stage3_dose_release_count_v1 <- function(x) {
  as.numeric(.post_stage4a_release_count_v1(as.numeric(x)))
}

stage3_dose_component_columns_v1 <- function() {
  c("Surface", "Macrocystis", "Understory")
}

stage3_dose_method_group_v1 <- function(method) {
  values <- unique(tolower(trimws(as.character(method))))
  values <- values[!is.na(values) & nzchar(values) &
                     !values %in% c("na", "n/a", "null")]
  if (!length(values)) return("missing")
  normalized <- ifelse(
    grepl("surface", values), "surface",
    ifelse(grepl("dive", values), "dive", "incomplete")
  )
  normalized <- unique(normalized)
  if (length(normalized) > 1L) return("mixed")
  paste0(normalized, "_only")
}

stage3_dose_read_index_v1 <- function(herring_path) {
  expected_hash <-
    "6d3b2c08e3586bde52f5fe2af602c63014468b54e49dc906bd1f8dfe6706e8ac"
  if (
    !file.exists(herring_path) ||
      !identical(.post_stage4a_sha256_v1(herring_path), expected_hash)
  ) {
    stop("STAGE3_DOSE_HERRING_HASH_GATE: frozen source mismatch",
         call. = FALSE)
  }
  required <- c(
    "Year", "StatisticalArea", "Section", "LocationCode", "SpawnNumber",
    "StartDate", "EndDate", "Longitude", "Latitude", "Length", "Width",
    "Method", stage3_dose_component_columns_v1()
  )
  raw <- data.table::fread(
    herring_path,
    select = required,
    colClasses = "character",
    na.strings = NULL,
    showProgress = FALSE
  )
  .post_stage4a_require_fields_v1(raw, required, "Stage 3 herring source")
  raw[, source_row__ := .I]
  for (name in required) {
    data.table::set(raw, j = name,
                    value = staged_refit_clean_v1(raw[[name]]))
  }
  raw[, event_year__ := suppressWarnings(as.integer(Year))]
  raw[, start_date__ := data.table::as.IDate(
    StartDate, format = "%Y-%m-%d"
  )]
  raw[, end_date__ := data.table::as.IDate(
    EndDate, format = "%Y-%m-%d"
  )]
  raw[, longitude__ := suppressWarnings(as.numeric(Longitude))]
  raw[, latitude__ := suppressWarnings(as.numeric(Latitude))]
  valid <- !is.na(raw$event_year__) &
    raw$event_year__ >= 1988L & raw$event_year__ <= 2025L &
    (!is.na(raw$start_date__) | !is.na(raw$end_date__)) &
    is.finite(raw$longitude__) & is.finite(raw$latitude__) &
    raw$longitude__ >= -180 & raw$longitude__ <= 180 &
    raw$latitude__ >= -90 & raw$latitude__ <= 90
  raw <- raw[valid]
  if (!nrow(raw)) {
    stop("STAGE3_DOSE_HERRING_GATE: no eligible source rows", call. = FALSE)
  }

  raw[, source_identity__ := paste(
    source_row__, event_year__, StatisticalArea, Section, LocationCode,
    SpawnNumber, sep = "|"
  )]
  raw[, herring_source_token := staged_refit_hash_token_v1(
    "herring_source", source_identity__
  )]
  if (anyDuplicated(raw$herring_source_token)) {
    stop("STAGE3_DOSE_SOURCE_TOKEN_GATE: duplicate source token",
         call. = FALSE)
  }
  raw[, event_identity__ := paste(
    event_year__, LocationCode, Section, SpawnNumber, sep = "|"
  )]
  raw[, dose_event_token__ := staged_refit_hash_token_v1(
    "herring_dose_event", event_identity__
  )]
  raw[, location_identity__ := paste(LocationCode, Section, sep = "|")]
  raw[, dose_location_token__ := staged_refit_hash_token_v1(
    "herring_dose_location", location_identity__
  )]
  if (any(raw[, data.table::uniqueN(dose_location_token__),
              by = dose_event_token__]$V1 != 1L)) {
    stop("STAGE3_DOSE_EVENT_LOCATION_GATE: event spans locations",
         call. = FALSE)
  }
  raw[, statistical_area_count__ := data.table::uniqueN(StatisticalArea),
      by = dose_event_token__]

  components <- stage3_dose_component_columns_v1()
  recorded_columns <- character()
  for (name in components) {
    numeric_name <- paste0(tolower(name), "_index__")
    recorded_name <- paste0(tolower(name), "_recorded__")
    raw[, (recorded_name) := !staged_refit_missing_text_v1(get(name))]
    raw[, (numeric_name) := suppressWarnings(as.numeric(get(name)))]
    if (any(raw[[recorded_name]] & !is.finite(raw[[numeric_name]]))) {
      stop("STAGE3_DOSE_COMPONENT_GATE: recorded nonnumeric component",
           call. = FALSE)
    }
    recorded_columns <- c(recorded_columns, recorded_name)
  }
  numeric_components <- paste0(tolower(components), "_index__")
  raw[, any_component_recorded__ :=
        rowSums(.SD) > 0L, .SDcols = recorded_columns]
  raw[, row_index__ := rowSums(
    as.data.frame(lapply(.SD, function(x) {
      x[!is.finite(x)] <- 0
      x
    }))
  ), .SDcols = numeric_components]
  raw[, length__ := suppressWarnings(as.numeric(Length))]
  raw[, width__ := suppressWarnings(as.numeric(Width))]
  raw[, row_extent__ := data.table::fifelse(
    is.finite(length__) & length__ > 0 &
      is.finite(width__) & width__ > 0,
    length__ * width__, NA_real_
  )]

  event <- raw[, {
    length_values <- length__[is.finite(length__) & length__ > 0]
    extent_values <- row_extent__[is.finite(row_extent__) &
                                    row_extent__ > 0]
    list(
      event_year = event_year__[[1L]],
      dose_location_token__ = dose_location_token__[[1L]],
      survey_rows = .N,
      statistical_areas = data.table::uniqueN(StatisticalArea),
      any_component_recorded = any(any_component_recorded__),
      relative_spawn_index_t = sum(row_index__),
      event_length_m = if (length(length_values)) {
        sum(length_values)
      } else {
        NA_real_
      },
      event_extent_m2 = if (length(extent_values)) {
        sum(extent_values)
      } else {
        NA_real_
      },
      survey_method_group = stage3_dose_method_group_v1(Method)
    )
  }, by = dose_event_token__]
  if (anyDuplicated(event$dose_event_token__)) {
    stop("STAGE3_DOSE_EVENT_AGGREGATION_GATE: duplicate event",
         call. = FALSE)
  }

  event[, score_status := data.table::fifelse(
    !any_component_recorded, "no_recorded_component",
    data.table::fifelse(
      !is.finite(relative_spawn_index_t) | relative_spawn_index_t <= 0,
      "nonpositive_scored_event", "positive_scored_event"
    )
  )]
  event[, log_index := data.table::fifelse(
    score_status == "positive_scored_event",
    log(relative_spawn_index_t), NA_real_
  )]
  event[, log_length := data.table::fifelse(
    is.finite(event_length_m) & event_length_m > 0,
    log(event_length_m), NA_real_
  )]
  event[, log_extent := data.table::fifelse(
    is.finite(event_extent_m2) & event_extent_m2 > 0,
    log(event_extent_m2), NA_real_
  )]
  positive <- event[score_status == "positive_scored_event"]
  positive[, location_log_mean := mean(log_index),
           by = dose_location_token__]
  event <- merge(
    event,
    positive[, .(dose_event_token__, location_log_mean)],
    by = "dose_event_token__",
    all.x = TRUE,
    sort = FALSE
  )
  if (nrow(event) != data.table::uniqueN(raw$dose_event_token__)) {
    stop("STAGE3_DOSE_EVENT_JOIN_GATE: row multiplication",
         call. = FALSE)
  }

  source_map <- as.data.frame(raw[, .(
    herring_source_token, dose_event_token__
  )])
  if (
    anyDuplicated(source_map$herring_source_token) ||
      anyNA(match(source_map$dose_event_token__, event$dose_event_token__))
  ) {
    stop("STAGE3_DOSE_SOURCE_EVENT_JOIN_GATE: many-to-one failure",
         call. = FALSE)
  }
  list(
    events = as.data.frame(event),
    source_map = source_map,
    source_hash = expected_hash,
    valid_source_rows = nrow(raw)
  )
}

stage3_dose_index_audit_v1 <- function(index) {
  event <- data.table::as.data.table(index$events)
  positive <- event[score_status == "positive_scored_event"]
  quantiles <- stats::quantile(
    positive$relative_spawn_index_t,
    probs = c(0, 0.25, 0.5, 0.75, 1),
    na.rm = TRUE,
    names = FALSE,
    type = 7
  )
  rows <- data.frame(
    audit_section = "event_index_distribution",
    method_group = "all",
    metric = c("minimum", "q25", "median", "q75", "maximum"),
    value = as.numeric(quantiles),
    count = NA_real_,
    count_suppressed_below_20 = FALSE,
    definition = "positive scored aggregated events",
    stringsAsFactors = FALSE
  )
  counts <- data.frame(
    audit_section = "event_aggregation_counts",
    method_group = "all",
    metric = c(
      "valid_source_rows", "aggregated_events",
      "events_no_recorded_component", "nonpositive_scored_events",
      "positive_scored_events", "multirow_events",
      "events_spanning_multiple_statistical_areas"
    ),
    value = NA_real_,
    count = c(
      index$valid_source_rows, nrow(event),
      sum(event$score_status == "no_recorded_component"),
      sum(event$score_status == "nonpositive_scored_event"),
      nrow(positive), sum(event$survey_rows > 1L),
      sum(event$statistical_areas > 1L)
    ),
    count_suppressed_below_20 = FALSE,
    definition = c(
      "eligible frozen survey rows through 2025",
      "Year + LocationCode + Section + SpawnNumber",
      "dropped from dose; not treated as zero spawn",
      "dropped separately because log index is undefined",
      "eligible for dose scoring",
      "aggregated event contains more than one survey row",
      "diagnostic only; StatisticalArea is not in the specified event key"
    ),
    stringsAsFactors = FALSE
  )
  method <- positive[, .(
    count__ = .N,
    minimum = min(relative_spawn_index_t),
    q25 = stats::quantile(relative_spawn_index_t, 0.25, names = FALSE),
    median = stats::median(relative_spawn_index_t),
    q75 = stats::quantile(relative_spawn_index_t, 0.75, names = FALSE),
    maximum = max(relative_spawn_index_t)
  ), by = survey_method_group]
  method_rows <- do.call(rbind, lapply(seq_len(nrow(method)), function(i) {
    data.frame(
      audit_section = "survey_method_cross_tab",
      method_group = method$survey_method_group[[i]],
      metric = c("minimum", "q25", "median", "q75", "maximum"),
      value = as.numeric(method[i, c(
        "minimum", "q25", "median", "q75", "maximum"
      )]),
      count = method$count__[[i]],
      count_suppressed_below_20 = method$count__[[i]] < 20L,
      definition = "positive scored aggregated events",
      stringsAsFactors = FALSE
    )
  }))
  method_rows$count <- stage3_dose_release_count_v1(method_rows$count)
  cross <- event[, .(count__ = .N),
                 by = .(survey_method_group, score_status)]
  cross_rows <- data.frame(
    audit_section = "survey_method_score_status_cross_tab",
    method_group = cross$survey_method_group,
    metric = cross$score_status,
    value = NA_real_,
    count = stage3_dose_release_count_v1(cross$count__),
    count_suppressed_below_20 =
      cross$count__ > 0L & cross$count__ < 20L,
    definition = "all aggregated events by method group and score status",
    stringsAsFactors = FALSE
  )
  counts$count_suppressed_below_20 <-
    is.finite(counts$count) & counts$count > 0 & counts$count < 20L
  counts$count <- stage3_dose_release_count_v1(counts$count)
  rbind(rows, counts, method_rows, cross_rows)
}

stage3_dose_link_audit_v1 <- function(links) {
  classified <- post_stage4a_classify_links_v1(links)
  use <- !is.na(classified$period)
  dt <- data.table::data.table(
    analysis_event_token = as.character(
      links$analysis_event_token[use]
    ),
    dose_event_token__ = as.character(
      links$dose_event_token__[use]
    )
  )
  grouped <- dt[, .(source_link_rows = .N),
                by = .(analysis_event_token, dose_event_token__)]
  if (any(grouped$source_link_rows != 1L)) {
    stop(
      "STAGE3_DOSE_CHECKLIST_EVENT_LINK_GATE: duplicate aggregated-event link",
      call. = FALSE
    )
  }
  raw <- c(
    analysis_window_source_link_rows = nrow(dt),
    unique_checklist_aggregated_event_links = nrow(grouped),
    duplicated_checklist_aggregated_event_groups =
      sum(grouped$source_link_rows > 1L),
    excess_duplicate_link_rows =
      sum(grouped$source_link_rows - 1L)
  )
  data.frame(
    audit_section = "link_cardinality",
    method_group = "all",
    metric = names(raw),
    value = NA_real_,
    count = stage3_dose_release_count_v1(raw),
    count_suppressed_below_20 = raw > 0 & raw < 20,
    definition = c(
      "start-date anchor links in -28 to +28 day support",
      "declared checklist-to-aggregated-event many-to-one mapping",
      "must be zero or explicitly resolved before fitting",
      "must be zero or explicitly resolved before fitting"
    ),
    stringsAsFactors = FALSE
  )
}

stage3_dose_attach_event_scores_v1 <- function(links, index) {
  map_index <- match(
    as.character(links$herring_source_token),
    as.character(index$source_map$herring_source_token)
  )
  if (anyNA(map_index)) {
    stop("STAGE3_DOSE_LINK_SOURCE_JOIN_GATE: unmatched link",
         call. = FALSE)
  }
  out <- links
  out$dose_event_token__ <-
    index$source_map$dose_event_token__[map_index]
  event_index <- match(
    out$dose_event_token__, index$events$dose_event_token__
  )
  if (anyNA(event_index)) {
    stop("STAGE3_DOSE_LINK_EVENT_JOIN_GATE: unmatched event",
         call. = FALSE)
  }
  add <- c(
    "dose_location_token__", "score_status", "relative_spawn_index_t",
    "log_index", "location_log_mean", "survey_method_group",
    "event_length_m", "log_length", "event_extent_m2", "log_extent",
    "event_year"
  )
  out[add] <- index$events[event_index, add, drop = FALSE]
  if (nrow(out) != nrow(links)) {
    stop("STAGE3_DOSE_LINK_EVENT_CARDINALITY_GATE: rows changed",
         call. = FALSE)
  }
  out
}

stage3_dose_prefix_terms_v1 <- function(prefix) {
  sub("^es_", paste0(prefix, "_"), post_stage4a_exposure_terms_v1())
}

stage3_dose_widen_by_link_v1 <- function(
    events, links, index, real_grand_mean = NULL,
    links_are_reanchored = FALSE, surface_only = FALSE,
    include_extent = FALSE) {
  if (!links_are_reanchored) {
    stop("STAGE3_DOSE_LINK_GATE: links must already use start-date anchor",
         call. = FALSE)
  }
  event_tokens <- as.character(events$analysis_event_token)
  selected <- links[
    as.character(links$analysis_event_token) %in% event_tokens,
    ,
    drop = FALSE
  ]
  if (surface_only) {
    selected <- selected[
      selected$survey_method_group == "surface_only", , drop = FALSE
    ]
  }
  counts <- table(selected$analysis_event_token)
  adjusted <- events
  adjusted$concurrent_links <- as.integer(counts[event_tokens])
  adjusted$concurrent_links[is.na(adjusted$concurrent_links)] <- 0L
  joint <- post_stage4a_add_joint_exposure_v1(adjusted, selected)
  classified <- post_stage4a_classify_links_v1(selected)
  selected$period__ <- classified$period
  selected$zone__ <- classified$zone
  selected$term__ <- classified$term
  selected <- selected[!is.na(selected$term__), , drop = FALSE]

  scored <- selected[
    selected$score_status == "positive_scored_event" &
      is.finite(selected$log_index), ,
    drop = FALSE
  ]
  if (is.null(real_grand_mean)) {
    real_grand_mean <- mean(scored$log_index)
  }
  if (!is.finite(real_grand_mean)) {
    stop("STAGE3_DOSE_GRAND_MEAN_GATE: undefined", call. = FALSE)
  }
  scored$dose_total__ <- scored$log_index - real_grand_mean
  scored$dose_within__ <- scored$log_index - scored$location_log_mean
  scored$dose_between__ <-
    scored$location_log_mean - real_grand_mean
  if (any(abs(
      scored$dose_total__ -
        scored$dose_within__ - scored$dose_between__
    ) > 1e-10)) {
    stop("STAGE3_DOSE_DECOMPOSITION_GATE: event identity failed",
         call. = FALSE)
  }

  aggregate_wide <- function(value, prefix, data = scored) {
    terms <- stage3_dose_prefix_terms_v1(prefix)
    if (!nrow(data)) {
      wide <- data.frame(analysis_event_token = character())
    } else {
      dt <- data.table::as.data.table(data)
      dt[, output_term__ := sub("^es_", paste0(prefix, "_"), term__)]
      agg <- dt[, .(value__ = sum(get(value))),
                by = .(analysis_event_token, output_term__)]
      wide <- data.table::dcast(
        agg, analysis_event_token ~ output_term__,
        value.var = "value__", fill = 0
      )
    }
    for (term in terms) {
      if (!term %in% names(wide)) wide[[term]] <- 0
    }
        wide <- data.table::as.data.table(wide)
        as.data.frame(wide[, c("analysis_event_token", terms), with = FALSE])
  }
  total_wide <- aggregate_wide("dose_total__", "dose_total")
  within_wide <- aggregate_wide("dose_within__", "dose_within")
  between_wide <- aggregate_wide("dose_between__", "dose_between")

  method <- selected
  method$method_model__ <- ifelse(
    method$survey_method_group == "dive_only", "dive_only",
    ifelse(
      method$survey_method_group == "incomplete_only",
      "incomplete_only", ifelse(
        method$survey_method_group == "surface_only",
        "surface_only", "mixed_or_missing"
      )
    )
  )
  method_counts <- data.table::as.data.table(method)[
    , .(method_links__ = .N),
    by = .(analysis_event_token, method_model__)
  ]
  method_wide <- data.table::dcast(
    method_counts, analysis_event_token ~ method_model__,
    value.var = "method_links__", fill = 0L
  )
  method_terms <- c(
    "method_links_dive_only", "method_links_incomplete_only",
    "method_links_mixed_or_missing"
  )
  names(method_wide) <- sub(
    "^(dive_only|incomplete_only|mixed_or_missing)$",
    "method_links_\\1", names(method_wide)
  )
  for (term in method_terms) {
    if (!term %in% names(method_wide)) method_wide[[term]] <- 0L
  }
  method_wide <- as.data.frame(method_wide[
    , c("analysis_event_token", method_terms), with = FALSE
  ])

  joined <- joint$events
  join_one <- function(base, add, label) {
    index__ <- match(
      as.character(base$analysis_event_token),
      as.character(add$analysis_event_token)
    )
    columns <- setdiff(names(add), "analysis_event_token")
    base[columns] <- add[index__, columns, drop = FALSE]
    for (name in columns) base[[name]][is.na(base[[name]])] <- 0
    if (nrow(base) != nrow(events) ||
        anyDuplicated(base$analysis_event_token)) {
      stop("STAGE3_DOSE_WIDE_JOIN_GATE: ", label, call. = FALSE)
    }
    base
  }
  joined <- join_one(joined, total_wide, "total")
  joined <- join_one(joined, within_wide, "within")
  joined <- join_one(joined, between_wide, "between")
  joined <- join_one(joined, method_wide, "method")

  extent_correlation <- NA_real_
  extent_event_n <- 0L
  length_grand_mean <- NA_real_
  if (include_extent) {
    eligible_extent <- scored[
      is.finite(scored$log_length), , drop = FALSE
    ]
    length_grand_mean <- mean(eligible_extent$log_length)
    eligible_extent$length_centered__ <-
      eligible_extent$log_length - length_grand_mean
    extent_wide <- aggregate_wide(
      "length_centered__", "dose_length", eligible_extent
    )
    joined <- join_one(joined, extent_wide, "extent")
    correlation_events <- index$events[
      index$events$score_status == "positive_scored_event" &
        is.finite(index$events$log_extent), , drop = FALSE
    ]
    extent_event_n <- nrow(correlation_events)
    if (extent_event_n >= 2L) {
      extent_correlation <- stats::cor(
        correlation_events$log_index,
        correlation_events$log_extent
      )
    }
  }
  total_terms <- stage3_dose_prefix_terms_v1("dose_total")
  within_terms <- stage3_dose_prefix_terms_v1("dose_within")
  between_terms <- stage3_dose_prefix_terms_v1("dose_between")
  identity <- rowSums(joined[total_terms]) -
    rowSums(joined[within_terms]) -
    rowSums(joined[between_terms])
  if (any(abs(identity) > 1e-9)) {
    stop("STAGE3_DOSE_DECOMPOSITION_GATE: checklist identity failed",
         call. = FALSE)
  }
  list(
    events = joined,
    selected_links = selected,
    scored_links = scored,
    grand_mean_log_index = real_grand_mean,
    method_terms = method_terms,
    extent_correlation = extent_correlation,
    extent_event_n = extent_event_n,
    length_grand_mean = length_grand_mean
  )
}

stage3_dose_formula_v1 <- function(
    response, variant = c("reduced", "total", "decomposed", "extent"),
    effort_response = NULL) {
  variant <- match.arg(variant)
  effort <- c("log_duration", "log_effort_distance", "observer_count")
  effort_covariates <- if (is.null(effort_response)) {
    effort
  } else {
    setdiff(effort, effort_response)
  }
  fixed <- c(
    post_stage4a_exposure_terms_v1(),
    "factor(checklist_year)", "protocol", effort_covariates,
    staged_refit_s2_detectability_terms_v1(),
    "method_links_dive_only", "method_links_incomplete_only",
    "method_links_mixed_or_missing"
  )
  if (variant == "total") {
    fixed <- c(fixed, stage3_dose_prefix_terms_v1("dose_total"))
  }
  if (variant %in% c("decomposed", "extent")) {
    fixed <- c(
      fixed, stage3_dose_prefix_terms_v1("dose_within"),
      stage3_dose_prefix_terms_v1("dose_between")
    )
  }
  if (variant == "extent") {
    fixed <- c(fixed, stage3_dose_prefix_terms_v1("dose_length"))
  }
  stats::as.formula(paste(
    response, "~", paste(fixed, collapse = " + "),
    "+ (1 | event_block_token) + (1 | observer_cluster_token) +",
    "(1 | location_cluster_token)"
  ))
}

stage3_dose_weights_v1 <- function(prefix) {
  weights <- staged_refit_s1_contrast_weights_v1()$active_minus_pre14
  names(weights) <- sub("^es_", paste0(prefix, "_"), names(weights))
  weights
}

stage3_dose_model_data_v1 <- function(dat, outcome) {
  if (outcome == "checklist_reporting") {
    use <- !is.na(dat$detection)
    dat$model_response <- dat$detection
  } else if (outcome == "conditional_positive_numeric_count") {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    dat$model_response <- log(dat$numeric_count)
  } else if (outcome %in% c(
      "log_duration", "log_effort_distance", "observer_count"
  )) {
    use <- is.finite(dat[[outcome]])
    dat$model_response <- dat[[outcome]]
  } else {
    stop("STAGE3_DOSE_OUTCOME_GATE: unsupported", call. = FALSE)
  }
  dat[use, , drop = FALSE]
}

stage3_dose_fit_engine_v1 <- function(
    formula, data, outcome, maximum_likelihood = FALSE) {
  if (outcome == "checklist_reporting") {
    lme4::glmer(
      formula, data = data, family = stats::binomial(), nAGQ = 0L,
      control = lme4::glmerControl(
        optimizer = "nloptwrap", calc.derivs = TRUE,
        optCtrl = list(maxeval = 10000L)
      )
    )
  } else {
    lme4::lmer(
      formula, data = data, REML = !maximum_likelihood,
      control = lme4::lmerControl(
        optimizer = "nloptwrap", calc.derivs = TRUE,
        optCtrl = list(maxeval = 10000L)
      )
    )
  }
}

stage3_dose_diagnostic_v1 <- function(fit, formula, data, status) {
  beta <- lme4::fixef(fit)
  optimizer_code <- fit@optinfo$conv$opt
  singular <- lme4::isSingular(fit, tol = 1e-4)
  classification <- .post_stage4a_model_messages_v1(
    optimizer_code, fit@optinfo$conv$lme4$messages, singular
  )
  rank_deficient <- length(beta) < ncol(stats::model.matrix(
    lme4::nobars(formula), data
  ))
  gradients <- fit@optinfo$derivs$gradient
  data.frame(
    converged = classification$converged,
    singular_fit = singular,
    rank_deficient = rank_deficient,
    convergence_message = classification$message,
    maximum_absolute_gradient = if (is.null(gradients)) {
      NA_real_
    } else {
      max(abs(gradients))
    },
    status = status,
    stringsAsFactors = FALSE
  )
}

stage3_dose_empty_fit_v1 <- function(
    taxon_id, species, outcome, status, n) {
  effects <- do.call(rbind, lapply(
    c("within_location", "between_location"), function(component) {
      data.frame(
        analysis_version = stage3_dose_version_v1(),
        analysis_taxon_id = taxon_id,
        species = species,
        outcome = outcome,
        component = component,
        comparison = "dose_did_active_minus_pre",
        estimate = NA_real_, standard_error = NA_real_,
        conf_low = NA_real_, conf_high = NA_real_,
        ratio = NA_real_, ratio_conf_low = NA_real_,
        ratio_conf_high = NA_real_, p_value = NA_real_,
        q_value = NA_real_, n = stage3_dose_release_count_v1(n),
        full_fixed_effect_covariance_used = TRUE,
        status = status,
        stringsAsFactors = FALSE
      )
    }
  ))
  lrt <- data.frame(
    analysis_version = stage3_dose_version_v1(),
    analysis_taxon_id = taxon_id, species = species, outcome = outcome,
    comparison = "total_dose_model_vs_reduced",
    likelihood_ratio = NA_real_, degrees_freedom = NA_real_,
    p_value = NA_real_, q_value = NA_real_,
    n = stage3_dose_release_count_v1(n), status = status,
    stringsAsFactors = FALSE
  )
  diagnostic <- data.frame(
    analysis_taxon_id = taxon_id, species = species, outcome = outcome,
    model = c("reduced_ml", "total_ml", "decomposed"),
    converged = FALSE, singular_fit = NA, rank_deficient = NA,
    convergence_message = status, maximum_absolute_gradient = NA_real_,
    status = status, stringsAsFactors = FALSE
  )
  list(effects = effects, lrt = lrt, diagnostics = diagnostic)
}

stage3_dose_fit_taxon_v1 <- function(
    dat, taxon_id, species, outcome, checkpoint_path, cache_signature,
    fit_lrt = TRUE, variant = "decomposed", effort_response = NULL) {
  if (file.exists(checkpoint_path)) {
    cached <- readRDS(checkpoint_path)
    if (identical(cached$cache_signature, cache_signature)) {
      return(cached$result)
    }
  }
  d <- stage3_dose_model_data_v1(dat, outcome)
  support <- nrow(d) >= 20L &&
    length(unique(d$model_response)) >= 2L &&
    all(vapply(
      post_stage4a_exposure_terms_v1(),
      function(term) sum(d[[term]] > 0) >= 20L,
      logical(1L)
    )) &&
    all(vapply(
      c(
        "event_block_token", "observer_cluster_token",
        "location_cluster_token"
      ),
      function(term) length(unique(d[[term]])) >= 2L,
      logical(1L)
    ))
  if (!support) {
    result <- stage3_dose_empty_fit_v1(
      taxon_id, species, outcome, "failed_insufficient_support", nrow(d)
    )
    saveRDS(list(cache_signature = cache_signature, result = result),
            checkpoint_path)
    return(result)
  }

  decomposed_formula <- stage3_dose_formula_v1(
    "model_response", variant = variant, effort_response = effort_response
  )
  decomposed <- try(
    stage3_dose_fit_engine_v1(
      decomposed_formula, d, outcome, maximum_likelihood = FALSE
    ),
    silent = TRUE
  )
  if (inherits(decomposed, "try-error")) {
    result <- stage3_dose_empty_fit_v1(
      taxon_id, species, outcome,
      "failed_decomposed_fit_no_fallback", nrow(d)
    )
    result$diagnostics$convergence_message <- substr(
      gsub("[\r\n]+", " ", as.character(decomposed)), 1L, 240L
    )
    saveRDS(list(cache_signature = cache_signature, result = result),
            checkpoint_path)
    return(result)
  }
  beta <- lme4::fixef(decomposed)
  covariance <- as.matrix(stats::vcov(decomposed))
  components <- c(
    within_location = "dose_within",
    between_location = "dose_between"
  )
  effects <- do.call(rbind, lapply(names(components), function(component) {
    x <- staged_refit_wald_v1(
      beta, covariance,
      stage3_dose_weights_v1(components[[component]])
    )
    data.frame(
      analysis_version = stage3_dose_version_v1(),
      analysis_taxon_id = taxon_id, species = species, outcome = outcome,
      component = component, comparison = "dose_did_active_minus_pre",
      estimate = x[["estimate"]],
      standard_error = x[["standard_error"]],
      conf_low = x[["conf_low"]], conf_high = x[["conf_high"]],
      ratio = exp(x[["estimate"]]),
      ratio_conf_low = exp(x[["conf_low"]]),
      ratio_conf_high = exp(x[["conf_high"]]),
      p_value = x[["p_value"]], q_value = NA_real_,
      n = stage3_dose_release_count_v1(nrow(d)),
      full_fixed_effect_covariance_used = TRUE,
      status = if (
        is.finite(x[["estimate"]]) &&
          is.finite(x[["standard_error"]]) &&
          x[["standard_error"]] > 0
      ) {
        "completed"
      } else {
        "failed_contrast_geometry"
      },
      stringsAsFactors = FALSE
    )
  }))
  diagnostic <- stage3_dose_diagnostic_v1(
    decomposed, decomposed_formula, d, "completed"
  )
  fit_status <- if (!diagnostic$converged[[1L]]) {
    "completed_with_convergence_warning"
  } else if (diagnostic$singular_fit[[1L]]) {
    "completed_with_singular_warning"
  } else if (diagnostic$rank_deficient[[1L]]) {
    "completed_with_rank_deficiency_warning"
  } else {
    "completed"
  }
  diagnostic$status <- fit_status
  effects$status[effects$status == "completed"] <- fit_status
  diagnostic$analysis_taxon_id <- taxon_id
  diagnostic$species <- species
  diagnostic$outcome <- outcome
  diagnostic$model <- variant

  lrt <- data.frame(
    analysis_version = stage3_dose_version_v1(),
    analysis_taxon_id = taxon_id, species = species, outcome = outcome,
    comparison = "total_dose_model_vs_reduced",
    likelihood_ratio = NA_real_, degrees_freedom = NA_real_,
    p_value = NA_real_, q_value = NA_real_,
    n = stage3_dose_release_count_v1(nrow(d)),
    status = if (fit_lrt) "failed_lrt_fit_no_fallback" else "not_requested",
    stringsAsFactors = FALSE
  )
  if (fit_lrt) {
    reduced_formula <- stage3_dose_formula_v1(
      "model_response", "reduced", effort_response
    )
    total_formula <- stage3_dose_formula_v1(
      "model_response", "total", effort_response
    )
    reduced <- try(stage3_dose_fit_engine_v1(
      reduced_formula, d, outcome, maximum_likelihood = TRUE
    ), silent = TRUE)
    total <- try(stage3_dose_fit_engine_v1(
      total_formula, d, outcome, maximum_likelihood = TRUE
    ), silent = TRUE)
    if (!inherits(reduced, "try-error") && !inherits(total, "try-error")) {
      lr <- max(0, 2 * (
        as.numeric(stats::logLik(total)) -
          as.numeric(stats::logLik(reduced))
      ))
      df <- attr(stats::logLik(total), "df") -
        attr(stats::logLik(reduced), "df")
      lrt$likelihood_ratio <- lr
      lrt$degrees_freedom <- df
      lrt$p_value <- stats::pchisq(lr, df = df, lower.tail = FALSE)
      lrt$status <- if (df == 12L) {
        "completed"
      } else {
        "completed_unexpected_degrees_freedom"
      }
      for (part in list(
          list(fit = reduced, formula = reduced_formula, name = "reduced_ml"),
          list(fit = total, formula = total_formula, name = "total_ml")
      )) {
        x <- stage3_dose_diagnostic_v1(
          part$fit, part$formula, d, "completed"
        )
        x$analysis_taxon_id <- taxon_id
        x$species <- species
        x$outcome <- outcome
        x$model <- part$name
        diagnostic <- rbind(diagnostic, x)
      }
    }
  }
  diagnostic <- diagnostic[, c(
    "analysis_taxon_id", "species", "outcome", "model",
    "converged", "singular_fit", "rank_deficient",
    "convergence_message", "maximum_absolute_gradient", "status"
  )]
  result <- list(
    effects = effects, lrt = lrt, diagnostics = diagnostic
  )
  saveRDS(list(cache_signature = cache_signature, result = result),
          checkpoint_path)
  result
}

stage3_dose_load_inputs_v1 <- function(herring_path) {
  files <- stage3_dose_source_files_v1()
  if (!all(file.exists(files))) {
    stop("STAGE3_DOSE_INPUT_GATE: protected source absent", call. = FALSE)
  }
  observed <- vapply(files, .post_stage4a_sha256_v1, character(1L))
  if (!identical(
      observed[names(stage3_dose_expected_hashes_v1())],
      stage3_dose_expected_hashes_v1()
    )) {
    stop("STAGE3_DOSE_INPUT_HASH_GATE: protected source changed",
         call. = FALSE)
  }
  events_all <- .stage4a_prepare_events(
    .stage4a_read_gz(files[["event_metadata"]])
  )
  selected <- events_all$region == "SoG" &
    events_all$checklist_year >= 2005L &
    events_all$checklist_year <= 2025L
  events <- events_all[selected, , drop = FALSE]
  rm(events_all)
  if (
    nrow(events) != 217200L ||
      anyDuplicated(events$analysis_event_token) ||
      any(as.integer(events$checklist_year) > 2025L)
  ) {
    stop("STAGE3_DOSE_POPULATION_GATE: changed", call. = FALSE)
  }
  stage4a_validate_folds(events)
  detectability <- staged_refit_s2_read_detectability_v1(
    files[["detectability"]]
  )
  joined <- staged_refit_s2_attach_detectability_v1(
    events, detectability
  )
  if (nrow(joined$events) != 217200L) {
    stop("STAGE3_DOSE_DETECTABILITY_GATE: complete population changed",
         call. = FALSE)
  }
  model_tokens <- as.character(joined$events$analysis_event_token)

  index <- stage3_dose_read_index_v1(herring_path)
  anchor_lookup <- staged_refit_build_anchor_lookup_v1(herring_path)
  archived_links <- .stage4a_read_gz(files[["source_links_archived"]])
  widened_links <- .stage4a_read_gz(files[["source_links_placebo"]])
  anchored_links <- staged_refit_reanchor_links_v1(
    archived_links, anchor_lookup
  )
  anchored_links <- stage3_dose_attach_event_scores_v1(
    anchored_links, index
  )
  real <- stage3_dose_widen_by_link_v1(
    events, anchored_links, index,
    real_grand_mean = NULL,
    links_are_reanchored = TRUE
  )
  real_detectability <- staged_refit_s2_attach_detectability_v1(
    real$events, detectability
  )
  real$events <- real_detectability$events
  if (!identical(
      as.character(real$events$analysis_event_token), model_tokens
  )) {
    stop("STAGE3_DOSE_REAL_JOIN_GATE: event order changed", call. = FALSE)
  }

  states_all <- .stage4a_read_gz(files[["reported_states"]])
  masks_all <- .stage4a_read_gz(files[["ambiguity_masks"]])
  if (nrow(states_all) != 1169612L || nrow(masks_all) != 5834L) {
    stop("STAGE3_DOSE_RESPONSE_SOURCE_GATE: protected cardinality changed",
         call. = FALSE)
  }
  states <- states_all[
    states_all$analysis_event_token %in% model_tokens, , drop = FALSE
  ]
  masks <- masks_all[
    masks_all$analysis_event_token %in% model_tokens, , drop = FALSE
  ]
  rm(states_all, masks_all)
  if (
    any(as.integer(real$events$checklist_year) > 2025L) ||
      any(!states$analysis_event_token %in% model_tokens) ||
      any(!masks$analysis_event_token %in% model_tokens)
  ) {
    stop("STAGE3_DOSE_LOCKED_YEAR_GATE: response population changed",
         call. = FALSE)
  }

  support_registry <- utils::read.csv(
    "outputs/stage2_design_lock/species_support_summary.csv",
    stringsAsFactors = FALSE
  )
  species_registry <- utils::read.csv(
    "metadata/canonical_species_registry.csv",
    stringsAsFactors = FALSE
  )
  taxa <- support_registry$analysis_taxon_id[
    support_registry$named_species_recommendation == "named_species_core"
  ]
  if (
    length(taxa) != 49L || anyDuplicated(taxa) ||
      anyDuplicated(species_registry$analysis_taxon_id)
  ) {
    stop("STAGE3_DOSE_FAMILY_GATE: fixed family changed", call. = FALSE)
  }
  species_names <- species_registry$common_name[
    match(taxa, species_registry$analysis_taxon_id)
  ]
  excluded <- c(
    "American Robin", "Chestnut-backed Chickadee",
    "Gadwall", "Northern Shoveler"
  )
  if (any(species_names %in% excluded)) {
    stop("STAGE3_DOSE_EXCLUDED_SPECIES_GATE: excluded comparator entered",
         call. = FALSE)
  }
  list(
    events = real$events,
    states = states,
    masks = masks,
    taxa = taxa,
    species_registry = species_registry,
    index = index,
    index_audit = rbind(
      stage3_dose_index_audit_v1(index),
      stage3_dose_link_audit_v1(anchored_links)
    ),
    real_grand_mean = real$grand_mean_log_index,
    anchored_links = anchored_links,
    widened_links = widened_links,
    anchor_lookup = anchor_lookup,
    base_events = events,
    detectability = detectability,
    source_hashes = c(observed, herring = index$source_hash)
  )
}

stage3_dose_family_results_v1 <- function(results) {
  list(
    effects = do.call(rbind, unlist(lapply(
      results, function(x) lapply(x, `[[`, "effects")
    ), recursive = FALSE)),
    lrt = do.call(rbind, unlist(lapply(
      results, function(x) lapply(x, `[[`, "lrt")
    ), recursive = FALSE)),
    diagnostics = do.call(rbind, unlist(lapply(
      results, function(x) lapply(x, `[[`, "diagnostics")
    ), recursive = FALSE))
  )
}

stage3_dose_fit_family_v1 <- function(
    taxa, events, states, masks, species_registry,
    checkpoint_dir, run_signature, fit_lrt = TRUE,
    variant = "decomposed", workers = 1L) {
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  if (!length(taxa)) {
    return(list(effects = data.frame(), lrt = data.frame(),
                diagnostics = data.frame()))
  }
  fit_one <- function(taxon_id) {
    species <- species_registry$common_name[
      match(taxon_id, species_registry$analysis_taxon_id)
    ]
    if (length(species) != 1L || is.na(species) || !nzchar(species)) {
      stop("STAGE3_DOSE_SPECIES_JOIN_GATE: unresolved taxon",
           call. = FALSE)
    }
    dat <- stage4a_materialize_taxon(
      events, states, masks, taxon_id
    )
    outcomes <- c(
      "checklist_reporting", "conditional_positive_numeric_count"
    )
    out <- lapply(outcomes, function(outcome) {
      stage3_dose_fit_taxon_v1(
        dat, taxon_id, species, outcome,
        file.path(
          checkpoint_dir,
          paste(taxon_id, outcome, variant, "rds", sep = "_")
        ),
        paste(
          run_signature, taxon_id, outcome, variant, fit_lrt, sep = "|"
        ),
        fit_lrt = fit_lrt, variant = variant
      )
    })
    names(out) <- outcomes
    out
  }
  workers <- min(as.integer(workers), length(taxa))
  if (workers <= 1L) {
    return(stage3_dose_family_results_v1(lapply(taxa, fit_one)))
  }
  cluster <- parallel::makePSOCKcluster(workers)
  on.exit(parallel::stopCluster(cluster), add = TRUE)
  parallel::clusterEvalQ(cluster, {
    Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
    source(file.path("R", "stage4a_core.R"), local = FALSE)
    source(file.path("R", "stage4a_production.R"), local = FALSE)
    source(
      file.path("R", "post_stage4a_sog_event_study_v1.R"),
      local = FALSE
    )
    source(
      file.path("R", "post_stage4a_distance_band_sensitivity_v2.R"),
      local = FALSE
    )
    source(
      file.path("R", "post_stage4a_staged_refit_v1.R"),
      local = FALSE
    )
    source(
      file.path("R", "post_stage4a_staged_refit_amendment_v1.R"),
      local = FALSE
    )
    source(
      file.path("R", "post_stage4a_staged_refit_stage2_v1.R"),
      local = FALSE
    )
    source(
      file.path("R", "post_stage4a_stage3_dose_v1.R"),
      local = FALSE
    )
    NULL
  })
  parallel::clusterExport(
    cluster,
    c(
      "events", "states", "masks", "species_registry",
      "checkpoint_dir", "run_signature", "fit_lrt", "variant"
    ),
    envir = environment()
  )
  stage3_dose_family_results_v1(parallel::parLapply(
    cluster, taxa, function(taxon_id) {
      species <- species_registry$common_name[
        match(taxon_id, species_registry$analysis_taxon_id)
      ]
      dat <- stage4a_materialize_taxon(
        events, states, masks, taxon_id
      )
      outcomes <- c(
        "checklist_reporting", "conditional_positive_numeric_count"
      )
      out <- lapply(outcomes, function(outcome) {
        stage3_dose_fit_taxon_v1(
          dat, taxon_id, species, outcome,
          file.path(
            checkpoint_dir,
            paste(taxon_id, outcome, variant, "rds", sep = "_")
          ),
          paste(
            run_signature, taxon_id, outcome, variant, fit_lrt, sep = "|"
          ),
          fit_lrt = fit_lrt, variant = variant
        )
      })
      names(out) <- outcomes
      out
    }
  ))
}

stage3_dose_adjust_family_v1 <- function(family) {
  within <- family$effects$component == "within_location"
  for (outcome in unique(family$effects$outcome)) {
    family_rows <- which(within & family$effects$outcome == outcome)
    if (length(family_rows) != 49L) {
      stop("STAGE3_DOSE_BH_GATE: primary family is not fixed at 49",
           call. = FALSE)
    }
    p <- family$effects$p_value[family_rows]
    finite <- is.finite(p)
    adjusted <- stats::p.adjust(ifelse(finite, p, 1), method = "BH")
    adjusted[!finite] <- NA_real_
    family$effects$q_value[family_rows] <- adjusted
  }
  for (outcome in unique(family$lrt$outcome)) {
    family_rows <- which(family$lrt$outcome == outcome)
    if (length(family_rows) != 49L) {
      stop("STAGE3_DOSE_BH_GATE: LRT family is not fixed at 49",
           call. = FALSE)
    }
    p <- family$lrt$p_value[family_rows]
    finite <- is.finite(p)
    adjusted <- stats::p.adjust(ifelse(finite, p, 1), method = "BH")
    adjusted[!finite] <- NA_real_
    family$lrt$q_value[family_rows] <- adjusted
  }
  family
}

stage3_dose_checkpoint_marker_v1 <- function(
    path, checkpoint, execution_code_commit, elapsed, extra = list()) {
  record <- c(list(
    execution_version = stage3_dose_version_v1(),
    checkpoint = checkpoint,
    completed_at_utc = format(
      Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
    ),
    elapsed_seconds = as.numeric(elapsed),
    execution_code_commit = execution_code_commit,
    authorization_verified_in_process = TRUE,
    maximum_response_year = 2025L,
    records_2026_plus_read = 0L
  ), extra)
  writeLines(
    yaml::as.yaml(record, precision = 16),
    path,
    useBytes = TRUE
  )
  invisible(record)
}

stage3_dose_run_signature_v1 <- function(inputs, execution_code_commit) {
  paste(
    stage3_dose_version_v1(), execution_code_commit,
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_stage3_dose_spec_v1.yml"
    ),
    .post_stage4a_sha256_v1("R/post_stage4a_stage3_dose_v1.R"),
    inputs$source_hashes,
    format(inputs$real_grand_mean, digits = 17),
    sep = "|", collapse = "|"
  )
}

run_post_stage4a_stage3_dose_case_v1 <- function(
    execution_code_commit, herring_path) {
  started <- Sys.time()
  stage3_dose_authorization_gate_v1()
  stage3_dose_spec_gate_v1()
  stage3_dose_parent_gate_v1()
  inputs <- stage3_dose_load_inputs_v1(herring_path)
  case_names <- c("Glaucous-winged Gull", "Bald Eagle")
  case_taxa <- inputs$species_registry$analysis_taxon_id[
    match(case_names, inputs$species_registry$common_name)
  ]
  if (anyNA(case_taxa) || !all(case_taxa %in% inputs$taxa)) {
    stop("STAGE3_DOSE_CASE_GATE: case species unresolved", call. = FALSE)
  }
  root <- file.path(
    "data", "derived", "post_stage4a_stage3_dose_v1"
  )
  checkpoint_dir <- file.path(root, "checkpoints", "real_family")
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  signature <- stage3_dose_run_signature_v1(
    inputs, execution_code_commit
  )
  results <- stage3_dose_fit_family_v1(
    case_taxa, inputs$events, inputs$states, inputs$masks,
    inputs$species_registry, checkpoint_dir, signature,
    fit_lrt = TRUE, variant = "decomposed",
    workers = post_stage4a_worker_count_v1(length(case_taxa))
  )
  saveRDS(
    list(
      cache_signature = signature, results = results,
      case_taxa = case_taxa,
      real_grand_mean = inputs$real_grand_mean,
      index_audit = inputs$index_audit
    ),
    file.path(root, "checkpoint_1_case_results.rds")
  )
  stage3_dose_checkpoint_marker_v1(
    file.path(root, "checkpoint_1_complete.yml"),
    "checkpoint_1_case_species",
    execution_code_commit, Sys.time() - started,
    list(
      case_species = case_names,
      model_components = 4L,
      dose_grand_mean_log_index = inputs$real_grand_mean,
      failed_effect_rows = sum(!is.finite(results$effects$estimate))
    )
  )
  invisible(results)
}

run_post_stage4a_stage3_dose_family_v1 <- function(
    execution_code_commit, herring_path) {
  started <- Sys.time()
  stage3_dose_authorization_gate_v1()
  stage3_dose_spec_gate_v1()
  stage3_dose_parent_gate_v1()
  root <- file.path(
    "data", "derived", "post_stage4a_stage3_dose_v1"
  )
  marker <- file.path(root, "checkpoint_1_complete.yml")
  case_path <- file.path(root, "checkpoint_1_case_results.rds")
  if (!file.exists(marker) || !file.exists(case_path)) {
    stop("STAGE3_DOSE_STAGING_GATE: checkpoint 1 incomplete",
         call. = FALSE)
  }
  case <- readRDS(case_path)
  inputs <- stage3_dose_load_inputs_v1(herring_path)
  signature <- stage3_dose_run_signature_v1(
    inputs, execution_code_commit
  )
  if (!identical(case$cache_signature, signature)) {
    stop("STAGE3_DOSE_CASE_CACHE_GATE: code or inputs changed",
         call. = FALSE)
  }
  remaining <- setdiff(inputs$taxa, case$case_taxa)
  remaining_results <- stage3_dose_fit_family_v1(
    remaining, inputs$events, inputs$states, inputs$masks,
    inputs$species_registry,
    file.path(root, "checkpoints", "real_family"),
    signature, fit_lrt = TRUE, variant = "decomposed",
    workers = post_stage4a_worker_count_v1(length(remaining))
  )
  family <- list(
    effects = rbind(case$results$effects, remaining_results$effects),
    lrt = rbind(case$results$lrt, remaining_results$lrt),
    diagnostics = rbind(
      case$results$diagnostics, remaining_results$diagnostics
    )
  )
  family <- stage3_dose_adjust_family_v1(family)
  if (
    nrow(family$effects) != 196L ||
      nrow(family$lrt) != 98L ||
      length(unique(family$effects$analysis_taxon_id)) != 49L
  ) {
    stop("STAGE3_DOSE_FAMILY_RESULT_GATE: fixed family incomplete",
         call. = FALSE)
  }
  saveRDS(
    list(cache_signature = signature, results = family),
    file.path(root, "checkpoint_2_family_results.rds")
  )
  primary <- family$effects[
    family$effects$component == "within_location", , drop = FALSE
  ]
  tallies <- aggregate(
    cbind(
      positive_bh = primary$q_value < 0.05 &
        primary$estimate > 0,
      negative_bh = primary$q_value < 0.05 &
        primary$estimate < 0
    ),
    by = primary["outcome"],
    FUN = sum, na.rm = TRUE
  )
  stage3_dose_checkpoint_marker_v1(
    file.path(root, "checkpoint_2_complete.yml"),
    "checkpoint_2_fixed_49_family",
    execution_code_commit, Sys.time() - started,
    list(
      fixed_family_species = 49L,
      primary_effect_rows = 98L,
      lrt_rows = 98L,
      positive_bh_tallies = split(tallies, seq_len(nrow(tallies))),
      failed_primary_rows = sum(
        family$effects$component == "within_location" &
          !is.finite(family$effects$estimate)
      )
    )
  )
  invisible(family)
}

stage3_dose_placebo_events_v1 <- function(
    inputs, offset_days) {
  shifted <- staged_refit_reanchor_links_v1(
    inputs$widened_links, inputs$anchor_lookup
  )
  shifted$event_day <- shifted$event_day - as.integer(offset_days)
  shifted <- stage3_dose_attach_event_scores_v1(
    shifted, inputs$index
  )
  widened <- stage3_dose_widen_by_link_v1(
    inputs$base_events, shifted, inputs$index,
    real_grand_mean = inputs$real_grand_mean,
    links_are_reanchored = TRUE
  )
  joined <- staged_refit_s2_attach_detectability_v1(
    widened$events, inputs$detectability
  )
  if (nrow(joined$events) != 217200L) {
    stop("STAGE3_DOSE_PLACEBO_JOIN_GATE: population changed",
         call. = FALSE)
  }
  joined$events
}

stage3_dose_effort_outcomes_v1 <- function(
    events, checkpoint_dir, signature) {
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  outcomes <- c("log_duration", "log_effort_distance", "observer_count")
  results <- lapply(outcomes, function(outcome) {
    stage3_dose_fit_taxon_v1(
      events, paste0("effort_", outcome),
      switch(
        outcome,
        log_duration = "Log duration minutes",
        log_effort_distance = "Log distance travelled plus one",
        observer_count = "Number of observers"
      ),
      outcome,
      file.path(checkpoint_dir, paste0(outcome, ".rds")),
      paste(signature, "effort", outcome, sep = "|"),
      fit_lrt = FALSE, variant = "decomposed",
      effort_response = outcome
    )
  })
  effects <- do.call(rbind, lapply(results, `[[`, "effects"))
  effects <- effects[
    effects$component == "within_location", , drop = FALSE
  ]
  finite <- is.finite(effects$p_value)
  effects$q_value <- stats::p.adjust(
    ifelse(finite, effects$p_value, 1), method = "BH"
  )
  effects$q_value[!finite] <- NA_real_
  effects$effort_response <- outcomes
  effects$effect_scale <- c(
    "log_ratio", "log_ratio", "additive_observers"
  )
  observer <- effects$effort_response == "observer_count"
  effects$ratio[observer] <- NA_real_
  effects$ratio_conf_low[observer] <- NA_real_
  effects$ratio_conf_high[observer] <- NA_real_
  effects
}

stage3_dose_guild_meta_v1 <- function(effects, species_registry) {
  primary <- effects[
    effects$component == "within_location" &
      is.finite(effects$estimate) &
      is.finite(effects$standard_error) &
      effects$standard_error > 0, , drop = FALSE
  ]
  index <- match(
    primary$analysis_taxon_id, species_registry$analysis_taxon_id
  )
  if (anyNA(index) ||
      any(primary$species != species_registry$common_name[index])) {
    stop("STAGE3_DOSE_GUILD_JOIN_GATE: many-to-one join failed",
         call. = FALSE)
  }
  primary$guild <- species_registry$guild_ids[index]
  output <- list()
  j <- 0L
  for (outcome in unique(primary$outcome)) {
    x <- primary[primary$outcome == outcome, , drop = FALSE]
    guild_factor <- factor(x$guild)
    if (length(levels(guild_factor)) != 7L) {
      stop("STAGE3_DOSE_GUILD_GATE: expected seven guilds",
           call. = FALSE)
    }
    design <- stats::model.matrix(~ 0 + guild_factor)
    precision <- 1 / (x$standard_error^2)
    information <- crossprod(design, precision * design)
    if (qr(information)$rank != ncol(information)) {
      stop("STAGE3_DOSE_GUILD_GEOMETRY_GATE: rank deficient",
           call. = FALSE)
    }
    coefficient <- solve(
      information, crossprod(design, precision * x$estimate)
    )
    covariance <- solve(information)
    standard_error <- sqrt(diag(covariance))
    fitted <- drop(design %*% coefficient)
    grand_mean <- sum(precision * x$estimate) / sum(precision)
    q_total <- sum(precision * (x$estimate - grand_mean)^2)
    q_residual <- sum(precision * (x$estimate - fitted)^2)
    q_between <- max(0, q_total - q_residual)
    guilds <- levels(guild_factor)
    df_between <- length(guilds) - 1L
    df_residual <- nrow(x) - length(guilds)
    z <- 1.959963984540054
    j <- j + 1L
    output[[j]] <- data.frame(
      analysis_version = stage3_dose_version_v1(),
      outcome = outcome, guild = guilds,
      species_count = as.integer(table(guild_factor)[guilds]),
      estimate = drop(coefficient),
      standard_error = standard_error,
      conf_low = drop(coefficient) - z * standard_error,
      conf_high = drop(coefficient) + z * standard_error,
      ratio = exp(drop(coefficient)),
      ratio_conf_low = exp(drop(coefficient) - z * standard_error),
      ratio_conf_high = exp(drop(coefficient) + z * standard_error),
      q_between = q_between, df_between = df_between,
      p_guild_differences = stats::pchisq(
        q_between, df_between, lower.tail = FALSE
      ),
      q_residual = q_residual, df_residual = df_residual,
      p_residual_heterogeneity = if (df_residual > 0L) {
        stats::pchisq(q_residual, df_residual, lower.tail = FALSE)
      } else {
        NA_real_
      },
      residual_i2_percent = if (q_residual > 0) {
        100 * max(0, (q_residual - df_residual) / q_residual)
      } else {
        0
      },
      variance_method =
        "inverse variance from exact full fixed-effect covariance",
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, output)
}

stage3_dose_assign_terciles_v1 <- function(index) {
  event <- data.table::as.data.table(index$events)
  positive <- event[score_status == "positive_scored_event"]
  positive[, within_year_rank__ := rank(
    relative_spawn_index_t, ties.method = "average"
  ), by = event_year]
  positive[, dose_tercile := pmin(
    3L, pmax(1L, as.integer(ceiling(
      3 * within_year_rank__ / .N
    )))
  ), by = event_year]
  as.data.frame(positive[, .(
    dose_event_token__, event_year, dose_tercile
  )])
}

stage3_dose_tercile_results_v1 <- function(
    inputs, checkpoint_dir, signature) {
  assignment <- stage3_dose_assign_terciles_v1(inputs$index)
  links <- inputs$anchored_links
  idx <- match(links$dose_event_token__, assignment$dose_event_token__)
  links$dose_tercile__ <- assignment$dose_tercile[idx]
  case_names <- c("Glaucous-winged Gull", "Bald Eagle")
  rows <- list()
  k <- 0L
  for (tercile in 1:3) {
    selected <- links[
      !is.na(links$dose_tercile__) &
        links$dose_tercile__ == tercile, , drop = FALSE
    ]
    joint <- staged_refit_amendment_events_from_links_v1(
      inputs$base_events, selected
    )
    joined <- staged_refit_s2_attach_detectability_v1(
      joint$events, inputs$detectability
    )
    for (species in case_names) {
      taxon_id <- inputs$species_registry$analysis_taxon_id[
        match(species, inputs$species_registry$common_name)
      ]
      dat <- stage4a_materialize_taxon(
        joined$events, inputs$states, inputs$masks, taxon_id
      )
      for (outcome in c(
          "checklist_reporting", "conditional_positive_numeric_count"
      )) {
        result <- staged_refit_s2_fit_component_v1(
          dat, taxon_id, species, "case_species", outcome,
          file.path(
            checkpoint_dir,
            paste(taxon_id, outcome, paste0("tercile", tercile),
                  "rds", sep = "_")
          ),
          paste(signature, "tercile", tercile, taxon_id, outcome,
                sep = "|")
        )
        effect <- result$contrasts[
          result$contrasts$comparison == "active_minus_pre14",
          , drop = FALSE
        ]
        k <- k + 1L
        rows[[k]] <- data.frame(
          analysis_version = stage3_dose_version_v1(),
          analysis_taxon_id = taxon_id, species = species,
          outcome = outcome, within_year_tercile = tercile,
          estimate = effect$estimate,
          standard_error = effect$standard_error,
          conf_low = effect$conf_low, conf_high = effect$conf_high,
          ratio = effect$ratio,
          ratio_conf_low = effect$ratio_conf_low,
          ratio_conf_high = effect$ratio_conf_high,
          p_value_descriptive_not_family_adjusted = effect$p_value,
          n = effect$n, status = effect$status,
          interpretation =
            "ordered visual diagnostic; not a separate test family",
          stringsAsFactors = FALSE
        )
      }
    }
  }
  out <- do.call(rbind, rows)
  if (nrow(out) != 12L) {
    stop("STAGE3_DOSE_TERCILE_GATE: expected 12 rows", call. = FALSE)
  }
  out
}

stage3_dose_make_tercile_figure_v1 <- function(tab, figure_root) {
  dir.create(figure_root, recursive = TRUE, showWarnings = FALSE)
  draw <- function() {
    old <- graphics::par(
      mfrow = c(2, 2), mar = c(4.2, 4.4, 2.5, 0.8),
      oma = c(0, 0, 1.2, 0)
    )
    on.exit(graphics::par(old), add = TRUE)
    species_order <- c("Glaucous-winged Gull", "Bald Eagle")
    outcome_order <- c(
      "checklist_reporting", "conditional_positive_numeric_count"
    )
    for (species in species_order) {
      for (outcome in outcome_order) {
        x <- tab[
          tab$species == species & tab$outcome == outcome,
          , drop = FALSE
        ]
        x <- x[order(x$within_year_tercile), , drop = FALSE]
        limits <- range(
          c(x$ratio_conf_low, x$ratio_conf_high, 1),
          finite = TRUE
        )
        pad <- 0.08 * diff(limits)
        if (!is.finite(pad) || pad == 0) pad <- 0.1
        graphics::plot(
          x$within_year_tercile, x$ratio,
          type = "b", pch = 19, lwd = 1.6,
          xlim = c(0.75, 3.25),
          ylim = limits + c(-pad, pad),
          xaxt = "n", xlab = "Within-year spawn-index tercile",
          ylab = "Active-minus-pre ratio",
          main = paste(
            species,
            if (outcome == "checklist_reporting") {
              "reporting"
            } else {
              "positive count"
            },
            sep = " — "
          )
        )
        graphics::axis(1, at = 1:3, labels = c("Low", "Middle", "High"))
        graphics::abline(h = 1, col = "grey55", lty = 2)
        graphics::arrows(
          x$within_year_tercile, x$ratio_conf_low,
          x$within_year_tercile, x$ratio_conf_high,
          angle = 90, code = 3, length = 0.05
        )
      }
    }
    graphics::mtext(
      "Stage 2 active-minus-pre estimates by recorded spawn-index tercile",
      outer = TRUE, cex = 1.05
    )
  }
  pdf_path <- file.path(figure_root, "dose_terciles_case_species.pdf")
  grDevices::pdf(
    pdf_path, width = 10, height = 8,
    family = "Helvetica", useDingbats = FALSE
  )
  draw()
  grDevices::dev.off()
  png_path <- file.path(
    figure_root, "dose_terciles_case_species_600dpi.png"
  )
  grDevices::png(
    png_path, width = 6000, height = 4800, res = 600,
    type = if (capabilities("cairo")) "cairo-png" else "windows"
  )
  draw()
  grDevices::dev.off()
  invisible(c(pdf = pdf_path, png = png_path))
}

stage3_dose_sensitivity_table_v1 <- function(
    sensitivity, real, label, extra = list()) {
  x <- sensitivity$effects[
    sensitivity$effects$component == "within_location", , drop = FALSE
  ]
  x <- stage3_dose_adjust_family_v1(list(
    effects = sensitivity$effects,
    lrt = sensitivity$lrt
  ))$effects
  x <- x[x$component == "within_location", , drop = FALSE]
  primary <- real$effects[
    real$effects$component == "within_location", , drop = FALSE
  ]
  key <- paste(x$analysis_taxon_id, x$outcome, sep = "\r")
  real_key <- paste(
    primary$analysis_taxon_id, primary$outcome, sep = "\r"
  )
  index <- match(key, real_key)
  if (anyNA(index) || anyDuplicated(key) || anyDuplicated(real_key)) {
    stop("STAGE3_DOSE_SENSITIVITY_JOIN_GATE: one-to-one failed",
         call. = FALSE)
  }
  data.frame(
    analysis_version = stage3_dose_version_v1(),
    sensitivity = label,
    analysis_taxon_id = x$analysis_taxon_id,
    species = x$species, outcome = x$outcome,
    comparison = x$comparison,
    estimate = x$estimate, standard_error = x$standard_error,
    conf_low = x$conf_low, conf_high = x$conf_high,
    ratio = x$ratio, ratio_conf_low = x$ratio_conf_low,
    ratio_conf_high = x$ratio_conf_high,
    p_value = x$p_value, q_value = x$q_value,
    primary_estimate = primary$estimate[index],
    primary_standard_error = primary$standard_error[index],
    primary_q_value = primary$q_value[index],
    sign_preserved = sign(x$estimate) == sign(primary$estimate[index]),
    status = x$status,
    stringsAsFactors = FALSE
  )
}

stage3_dose_placebo_tallies_v1 <- function(placebo_results) {
  rows <- list()
  k <- 0L
  for (offset in names(placebo_results)) {
    family <- stage3_dose_adjust_family_v1(placebo_results[[offset]])
    primary <- family$effects[
      family$effects$component == "within_location", , drop = FALSE
    ]
    for (outcome in c(
        "checklist_reporting", "conditional_positive_numeric_count"
    )) {
      x <- primary[primary$outcome == outcome, , drop = FALSE]
      k <- k + 1L
      rows[[k]] <- data.frame(
        analysis_version = stage3_dose_version_v1(),
        offset_days = as.integer(offset),
        outcome = outcome,
        positive_bh_q_lt_0_05 = sum(
          x$q_value < 0.05 & x$estimate > 0, na.rm = TRUE
        ),
        negative_bh_q_lt_0_05 = sum(
          x$q_value < 0.05 & x$estimate < 0, na.rm = TRUE
        ),
        estimable_species = sum(is.finite(x$estimate)),
        fixed_family_size = 49L,
        status = if (all(!is.finite(x$estimate))) {
          "all_fits_failed"
        } else {
          "completed_with_failures_retained"
        },
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

stage3_dose_falsification_verdict_v1 <- function(
    real, method, extent, effort) {
  primary <- real$effects[
    real$effects$component == "within_location", , drop = FALSE
  ]
  between <- real$effects[
    real$effects$component == "between_location", , drop = FALSE
  ]
  key <- paste(primary$analysis_taxon_id, primary$outcome, sep = "\r")
  method_index <- match(
    key, paste(method$analysis_taxon_id, method$outcome, sep = "\r")
  )
  extent_index <- match(
    key, paste(extent$analysis_taxon_id, extent$outcome, sep = "\r")
  )
  between_index <- match(
    key, paste(between$analysis_taxon_id, between$outcome, sep = "\r")
  )
  focus <- is.finite(primary$q_value) & primary$q_value < 0.05
  reversal <- focus & is.finite(method$estimate[method_index]) &
    sign(primary$estimate) != sign(method$estimate[method_index])
  effort_response <- any(
    is.finite(effort$q_value) & effort$q_value < 0.05
  )
  if (effort_response || any(reversal, na.rm = TRUE)) {
    return(list(
      verdict = "uninterpretable",
      reason = if (effort_response) {
        paste(
          "At least one observer-effort outcome has a BH-adjusted dose",
          "response, satisfying the prespecified uninterpretable rule."
        )
      } else {
        paste(
          "At least one primary BH signal reverses between the full and",
          "surface-only fits, satisfying the prespecified uninterpretable rule."
        )
      }
    ))
  }
  lrt_supported <- vapply(
    c("checklist_reporting", "conditional_positive_numeric_count"),
    function(outcome) any(
      real$lrt$outcome == outcome &
        is.finite(real$lrt$q_value) & real$lrt$q_value < 0.05
    ),
    logical(1L)
  )
  within_positive <- vapply(
    c("checklist_reporting", "conditional_positive_numeric_count"),
    function(outcome) sum(
      primary$outcome == outcome &
        is.finite(primary$q_value) & primary$q_value < 0.05 &
        primary$estimate > 0
    ),
    integer(1L)
  )
  surface_holds <- !any(
    focus & (
      !is.finite(method$estimate[method_index]) |
        sign(primary$estimate) != sign(method$estimate[method_index])
    )
  )
  extent_disappears <- any(
    focus & (
      !is.finite(extent$estimate[extent_index]) |
        sign(primary$estimate) != sign(extent$estimate[extent_index]) |
        !is.finite(extent$q_value[extent_index]) |
        extent$q_value[extent_index] >= 0.05
    )
  )
  between_only <- !any(focus) && any(
    is.finite(between$q_value[between_index]) &
      between$q_value[between_index] < 0.05
  )
  if (
    any(!lrt_supported) || all(within_positive == 0L) ||
      between_only || extent_disappears
  ) {
    return(list(
      verdict = "not supported",
      reason = paste(
        "One or more prespecified support conditions failed: dose-model LRT",
        "support in both outcomes, within-location BH signal, within rather",
        "than between-location carriage, and persistence with log length."
      )
    ))
  }
  if (
    all(lrt_supported) && sum(within_positive) >= 2L &&
      surface_holds && !effort_response
  ) {
    return(list(
      verdict = "supported",
      reason = paste(
        "Within-location positive BH signals and dose-model LRT support occur",
        "across the outcomes, preserve direction under the surface-only",
        "restriction, and have no effort-outcome dose response."
      )
    ))
  }
  list(
    verdict = "not supported",
    reason = "The full prespecified support pattern was not achieved."
  )
}

stage3_dose_format_number_v1 <- function(x, digits = 3L) {
  ifelse(
    is.finite(x),
    formatC(x, digits = digits, format = "fg", flag = "#"),
    "not estimable"
  )
}

stage3_dose_report_v1 <- function(
    output_root, index_audit, real, method, extent, effort,
    placebo, guild, tercile, grand_mean) {
  verdict <- stage3_dose_falsification_verdict_v1(
    real, method, extent, effort
  )
  primary <- real$effects[
    real$effects$component == "within_location", , drop = FALSE
  ]
  tally <- function(outcome, direction = 1) {
    x <- primary[primary$outcome == outcome, , drop = FALSE]
    sum(
      is.finite(x$q_value) & x$q_value < 0.05 &
        sign(x$estimate) == direction,
      na.rm = TRUE
    )
  }
  lrt_tally <- function(outcome) {
    sum(
      real$lrt$outcome == outcome &
        is.finite(real$lrt$q_value) & real$lrt$q_value < 0.05
    )
  }
  positive_events <- index_audit$count[
    index_audit$metric == "positive_scored_events"
  ]
  missing_events <- index_audit$count[
    index_audit$metric == "events_no_recorded_component"
  ]
  multirow <- index_audit$count[
    index_audit$metric == "multirow_events"
  ]
  distribution <- index_audit[
    index_audit$audit_section == "event_index_distribution", ,
    drop = FALSE
  ]
  value <- function(metric) {
    distribution$value[match(metric, distribution$metric)]
  }
  effort_lines <- vapply(seq_len(nrow(effort)), function(i) {
    paste0(
      "- ", effort$species[[i]], ": estimate ",
      stage3_dose_format_number_v1(effort$estimate[[i]]),
      if (effort$effect_scale[[i]] == "additive_observers") {
        " observers"
      } else {
        paste0(
          ", ratio ",
          stage3_dose_format_number_v1(effort$ratio[[i]])
        )
      },
      ", BH q = ", stage3_dose_format_number_v1(effort$q_value[[i]]), "."
    )
  }, character(1L))
  placebo_lines <- vapply(seq_len(nrow(placebo)), function(i) {
    paste0(
      "- Offset ", sprintf("%+d", placebo$offset_days[[i]]),
      " days, ", placebo$outcome[[i]], ": ",
      placebo$positive_bh_q_lt_0_05[[i]],
      " positive and ", placebo$negative_bh_q_lt_0_05[[i]],
      " negative BH-surviving dose contrasts (",
      placebo$estimable_species[[i]], "/49 estimable)."
    )
  }, character(1L))
  diagnostic <- real$diagnostics
  failed <- sum(grepl("^failed", diagnostic$status))
  warnings <- sum(
    diagnostic$singular_fit %in% TRUE |
      diagnostic$rank_deficient %in% TRUE |
      !diagnostic$converged %in% TRUE,
    na.rm = TRUE
  )
  lines <- c(
    "# Stage 3 dose analysis",
    "",
    paste0(
      "The prespecified Stage 3 dose pattern is **",
      verdict$verdict, "**."
    ),
    verdict$reason,
    paste0(
      "This is a post-result estimand refinement and does not establish that ",
      "recorded spawn index is absolute biomass or that associations are causal."
    ),
    "",
    "## Prespecified falsification criteria",
    "",
    paste0(
      "- **Supported:** The within-location dose contrast is positive and ",
      "survives BH for a meaningful number of species, the likelihood-ratio ",
      "test is significant, the signal holds under the surface-only ",
      "restriction, and the effort outcomes show no dose response."
    ),
    paste0(
      "- **Not supported:** The likelihood-ratio test is not significant, or ",
      "the effect is carried entirely by the between-location term, or it ",
      "disappears when log(length_m) is held constant."
    ),
    paste0(
      "- **Uninterpretable:** Checklist duration shows a dose response, or ",
      "the effect reverses between the full and surface-only fits."
    ),
    "",
    "These criteria were committed before any Stage 3 response fit.",
    "",
    "## Index aggregation and dose scale",
    "",
    paste0(
      "The frozen source yielded ", positive_events,
      " positive scored events; ", missing_events,
      " events had no recorded component and were dropped rather than treated ",
      "as zero spawn. The specified event key produced ", multirow,
      " multirow events."
    ),
    paste0(
      "Among positive events, relative spawn index had median ",
      stage3_dose_format_number_v1(value("median")),
      " (IQR ", stage3_dose_format_number_v1(value("q25")), "–",
      stage3_dose_format_number_v1(value("q75")), "), range ",
      stage3_dose_format_number_v1(value("minimum")), "–",
      stage3_dose_format_number_v1(value("maximum")), "."
    ),
    paste0(
      "The frozen link-weighted grand mean of log index was ",
      stage3_dose_format_number_v1(grand_mean, 6L),
      ". Missing row components contributed zero only to the derived row sum; ",
      "events with no recorded component were not assigned zero spawn."
    ),
    "",
    "## Primary within-location dose contrast and likelihood-ratio tests",
    "",
    paste0(
      "BH-surviving positive within-location contrasts: ",
      tally("conditional_positive_numeric_count"), "/49 for conditional ",
      "positive numeric count and ", tally("checklist_reporting"),
      "/49 for checklist reporting. Negative tallies were ",
      tally("conditional_positive_numeric_count", -1), " and ",
      tally("checklist_reporting", -1), ", respectively."
    ),
    paste0(
      "The total-dose versus reduced-model LRT survived its separate BH family ",
      "for ", lrt_tally("conditional_positive_numeric_count"),
      "/49 count fits and ", lrt_tally("checklist_reporting"),
      "/49 reporting fits. All 49 species remain in both output families, ",
      "including failed fits."
    ),
    "",
    "## Within- versus between-location dose",
    "",
    paste0(
      "The prespecified primary coefficient is the within-location component: ",
      "event log index minus the unweighted mean event log index at its ",
      "location. The between-location component is that location mean centred ",
      "on the real-link grand mean; the two components reproduce total centred ",
      "dose exactly at event and checklist-period-zone grain."
    ),
    "",
    "## Survey method and extent sensitivities",
    "",
    paste0(
      "The surface-only table reports every species and outcome beside its ",
      "full-fit estimate. The extent table adds 12 centred log-length terms; ",
      "the event-level Pearson correlation between log index and log ",
      "length-by-width extent is ",
      stage3_dose_format_number_v1(
        unique(extent$index_extent_correlation)[[1L]]
      ), " across ",
      unique(extent$index_extent_event_n)[[1L]], " eligible events."
    ),
    "",
    "## Observer-effort negative controls",
    "",
    effort_lines,
    "",
    "Each effort model drops its response from the covariate set and retains the other two effort measures.",
    "",
    "## Fake-anchor dose placebos",
    "",
    placebo_lines,
    "",
    "The placebo models reuse the real-anchor centring constant and apply BH within the fixed 49-species family separately by offset and outcome.",
    "",
    "## Species, guild, and tercile summaries",
    "",
    paste0(
      "Inverse-variance guild summaries use each species contrast variance ",
      "computed from the complete fixed-effect covariance matrix. Seven guild ",
      "means per outcome and the corresponding guild-difference omnibus are ",
      "reported in `dose_guild_meta.csv`."
    ),
    paste0(
      "The ordered tercile figure refits the Stage 2 link-count model within ",
      "year-specific event-index terciles for Glaucous-winged Gull and Bald ",
      "Eagle. It is a visual monotonicity diagnostic, not an additional ",
      "hypothesis-test family."
    ),
    "",
    "## Fit failures and warnings",
    "",
    paste0(
      failed, " diagnostic rows were failed and ", warnings,
      " carried a convergence, singularity, or rank warning. No fallback ",
      "model was substituted; details and every species-level status are in ",
      "the CSV outputs and protected checkpoints."
    ),
    "",
    "## What this analysis does not claim",
    "",
    paste0(
      "Relative spawn index is not absolute biomass. Conditional positive ",
      "counts are not abundance, missing herring components are not observed ",
      "zeros, and checklist reporting is partly an observer process. These ",
      "post-result fits are exploratory and require prospective confirmation."
    )
  )
  writeLines(
    lines, file.path(output_root, "..", "..", "STAGE3_DOSE_REPORT.md"),
    useBytes = TRUE
  )
  invisible(verdict)
}

stage3_dose_privacy_gate_v1 <- function(paths) {
  prohibited <- c(
    "analysis_event_token", "analysis_checklist_id",
    "observer_cluster_token", "location_cluster_token",
    "event_block_token", "herring_source_token",
    "dose_event_token", "dose_location_token",
    "latitude", "longitude", "locality", "coordinates",
    "source_id", "analysis_id"
  )
  failures <- character()
  for (path in paths) {
    if (!grepl("\\.csv$", path, ignore.case = TRUE)) next
    header <- tolower(names(utils::read.csv(
      path, nrows = 1L, check.names = FALSE
    )))
    bad <- intersect(header, prohibited)
    if (length(bad)) {
      failures <- c(failures, paste(path, bad, sep = ":"))
    }
  }
  if (length(failures)) {
    stop(
      "STAGE3_DOSE_PRIVACY_GATE: ",
      paste(failures, collapse = "; "), call. = FALSE
    )
  }
  invisible(TRUE)
}

stage3_dose_write_outputs_v1 <- function(
    output_root, inputs, real, method, extent, effort,
    placebo, guild, tercile, execution_record) {
  dir.create(file.path(output_root, "figures"),
             recursive = TRUE, showWarnings = FALSE)
  primary <- real$effects[
    real$effects$component == "within_location", , drop = FALSE
  ]
  within_between <- real$effects
  method_table <- stage3_dose_sensitivity_table_v1(
    method, real, "surface_only"
  )
  extent_table <- stage3_dose_sensitivity_table_v1(
    extent, real, "log_length_adjusted"
  )
  extent_table$index_extent_correlation <- extent$extent_correlation
  extent_table$index_extent_event_n <-
    stage3_dose_release_count_v1(extent$extent_event_n)
  extent_table$length_link_grand_mean <- extent$length_grand_mean
  tables <- list(
    index_aggregation_audit = inputs$index_audit,
    dose_estimates_49x2 = primary,
    dose_within_between = within_between,
    dose_lrt = real$lrt,
    dose_method_sensitivity = method_table,
    dose_extent_sensitivity = extent_table,
    dose_effort_outcomes = effort,
    dose_placebo_tallies = placebo,
    dose_guild_meta = guild,
    dose_terciles_case_species = tercile
  )
  paths <- character()
  for (name in names(tables)) {
    path <- file.path(output_root, paste0(name, ".csv"))
    .post_stage4a_write_csv_v1(tables[[name]], path)
    paths <- c(paths, path)
  }
  figure_paths <- stage3_dose_make_tercile_figure_v1(
    tercile, file.path(output_root, "figures")
  )
  execution_path <- file.path(output_root, "execution_record_v1.yml")
  writeLines(
    yaml::as.yaml(execution_record, precision = 16),
    execution_path, useBytes = TRUE
  )
  paths <- c(paths, unname(figure_paths), execution_path)
  stage3_dose_privacy_gate_v1(paths)
  report_verdict <- stage3_dose_report_v1(
    output_root, inputs$index_audit, real, method_table, extent_table,
    effort, placebo, guild, tercile, inputs$real_grand_mean
  )
  report_path <- "STAGE3_DOSE_REPORT.md"
  manifest <- data.frame(
    file = c(paths, report_path),
    sha256 = vapply(
      c(paths, report_path), .post_stage4a_sha256_v1, character(1L)
    ),
    stringsAsFactors = FALSE
  )
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_root, "output_hash_manifest_v1.csv")
  )
  invisible(list(
    paths = paths, verdict = report_verdict, manifest = manifest
  ))
}

run_post_stage4a_stage3_dose_sensitivities_v1 <- function(
    execution_code_commit, herring_path,
    output_root = "outputs/post_stage4a_stage3_dose_v1") {
  started <- Sys.time()
  stage3_dose_authorization_gate_v1()
  stage3_dose_spec_gate_v1()
  stage3_dose_parent_gate_v1()
  protected_root <- file.path(
    "data", "derived", "post_stage4a_stage3_dose_v1"
  )
  family_path <- file.path(
    protected_root, "checkpoint_2_family_results.rds"
  )
  if (
    !file.exists(file.path(protected_root, "checkpoint_2_complete.yml")) ||
      !file.exists(family_path)
  ) {
    stop("STAGE3_DOSE_STAGING_GATE: checkpoint 2 incomplete",
         call. = FALSE)
  }
  parent_roots <- c(
    "outputs/post_stage4a_sog_event_study_v1",
    "outputs/post_stage4a_staged_refit_v1",
    "outputs/post_stage4a_staged_refit_stage2_v1"
  )
  parent_before <- lapply(
    parent_roots, staged_refit_amendment_snapshot_v1
  )
  names(parent_before) <- parent_roots
  inputs <- stage3_dose_load_inputs_v1(herring_path)
  signature <- stage3_dose_run_signature_v1(
    inputs, execution_code_commit
  )
  family_cache <- readRDS(family_path)
  if (!identical(family_cache$cache_signature, signature)) {
    stop("STAGE3_DOSE_FAMILY_CACHE_GATE: code or inputs changed",
         call. = FALSE)
  }
  real <- family_cache$results
  timings <- list()

  phase <- Sys.time()
  surface_wide <- stage3_dose_widen_by_link_v1(
    inputs$base_events, inputs$anchored_links, inputs$index,
    real_grand_mean = inputs$real_grand_mean,
    links_are_reanchored = TRUE, surface_only = TRUE
  )
  surface_events <- staged_refit_s2_attach_detectability_v1(
    surface_wide$events, inputs$detectability
  )$events
  method <- stage3_dose_fit_family_v1(
    inputs$taxa, surface_events, inputs$states, inputs$masks,
    inputs$species_registry,
    file.path(protected_root, "checkpoints", "surface_only"),
    paste(signature, "surface_only", sep = "|"),
    fit_lrt = FALSE, variant = "decomposed",
    workers = post_stage4a_worker_count_v1(length(inputs$taxa))
  )
  timings$surface_only_seconds <- as.numeric(Sys.time() - phase)

  phase <- Sys.time()
  extent_wide <- stage3_dose_widen_by_link_v1(
    inputs$base_events, inputs$anchored_links, inputs$index,
    real_grand_mean = inputs$real_grand_mean,
    links_are_reanchored = TRUE, include_extent = TRUE
  )
  extent_events <- staged_refit_s2_attach_detectability_v1(
    extent_wide$events, inputs$detectability
  )$events
  extent <- stage3_dose_fit_family_v1(
    inputs$taxa, extent_events, inputs$states, inputs$masks,
    inputs$species_registry,
    file.path(protected_root, "checkpoints", "extent"),
    paste(
      signature, "extent",
      format(extent_wide$length_grand_mean, digits = 17), sep = "|"
    ),
    fit_lrt = FALSE, variant = "extent",
    workers = post_stage4a_worker_count_v1(length(inputs$taxa))
  )
  extent$extent_correlation <- extent_wide$extent_correlation
  extent$extent_event_n <- extent_wide$extent_event_n
  extent$length_grand_mean <- extent_wide$length_grand_mean
  timings$extent_seconds <- as.numeric(Sys.time() - phase)

  phase <- Sys.time()
  placebo_results <- list()
  for (offset in c(-90L, 90L)) {
    placebo_events <- stage3_dose_placebo_events_v1(inputs, offset)
    placebo_results[[as.character(offset)]] <-
      stage3_dose_fit_family_v1(
        inputs$taxa, placebo_events, inputs$states, inputs$masks,
        inputs$species_registry,
        file.path(
          protected_root, "checkpoints",
          paste0("placebo_", ifelse(offset < 0, "m", "p"), abs(offset))
        ),
        paste(signature, "placebo", offset, sep = "|"),
        fit_lrt = FALSE, variant = "decomposed",
        workers = post_stage4a_worker_count_v1(length(inputs$taxa))
      )
  }
  placebo <- stage3_dose_placebo_tallies_v1(placebo_results)
  timings$placebo_seconds <- as.numeric(Sys.time() - phase)

  phase <- Sys.time()
  effort <- stage3_dose_effort_outcomes_v1(
    inputs$events,
    file.path(protected_root, "checkpoints", "effort"),
    signature
  )
  guild <- stage3_dose_guild_meta_v1(
    real$effects, inputs$species_registry
  )
  tercile <- stage3_dose_tercile_results_v1(
    inputs,
    file.path(protected_root, "checkpoints", "terciles"),
    signature
  )
  timings$effort_guild_tercile_seconds <-
    as.numeric(Sys.time() - phase)

  parent_after <- lapply(
    parent_roots, staged_refit_amendment_snapshot_v1
  )
  names(parent_after) <- parent_roots
  if (!identical(parent_before, parent_after)) {
    stop("STAGE3_DOSE_PARENT_IMMUTABILITY_GATE: parent changed",
         call. = FALSE)
  }
  primary <- real$effects[
    real$effects$component == "within_location", , drop = FALSE
  ]
  primary_tallies <- do.call(rbind, lapply(
    c("checklist_reporting", "conditional_positive_numeric_count"),
    function(outcome) {
      x <- primary[primary$outcome == outcome, , drop = FALSE]
      data.frame(
        outcome = outcome,
        positive_bh_q_lt_0_05 = sum(
          x$q_value < 0.05 & x$estimate > 0, na.rm = TRUE
        ),
        negative_bh_q_lt_0_05 = sum(
          x$q_value < 0.05 & x$estimate < 0, na.rm = TRUE
        ),
        estimable_species = sum(is.finite(x$estimate)),
        stringsAsFactors = FALSE
      )
    }
  ))
  execution_record <- list(
    execution_version = "post_stage4a_stage3_dose_execution_v1",
    analysis_status = "post_result_estimand_refinement_not_confirmatory",
    execution_code_commit = execution_code_commit,
    executed_at_utc = format(
      Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
    ),
    elapsed_seconds = as.numeric(Sys.time() - started),
    stage_timings_seconds = timings,
    completed_checkpoints = c(
      "checkpoint_1_case_species",
      "checkpoint_2_fixed_49_family",
      "checkpoint_3_sensitivities"
    ),
    authorization = list(
      variable = "POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED",
      exact_value_verified_in_process = TRUE,
      set_by_agent = FALSE
    ),
    population = list(
      region = "SoG", years = c(2005L, 2025L),
      eligible_checklists = 217200L,
      fixed_family_species = 49L,
      records_2026_plus_read = 0L
    ),
    index = list(
      transform = "log(relative_spawn_index_t)",
      grand_mean_log_index = inputs$real_grand_mean,
      aggregation =
        "sum rows within Year+LocationCode+Section+SpawnNumber",
      missing_component_rule =
        "zero only in derived row sum; unscorable event dropped",
      source_sha256 = inputs$index$source_hash
    ),
    joins = list(
      source_rows_to_aggregated_events = "many_to_one_PASS",
      source_links_to_aggregated_events = "many_to_one_PASS",
      links_to_checklists_then_aggregate = "many_to_one_PASS",
      detectability_to_checklists = "one_to_one_217200_PASS",
      species_to_primary_guild = "many_to_one_seven_guilds_PASS"
    ),
    engines = list(
      checklist_reporting = "lme4::glmer binomial nAGQ=0",
      conditional_positive_numeric_count =
        "lme4::lmer log count; REML estimates; ML LRT",
      effort_outcomes = "lme4::lmer REML"
    ),
    multiplicity = list(
      primary =
        "BH fixed 49 separately by outcome for dose_did_active_minus_pre",
      likelihood_ratio =
        "BH fixed 49 separately by outcome; separate from primary",
      effort = "BH across three effort outcomes",
      placebo =
        "BH fixed 49 separately by offset and outcome"
    ),
    parent_stage2_bh_positive = list(
      conditional_positive_numeric_count = 20L,
      checklist_reporting = 13L
    ),
    stage3_primary_tallies = split(
      primary_tallies, seq_len(nrow(primary_tallies))
    ),
    placebo_tallies = split(placebo, seq_len(nrow(placebo))),
    extent = list(
      index_extent_pearson_correlation =
        extent_wide$extent_correlation,
      eligible_events = stage3_dose_release_count_v1(
        extent_wide$extent_event_n
      ),
      link_grand_mean_log_length =
        extent_wide$length_grand_mean
    ),
    fit_diagnostics = list(
      real_diagnostic_rows = nrow(real$diagnostics),
      failed_real_diagnostic_rows = stage3_dose_release_count_v1(
        sum(grepl("^failed", real$diagnostics$status))
      ),
      warnings_real_diagnostic_rows = stage3_dose_release_count_v1(
        sum(
          real$diagnostics$singular_fit %in% TRUE |
            real$diagnostics$rank_deficient %in% TRUE |
            !real$diagnostics$converged %in% TRUE,
          na.rm = TRUE
        )
      ),
      no_fallback_models = TRUE
    ),
    full_fixed_effect_covariance_used = TRUE,
    parent_outputs_unchanged = TRUE,
    historical_withdrawn_control_outputs_retained_unchanged = TRUE,
    r_version = R.version.string,
    package_versions = as.list(vapply(
      c("data.table", "digest", "lme4", "yaml"),
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    )),
    workers = post_stage4a_worker_count_v1(length(inputs$taxa))
  )
  written <- stage3_dose_write_outputs_v1(
    output_root, inputs, real, method, extent, effort,
    placebo, guild, tercile, execution_record
  )
  stage3_dose_checkpoint_marker_v1(
    file.path(protected_root, "checkpoint_3_complete.yml"),
    "checkpoint_3_sensitivities",
    execution_code_commit, Sys.time() - started,
    list(
      output_root = output_root,
      verdict = written$verdict$verdict
    )
  )
  invisible(written)
}

stage3_dose_fixture_v1 <- function() {
  stopifnot(
    length(stage3_dose_prefix_terms_v1("dose_total")) == 12L,
    length(stage3_dose_prefix_terms_v1("dose_within")) == 12L,
    length(stage3_dose_prefix_terms_v1("dose_between")) == 12L,
    length(stage3_dose_weights_v1("dose_within")) == 10L
  )
  event <- data.frame(
    log_index = c(log(2), log(8), log(4), log(16)),
    location = c("a", "a", "b", "b")
  )
  event$location_mean <- ave(
    event$log_index, event$location, FUN = mean
  )
  grand <- mean(event$log_index)
  total <- event$log_index - grand
  within <- event$log_index - event$location_mean
  between <- event$location_mean - grand
  stopifnot(max(abs(total - within - between)) < 1e-12)
  formula <- stage3_dose_formula_v1("model_response", "decomposed")
  stopifnot(
    all(stage3_dose_prefix_terms_v1("dose_within") %in%
          all.vars(formula)),
    all(stage3_dose_prefix_terms_v1("dose_between") %in%
          all.vars(formula))
  )
  invisible(TRUE)
}
