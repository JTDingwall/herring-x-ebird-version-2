expand_env_scalar <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) return(x)
  pattern <- "\\$\\{([A-Za-z_][A-Za-z0-9_]*)\\}"
  hits <- gregexpr(pattern, x, perl = TRUE)[[1]]
  if (identical(hits, -1L)) return(x)
  matches <- regmatches(x, list(hits))[[1]]
  for (m in matches) {
    key <- sub("^\\$\\{|\\}$", "", m)
    value <- Sys.getenv(key, unset = "")
    x <- sub(m, value, x, fixed = TRUE)
  }
  x
}

expand_env_recursive <- function(x) {
  if (is.list(x)) return(lapply(x, expand_env_recursive))
  if (is.character(x)) return(vapply(x, expand_env_scalar, character(1), USE.NAMES = FALSE))
  x
}

read_project_config <- function(path = "config/project.yml") {
  if (!file.exists(path)) stop("Missing configuration: ", path, call. = FALSE)
  cfg <- yaml::read_yaml(path)
  cfg <- expand_env_recursive(cfg)
  required <- c("project", "input_paths", "study_scope", "filters", "spatial_design", "temporal_design", "analysis_policy")
  absent <- setdiff(required, names(cfg))
  if (length(absent)) stop("Missing top-level configuration: ", paste(absent, collapse = ", "), call. = FALSE)
  cfg
}

resolve_input_paths <- function(cfg) {
  x <- unlist(cfg$input_paths, use.names = TRUE)
  empty <- names(x)[!nzchar(x)]
  if (length(empty)) {
    stop("Unset input environment variables for: ", paste(empty, collapse = ", "), call. = FALSE)
  }
  x
}
