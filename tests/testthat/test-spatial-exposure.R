test_that("distance rings include the registered half kilometre boundary", {
  x <- assign_distance_ring(c(0, 0.499, 0.5, 0.999, 1, 19.999))
  expect_identical(as.character(x), c("0-0.5km", "0-0.5km", "0.5-1km", "0.5-1km", "1-2km", "10-20km"))
})

test_that("all concurrent event memberships are retained and exposure is additive", {
  links <- data.table(analysis_checklist_id = c("fixture_a", "fixture_a"),
                      source_record_id = c("event_a", "event_b"),
                      event_distance_km = c(0, 1), event_day = c(0, 0))
  rules <- data.table(window_id = "near", max_distance_km = 2, pre_days = 1, post_days = 7)
  membership <- event_window_membership(links, rules)
  expect_equal(nrow(membership), 2L)
  expect_equal(summarise_event_membership(membership)$event_count, 2L)
  got <- additive_spawn_exposure(links, scale_km = 1, duration_days = 14)
  expect_equal(got$contributing_events, 2L)
  expect_equal(got$additive_exposure, 1 + exp(-1), tolerance = 1e-8)
})

test_that("kernel truncation is audited at the cumulative exposure level", {
  links <- data.table(
    analysis_checklist_id = rep(c("fixture_a", "fixture_b"), each = 3),
    source_record_id = paste0("source_", 1:6),
    event_distance_km = c(1, 4, 8, 1, 2, 3),
    event_day = 0
  )
  got <- kernel_truncation_audit(
    links, production_radius_km = 5, wider_radius_km = 10,
    scale_km = 10, duration_days = 14, exposure_tolerance = 0.05
  )
  expect_identical(got[analysis_checklist_id == "fixture_a", truncation_status], "FAIL")
  expect_identical(got[analysis_checklist_id == "fixture_b", truncation_status], "PASS")
  expect_equal(got[analysis_checklist_id == "fixture_a", omitted_contributing_events], 1L)
})

test_that("CRS transformation uses metre units", {
  skip_if_not_installed("sf")
  x <- sf::st_as_sf(data.frame(x = -123, y = 49), coords = c("x", "y"), crs = 4326)
  y <- transform_for_linkage(x)
  expect_silent(assert_metric_crs(y))
  expect_error(assert_metric_crs(x), "projected CRS")
})

test_that("spatial linkage returns stable typed pairs and typed empty output", {
  skip_if_not_installed("sf")
  checklists <- sf::st_as_sf(
    data.frame(analysis_checklist_id = c("fixture_a", "fixture_b"),
               x = c(0, 100000), y = c(0, 100000)),
    coords = c("x", "y"), crs = 3005
  )
  events <- sf::st_as_sf(
    data.frame(source_record_id = c("source_a", "source_b"),
               x = c(100, 200000), y = c(0, 200000)),
    coords = c("x", "y"), crs = 3005
  )
  got <- candidate_event_links(checklists, events, max_distance_km = 1)
  expect_identical(names(got),
                   c("analysis_checklist_id", "source_record_id", "event_distance_km"))
  expect_equal(nrow(got), 1L)
  expect_identical(got$analysis_checklist_id, "fixture_a")
  empty <- candidate_event_links(checklists, events, max_distance_km = 0.01)
  expect_identical(names(empty), names(got))
  expect_type(empty$analysis_checklist_id, "character")
  expect_type(empty$source_record_id, "character")
  expect_type(empty$event_distance_km, "double")
  duplicate_events <- rbind(events, events[1, ])
  expect_error(candidate_event_links(checklists, duplicate_events, 1),
               "SPATIAL_LINKAGE_SOURCE_ID")
})

test_that("alongshore segments are actual requested-length line substrings", {
  shoreline <- rbind(c(0, 0), c(100, 0), c(100, 100))
  got <- construct_alongshore_segment(shoreline, c(90, 5), 80)
  expect_identical(got$status, "constructed")
  expect_equal(got$constructed_length_m, 80, tolerance = 1e-8)
  expect_true(nrow(got$coordinates) >= 2L)
  too_long <- construct_alongshore_segment(shoreline, c(90, 5), 250)
  expect_identical(too_long$status, "shoreline_feature_shorter_than_requested_length")
})
