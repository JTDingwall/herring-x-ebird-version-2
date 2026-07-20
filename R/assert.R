assert_true <- function(x, message) {
  if (!isTRUE(x)) stop(message, call. = FALSE)
  invisible(TRUE)
}

assert_columns <- function(x, required, label = deparse(substitute(x))) {
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

assert_unique_key <- function(x, key, label = deparse(substitute(x))) {
  assert_columns(x, key, label)
  duplicated_key <- duplicated(x[, key, with = FALSE])
  if (any(duplicated_key)) {
    stop(label, " has ", sum(duplicated_key), " duplicated key rows for ", paste(key, collapse = " + "), call. = FALSE)
  }
  invisible(TRUE)
}
