# Ported and generalized from Version 1 R/input_manifest.R.

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

shapefile_components <- function(path) {
  if (!identical(tolower(tools::file_ext(path)), "shp")) return(path)
  stem <- tools::file_path_sans_ext(basename(path))
  allowed <- c("shp", "shx", "dbf", "prj", "cpg", "sbn", "sbx", "shp.xml")
  files <- list.files(dirname(path), full.names = TRUE)
  names_lower <- tolower(basename(files))
  prefix <- paste0(tolower(stem), ".")
  files <- files[startsWith(names_lower, prefix)]
  suffix <- substring(tolower(basename(files)), nchar(stem) + 2L)
  files <- files[suffix %in% allowed]
  files[order(tolower(basename(files)), method = "radix")]
}

shapefile_bundle_audit <- function(path, checksum = TRUE) {
  files <- shapefile_components(path)
  suffix <- if (length(files)) substring(tolower(basename(files)),
    nchar(tools::file_path_sans_ext(basename(path))) + 2L) else character()
  required <- c("shp", "shx", "dbf", "prj")
  hashes <- if (checksum && length(files)) vapply(files, sha256_file, character(1L)) else rep(NA_character_, length(files))
  names(hashes) <- basename(files)
  bundle_hash <- if (checksum && length(hashes)) digest::digest(
    paste(names(hashes), hashes, sep = "=", collapse = "\n"),
    algo = "sha256", serialize = FALSE
  ) else NA_character_
  data.table::data.table(
    exists = file.exists(path),
    complete = all(required %in% suffix),
    component_count = length(files),
    components = paste(basename(files), collapse = ";"),
    bytes = if (length(files)) sum(file.info(files)$size) else NA_real_,
    sha256 = bundle_hash,
    checksum_scope = "shapefile_bundle"
  )
}

audit_one_input <- function(path, checksum = FALSE) {
  if (identical(tolower(tools::file_ext(path)), "shp")) {
    return(shapefile_bundle_audit(path, checksum))
  }
  exists <- file.exists(path)
  data.table::data.table(
    exists = exists,
    complete = exists,
    component_count = as.integer(exists),
    components = if (exists) basename(path) else "",
    bytes = if (exists) file.info(path)$size else NA_real_,
    sha256 = if (exists && checksum) sha256_file(path) else NA_character_,
    checksum_scope = "file"
  )
}

build_input_manifest <- function(paths, expected, checksum = FALSE) {
  assert_columns(expected, c("dataset_id", "environment_variable", "expected_bytes", "expected_sha256"), "expected input registry")
  map <- c(input_ebird_ebd = "ebird_ebd", input_ebird_sed = "ebird_sed",
           input_herring = "herring_csv", input_shoreline = "shoreline_shp",
           input_sections = "sections_shp")
  rows <- lapply(seq_len(nrow(expected)), function(i) {
    id <- expected$dataset_id[[i]]
    path <- unname(paths[[map[[id]]]])
    expected_bytes <- as.double(as.character(expected$expected_bytes[[i]]))
    x <- audit_one_input(path, checksum)
    x[, `:=`(
      dataset_id = id,
      environment_variable = expected$environment_variable[[i]],
      expected_bytes = expected_bytes,
      expected_sha256 = expected$expected_sha256[[i]],
      bytes_match = exists & bytes == expected_bytes,
      sha256_match = if (checksum) exists & sha256 == expected$expected_sha256[[i]] else NA
    )]
    x[, status := if (!exists) "FAIL" else if (!complete || !bytes_match) "FAIL" else if (checksum && !sha256_match) "FAIL" else "PASS"]
    x[, .(dataset_id, environment_variable, exists, complete, component_count,
          components, bytes, expected_bytes, bytes_match, sha256,
          expected_sha256, sha256_match, checksum_scope, status)]
  })
  data.table::rbindlist(rows)
}
