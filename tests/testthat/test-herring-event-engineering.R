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

test_that("deterministic anti-chaining enforces temporal spatial and region caps", {
  events <- data.table(
    original_complex_id = "linked_chain",
    source_record_id = sprintf("event_%02d", 1:5),
    event_date = as.Date("2020-01-01") + c(0, 7, 14, 21, 28),
    x_m = c(0, 1000, 2000, 3000, 4000),
    y_m = 0,
    region = c("A", "A", "A", "A", "B")
  )
  first <- anti_chain_event_complexes(events)
  second <- anti_chain_event_complexes(events[sample(.N)])
  setorder(first, source_record_id); setorder(second, source_record_id)
  expect_identical(first$anti_chain_complex_id, second$anti_chain_complex_id)
  checked <- merge(events, first, by = c("source_record_id", "original_complex_id"))
  spans <- checked[, .(
    days = as.numeric(max(event_date) - min(event_date)),
    diameter_km = sqrt(diff(range(x_m))^2 + diff(range(y_m))^2) / 1000,
    regions = uniqueN(region)
  ), by = anti_chain_complex_id]
  expect_true(all(spans$days <= 21))
  expect_true(all(spans$diameter_km <= 25))
  expect_true(all(spans$regions == 1L))
})

test_that("event id uniqueness is enforced only on request", {
  x <- rbind(herring_fixture(), herring_fixture())
  expect_error(derive_herring_event_fields(x, require_unique_event_id = TRUE), "EVENT_ID_UNIQUENESS")
  expect_equal(nrow(derive_herring_event_fields(x)), 2L)
})
