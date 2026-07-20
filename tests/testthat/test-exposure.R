source("R/assert.R")
source("R/exposure_surfaces.R")

test_that("distance rings use requested 1-km boundaries", {
  x <- assign_distance_ring(c(0, 0.999, 1, 1.999, 2, 2.999, 3, 3.999, 4, 4.999, 5, 9.999, 10, 49.9))
  expect_equal(as.character(x)[c(1,3,5,7,9,11,13)], c("0-1km","1-2km","2-3km","3-4km","4-5km","5-10km","10-25km"))
})

test_that("additive exposure sums concurrent events", {
  x <- data.table::data.table(
    sampling_event_identifier = c("a","a"),
    event_distance_km = c(0,1),
    event_day = c(0,0)
  )
  z <- additive_spawn_exposure(x, scale_km = 1, duration_days = 14)
  expect_equal(z$contributing_events, 2L)
  expect_equal(z$additive_exposure, 1 + exp(-1), tolerance = 1e-8)
})
