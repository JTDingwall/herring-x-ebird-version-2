herring_fixture <- function() data.table(
  Region = "fixture_region", Year = 2020L, StatisticalArea = "fixture_area", Section = "fixture_section",
  LocationCode = "fixture_location", LocationName = "fixture_name", SpawnNumber = 1L,
  StartDate = "2020-03-01", EndDate = "2020-03-03", Longitude = -123, Latitude = 49,
  Length = 100, Width = 10, Method = "fixture_method", Surface = 1,
  Macrocystis = NA_real_, Understory = 2
)

test_that("all seventeen source fields and missing components are preserved", {
  x <- herring_fixture(); got <- derive_herring_event_fields(x)
  expect_identical(got[, required_herring_source_fields(), with = FALSE], x)
  expect_true(got$component_macrocystis_missing)
  expect_equal(got$relative_spawn_index, 3)
  x[, c("Surface", "Macrocystis", "Understory") := NA_real_]
  expect_true(is.na(derive_herring_event_fields(x)$relative_spawn_index))
})

test_that("source IDs quality tiers and event complexes are deterministic", {
  x <- herring_fixture()
  expect_identical(stable_source_record_id(x, paste(rep("a", 64), collapse = "")),
                   stable_source_record_id(x, paste(rep("a", 64), collapse = "")))
  expect_identical(as.character(derive_herring_event_fields(x)$event_quality_tier), "high")
  pairs <- data.table(event_id_a = c("event_a", "event_b", "event_d"),
                      event_id_b = c("event_b", "event_c", "event_e"), linked = c(TRUE, TRUE, FALSE))
  got <- event_complex_components(pairs)
  expect_equal(uniqueN(got[event_id %in% c("event_a", "event_b", "event_c"), event_complex_id]), 1L)
})
