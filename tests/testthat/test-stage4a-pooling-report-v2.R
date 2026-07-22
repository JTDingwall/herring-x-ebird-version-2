test_that("publication repair report artifacts are complete and hash-valid", {
  output_dir <- repo_file("outputs", "stage4a_pooling_report_v2")
  manifest <- fread(file.path(output_dir, "report_artifact_hashes_v2.csv"))
  chart_map <- fread(file.path(output_dir, "chart_map_v2.csv"))
  expect_equal(nrow(manifest), 11L)
  expect_equal(nrow(chart_map), 5L)
  expect_setequal(chart_map$chart_family,
                  c("bar", "faceted dot and interval",
                    "categorical point and interval", "histogram"))
  for (i in seq_len(nrow(manifest))) {
    file <- file.path(project_root, manifest$artifact_path[i])
    expect_true(file.exists(file), info = manifest$artifact_path[i])
    expect_identical(digest::digest(file, algo = "sha256", file = TRUE,
                                    serialize = FALSE), manifest$sha256[i])
    expect_equal(unname(file.info(file)$size), manifest$bytes[i])
  }
  text_artifacts <- file.path(project_root, manifest$artifact_path)
  text_artifacts <- text_artifacts[grepl("\\.(html|svg)$", text_artifacts)]
  for (file in text_artifacts) {
    bytes <- readBin(file, what = "raw", n = file.info(file)$size)
    expect_false(any(bytes == as.raw(13L)), info = file)
  }
})

test_that("publication repair report states scope and interpretation boundaries", {
  report <- paste(readLines(repo_file("reports", "stage4a_pooling_repair_v2.html"),
                            warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  required <- c(
    "6,562 finite v1 pooling rows", "112 invalid historical families",
    "162 v2 families", "6,085 primary rows", "No protected record was used",
    "parser undercount", "not a causal event-study estimate",
    "do not identify population abundance, biomass, occupancy, movement, or causal effects",
    "Missing DFO records are not surveyed negatives", "M26 v1"
  )
  for (phrase in required) expect_match(report, phrase, fixed = TRUE)
  expect_match(report, "<td>Estimable v2 families</td><td>162</td>", fixed = TRUE)
  expect_false(grepl("ELIGIBLE_MINIMUM_COMPONENT_COUNT</td>", report, fixed = TRUE))
  expect_false(grepl("2026", report, fixed = TRUE))
  expect_equal(lengths(regmatches(report, gregexpr("<svg", report, fixed = TRUE))), 5L)
})

test_that("publication repair report rebuild is byte-identical", {
  output_dir <- repo_file("outputs", "stage4a_pooling_report_v2")
  before <- fread(file.path(output_dir, "report_artifact_hashes_v2.csv"))
  build_stage4a_pooling_report_v2(project_root)
  after <- fread(file.path(output_dir, "report_artifact_hashes_v2.csv"))
  expect_identical(after, before)
})
