stage4a_allowed_dispositions <- function() {
  c("activated_core", "activated_component", "activated_diagnostic",
    "deferred_pre_response", "prospective_locked")
}

stage4a_activated_models <- function() {
  c("M01", "M02", "M05", "M08", "M11", "M12", "M26", "M27",
    "M28", "M29", "M32", "M40")
}

stage4a_validate_disposition <- function(registry, disposition) {
  stopifnot(nrow(registry) == 45L, nrow(disposition) == 45L)
  stopifnot(identical(as.character(registry$model_id),
                      as.character(disposition$model_id)))
  stopifnot(all(disposition$stage4a_disposition %in%
                stage4a_allowed_dispositions()))
  observed <- disposition$model_id[grepl("^activated_",
    disposition$stage4a_disposition)]
  stopifnot(setequal(observed, stage4a_activated_models()))
  stopifnot(identical(disposition$stage4a_disposition[disposition$model_id == "M31"],
                      "prospective_locked"))
  invisible(TRUE)
}

stage4a_region_role <- function(region, year) {
  ifelse(region == "SoG" & year >= 2005, "primary",
    ifelse(region == "WCVI" & year >= 2015, "candidate_primary",
      ifelse(region %in% c("CC", "NA"), "hierarchical_descriptive", "unsupported")))
}

stage4a_effort_eligible <- function(protocol, duration_minutes,
                                    effort_distance_km, observer_count,
                                    maximum_travel_km = 5) {
  protocol <- tolower(protocol)
  complete_effort <- protocol %in% c("stationary", "traveling") &
    is.finite(duration_minutes) & duration_minutes >= 5 & duration_minutes <= 300 &
    is.finite(observer_count) & observer_count >= 1 & observer_count <= 10
  distance_ok <- protocol == "stationary" |
    (is.finite(effort_distance_km) & effort_distance_km >= 0 &
       effort_distance_km <= maximum_travel_km)
  complete_effort & distance_ok
}

stage4a_materialize_taxon <- function(events, states, masks, analysis_taxon_id) {
  stopifnot(!anyDuplicated(events$analysis_event_token))
  state <- states[states$analysis_taxon_id == analysis_taxon_id, , drop = FALSE]
  mask <- masks[masks$analysis_taxon_id == analysis_taxon_id, , drop = FALSE]
  stopifnot(!anyDuplicated(state$analysis_event_token),
            !anyDuplicated(mask$analysis_event_token))
  idx <- match(events$analysis_event_token, state$analysis_event_token)
  midx <- match(events$analysis_event_token, mask$analysis_event_token)
  out <- events
  out$detection <- ifelse(is.na(idx), 0L, as.integer(state$detection[idx]))
  out$numeric_count <- suppressWarnings(as.numeric(state$numeric_count[idx]))
  out$lower_bound_count <- suppressWarnings(as.numeric(state$lower_bound_count[idx]))
  out$count_type <- ifelse(is.na(idx), "deterministic_zero", state$count_type[idx])
  out$ambiguity_flag <- !is.na(midx) |
    (!is.na(idx) & as.logical(state$ambiguity_flag[idx]))
  unresolved <- is.na(idx) & out$ambiguity_flag
  out$detection[unresolved] <- NA_integer_
  out$count_type[unresolved] <- "structural_unknown"
  out$analysis_taxon_id <- analysis_taxon_id
  out
}

stage4a_population_prediction <- function(model, newdata, random_terms = character()) {
  if (inherits(model, "gam") && length(random_terms)) {
    return(stats::predict(model, newdata = newdata, type = "response",
                          exclude = random_terms))
  }
  stats::predict(model, newdata = newdata, type = "response")
}

stage4a_validate_folds <- function(events) {
  stopifnot(setequal(sort(unique(events$event_fold)), 1:4))
  stopifnot(all(events$event_fold >= 1L & events$event_fold <= 4L))
  stopifnot(all(events$observer_fold >= 1L & events$observer_fold <= 4L))
  stopifnot(all(tapply(events$event_fold, events$event_block_token,
                       function(x) length(unique(x))) == 1L))
  invisible(TRUE)
}

stage4a_bh_within_family <- function(tab) {
  stopifnot(all(c("multiplicity_family", "p_value") %in% names(tab)))
  tab$q_value <- NA_real_
  for (family in unique(tab$multiplicity_family)) {
    idx <- which(tab$multiplicity_family == family & is.finite(tab$p_value))
    tab$q_value[idx] <- stats::p.adjust(tab$p_value[idx], method = "BH")
  }
  tab
}

stage4a_suppress_small_cells <- function(tab, count_column = "n", threshold = 20L) {
  stopifnot(count_column %in% names(tab))
  small <- !is.na(tab[[count_column]]) & tab[[count_column]] < threshold
  protected_measure <- setdiff(names(tab),
    c("model_id", "analysis_scope", "region", "outcome", "status",
      "fold", "sensitivity", "multiplicity_family", "suppressed_below_20"))
  tab$suppressed_below_20 <- small
  tab[small, protected_measure] <- NA
  tab
}

stage4a_fixture <- function() {
  events <- data.frame(
    analysis_event_token = sprintf("fixture_%03d", 1:80),
    event_block_token = sprintf("block_%02d", rep(1:20, each = 4)),
    event_fold = rep(rep(1:4, each = 5), each = 4),
    observer_fold = rep(4:1, 20),
    region = rep(c("SoG", "WCVI"), each = 40),
    checklist_year = c(rep(2018, 40), rep(2021, 40)),
    protocol = rep(c("stationary", "traveling"), 40),
    duration_minutes = 30, effort_distance_km = rep(c(0, 2), 40),
    observer_count = 2, stringsAsFactors = FALSE)
  states <- data.frame(
    analysis_event_token = events$analysis_event_token[c(1, 2, 5, 9)],
    analysis_taxon_id = "fixture_taxon", detection = 1L,
    numeric_count = c("3", "", "5", ""),
    lower_bound_count = c("", "", "", "2"),
    count_type = c("numeric", "unquantified_X", "numeric", "lower_bound"),
    ambiguity_flag = c(FALSE, FALSE, FALSE, FALSE), stringsAsFactors = FALSE)
  masks <- data.frame(analysis_event_token = events$analysis_event_token[3],
    analysis_taxon_id = "fixture_taxon", stringsAsFactors = FALSE)
  den <- stage4a_materialize_taxon(events, states, masks, "fixture_taxon")
  stopifnot(sum(den$detection == 1, na.rm = TRUE) == 4L,
            sum(den$count_type == "deterministic_zero") == 75L,
            sum(den$count_type == "structural_unknown") == 1L,
            is.na(den$numeric_count[2]), is.na(den$detection[3]))
  stage4a_validate_folds(events)
  stopifnot(all(stage4a_effort_eligible(events$protocol,
    events$duration_minutes, events$effort_distance_km, events$observer_count)))
  invisible(TRUE)
}
