privacy_text_files <- function(root = ".") {
  old <- setwd(root); on.exit(setwd(old), add = TRUE)
  files <- system2("git", c("ls-files", "--full-name", "--cached", "--others", "--exclude-standard"), stdout = TRUE)
  files <- unique(files[file.exists(file.path(root, files))])
  binary_ext <- c("png", "jpg", "jpeg", "gif", "ico", "pdf", "shp", "shx", "dbf", "rds", "qs", "fst", "parquet")
  files[!tolower(tools::file_ext(files)) %in% binary_ext]
}

scan_privacy <- function(root = ".") {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  files <- privacy_text_files(root)
  patterns <- list(
    checklist_value = paste0("(?<![A-Za-z0-9_])", "S", "[0-9]{6,}(?![A-Za-z0-9_])"),
    observer_value = paste0("(?i)(?<![A-Za-z0-9_])", "obsr", "[0-9]{3,}(?![A-Za-z0-9_])"),
    locality_value = paste0("(?<![A-Za-z0-9_])", "L", "[0-9]{6,}(?![A-Za-z0-9_])"),
    coordinate_pair = "[-+]?[0-9]{1,3}\\.[0-9]{6,}[,[:space:]]+[-+]?[0-9]{1,3}\\.[0-9]{6,}",
    windows_user_path = paste0("(?i)[A-Z]:[\\\\/]", "Users", "[\\\\/][^<>{}[:space:]]+"),
    unix_home_path = "(?<![A-Za-z0-9_])/(home|Users)/[^/<>{}[:space:]]+",
    credential = paste0("(?i)(token|password|secret)[[:space:]]*[:=][[:space:]]*['\"]?", "[A-Za-z0-9_./+-]{16,}")
  )
  allowed_raw_name_files <- c("metadata/input_manifest.csv", "config/project.yml",
                              ".Renviron.example", "R/privacy_scan.R")
  violations <- list()
  for (file in files) {
    text <- paste(readLines(file.path(root, file), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    for (kind in names(patterns)) {
      if (grepl(patterns[[kind]], text, perl = TRUE)) {
        violations[[length(violations) + 1L]] <- data.table::data.table(file = file, kind = kind)
      }
    }
    raw_name <- paste0("(?i)(", "ebd_CA-BC", "|sampling_event_data|Pacific_herring_spawn_index_data_2025_EN)")
    if (!file %in% allowed_raw_name_files && grepl(raw_name, text, perl = TRUE)) {
      violations[[length(violations) + 1L]] <- data.table::data.table(file = file, kind = "raw_filename")
    }
  }
  old <- setwd(root); on.exit(setwd(old), add = TRUE)
  tracked <- system2("git", c("ls-files", "--full-name"), stdout = TRUE)
  forbidden_ext <- grepl("\\.(rds|RDS|qs|fst|parquet)$", tracked)
  if (any(forbidden_ext)) {
    violations[[length(violations) + 1L]] <- data.table::data.table(file = tracked[forbidden_ext], kind = "forbidden_binary")
  }
  found <- data.table::rbindlist(violations, use.names = TRUE, fill = TRUE)
  list(status = if (nrow(found)) "FAIL" else "PASS", files_scanned = length(files),
       violation_count = nrow(found), violations = found)
}

write_privacy_summary <- function(scan, path = "outputs/setup/privacy_scan_summary.json") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  safe <- list(status = scan$status, files_scanned = scan$files_scanned,
               violation_count = scan$violation_count,
               categories = if (nrow(scan$violations)) sort(unique(scan$violations$kind)) else character(),
               matching_text_persisted = FALSE)
  jsonlite::write_json(safe, path, pretty = TRUE, auto_unbox = TRUE)
  invisible(path)
}
