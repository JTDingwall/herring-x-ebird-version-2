# Additive, privacy-safe audit helpers. These functions do not alter or rerun the
# historical Stage 4A v1 analysis.

audit_stage4a_partial_pooling_families <- function(
    effect_table, registered_regions = c("SoG", "WCVI", "CC", "NA")) {
  required <- c(
    "model_id", "region", "unit_class", "outcome", "contrast",
    "estimate", "standard_error", "partial_pool_estimate",
    "partial_pool_standard_error"
  )
  missing <- setdiff(required, names(effect_table))
  if (length(missing)) {
    stop("Missing Stage 4A effect columns: ", paste(missing, collapse = ", "))
  }
  if (anyNA(effect_table$region) || any(!nzchar(trimws(effect_table$region)))) {
    stop("Stage 4A pooling audit contains a truly missing region identity")
  }
  if (any(!effect_table$region %in% registered_regions)) {
    stop("Stage 4A pooling audit contains an unregistered region code")
  }

  computed <- is.finite(effect_table$partial_pool_estimate) |
    is.finite(effect_table$partial_pool_standard_error)
  x <- effect_table[computed, , drop = FALSE]
  if (!nrow(x)) {
    return(data.frame(
      region = character(), outcome = character(), contrast = character(),
      n_rows = integer(), n_model_ids = integer(), n_unit_classes = integer(),
      model_ids = character(), unit_classes = character(),
      family_is_model_and_unit_specific = logical(), stringsAsFactors = FALSE
    ))
  }

  historical_family <- paste(x$region, x$outcome, x$contrast, sep = "\036")
  groups <- split(seq_len(nrow(x)), historical_family)
  rows <- lapply(groups, function(i) {
    model_ids <- sort(unique(x$model_id[i]))
    unit_classes <- sort(unique(x$unit_class[i]))
    data.frame(
      region = x$region[i[1L]],
      outcome = x$outcome[i[1L]],
      contrast = x$contrast[i[1L]],
      n_rows = length(i),
      n_model_ids = length(model_ids),
      n_unit_classes = length(unit_classes),
      model_ids = paste(model_ids, collapse = "|"),
      unit_classes = paste(unit_classes, collapse = "|"),
      family_is_model_and_unit_specific =
        length(model_ids) == 1L && length(unit_classes) == 1L,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

stage4a_synthetic_holdout_metadata_release <- function(
    x, date_column, release_columns, cutoff_year = 2025L) {
  if (!is.data.frame(x) || !nrow(x)) stop("x must be a non-empty data frame")
  if (length(date_column) != 1L || !date_column %in% names(x)) {
    stop("date_column must name exactly one existing field")
  }
  if (!length(release_columns) || anyDuplicated(release_columns) ||
      any(!release_columns %in% names(x))) {
    stop("release_columns must be unique existing fields")
  }
  forbidden <- grepl(
    "response|detect|count|taxon|species|comment|coordinate|latitude|longitude|observer|checklist",
    release_columns, ignore.case = TRUE
  )
  if (any(forbidden)) {
    stop("release_columns include a response or restricted-identity field")
  }
  dates <- as.Date(x[[date_column]])
  if (anyNA(dates)) stop("date_column contains missing or malformed dates")
  years <- as.integer(format(dates, "%Y"))
  keep <- years <= as.integer(cutoff_year)

  # Selection precedes projection and projection is an explicit allow-list. The
  # helper deliberately never evaluates non-date, non-release fields.
  out <- x[keep, release_columns, drop = FALSE]
  attr(out, "holdout_audit") <- list(
    cutoff_year = as.integer(cutoff_year),
    input_rows = nrow(x),
    released_rows = nrow(out),
    excluded_future_rows = sum(!keep),
    release_columns = release_columns
  )
  out
}
