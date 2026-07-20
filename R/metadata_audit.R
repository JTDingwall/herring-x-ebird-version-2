required_ebd_fields <- function() c(
  "TAXON CONCEPT ID", "COMMON NAME", "SCIENTIFIC NAME", "CATEGORY",
  "OBSERVATION COUNT", "OBSERVATION DATE", "SAMPLING EVENT IDENTIFIER",
  "APPROVED", "REVIEWED"
)

required_sed_fields <- function() c(
  "SAMPLING EVENT IDENTIFIER", "OBSERVER ID", "LOCALITY ID", "LOCALITY TYPE",
  "LATITUDE", "LONGITUDE", "OBSERVATION DATE", "TIME OBSERVATIONS STARTED",
  "PROTOCOL NAME", "DURATION MINUTES", "EFFORT DISTANCE KM", "EFFORT AREA HA",
  "NUMBER OBSERVERS", "ALL SPECIES REPORTED", "GROUP IDENTIFIER", "COUNTY"
)

audit_source_headers <- function(paths) {
  schemas <- list(
    ebird_ebd = inspect_delimited_header(paths[["ebird_ebd"]], delimiter = "\t"),
    ebird_sed = inspect_delimited_header(paths[["ebird_sed"]], delimiter = "\t"),
    herring_csv = inspect_delimited_header(paths[["herring_csv"]], delimiter = ",")
  )
  required <- list(ebird_ebd = required_ebd_fields(), ebird_sed = required_sed_fields(),
                   herring_csv = required_herring_source_fields())
  data.table::rbindlist(lapply(names(required), function(id) {
    fields <- schemas[[id]]$source_fields[[1L]]
    data.table::data.table(dataset_id = id, required_field = required[[id]],
                           present = required[[id]] %in% fields)
  }))
}

read_expected_input_manifest <- function(path = "metadata/input_manifest.csv") {
  x <- data.table::fread(path, colClasses = list(character = c("expected_bytes", "expected_sha256")))
  assert_columns(x, c("dataset_id", "environment_variable", "expected_bytes",
                      "expected_sha256", "checksum_scope"), "input manifest")
  assert_unique_key(x, "dataset_id", "input manifest")
  x
}

run_input_metadata_audit <- function(cfg, checksum = FALSE) {
  paths <- resolve_input_paths(cfg)
  expected <- read_expected_input_manifest()
  manifest <- build_input_manifest(paths, expected, checksum = checksum)
  if (any(manifest$status != "PASS")) stop("INPUT_AUDIT: input manifest mismatch", call. = FALSE)
  headers <- audit_source_headers(paths)
  if (any(!headers$present)) stop("INPUT_AUDIT: required source field missing", call. = FALSE)
  list(manifest = manifest, headers = headers)
}

write_input_audit <- function(audit, directory = "outputs/input_audit_local") {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(audit$manifest, file.path(directory, "input_manifest_audit.csv"))
  data.table::fwrite(audit$headers, file.path(directory, "header_audit.csv"))
  invisible(directory)
}

profile_sed_metadata <- function(path) {
  fields <- c("OBSERVER ID", "LOCALITY ID", "OBSERVATION DATE", "PROTOCOL NAME",
              "DURATION MINUTES", "EFFORT DISTANCE KM", "NUMBER OBSERVERS",
              "ALL SPECIES REPORTED", "GROUP IDENTIFIER")
  x <- data.table::fread(path, sep = "\t", select = fields, quote = "",
                         showProgress = TRUE, check.names = FALSE)
  data.table::setnames(x, fields, c("observer_id", "locality_id", "observation_date",
    "protocol_name", "duration_minutes", "effort_distance_km", "number_observers",
    "all_species_reported", "group_identifier"))
  list(
    overview = data.table::data.table(
      sed_rows = nrow(x), unique_observers = data.table::uniqueN(x$observer_id),
      unique_localities = data.table::uniqueN(x$locality_id),
      earliest_date = as.character(min(as.Date(x$observation_date), na.rm = TRUE)),
      latest_date = as.character(max(as.Date(x$observation_date), na.rm = TRUE))
    ),
    protocol = x[, .N, by = protocol_name][order(-N)],
    completeness = x[, .N, by = all_species_reported][order(-N)],
    missingness = data.table::data.table(
      field = c("duration_minutes", "effort_distance_km", "number_observers",
                "observer_id", "locality_id", "group_identifier"),
      missing = c(sum(is.na(x$duration_minutes)), sum(is.na(x$effort_distance_km)),
        sum(is.na(x$number_observers)), sum(is.na(x$observer_id) | !nzchar(x$observer_id)),
        sum(is.na(x$locality_id) | !nzchar(x$locality_id)),
        sum(is.na(x$group_identifier) | !nzchar(x$group_identifier)))
    )
  )
}

profile_herring_metadata <- function(path) {
  x <- data.table::fread(path, na.strings = c("", "NA"), check.names = FALSE)
  validate_herring_schema(x)
  list(
    overview = data.table::data.table(
      source_rows = nrow(x), earliest_year = min(x$Year, na.rm = TRUE),
      latest_year = max(x$Year, na.rm = TRUE), regions = data.table::uniqueN(x$Region),
      methods = data.table::uniqueN(x$Method)
    ),
    field_missingness = data.table::rbindlist(lapply(required_herring_source_fields(), function(field) {
      data.table::data.table(field = field, missing = sum(is.na(x[[field]])),
                             nonmissing = sum(!is.na(x[[field]])))
    })),
    component_pattern = x[, .N, by = .(
      surface_observed = !is.na(Surface), macrocystis_observed = !is.na(Macrocystis),
      understory_observed = !is.na(Understory))][order(-N)],
    method_counts = x[, .N, by = Method][order(-N)]
  )
}
