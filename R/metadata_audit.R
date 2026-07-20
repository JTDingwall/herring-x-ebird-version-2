sha256_file <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)

file_audit <- function(dataset_id, path, expected_bytes = NA_real_, expected_sha256 = NA_character_, checksum = TRUE) {
  exists <- file.exists(path)
  size <- if (exists) unname(file.info(path)$size) else NA_real_
  sha <- if (exists && checksum) sha256_file(path) else NA_character_
  data.table::data.table(
    dataset_id = dataset_id,
    path = normalizePath(path, winslash = "/", mustWork = FALSE),
    exists = exists,
    bytes = size,
    expected_bytes = expected_bytes,
    bytes_match = if (is.na(expected_bytes) || !exists) NA else identical(as.numeric(size), as.numeric(expected_bytes)),
    sha256 = sha,
    expected_sha256 = expected_sha256,
    sha256_match = if (is.na(expected_sha256) || !exists || !checksum) NA else identical(sha, expected_sha256)
  )
}

read_delimited_header <- function(path, sep = "\t") {
  data.table::fread(path, sep = sep, nrows = 0L, quote = "", check.names = FALSE)
}

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

required_herring_fields <- function() c(
  "Region", "Year", "StatisticalArea", "Section", "LocationCode", "LocationName",
  "SpawnNumber", "StartDate", "EndDate", "Longitude", "Latitude", "Length",
  "Width", "Method", "Surface", "Macrocystis", "Understory"
)

audit_headers <- function(paths) {
  ebd <- names(read_delimited_header(paths[["ebird_ebd"]], "\t"))
  sed <- names(read_delimited_header(paths[["ebird_sed"]], "\t"))
  herring <- names(read_delimited_header(paths[["herring_csv"]], ","))
  data.table::rbindlist(list(
    data.table::data.table(dataset = "ebird_ebd", required_field = required_ebd_fields(), present = required_ebd_fields() %in% ebd),
    data.table::data.table(dataset = "ebird_sed", required_field = required_sed_fields(), present = required_sed_fields() %in% sed),
    data.table::data.table(dataset = "herring_csv", required_field = required_herring_fields(), present = required_herring_fields() %in% herring)
  ))
}

profile_sed_metadata <- function(path) {
  cols <- required_sed_fields()
  x <- data.table::fread(path, sep = "\t", select = cols, quote = "", showProgress = TRUE, check.names = FALSE)
  data.table::setnames(x, names(x), gsub(" ", "_", tolower(names(x)), fixed = TRUE))
  list(
    rows = nrow(x),
    protocol = x[, .N, by = protocol_name][order(-N)],
    completeness = x[, .N, by = all_species_reported][order(-N)],
    effort_missingness = data.table::data.table(
      field = c("duration_minutes", "effort_distance_km", "number_observers", "time_observations_started", "observer_id", "locality_id"),
      missing = c(sum(is.na(x$duration_minutes)), sum(is.na(x$effort_distance_km)), sum(is.na(x$number_observers)),
                  sum(is.na(x$time_observations_started) | x$time_observations_started == ""),
                  sum(is.na(x$observer_id) | x$observer_id == ""), sum(is.na(x$locality_id) | x$locality_id == ""))
    )
  )
}

profile_herring_metadata <- function(path) {
  x <- data.table::fread(path, na.strings = c("", "NA"), check.names = FALSE)
  assert_columns(x, required_herring_fields(), "herring source")
  numeric_fields <- c("Year", "LocationCode", "SpawnNumber", "Longitude", "Latitude", "Length", "Width", "Surface", "Macrocystis", "Understory")
  summary <- data.table::rbindlist(lapply(names(x), function(nm) {
    z <- x[[nm]]
    data.table::data.table(
      field = nm,
      storage_class = class(z)[1],
      missing = sum(is.na(z)),
      nonmissing = sum(!is.na(z)),
      distinct_nonmissing = data.table::uniqueN(z[!is.na(z)]),
      minimum = if (nm %in% numeric_fields && any(!is.na(z))) suppressWarnings(min(z, na.rm = TRUE)) else NA_real_,
      maximum = if (nm %in% numeric_fields && any(!is.na(z))) suppressWarnings(max(z, na.rm = TRUE)) else NA_real_
    )
  }))
  list(
    rows = nrow(x),
    field_summary = summary,
    method = x[, .N, by = Method][order(-N)],
    component_pattern = x[, .N, by = .(
      surface_observed = !is.na(Surface),
      macrocystis_observed = !is.na(Macrocystis),
      understory_observed = !is.na(Understory)
    )][order(-N)]
  )
}

audit_inputs <- function(paths, manifest_path = "metadata/input_manifest_template.csv", checksum = TRUE) {
  manifest <- data.table::fread(manifest_path)
  map <- c(
    input_ebird_ebd = "ebird_ebd",
    input_ebird_sed = "ebird_sed",
    input_herring = "herring_csv",
    input_shoreline = "shoreline_shp",
    input_sections = "sections_shp"
  )
  file_rows <- data.table::rbindlist(lapply(seq_len(nrow(manifest)), function(i) {
    id <- manifest$dataset_id[[i]]
    file_audit(id, paths[[map[[id]]]], manifest$expected_bytes[[i]], manifest$legacy_sha256[[i]], checksum)
  }))
  if (any(!file_rows$exists)) stop("One or more configured inputs do not exist", call. = FALSE)
  headers <- audit_headers(paths)
  if (any(!headers$present)) stop("One or more required source fields are missing", call. = FALSE)
  list(files = file_rows, headers = headers)
}

write_metadata_audit_json <- function(audit, path = "outputs/metadata_audit.json") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(audit, path, pretty = TRUE, auto_unbox = TRUE, na = "null")
  path
}
