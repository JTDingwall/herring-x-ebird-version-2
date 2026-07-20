test_that("file SHA-256 and byte audit are exact", {
  path <- tempfile(fileext = ".csv")
  writeLines("fixture", path, useBytes = TRUE)
  expected <- data.table(dataset_id = "input_herring", environment_variable = "FIXTURE",
                         expected_bytes = file.info(path)$size, expected_sha256 = sha256_file(path))
  got <- build_input_manifest(c(herring_csv = path), expected, checksum = TRUE)
  expect_identical(got$status, "PASS")
  expect_true(got$sha256_match)
})

test_that("shapefile bundle requires and hashes all required sidecars", {
  d <- tempfile(); dir.create(d)
  for (ext in c("shp", "shx", "dbf", "prj", "cpg")) writeLines(ext, file.path(d, paste0("coast.", ext)))
  got <- shapefile_bundle_audit(file.path(d, "coast.shp"), checksum = TRUE)
  expect_true(got$complete)
  expect_equal(got$component_count, 5L)
  unlink(file.path(d, "coast.prj"))
  expect_false(shapefile_bundle_audit(file.path(d, "coast.shp"), FALSE)$complete)
})
