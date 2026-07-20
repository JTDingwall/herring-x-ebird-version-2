new_qa_record <- function(check_id, status, n_examined = NA_integer_, n_flagged = NA_integer_, note = "") {
  allowed <- c("pass", "warning", "hard_stop", "not_run")
  if (!status %in% allowed) stop("Unknown QA status", call. = FALSE)
  data.table::data.table(
    check_id = as.character(check_id),
    status = status,
    n_examined = as.integer(n_examined),
    n_flagged = as.integer(n_flagged),
    note = as.character(note)
  )
}

write_aggregate_qa <- function(records, path) {
  records <- data.table::rbindlist(records, use.names = TRUE, fill = TRUE)
  forbidden <- c("sampling_event_identifier", "observer_id", "locality_id", "latitude", "longitude", "comments")
  if (length(intersect(tolower(names(records)), forbidden))) {
    stop("QA output contains row-level or restricted identifier columns", call. = FALSE)
  }
  data.table::fwrite(records, path)
  invisible(path)
}
