test_that("distance rings include the registered half kilometre boundary", {
  x <- assign_distance_ring(c(0, 0.499, 0.5, 0.999, 1, 19.999))
  expect_identical(as.character(x), c("0-0.5km", "0-0.5km", "0.5-1km", "0.5-1km", "1-2km", "10-20km"))
})

test_that("all concurrent event memberships are retained and exposure is additive", {
  links <- data.table(sampling_event_identifier = c("fixture_a", "fixture_a"),
                      event_id = c("event_a", "event_b"), event_distance_km = c(0, 1), event_day = c(0, 0))
  rules <- data.table(window_id = "near", max_distance_km = 2, pre_days = 1, post_days = 7)
  membership <- event_window_membership(links, rules)
  expect_equal(nrow(membership), 2L)
  expect_equal(summarise_event_membership(membership)$event_count, 2L)
  got <- additive_spawn_exposure(links, scale_km = 1, duration_days = 14)
  expect_equal(got$contributing_events, 2L)
  expect_equal(got$additive_exposure, 1 + exp(-1), tolerance = 1e-8)
})

test_that("CRS transformation uses metre units", {
  skip_if_not_installed("sf")
  x <- sf::st_as_sf(data.frame(x = -123, y = 49), coords = c("x", "y"), crs = 4326)
  y <- transform_for_linkage(x)
  expect_silent(assert_metric_crs(y))
  expect_error(assert_metric_crs(x), "projected CRS")
})
