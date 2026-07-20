# Ported from Version 1 R/join_assertions.R with explicit post-join accounting.

key_signature <- function(x, keys) {
  columns <- if (data.table::is.data.table(x)) x[, ..keys] else x[keys]
  do.call(paste, c(lapply(columns, function(z) ifelse(is.na(z), "<NA>", as.character(z))), sep = "\u001f"))
}

assert_join_cardinality <- function(x, y, by, expected, relationship_name = "join") {
  allowed <- c("one-to-one", "many-to-one", "one-to-many", "many-to-many")
  if (!expected %in% allowed) stop("JOIN_DECLARATION: invalid expected cardinality", call. = FALSE)
  if (is.null(names(by)) || all(names(by) == "")) {
    x_keys <- y_keys <- as.character(by)
  } else {
    x_keys <- names(by); y_keys <- unname(by)
  }
  assert_columns(x, x_keys, paste0(relationship_name, " left"))
  assert_columns(y, y_keys, paste0(relationship_name, " right"))
  x_dup <- anyDuplicated(key_signature(x, x_keys)) > 0L
  y_dup <- anyDuplicated(key_signature(y, y_keys)) > 0L
  violates <- switch(expected,
    "one-to-one" = x_dup || y_dup,
    "many-to-one" = y_dup,
    "one-to-many" = x_dup,
    "many-to-many" = FALSE)
  if (violates) stop("JOIN_CARDINALITY [", relationship_name, "]: expected ", expected,
                     "; left_duplicate=", x_dup, "; right_duplicate=", y_dup, call. = FALSE)
  invisible(list(expected = expected, x_duplicate = x_dup, y_duplicate = y_dup))
}

assert_join_row_accounting <- function(before_n, after_n, expected, relationship_name = "join") {
  if (expected %in% c("one-to-one", "many-to-one") && after_n != before_n) {
    stop("JOIN_ROW_ACCOUNTING [", relationship_name, "]: ", before_n, " -> ", after_n, call. = FALSE)
  }
  invisible(TRUE)
}
