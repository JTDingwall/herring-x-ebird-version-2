test_that("every registered illustrative figure is labelled synthetic in the plan", {
  registry <- fread(repo_file("metadata", "figure_registry.csv"))
  html <- paste(readLines(repo_file("reports", "comprehensive_analysis_plan.html"), warn = FALSE), collapse = "\n")
  expect_equal(nrow(registry), 18L)
  expect_true(grepl("illustrative|synthetic", html, ignore.case = TRUE))
  expect_equal(length(gregexpr("<figure class=\\\"figure\\\">", html, fixed = FALSE)[[1]]), 18L)
})

test_that("working tree passes the privacy value scan", {
  got <- scan_privacy(project_root)
  if (got$status != "PASS") fail(paste(unique(paste(got$violations$file, got$violations$kind)), collapse = "; "))
  succeed()
})

test_that("privacy coordinate scan distinguishes BC coordinates from estimates", {
  expect_true(privacy_contains_bc_coordinate_pair(paste0("49.282", "700, -123.120", "700")))
  expect_true(privacy_contains_bc_coordinate_pair(paste0("-123.120", "700 49.282", "700")))
  expect_false(privacy_contains_bc_coordinate_pair("0.23445222, 0.1320002 0.3369043"))
  expect_false(privacy_contains_bc_coordinate_pair("1.74766322 2.22726575"))
})
