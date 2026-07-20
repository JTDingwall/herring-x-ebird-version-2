# Generalized from Version 1 R/config.R at the pinned source commit.

expand_env_scalar <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) return(x)
  pattern <- "\\$\\{([A-Za-z_][A-Za-z0-9_]*)\\}"
  hits <- gregexpr(pattern, x, perl = TRUE)[[1L]]
  if (identical(hits, -1L)) return(x)
  for (token in regmatches(x, list(hits))[[1L]]) {
    key <- substr(token, 3L, nchar(token) - 1L)
    x <- sub(token, Sys.getenv(key, unset = ""), x, fixed = TRUE)
  }
  x
}

expand_env_recursive <- function(x) {
  if (is.list(x)) return(lapply(x, expand_env_recursive))
  if (is.character(x)) return(vapply(x, expand_env_scalar, character(1L), USE.NAMES = FALSE))
  x
}

read_project_config <- function(path = "config/project.yml") {
  if (!file.exists(path)) stop("CONFIG_MISSING: ", path, call. = FALSE)
  cfg <- expand_env_recursive(yaml::read_yaml(path))
  required <- c("project", "input_paths", "source_versions", "study_scope",
                "filters", "spatial_design", "temporal_design", "analysis_policy")
  absent <- setdiff(required, names(cfg))
  if (length(absent)) stop("CONFIG_SCHEMA: missing sections: ", paste(absent, collapse = ", "), call. = FALSE)
  if (!identical(cfg$project$outcome_gate, "metadata_design_only")) {
    stop("OUTCOME_GATE: setup must remain metadata_design_only", call. = FALSE)
  }
  cfg
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L || is.na(x)) y else x

resolve_input_paths <- function(cfg, require_all = TRUE) {
  paths <- unlist(cfg$input_paths, use.names = TRUE)
  blocked <- !nzchar(paths) | grepl("^<.*>$", paths)
  if (require_all && any(blocked)) {
    stop("INPUT_ENV_GATE: unset protected paths for: ", paste(names(paths)[blocked], collapse = ", "), call. = FALSE)
  }
  paths
}

validate_config_paths <- function(paths) {
  data.table::data.table(
    input_name = names(paths),
    configured = nzchar(paths),
    exists = nzchar(paths) & file.exists(paths),
    readable = nzchar(paths) & file.exists(paths) & file.access(paths, 4L) == 0L
  )
}
